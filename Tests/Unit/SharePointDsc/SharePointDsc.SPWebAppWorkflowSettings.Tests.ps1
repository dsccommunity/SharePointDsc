[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_SPWebAppWorkflowSettings"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPWebAppWorkflowSettings - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            Url = "http://sites.sharepoint.com"
            ExternalWorkflowParticipantsEnabled = $true
            UserDefinedWorkflowsEnabled = $true
            EmailToNoPermissionWorkflowParticipantsEnable = $true
        }
        
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDsc")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue
        
        Mock New-SPAuthenticationProvider { }
        Mock New-SPWebApplication { }
        Mock Get-SPAuthenticationProvider { return @{ DisableKerberos = $true; AllowAnonymous = $false } }

        Context "The web appliation exists and has the correct workflow settings" {
            Mock Get-SPWebApplication { return @(@{
                DisplayName = $testParams.Name
                ApplicationPool = @{ 
                    Name = $testParams.ApplicationPool
                    Username = $testParams.ApplicationPoolAccount
                }
                ContentDatabases = @(
                    @{
                        Name = "SP_Content_01"
                        Server = "sql.domain.local"
                    }
                )
                IisSettings = @( 
                    @{ Path = "C:\inetpub\wwwroot\something" }
                )
                Url = $testParams.Url
                UserDefinedWorkflowsEnabled = $true
                EmailToNoPermissionWorkflowParticipantsEnabled = $true
                ExternalWorkflowParticipantsEnabled = $true
            })}

            It "returns the current data from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "The web appliation exists and uses incorrect workflow settings" {    
            Mock Get-SPWebApplication { 
                $webApp = @{
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ 
                        Name = $testParams.ApplicationPool
                        Username = $testParams.ApplicationPoolAccount
                    }
                    ContentDatabases = @(
                        @{
                            Name = "SP_Content_01"
                            Server = "sql.domain.local"
                        }
                    )
                    IisSettings = @( 
                        @{ Path = "C:\inetpub\wwwroot\something" }
                    )
                    Url = $testParams.Url
                    UserDefinedWorkflowsEnabled = $false
                    EmailToNoPermissionWorkflowParticipantsEnabled = $false
                    ExternalWorkflowParticipantsEnabled = $false
                }
                $webApp = $webApp | Add-Member ScriptMethod Update {
                    $Global:SPWebApplicationUpdateCalled = $true
                } -PassThru | Add-Member ScriptMethod UpdateWorkflowConfigurationSettings {
                    $Global:SPWebApplicationUpdateWorkflowCalled = $true
                } -PassThru
                return @($webApp)
            }

            It "returns the current data from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPWebApplicationUpdateCalled = $false
            $Global:SPWebApplicationUpdateWorkflowCalled = $false
            It "updates the workflow settings" {
                Set-TargetResource @testParams
                $Global:SPWebApplicationUpdateWorkflowCalled | Should Be $true
            }
        }
    }    
}