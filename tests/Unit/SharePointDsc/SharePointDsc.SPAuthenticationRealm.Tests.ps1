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
$script:DSCResourceName = 'SPAuthenticationRealm'
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

            Mock -CommandName Get-SPAuthenticationRealm {
                return $Global:SPAuthenticationRealm
            }

            Mock -CommandName Set-SPAuthenticationRealm {
                $Global:SPAuthenticationRealm = $Realm
            }

            Context -Name "Authentication realm matches the farm's current atuhentication realm" -Fixture {
                $Global:SPAuthenticationRealm = "14757a87-4d74-4323-83b9-fb1e77e8f22f"
                $testParams = @{
                    IsSingleInstance    = "Yes"
                    AuthenticationRealm = $Global:SPAuthenticationRealm
                }

                It "Should return true from the set method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }

            Context -Name "Authentication realm does not match the farm's current atuhentication realm" -Fixture {
                $Global:SPAuthenticationRealm = "11111111-1111-1111-1111-111111111111"

                $testParams = @{
                    IsSingleInstance    = "Yes"
                    AuthenticationRealm = "14757a87-4d74-4323-83b9-fb1e77e8f22f"
                }

                It "Should return false from the set method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "Should modify the authentication realm in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName Set-SPAuthenticationRealm -Times 1
                    $Global:SPAuthenticationRealm | Should Be "14757a87-4d74-4323-83b9-fb1e77e8f22f"
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
