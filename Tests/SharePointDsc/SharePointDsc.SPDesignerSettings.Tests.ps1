[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPDesignerSettings"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPDesignerSettings - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            Url = "https://intranet.sharepoint.contoso.com"
            SettingsScope = "WebApplication"
            AllowSharePointDesigner = $false
            AllowDetachPagesFromDefinition = $false
            AllowCustomiseMasterPage = $false
            AllowManageSiteURLStructure = $false
            AllowCreateDeclarativeWorkflow = $false
            AllowSavePublishDeclarativeWorkflow = $false
            AllowSaveDeclarativeWorkflowAsTemplate = $false
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\SharePointDsc")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue

        Context "The server is not part of SharePoint farm" {
            Mock Get-SPFarm { throw "Unable to detect local farm" }

            It "return null from the get method" {
                Get-TargetResource @testParams | Should Be $null
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "throws an exception in the set method to say there is no local farm" {
                { Set-TargetResource @testParams } | Should throw "No local SharePoint farm was detected"
            }
        }

        Context "The server is in a farm, target web application and the incorrect settings have been applied" {
            Mock Get-SPDesignerSettings { return @{
                    AllowDesigner = $true
                    AllowRevertFromTemplate = $true
                    AllowMasterPageEditing = $true
                    ShowURLStructure = $true
                    AllowCreateDeclarativeWorkflow = $true
                    AllowSavePublishDeclarativeWorkflow = $true
                    AllowSaveDeclarativeWorkflowAsTemplate = $true
                } 
            }
            
            Mock Get-SPWebApplication { 
                $result = @{}
                $result.DisplayName = "Test"
                $result.Url = "https://intranet.sharepoint.contoso.com"

                $result = $result | Add-Member ScriptMethod Update { $Global:SPDSCDesignerUpdated = $true } -PassThru

                return $result
            }
            
            Mock Get-SPFarm { return @{} }
            
            It "return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPDSCDesignerUpdated = $false
            It "updates the SharePoint Designer settings" {
                Set-TargetResource @testParams
                $Global:SPDSCDesignerUpdated | Should Be $true
            }
        }

        Context "The server is in a farm, target site collection and the incorrect settings have been applied" {
            $testParams = @{
                Url = "https://intranet.sharepoint.contoso.com"
                SettingsScope = "SiteCollection"
                AllowSharePointDesigner = $false
                AllowDetachPagesFromDefinition = $false
                AllowCustomiseMasterPage = $false
                AllowManageSiteURLStructure = $false
                AllowCreateDeclarativeWorkflow = $false
                AllowSavePublishDeclarativeWorkflow = $false
                AllowSaveDeclarativeWorkflowAsTemplate = $false
            }
            Mock Get-SPSite {
                return @{
                        Url = "https://intranet.sharepoint.contoso.com"
                        AllowDesigner = $true
                        AllowRevertFromTemplate = $true
                        AllowMasterPageEditing = $true
                        ShowURLStructure = $true
                        AllowCreateDeclarativeWorkflow = $true
                        AllowSavePublishDeclarativeWorkflow = $true
                        AllowSaveDeclarativeWorkflowAsTemplate = $true
                } 
            }

            Mock Test-SPDSCRunAsCredential { return $true }

            Mock Get-SPFarm { return @{} }

            It "return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "updates the SharePoint Designer settings" {
                Set-TargetResource @testParams
            }
        }

        Context "The server is in a farm, target site collection and InstallAccount is used" {
            $testParams = @{
                Url = "https://intranet.sharepoint.contoso.com"
                SettingsScope = "SiteCollection"
                AllowSharePointDesigner = $false
                AllowDetachPagesFromDefinition = $false
                AllowCustomiseMasterPage = $false
                AllowManageSiteURLStructure = $false
                AllowCreateDeclarativeWorkflow = $false
                AllowSavePublishDeclarativeWorkflow = $false
                AllowSaveDeclarativeWorkflowAsTemplate = $false
            }
            Mock Get-SPSite {
                return @{
                        Url = "https://intranet.sharepoint.contoso.com"
                        AllowDesigner = $true
                        AllowRevertFromTemplate = $true
                        AllowMasterPageEditing = $true
                        ShowURLStructure = $true
                        AllowCreateDeclarativeWorkflow = $true
                        AllowSavePublishDeclarativeWorkflow = $true
                        AllowSaveDeclarativeWorkflowAsTemplate = $true
                } 
            }
            Mock Test-SPDSCRunAsCredential { return $false }

            Mock Get-SPFarm { return @{} }

            It "throws an exception in the get method to say that this is not supported" {
                { Get-TargetResource @testParams } | Should throw "http://aka.ms/xSharePointRemoteIssues"
            }

            It "throws an exception in the test method to say that this is not supported" {
                { Test-TargetResource @testParams } | Should throw "http://aka.ms/xSharePointRemoteIssues"
            }

            It "throws an exception in the set method to say that this is not supported" {
                { Set-TargetResource @testParams } | Should throw "http://aka.ms/xSharePointRemoteIssues"
            }
        }

        Context "The server is in a farm, target is web application and the correct settings have been applied" {
            Mock Get-SPDesignerSettings {
                $returnVal = @{
                    AllowDesigner = $false
                    AllowRevertFromTemplate = $false
                    AllowMasterPageEditing = $false
                    ShowURLStructure = $false
                    AllowCreateDeclarativeWorkflow = $false
                    AllowSavePublishDeclarativeWorkflow = $false
                    AllowSaveDeclarativeWorkflowAsTemplate = $false
                } 
                $returnVal = $returnVal | Add-Member ScriptMethod Update { $Global:SPDSCDesignerUpdated = $true } -PassThru
                return $returnVal
            }
            
            Mock Get-SPWebApplication { 
                $result = @{}
                $result.DisplayName = "Test"
                $result.Url = "https://intranet.sharepoint.contoso.com"

                return $result
            }

            Mock Get-SPFarm { return @{} }

            It "return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }

        }

        Context "The server is in a farm, target is site collection and the correct settings have been applied" {
            $testParams = @{
                Url = "https://intranet.sharepoint.contoso.com"
                SettingsScope = "SiteCollection"
                AllowSharePointDesigner = $false
                AllowDetachPagesFromDefinition = $false
                AllowCustomiseMasterPage = $false
                AllowManageSiteURLStructure = $false
                AllowCreateDeclarativeWorkflow = $false
                AllowSavePublishDeclarativeWorkflow = $false
                AllowSaveDeclarativeWorkflowAsTemplate = $false
            }

            Mock Get-SPSite {
                $returnVal = @{
                        Url = "https://intranet.sharepoint.contoso.com"
                        AllowDesigner = $false
                        AllowRevertFromTemplate = $false
                        AllowMasterPageEditing = $false
                        ShowURLStructure = $false
                        AllowCreateDeclarativeWorkflow = $false
                        AllowSavePublishDeclarativeWorkflow = $false
                        AllowSaveDeclarativeWorkflowAsTemplate = $false
                } 
                $returnVal = $returnVal | Add-Member ScriptMethod Update { $Global:SPDSCDesignerUpdated = $true } -PassThru
                return $returnVal
            }

            Mock Test-SPDSCRunAsCredential { return $true }

            Mock Get-SPFarm { return @{} }

            It "return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }
}
