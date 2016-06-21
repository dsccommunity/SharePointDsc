[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_SPOutgoingEmailSettings"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPOutgoingEmailSettings - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            WebAppUrl = "http://sharepoint.contoso.com"
            SMTPServer = "smtp.contoso.com"
            FromAddress = "from@email.com"
            ReplyToAddress = "reply@email.com"
            CharacterSet= "65001"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\SharePointDsc")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue         


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
                { Set-TargetResource @testParams } | Should throw
            }
        }


        Context "The web application exists and the properties match" {
            Mock Get-SPWebApplication { 
                return @{
                        Url= "http://sharepoint.contoso.com"
                        OutboundMailServiceInstance= @{
                            Server = @{
                                Name = "smtp.contoso.com"
                            }
                        }
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


        Context "The web application exists and the properties don't match" {
            Mock Get-SPWebApplication { 
                $result = @{
                        Url= "http://sharepoint.contoso.com"
                        OutboundMailServiceInstance= @{
                            Server = @{
                                Name = "smtp2.contoso.com"
                            }
                        }
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