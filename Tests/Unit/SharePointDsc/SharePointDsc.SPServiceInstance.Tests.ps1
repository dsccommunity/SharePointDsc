[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPServiceInstance"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPServiceInstance - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Service pool"
            Ensure = "Present"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDsc")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        Mock -CommandName Start-SPServiceInstance { }
        Mock Stop-SPServiceInstance { }

        Context -Name "The service instance is not running but should be" {
            Mock -CommandName Get-SPServiceInstance { return @() }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the set method" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context -Name "The service instance is not running but should be" {
            Mock -CommandName Get-SPServiceInstance { return @(
                @{
                    TypeName = $testParams.Name
                    Status = "Disabled"
                })
            }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the set method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call the start service call from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Start-SPServiceInstance
            }
        }

        Context -Name "The service instance is running and should be" {
            Mock -CommandName Get-SPServiceInstance { return @(
                @{
                    TypeName = $testParams.Name
                    Status = "Online"
                })
            }

            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "An invalid service application is specified to start" {
            Mock -CommandName Get-SPServiceInstance  { return $null }

            It "Should throw when the set method is called" {
                { Set-TargetResource @testParams } | Should Throw
            }
        }

        $testParams.Ensure = "Absent"

        Context -Name "The service instance is not running and should not be" {
            Mock -CommandName Get-SPServiceInstance { return @(
                @{
                    TypeName = $testParams.Name
                    Status = "Disabled"
                })
            }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "The service instance is running and should not be" {
            Mock -CommandName Get-SPServiceInstance { return @(
                @{
                    TypeName = $testParams.Name
                    Status = "Online"
                })
            }

            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return false from the set method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call the stop service call from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Stop-SPServiceInstance
            }
        }

        Context -Name "An invalid service application is specified to stop" {
            Mock -CommandName Get-SPServiceInstance  { return $null }

            It "Should throw when the set method is called" {
                { Set-TargetResource @testParams } | Should Throw
            }
        }
    }    
}