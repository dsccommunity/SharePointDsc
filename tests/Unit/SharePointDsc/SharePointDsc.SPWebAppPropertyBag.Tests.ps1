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

            Context -Name 'The web application does not exist' -Fixture {
                $testParams = @{
                    WebAppUrl = "http://sharepoint.contoso.com"
                    Key       = 'PropertyKey'
                    Value     = 'NewPropertyValue'
                }
                Mock -CommandName Get-SPWebApplication -MockWith {
                    return $null
                }

                $result = Get-TargetResource @testParams

                It 'Should return absent from the get method' {
                    $result.Ensure | Should Be 'absent'
                }

                It 'Should return null value from the get method' {
                    $result.Value | Should Be $null
                }
            }

            Context -Name 'The web application property value does not match' -Fixture {
                $testParams = @{
                    WebAppUrl = "http://sharepoint.contoso.com"
                    Key       = 'PropertyKey'
                    Value     = 'NewPropertyValue'
                    Ensure    = 'Present'
                }

                $result = Get-TargetResource @testParams

                It 'Should return present from the get method' {
                    $result.Ensure | Should Be 'present'
                }

                It 'Should return the same key value as passed as parameter' {
                    $result.Key | Should Be $testParams.Key
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParams | Should Be $false
                }

                It 'Should not throw an exception in the set method' {
                    { Set-TargetResource @testParams } | Should not throw
                }

                $Global:SPDscWebApplicationPropertyUpdated = $false
                It 'Calls Get-SPWebApplication and update web application property bag from the set method' {
                    Set-TargetResource @testParams

                    $Global:SPDscWebApplicationPropertyUpdated | Should Be $true
                }
            }

            Context -Name 'The web application property exists, and the value match' -Fixture {
                $testParams = @{
                    WebAppUrl = "http://sharepoint.contoso.com"
                    Key       = 'PropertyKey'
                    Value     = 'PropertyValue'
                    Ensure    = 'Present'
                }

                $result = Get-TargetResource @testParams

                It 'Should return present from the get method' {
                    $result.Ensure | Should Be 'present'
                }

                It 'Should return the same values as passed as parameters' {
                    $result.Key | Should Be $testParams.Key
                    $result.value | Should Be $testParams.value
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParams | Should Be $true
                }
            }

            Context -Name 'The web application property does not exist, and should be removed' -Fixture {
                $testParams = @{
                    WebAppUrl = "http://sharepoint.contoso.com"
                    Key       = 'NonExistingPropertyKey'
                    Value     = 'PropertyValue'
                    Ensure    = 'Absent'
                }

                $result = Get-TargetResource @testParams

                It 'Should return absent from the get method' {
                    $result.Ensure | Should Be 'absent'
                }

                It 'Should return the same key as passed as parameter and null value.' {
                    $result.Key | Should Be $testParams.Key
                    $result.value | Should Be $null
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParams | Should Be $true
                }
            }

            Context -Name 'The web application property exists, and should not be' -Fixture {
                $testParams = @{
                    WebAppUrl = "http://sharepoint.contoso.com"
                    Key       = 'PropertyKey'
                    Value     = 'PropertyValue'
                    Ensure    = 'Absent'
                }

                $result = Get-TargetResource @testParams

                It 'Should return Present from the get method' {
                    $result.Ensure | Should Be 'Present'
                }

                It 'Should return the same values as passed as parameters' {
                    $result.Key | Should Be $testParams.Key
                    $result.value | Should Be $testParams.Value
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParams | Should Be $false
                }

                It 'Should not throw an exception in the set method' {
                    { Set-TargetResource @testParams } | Should not throw
                }

                $Global:SPDscWebApplicationPropertyUpdated = $false
                It 'Calls Get-SPWebApplication and remove web application property bag from the set method' {
                    Set-TargetResource @testParams

                    $Global:SPDscWebApplicationPropertyUpdated | Should Be $true
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
