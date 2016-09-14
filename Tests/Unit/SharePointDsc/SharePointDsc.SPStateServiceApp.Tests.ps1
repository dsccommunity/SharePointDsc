[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPStateServiceApp"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPStateServiceApp - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "State Service App"
            DatabaseName = "SP_StateService"
            DatabaseServer = "SQL.test.domain"
            DatabaseCredentials = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
            Ensure = "Present"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDsc")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        
        Mock -CommandName New-SPStateServiceDatabase { return @{} }
        Mock -CommandName New-SPStateServiceApplication { return @{} }
        Mock -CommandName New-SPStateServiceApplicationProxy { return @{} }
        Mock -CommandName Remove-SPServiceApplication { }

        Context -Name "the service app doesn't exist and should" {
            Mock -CommandName Get-SPStateServiceApplication { return $null }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }

            It "Should return false from the get method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should create a state service app from the set method" {
                Set-TargetResource @testParams 

                Assert-MockCalled New-SPStateServiceApplication
            }
        }

        Context -Name "the service app exists and should" {
            Mock -CommandName Get-SPStateServiceApplication { return @{ DisplayName = $testParams.Name } }

            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present" 
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        $testParams.Ensure = "Absent"
        
        Context -Name "When the service app exists but it shouldn't" {
            Mock -CommandName Get-SPStateServiceApplication { return @{ DisplayName = $testParams.Name } }
            
            It "Should return present from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present" 
            }
            
            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "Should remove the service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPServiceApplication
            }
        }
        
        Context -Name "When the service app doesn't exist and shouldn't" {
            Mock -CommandName Get-SPServiceApplication -MockWith { return $null }
            
            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }
            
            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }    
}
