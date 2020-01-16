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
$script:DSCResourceName = 'SPSearchMetadataCategory'
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

            # Mocks for all contexts
            Mock -CommandName Get-SPEnterpriseSearchServiceApplication {
                return @{
                    SearchCenterUrl = "http://example.sharepoint.com/pages"
                }
            }

            Mock -CommandName New-SPEnterpriseSearchMetadataCategory {
                return @{
                    Name = "Test Category"
                }
            }

            Mock -CommandName Set-SPEnterpriseSearchMetadataCategory {
                return @{ }
            }

            Mock -CommandName Remove-SPEnterpriseSearchMetadataCategory {
                return @{ }
            }

            # Test contexts
            Context -Name "A search metadata category doesn't exist and should" -Fixture {
                Mock -CommandName Get-SPEnterpriseSearchMetadataCategory {
                    return $null
                }

                $testParams = @{
                    Name                           = "Test Category"
                    ServiceAppName                 = "Search Service Application"
                    AutoCreateNewManagedProperties = $true
                    DiscoverNewProperties          = $true
                    MapToContents                  = $true
                    Ensure                         = "Present"
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "Should create the result source in the set method" {
                    Set-TargetResource @testParams
                }
            }

            Context -Name "A search metadata category exists and shouldn't" -Fixture {
                Mock -CommandName Get-SPEnterpriseSearchMetadataCategory {
                    return @{
                        Name = "Test Category"
                    }
                }

                $testParams = @{
                    Name           = "Test Category"
                    ServiceAppName = "Search Service Application"
                    Ensure         = "Absent"
                }

                It "Should return Present from the Get Method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }

                It "Should delete the content source within the Set Method" {
                    Set-TargetResource @testParams
                }
            }

            Context -Name "Trying to delete a non-empty metadata category" -Fixture {
                Mock -CommandName Get-SPEnterpriseSearchMetadataCategory {
                    return @{
                        Name                 = "Test Category"
                        CrawledPropertyCount = 1
                    }
                }

                $testParams = @{
                    Name           = "Test Category"
                    ServiceAppName = "Search Service Application"
                    Ensure         = "Absent"
                }

                It "Should throw an error from the Set Method" {
                    { Set-TargetResource @testParams } | Should Throw
                }
            }

            Context -Name "An invalid Search Service Aplication was specified" -Fixture {
                $testParams = @{
                    Name           = "Test Category"
                    ServiceAppName = "Search Service Application"
                    Ensure         = "Absent"
                }

                Mock -CommandName Get-SPEnterpriseSearchServiceApplication {
                    return $null
                }

                It "Should throw an error in the Get Method" {
                    { Get-TargetResource @testParams } | Should Throw
                }

                It "Should throw an error in the Set Method" {
                    { Set-TargetResource @testParams } | Should Throw
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
