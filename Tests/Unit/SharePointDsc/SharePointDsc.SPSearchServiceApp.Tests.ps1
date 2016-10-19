[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
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
                                              -DscResource "SPSearchServiceApp"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests
        $getTypeFullName = "Microsoft.Office.Server.Search.Administration.SearchServiceApplication"

        Add-Type -TypeDefinition @"
            namespace Microsoft.Office.Server.Search.Administration {
                public static class SearchContext {
                    public static object GetContext(object site) {
                        return null;
                    }
                }
            }
"@
        
        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
        $mockCredential = New-Object -TypeName System.Management.Automation.PSCredential `
                                     -ArgumentList @("DOMAIN\username", $mockPassword)

        # Mocks for all contexts   
        Mock -CommandName Start-SPEnterpriseSearchServiceInstance -MockWith {}
        Mock -CommandName Remove-SPServiceApplication -MockWith {}   
        Mock -CommandName New-SPEnterpriseSearchServiceApplicationProxy -MockWith {}
        Mock -CommandName Set-SPEnterpriseSearchServiceApplication -MockWith {} 
        Mock -CommandName New-SPBusinessDataCatalogServiceApplication -MockWith { }
        Mock -CommandName Set-SPEnterpriseSearchServiceApplication -MockWith { } 
        
        Mock -CommandName Get-SPEnterpriseSearchServiceInstance -MockWith { 
            return @{} 
        }
        Mock -CommandName New-SPEnterpriseSearchServiceApplication -MockWith { 
            return @{} 
        }
        Mock -CommandName Get-SPServiceApplicationPool -MockWith { 
            return @{ 
                Name = $testParams.ApplicationPool 
            } 
        }
        Mock -CommandName Get-SPWebapplication -MockWith { 
            return @(@{
                Url = "http://centraladmin.contoso.com"
                IsAdministrationWebApplication = $true
            }) 
        }
        Mock -CommandName Get-SPSite -MockWith { 
            @{} 
        }
        Mock -CommandName New-Object -MockWith {
            return @{
                DefaultGatheringAccount = "Domain\username"
            }
        } -ParameterFilter { 
            $TypeName -eq "Microsoft.Office.Server.Search.Administration.Content" 
        }
        
        Mock Import-Module -MockWith {} -ParameterFilter { $_.Name -eq $ModuleName }

        # Test contexts
        Context -Name "When no service applications exist in the current farm" -Fixture {
            $testParams = @{
                Name = "Search Service Application"
                ApplicationPool = "SharePoint Search Services"
                Ensure = "Present"
            }

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
                Assert-MockCalled New-SPEnterpriseSearchServiceApplication 
            }
        }

        Context -Name "When service applications exist in the current farm but the specific search app does not" -Fixture {
            $testParams = @{
                Name = "Search Service Application"
                ApplicationPool = "SharePoint Search Services"
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

            It "Should create a new service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPEnterpriseSearchServiceApplication 
            }
        }

        Context -Name "When a service application exists and is configured correctly" -Fixture {
            $testParams = @{
                Name = "Search Service Application"
                ApplicationPool = "SharePoint Search Services"
                Ensure = "Present"
            }
            
            Mock -CommandName Get-SPServiceApplication -MockWith { 
                $spServiceApp = [PSCustomObject]@{
                    TypeName = "Search Service Application"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
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
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name } 
            }

            It "Should return true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "When a service application exists and the app pool is not configured correctly" -Fixture {
            $testParams = @{
                Name = "Search Service Application"
                ApplicationPool = "SharePoint Search Services"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                $spServiceApp = [PSCustomObject]@{
                    TypeName = "Search Service Application"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = "Wrong App Pool Name" }
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
                Assert-MockCalled Set-SPEnterpriseSearchServiceApplication
            }
        }
        
        Context -Name "When the default content access account does not match" -Fixture {    
            $testParams = @{
                Name = "Search Service Application"
                ApplicationPool = "SharePoint Search Services"
                Ensure = "Present"
                DefaultContentAccessAccount = $mockCredential
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                $spServiceApp = [PSCustomObject]@{
                    TypeName = "Search Service Application"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
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
            
            Mock -CommandName New-Object -MockWith {
                return @{
                    DefaultGatheringAccount = "WRONG\username"
                }
            } -ParameterFilter { 
                $TypeName -eq "Microsoft.Office.Server.Search.Administration.Content" 
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "changes the content access account" {
                Set-TargetResource @testParams 

                Assert-MockCalled Get-SPServiceApplicationPool
                Assert-MockCalled Set-SPEnterpriseSearchServiceApplication
            }
        }
        
        Context -Name "When the default content access account does match" -Fixture {    
            $testParams = @{
                Name = "Search Service Application"
                ApplicationPool = "SharePoint Search Services"
                Ensure = "Present"
                DefaultContentAccessAccount = $mockCredential
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                $spServiceApp = [PSCustomObject]@{
                    TypeName = "Search Service Application"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ 
                        Name = $testParams.ApplicationPool 
                    }
                    Database = @{
                        Name = $testParams.DatabaseName
                        Server = @{ 
                            Name = $testParams.DatabaseServer 
                        }
                    }
                }
                $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value { 
                    return @{ FullName = $getTypeFullName } 
                } -PassThru -Force
                return $spServiceApp
            }
            
            Mock -CommandName New-Object -MockWith {
                return @{
                    DefaultGatheringAccount = "DOMAIN\username"
                }
            } -ParameterFilter { 
                $TypeName -eq "Microsoft.Office.Server.Search.Administration.Content" 
            }
            
            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        Context -Name "When the search center URL does not match" -Fixture {
            $testParams = @{
                Name = "Search Service Application"
                ApplicationPool = "SharePoint Search Services"
                Ensure = "Present"
                SearchCenterUrl = "http://search.sp.contoso.com"
            }

            $Global:SPDscSearchURLUpdated = $false

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                $spServiceApp = [PSCustomObject]@{
                    TypeName = "Search Service Application"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                    SearchCenterUrl = "http://wrong.url.here"
                    Database = @{
                        Name = $testParams.DatabaseName
                        Server = @{ Name = $testParams.DatabaseServer }
                    }
                }
                $spServiceApp = $spServiceApp | Add-Member ScriptMethod Update {
                    $Global:SPDscSearchURLUpdated = $true
                } -PassThru
                $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value { 
                    return @{ FullName = $getTypeFullName } 
                } -PassThru -Force
                return $spServiceApp
            }

            Mock -CommandName Get-SPServiceApplicationPool -MockWith { 
                return @{ 
                    Name = $testParams.ApplicationPool 
                } 
            }
            
            Mock -CommandName Get-SPWebapplication -MockWith { 
                return @(@{
                    Url = "http://centraladmin.contoso.com"
                    IsAdministrationWebApplication = $true
                }) 
            }

            Mock -CommandName Get-SPSite -MockWith { @{} }
            
            Mock -CommandName New-Object -MockWith {
                return @{
                    DefaultGatheringAccount = "Domain\username"
                }
            } -ParameterFilter { 
                $TypeName -eq "Microsoft.Office.Server.Search.Administration.Content" 
            }
            
            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "Should update the service app in the set method" {
                Set-TargetResource @testParams
                $Global:SPDscSearchURLUpdated | Should Be $true
            }
        }
        
        Context -Name "When the search center URL does match" -Fixture {
            $testParams = @{
                Name = "Search Service Application"
                ApplicationPool = "SharePoint Search Services"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPServiceApplicationPool -MockWith { 
                return @{ 
                    Name = $testParams.ApplicationPool 
                } 
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                $spServiceApp = [PSCustomObject]@{
                    TypeName = "Search Service Application"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                    SearchCenterUrl = "http://search.sp.contoso.com"
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
           
            Mock -CommandName Get-SPWebapplication -MockWith { 
                return @(@{
                    Url = "http://centraladmin.contoso.com"
                    IsAdministrationWebApplication = $true
                }) 
            }

            Mock -CommandName Get-SPSite -MockWith { 
                return @{} 
            }
            
            Mock -CommandName New-Object {
                return @{
                    DefaultGatheringAccount = "Domain\username"
                }
            } -ParameterFilter { 
                $TypeName -eq "Microsoft.Office.Server.Search.Administration.Content" 
            }
            
            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        Context -Name "When the service app exists but it shouldn't" -Fixture {
            $testParams = @{
                Name = "Search Service Application"
                ApplicationPool = "SharePoint Search Services"
                Ensure = "Absent"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                $spServiceApp = [PSCustomObject]@{
                    TypeName = "Search Service Application"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ 
                        Name = $testParams.ApplicationPool 
                    }
                    Database = @{
                        Name = $testParams.DatabaseName
                        Server = @{ 
                            Name = $testParams.DatabaseServer 
                        }
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
                Name = "Search Service Application"
                ApplicationPool = "SharePoint Search Services"
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
        
        Context -Name "When the service app exists and is cloud enabled" -Fixture {
            $testParams = @{
                Name = "Search Service Application"
                ApplicationPool = "SharePoint Search Services"
                Ensure = "Present"
                CloudIndex = $true
            }
            
            Mock -CommandName Get-SPServiceApplication -MockWith { 
                $spServiceApp = [PSCustomObject]@{
                    TypeName = "Search Service Application"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                    CloudIndex = $true
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

            Mock -CommandName Get-SPDSCInstalledProductVersion -MockWith { 
                return @{ 
                    FileMajorPart = 15
                    FileBuildPart = 0 
                } 
            }
            
            It "Should return false if the version is too low" {
                (Get-TargetResource @testParams).CloudIndex | Should Be $false
            }
            
            Mock -CommandName Get-SPDSCInstalledProductVersion -MockWith { 
                return @{ 
                    FileMajorPart = 15
                    FileBuildPart = 5000 
                } 
            }
            
            It "Should return that the web app is hybrid enabled from the get method" {
                (Get-TargetResource @testParams).CloudIndex | Should Be $true
            }
        }
        
        Context -Name "When the service doesn't exist and it should be cloud enabled" -Fixture {
            $testParams = @{
                Name = "Search Service Application"
                ApplicationPool = "SharePoint Search Services"
                Ensure = "Present"
                CloudIndex = $true
            }
            
            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return $null 
            }
            
            Mock -CommandName Get-SPDSCInstalledProductVersion -MockWith { 
                return @{ 
                    FileMajorPart = 15
                    FileBuildPart = 5000 
                }
            }
            
            It "Should create the service app in the set method" {
                Set-TargetResource @testParams
            }
            
            Mock -CommandName Get-SPDSCInstalledProductVersion -MockWith { 
                return @{ 
                    FileMajorPart = 15
                    FileBuildPart = 0 
                } 
            }
            
            It "Should throw an error in the set method if the version of SharePoint isn't high enough" {
                { Set-TargetResource @testParams } | Should Throw
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
