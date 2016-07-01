[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPQuotaTemplate"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDSC\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPQuotaTemplate - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Test"
            StorageMaxInMB = 1024
            StorageWarningInMB = 512
            MaximumUsagePointsSolutions = 1000
            WarningUsagePointsSolutions = 800
            Ensure = "Present"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\SharePointDSC")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue

        Add-Type -TypeDefinition "namespace Microsoft.SharePoint.Administration { public class SPQuotaTemplate { public string Name { get; set; } public long StorageMaximumLevel { get; set; } public long StorageWarningLevel { get; set; } public double UserCodeMaximumLevel { get; set; } public double UserCodeWarningLevel { get; set; }}}"

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

        Context "The server is in a farm and the incorrect settings have been applied to the template" {
            Mock Get-SPDSCContentService {
                $quotaTemplates = @(@{
                        Test = @{
                            StorageMaximumLevel = 512
                            StorageWarningLevel = 256
                            UserCodeMaximumLevel = 400
                            UserCodeWarningLevel = 200
                        }
                    })
                $quotaTemplatesCol = {$quotaTemplates}.Invoke() 

                
                $contentService = @{
                    QuotaTemplates = $quotaTemplatesCol
                } 

                $contentService = $contentService | Add-Member ScriptMethod Update { $Global:SPDSCQuotaTemplatesUpdated = $true } -PassThru
                return $contentService
            }

            Mock Get-SPFarm { return @{} }

            It "return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPDSCQuotaTemplatesUpdated = $false
            It "updates the quota template settings" {
                Set-TargetResource @testParams
                $Global:SPDSCQuotaTemplatesUpdated | Should Be $true
            }
        }

        Context "The server is in a farm and the template doesn't exist" {
            Mock Get-SPDSCContentService {
                $quotaTemplates = @(@{
                        Test = $null
                    })
                $quotaTemplatesCol = {$quotaTemplates}.Invoke() 

                
                $contentService = @{
                    QuotaTemplates = $quotaTemplatesCol
                } 

                $contentService = $contentService | Add-Member ScriptMethod Update { $Global:SPDSCQuotaTemplatesUpdated = $true } -PassThru
                return $contentService
            }

            Mock Get-SPFarm { return @{} }

            It "return values from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be 'Absent'
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPDSCQuotaTemplatesUpdated = $false
            It "creates a new quota template" {
                Set-TargetResource @testParams
                $Global:SPDSCQuotaTemplatesUpdated | Should Be $true
            }
        }

        Context "The server is in a farm and the correct settings have been applied" {
             Mock Get-SPDSCContentService { 
                 $returnVal = @{ 
                     QuotaTemplates = @{ 
                         Test = @{ 
                             StorageMaximumLevel = 1073741824 
                             StorageWarningLevel = 536870912 
                             UserCodeMaximumLevel = 1000 
                             UserCodeWarningLevel = 800 
                         } 
                     } 
                 }  
                 $returnVal = $returnVal | Add-Member ScriptMethod Update { $Global:SPDSCQuotaTemplatesUpdated = $true } -PassThru 
                 return $returnVal 
             } 


            Mock Get-SPFarm { return @{} }

            It "return values from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be 'Present'
                $result.StorageMaxInMB | Should Be 1024
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }

        }
    }
}
