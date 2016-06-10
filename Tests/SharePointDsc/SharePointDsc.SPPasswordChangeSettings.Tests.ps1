[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_SPPasswordChangeSettings"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPPasswordChangeSettings - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            MailAddress = "e@mail.com"
            DaysBeforeExpiry = 7
            PasswordChangeWaitTimeSeconds = 60

        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\SharePointDsc")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue         

         Context "No local SharePoint farm is available" {
            Mock Get-SPFarm { return $null }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should Throw 
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should be $false
            }
        }


        Context "There is a local SharePoint farm and the properties are set correctly" {
            Mock Get-SPFarm { 
                return @{
                    PasswordChangeEmailAddress = "e@mail.com"
                    DaysBeforePasswordExpirationToSendEmail = 7
                    PasswordChangeGuardTime = 60
                    PasswordChangeMaximumTries = 3
                }
            }
            
            It "returns farm properties from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty 
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }


        Context "There is a local SharePoint farm and the properties are not set correctly" {
            Mock Get-SPFarm { 
                $result = @{
                    PasswordChangeEmailAddress = "";
                    PasswordChangeGuardTime = 0
                    PasswordChangeMaximumTries = 0
                    DaysBeforePasswordExpirationToSendEmail = 0
                }
                $result = $result | Add-Member  ScriptMethod Update { 
                    $Global:SPFarmUpdateCalled = $true;
                    return $true;
                
                    } -PassThru
                return $result
            }

            It "returns farm properties from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty 
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "calls the new and set methods from the set function" {
                $Global:SPFarmUpdateCalled = $false;
                Set-TargetResource @testParams
                Assert-MockCalled Get-SPFarm
                $Global:SPFarmUpdateCalled  | Should Be $true
            }
        }



    }    
}