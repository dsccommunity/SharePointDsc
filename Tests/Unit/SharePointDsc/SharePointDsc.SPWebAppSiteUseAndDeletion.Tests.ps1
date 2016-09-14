[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPWebAppSiteUseAndDeletion"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPWebAppSiteUseAndDeletion - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            Url                                      = "http://example.contoso.local"
            SendUnusedSiteCollectionNotifications    = $true
            UnusedSiteNotificationPeriod             = 90
            AutomaticallyDeleteUnusedSiteCollections = $true
            UnusedSiteNotificationsBeforeDeletion    = 30
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDsc")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue

        Context -Name "The server is not part of SharePoint farm" {
            Mock -CommandName Get-SPFarm -MockWith { throw "Unable to detect local farm" }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Be $null
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an exception in the set method to say there is no local farm" {
                { Set-TargetResource @testParams } | Should throw "No local SharePoint farm was detected"
            }
        }

        Context -Name "The Web Application isn't available" {
            Mock -CommandName Get-SPWebApplication -MockWith  { return $null
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty 
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should be $false
            }

            It "Should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "Configured web application could not be found"
            }
        }

        Context -Name "The server is in a farm and the incorrect settings have been applied" {
            Mock -CommandName Get-SPWebApplication -MockWith  {
                $returnVal = @{
                        SendUnusedSiteCollectionNotifications    = $false
                        UnusedSiteNotificationPeriod             = @{ TotalDays = 45; }
                        AutomaticallyDeleteUnusedSiteCollections = $false
                        UnusedSiteNotificationsBeforeDeletion    = 28
                } 
                $returnVal = $returnVal | Add-Member -MemberType ScriptMethod -Name Update -Value { $Global:SPDscSiteUseUpdated = $true } -PassThru
                return $returnVal
            }

            Mock -CommandName Get-SPFarm -MockWith { return @{} }

            It "Should return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPDscSiteUseUpdated = $false
            It "Should update the Site Use and Deletion settings" {
                Set-TargetResource @testParams
                $Global:SPDscSiteUseUpdated | Should Be $true
            }
        }

        Context -Name "The server is in a farm and the correct settings have been applied" {
            Mock -CommandName Get-SPWebApplication -MockWith  {
                $returnVal = @{
                    SendUnusedSiteCollectionNotifications    = $true
                    UnusedSiteNotificationPeriod             = @{ TotalDays = 90; }
                    AutomaticallyDeleteUnusedSiteCollections = $true
                    UnusedSiteNotificationsBeforeDeletion    = 30
                } 
                $returnVal = $returnVal | Add-Member -MemberType ScriptMethod -Name Update -Value { $Global:SPDscSiteUseUpdated = $true } -PassThru
                return $returnVal
            }
            Mock -CommandName Get-SPFarm -MockWith { return @{} }

            It "Should return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }

        }
    }
}
