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
                                              -DscResource "SPDistributedCacheClientSettings" `
                                              -IncludeDistributedCacheStubs

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Mocks for all contexts

        Mock -CommandName Set-SPDistributedCacheClientSetting{}
        Mock -CommandName Get-SPDistributedCacheClientSetting -MockWith {
            return @{
                MaxConnectionsToServer = 3
                RequestTimeout = 1000
                ChannelOpenTimeOut = 1000
        } }

        # Test contexts
        Context -Name "Ensure is set to Absent" -Fixture {
            $testParams = @{
                Ensure = "Absent"
            }

            It "Should throw an error complaining that Ensure can't be Absent" {
                { Set-TargetResource @testParams } | Should Throw "The SPDistributedCacheClientSettings resource only supports Ensure='Present'."
            }
        }

        Context -Name "Some Distributed Cache Client Settings are Properly Configured" -Fixture {
            $testParams = @{
                Ensure = "Present"
                DTCChannelOpenTimeOut = 1500
                DSCMaxConnectionsToServer = 5
            }

            It "Should return Ensure equals Present" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should properly set the settings" {
                Set-TargetResource @testParams
            }

            It "Should successfully test the resource" {
                (Test-TargetResource @testParams) | Should Be $true
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
