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
$script:DSCResourceName = 'SPWebAppPropertyBag'
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

                Mock -CommandName Get-SPWebApplication -MockWith {
                    $spWebApp = [pscustomobject]@{
                        Properties = @{
                            PropertyKey = 'PropertyValue'
                        }
                    }
                    $spWebApp = $spWebApp | Add-Member ScriptMethod Update {
                        $Global:SPDscWebApplicationPropertyUpdated = $true
                    } -PassThru
                    $spWebApp = $spWebApp | Add-Member ScriptMethod Remove {
                        $Global:SPDscWebApplicationPropertyUpdated = $true
                    } -PassThru
                    return $spWebApp
                }
            }

            Context -Name 'The web application does not exist' -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Key       = 'PropertyKey'
                        Value     = 'NewPropertyValue'
                    }
                    Mock -CommandName Get-SPWebApplication -MockWith {
                        return $null
                    }
                }

                It 'Should return Ensure=absent and Value=null from the get method' {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be 'absent'
                    $result.Value | Should -Be $null
                }
            }

            Context -Name 'The web application property value does not match' -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Key       = 'PropertyKey'
                        Value     = 'NewPropertyValue'
                        Ensure    = 'Present'
                    }
                }

                It 'Should return Ensure=present and Key=inserted value from the get method' {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be 'present'
                    $result.Key | Should -Be $testParams.Key
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It 'Should not throw an exception in the set method' {
                    { Set-TargetResource @testParams } | Should -Not -Throw
                }

                It 'Calls Get-SPWebApplication and update web application property bag from the set method' {
                    $Global:SPDscWebApplicationPropertyUpdated = $false
                    Set-TargetResource @testParams

                    $Global:SPDscWebApplicationPropertyUpdated | Should -Be $true
                }
            }

            Context -Name 'The web application property exists, and the value match' -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Key       = 'PropertyKey'
                        Value     = 'PropertyValue'
                        Ensure    = 'Present'
                    }
                }

                It 'Should return Ensure=present and Key/Value=inserted values from the get method' {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be 'present'
                    $result.Key | Should -Be $testParams.Key
                    $result.value | Should -Be $testParams.value
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name 'The web application property does not exist, and should be removed' -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Key       = 'NonExistingPropertyKey'
                        Value     = 'PropertyValue'
                        Ensure    = 'Absent'
                    }
                }

                It 'Should return Ensure=absent, Key=inserted value and Value=null from the get method' {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be 'absent'
                    $result.Key | Should -Be $testParams.Key
                    $result.value | Should -Be $null
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name 'The web application property exists, and should not be' -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sharepoint.contoso.com"
                        Key       = 'PropertyKey'
                        Value     = 'PropertyValue'
                        Ensure    = 'Absent'
                    }
                }

                It 'Should return Ensure=Present and Key/Value=inserted value from the get method' {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be 'Present'
                    $result.Key | Should -Be $testParams.Key
                    $result.value | Should -Be $testParams.Value
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It 'Should not throw an exception in the set method' {
                    { Set-TargetResource @testParams } | Should -Not -Throw
                }

                It 'Calls Get-SPWebApplication and remove web application property bag from the set method' {
                    $Global:SPDscWebApplicationPropertyUpdated = $false
                    Set-TargetResource @testParams

                    $Global:SPDscWebApplicationPropertyUpdated | Should -Be $true
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
