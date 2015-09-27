[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_xSPServiceInstance"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPServiceInstance" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Service pool"
            Ensure = "Present"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        Mock Start-SPServiceInstance { }
        Mock Stop-SPServiceInstance { }

        Context "The service instance is not running but should be" {
            Mock Get-SPServiceInstance { return @(
                @{
                    TypeName = $testParams.Name
                    Status = "Disabled"
                })
            }

            It "returns absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "returns false from the set method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "calls the start service call from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Start-SPServiceInstance
            }
        }

        Context "The service instance is running and should be" {
            Mock Get-SPServiceInstance { return @(
                @{
                    TypeName = $testParams.Name
                    Status = "Online"
                })
            }

            It "returns present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "An invalid service application is specified to start" {
            Mock Get-SPServiceInstance  { return $null }

            It "throws when the set method is called" {
                { Set-TargetResource @testParams } | Should Throw
            }
        }

        $testParams.Ensure = "Absent"

        Context "The service instance is not running and should not be" {
            Mock Get-SPServiceInstance { return @(
                @{
                    TypeName = $testParams.Name
                    Status = "Disabled"
                })
            }

            It "returns absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "The service instance is running and should not be" {
            Mock Get-SPServiceInstance { return @(
                @{
                    TypeName = $testParams.Name
                    Status = "Online"
                })
            }

            It "returns present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "returns false from the set method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "calls the stop service call from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Stop-SPServiceInstance
            }
        }

        Context "An invalid service application is specified to stop" {
            Mock Get-SPServiceInstance  { return $null }

            It "throws when the set method is called" {
                { Set-TargetResource @testParams } | Should Throw
            }
        }
    }    
}