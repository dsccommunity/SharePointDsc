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
                DLTCMaxConnectionsToServer = 5
                DLTCRequestTimeout = 1000
                DLTCChannelOpenTimeOut = 1000
                DVSCMaxConnectionsToServer = 3
                DVSCRequestTimeout = 1000
                DVSCChannelOpenTimeOut = 1000
                DACMaxConnectionsToServer = 3
                DACRequestTimeout = 1000
                DACChannelOpenTimeOut = 1000
                DAFMaxConnectionsToServer = 3
                DAFRequestTimeout = 1000
                DAFChannelOpenTimeOut = 1000
                DAFCMaxConnectionsToServer = 3
                DAFCRequestTimeout = 1000
                DAFCChannelOpenTimeOut = 1000
                DBCMaxConnectionsToServer = 3
                DBCRequestTimeout = 1000
                DBCChannelOpenTimeOut = 1000
                DDCMaxConnectionsToServer = 3
                DDCRequestTimeout = 1000
                DDCChannelOpenTimeOut = 1000
                DSCMaxConnectionsToServer = 5
                DSCRequestTimeout = 1000
                DSCChannelOpenTimeOut = 1000
                DTCMaxConnectionsToServer = 3
                DTCRequestTimeout = 1000
                DTCChannelOpenTimeOut = 1500
                DSTACMaxConnectionsToServer = 3
                DSTACRequestTimeout = 1000
                DSTACChannelOpenTimeOut = 1000
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
