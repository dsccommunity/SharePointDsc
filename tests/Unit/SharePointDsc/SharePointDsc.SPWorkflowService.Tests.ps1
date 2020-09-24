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
$script:DSCResourceName = 'SPWorkflowService'
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
    InModuleScope -ModuleName $script:DSCResourceFullName -ScriptBlock {
        Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
            BeforeAll {
                Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

                # Initialize tests

                # Mocks for all contexts
                Mock -CommandName Get-SPWorkflowServiceApplicationProxy -MockWith {
                    return @(@{
                            Value = $true
                        } | Add-Member -MemberType ScriptMethod `
                            -Name GetHostname `
                            -Value {
                            return "http://workflow.sharepoint.com"
                        } -PassThru `
                        | Add-Member -MemberType ScriptMethod `
                            -Name GetWorkflowScopeName `
                            -Value {
                            return "SharePoint"
                        } -PassThru)
                }

                Mock -CommandName Get-SPSite -MockWith {
                    return @(
                        @{
                            Url = "http://sites.sharepoint.com"
                        }
                    )
                }

                Mock -CommandName Register-SPWorkflowService -MockWith { }
            }

            # Test contexts
            Context -Name "Specified Site Collection does not exist" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WorkflowHostUri = "http://workflow.sharepoint.com"
                        SPSiteUrl       = "http://sites.sharepoint.com"
                        AllowOAuthHttp  = $true
                    }

                    Mock -CommandName Get-SPSite -MockWith { return @($null) }

                    Mock -CommandName Get-SPWorkflowServiceApplicationProxy -MockWith {
                        return $null
                    }
                }

                It "return error that invalid the specified site collection doesn't exist" {
                    { Set-TargetResource @testParams } | Should -Throw "Specified site collection could not be found."
                }

                It "return empty workflow service instance" {
                    $result = Get-TargetResource @testParams
                    $result.WorkflowHostUri | Should -Be $null
                    $result.SPSiteUrl | Should -Be "http://sites.sharepoint.com"
                    $result.ScopeName | Should -Be $null
                }

                It "return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "both the specified Site Collection and Workflow Service exist and are accessible" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WorkflowHostUri = "http://workflow.sharepoint.com"
                        SPSiteUrl       = "http://sites.sharepoint.com"
                        AllowOAuthHttp  = $true
                    }

                    Mock -CommandName Register-SPWorkflowService -MockWith {
                        return @(@{
                                Value = $true
                            })
                    }
                }

                It "properly creates the workflow service proxy" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Register-SPWorkflowService -ParameterFilter { $ScopeName -eq $null -and $WorkflowHostUri -eq "http://workflow.sharepoint.com" }
                }

                It "returns the workflow service instance" {
                    $result = Get-TargetResource @testParams
                    $result.WorkflowHostUri | Should -Be "http://workflow.sharepoint.com"
                    $result.SPSiteUrl = "http://sites.sharepoint.com"
                    $result.ScopeName | Should -Be "SharePoint"
                    Assert-MockCalled Get-SPWorkflowServiceApplicationProxy
                }

                It "return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "workflow host URL is incorrect" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WorkflowHostUri = "http://new-workflow.sharepoint.com"
                        ScopeName       = "SharePoint"
                        SPSiteUrl       = "http://sites.sharepoint.com"
                        AllowOAuthHttp  = $true
                    }
                }

                It "properly creates the workflow service proxy" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Register-SPWorkflowService -ParameterFilter { $ScopeName -eq "SharePoint" -and $WorkflowHostUri -eq "http://new-workflow.sharepoint.com" }
                }

                It "return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "workflow scope name is incorrect" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WorkflowHostUri = "http://workflow.sharepoint.com"
                        ScopeName       = "AnotherScope"
                        SPSiteUrl       = "http://sites.sharepoint.com"
                        AllowOAuthHttp  = $true
                    }
                }

                It "return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "workflow host URL contains a trailing forward slash" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WorkflowHostUri = "http://workflow.sharepoint.com/"
                        SPSiteUrl       = "http://sites.sharepoint.com"
                        AllowOAuthHttp  = $true
                    }
                }

                It "return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
