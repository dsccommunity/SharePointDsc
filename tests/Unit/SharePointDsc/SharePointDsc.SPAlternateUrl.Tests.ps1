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
$script:DSCResourceName = 'SPAlternateUrl'
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

                # Mocks for all contexts
                Mock -CommandName New-SPAlternateURL { }
                Mock -CommandName Set-SPAlternateURL { }
                Mock -CommandName Remove-SPAlternateURL { }
            }

            # Test contexts
            Context -Name "Specified web application does not exist" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppName = "SharePoint - www.domain.com80"
                        Zone       = "Internet"
                        Url        = "http://something.contoso.local"
                        Internal   = $false
                        Ensure     = "Present"
                    }

                    Mock -CommandName Get-SPAlternateUrl -MockWith {
                        return @()
                    } -ParameterFilter { $Identity -eq $testParams.Url }

                    Mock -CommandName Get-SPAlternateUrl -MockWith {
                        return @(
                            @{
                                PublicUrl   = "http://www.contoso.local"
                                IncomingUrl = "http://www.contoso.local"
                                Zone        = "Default"
                            }
                        )
                    } -ParameterFilter { $WebApplication.DisplayName -eq $testParams.WebAppName }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        return @()
                    }
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Web application was not found. Please check WebAppName parameter!"
                }
            }

            Context -Name "No internal alternate URL exists for the specified zone and web app, and there should be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppName = "SharePoint - www.domain.com80"
                        Zone       = "Internet"
                        Url        = "http://something.contoso.local"
                        Internal   = $true
                        Ensure     = "Present"
                    }

                    Mock -CommandName Get-SPAlternateUrl -MockWith {
                        return @()
                    } -ParameterFilter { $Identity -eq $testParams.Url }

                    Mock -CommandName Get-SPAlternateUrl -MockWith {
                        return @(
                            @{
                                PublicUrl   = "http://www.domain.com"
                                IncomingUrl = "http://www.domain.com"
                                Zone        = "Default"
                            }
                        )
                    } -ParameterFilter { $WebApplication.DisplayName -eq $testParams.WebAppName }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        return @{
                            DisplayName = $testParams.WebAppName
                        }
                    }
                }

                It "Should return Ensure=Absent in the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-targetResource @testParams | Should -Be $false
                }

                It "Should call the new function in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPAlternateURL
                }
            }

            Context -Name "No internal alternate URL exists for the specified zone and web app, and there should be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppName = "SharePoint - www.domain.com80"
                        Zone       = "Internet"
                        Url        = "http://something.contoso.local"
                        Internal   = $true
                        Ensure     = "Present"
                    }

                    Mock -CommandName Get-SPAlternateUrl -MockWith {
                        return @()
                    } -ParameterFilter { $Identity -eq $testParams.Url }

                    Mock -CommandName Get-SPAlternateUrl -MockWith {
                        return @()
                    } -ParameterFilter { $WebApplication.DisplayName -eq $testParams.WebAppName }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        return @{
                            DisplayName = $testParams.WebAppName
                        }
                    }
                }

                It "Should return Ensure=Absent in the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-targetResource @testParams | Should -Be $false
                }

                It "Should call the new function in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPAlternateURL
                }
            }

            Context -Name "The internal alternate URL exists for the specified zone and web app, and should be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppName = "SharePoint - www.domain.com80"
                        Zone       = "Internet"
                        Url        = "http://something.contoso.local"
                        Internal   = $true
                        Ensure     = "Present"
                    }

                    Mock -CommandName Get-SPAlternateUrl -MockWith {
                        return @(
                            @{
                                PublicUrl   = "http://www.domain.com"
                                IncomingUrl = "http://something.contoso.local"
                                Zone        = "Internet"
                            }
                        )
                    } -ParameterFilter { $Identity -eq $testParams.Url }

                    Mock -CommandName Get-SPAlternateUrl -MockWith {
                        return @(
                            @{
                                PublicUrl   = "http://www.domain.com"
                                IncomingUrl = "http://something.contoso.local"
                                Zone        = "Default"
                            }
                        )
                    } -ParameterFilter { $WebApplication.DisplayName -eq $testParams.WebAppName }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        return @{
                            DisplayName = $testParams.WebAppName
                        }
                    }
                }

                It "Should return Ensure=Present in the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false from the test method" {
                    Test-targetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The internal alternate URL exists on another zone and web app (New zone)" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppName = "SharePoint - www.domain.com80"
                        Zone       = "Internet"
                        Url        = "http://something.contoso.local"
                        Internal   = $true
                        Ensure     = "Present"
                    }

                    Mock -CommandName Get-SPAlternateUrl -MockWith {
                        return @(
                            @{
                                PublicUrl   = "http://www.otherdomain.com"
                                IncomingUrl = "http://something.contoso.local"
                                Zone        = "Default"
                            }
                        )
                    } -ParameterFilter { $Identity -eq $testParams.Url }

                    Mock -CommandName Get-SPAlternateUrl -MockWith {
                        return @()
                    } -ParameterFilter { $WebApplication.DisplayName -eq $testParams.WebAppName }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        return @{
                            DisplayName = $testParams.WebAppName
                        }
                    }
                }

                It "Should return Ensure=Present in the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false from the test method" {
                    Test-targetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Specified URL found on different WebApp/Zone: WebApp"
                }
            }

            Context -Name "The internal alternate URL exists on another zone and web app (Existing zone)" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppName = "SharePoint - www.domain.com80"
                        Zone       = "Internet"
                        Url        = "http://something.contoso.local"
                        Internal   = $true
                        Ensure     = "Present"
                    }

                    Mock -CommandName Get-SPAlternateUrl -MockWith {
                        return @(
                            @{
                                PublicUrl   = "http://www.otherdomain.com"
                                IncomingUrl = "http://something.contoso.local"
                                Zone        = "Default"
                            }
                        )
                    } -ParameterFilter { $Identity -eq $testParams.Url }

                    Mock -CommandName Get-SPAlternateUrl -MockWith {
                        return @(
                            @{
                                PublicUrl   = "http://www.domain.com"
                                IncomingUrl = "http://www.domain.com"
                                Zone        = "Internet"
                            }
                        )
                    } -ParameterFilter { $WebApplication.DisplayName -eq $testParams.WebAppName }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        return @{
                            DisplayName = $testParams.WebAppName
                        }
                    }
                }

                It "Should return Ensure=Present in the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false from the test method" {
                    Test-targetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Specified URL"
                }
            }

            Context -Name "An internal URL exists for the specified zone and web app, and it should not" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppName = "SharePoint - www.domain.com80"
                        Zone       = "Default"
                        Url        = "http://something.contoso.local"
                        Internal   = $true
                        Ensure     = "Absent"
                    }

                    Mock -CommandName Get-SPAlternateUrl -MockWith {
                        return @(
                            @{
                                PublicUrl   = "http://www.domain.com"
                                IncomingUrl = "http://something.contoso.local"
                                Zone        = "Default"
                            }
                        )
                    } -ParameterFilter { $Identity -eq $testParams.Url }

                    Mock -CommandName Get-SPAlternateUrl -MockWith {
                        return @(
                            @{
                                PublicUrl   = "http://www.domain.com"
                                IncomingUrl = "http://www.domain.com"
                                Zone        = "Default"
                            },
                            @{
                                PublicUrl   = "http://www.domain.com"
                                IncomingUrl = "http://something.contoso.local"
                                Zone        = "Default"
                            }
                        )
                    } -ParameterFilter { $WebApplication.DisplayName -eq $testParams.WebAppName }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        return @{
                            Name = $testParams.WebAppName
                        }
                    }
                }

                It "Should return Ensure=Present in the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false from the test method" {
                    Test-targetResource @testParams | Should -Be $false
                }

                It "Should call the Remove function in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-SPAlternateURL
                }
            }

            Context -Name "The URL for the specified zone and web app is incorrect, this must be changed" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppName = "SharePoint - www.domain.com80"
                        Zone       = "Default"
                        Url        = "http://www.newdomain.com"
                        Internal   = $false
                        Ensure     = "Present"
                    }

                    Mock -CommandName Get-SPAlternateUrl -MockWith {
                        return @()
                    } -ParameterFilter { $Identity -eq $testParams.Url }

                    Mock -CommandName Get-SPAlternateUrl -MockWith {
                        return @(
                            @{
                                PublicUrl   = "http://www.domain.com"
                                IncomingUrl = "http://www.domain.com"
                                Zone        = "Default"
                            }
                        )
                    } -ParameterFilter { $WebApplication.DisplayName -eq $testParams.WebAppName }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        return @{
                            DisplayName = $testParams.WebAppName
                        }
                    }
                }

                It "Should return Ensure=Absent in the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-targetResource @testParams | Should -Be $false
                }

                It "Should call the new function in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPAlternateURL
                }
            }

            Context -Name "The URL for the specified zone and web app exists as internal url, this must be changed" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppName = "SharePoint - www.domain.com80"
                        Zone       = "Default"
                        Url        = "http://www.newdomain.com"
                        Internal   = $false
                        Ensure     = "Present"
                    }

                    Mock -CommandName Get-SPAlternateUrl -MockWith {
                        return @(
                            @{
                                PublicUrl   = "http://www.domain.com"
                                IncomingUrl = "http://www.newdomain.com"
                                Zone        = "Default"
                            }
                        )
                    } -ParameterFilter { $Identity -eq $testParams.Url }

                    Mock -CommandName Get-SPAlternateUrl -MockWith {
                        return @(
                            @{
                                PublicUrl   = "http://www.domain.com"
                                IncomingUrl = "http://www.domain.com"
                                Zone        = "Default"
                            },
                            @{
                                PublicUrl   = "http://www.domain.com"
                                IncomingUrl = "http://www.newdomain.com"
                                Zone        = "Default"
                            }
                        )
                    } -ParameterFilter { $WebApplication.DisplayName -eq $testParams.WebAppName }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        return @{
                            DisplayName = $testParams.WebAppName
                        }
                    }
                }

                It "Should return Ensure=Present in the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false from the test method" {
                    Test-targetResource @testParams | Should -Be $false
                }

                It "Should call the Set function in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-SPAlternateURL
                }
            }

            Context -Name "The URL for the specified zone and web app is correct, and should be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppName = "SharePoint - www.domain.com80"
                        Zone       = "Default"
                        Url        = "http://www.domain.com"
                        Internal   = $false
                        Ensure     = "Present"
                    }

                    Mock -CommandName Get-SPAlternateUrl -MockWith {
                        return @(
                            @{
                                PublicUrl   = "http://www.domain.com"
                                IncomingUrl = "http://www.domain.com"
                                Zone        = "Default"
                            }
                        )
                    } -ParameterFilter { $Identity -eq $testParams.Url }

                    Mock -CommandName Get-SPAlternateUrl -MockWith {
                        return @(
                            @{
                                PublicUrl   = "http://www.domain.com"
                                IncomingUrl = "http://www.domain.com"
                                Zone        = "Default"
                            }
                        )
                    } -ParameterFilter { $WebApplication.DisplayName -eq $testParams.WebAppName }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        return @{
                            DisplayName = $testParams.WebAppName
                        }
                    }
                }

                It "Should return Ensure=Present in the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return true from the test method" {
                    Test-targetResource @testParams | Should -Be $true
                }
            }

            Context -Name "A URL exists for the specified zone and web app, and it should not" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppName = "SharePoint - www.domain.com80"
                        Zone       = "Internet"
                        Url        = "http://www.domain.com"
                        Internal   = $false
                        Ensure     = "Absent"
                    }

                    Mock -CommandName Get-SPAlternateUrl -MockWith {
                        return @(
                            @{
                                PublicUrl   = "http://www.domain.com"
                                IncomingUrl = "http://www.domain.com"
                                Zone        = "Internet"
                            }
                        )
                    } -ParameterFilter { $Identity -eq $testParams.Url }

                    Mock -CommandName Get-SPAlternateUrl -MockWith {
                        return @(
                            @{
                                PublicUrl   = "http://www.domain.com"
                                IncomingUrl = "http://www.domain.com"
                                Zone        = "Default"
                            }
                        )
                    } -ParameterFilter { $WebApplication.DisplayName -eq $testParams.WebAppName }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        return @{
                            DisplayName = $testParams.WebAppName
                        }
                    }
                }

                It "Should return Ensure=Present in the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false from the test method" {
                    Test-targetResource @testParams | Should -Be $false
                }

                It "Should call the Remove function in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-SPAlternateURL
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
