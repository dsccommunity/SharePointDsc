[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string] 
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
                                         -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
                                         -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
                                -ChildPath "..\SharePointDsc.TestHarness.psm1" `
                                -Resolve)

$Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
                                              -DscResource "SPSubscriptionSettingsServiceApp"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests
        $getTypeFullName = "Microsoft.SharePoint.SPSubscriptionSettingsServiceApplication"

        # Mocks for all contexts   
        Mock -CommandName New-SPSubscriptionSettingsServiceApplication -MockWith {
            return @{} 
        }
        Mock -CommandName New-SPSubscriptionSettingsServiceApplicationProxy -MockWith { 
            return @{}
        }
        Mock -CommandName Set-SPSubscriptionSettingsServiceApplication -MockWith { }
        Mock -CommandName Remove-SPServiceApplication -MockWith { }

        # Test contexts
        Context -Name "When no service applications exist in the current farm" -Fixture {
            $testParams = @{
                Name = "Test App"
                ApplicationPool = "Test App Pool"
                DatabaseName = "Test_DB"
                DatabaseServer = "TestServer\Instance"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return $null 
            }
            
            Mock -CommandName New-SPSubscriptionSettingsServiceApplication -MockWith { 
                return @{}
            }
            
            Mock -CommandName New-SPSubscriptionSettingsServiceApplicationProxy -MockWith { 
                return @{}
            }
            
            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"  
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should create a new service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPSubscriptionSettingsServiceApplication
                Assert-MockCalled New-SPSubscriptionSettingsServiceApplicationProxy
            }
        }

        Context -Name "When service applications exist in the current farm but the specific subscription settings service app does not" -Fixture {
            $testParams = @{
                Name = "Test App"
                ApplicationPool = "Test App Pool"
                DatabaseName = "Test_DB"
                DatabaseServer = "TestServer\Instance"
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

            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }
        }

        Context -Name "When a service application exists and is configured correctly" -Fixture {
            $testParams = @{
                Name = "Test App"
                ApplicationPool = "Test App Pool"
                DatabaseName = "Test_DB"
                DatabaseServer = "TestServer\Instance"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                $spServiceApp = [PSCustomObject]@{
                    TypeName = "Microsoft SharePoint Foundation Subscription Settings Service Application"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ 
                        Name = $testParams.ApplicationPool 
                    }
                    Database = @{
                        Name = $testParams.DatabaseName
                        Server = @{ Name = $testParams.DatabaseServer }
                    }
                }
                $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value { 
                    return @{ FullName = $getTypeFullName } 
                } -PassThru -Force
                return $spServiceApp
            }

            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"  
            }

            It "Should return true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "When a service application exists and the app pool is not configured correctly" -Fixture {
            $testParams = @{
                Name = "Test App"
                ApplicationPool = "Test App Pool"
                DatabaseName = "Test_DB"
                DatabaseServer = "TestServer\Instance"
                Ensure = "Present"
            }
            
            Mock -CommandName Get-SPServiceApplication -MockWith {
                $spServiceApp = [pscustomobject]@{
                    TypeName = "Microsoft SharePoint Foundation Subscription Settings Service Application"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = "Wrong App Pool Name" }
                    Database = @{
                        Name = $testParams.DatabaseName
                        Server = @{ Name = $testParams.DatabaseServer }
                    }
                }
                $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                                    -Name Update `
                                    -Value {
                                            $Global:SPDscSubscriptionServiceUpdateCalled = $true
                                    } -PassThru 
                $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                                    -Name GetType `
                                    -Value { 
                                        New-Object -TypeName "Object" |
                                            Add-Member -MemberType NoteProperty `
                                                       -Name FullName `
                                                       -Value $getTypeFullName `
                                                       -PassThru
                                    } -PassThru -Force
                return $spServiceApp
            }

            Mock -CommandName Get-SPServiceApplicationPool { 
                return @{ 
                    Name = $testParams.ApplicationPool 
                } 
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call the update service app cmdlet from the set method" {
                $Global:SPDscSubscriptionServiceUpdateCalled = $false
                Set-TargetResource @testParams
                Assert-MockCalled Get-SPServiceApplicationPool
                $Global:SPDscSubscriptionServiceUpdateCalled | Should Be $true
            }
        }

        Context -Name "When a service app needs to be created and no database parameters are provided" -Fixture {
            $testParams = @{
                Name = "Test App"
                ApplicationPool = "Test App Pool"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return $null 
            }

            It "should not throw an exception in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPSubscriptionSettingsServiceApplication
                Assert-MockCalled New-SPSubscriptionSettingsServiceApplicationProxy
            }
        }
        
        Context -Name "When the service app exists but it shouldn't" -Fixture {
            $testParams = @{
                Name = "Test App"
                ApplicationPool = "-"
                Ensure = "Absent"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                $spServiceApp = [PSCustomObject]@{
                    TypeName = "Microsoft SharePoint Foundation Subscription Settings Service Application"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ 
                        Name = $testParams.ApplicationPool 
                    }
                    Database = @{
                        Name = $testParams.DatabaseName
                        Server = @{ Name = $testParams.DatabaseServer }
                    }
                }
                $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value { 
                    return @{ FullName = $getTypeFullName } 
                } -PassThru -Force
                return $spServiceApp
            }
            
            It "Should return present from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present" 
            }
            
            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "Should remove the service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPServiceApplication
            }
        }
        
        Context -Name "When the service app doesn't exist and shouldn't" -Fixture {
            $testParams = @{
                Name = "Test App"
                ApplicationPool = "-"
                Ensure = "Absent"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return $null 
            }
            
            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }
            
            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
