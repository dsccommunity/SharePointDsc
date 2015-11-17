[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_xSPOutgoingEmailSettings"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPOutgoingEmailSettings" {
    InModuleScope $ModuleName {
        $testParams = @{
            WebAppUrl = "http://sharepoint.contoso.com"
            SMTPServer = "smtp.contoso.com"
            FromAddress = "from@email.com"
            ReplyToAddress = "reply@email.com"
            CharacterSet= "65001"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue         



        Context " Web Application isn't available " {
            Mock Get-SPWebApplication -MockWith  { return $null
            }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty 
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should be $false
            }

        }

        Context " Properties match" {
            Mock Get-SPWebApplication { 
                return @{
                        Url= "http://sharepoint.contoso.com"
                        OutboundMailServiceInstance= "smtp.contoso.com"
                        OutboundMailSenderAddress = "from@email.com"
                        OutboundMailReplyToAddress= "reply@email.com"
                        OutboundMailCodePage= "65001"
                    }
            }
            
            It "returns web app properties from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty 
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }

        } 


        Context " Properties update tests " {
            Mock Get-SPWebApplication { 
                $result = @{
                        Url= "http://sharepoint.contoso.com"
                        OutboundMailServiceInstance= "smtp2.contoso.com"
                        OutboundMailSenderAddress = "from@email.com"
                        OutboundMailReplyToAddress= "reply@email.com"
                        OutboundMailCodePage= "65001"
                    }
                $result = $result | Add-Member  ScriptMethod UpdateMailSettings  {
                        param( [string]$SMTPServer, [string]$FromAddress, [string]$ReplyToAddress, [string]$CharacterSet )
                        $Global:UpdateMailSettingsCalled = $true;
                        return ; } -passThru
                return $result
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "calls the new and set methods from the set function" {
                $Global:UpdateMailSettingsCalled=$false;
                Set-TargetResource @testParams
                Assert-MockCalled Get-SPWebApplication
                $Global:UpdateMailSettingsCalled | Should Be $true
            }
        }



    }    
}