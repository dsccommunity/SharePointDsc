[CmdletBinding()]
param()

if (!$PSScriptRoot) # $PSScriptRoot is not defined in 2.0
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

$ModuleName = "MSFT_xSPFeature"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPFeature" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "DemoFeature"
            FeatureScope = "Farm"
            Url = "http://site.sharepoint.com"
            Ensure = "Present"
        }

        Context "Validate get method" {
            It "Returns as empty where a feature is not installed in the farm" {
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPFeature" -and $Arguments.Count -eq 1 }

                Get-TargetResource @testParams

                Assert-VerifiableMocks
            }
            It "Returns a disabled state when an installed feature is not found at a farm scope" {
                Mock Invoke-xSharePointSPCmdlet { return @{ Name = $testParams.Name } } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPFeature" -and $Arguments.Count -eq 1 }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPFeature" -and $Arguments.Count -eq 2 }

                $result = Get-TargetResource @testParams

                $result.Enabled | Should be $false

                Assert-VerifiableMocks
            }
            $testParams.FeatureScope = "Site"
            It "Returns a disabled state when an installed feature is not found at a site scope" {
                Mock Invoke-xSharePointSPCmdlet { return @{ Name = $testParams.Name } } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPFeature" -and $Arguments.Count -eq 1 }
                Mock Invoke-xSharePointSPCmdlet { return $null } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPFeature" -and $Arguments.Count -eq 2 }

                $result = Get-TargetResource @testParams

                $result.Enabled | Should be $false

                Assert-VerifiableMocks
            }
            It "Returns an enabled state when an installed feature is found at a site scope" {
                Mock Invoke-xSharePointSPCmdlet { return @{ Name = $testParams.Name } } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPFeature" -and $Arguments.Count -eq 1 }
                Mock Invoke-xSharePointSPCmdlet { return @{ Name = $testParams.Name } } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPFeature" -and $Arguments.Count -eq 2 }

                $result = Get-TargetResource @testParams

                $result.Enabled | Should be $true

                Assert-VerifiableMocks
            }
            $testParams.FeatureScope = "Farm"
            It "Returns an enabled state when an installed feature is found at a farm scope" {
                Mock Invoke-xSharePointSPCmdlet { return @{ Name = $testParams.Name } } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPFeature" -and $Arguments.Count -eq 1 }
                Mock Invoke-xSharePointSPCmdlet { return @{ Name = $testParams.Name } } -Verifiable -ParameterFilter { $CmdletName -eq "Get-SPFeature" -and $Arguments.Count -eq 2 }

                $result = Get-TargetResource @testParams

                $result.Enabled | Should be $true

                Assert-VerifiableMocks
            }
        }

        Context "Validate test method" {
            It "Throws when a feature is not installed in the farm" {
                Mock -ModuleName $ModuleName Get-TargetResource { return @{} }
                { Test-TargetResource @testParams } | Should Throw "Unable to locate feature"
            }
            It "Passes when a farm feature is enabaled and should be" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
                        Id = [Guid]::NewGuid()
                        Version = "1.0"
                        Enabled = $true
                    }
                } 
                Test-TargetResource @testParams | Should Be $true
            }
            It "Fails when a farm feature is not enabaled and should be" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
                        Id = [Guid]::NewGuid()
                        Version = "1.0"
                        Enabled = $false
                    }
                } 
                Test-TargetResource @testParams | Should Be $false
            }

            $testParams.Ensure = "Absent"

            It "Passes when a farm feature is not enabaled and should not be" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
                        Id = [Guid]::NewGuid()
                        Version = "1.0"
                        Enabled = $false
                    }
                } 
                Test-TargetResource @testParams | Should Be $true
            }
            It "Fails when a farm feature is enabaled and should not be" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
                        Id = [Guid]::NewGuid()
                        Version = "1.0"
                        Enabled = $true
                    }
                } 
                Test-TargetResource @testParams | Should Be $false
            }

            $testParams.Ensure = "Present"
            $testParams.FeatureScope = "Site"

            It "Passes when a site feature is enabaled and should be" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
                        Id = [Guid]::NewGuid()
                        Version = "1.0"
                        Enabled = $true
                    }
                } 
                Test-TargetResource @testParams | Should Be $true
            }
            It "Fails when a site feature is not enabaled and should be" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
                        Id = [Guid]::NewGuid()
                        Version = "1.0"
                        Enabled = $false
                    }
                } 
                Test-TargetResource @testParams | Should Be $false
            }

            $testParams.Ensure = "Absent"

            It "Passes when a site feature is not enabaled and should not be" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
                        Id = [Guid]::NewGuid()
                        Version = "1.0"
                        Enabled = $false
                    }
                } 
                Test-TargetResource @testParams | Should Be $true
            }
            It "Fails when a site feature is enabaled and should not be" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
                        Id = [Guid]::NewGuid()
                        Version = "1.0"
                        Enabled = $true
                    }
                } 
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context "Validate set method" {

            $testParams.Ensure = "Present"

            It "Enables a feature that should be on" {
                Mock Invoke-xSharePointSPCmdlet { return $false } -Verifiable -ParameterFilter { $CmdletName -eq "Enable-SPFeature" }

                Set-TargetResource @testParams

                Assert-VerifiableMocks
            }

            $testParams.Ensure = "Absent"

            It "Disables a feature that should be turned off" {
                Mock Invoke-xSharePointSPCmdlet { return $false } -Verifiable -ParameterFilter { $CmdletName -eq "Disable-SPFeature" }

                Set-TargetResource @testParams

                Assert-VerifiableMocks
            }
        }
    }    
}