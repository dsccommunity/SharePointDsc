[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_SPManagedPath"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDSC\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPManagedPath - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            WebAppUrl   = "http://sites.sharepoint.com"
            RelativeUrl = "teams"
            Explicit    = $false
            HostHeader  = $false
            Ensure      = "Present"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\SharePointDSC")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        Mock New-SPManagedPath { }
        Mock Remove-SPManagedPath { }

        Context "The managed path does not exist and should" {
            Mock Get-SPManagedPath { return $null }

            It "returns absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "creates a host header path in the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled New-SPManagedPath
            }

            $testParams.HostHeader = $true
            It "creates a host header path in the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled New-SPManagedPath
            }
            $testParams.HostHeader = $false

            $testParams.Add("InstallAccount", (New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))))
            It "creates a host header path in the set method where InstallAccount is used" {
                Set-TargetResource @testParams

                Assert-MockCalled New-SPManagedPath
            }
            $testParams.Remove("InstallAccount")
        }

        Context "The path exists but is of the wrong type" {
            Mock Get-SPManagedPath { return @{
                Name = $testParams.RelativeUrl
                Type = "ExplicitInclusion"
            } }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context "The path exists and is the correct type" {
            Mock Get-SPManagedPath { return @{
                Name = $testParams.RelativeUrl
                Type = "WildcardInclusion"
            } }

            It "returns present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        $testParams = @{
            WebAppUrl   = "http://sites.sharepoint.com"
            RelativeUrl = "teams"
            Explicit    = $false
            HostHeader  = $false
            Ensure      = "Absent"
        }
        
        Context "The managed path exists but shouldn't" {
            Mock Get-SPManagedPath { return @{
                Name = $testParams.RelativeUrl
                Type = "WildcardInclusion"
            } }
            
            It "should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }
            
            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "should call the remove cmdlet from the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPManagedPath
            }
        }
        
        Context "The managed path doesn't exist and shouldn't" {
            Mock Get-SPManagedPath { return $null }
            
            It "should return absent from the set method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }
            
            It "should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }    
}
