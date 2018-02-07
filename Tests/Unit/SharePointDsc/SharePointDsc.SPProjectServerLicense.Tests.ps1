[CmdletBinding()]
param(
    [Parameter()]
    [string] 
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
                                         -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
                                         -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
                                -ChildPath "..\UnitTestHelper.psm1" `
                                -Resolve)

$Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
                                              -DscResource "SPProjectServerLicense"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major) 
        {
            15 {
                Context -Name "All methods throw exceptions as Project Server support in SharePointDsc is only for 2016" -Fixture {
                    It "Should throw on the get method" {
                        { Get-TargetResource @testParams } | Should Throw
                    }

                    It "Should throw on the test method" {
                        { Test-TargetResource @testParams } | Should Throw
                    }

                    It "Should throw on the set method" {
                        { Set-TargetResource @testParams } | Should Throw
                    }
                }
            }
            16 {
                Mock -CommandName Enable-ProjectServerLicense -MockWith { }
                Mock -CommandName Disable-ProjectServerLicense -MockWith { }

                Context -Name "Project server license is not enabled, but it should be" -Fixture {
                    $testParams = @{
                        Ensure     = "Present"
                        ProductKey = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
                    }

                    Mock -CommandName Get-ProjectServerLicense -MockWith {
                        return "Project Server 2016 : Disabled"
                    }

                    It "Should return absent from the Get method" {
                        (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
                    }
        
                    It "Should return false when the Test method is called" {
                        Test-TargetResource @testParams | Should Be $false
                    }
        
                    It "Should enable the license in the set method" {
                        Set-TargetResource @testParams
                        Assert-MockCalled Enable-ProjectServerLicense
                    }
                }

                Context -Name "Project server license is enabled, and it should be" -Fixture {
                    $testParams = @{
                        Ensure     = "Present"
                        ProductKey = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
                    }

                    Mock -CommandName Get-ProjectServerLicense -MockWith {
                        return "Project Server 2016 : Active"
                    }

                    It "Should return present from the Get method" {
                        (Get-TargetResource @testParams).Ensure | Should Be "Present" 
                    }
        
                    It "Should return true when the Test method is called" {
                        Test-TargetResource @testParams | Should Be $true
                    }
                }

                Context -Name "Project server license is enabled, but it should not be" -Fixture {
                    $testParams = @{
                        Ensure     = "Absent"
                    }

                    Mock -CommandName Get-ProjectServerLicense -MockWith {
                        return "Project Server 2016 : Active"
                    }

                    It "Should return present from the Get method" {
                        (Get-TargetResource @testParams).Ensure | Should Be "Present" 
                    }
        
                    It "Should return false when the Test method is called" {
                        Test-TargetResource @testParams | Should Be $false
                    }
        
                    It "Should enable the license in the set method" {
                        Set-TargetResource @testParams
                        Assert-MockCalled Disable-ProjectServerLicense
                    }
                }

                Context -Name "Project server license is not enabled, and it should not be" -Fixture {
                    $testParams = @{
                        Ensure     = "Absent"
                    }

                    Mock -CommandName Get-ProjectServerLicense -MockWith {
                        return "Project Server 2016 : Disabled"
                    }

                    It "Should return absent from the Get method" {
                        (Get-TargetResource @testParams).Ensure | Should Be "absent" 
                    }
        
                    It "Should return true when the Test method is called" {
                        Test-TargetResource @testParams | Should Be $true
                    }
                }

                Context -Name "The farm is not in a state to determine the license status" -Fixture {
                    $testParams = @{
                        Ensure     = "Present"
                        ProductKey = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
                    }

                    Mock -CommandName Get-ProjectServerLicense -MockWith {
                        throw "Unkown error"
                    }

                    It "Should return absent from the Get method" {
                        (Get-TargetResource @testParams).Ensure | Should Be "absent" 
                    }
                }

                Context -Name "The license should be enabled but no product key was provided" -Fixture {
                    $testParams = @{
                        Ensure     = "Present"
                    }

                    Mock -CommandName Get-ProjectServerLicense -MockWith {
                        return "Project Server 2016 : Disabled"
                    }

                    It "Should throw an error in the set method" {
                        { Set-TargetResource @testParams } | Should Throw
                    }
                }
            }
            Default {
                throw [Exception] "A supported version of SharePoint was not used in testing"
            }
        }
    }
}
