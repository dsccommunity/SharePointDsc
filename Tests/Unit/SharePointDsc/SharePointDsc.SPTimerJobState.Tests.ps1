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
                                              -DscResource "SPTimerJobState"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests

        # Mocks for all contexts   
        Mock -CommandName Set-SPTimerJob -MockWith { 
            return $null 
        }
        Mock -CommandName Get-SPFarm -MockWith { 
            return @{} 
        }

        # Test contexts
        Context -Name "The server is not part of SharePoint farm" -Fixture {
            $testParams = @{
                Name = "job-spapp-statequery"
                Enabled = $true
                Schedule = "hourly between 0 and 59"
            }

            Mock -CommandName Get-SPFarm -MockWith { 
                throw "Unable to detect local farm" 
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Be $null
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an exception in the set method to say there is no local farm" {
                { Set-TargetResource @testParams } | Should throw "No local SharePoint farm was detected"
            }
        }

        Context -Name "The server is in a farm and the incorrect enabled settings have been applied" -Fixture {
            $testParams = @{
                Name = "job-spapp-statequery"
                Enabled = $true
                Schedule = "hourly between 0 and 59"
            }
            
            Mock -CommandName Get-SPTimerJob -MockWith {
                $returnVal = @{
                    Name = "job-spapp-statequery"
                    IsDisabled = $true
                    Schedule = "hourly between 0 and 59"
                }
                return @($returnVal)
            }

            It "Should return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should update the timerjob settings" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPTimerJob
            }
        }

        Context -Name "The server is in a farm and the incorrect schedule settings have been applied" -Fixture {
            $testParams = @{
                Name = "job-spapp-statequery"
                Enabled = $true
                Schedule = "hourly between 0 and 59"
            }
            
            Mock -CommandName Get-SPTimerJob -MockWith {
                $returnVal = @{
                    Name = "job-spapp-statequery"
                    IsDisabled = $false
                    Schedule = "weekly at sat 23:00:00"
                }
                return @($returnVal)
            }

            It "Should return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should update the timer job settings" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPTimerJob
            }
        }

        Context -Name "The server is in a farm and the incorrect schedule format has been used" -Fixture {
            $testParams = @{
                Name = "job-spapp-statequery"
                Enabled = $true
                Schedule = "hourly between 0 and 59"
            }
            
            Mock -CommandName Get-SPTimerJob -MockWith {
                $returnVal = @{
                    Name = "job-spapp-statequery"
                    IsDisabled = $false
                    Schedule = "incorrect format"
                }
                return @($returnVal)
            }

            Mock -CommandName Set-SPTimerJob -MockWith { 
                throw "Invalid Time: `"The time given was not given in the proper format. See: Get-Help Set-SPTimerJob -detailed`"" 
            }

            It "Should return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an exception because the incorrect schedule format is used" {
                { Set-TargetResource @testParams } | Should throw "Incorrect schedule format used. New schedule will not be applied."
            }
        }

        Context -Name "The server is in a farm and the correct settings have been applied" -Fixture {
            $testParams = @{
                Name = "job-spapp-statequery"
                Enabled = $true
                Schedule = "hourly between 0 and 59"
            }
            
            Mock -CommandName Get-SPTimerJob -MockWith {
                $returnVal = @{
                    Name = "job-spapp-statequery"
                    IsDisabled = $false
                    Schedule = "hourly between 0 and 59"
                }
                return @($returnVal)
            }

            It "Should return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
