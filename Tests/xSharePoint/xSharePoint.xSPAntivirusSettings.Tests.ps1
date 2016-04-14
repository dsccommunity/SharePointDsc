[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_xSPAntivirusSettings"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPAntivirusSettings" {
    InModuleScope $ModuleName {
        $testParams = @{
            ScanOnDownload = $true
            ScanOnUpload = $true
            AllowDownloadInfected = $true
            AttemptToClean = $true
            TimeoutDuration = 60
            NumberOfThreads = 5
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
                    AntivirusSettings = @{
                        AllowDownload = $false
                        DownloadScanEnabled = $false
                        UploadScanEnabled = $false
                        CleaningEnabled = $false
                        NumberOfThreads = 0
                        Timeout = @{
                            TotalSeconds = 0;
                        }
                    }
                } 
                $returnVal = $returnVal | Add-Member ScriptMethod Update { $Global:xSharePointAntivirusUpdated = $true } -PassThru
                return $returnVal
            }
            Mock Get-SPFarm { return @{} }

            It "return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:xSharePointAntivirusUpdated = $false
            It "updates the antivirus settings" {
                Set-TargetResource @testParams
                $Global:xSharePointAntivirusUpdated | Should Be $true
            }
        }

        Context "The server is in a farm and the correct settings have been applied" {
            Mock Get-xSharePointContentService {
                $returnVal = @{
                    AntivirusSettings = @{
                        AllowDownload = $true
                        DownloadScanEnabled = $true
                        UploadScanEnabled = $true
                        CleaningEnabled = $true
                        NumberOfThreads = 5
                        Timeout = @{
                            TotalSeconds = 60;
                        }
                    }
                } 
                $returnVal = $returnVal | Add-Member ScriptMethod Update { $Global:xSharePointAntivirusUpdated = $true } -PassThru
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
