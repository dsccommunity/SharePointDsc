[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPVisioServiceApp"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPVisioServiceApp - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Test Visio App"
            ApplicationPool = "Test App Pool"
            Ensure = "Present"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\SharePointDsc")

        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue

        Mock Remove-SPServiceApplication { }

        Context "When no service applications exist in the current farm" {

            Mock Get-SPServiceApplication { return $null }
            Mock New-SPVisioServiceApplication { }

            It "returns absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "returns false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "creates a new service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPVisioServiceApplication 
            }
        }

        Context "When service applications exist in the current farm but the specific Visio Graphics app does not" {

            Mock Get-SPServiceApplication { return @(@{
                TypeName = "Some other service app type"
            }) }

            It "returns absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }

        }

        Context "When a service application exists and is configured correctly" {
            Mock Get-SPServiceApplication { 
                return @(@{
                    TypeName = "Visio Graphics Service Application"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                })
            }

            It "returns present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "returns true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "When a service application exists and is not configured correctly" {
            Mock Get-SPServiceApplication { 
                return @(@{
                    TypeName = "Visio Graphics Service Application"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = "Wrong App Pool Name" }
                })
            }
            Mock Get-SPServiceApplicationPool { return @{ Name = $testParams.ApplicationPool } }

            It "returns false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "calls the update service app cmdlet from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Get-SPServiceApplicationPool
            }
        }
        
        $testParams = @{
            Name = "Test App"
            ApplicationPool = "-"
            Ensure = "Absent"
        }
        
        Context "When the service app exists but it shouldn't" {
            Mock Get-SPServiceApplication { 
                return @(@{
                    TypeName = "Visio Graphics Service Application"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                })
            }
            
            It "returns present from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present" 
            }
            
            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "should remove the service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPServiceApplication
            }
        }
        
        Context "When the service app doesn't exist and shouldn't" {
            Mock Get-SPServiceApplication { return $null }
            
            It "returns absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }
            
            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }
}
