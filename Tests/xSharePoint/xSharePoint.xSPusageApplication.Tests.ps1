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
            Name = "Usage Service App"
            UsageLogCutTime = 60
            UsageLogLocation = "L:\UsageLogs"
            UsageLogMaxFileSizeKB = 1024
            UsageLogMaxSpaceGB = 10
        }

        Context "Validate get method" {
            It "Calls the right functions to retrieve SharePoint data" {
                Mock Invoke-xSharePointSPCmdlet { return @(@{ TypeName = "Usage and Health Data Collection Service Application" }) } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPServiceApplication" -and $Arguments.Name -eq $testParams.Name } -ModuleName "xSharePoint.ServiceApplications"
                Mock Invoke-xSharePointSPCmdlet { return @{} } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPUsageService" }
                Get-TargetResource @testParams
                Assert-VerifiableMocks
            }
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
                        UsageLogLocation = $testParams.UsageLogLocation
                        UsageLogMaxFileSizeKB = $testParams.UsageLogMaxFileSizeKB
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
                        UsageLogLocation = "C:\WrongPath"
                        UsageLogMaxFileSizeKB = $testParams.UsageLogMaxFileSizeKB
                        UsageLogMaxSpaceGB = $testParams.UsageLogMaxSpaceGB
                    } 
                } 
                Test-TargetResource @testParams | Should Be $false
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
                        UsageLogCutTime = 0
                        UsageLogLocation = $testParams.UsageLogLocation
                        UsageLogMaxFileSizeKB = $testParams.UsageLogMaxFileSizeKB
                        UsageLogMaxSpaceGB = $testParams.UsageLogMaxSpaceGB
                    } 
                } 
                Test-TargetResource @testParams | Should Be $false
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
                        UsageLogCutTime = $testParams.UsageLogCutTime
                        UsageLogLocation = $testParams.UsageLogLocation
                        UsageLogMaxFileSizeKB = 0
                        UsageLogMaxSpaceGB = $testParams.UsageLogMaxSpaceGB
                    } 
                } 
                Test-TargetResource @testParams | Should Be $false
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
                        UsageLogCutTime = $testParams.UsageLogCutTime
                        UsageLogLocation = $testParams.UsageLogLocation
                        UsageLogMaxFileSizeKB = $testParams.UsageLogMaxFileSizeKB
                        UsageLogMaxSpaceGB = 0
                    } 
                } 
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context "Validate set method" {
            It "Sets the usage values correctly" {
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPServiceApplication" -and $Arguments.Name -eq $testParams.Name }
                Mock Invoke-xSharePointSPCmdlet { return @{} } -Verifiable -ParameterFilter { $CmdletName -eq "New-SPUsageApplication" }
                Mock Invoke-xSharePointSPCmdlet { return @{} } -Verifiable -ParameterFilter { $CmdletName -eq "Set-SPUsageService" }

                Set-TargetResource @testParams

                Assert-VerifiableMocks
            }
        }
    }    
}