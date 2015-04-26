[CmdletBinding()]
param()

if (!$PSScriptRoot) # $PSScriptRoot is not defined in 2.0
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

$ModuleName = "MSFT_xSPUsageApplication"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPUsageApplication" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Managed Metadata Service App"
            InstallAccount = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
            UsageLogCutTime = 60
            UsageLogLocation = "L:\UsageLogs"
            UsageLogMaxFileSize = 1024
            UsageLogMaxSpaceGB = 10
        }

        Context "Validate test method" {
            It "Fails when state service app doesn't exist" {
                Mock -ModuleName $ModuleName Get-TargetResource { return @{} }
                Test-TargetResource @testParams | Should Be $false
            }
            It "Passes when the state service app exists and settings are corrent" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
                        UsageLogCutTime = $testParams.UsageLogCutTime
                        UsageLogDir = $testParams.UsageLogLocation
                        UsageLogMaxFileSize = $testParams.UsageLogMaxFileSize
                        UsageLogMaxSpaceGB = $testParams.UsageLogMaxSpaceGB
                    } 
                } 
                Test-TargetResource @testParams | Should Be $true
            }
            It "Fails when the state service app exists and settings are wrong" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
                        UsageLogCutTime = $testParams.UsageLogCutTime
                        UsageLogDir = "C:\WrongPath"
                        UsageLogMaxFileSize = $testParams.UsageLogMaxFileSize
                        UsageLogMaxSpaceGB = $testParams.UsageLogMaxSpaceGB
                    } 
                } 
                Test-TargetResource @testParams | Should Be $false
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
                        UsageLogCutTime = 0
                        UsageLogDir = $testParams.UsageLogLocation
                        UsageLogMaxFileSize = $testParams.UsageLogMaxFileSize
                        UsageLogMaxSpaceGB = $testParams.UsageLogMaxSpaceGB
                    } 
                } 
                Test-TargetResource @testParams | Should Be $false
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
                        UsageLogCutTime = $testParams.UsageLogCutTime
                        UsageLogDir = $testParams.UsageLogLocation
                        UsageLogMaxFileSize = 0
                        UsageLogMaxSpaceGB = $testParams.UsageLogMaxSpaceGB
                    } 
                } 
                Test-TargetResource @testParams | Should Be $false
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
                        UsageLogCutTime = $testParams.UsageLogCutTime
                        UsageLogDir = $testParams.UsageLogLocation
                        UsageLogMaxFileSize = $testParams.UsageLogMaxFileSize
                        UsageLogMaxSpaceGB = 0
                    } 
                } 
                Test-TargetResource @testParams | Should Be $false
            }
        }
    }    
}