[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string] 
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
                                         -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
                                         -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
                                -ChildPath "..\UnitTestHelper.psm1" `
                                -Resolve)

$Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
                                              -DscResource "SPPowerPointAutomationServiceApp"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests
        $getTypeFullName = "Microsoft.Office.Server.PowerPoint.Administration.PowerPointConversionServiceApplication"

        # Mocks for all 
        Mock -CommandName Get-SPServiceApplication -MockWith { }
        Mock -CommandName Get-SPServiceApplicationPool -MockWith { }
        Mock -CommandName Get-SPServiceApplicationProxy -MockWith { }

        Mock -CommandName New-SPPowerPointConversionServiceApplication -MockWith { }
        Mock -CommandName New-SPPowerPointConversionServiceApplicationProxy -MockWith { }
        Mock -CommandName Remove-SPServiceApplication -MockWith { }

        # Test contexts 
        Context -Name "When Ensure is Absent and we specify additional paramters" -Fixture {
            $testParams = @{
                Name = "Power Point Automation Service Application"
                ProxyName = "Power Point Automation Service Application Proxy"
                ApplicationPool = "SharePoint Services App Pool"
                CacheExpirationPeriodInSeconds = 600
                MaximumConversionsPerWorker = 5
                WorkerKeepAliveTimeoutInSeconds = 120
                WorkerProcessCount = 3
                WorkerTimeoutInSeconds = 300
                Ensure = "Absent"
            }
  
            It "Should throw an exception as additional parameters are not allowed when Ensure = 'Absent'" { 
                { Get-TargetResource @testParams } | Should throw "You cannot use any of the parameters when Ensure is specified as Absent"
                { Test-TargetResource @testParams } | Should throw "You cannot use any of the parameters when Ensure is specified as Absent"
                { Set-TargetResource @testParams } | Should throw "You cannot use any of the parameters when Ensure is specified as Absent"    
            } 
        }

        Context -Name "When Ensure is Present but we don't specify an ApplicationPool" -Fixture {
            $testParams = @{
                Name = "Power Point Automation Service Application"
                ProxyName = "Power Point Automation Service Application Proxy"
                CacheExpirationPeriodInSeconds = 600
                MaximumConversionsPerWorker = 5
                WorkerKeepAliveTimeoutInSeconds = 120
                WorkerProcessCount = 3
                WorkerTimeoutInSeconds = 300
                Ensure = "Present"
            }

            Mock -CommandName Get-SPServiceApplicationPool -MockWith { 
                return $null
            } 
  
            It "Should throw an exception as additional parameters are not allowed when Ensure = 'Absent'" { 
                { Get-TargetResource @testParams } | Should throw "An Application Pool and  are required to configure the PowerPoint Automation Service Application"
                { Test-TargetResource @testParams } | Should throw "An Application Pool and  are required to configure the PowerPoint Automation Service Application"
                { Set-TargetResource @testParams } | Should throw "An Application Pool and  are required to configure the PowerPoint Automation Service Application"
            } 
        }

        

        Context -Name "When no service applications exist in the current farm" -Fixture {
            $testParams = @{
                Name = "Power Point Automation Service Application"
                ProxyName = "Power Point Automation Service Application Proxy"
                ApplicationPool = "SharePoint Services App Pool"
                CacheExpirationPeriodInSeconds = 600
                MaximumConversionsPerWorker = 5
                WorkerKeepAliveTimeoutInSeconds = 120
                WorkerProcessCount = 3
                WorkerTimeoutInSeconds = 300
                Ensure = "Present"
            }

            Mock -CommandName Get-SPServiceApplicationPool -MockWith { 
                return @{ 
                    Name = $testParams.ApplicationPool 
                } 
            }
            
            Mock -CommandName New-SPPowerPointConversionServiceApplication -MockWith { }
            Mock -CommandName New-SPPowerPointConversionServiceApplicationProxy -MockWith { }
            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return $null 
            }
            
            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }
            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }
            It "Should create a new service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Get-SPServiceApplicationPool -Times 1
                Assert-MockCalled New-SPPowerPointConversionServiceApplication -Times 1
                Assert-MockCalled New-SPPowerPointConversionServiceApplicationProxy -Times 1
            }

        }

        Context -Name "When service applications exist in the current farm but the specific PowerPoint Automation Services app does not" -Fixture {
           $testParams = @{
                Name = "Power Point Automation Service Application"
                ProxyName = "Power Point Automation Service Application Proxy"
                ApplicationPool = "SharePoint Services App Pool"
                CacheExpirationPeriodInSeconds = 600
                MaximumConversionsPerWorker = 5
                WorkerKeepAliveTimeoutInSeconds = 120
                WorkerProcessCount = 3
                WorkerTimeoutInSeconds = 300
                Ensure = "Present"
            }

             Mock -CommandName Get-SPServiceApplicationPool -MockWith { 
                return @{ 
                    Name = $testParams.ApplicationPool 
                } 
            }

            Mock -CommandName New-SPPowerPointConversionServiceApplication -MockWith { }
            Mock -CommandName New-SPPowerPointConversionServiceApplicationProxy -MockWith { }
            
            Mock -CommandName Get-SPServiceApplication -MockWith {
                $spServiceApp = [PSCustomObject]@{ 
                                    DisplayName = $testParams.Name 
                                } 
                $spServiceApp | Add-Member -MemberType ScriptMethod `
                                           -Name GetType `
                                           -Value {  
                                                return @{ 
                                                    FullName = "Microsoft.Office.UnKnownWebServiceApplication" 
                                                }  
                                            } -PassThru -Force 
                return $spServiceApp 
            }

            It "Should return 'Absent' from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }
            It "Should return 'false' from the Test method" {
                Test-TargetResource @testParams | Should Be $false 
            }  
            It "Should create a new Power Point Automation Service Application from the Set method" {
                Set-TargetResource @testParams
                Assert-MockCalled  Get-SPServiceApplicationPool
                Assert-MockCalled New-SPPowerPointConversionServiceApplication
                Assert-MockCalled New-SPPowerPointConversionServiceApplicationProxy
            }
        }

        Context -Name "When service applications should exist but the application pool doesn't exist" -Fixture {
           $testParams = @{
                Name = "Power Point Automation Service Application"
                ProxyName = "Power Point Automation Service Application Proxy"
                ApplicationPool = "SharePoint Services App Pool"
                CacheExpirationPeriodInSeconds = 600
                MaximumConversionsPerWorker = 5
                WorkerKeepAliveTimeoutInSeconds = 120
                WorkerProcessCount = 3
                WorkerTimeoutInSeconds = 300
                Ensure = "Present"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                $spServiceApp = [PSCustomObject]@{ 
                                    DisplayName = $testParams.Name 
                                } 
                $spServiceApp | Add-Member -MemberType ScriptMethod `
                                           -Name GetType `
                                           -Value {  
                                                return @{ 
                                                    FullName = "Microsoft.Office.UnKnownWebServiceApplication" 
                                                }  
                                            } -PassThru -Force 
                return $spServiceApp 
            }

            Mock -CommandName Get-SPServiceApplicationPool -MockWith {
                return $null
            }

            It "Should return 'Absent' from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }
            It "Should return 'false' from the Test method" {
                Test-TargetResource @testParams | Should Be $false 
            }  
            It "Should create a new Power Point Automation Service Application from the Set method" {
                 { Set-TargetResource @testParams } | Should throw "Specified application pool does not exist"
            }
        }

        Context -Name "When a service application exists and is configured correctly" -Fixture {
            $testParams = @{
                Name = "Power Point Automation Service Application"
                ProxyName = "Power Point Automation Service Application Proxy"
                ApplicationPool = "SharePoint Services App Pool"
                CacheExpirationPeriodInSeconds = 600
                MaximumConversionsPerWorker = 5
                WorkerKeepAliveTimeoutInSeconds = 120
                WorkerProcessCount = 3
                WorkerTimeoutInSeconds = 300
                Ensure = "Present"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                $spServiceApp = [PSCustomObject]@{ 
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                }
                $spServiceApp | Add-Member -MemberType ScriptMethod `
                                           -Name GetType `
                                           -Value {  
                                                return @{ 
                                                    FullName = $getTypeFullName 
                                                }  
                                            } -PassThru -Force 
                
                $spServiceApp | Add-Member -MemberType SCriptMethod `
                                            -Name IsConnected `
                                            -Value {
                                                return $true
                                            } -PassThru -Force

                return $spServiceApp
            }

            Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                return @{
                    Name = $testParams.ProxyName
                }
            }

            It "Should return Present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "When a service application exists but has a new Proxy Assignment" -Fixture {
            $testParams = @{
                Name = "Power Point Automation Service Application"
                ProxyName = "Power Point Automation Service Application Proxy"
                ApplicationPool = "SharePoint Services App Pool"
                CacheExpirationPeriodInSeconds = 600
                MaximumConversionsPerWorker = 5
                WorkerKeepAliveTimeoutInSeconds = 120
                WorkerProcessCount = 3
                WorkerTimeoutInSeconds = 300
                Ensure = "Present"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                $spServiceApp = [PSCustomObject]@{ 
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                }
                $spServiceApp | Add-Member -MemberType ScriptMethod `
                                           -Name GetType `
                                           -Value {  
                                                return @{ 
                                                    FullName = $getTypeFullName 
                                                }  
                                            } -PassThru -Force 
                return $spServiceApp
            }

             Mock -CommandName Get-SPServiceApplicationPool -MockWith { 
                return @{ 
                    Name = $testParams.ApplicationPool 
                } 
            }

            Mock -CommandName Get-SPServiceApplicationProxy -MockWith { }

            It "Should return Present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }
            It "Should call Get-SPServiceApplicationProxy when Set method is called." {
                Set-TargetResource @testParams
                Assert-MockCalled Get-SPServiceApplicationProxy
            }
        }

        Context -Name "When a service application exists but has a new Application Pool Assignment" -Fixture {
            $testParams = @{
                Name = "Power Point Automation Service Application"
                ProxyName = "Power Point Automation Service Application Proxy"
                ApplicationPool = "SharePoint Services App Pool"
                CacheExpirationPeriodInSeconds = 600
                MaximumConversionsPerWorker = 5
                WorkerKeepAliveTimeoutInSeconds = 120
                WorkerProcessCount = 3
                WorkerTimeoutInSeconds = 300
                Ensure = "Present"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                $spServiceApp = [PSCustomObject]@{ 
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = "Other SharePoint Services App Pool" }
                }
                $spServiceApp | Add-Member -MemberType ScriptMethod `
                                           -Name GetType `
                                           -Value {  
                                                return @{ 
                                                    FullName = $getTypeFullName 
                                                }  
                                            } -PassThru -Force 
                return $spServiceApp
            }

            It "Should return Present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }
            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }
        }
        
        Context -Name "When the service application exists but it shouldn't" -Fixture {
            $testParams = @{
                Name = "Power Point Automation Service Application"
                Ensure = "Absent"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                $spServiceApp = [PSCustomObject]@{ 
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                }
                $spServiceApp | Add-Member -MemberType ScriptMethod `
                                           -Name GetType `
                                           -Value {  
                                                return @{ 
                                                    FullName = $getTypeFullName 
                                                }  
                                            } -PassThru -Force 
                return $spServiceApp
            }
            
            It "Should return present from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present" 
            }
            
            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "Should call the remove service application cmdlet in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPServiceApplication
            }
        }
        
        Context -Name "When the service application doesn't exist and it shouldn't" -Fixture {
            $testParams = @{
                Name = "Power Point Automation Service Application"
                Ensure = "Absent"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return $null 
            }
            
            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }
            
            It "Should return true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "When a service application doesn't exists but it should" -Fixture {
           $testParams = @{
                Name = "Power Point Automation Service Application"
                ProxyName = "Power Point Automation Service Application Proxy"
                ApplicationPool = "SharePoint Services App Pool"
                CacheExpirationPeriodInSeconds = 600
                MaximumConversionsPerWorker = 5
                WorkerKeepAliveTimeoutInSeconds = 120
                WorkerProcessCount = 3
                WorkerTimeoutInSeconds = 300
                Ensure = "Present"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return $nulls
            }

            It "Should return Absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }
        }
        
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
