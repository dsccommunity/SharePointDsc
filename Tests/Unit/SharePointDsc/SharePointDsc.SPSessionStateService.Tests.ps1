[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
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
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDsc")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        
        Mock -CommandName Set-SPSessionStateService { return @{} }
        Mock -CommandName Enable-SPSessionStateService { return @{} }
        Mock -CommandName Disable-SPSessionStateService { return @{} }

        Context -Name "the service isn't enabled but should be" {
            Mock -CommandName Get-SPSessionStateService  { return @{ SessionStateEnabled = $false; Timeout = @{TotalMinutes = 60}} }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "enables the session service from the set method" {
                Set-TargetResource @testParams 

                Assert-MockCalled Enable-SPSessionStateService
            }
        }
        Context -Name "the service is enabled and should be" {
            Mock -CommandName Get-SPSessionStateService  { return @{ SessionStateEnabled = $true; Timeout = @{TotalMinutes = 60}} }

            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        Context -Name "the timeout should be set to 90 seconds but is 60" {
            Mock -CommandName Get-SPSessionStateService  { return @{ SessionStateEnabled = $true; Timeout = @{TotalMinutes = 60}} }
            $testParams.SessionTimeout = 90
            It "Should return present from the get method" {
                $result = Get-TargetResource @testParams 
                $result.Ensure | Should Be "Present"
                $result.SessionTimeout | Should Be 60
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "Should update session timeout to 90 seconds" {
                Set-TargetResource @testParams 

                Assert-MockCalled Set-SPSessionStateService 
            }
        }
        
        Context -Name "the service is enabled but shouldn't be" {
            Mock -CommandName Get-SPSessionStateService  { return @{ SessionStateEnabled = $true; Timeout = @{TotalMinutes = 60}} }
            $testParams.Ensure = "Absent"
            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "disable the session service from the set method" {
                Set-TargetResource @testParams 
                Assert-MockCalled Disable-SPSessionStateService
            }
        }
        
        Context -Name "the service is disabled and should be" {
            Mock -CommandName Get-SPSessionStateService  { return @{ SessionStateEnabled = $false; Timeout = @{TotalMinutes = 60}} }
            
            It "Should return enabled from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }    
}
