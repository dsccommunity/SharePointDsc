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
                                              -DscResource "SPWorkflowService"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests

        # Mocks for all contexts

        # Test contexts
        Context -Name "Specified Site Collection does not exist" -Fixture {
            $testParams = @{
                WorkflowHostUri = "http://workflow.sharepoint.com"
                SPSiteUrl = "http://sites.sharepoint.com"
                AllowOAuthHttp = $true
            }

            Mock -CommandName Get-SPSite -MockWith {return @($null)}

            Mock -CommandName Get-SPWorkflowServiceApplicationProxy -MockWith{
                return $null
            }

            It "return error that invalid the specified site collection doesn't exist" {
                { Set-TargetResource @testParams } | Should Throw "Specified site collection could not be found."
            }

            It "return empty workflow service instance"{
                (Get-TargetResource @testParams).WorkflowHostUri  | Should Be $null
            }

            It "return false from the test method"{
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context -Name "both the specified Site Collection and Workflow Service exist and are accessible" -Fixture {
            $testParams = @{
                WorkflowHostUri = "http://workflow.sharepoint.com"
                SPSiteUrl = "http://sites.sharepoint.com"
                AllowOAuthHttp = $true
            }

            Mock -CommandName Get-SPSite -MockWith {return @(@{
                    Url = "http://sites.sharepoint.com"
                }
            )}

            Mock -CommandName Register-SPWorkflowService -MockWith{
                return @(@{
                    Value = $true
                })
            }

            Mock -CommandName Get-SPWorkflowServiceApplicationProxy -MockWith{
                return @(@{
                    Value = $true
                } | Add-Member -MemberType ScriptMethod `
                                         -Name GetHostname `
                                         -Value {
                                            return "http://workflow.sharepoint.com"
                                        } -PassThru)
            }

            It "properly creates the workflow service proxy" {
                Set-TargetResource @testParams
                Assert-MockCalled Register-SPWorkflowService
            }

            It "returns the workflow service instance" {
                (Get-TargetResource @testParams).WorkflowHostUri | Should Be "http://workflow.sharepoint.com"
                Assert-MockCalled Get-SPWorkflowServiceApplicationProxy
            }

            It "return true from the test method"{
                Test-TargetResource @testParams |  Should Be $true
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
