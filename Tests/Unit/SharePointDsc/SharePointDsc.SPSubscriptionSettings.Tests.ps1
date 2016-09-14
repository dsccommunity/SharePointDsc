[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPSubscriptionSettingsServiceApp"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPSubscriptionSettingsServiceApp - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Test App"
            ApplicationPool = "Test App Pool"
            DatabaseName = "Test_DB"
            DatabaseServer = "TestServer\Instance"
            Ensure = "Present"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDsc")

        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue
        Mock -CommandName Remove-SPServiceApplication {}

        Context -Name "When no service applications exist in the current farm" {

            Mock -CommandName Get-SPServiceApplication -MockWith { return $null }
            Mock -CommandName New-SPSubscriptionSettingsServiceApplication { return @{}}
            Mock -CommandName New-SPSubscriptionSettingsServiceApplicationProxy { return @{}}
            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"  
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should create a new service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPSubscriptionSettingsServiceApplication
                Assert-MockCalled New-SPSubscriptionSettingsServiceApplicationProxy
            }
        }

        Context -Name "When service applications exist in the current farm but the specific subscription settings service app does not" {

            Mock -CommandName Get-SPServiceApplication -MockWith { return @(@{
                TypeName = "Some other service app type"
            }) }

            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }

        }

        Context -Name "When a service application exists and is configured correctly" {
            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return @(@{
                    TypeName = "Microsoft SharePoint Foundation Subscription Settings Service Application"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                    Database = @{
                        Name = $testParams.DatabaseName
                        Server = @{ Name = $testParams.DatabaseServer }
                    }
                })
            }

            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"  
            }

            It "Should return true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "When a service application exists and the app pool is not configured correctly" {
            Mock -CommandName Get-SPServiceApplication -MockWith { 
                $service = @(@{
                    TypeName = "Microsoft SharePoint Foundation Subscription Settings Service Application"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = "Wrong App Pool Name" }
                    Database = @{
                        Name = $testParams.DatabaseName
                        Server = @{ Name = $testParams.DatabaseServer }
                    }
                })
                    
                $service = $service | Add-Member -MemberType ScriptMethod -Name Update -Value {
                    $Global:SPSubscriptionServiceUpdateCalled = $true
                } -PassThru 
                return $service


            }
            Mock -CommandName Get-SPServiceApplicationPool { return @{ Name = $testParams.ApplicationPool } }
            Mock -CommandName Set-SPSubscriptionSettingsServiceApplication { }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPSubscriptionServiceUpdateCalled = $false
            It "Should call the update service app cmdlet from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Get-SPServiceApplicationPool
                $Global:SPSubscriptionServiceUpdateCalled | Should Be $true
            }
        }

        Context -Name "When a service app needs to be created and no database parameters are provided" {
            $testParams = @{
                Name = "Test App"
                ApplicationPool = "Test App Pool"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { return $null }
            Mock -CommandName New-SPSubscriptionSettingsServiceApplication {return @{} }
            Mock -CommandName New-SPSubscriptionSettingsServiceApplicationProxy { return @{}}

            It "should not throw an exception in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPSubscriptionSettingsServiceApplication
                Assert-MockCalled New-SPSubscriptionSettingsServiceApplicationProxy
            }
        }
        
        $testParams = @{
            Name = "Test App"
            ApplicationPool = "-"
            Ensure = "Absent"
        }
        
        Context -Name "When the service app exists but it shouldn't" {
            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return @(@{
                    TypeName = "Microsoft SharePoint Foundation Subscription Settings Service Application"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                    Database = @{
                        Name = "Database"
                        Server = @{ Name = "Server" }
                    }
                })
            }
            
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



