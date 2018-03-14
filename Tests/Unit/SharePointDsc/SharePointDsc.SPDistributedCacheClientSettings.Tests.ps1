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
        Context -Name "Some Distributed Cache Client Settings are Not Properly Configured" -Fixture {
            $testParams = @{
                IsSingleInstance = "Yes"
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

            It "Should return IsSingleInstance equals Yes" {
                (Get-TargetResource @testParams).IsSingleInstance | Should Be "Yes"
            }

            It "Should properly set the settings" {
                Set-TargetResource @testParams
            }

            It "Should successfully test the resource" {
                (Test-TargetResource @testParams) | Should Be $false
            }
        }
        Context -Name "Some Distributed Cache Client Settings are Not Properly Configured" -Fixture {
            $testParams = @{
                IsSingleInstance = "Yes"
                DLTCMaxConnectionsToServer = 1
                DLTCRequestTimeout = 3000
                DLTCChannelOpenTimeOut = 3000
                DVSCMaxConnectionsToServer = 1
                DVSCRequestTimeout = 3000
                DVSCChannelOpenTimeOut = 3000
                DACMaxConnectionsToServer = 1
                DACRequestTimeout = 3000
                DACChannelOpenTimeOut = 3000
                DAFMaxConnectionsToServer = 1
                DAFRequestTimeout = 3000
                DAFChannelOpenTimeOut = 3000
                DAFCMaxConnectionsToServer = 1
                DAFCRequestTimeout = 3000
                DAFCChannelOpenTimeOut = 3000
                DBCMaxConnectionsToServer = 1
                DBCRequestTimeout = 3000
                DBCChannelOpenTimeOut = 3000
                DDCMaxConnectionsToServer = 1
                DDCRequestTimeout = 3000
                DDCChannelOpenTimeOut = 3000
                DSCMaxConnectionsToServer = 1
                DSCRequestTimeout = 3000
                DSCChannelOpenTimeOut = 3000
                DTCMaxConnectionsToServer = 1
                DTCRequestTimeout = 3000
                DTCChannelOpenTimeOut = 3000
                DSTACMaxConnectionsToServer = 1
                DSTACRequestTimeout = 3000
                DSTACChannelOpenTimeOut = 3000
            }
            It "Should successfully test the resource" {
                (Test-TargetResource @testParams) | Should Be $false
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
