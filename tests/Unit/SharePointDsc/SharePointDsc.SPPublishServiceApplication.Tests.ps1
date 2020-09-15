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
$script:DSCResourceName = 'SPPublishServiceApplication'
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
    $ErrorActionPreference = 'stop'
    Set-StrictMode -Version latest

    Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
        InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
            Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

            $testParams = @{
                Name   = "Managed Metadata"
                Ensure = "Present"
            }

            Mock Publish-SPServiceApplication { }
            Mock Unpublish-SPServiceApplication { }

            Context -Name "An invalid service application is specified to be published" {
                Mock -CommandName Get-SPServiceApplication {
                    $spServiceApp = [pscustomobject]@{
                        Name = $testParams.Name
                        Uri  = $null
                    }
                    return $spServiceApp
                }
                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "throws when the set method is called" {
                    { Set-TargetResource @testParams } | Should -Throw
                }
            }

            Context -Name "The service application is not published but should be" {
                Mock -CommandName Get-SPServiceApplication {
                    $spServiceApp = [pscustomobject]@{
                        Name   = $testParams.Name
                        Uri    = "urn:schemas-microsoft-com:sharepoint:service:mmsid"
                        Shared = $false
                    }
                    return $spServiceApp
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "calls the Publish-SPServiceApplication call from the set method" {
                    Set-TargetResource @testParams

                    Assert-MockCalled Publish-SPServiceApplication
                }
            }

            Context -Name "The service application is published and should be" {
                Mock -CommandName Get-SPServiceApplication {
                    $spServiceApp = [pscustomobject]@{
                        Name   = $testParams.Name
                        Uri    = "urn:schemas-microsoft-com:sharepoint:service:mmsid"
                        Shared = $true
                    }
                    return $spServiceApp
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The service application specified does not exist" {
                Mock -CommandName Get-SPServiceApplication { return $null }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "throws when the set method is called" {
                    { Set-TargetResource @testParams } | Should -Throw
                }
            }

            $testParams.Ensure = "Absent"

            Context -Name "The service application is not published and should not be" {
                Mock -CommandName Get-SPServiceApplication {
                    $spServiceApp = [pscustomobject]@{
                        Name   = $testParams.Name
                        Uri    = "urn:schemas-microsoft-com:sharepoint:service:mmsid"
                        Shared = $false
                    }
                    return $spServiceApp
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The service application is published and should not be" {
                Mock -CommandName Get-SPServiceApplication {
                    $spServiceApp = [pscustomobject]@{
                        Name   = $testParams.Name
                        Uri    = "urn:schemas-microsoft-com:sharepoint:service:mmsid"
                        Shared = $true
                    }
                    return $spServiceApp
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "calls the Unpublish-SPServiceApplication call from the set method" {
                    Set-TargetResource @testParams

                    Assert-MockCalled Unpublish-SPServiceApplication
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
