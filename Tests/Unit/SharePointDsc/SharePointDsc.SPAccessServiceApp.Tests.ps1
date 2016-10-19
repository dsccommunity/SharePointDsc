[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPAccessServiceApp"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPAccessServiceApp - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Test Access Services App"
            DatabaseServer = "SQL.contoso.local"
            ApplicationPool = "Test App Pool"
        }
        $getTypeFullName = "Microsoft.Office.Access.Services.MossHost.AccessServicesWebServiceApplication"

        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDsc")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue
        Mock New-SPAccessServicesApplication { }
        Mock Set-SPAccessServicesApplication { }
        Mock Remove-SPServiceApplication { }

        Context "When no service applications exist in the current farm" {
            Mock Get-SPServiceApplication { return $null }
            
            It "returns Absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "returns false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "creates a new service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPAccessServicesApplication
            }
        }

        Context "When service applications exist in the current farm but the specific Access Services app does not" {
            Mock Get-SPServiceApplication {
                $spServiceApp = [pscustomobject]@{
                    DisplayName = $testParams.Name
                }
                $spServiceApp | Add-Member ScriptMethod GetType { 
                    return @{ FullName = "Microsoft.Office.UnKnownWebServiceApplication" } 
                } -PassThru -Force
                return $spServiceApp
            }

            It "returns Absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                Assert-MockCalled Get-SPServiceApplication
            }
        }

        Context "When a service application exists and is configured correctly" {
            Mock Get-SPServiceApplication {
                $spServiceApp = [pscustomobject]@{
                    DisplayName = $testParams.Name
                    DatabaseServer = $testParams.DatebaseName
                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                }
                $spServiceApp = $spServiceApp | Add-Member ScriptMethod GetType { 
                    return @{ FullName = $getTypeFullName } 
                } -PassThru -Force
                return $spServiceApp
            }

            It "returns Present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "returns true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        $testParams = @{
            Name = "Test App"
            ApplicationPool = "-"
            DatabaseServer = "-"
            Ensure = "Absent"
        }
        Context "When the service application exists but it shouldn't" {
            Mock Get-SPServiceApplication {
                $spServiceApp = [pscustomobject]@{
                    DisplayName = $testParams.Name
                    DatabaseServer = $testParams.DatebaseName
                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                }
                $spServiceApp = $spServiceApp | Add-Member ScriptMethod GetType { 
                    return @{ FullName = $getTypeFullName } 
                } -PassThru -Force
                return $spServiceApp
            }
            
            It "returns Present from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present" 
            }
            
            It "returns false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "calls the remove service application cmdlet in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPServiceApplication
            }
        }
        
        Context "When the serivce application doesn't exist and it shouldn't" {
            Mock Get-SPServiceApplication { return $null }
            
            It "returns Absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }
            
            It "returns true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }
}
