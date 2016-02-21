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
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue    
        
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
            Mock Get-SPEnterpriseSearchServiceInstance { return @{} }
            Mock New-SPBusinessDataCatalogServiceApplication { }
            Mock Start-SPEnterpriseSearchServiceInstance { }
            Mock New-SPEnterpriseSearchServiceApplication { return @{} }
            Mock New-SPEnterpriseSearchServiceApplicationProxy { }
            Mock Set-SPEnterpriseSearchServiceApplication { } 

            It "returns null from the Get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name } 
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
            Mock Get-SPEnterpriseSearchServiceInstance { return @{} }
            Mock New-SPBusinessDataCatalogServiceApplication { }
            Mock Start-SPEnterpriseSearchServiceInstance { }
            Mock New-SPEnterpriseSearchServiceApplication { return @{} }
            Mock New-SPEnterpriseSearchServiceApplicationProxy { }
            Mock Set-SPEnterpriseSearchServiceApplication { } 
            Mock Get-SPServiceApplication { return @(@{
                TypeName = "Some other service app type"
            }) }

            It "returns null from the Get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name } 
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
            Mock Get-SPEnterpriseSearchServiceInstance { return @{} }
            Mock New-SPBusinessDataCatalogServiceApplication { }
            Mock Start-SPEnterpriseSearchServiceInstance { }
            Mock New-SPEnterpriseSearchServiceApplication { return @{} }
            Mock New-SPEnterpriseSearchServiceApplicationProxy { }
            Mock Set-SPEnterpriseSearchServiceApplication { } 
            
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

            It "returns values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name } 
            }

            It "returns true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "When a service application exists and the app pool is not configured correctly" {
            Mock Get-SPEnterpriseSearchServiceInstance { return @{} }
            Mock New-SPBusinessDataCatalogServiceApplication { }
            Mock Start-SPEnterpriseSearchServiceInstance { }
            Mock New-SPEnterpriseSearchServiceApplication { return @{} }
            Mock New-SPEnterpriseSearchServiceApplicationProxy { }

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
            
            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }    
}
