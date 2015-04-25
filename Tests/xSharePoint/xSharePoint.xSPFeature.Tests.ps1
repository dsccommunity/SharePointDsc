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
            InstallAccount = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
            Ensure = "Present"
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
    }    
}