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
$script:DSCResourceName = 'SPAppDomain'
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
            -ModuleVersion $moduleVersionFolder
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

Invoke-TestSetup -ModuleVersion $moduleVersion

try
{
    Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
        InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
            Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

            # Mocks for all contexts
            Mock -CommandName Set-SPAppDomain -MockWith { }
            Mock -CommandName Set-SPAppSiteSubscriptionName -MockWith { }

            # Test contexts
            Context -Name "No app URLs have been configured locally" -Fixture {
                $testParams = @{
                    AppDomain = "apps.contoso.com"
                    Prefix    = "apps"
                }

                Mock -CommandName Get-SPAppDomain -MockWith { }
                Mock -CommandName Get-SPAppSiteSubscriptionName -MockWith { }

                It "Should return values from the get method" {
                    Get-TargetResource @testParams | Should Not BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "Should save settings when the set method is run" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-SPAppDomain
                    Assert-MockCalled Set-SPAppSiteSubscriptionName
                }
            }

            Context -Name "Incorrect app URLs have been configured locally" -Fixture {
                $testParams = @{
                    AppDomain = "apps.contoso.com"
                    Prefix    = "apps"
                }

                Mock -CommandName Get-SPAppDomain -MockWith { return "wrong.domain" }
                Mock -CommandName Get-SPAppSiteSubscriptionName -MockWith { return "wrongprefix" }

                It "Should return values from the get method" {
                    Get-TargetResource @testParams | Should Not BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "Should save settings when the set method is run" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-SPAppDomain
                    Assert-MockCalled Set-SPAppSiteSubscriptionName
                }
            }

            Context -Name "Correct app URLs have been configured locally" -Fixture {
                $testParams = @{
                    AppDomain = "apps.contoso.com"
                    Prefix    = "apps"
                }

                Mock -CommandName Get-SPAppDomain -MockWith { return $testParams.AppDomain }
                Mock -CommandName Get-SPAppSiteSubscriptionName -MockWith { $testParams.Prefix }

                It "Should return values from the get method" {
                    Get-TargetResource @testParams | Should Not BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
