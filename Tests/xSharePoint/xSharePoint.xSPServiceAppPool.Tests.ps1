[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_xSPServiceAppPool"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPServiceAppPool" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Service pool"
            ServiceAccount = "DEMO\svcSPServiceApps"
            Ensure = "Present"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        Mock New-SPServiceApplicationPool { }
        Mock Set-SPServiceApplicationPool { }
        Mock Remove-SPServiceApplicationPool { }

        Context "A service account pool does not exist but should" {
            Mock Get-SPServiceApplicationPool { return $null }

            It "returns absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "calls the set method to create a new service account pool" {
                Set-TargetResource @testParams
                
                Assert-MockCalled New-SPServiceApplicationPool 
            }
        }

        Context "A service account pool exists but has the wrong service account" {
            Mock Get-SPServiceApplicationPool { return @{
                Name = $testParams.Name
                ProcessAccountName = "WRONG\account"
            }}

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false                
            }

            It "calls the set method to update the service account pool" {
                Set-TargetResource @testParams

                Assert-MockCalled Set-SPServiceApplicationPool 
            }
        }

        Context "A service account pool exists and uses the correct account" {
            Mock Get-SPServiceApplicationPool { return @{
                Name = $testParams.Name
                ProcessAccountName = $testParams.ServiceAccount
            }}

            It "retrieves present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        $testParams = @{
            Name = "Service pool"
            ServiceAccount = "DEMO\svcSPServiceApps"
            Ensure = "Absent"
        }
        
        Context "When the service app pool exists but it shouldn't" {
            Mock Get-SPServiceApplicationPool { return @{
                Name = $testParams.Name
                ProcessAccountName = $testParams.ServiceAccount
            }}
            
            It "returns present from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present" 
            }
            
            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "should remove the service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPServiceApplicationPool
            }
        }
        
        Context "When the service app pool doesn't exist and shouldn't" {
            Mock Get-SPServiceApplicationPool { return $null }
            
            It "returns absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }
            
            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }    
}
