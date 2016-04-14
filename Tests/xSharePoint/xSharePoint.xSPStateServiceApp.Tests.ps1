[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_xSPStateServiceApp"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPStateServiceApp" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "State Service App"
            DatabaseName = "SP_StateService"
            DatabaseServer = "SQL.test.domain"
            DatabaseCredentials = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
            Ensure = "Present"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        
        Mock New-SPStateServiceDatabase { return @{} }
        Mock New-SPStateServiceApplication { return @{} }
        Mock New-SPStateServiceApplicationProxy { return @{} }
        Mock Remove-SPServiceApplication { }

        Context "the service app doesn't exist and should" {
            Mock Get-SPStateServiceApplication { return $null }

            It "returns absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }

            It "returns false from the get method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "creates a state service app from the set method" {
                Set-TargetResource @testParams 

                Assert-MockCalled New-SPStateServiceApplication
            }
        }

        Context "the service app exists and should" {
            Mock Get-SPStateServiceApplication { return @{ DisplayName = $testParams.Name } }

            It "returns present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present" 
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        $testParams.Ensure = "Absent"
        
        Context "When the service app exists but it shouldn't" {
            Mock Get-SPStateServiceApplication { return @{ DisplayName = $testParams.Name } }
            
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
