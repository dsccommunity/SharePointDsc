[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_xSPSearchServiceApp"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPSearchServiceApp" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Search Service Application"
            ApplicationPool = "SharePoint Search Services"
            Ensure = "Present"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue
        
        Mock Start-SPEnterpriseSearchServiceInstance {}
        Mock Remove-SPServiceApplication {}   
        Mock New-SPEnterpriseSearchServiceApplicationProxy {}
        Mock Set-SPEnterpriseSearchServiceApplication {} 
        Mock Get-SPEnterpriseSearchServiceInstance { return @{} }
        Mock New-SPEnterpriseSearchServiceApplication { return @{} }
        Mock Get-SPServiceApplicationPool { return @{ Name = $testParams.ApplicationPool } }
        
        Add-Type -TypeDefinition @"
            namespace Microsoft.Office.Server.Search.Administration {
                public static class SearchContext {
                    public static object GetContext(object site) {
                        return null;
                    }
                }
            }
"@

            Mock Get-SPWebApplication { return @(@{
                Url = "http://centraladmin.contoso.com"
                IsAdministrationWebApplication = $true
            }) }
            Mock Get-SPSite { @{} }
            
            Mock New-Object {
                return @{
                    DefaultGatheringAccount = "DOMAIN\username"
                }
            } -ParameterFilter { $TypeName -eq "Microsoft.Office.Server.Search.Administration.Content" }

        Context "When no service applications exist in the current farm" {

            Mock Get-SPServiceApplication { return $null }
            
            It "returns absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }

            It "returns false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "creates a new service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPEnterpriseSearchServiceApplication 
            }

            $testParams.Add("InstallAccount", (New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))))
            It "creates a new service application in the set method where InstallAccount is used" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPEnterpriseSearchServiceApplication 
            }
            $testParams.Remove("InstallAccount")
        }

        Context "When service applications exist in the current farm but the specific search app does not" {

            Mock Get-SPServiceApplication { return @(@{
                TypeName = "Some other service app type"
            }) }

            It "returns absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }

            It "returns false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "creates a new service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPEnterpriseSearchServiceApplication 
            }
        }

        Context "When a service application exists and is configured correctly" {
            
            Mock Get-SPServiceApplication { 
                return @(@{
                    TypeName = "Search Service Application"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                    Database = @{
                        Name = $testParams.DatabaseName
                        Server = @{ Name = $testParams.DatabaseServer }
                    }
                })
            }

            It "returns present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name } 
            }

            It "returns true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "When a service application exists and the app pool is not configured correctly" {

            Mock Get-SPServiceApplication { 
                return @(@{
                    TypeName = "Search Service Application"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = "Wrong App Pool Name" }
                    Database = @{
                        Name = $testParams.DatabaseName
                        Server = @{ Name = $testParams.DatabaseServer }
                    }
                })
            }
            Mock Get-SPServiceApplicationPool { return @{ Name = $testParams.ApplicationPool } }
            Mock Set-SPEnterpriseSearchServiceApplication { } 

            It "returns false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "calls the update service app cmdlet from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Get-SPServiceApplicationPool
                Assert-MockCalled Set-SPEnterpriseSearchServiceApplication
            }
        }
        
        $testParams.Add("DefaultContentAccessAccount", (New-Object System.Management.Automation.PSCredential ("DOMAIN\username", (ConvertTo-SecureString "password" -AsPlainText -Force))))
        
        Context "When the default content access account does not match" {    
            Mock Get-SPServiceApplication { 
                return @(@{
                    TypeName = "Search Service Application"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                    Database = @{
                        Name = $testParams.DatabaseName
                        Server = @{ Name = $testParams.DatabaseServer }
                    }
                })
            }
            
            Mock New-Object {
                return @{
                    DefaultGatheringAccount = "DOESNOT\match"
                }
            } -ParameterFilter { $TypeName -eq "Microsoft.Office.Server.Search.Administration.Content" }
            
            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "changes the content access account" {
                Set-TargetResource @testParams 

                Assert-MockCalled Get-SPServiceApplicationPool
                Assert-MockCalled Set-SPEnterpriseSearchServiceApplication
            }
        }
        
        Context "When the default content access account does match" {    
            Mock Get-SPServiceApplication { 
                return @(@{
                    TypeName = "Search Service Application"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                    Database = @{
                        Name = $testParams.DatabaseName
                        Server = @{ Name = $testParams.DatabaseServer }
                    }
                })
            }
            
            Mock New-Object {
                return @{
                    DefaultGatheringAccount = "DOMAIN\username"
                }
            } -ParameterFilter { $TypeName -eq "Microsoft.Office.Server.Search.Administration.Content" }
            
            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        $testParams.Add("SearchCenterUrl", "http://search.sp.contoso.com")
        $Global:xSharePointSearchURLUpdated = $false
        Context "When the search center URL does not match" {
            Mock Get-SPServiceApplication { 
                return @(@{
                    TypeName = "Search Service Application"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                    Database = @{
                        Name = $testParams.DatabaseName
                        Server = @{ Name = $testParams.DatabaseServer }
                    }
                    SearchCenterUrl = "http://wrong.url.here"
                } | Add-Member ScriptMethod Update {
                    $Global:xSharePointSearchURLUpdated = $true
                } -PassThru)
            }
            Mock Get-SPServiceApplicationPool { return @{ Name = $testParams.ApplicationPool } }
            Mock Get-SPEnterpriseSearchServiceInstance { return @{} }
            Mock New-SPBusinessDataCatalogServiceApplication { }
            Mock Start-SPEnterpriseSearchServiceInstance { }
            Mock New-SPEnterpriseSearchServiceApplication { return @{} }
            Mock New-SPEnterpriseSearchServiceApplicationProxy { }
            Mock Set-SPEnterpriseSearchServiceApplication { } 
            
            Mock Get-SPWebApplication { return @(@{
                Url = "http://centraladmin.contoso.com"
                IsAdministrationWebApplication = $true
            }) }
            Mock Get-SPSite { @{} }
            
            Mock New-Object {
                return @{
                    DefaultGatheringAccount = "DOMAIN\username"
                }
            } -ParameterFilter { $TypeName -eq "Microsoft.Office.Server.Search.Administration.Content" }
            
            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "should update the service app in the set method" {
                Set-TargetResource @testParams
                $Global:xSharePointSearchURLUpdated | Should Be $true
            }
        }
        
        Context "When the search center URL does match" {
            Mock Get-SPServiceApplication { 
                return @(@{
                    TypeName = "Search Service Application"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                    Database = @{
                        Name = $testParams.DatabaseName
                        Server = @{ Name = $testParams.DatabaseServer }
                    }
                    SearchCenterUrl = "http://search.sp.contoso.com"
                })
            }
            Mock Get-SPServiceApplicationPool { return @{ Name = $testParams.ApplicationPool } }
            Mock Get-SPEnterpriseSearchServiceInstance { return @{} }
            Mock New-SPBusinessDataCatalogServiceApplication { }
            Mock Start-SPEnterpriseSearchServiceInstance { }
            Mock New-SPEnterpriseSearchServiceApplication { return @{} }
            Mock New-SPEnterpriseSearchServiceApplicationProxy { }
            Mock Set-SPEnterpriseSearchServiceApplication { } 
            
            Mock Get-SPWebApplication { return @(@{
                Url = "http://centraladmin.contoso.com"
                IsAdministrationWebApplication = $true
            }) }
            Mock Get-SPSite { @{} }
            
            Mock New-Object {
                return @{
                    DefaultGatheringAccount = "DOMAIN\username"
                }
            } -ParameterFilter { $TypeName -eq "Microsoft.Office.Server.Search.Administration.Content" }
            
            It "should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        $testParams.Ensure = "Absent"
        
        Context "When the service app exists but it shouldn't" {
            Mock Get-SPServiceApplication { 
                return @(@{
                    TypeName = "Search Service Application"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                    Database = @{
                        Name = $testParams.DatabaseName
                        Server = @{ Name = $testParams.DatabaseServer }
                    }
                })
            }
            
            It "returns present from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present" 
            }
            
            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "should remove the service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPServiceApplication
            }
        }
        
        Context "When the service app doesn't exist and shouldn't" {
            Mock Get-SPServiceApplication { return $null }
            
            It "returns absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }
            
            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }    
}
