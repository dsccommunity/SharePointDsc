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
$script:DSCResourceName = 'SPAppCatalog'
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

                $mockSiteId = [Guid]::NewGuid()

                $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                $mockCredential = New-Object -TypeName System.Management.Automation.PSCredential `
                    -ArgumentList @("$($Env:USERDOMAIN)\$($Env:USERNAME)", $mockPassword)
                $mockFarmCredential = New-Object -TypeName System.Management.Automation.PSCredential `
                    -ArgumentList @("DOMAIN\sp_farm", $mockPassword)

                # Mocks for all contexts
                Mock -CommandName Get-SPDscFarmAccount -MockWith {
                    return $mockFarmCredential
                }
                Mock -CommandName Add-SPDscUserToLocalAdmin -MockWith { }
                Mock -CommandName Test-SPDscUserIsLocalAdmin -MockWith { return $false }
                Mock -CommandName Remove-SPDscUserToLocalAdmin -MockWith { }
                Mock -CommandName Restart-Service { }
            }

            # Test contexts
            Context -Name "The PsDscRunAsCredential is the Farm account" -Fixture {
                BeforeAll {
                    $testParams = @{
                        SiteUrl = "https://content.sharepoint.contoso.com/sites/AppCatalog"
                    }

                    Mock -CommandName Update-SPAppCatalogConfiguration -MockWith { }
                    Mock -CommandName Get-SPSite -MockWith {
                        return @{
                            WebApplication = @{
                                Features = @( @{ } ) | Add-Member -MemberType ScriptMethod `
                                    -Name "Item" `
                                    -Value { return $null } `
                                    -PassThru `
                                    -Force
                            }
                            ID             = $mockSiteId
                        }
                    }
                    Mock -CommandName Get-SPDscFarmAccount -MockWith {
                        return $mockCredential
                    }
                }

                It "Should throw exception when executed" {
                    { Set-TargetResource @testParams } | Should -Throw "Specified PSDSCRunAsCredential"
                }
            }

            Context -Name "The specified site exists, but cannot be set as an app catalog as it is of the wrong template" -Fixture {
                BeforeAll {
                    $testParams = @{
                        SiteUrl = "https://content.sharepoint.contoso.com/sites/AppCatalog"
                    }

                    Mock -CommandName Update-SPAppCatalogConfiguration -MockWith { throw 'Exception' }
                    Mock -CommandName Get-SPSite -MockWith {
                        return @{
                            WebApplication = @{
                                Features = @( @{ } ) | Add-Member -MemberType ScriptMethod `
                                    -Name "Item" `
                                    -Value { return $null } `
                                    -PassThru `
                                    -Force
                            }
                            ID             = $mockSiteId
                        }
                    }
                }

                It "Should return null from the get method" {
                    (Get-TargetResource @testParams).SiteUrl | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw exception when executed" {
                    { Set-TargetResource @testParams } | Should -Throw
                }
            }

            Context -Name "The specified site exists but is not set as the app catalog for its web application" -Fixture {
                BeforeAll {
                    $testParams = @{
                        SiteUrl = "https://content.sharepoint.contoso.com/sites/AppCatalog"
                    }

                    Mock -CommandName Update-SPAppCatalogConfiguration -MockWith { }
                    Mock -CommandName Get-SPSite -MockWith {
                        return @{
                            WebApplication = @{
                                Features = @( @{ } ) | Add-Member -MemberType ScriptMethod `
                                    -Name "Item" `
                                    -Value { return $null } `
                                    -PassThru `
                                    -Force
                            }
                            ID             = $mockSiteId
                        }
                    }
                }

                It "Should return null from the get method" {
                    (Get-TargetResource @testParams).SiteUrl | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the settings in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Update-SPAppCatalogConfiguration
                }

            }

            Context -Name "The specified site exists and is the current app catalog already" -Fixture {
                BeforeAll {
                    $testParams = @{
                        SiteUrl = "https://content.sharepoint.contoso.com/sites/AppCatalog"
                    }

                    Mock -CommandName Get-SPSite -MockWith {
                        return @{
                            WebApplication = @{
                                Features = @( @{ } ) | Add-Member -MemberType ScriptMethod `
                                    -Name "Item" `
                                    -Value {
                                    return @{
                                        ID         = [guid]::NewGuid()
                                        Properties = @{
                                            "__AppCatSiteId" = @{Value = $mockSiteId }
                                        }
                                    }
                                } `
                                    -PassThru `
                                    -Force
                            }
                            ID             = $mockSiteId
                            Url            = $testParams.SiteUrl
                        }
                    }
                }

                It "Should return value from the get method" {
                    (Get-TargetResource @testParams).SiteUrl | Should -Not -BeNullOrEmpty
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The specified site exists and the resource tries to set the site using the farm account" -Fixture {
                BeforeAll {
                    $testParams = @{
                        SiteUrl = "https://content.sharepoint.contoso.com/sites/AppCatalog"
                    }

                    Mock -CommandName Update-SPAppCatalogConfiguration -MockWith {
                        throw [System.UnauthorizedAccessException] "ACCESS IS DENIED"
                    }
                    Mock -CommandName Get-SPSite -MockWith {
                        return @{
                            WebApplication = @{
                                Features = @( @{ } ) | Add-Member -MemberType ScriptMethod `
                                    -Name "Item" `
                                    -Value { return $null } `
                                    -PassThru `
                                    -Force
                            }
                            ID             = $mockSiteId
                        }
                    }
                }

                It "Should return null from the get method" {
                    (Get-TargetResource @testParams).SiteUrl | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw `
                    ("This resource must be run as the farm account (not a setup account). " + `
                            "Please ensure either the PsDscRunAsCredential or InstallAccount " + `
                            "credentials are set to the farm account and run this resource again")
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
