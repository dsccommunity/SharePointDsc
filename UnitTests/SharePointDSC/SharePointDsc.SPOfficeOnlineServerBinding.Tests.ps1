[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_SPOfficeOnlineServerBinding"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDSC\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPOfficeOnlineServerBinding - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\SharePointDSC")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 

        Mock Remove-SPWOPIBinding {}
        Mock New-SPWOPIBinding {}
        Mock Set-SPWOPIZone {}
        Mock Get-SPWOPIZone { return "internal-https" }
        
        Context "No bindings are set for the specified zone, but they should be" {
            $testParams = @{
                Zone    = "internal-https"
                DnsName = "webapps.contoso.com"
                Ensure  = "Present"
            }

            Mock Get-SPWOPIBinding {
                return $null
            }

            It "should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }

            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "should create the bindings in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPWOPIBinding 
                Assert-MockCalled Set-SPWOPIZone
            }
        }

        Context "Incorrect bindings are set for the specified zone that should be configured" {
            $testParams = @{
                Zone    = "internal-https"
                DnsName = "webapps.contoso.com"
                Ensure  = "Present"
            }

            Mock Get-SPWOPIBinding {
                return @(
                    @{
                        ServerName = "wrong.contoso.com"
                    }
                )
            }

            It "should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "should remove the old bindings and create the new bindings in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPWOPIBinding
                Assert-MockCalled New-SPWOPIBinding 
                Assert-MockCalled Set-SPWOPIZone
            }
        }

        Context "Correct bindings are set for the specified zone" {
            $testParams = @{
                Zone    = "internal-https"
                DnsName = "webapps.contoso.com"
                Ensure  = "Present"
            }

            Mock Get-SPWOPIBinding {
                return @(
                    @{
                        ServerName = "webapps.contoso.com"
                    }
                )
            }

            It "should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "Bindings are set for the specified zone, but they should not be" {
            $testParams = @{
                Zone    = "internal-https"
                DnsName = "webapps.contoso.com"
                Ensure  = "Absent"
            }

            Mock Get-SPWOPIBinding {
                return @(
                    @{
                        ServerName = "webapps.contoso.com"
                    }
                )
            }

            It "should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "should remove the bindings in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPWOPIBinding
            }
        } 

        Context "Bindings are not set for the specified zone, and they should not be" {
            $testParams = @{
                Zone    = "internal-https"
                DnsName = "webapps.contoso.com"
                Ensure  = "Absent"
            }

            Mock Get-SPWOPIBinding {
                return $null
            }

            It "should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }    
}
