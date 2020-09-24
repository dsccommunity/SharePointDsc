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
$script:DSCResourceName = 'SPWebAppBlockedFileTypes'
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
                Mock -CommandName New-SPAuthenticationProvider -MockWith { }
                Mock -CommandName New-SPWebApplication -MockWith { }
                Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                    return @{
                        DisableKerberos = $true
                        AllowAnonymous  = $false
                    }
                }
            }

            # Test contexts
            Context -Name "The web appliation exists and a specific blocked file type list matches" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sites.sharepoint.com"
                        Blocked   = @("exe", "dll", "ps1")
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        [Collections.Generic.List[String]]$CurrentBlockedFiles = @("exe", "ps1", "dll")
                        $webApp = @{
                            DisplayName           = $testParams.Name
                            ApplicationPool       = @{
                                Name     = $testParams.ApplicationPool
                                Username = $testParams.ApplicationPoolAccount
                            }
                            ContentDatabases      = @(
                                @{
                                    Name   = "SP_Content_01"
                                    Server = "sql.domain.local"
                                }
                            )
                            IisSettings           = @(
                                @{ Path = "C:\inetpub\wwwroot\something" }
                            )
                            Url                   = $testParams.WebAppUrl
                            BlockedFileExtensions = $CurrentBlockedFiles
                        }
                        $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscWebApplicationUpdateCalled = $true
                        } -PassThru
                        return @($webApp)
                    }
                }

                It "Should return the current data from the get method" {
                    (Get-TargetResource @testParams).Blocked.Count | Should -Be 3
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The web appliation exists and a specific blocked file type list does not match" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sites.sharepoint.com"
                        Blocked   = @("exe", "dll", "ps1")
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        [Collections.Generic.List[String]]$CurrentBlockedFiles = @("exe", "pdf", "dll")
                        $webApp = @{
                            DisplayName           = $testParams.Name
                            ApplicationPool       = @{
                                Name     = $testParams.ApplicationPool
                                Username = $testParams.ApplicationPoolAccount
                            }
                            ContentDatabases      = @(
                                @{
                                    Name   = "SP_Content_01"
                                    Server = "sql.domain.local"
                                }
                            )
                            IisSettings           = @(
                                @{ Path = "C:\inetpub\wwwroot\something" }
                            )
                            Url                   = $testParams.WebAppUrl
                            BlockedFileExtensions = $CurrentBlockedFiles
                        }
                        $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscWebApplicationUpdateCalled = $true
                        } -PassThru
                        return @($webApp)
                    }
                }

                It "Should return the current data from the get method" {
                    (Get-TargetResource @testParams).Blocked.Count | Should -Be 3
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                $Global:SPDscWebApplicationUpdateCalled = $false
                It "Should update the workflow settings" {
                    Set-TargetResource @testParams
                    $Global:SPDscWebApplicationUpdateCalled | Should -Be $true
                }
            }

            Context -Name "The web appliation exists and a list of types to include and exclude both match" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl     = "http://sites.sharepoint.com"
                        EnsureBlocked = @("exe")
                        EnsureAllowed = @("pdf")
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        [Collections.Generic.List[String]]$CurrentBlockedFiles = @("exe", "ps1", "dll")
                        $webApp = @{
                            DisplayName           = $testParams.Name
                            ApplicationPool       = @{
                                Name     = $testParams.ApplicationPool
                                Username = $testParams.ApplicationPoolAccount
                            }
                            ContentDatabases      = @(
                                @{
                                    Name   = "SP_Content_01"
                                    Server = "sql.domain.local"
                                }
                            )
                            IisSettings           = @(
                                @{ Path = "C:\inetpub\wwwroot\something" }
                            )
                            Url                   = $testParams.WebAppUrl
                            BlockedFileExtensions = $CurrentBlockedFiles
                        }
                        $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscWebApplicationUpdateCalled = $true
                        } -PassThru
                        return @($webApp)
                    }
                }

                It "Should return the current data from the get method" {
                    (Get-TargetResource @testParams).Blocked.Count | Should -Be 3
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The web appliation exists and a list of types to include and exclude both failed" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl     = "http://sites.sharepoint.com"
                        EnsureBlocked = @("exe")
                        EnsureAllowed = @("pdf")
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        [Collections.Generic.List[String]]$CurrentBlockedFiles = @("pdf", "dll")
                        $webApp = @{
                            DisplayName           = $testParams.Name
                            ApplicationPool       = @{
                                Name     = $testParams.ApplicationPool
                                Username = $testParams.ApplicationPoolAccount
                            }
                            ContentDatabases      = @(
                                @{
                                    Name   = "SP_Content_01"
                                    Server = "sql.domain.local"
                                }
                            )
                            IisSettings           = @(
                                @{ Path = "C:\inetpub\wwwroot\something" }
                            )
                            Url                   = $testParams.WebAppUrl
                            BlockedFileExtensions = $CurrentBlockedFiles
                        }
                        $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscWebApplicationUpdateCalled = $true
                        } -PassThru
                        return @($webApp)
                    }
                }

                It "Should return the current data from the get method" {
                    (Get-TargetResource @testParams).Blocked.Count | Should -Be 2
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                $Global:SPDscWebApplicationUpdateCalled = $false
                It "Should update the workflow settings" {
                    Set-TargetResource @testParams
                    $Global:SPDscWebApplicationUpdateCalled | Should -Be $true
                }
            }

            Context -Name "All blocked file type parameters are passed to the methods" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl     = "http://sites.sharepoint.com"
                        Blocked       = @("exe", "dll", "ps1")
                        EnsureBlocked = @("exe", "dll")
                        EnsureAllowed = @("ps1")
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        [Collections.Generic.List[String]]$CurrentBlockedFiles = @("pdf", "dll")
                        $webApp = @{
                            DisplayName           = $testParams.Name
                            ApplicationPool       = @{
                                Name     = $testParams.ApplicationPool
                                Username = $testParams.ApplicationPoolAccount
                            }
                            ContentDatabases      = @(
                                @{
                                    Name   = "SP_Content_01"
                                    Server = "sql.domain.local"
                                }
                            )
                            IisSettings           = @(
                                @{ Path = "C:\inetpub\wwwroot\something" }
                            )
                            Url                   = $testParams.WebAppUrl
                            BlockedFileExtensions = $CurrentBlockedFiles
                        }
                        $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscWebApplicationUpdateCalled = $true
                        } -PassThru
                        return @($webApp)
                    }
                }

                It "Should throw an exception on the test method" {
                    { Test-TargetResource @testParams } | Should -Throw
                }

                It "Should throw an exception on the set method" {
                    { Set-TargetResource @testParams } | Should -Throw
                }
            }

            Context -Name "No blocked file type parameters are passed to the methods" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl = "http://sites.sharepoint.com"
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        [Collections.Generic.List[String]]$CurrentBlockedFiles = @("pdf", "dll")
                        $webApp = @{
                            DisplayName           = $testParams.Name
                            ApplicationPool       = @{
                                Name     = $testParams.ApplicationPool
                                Username = $testParams.ApplicationPoolAccount
                            }
                            ContentDatabases      = @(
                                @{
                                    Name   = "SP_Content_01"
                                    Server = "sql.domain.local"
                                }
                            )
                            IisSettings           = @(
                                @{ Path = "C:\inetpub\wwwroot\something" }
                            )
                            Url                   = $testParams.WebAppUrl
                            BlockedFileExtensions = $CurrentBlockedFiles
                        }
                        $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscWebApplicationUpdateCalled = $true
                        } -PassThru
                        return @($webApp)
                    }
                }

                It "Should throw an exception on the test method" {
                    { Test-TargetResource @testParams } | Should -Throw
                }

                It "Should throw an exception on the set method" {
                    { Set-TargetResource @testParams } | Should -Throw
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
