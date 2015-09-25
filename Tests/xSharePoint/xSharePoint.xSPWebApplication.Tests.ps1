[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_xSPWebApplication"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPWebApplication" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Managed Metadata Service App"
            ApplicationPool = "SharePoint Web Apps"
            ApplicationPoolAccount = "DEMO\ServiceAccount"
            Url = "http://sites.sharepoint.com"
            AuthenticationMethod = "NTLM"
        }

        Mock Initialize-xSharePointPSSnapin { } -ModuleName "xSharePoint.Util"
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        Mock New-SPAuthenticationProvider { }
        Mock New-SPWebApplication { }

        Context "The web application that uses NTLM doesn't exist but should" {
            Mock Get-SPWebApplication { return $null }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "calls the new cmdlet from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled New-SPWebApplication
                Assert-MockCalled New-SPAuthenticationProvider -ParameterFilter { $DisableKerberos -eq $true }
            }
        }

        $testParams.AuthenticationMethod = "Kerberos"

        Context "The web application that uses Kerberos doesn't exist but should" {
            Mock Get-SPWebApplication { return $null }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "calls the new cmdlet from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled New-SPWebApplication
            }
        }

        Context "The web appliation does exist and should" {
            Mock Get-SPAuthenticationProvider { return @{ DisableKerberos = $true; AllowAnonymous = $false } }
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
            })}

            It "returns the current data from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }    
}