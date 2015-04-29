[CmdletBinding()]
param()

if (!$PSScriptRoot) # $PSScriptRoot is not defined in 2.0
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

$ModuleName = "MSFT_xSPWebApplication"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPWebApplication" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Managed Metadata Service App"
            InstallAccount = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
            ApplicationPool = "SharePoint Web Apps"
            ApplicationPoolAccount = "DEMO\ServiceAccount"
            Url = "http://sites.sharepoint.com"
        }

        Context "Validate test method" {
            It "Fails when web app doesn't exist" {
                Mock -ModuleName $ModuleName Get-TargetResource { return @{} }
                Test-TargetResource @testParams | Should Be $false
            }
            It "Passes when the web app exists and has correct settings" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
                        ApplicationPool = $testParams.ApplicationPool
                        ApplicationPoolAccount = $testParams.ApplicationPoolAccount
                    } 
                } 
                Test-TargetResource @testParams | Should Be $true
            }
            It "Fails when the web app exists and has the wrong app pool" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
                        ApplicationPool = "Wrong app pool"
                        ApplicationPoolAccount = $testParams.ApplicationPoolAccount
                    } 
                } 
                Test-TargetResource @testParams | Should Be $false
            }
        }
    }    
}