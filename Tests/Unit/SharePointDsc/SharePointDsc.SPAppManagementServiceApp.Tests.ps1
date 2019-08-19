[CmdletBinding()]
param(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
            -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
        -ChildPath "..\UnitTestHelper.psm1" `
        -Resolve)

$Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
    -DscResource "SPAppManagementServiceApp"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        #initialise tests
        $getTypeFullName = "Microsoft.SharePoint.AppManagement.AppManagementServiceApplication"

        # Mocks for all contexts
        Mock -CommandName Remove-SPServiceApplication -MockWith { }

        # Test contexts
        Context -Name "When no service applications exist in the current farm but it should" -Fixture {
            $testParams = @{
                Name            = "Test App"
                ApplicationPool = "Test App Pool"
                DatabaseName    = "Test_DB"
                Ensure          = "Present"
                DatabaseServer  = "TestServer\Instance"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { return $null }
            Mock -CommandName New-SPAppManagementServiceApplication -MockWith { return  @(@{ }) }
            Mock -CommandName New-SPAppManagementServiceApplicationProxy -MockWith { return $null }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name }
            }

            It "Should return false when the test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should create a new service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPAppManagementServiceApplication
            }
        }

        Context -Name "When service applications exist in the current farm with the same name but is the wrong type" -Fixture {
            $testParams = @{
                Name            = "Test App"
                ApplicationPool = "Test App Pool"
                DatabaseName    = "Test_DB"
                Ensure          = "Present"
                DatabaseServer  = "TestServer\Instance"
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

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name }
            }

        }

        Context -Name "When a service application exists and it should, and is also configured correctly" -Fixture {
            $testParams = @{
                Name            = "Test App"
                ApplicationPool = "Test App Pool"
                DatabaseName    = "Test_DB"
                Ensure          = "Present"
                DatabaseServer  = "TestServer\Instance"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith {
                $spServiceApp = [PSCustomObject]@{
                    TypeName        = "App Management Service Application"
                    DisplayName     = $testParams.Name
                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                    Database        = @{
                        Name                 = $testParams.DatabaseName
                        NormalizedDataSource = $testParams.DatabaseServer
                    }
                }
                $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                    return @{ FullName = $getTypeFullName }
                } -PassThru -Force
                $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name IsConnected -Value {
                    return $true
                } -PassThru -Force
                return $spServiceApp
            }

            Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                $proxiesToReturn = @()
                $proxy = @{
                    Name        = "AppManagement Proxy"
                    DisplayName = "AppManagement Proxy"
                }
                $proxy = $proxy | Add-Member -MemberType ScriptMethod `
                    -Name Delete `
                    -Value { } `
                    -PassThru
                $proxiesToReturn += $proxy

                return $proxiesToReturn
            }

            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name }
            }

            It "Should return true when the test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "When a service application exists and it should, but the app pool is not configured correctly" -Fixture {
            $testParams = @{
                Name            = "Test App"
                ApplicationPool = "Test App Pool"
                DatabaseName    = "Test_DB"
                Ensure          = "Present"
                DatabaseServer  = "TestServer\Instance"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith {
                $spServiceApp = [PSCustomObject]@{
                    TypeName        = "App Management Service Application"
                    DisplayName     = $testParams.Name
                    ApplicationPool = @{ Name = "Wrong app pool" }
                    Database        = @{
                        Name                 = $testParams.DatabaseName
                        NormalizedDataSource = $testParams.DatabaseServer
                    }
                }
                $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                    return @{ FullName = $getTypeFullName }
                } -PassThru -Force

                $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                    $Global:SPDscAppServiceUpdateCalled = $true
                } -PassThru
                return $spServiceApp
            }
            Mock -CommandName Get-SPServiceApplicationPool -MockWith {
                @{ Name = $testParams.ApplicationPool } }

            It "Should return false when the test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPDscAppServiceUpdateCalled = $false
            It "Should call the update service app cmdlet from the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Get-SPServiceApplicationPool
                $Global:SPDscAppServiceUpdateCalled | Should Be $true
            }
        }

        Context -Name "When a service application exists and it should, but no proxy exists" -Fixture {
            $testParams = @{
                Name            = "Test App"
                ApplicationPool = "Test App Pool"
                DatabaseName    = "Test_DB"
                Ensure          = "Present"
                DatabaseServer  = "TestServer\Instance"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith {
                $spServiceApp = [PSCustomObject]@{
                    TypeName        = "App Management Service Application"
                    DisplayName     = $testParams.Name
                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                    Database        = @{
                        Name                 = $testParams.DatabaseName
                        NormalizedDataSource = $testParams.DatabaseServer
                    }
                }
                $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                    return @{ FullName = $getTypeFullName }
                } -PassThru -Force
                $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name IsConnected -Value {
                    return $false
                } -PassThru -Force

                $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                    $Global:SPDscAppServiceUpdateCalled = $true
                } -PassThru
                return $spServiceApp
            }
            Mock -CommandName Get-SPServiceApplicationPool -MockWith {
                @{ Name = $testParams.ApplicationPool } }
            Mock -CommandName New-SPAppManagementServiceApplicationProxy -MockWith { return $null }

            It "Should return an empty ProxyName from the get method" {
                (Get-TargetResource @testParams).ProxyName | Should Be ""
            }

            It "Should return false when the test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call the update service app cmdlet from the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPAppManagementServiceApplicationProxy
            }
        }

        Context -Name "When a service app needs to be created and no database paramsters are provided" -Fixture {
            $testParams = @{
                Name            = "Test App"
                ApplicationPool = "Test App Pool"
                Ensure          = "Present"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { return $null }
            Mock -CommandName New-SPAppManagementServiceApplication -MockWith { return  @(@{ }) }
            Mock -CommandName New-SPAppManagementServiceApplicationProxy -MockWith { return $null }

            It "Should not throw an exception in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPAppManagementServiceApplication
            }
        }

        Context -Name "When the service application exists but it shouldn't" -Fixture {
            $testParams = @{
                Name            = "Test App"
                ApplicationPool = "-"
                Ensure          = "Absent"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith {
                $spServiceApp = [PSCustomObject]@{
                    TypeName        = "App Management Service Application"
                    DisplayName     = $testParams.Name
                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                    Database        = @{
                        Name                 = $testParams.DatabaseName
                        NormalizedDataSource = $testParams.DatabaseServer
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

            It "Should return false when the test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call the remove service application cmdlet in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPServiceApplication
            }
        }

        Context -Name "When the serivce application doesn't exist and it shouldn't" -Fixture {
            $testParams = @{
                Name            = "Test App"
                ApplicationPool = "-"
                Ensure          = "Absent"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { return $null }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should returns true when the test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
