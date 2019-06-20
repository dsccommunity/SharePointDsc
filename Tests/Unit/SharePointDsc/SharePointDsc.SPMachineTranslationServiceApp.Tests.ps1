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
                                              -DscResource "SPMachineTranslationServiceApp"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        #Initialize Tests
        $getTypeFullName = "Microsoft.Office.TranslationServices.TranslationServiceApplication"

        # Mocks for all contexts
        Mock -CommandName New-SPTranslationServiceApplication -MockWith { return @{} }
        Mock -CommandName Get-SPServiceApplication -MockWith { }
        Mock -CommandName Remove-SPServiceApplication -MockWith { }

        # Test contexts
        Context -Name "When no service applications exist in the current farm" -Fixture {
            $testParams = @{
                Name = "Translation Service"
                ProxyName = "Machine Translation Service App Proxy"
                ApplicationPool = "SharePoint Service Applications"
                DatabaseServer = "SPDB"
                DatabaseName = "Translation"
                Ensure = "Present"
            }

            Mock -CommandName New-SPTranslationServiceApplication -MockWith {
                $returnVal = @{
                    Name = $testParams.Name
                }
                $returnVal = $returnVal | Add-Member -MemberType ScriptMethod `
                                                     -Name IsConnected -Value {
                                                            return $true
                                                        } -PassThru

                return $returnVal
            }
            Mock -CommandName Get-SPServiceApplication -MockWith { return $null }
            Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                $proxiesToReturn = @()
                $proxy = @{
                    Name = $testParams.ProxyName
                    DisplayName = $testParams.ProxyName
                }
                $proxy = $proxy | Add-Member -MemberType ScriptMethod `
                                                -Name Delete `
                                                -Value {} `
                                                -PassThru
                $proxiesToReturn +=  $proxy

                return $proxiesToReturn
            }

            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should create a new service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPTranslationServiceApplication
            }
        }

        Context -Name "When service applications exist in the current farm but the specific Translation app does not" -Fixture {
            $testParams = @{
                Name = "Translation Service"
                ApplicationPool = "SharePoint Service Applications"
                DatabaseServer = "SPDB"
                DatabaseName = "Translation"
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

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context -Name "When a service application exists and is configured correctly" -Fixture {
            $testParams = @{
                Name = "Translation Service"
                ProxyName = "Machine Translation Service App Proxy"
                ApplicationPool = "SharePoint Service Applications"
                DatabaseServer = "SPDB"
                DatabaseName = "Translation"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith {
                $spServiceApp = [PSCustomObject]@{
                    TypeName = "Machine Translation Service"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{
                        Name = $testParams.ApplicationPool
                    }
                    Database = @{
                        Name = $testParams.DatabaseName
                        NormalizedDataSource = $testParams.DatabaseServer
                    }
                }
                $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                        return (@{
                            FullName = $getTypeFullName
                        })
                        } -PassThru -Force
                $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name IsConnected -Value {
                    return $true
                    } -PassThru -Force
                return $spServiceApp
            }

            Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                $proxiesToReturn = @()
                $proxy = @{
                    Name = $testParams.ProxyName
                    DisplayName = $testParams.ProxyName
                }
                $proxy = $proxy | Add-Member -MemberType ScriptMethod `
                                                -Name Delete `
                                                -Value {} `
                                                -PassThru
                $proxiesToReturn +=  $proxy

                return $proxiesToReturn
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
                Name = "Translation Service"
                ApplicationPool = "SharePoint Service Applications"
                DatabaseServer = "SPDB"
                DatabaseName = "Translation"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith {
                $spServiceApp = [PSCustomObject]@{
                    TypeName = "Machine Translation Service"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{
                        Name = "Wrong App Pool Name"
                    }
                    Database = @{
                        Name = $testParams.DatabaseName
                        NormalizedDataSource = $testParams.DatabaseServer
                    }
                }
                $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                        return (@{
                            FullName = $getTypeFullName
                        })
                 } -PassThru -Force
                return $spServiceApp
            }

            Mock -CommandName Get-SPServiceApplicationPool -MockWith {
                return @{
                    Name = $testParams.ApplicationPool
                }
            }

            Mock -CommandName Set-SPTranslationServiceApplication -MockWith {

            }

            It "Should return present from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call the set service app cmdlet from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Get-SPServiceApplication
                Assert-MockCalled  Set-SPTranslationServiceApplication
           }
        }

        Context -Name "When the service application exists but it shouldn't" -Fixture {
            $testParams = @{
                Name = "Translation Service"
                ApplicationPool = "SharePoint Service Applications"
                DatabaseServer = "SPDB"
                DatabaseName = "Translation"
                Ensure = "Absent"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith {
                $spServiceApp = [PSCustomObject]@{
                    TypeName = "Machine Translation Service"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{
                        Name = "Wrong App Pool Name"
                    }
                    Database = @{
                        Name = $testParams.DatabaseName
                        NormalizedDataSource = $testParams.DatabaseServer
                    }
                }
                $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                        return (@{
                            FullName = $getTypeFullName
                        })
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

                Assert-MockCalled Get-SPServiceApplication
                Assert-MockCalled Remove-SPServiceApplication
            }
        }

        Context -Name "When the service application doesn't exist and it shouldn't" -Fixture {
            $testParams = @{
                Name = "Translation Service"
                ApplicationPool = "SharePoint Service Applications"
                DatabaseServer = "SPDB"
                DatabaseName = "Translation"
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
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
