[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPSessionStateService"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPSessionStateService - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            DatabaseName = "SP_StateService"
            DatabaseServer = "SQL.test.domain"
            Ensure = "Present"
            SessionTimeout = 60
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\SharePointDsc")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        
        Mock Set-SPSessionStateService { return @{} }
        Mock Enable-SPSessionStateService { return @{} }
        Mock Disable-SPSessionStateService { return @{} }

        Context "the service isn't enabled but should be" {
            Mock Get-SPSessionStateService  { return @{ SessionStateEnabled = $false; Timeout = @{TotalMinutes = 60}} }

            It "returns absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "enables the session service from the set method" {
                Set-TargetResource @testParams 

                Assert-MockCalled Enable-SPSessionStateService
            }
        }
        Context "the service is enabled and should be" {
            Mock Get-SPSessionStateService  { return @{ SessionStateEnabled = $true; Timeout = @{TotalMinutes = 60}} }

            It "returns present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        Context "the timeout should be set to 90 seconds but is 60" {
            Mock Get-SPSessionStateService  { return @{ SessionStateEnabled = $true; Timeout = @{TotalMinutes = 60}} }
            $testParams.SessionTimeout = 90
            It "returns present from the get method" {
                $result = Get-TargetResource @testParams 
                $result.Ensure | Should Be "Present"
                $result.SessionTimeout | Should Be 60
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "updates session timeout to 90 seconds" {
                Set-TargetResource @testParams 

                Assert-MockCalled Set-SPSessionStateService 
            }
        }
        
        Context "the service is enabled but shouldn't be" {
            Mock Get-SPSessionStateService  { return @{ SessionStateEnabled = $true; Timeout = @{TotalMinutes = 60}} }
            $testParams.Ensure = "Absent"
            It "returns present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "disable the session service from the set method" {
                Set-TargetResource @testParams 
                Assert-MockCalled Disable-SPSessionStateService
            }
        }
        
        Context "the service is disabled and should be" {
            Mock Get-SPSessionStateService  { return @{ SessionStateEnabled = $false; Timeout = @{TotalMinutes = 60}} }
            
            It "returns enabled from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }    
}
