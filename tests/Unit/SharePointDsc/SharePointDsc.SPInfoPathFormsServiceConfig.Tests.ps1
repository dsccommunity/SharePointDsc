[CmdletBinding()]
param(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
            -Resolve)
)

$script:DSCModuleName = 'SharePointDsc'
$script:DSCResourceName = 'SPInfoPathFormsServiceConfig'
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
            -DscResource $script:DSCResourceName
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

            Mock -CommandName Get-SPInfoPathFormsService -MockWith {
                return @{
                    Ensure                                   = "Present"
                    AllowUserFormBrowserEnabling             = $true
                    AllowUserFormBrowserRendering            = $true
                    MaxDataConnectionTimeout                 = 20000
                    DefaultDataConnectionTimeout             = 10000
                    MaxDataConnectionResponseSize            = 1500
                    RequireSslForDataConnections             = $true
                    AllowEmbeddedSqlForDataConnections       = $false
                    AllowUdcAuthenticationForDataConnections = $false
                    AllowUserFormCrossDomainDataConnections  = $false
                    AllowEventPropagation                    = $false
                    MaxPostbacksPerSession                   = 75
                    MaxUserActionsPerPostback                = 200
                    ActiveSessionsTimeout                    = 1440
                    MaxSizeOfUserFormState                   = 4194304
                } | Add-Member ScriptMethod Update {
                    $global:InfoPathSettingsUpdated = $true
                } -PassThru
            }

            Context -Name "When the InfoPath Form Services is null" -Fixture {
                Mock -CommandName Get-SPInfoPathFormsService -MockWith {
                    return $null
                }

                $testParams = @{
                    IsSingleInstance                         = "Yes"
                    Ensure                                   = "Present"
                    AllowUserFormBrowserEnabling             = $false
                    AllowUserFormBrowserRendering            = $true
                    MaxDataConnectionTimeout                 = 20000
                    DefaultDataConnectionTimeout             = 10000
                    MaxDataConnectionResponseSize            = 1500
                    RequireSslForDataConnections             = $true
                    AllowEmbeddedSqlForDataConnections       = $false
                    AllowUdcAuthenticationForDataConnections = $false
                    AllowUserFormCrossDomainDataConnections  = $false
                    AllowEventPropagation                    = $false
                    MaxPostbacksPerSession                   = 75
                    MaxUserActionsPerPostback                = 200
                    ActiveSessionsTimeout                    = 1440
                    MaxSizeOfUserFormState                   = 4096
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "When trying to remove configurations" -Fixture {
                $testParams = @{
                    IsSingleInstance                         = "Yes"
                    Ensure                                   = "Absent"
                    AllowUserFormBrowserEnabling             = $false
                    AllowUserFormBrowserRendering            = $true
                    MaxDataConnectionTimeout                 = 20000
                    DefaultDataConnectionTimeout             = 10000
                    MaxDataConnectionResponseSize            = 1500
                    RequireSslForDataConnections             = $true
                    AllowEmbeddedSqlForDataConnections       = $false
                    AllowUdcAuthenticationForDataConnections = $false
                    AllowUserFormCrossDomainDataConnections  = $false
                    AllowEventPropagation                    = $false
                    MaxPostbacksPerSession                   = 75
                    MaxUserActionsPerPostback                = 200
                    ActiveSessionsTimeout                    = 1440
                    MaxSizeOfUserFormState                   = 4096
                }

                It "Should return false when the Test method is called" {
                    { Set-TargetResource @testParams } | Should -Throw "This resource cannot undo InfoPath Forms Service Configuration changes. " `
                        "Please set Ensure to Present or omit the resource"
                }
            }

            Context -Name "When the InfoPath Form Services is not properly configured" -Fixture {
                $testParams = @{
                    IsSingleInstance                         = "Yes"
                    Ensure                                   = "Present"
                    AllowUserFormBrowserEnabling             = $false
                    AllowUserFormBrowserRendering            = $false
                    MaxDataConnectionTimeout                 = 20001
                    DefaultDataConnectionTimeout             = 10001
                    MaxDataConnectionResponseSize            = 1501
                    RequireSslForDataConnections             = $false
                    AllowEmbeddedSqlForDataConnections       = $true
                    AllowUdcAuthenticationForDataConnections = $true
                    AllowUserFormCrossDomainDataConnections  = $true
                    AllowEventPropagation                    = $true
                    MaxPostbacksPerSession                   = 76
                    MaxUserActionsPerPostback                = 201
                    ActiveSessionsTimeout                    = 1439
                    MaxSizeOfUserFormState                   = 4095
                }

                It "Should return true when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should return the proper MaxSizeOfUserFormState value" {
                    (Get-TargetResource @testParams).MaxSizeOfUserFormState | Should -Be 4096
                }

                $global:InfoPathSettingsUpdated = $false
                It "Should properly configure the InfoPath Forms Service" {
                    Set-TargetResource @testParams
                    $global:InfoPathSettingsUpdated | Should -Be $true
                }
            }

            Context -Name "When the InfoPath Form Services is properly configured" -Fixture {
                $testParams = @{
                    IsSingleInstance                         = "Yes"
                    Ensure                                   = "Present"
                    AllowUserFormBrowserEnabling             = $true
                    AllowUserFormBrowserRendering            = $true
                    MaxDataConnectionTimeout                 = 20000
                    DefaultDataConnectionTimeout             = 10000
                    MaxDataConnectionResponseSize            = 1500
                    RequireSslForDataConnections             = $true
                    AllowEmbeddedSqlForDataConnections       = $false
                    AllowUdcAuthenticationForDataConnections = $false
                    AllowUserFormCrossDomainDataConnections  = $false
                    AllowEventPropagation                    = $false
                    MaxPostbacksPerSession                   = 75
                    MaxUserActionsPerPostback                = 200
                    ActiveSessionsTimeout                    = 1440
                    MaxSizeOfUserFormState                   = 4096
                }

                It "Should return true when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $true
                }

                It "Should return the proper MaxSizeOfUserFormState value" {
                    (Get-TargetResource @testParams).MaxSizeOfUserFormState | Should -Be 4096
                }

                It "Should properly configure the InfoPath Forms Service" {
                    Set-TargetResource @testParams
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
