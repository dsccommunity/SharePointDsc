[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string] 
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
                                         -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
                                         -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
                                -ChildPath "..\SharePointDsc.TestHarness.psm1" `
                                -Resolve)

$Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
                                              -DscResource "SPServiceAppPool"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests

        # Mocks for all contexts   
        Mock -CommandName New-SPServiceApplicationPool -MockWith { }
        Mock -CommandName Set-SPServiceApplicationPool -MockWith { }
        Mock -CommandName Remove-SPServiceApplicationPool -MockWith { }

        # Test contexts
        Context -Name "A service account pool does not exist but should" -Fixture {
            $testParams = @{
                Name = "Service pool"
                ServiceAccount = "DEMO\svcSPServiceApps"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPServiceApplicationPool -MockWith { 
                return $null 
            }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call the set method to create a new service account pool" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPServiceApplicationPool 
            }
        }

        Context -Name "A service account pool exists but has the wrong service account" -Fixture {
            $testParams = @{
                Name = "Service pool"
                ServiceAccount = "DEMO\svcSPServiceApps"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPServiceApplicationPool -MockWith { 
                return @{
                    Name = $testParams.Name
                    ProcessAccountName = "WRONG\account"
                }
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false                
            }

            It "Should call the set method to update the service account pool" {
                Set-TargetResource @testParams

                Assert-MockCalled Set-SPServiceApplicationPool 
            }
        }

        Context -Name "A service account pool exists and uses the correct account" -Fixture {
            $testParams = @{
                Name = "Service pool"
                ServiceAccount = "DEMO\svcSPServiceApps"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPServiceApplicationPool -MockWith { 
                return @{
                    Name = $testParams.Name
                    ProcessAccountName = $testParams.ServiceAccount
                }
            }

            It "retrieves present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        Context -Name "When the service app pool exists but it shouldn't" -Fixture {
            $testParams = @{
                Name = "Service pool"
                ServiceAccount = "DEMO\svcSPServiceApps"
                Ensure = "Absent"
            }

            Mock -CommandName Get-SPServiceApplicationPool -MockWith { 
                return @{
                    Name = $testParams.Name
                    ProcessAccountName = $testParams.ServiceAccount
                }
            }
            
            It "Should return present from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present" 
            }
            
            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "Should remove the service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPServiceApplicationPool
            }
        }
        
        Context -Name "When the service app pool doesn't exist and shouldn't" -Fixture {
            $testParams = @{
                Name = "Service pool"
                ServiceAccount = "DEMO\svcSPServiceApps"
                Ensure = "Absent"
            }

            Mock -CommandName Get-SPServiceApplicationPool -MockWith { 
                return $null 
            }
            
            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }
            
            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
