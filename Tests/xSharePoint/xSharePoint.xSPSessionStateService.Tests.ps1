[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_xSPSessionStateService"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPSessionStateService" {
    InModuleScope $ModuleName {
        $testParams = @{
            DatabaseName = "SP_StateService"
            DatabaseServer = "SQL.test.domain"
            Enabled = $true
            SessionTimeout = 60
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        
        Mock Set-SPSessionStateService { return @{} }
        Mock Enable-SPSessionStateService { return @{} }
        Mock Disable-SPSessionStateService { return @{} }

        Context "the service isn't enabled but should be" {
            Mock Get-SPSessionStateService  { return @{ SessionStateEnabled = $false; Timeout = @{TotalMinutes = 60}} }

            It "returns disabled from the get method" {
                (Get-TargetResource @testParams).Enabled | Should Be $false
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

            It "returns enabled from the get method" {
                (Get-TargetResource @testParams).Enabled | Should Be $true
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        Context "the timeout should be set to 90 seconds but is 60" {
            Mock Get-SPSessionStateService  { return @{ SessionStateEnabled = $true; Timeout = @{TotalMinutes = 60}} }
            $testParams.SessionTimeout = 90
            It "returns enabled from the get method" {
                (Get-TargetResource @testParams).Enabled | Should Be $true
                (Get-TargetResource @testParams).SessionTimeout | Should Be 60
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
            $testParams.Enabled = $false
            It "returns enabled from the get method" {
                (Get-TargetResource @testParams).Enabled | Should Be $true
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "disable the session service from the set method" {
                Set-TargetResource @testParams 

                Assert-MockCalled Disable-SPSessionStateService
            }
        }
    }    
}
