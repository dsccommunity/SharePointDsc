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
                                              -DscResource "SPServiceInstance"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Mocks for all contexts   
        Mock -CommandName Start-SPServiceInstance -MockWith { }
        Mock -CommandName Stop-SPServiceInstance -MockWith { }

        # Test contexts
        Context -Name "The service instance is not running but should be" -Fixture {
            $testParams = @{
                Name = "Service pool"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPServiceInstance -MockWith { 
                return @() 
            }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the set method" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context -Name "The service instance is not running but should be" -Fixture {
            $testParams = @{
                Name = "Service pool"
                Ensure = "Present"
            }
            
            Mock -CommandName Get-SPServiceInstance -MockWith { 
                return @(@{
                    TypeName = $testParams.Name
                    Status = "Disabled"
                })
            }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the set method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call the start service call from the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Start-SPServiceInstance
            }
        }

        Context -Name "The service instance is running and should be" -Fixture {
            $testParams = @{
                Name = "Service pool"
                Ensure = "Present"
            }
            
            Mock -CommandName Get-SPServiceInstance -MockWith { 
                return @(@{
                    TypeName = $testParams.Name
                    Status = "Online"
                })
            }

            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "An invalid service application is specified to start" -Fixture {
            $testParams = @{
                Name = "Service pool"
                Ensure = "Present"
            }
            
            Mock -CommandName Get-SPServiceInstance  { 
                return $null 
            }

            It "Should throw when the set method is called" {
                { Set-TargetResource @testParams } | Should Throw
            }
        }

        Context -Name "The service instance is not running and should not be" -Fixture {
            $testParams = @{
                Name = "Service pool"
                Ensure = "Absent"
            }
            
            Mock -CommandName Get-SPServiceInstance -MockWith { 
                return @(@{
                    TypeName = $testParams.Name
                    Status = "Disabled"
                })
            }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "The service instance is running and should not be" -Fixture {
            $testParams = @{
                Name = "Service pool"
                Ensure = "Absent"
            }
            
            Mock -CommandName Get-SPServiceInstance -MockWith { 
                return @(@{
                    TypeName = $testParams.Name
                    Status = "Online"
                })
            }

            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return false from the set method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call the stop service call from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Stop-SPServiceInstance
            }
        }

        Context -Name "An invalid service application is specified to stop" -Fixture {
            $testParams = @{
                Name = "Service pool"
                Ensure = "Absent"
            }
            
            Mock -CommandName Get-SPServiceInstance  { 
                return $null 
            }

            It "Should throw when the set method is called" {
                { Set-TargetResource @testParams } | Should Throw
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
