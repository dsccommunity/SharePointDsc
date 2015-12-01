[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_xSPQuotaTemplate"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPQuotaTemplate" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Test"
            StorageMaxInMB = 1024
            StorageWarningInMB = 512
            MaximumUsagePointsSolutions = 1000
            WarningUsagePointsSolutions = 800
            Ensure = "Present"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
                
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

        Context "The server is in a farm and the incorrect settings have been applied" {
            Mock Get-xSharePointContentService {
                $returnVal = @{
                    QuotaTemplates = @{
                        Test = @{
                            StorageMaximumLevel = 512
                            StorageWarningLevel = 256
                            UserCodeMaximumLevel = 400
                            UserCodeWarningLevel = 200
                        }
                    }
                } 
                $returnVal = $returnVal | Add-Member ScriptMethod Update { $Global:xSharePointQuotaTemplatesUpdated = $true } -PassThru
                return $returnVal
            }
            Mock Get-SPFarm { return @{} }

            It "return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:xSharePointQuotaTemplatesUpdated = $false
            It "updates the quota template settings" {
                Set-TargetResource @testParams
                $Global:xSharePointQuotaTemplatesUpdated | Should Be $true
            }
        }

        Context "The server is in a farm and the correct settings have been applied" {
            Mock Get-xSharePointContentService {
                $returnVal = @{
                    QuotaTemplates = @{
                        Test = @{
                            StorageMaximumLevel = 1024
                            StorageWarningLevel = 512
                            UserCodeMaximumLevel = 1000
                            UserCodeWarningLevel = 800
                        }
                    }
                } 
                $returnVal = $returnVal | Add-Member ScriptMethod Update { $Global:xSharePointQuotaTemplatesUpdated = $true } -PassThru
                return $returnVal
            }
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
