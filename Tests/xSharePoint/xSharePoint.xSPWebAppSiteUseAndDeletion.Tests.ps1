[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_xSPWebAppSiteUseAndDeletion"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPWebAppSiteUseAndDeletion" {
    InModuleScope $ModuleName {
        $testParams = @{
            Url                                      = "http://example.contoso.local"
            SendUnusedSiteCollectionNotifications    = $true
            UnusedSiteNotificationPeriod             = 90
            AutomaticallyDeleteUnusedSiteCollections = $true
            UnusedSiteNotificationsBeforeDeletion    = 30
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force        
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

        Context "The Web Application isn't available" {
            Mock Get-SPWebApplication -MockWith  { return $null
            }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty 
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should be $false
            }

            It "throws an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "Configured web application could not be found"
            }
        }

        Context "The server is in a farm and the incorrect settings have been applied" {
            Mock Get-SPWebApplication -MockWith  {
                $returnVal = @{
                        SendUnusedSiteCollectionNotifications    = $false
                        UnusedSiteNotificationPeriod             = @{ TotalDays = 45; }
                        AutomaticallyDeleteUnusedSiteCollections = $false
                        UnusedSiteNotificationsBeforeDeletion    = 28
                } 
                $returnVal = $returnVal | Add-Member ScriptMethod Update { $Global:xSharePointSiteUseUpdated = $true } -PassThru
                return $returnVal
            }

            Mock Get-SPFarm { return @{} }

            It "return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:xSharePointSiteUseUpdated = $false
            It "updates the Site Use and Deletion settings" {
                Set-TargetResource @testParams
                $Global:xSharePointSiteUseUpdated | Should Be $true
            }
        }

        Context "The server is in a farm and the correct settings have been applied" {
            Mock Get-SPWebApplication -MockWith  {
                $returnVal = @{
                    SendUnusedSiteCollectionNotifications    = $true
                    UnusedSiteNotificationPeriod             = @{ TotalDays = 90; }
                    AutomaticallyDeleteUnusedSiteCollections = $true
                    UnusedSiteNotificationsBeforeDeletion    = 30
                } 
                $returnVal = $returnVal | Add-Member ScriptMethod Update { $Global:xSharePointSiteUseUpdated = $true } -PassThru
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
