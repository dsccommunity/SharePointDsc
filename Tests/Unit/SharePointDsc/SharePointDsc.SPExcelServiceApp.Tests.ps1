[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPExcelServiceApp"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPExcelServiceApp - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Test Excel Services App"
            ApplicationPool = "Test App Pool"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDsc")

        $versionBeingTested = (Get-Item $Global:CurrentSharePointStubModule).Directory.BaseName
        $majorBuildNumber = $versionBeingTested.Substring(0, $versionBeingTested.IndexOf("."))
        Mock Get-SPDSCInstalledProductVersion { return @{ FileMajorPart = $majorBuildNumber } }
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue

        Mock Remove-SPServiceApplication { }
        Mock Get-SPServiceApplicationProxy { return $null }

        switch ($majorBuildNumber) {
            15 {
                Context "When no service applications exist in the current farm" {

                    Mock Get-SPServiceApplication { return $null }
                    Mock New-SPExcelServiceApplication { }

                    It "returns absent from the Get method" {
                        (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                    }

                    It "returns false when the Test method is called" {
                        Test-TargetResource @testParams | Should Be $false
                    }

                    It "creates a new service application in the set method" {
                        Set-TargetResource @testParams
                        Assert-MockCalled New-SPExcelServiceApplication 
                    }
                }

                Context "When service applications exist in the current farm but the specific Excel Services app does not" {

                    Mock Get-SPServiceApplication { return @(@{
                        TypeName = "Some other service app type"
                    }) }

                    It "returns absent from the Get method" {
                        (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
                    }

                }

                Context "When a service application exists and is configured correctly" {
                    Mock Get-SPServiceApplication { 
                        return @(@{
                            TypeName = "Excel Services Application Web Service Application"
                            DisplayName = $testParams.Name
                            ApplicationPool = @{ Name = $testParams.ApplicationPool }
                        })
                    }

                    It "returns values from the get method" {
                        (Get-TargetResource @testParams).Ensure | Should Be "Present" 
                    }

                    It "returns true when the Test method is called" {
                        Test-TargetResource @testParams | Should Be $true
                    }
                }
                
                $testParams = @{
                    Name = "Test App"
                    ApplicationPool = "-"
                    Ensure = "Absent"
                }
                Context "When the service application exists but it shouldn't" {
                    Mock Get-SPServiceApplication { 
                        return @(@{
                            TypeName = "Excel Services Application Web Service Application"
                            DisplayName = $testParams.Name
                            DatabaseServer = $testParams.DatabaseServer
                            ApplicationPool = @{ Name = $testParams.ApplicationPool }
                        })
                    }
                    
                    It "returns present from the Get method" {
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
                    
                    It "returns absent from the Get method" {
                        (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
                    }
                    
                    It "returns true when the Test method is called" {
                        Test-TargetResource @testParams | Should Be $true
                    }
                }
            }
            16 {
                Context "All methods throw exceptions as Excel Services doesn't exist in 2016" {
                    It "throws on the get method" {
                        { Get-TargetResource @testParams } | Should Throw
                    }

                    It "throws on the test method" {
                        { Test-TargetResource @testParams } | Should Throw
                    }

                    It "throws on the set method" {
                        { Set-TargetResource @testParams } | Should Throw
                    }
                }
            }
        }
        
        
    }
}
