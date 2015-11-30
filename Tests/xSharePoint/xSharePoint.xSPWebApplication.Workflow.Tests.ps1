[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot  "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_xSPWebApplication"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\Modules\xSharePoint.Util\xSharePoint.Util.psm1")

Describe "xSPWebApplication (Workflow)" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "SharePoint Sites"
            ApplicationPool = "SharePoint Web Apps"
            ApplicationPoolAccount = "DEMO\ServiceAccount"
            Url = "http://sites.sharepoint.com"
            AuthenticationMethod = "NTLM"
            WorkflowSettings = @{
                ExternalWorkflowParticipantsEnabled = $true
                UserDefinedWorkflowsEnabled = $true
                EmailToNoPermissionWorkflowParticipantsEnable = $true
            }
        }
        
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
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
                $webApp = $webApp | Add-Member ScriptMethod UpdateWorkflowConfigurationSettings {
                    $Global:xSPWebApplicationUpdateWorkflowCalled = $true
                } -PassThru
                return @($webApp)
            }

            It "returns the current data from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:xSPWebApplicationUpdateWorkflowCalled = $false
            It "updates the workflow settings" {
                Set-TargetResource @testParams
                $Global:xSPWebApplicationUpdateWorkflowCalled | Should Be $true
            }
        }
    }    
}