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
$script:DSCResourceName = 'SPSitePropertyBag'
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

            Mock -CommandName Get-SPSite -MockWith {
                $spSite = [pscustomobject]@{
                    RootWeb = @{
                        Properties = @{
                            PropertyKey = 'PropertyValue'
                        }
                    }
                }

                $spSite = $spSite | Add-Member ScriptMethod OpenWeb {
                    $prop = @{
                        PropertyKey = 'PropertyValue'
                    }
                    $prop = $prop | Add-Member ScriptMethod Update {
                    } -PassThru

                    $returnval = @{
                        Properties    = $prop
                        AllProperties = @{ }
                    }

                    $returnval = $returnval | Add-Member ScriptMethod Update {
                        $Global:SPDscSitePropertyUpdated = $true
                    } -PassThru

                    return $returnval
                } -PassThru
                return $spSite
            }

            Context -Name 'The site collection does not exist' -Fixture {
                $testParams = @{
                    Url   = "http://sharepoint.contoso.com"
                    Key   = 'PropertyKey'
                    Value = 'NewPropertyValue'
                }
                Mock -CommandName Get-SPSite -MockWith {
                    return $null
                }

                It 'Should throw exception in the get method' {
                    { Get-TargetResource @testParams } | Should Throw "Specified site collection could not be found."
                }

                It 'Should throw exception in the set method' {
                    { Set-TargetResource @testParams } | Should Throw "Specified site collection could not be found."
                }

                It 'Should throw exception in the test method' {
                    { Test-TargetResource @testParams } | Should Throw "Specified site collection could not be found."
                }
            }

            Context -Name 'The site collection property value does not match' -Fixture {
                $testParams = @{
                    Url    = "http://sharepoint.contoso.com"
                    Key    = 'PropertyKey'
                    Value  = 'NewPropertyValue'
                    Ensure = 'Present'
                }

                It 'Should return present from the get method' {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should Be 'Present'
                    $result.Key | Should Be $testParams.Key
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParams | Should Be $false
                }

                It 'Should not throw an exception in the set method' {
                    { Set-TargetResource @testParams } | Should not throw
                }

                $Global:SPDscSitePropertyUpdated = $false
                It 'Calls Get-SPSite and update site collection property bag from the set method' {
                    Set-TargetResource @testParams

                    $Global:SPDscSitePropertyUpdated | Should Be $true
                }
            }

            Context -Name 'The site collection property exists, and the value match' -Fixture {
                $testParams = @{
                    Url    = "http://sharepoint.contoso.com"
                    Key    = 'PropertyKey'
                    Value  = 'PropertyValue'
                    Ensure = 'Present'
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

            Context -Name 'The site collection property does not exist, and should be removed' -Fixture {
                $testParams = @{
                    Url    = "http://sharepoint.contoso.com"
                    Key    = 'NonExistingPropertyKey'
                    Value  = 'PropertyValue'
                    Ensure = 'Absent'
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

            Context -Name 'The site collection property exists, and should not be' -Fixture {
                $testParams = @{
                    Url    = "http://sharepoint.contoso.com"
                    Key    = 'PropertyKey'
                    Value  = 'PropertyValue'
                    Ensure = 'Absent'
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

                $Global:SPDscSitePropertyUpdated = $false
                It 'Calls Get-SPSite and remove site collection property bag from the set method' {
                    Set-TargetResource @testParams

                    $Global:SPDscSitePropertyUpdated | Should Be $true
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
