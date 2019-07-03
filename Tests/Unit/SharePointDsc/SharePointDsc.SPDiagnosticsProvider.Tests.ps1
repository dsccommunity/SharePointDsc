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
    -DscResource "SPDiagnosticsProvider"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        Mock -CommandName Get-SPDiagnosticsProvider -MockWith {
            return @{
                Name                = "job-diagnostics-blocking-query-provider"
                MaxTotalSizeInBytes = 100000
                Retention           = 14
                Enabled             = $true
            } | Add-Member ScriptMethod Update {
            } -PassThru
        }

        Mock -CommandName Set-SPDiagnosticsProvider -MockWith { }

        Context -Name "When the Diagnostics Provider passed doesn't exist" -Fixture {

            $testParams = @{
                Name                = "MyFakeProvider"
                Retention           = 13
                MaxTotalSizeInBytes = 10000
                Enabled             = $true
                Ensure              = "Present"
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an error about a non-existing provider" {
                { Set-TargetResource @testParams } | Should throw "The specified Diagnostic Provider {MyFakeProvider} could not be found."
            }

            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should be "Absent"
            }
        }

        Context -Name "When the Diagnostics Provider exists" -Fixture {

            $testParams = @{
                Name                = "job-diagnostics-blocking-query-provider"
                Retention           = 13
                MaxTotalSizeInBytes = 10000
                Enabled             = $true
                Ensure              = "Present"
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should properly configure the provider" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPDiagnosticsProvider
            }

            It "Should return a Retention period of 14 from the Get method" {
                (Get-TargetResource @testParams).Retention | Should be 14
            }
        }

        Context -Name "When using Ensure is Absent" -Fixture {

            $testParams = @{
                Name                = "job-diagnostics-blocking-query-provider"
                Retention           = 13
                MaxTotalSizeInBytes = 10000
                Enabled             = $true
                Ensure              = "Absent"
            }

            It "Should properly configure the provider" {
                { Set-TargetResource @testParams } | Should throw "This resource cannot remove Diagnostics Provider. Please use ensure equals Present."
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
