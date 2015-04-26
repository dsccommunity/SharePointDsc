[CmdletBinding()]
param()

if (!$PSScriptRoot) # $PSScriptRoot is not defined in 2.0
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

$ModuleName = "MSFT_xSPServiceInstance"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPServiceInstance" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Service pool"
            InstallAccount = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
            Ensure = "Present"
        }

        Context "Validate test method" {
            It "Fails when service instance is not found at all" {
                Mock -ModuleName $ModuleName Get-TargetResource { return @{} }
                Test-TargetResource @testParams | Should Be $false
            }
            It "Passes when the service instance is running and it should be" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
						Status = "Online"
                    }
                } 
                Test-TargetResource @testParams | Should Be $true
            }
            It "Fails when the service instance isn't running and it should be" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
						Status = "Disabled"
                    }
                } 
                Test-TargetResource @testParams | Should Be $false
            }

			$testParams.Ensure = "Absent"

			It "Fails when the service instance is running and it should not be" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
						Status = "Online"
                    }
                } 
                Test-TargetResource @testParams | Should Be $false
            }
            It "Passes when the service instance isn't running and it should not be" {
                Mock -ModuleName $ModuleName Get-TargetResource { 
                    return @{
                        Name = $testParams.Name
						Status = "Disabled"
                    }
                } 
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }    
}