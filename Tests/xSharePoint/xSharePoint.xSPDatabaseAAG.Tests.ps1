[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_xSPDatabaseAAG"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPDatabaseAAG" {
    InModuleScope $ModuleName {
        $testParams = @{
            DatabaseName = "SampleDatabase"
            AGName = "AGName"
            Ensure = "Present"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        
        Mock Add-DatabaseToAvailabilityGroup { }
        Mock Remove-DatabaseFromAvailabilityGroup { }

        Context "The database is not in an availability group, but should be" {
            Mock Get-SPDatabase {
                return @(
                    @{
                        Name = $testParams.DatabaseName
                        AvailabilityGroup = $null
                    }
                )
            }

            it "returns the current values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            it "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            it "calls the add cmdlet in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Add-DatabaseToAvailabilityGroup
            }
        }

        Context "The database is not in the availability group and should not be" {
            $testParams.Ensure = "Absent"
            Mock Get-SPDatabase {
                return @(
                    @{
                        Name = $testParams.DatabaseName
                        AvailabilityGroup = $null
                    }
                )
            }

            it "returns the current values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            it "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "The database is in the correct availability group and should be" {
            $testParams.Ensure = "Present"
            Mock Get-SPDatabase {
                return @(
                    @{
                        Name = $testParams.DatabaseName
                        AvailabilityGroup = @{
                            Name = $testParams.AGName
                        }
                    }
                )
            }

            it "returns the current values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            it "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "The database is in an availability group and should not be" {
            $testParams.Ensure = "Absent"
            Mock Get-SPDatabase {
                return @(
                    @{
                        Name = $testParams.DatabaseName
                        AvailabilityGroup = @{
                            Name = $testParams.AGName
                        }
                    }
                )
            }

            it "returns the current values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            it "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            it "calls the remove cmdlet in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-DatabaseFromAvailabilityGroup
            }
        }

        Context "The database is in the wrong availability group" {
            $testParams.Ensure = "Present"
            Mock Get-SPDatabase {
                return @(
                    @{
                        Name = $testParams.DatabaseName
                        AvailabilityGroup = @{
                            Name = "WrongAAG"
                        }
                    }
                )
            }

            it "returns the current values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            it "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            it "calls the remove and add cmdlets in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-DatabaseFromAvailabilityGroup
                Assert-MockCalled Add-DatabaseToAvailabilityGroup
            }
        }
    }
}

