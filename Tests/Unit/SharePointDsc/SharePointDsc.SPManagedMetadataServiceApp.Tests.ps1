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
                                              -DscResource "SPManagedMetaDataServiceApp"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        #Initialize Tests
        $getTypeFullName = "Microsoft.SharePoint.Taxonomy.MetadataWebServiceApplication"

        # Mocks for all contexts
        Mock -CommandName New-SPMetadataServiceApplication -MockWith { return @{} }
        Mock -CommandName New-SPMetadataServiceApplicationProxy -MockWith { return @{} }
        Mock -CommandName Set-SPMetadataServiceApplication -MockWith { }
        Mock -CommandName Remove-SPServiceApplication -MockWith { }   

        # Test contexts
        Context -Name "When no service applications exist in the current farm" -Fixture {
            $testParams = @{
                Name = "Managed Metadata Service App"
                ApplicationPool = "SharePoint Service Applications"
                DatabaseServer = "databaseserver\instance"
                DatabaseName = "SP_MMS"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { return $null }

            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should create a new service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPMetadataServiceApplication
            }
        }

        Context -Name "When service applications exist in the current farm but the specific MMS app does not" -Fixture {
            $testParams = @{
                Name = "Managed Metadata Service App"
                ApplicationPool = "SharePoint Service Applications"
                DatabaseServer = "databaseserver\instance"
                DatabaseName = "SP_MMS"
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
                Name = "Managed Metadata Service App"
                ApplicationPool = "SharePoint Service Applications"
                DatabaseServer = "databaseserver\instance"
                DatabaseName = "SP_MMS"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                $spServiceApp = [PSCustomObject]@{ 
                    TypeName = "Managed Metadata Service"
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
                        return (@{ 
                            FullName = $getTypeFullName 
                        }) | Add-Member -MemberType ScriptMethod -Name GetMethods -Value {
                            return (@(
                                Name = "GetContentTypeSyndicationHubLocal"
                            )) | Add-Member -MemberType ScriptMethod -Name Invoke -Value {
                                return @{
                                    AbsoluteUri = ""
                                }
                            } -PassThru -Force
                        } -PassThru -Force 
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
                Name = "Managed Metadata Service App"
                ApplicationPool = "SharePoint Service Applications"
                DatabaseServer = "databaseserver\instance"
                DatabaseName = "SP_MMS"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                $spServiceApp = [PSCustomObject]@{
                    TypeName = "Managed Metadata Service"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ 
                        Name = "Wrong App Pool Name" 
                    }
                    Database = @{
                        Name = $testParams.DatabaseName
                        Server = @{ 
                            Name = $testParams.DatabaseServer 
                        }
                    }
                }
                $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value { 
                        return (@{ 
                            FullName = $getTypeFullName 
                        }) | Add-Member -MemberType ScriptMethod -Name GetMethods -Value {
                            return (@(
                                Name = "GetContentTypeSyndicationHubLocal"
                            )) | Add-Member -MemberType ScriptMethod -Name Invoke -Value {
                                return @{
                                    AbsoluteUri = ""
                                }
                            } -PassThru -Force
                        } -PassThru -Force 
                    } -PassThru -Force
                return $spServiceApp
            }

            Mock -CommandName Get-SPServiceApplicationPool -MockWith { 
                return @{ 
                    Name = $testParams.ApplicationPool 
                } 
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call the update service app cmdlet from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Get-SPServiceApplicationPool
                Assert-MockCalled Set-SPMetadataServiceApplication -ParameterFilter { 
                    $ApplicationPool.Name -eq $testParams.ApplicationPool 
                }
            }
        }

        Context -Name "When a service application exists and the content type hub is not configured correctly" -Fixture {
            $testParams = @{
                Name = "Managed Metadata Service App"
                ApplicationPool = "SharePoint Service Applications"
                DatabaseServer = "databaseserver\instance"
                DatabaseName = "SP_MMS"
                ContentTypeHubUrl = "https://contenttypes.contoso.com"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                $spServiceApp = [PSCustomObject]@{
                    TypeName = "Managed Metadata Service"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ 
                        Name = $testParams.AookucationPool
                    }
                    Database = @{
                        Name = $testParams.DatabaseName
                        Server = @{ 
                            Name = $testParams.DatabaseServer 
                        }
                    }
                }
                $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value { 
                        return (@{ 
                            FullName = $getTypeFullName 
                        }) | Add-Member -MemberType ScriptMethod -Name GetMethods -Value {
                            return (@(
                                Name = "GetContentTypeSyndicationHubLocal"
                            )) | Add-Member -MemberType ScriptMethod -Name Invoke -Value {
                                return @{
                                    AbsoluteUri = ""
                                }
                            } -PassThru -Force
                        } -PassThru -Force 
                    } -PassThru -Force
                return $spServiceApp
            }

            Mock -CommandName Get-SPServiceApplicationPool -MockWith { 
                return @{ 
                    Name = $testParams.ApplicationPool 
                } 
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call the update service app cmdlet from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled set-SPMetadataServiceApplication
            }
        }
        
        Context -Name "When the service application exists but it shouldn't" -Fixture {
            $testParams = @{
                Name = "Test App"
                ApplicationPool = "-"
                Ensure = "Absent"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                $spServiceApp = [PSCustomObject]@{ 
                    TypeName = "Managed Metadata Service"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ 
                        Name = "Wrong App Pool Name" 
                    }
                    Database = @{
                        Name = $testParams.DatabaseName
                        Server = @{ 
                            Name = $testParams.DatabaseServer 
                        }
                    }
                }
                $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value { 
                        return (@{ 
                            FullName = $getTypeFullName 
                        }) | Add-Member -MemberType ScriptMethod -Name GetMethods -Value {
                            return (@(
                                Name = "GetContentTypeSyndicationHubLocal"
                            )) | Add-Member -MemberType ScriptMethod -Name Invoke -Value {
                                return @{
                                    AbsoluteUri = ""
                                }
                            } -PassThru -Force
                        } -PassThru -Force 
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
        
        Context -Name "When the serivce application doesn't exist and it shouldn't" -Fixture {
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
            
            It "Should return true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
