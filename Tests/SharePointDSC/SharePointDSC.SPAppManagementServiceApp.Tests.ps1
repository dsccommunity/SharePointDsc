[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPAppManagementServiceApp"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDSC\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPAppManagementServiceApp - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Test App"
            ApplicationPool = "Test App Pool"
            DatabaseName = "Test_DB"
            Ensure = "Present"
            DatabaseServer = "TestServer\Instance"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\SharePointDSC")

        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue
        Mock Remove-SPServiceApplication { }

        Context "When no service applications exist in the current farm but it should" {

            Mock Get-SPServiceApplication { return $null }
            Mock New-SPAppManagementServiceApplication {  return  @(@{})}
            Mock New-SPAppManagementServiceApplicationProxy{ return $null }

            It "returns absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name } 
            }

            It "returns false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "creates a new service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPAppManagementServiceApplication
            }
        }

        Context "When service applications exist in the current farm with the same name but is the wrong type" {

            Mock Get-SPServiceApplication { return @(@{
                TypeName = "Some other service app type"
            }) }

            It "returns absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name } 
            }

        }

        Context "When a service application exists and it should, and is also configured correctly" {
            Mock Get-SPServiceApplication { 
                return @(@{
                    TypeName = "App Management Service Application"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                    Database = @{
                        Name = $testParams.DatabaseName
                        Server = @{ Name = $testParams.DatabaseServer }
                    }
                })
            }

            It "returns present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name } 
            }

            It "returns true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "When a service application exists and it should, but the app pool is not configured correctly" {
            Mock Get-SPServiceApplication { 
                $service = @(@{
                    TypeName = "App Management Service Application"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = "Wrong App Pool Name" }
                    Database = @{
                        Name = $testParams.DatabaseName
                        Server = @{ Name = $testParams.DatabaseServer }
                    }
                })
                    
                $service = $service | Add-Member ScriptMethod Update {
                    $Global:SPAppServiceUpdateCalled = $true
                } -PassThru 
                return $service
            }
            Mock Get-SPServiceApplicationPool { 
                @{ Name = $testParams.ApplicationPool } }

            It "returns false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPAppServiceUpdateCalled = $false
            It "calls the update service app cmdlet from the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Get-SPServiceApplicationPool
                $Global:SPAppServiceUpdateCalled | Should Be $true
            }
        }

        Context "When a service app needs to be created and no database paramsters are provided" {
            $testParams = @{
                Name = "Test App"
                ApplicationPool = "Test App Pool"
                Ensure = "Present"
            }

            Mock Get-SPServiceApplication { return $null }
            Mock New-SPAppManagementServiceApplication {  return  @(@{})}
            Mock New-SPAppManagementServiceApplicationProxy{ return $null }

            it "should not throw an exception in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPAppManagementServiceApplication
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
                    TypeName = "App Management Service Application"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                    Database = @{
                        Name = $testParams.DatabaseName
                        Server = @{ Name = $testParams.DatabaseServer }
                    }
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
}
