[CmdletBinding()]
param
(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
            -Resolve)
)

$script:DSCModuleName = 'SharePointDsc'
$script:DSCResourceName = 'SPDistributedCacheClientSettings'
$script:DSCResourceFullName = 'MSFT_' + $script:DSCResourceName

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force

        Import-Module -Name (Join-Path -Path $PSScriptRoot `
                -ChildPath "..\UnitTestHelper.psm1" `
                -Resolve)

        $Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
            -DscResource $script:DSCResourceName `
            -IncludeDistributedCacheStubs
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:DSCModuleName `
        -DSCResourceName $script:DSCResourceFullName `
        -ResourceType 'Mof' `
        -TestType 'Unit'
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
        InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
            Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

            # Mocks for all contexts

            Mock -CommandName Set-SPDistributedCacheClientSetting { }

            # Test contexts
            Context -Name "Some Distributed Cache Client Settings are Not Properly Configured" -Fixture {
                Mock -CommandName Get-SPDistributedCacheClientSetting -MockWith {
                    return @{
                        MaxConnectionsToServer = 5
                        RequestTimeout         = 2000
                        ChannelOpenTimeOut     = 2000
                    } }
                $testParams = @{
                    IsSingleInstance            = "Yes"
                    DLTCMaxConnectionsToServer  = 3
                    DLTCRequestTimeout          = 1000
                    DLTCChannelOpenTimeOut      = 1000
                    DVSCMaxConnectionsToServer  = 3
                    DVSCRequestTimeout          = 1000
                    DVSCChannelOpenTimeOut      = 1000
                    DACMaxConnectionsToServer   = 3
                    DACRequestTimeout           = 1000
                    DACChannelOpenTimeOut       = 1000
                    DAFMaxConnectionsToServer   = 3
                    DAFRequestTimeout           = 1000
                    DAFChannelOpenTimeOut       = 1000
                    DAFCMaxConnectionsToServer  = 3
                    DAFCRequestTimeout          = 1000
                    DAFCChannelOpenTimeOut      = 1000
                    DBCMaxConnectionsToServer   = 3
                    DBCRequestTimeout           = 1000
                    DBCChannelOpenTimeOut       = 1000
                    DDCMaxConnectionsToServer   = 3
                    DDCRequestTimeout           = 1000
                    DDCChannelOpenTimeOut       = 1000
                    DSCMaxConnectionsToServer   = 3
                    DSCRequestTimeout           = 1000
                    DSCChannelOpenTimeOut       = 1000
                    DTCMaxConnectionsToServer   = 3
                    DTCRequestTimeout           = 1000
                    DTCChannelOpenTimeOut       = 1000
                    DSTACMaxConnectionsToServer = 3
                    DSTACRequestTimeout         = 1000
                    DSTACChannelOpenTimeOut     = 1000
                }

                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -ne 15)
                {
                    $testparams.add("DFLTCMaxConnectionsToServer", 3)
                    $testparams.add("DFLTCRequestTimeout", 1000)
                    $testparams.add("DFLTCChannelOpenTimeOut", 1000)
                    $testparams.add("DSWUCMaxConnectionsToServer", 3)
                    $testparams.add("DSWUCRequestTimeout", 1000)
                    $testparams.add("DSWUCChannelOpenTimeOut", 1000)
                    $testparams.add("DUGCMaxConnectionsToServer", 3)
                    $testparams.add("DUGCRequestTimeout", 1000)
                    $testparams.add("DUGCChannelOpenTimeOut", 1000)
                    $testparams.add("DRTCMaxConnectionsToServer", 3)
                    $testparams.add("DRTCRequestTimeout", 1000)
                    $testparams.add("DRTCChannelOpenTimeOut", 1000)
                    $testparams.add("DHSCMaxConnectionsToServer", 3)
                    $testparams.add("DHSCRequestTimeout", 1000)
                    $testparams.add("DHSCChannelOpenTimeOut", 1000)
                }

                It "Should return DLTCMaxConnectionsToServer equals 5" {
                    (Get-TargetResource @testParams).DLTCMaxConnectionsToServer | Should -Be 5
                }

                It "Should properly set the settings" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-SPDistributedCacheClientSetting
                }

                It "Should return false from Test-TargetResource" {
                    (Test-TargetResource @testParams) | Should -Be $false
                }
            }

            Context -Name "All Distributed Cache Client Settings are properly Configured" -Fixture {
                Mock -CommandName Get-SPDistributedCacheClientSetting -MockWith {
                    return @{
                        MaxConnectionsToServer = 1
                        RequestTimeout         = 3000
                        ChannelOpenTimeOut     = 3000
                    } }

                $testParams = @{
                    IsSingleInstance            = "Yes"
                    DLTCMaxConnectionsToServer  = 1
                    DLTCRequestTimeout          = 3000
                    DLTCChannelOpenTimeOut      = 3000
                    DVSCMaxConnectionsToServer  = 1
                    DVSCRequestTimeout          = 3000
                    DVSCChannelOpenTimeOut      = 3000
                    DACMaxConnectionsToServer   = 1
                    DACRequestTimeout           = 3000
                    DACChannelOpenTimeOut       = 3000
                    DAFMaxConnectionsToServer   = 1
                    DAFRequestTimeout           = 3000
                    DAFChannelOpenTimeOut       = 3000
                    DAFCMaxConnectionsToServer  = 1
                    DAFCRequestTimeout          = 3000
                    DAFCChannelOpenTimeOut      = 3000
                    DBCMaxConnectionsToServer   = 1
                    DBCRequestTimeout           = 3000
                    DBCChannelOpenTimeOut       = 3000
                    DDCMaxConnectionsToServer   = 1
                    DDCRequestTimeout           = 3000
                    DDCChannelOpenTimeOut       = 3000
                    DSCMaxConnectionsToServer   = 1
                    DSCRequestTimeout           = 3000
                    DSCChannelOpenTimeOut       = 3000
                    DTCMaxConnectionsToServer   = 1
                    DTCRequestTimeout           = 3000
                    DTCChannelOpenTimeOut       = 3000
                    DSTACMaxConnectionsToServer = 1
                    DSTACRequestTimeout         = 3000
                    DSTACChannelOpenTimeOut     = 3000
                }

                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -ne 15)
                {
                    $testparams.add("DFLTCMaxConnectionsToServer", 1)
                    $testparams.add("DFLTCRequestTimeout", 3000)
                    $testparams.add("DFLTCChannelOpenTimeOut", 3000)
                    $testparams.add("DSWUCMaxConnectionsToServer", 1)
                    $testparams.add("DSWUCRequestTimeout", 3000)
                    $testparams.add("DSWUCChannelOpenTimeOut", 3000)
                    $testparams.add("DUGCMaxConnectionsToServer", 1)
                    $testparams.add("DUGCRequestTimeout", 3000)
                    $testparams.add("DUGCChannelOpenTimeOut", 3000)
                    $testparams.add("DRTCMaxConnectionsToServer", 1)
                    $testparams.add("DRTCRequestTimeout", 3000)
                    $testparams.add("DRTCChannelOpenTimeOut", 3000)
                    $testparams.add("DHSCMaxConnectionsToServer", 1)
                    $testparams.add("DHSCRequestTimeout", 3000)
                    $testparams.add("DHSCChannelOpenTimeOut", 3000)
                }

                It "Should return DLTCMaxConnectionsToServer equals 5" {
                    (Get-TargetResource @testParams).DLTCMaxConnectionsToServer | Should -Be 1
                }

                It "Should return true from test the resource" {
                    (Test-TargetResource @testParams) | Should -Be $true
                }
            }

            if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
            {
                Context -Name "SP2016+ parameters specified with SP2013" -Fixture {
                    Mock -CommandName Get-SPDistributedCacheClientSetting -MockWith {
                        return @{
                            MaxConnectionsToServer = 1
                            RequestTimeout         = 3000
                            ChannelOpenTimeOut     = 3000
                        } }
                    $testParams = @{
                        IsSingleInstance            = "Yes"
                        DLTCMaxConnectionsToServer  = 1
                        DLTCRequestTimeout          = 3000
                        DLTCChannelOpenTimeOut      = 3000
                        DFLTCMaxConnectionsToServer = 1
                        DFLTCRequestTimeout         = 3000
                        DFLTCChannelOpenTimeOut     = 3000
                    }

                    It "Should throw exception in the Get method" {
                        { Get-TargetResource @testParams } | Should -Throw "The following parameters are only supported in SharePoint 2016 and above"
                    }

                    It "Should throw exception in the Set method" {
                        { Set-TargetResource @testParams } | Should -Throw "The following parameters are only supported in SharePoint 2016 and above"
                    }

                    It "Should throw exception in the Test method" {
                        { Test-TargetResource @testParams } | Should -Throw "The following parameters are only supported in SharePoint 2016 and above"
                    }
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
