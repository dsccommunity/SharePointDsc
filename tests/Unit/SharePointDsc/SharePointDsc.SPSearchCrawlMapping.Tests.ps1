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
$script:DSCResourceName = 'SPSearchCrawlMapping'
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

            # Initialize tests
            $getTypeFullName = "Microsoft.Office.Server.Search.Administration.SearchServiceApplication"

            # Mocks for all contexts
            Mock -CommandName Remove-SPEnterpriseSearchCrawlMapping -MockWith { }
            Mock -CommandName New-SPEnterpriseSearchCrawlMapping -MockWith { }
            Mock -CommandName Get-SPEnterpriseSearchCrawlMapping -MockWith { }
            Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith { }

            Mock -CommandName Get-SPServiceApplication -MockWith {
                return @(
                    New-Object -TypeName "Object" |
                    Add-Member -MemberType ScriptMethod `
                        -Name GetType `
                        -Value {
                        New-Object -TypeName "Object" |
                        Add-Member -MemberType NoteProperty `
                            -Name FullName `
                            -Value $getTypeFullName `
                            -PassThru
                    } `
                        -PassThru -Force)
            }

            # Test contexts
            Context -Name "When enterprise search service doesn't exist in the current farm" -Fixture {
                $testParams = @{
                    ServiceAppName = "Search Service Application"
                    Url            = "http://crawl.sharepoint.com"
                    Target         = "http://site.sharepoint.com"
                    Ensure         = "Present"
                }

                Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith {
                    return $null
                }

                It "Should return absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw Exception -- The Search Service Application does not exist" {
                    { Set-TargetResource @testParams } | Should -Throw "The Search Service Application does not exist"
                }

            }

            Context -Name "When no crawl mappings exists" -Fixture {
                $testParams = @{
                    ServiceAppName = "Search Service Application"
                    Url            = "http://crawl.sharepoint.com"
                    Target         = "http://site.sharepoint.com"
                    Ensure         = "Present"
                }

                Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith {
                    return @{
                        Name = "Search Service Application"
                    }
                }


                Mock -CommandName Get-SPEnterpriseSearchCrawlMapping -MockWith {
                    return $null
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return true when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }


            }

            Context -Name "When crawl mappings exists but specific mapping does not" -Fixture {
                $testParams = @{
                    ServiceAppName = "Search Service Application"
                    Url            = "http://crawl.sharepoint.com"
                    Target         = "http://site.sharepoint.com"
                    Ensure         = "Present"
                }

                Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith {
                    return @{
                        Name = "Search Service Application"
                    }
                }


                Mock -CommandName Get-SPEnterpriseSearchCrawlMapping -MockWith {
                    return @(
                        @{
                            Url    = "http://other.sharepoint.com"
                            Target = "http://site.sharepoint.com"
                        },
                        @{
                            Url    = "http://site.sharepoint.com"
                            Target = "http://site2.sharepoint.com"
                        }
                    )
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "When a crawl mapping exists, and is configured correctly" -Fixture {

                $testParams = @{
                    ServiceAppName = "Search Service Application"
                    Url            = "http://crawl.sharepoint.com"
                    Target         = "http://site.sharepoint.com"
                    Ensure         = "Present"
                }

                Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith {
                    return @{
                        Name = "Search Service Application"
                    }
                }


                Mock -CommandName Get-SPEnterpriseSearchCrawlMapping -MockWith {
                    return @(
                        @{
                            Source = "http://other.sharepoint.com"
                            Target = "http://site.sharepoint.com"
                        },
                        @{
                            Source = "http://site.sharepoint.com"
                            Target = "http://site2.sharepoint.com"
                        },
                        @{
                            Source = $testParams.Url
                            Target = $testParams.Target
                        }
                    )
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return true when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $true
                }

                It "Should call the Get Remove New SPEnterpriseSearchCrawlMapping update the crawl mapping" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Get-SPEnterpriseSearchServiceApplication
                    Assert-MockCalled Get-SPEnterpriseSearchCrawlMapping
                    Assert-MockCalled Remove-SPEnterpriseSearchCrawlMapping
                    Assert-MockCalled New-SPEnterpriseSearchCrawlMapping
                }
            }

            Context -Name "When a crawl mapping exists, but isn't configured correctly" -Fixture {
                $testParams = @{
                    ServiceAppName = "Search Service Application"
                    Url            = "http://crawl.sharepoint.com"
                    Target         = "http://site.sharepoint.com"
                    Ensure         = "Present"
                }

                Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith {
                    return @{
                        Name = "Search Service Application"
                    }
                }


                Mock -CommandName Get-SPEnterpriseSearchCrawlMapping -MockWith {
                    return @(
                        @{
                            Source = "http://other.sharepoint.com"
                            Target = "http://site.sharepoint.com"
                        },
                        @{
                            Source = "http://site.sharepoint.com"
                            Target = "http://site2.sharepoint.com"
                        },
                        @{
                            Source = $testParams.Url
                            Target = "http://other.sharepoint.com"
                        }
                    )
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the Get Remove New -SPEnterpriseSearchCrawlMapping update the crawl mapping" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Get-SPEnterpriseSearchCrawlMapping
                    Assert-MockCalled Remove-SPEnterpriseSearchCrawlMapping
                    Assert-MockCalled New-SPEnterpriseSearchCrawlMapping
                }
            }

            Context -Name "When a crawl mapping doesn't exists, but it should" -Fixture {
                $testParams = @{
                    ServiceAppName = "Search Service Application"
                    Url            = "http://crawl.sharepoint.com"
                    Target         = "http://site.sharepoint.com"
                    Ensure         = "Present"
                }

                Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith {
                    return @{
                        Name = "Search Service Application"
                    }
                }


                Mock -CommandName Get-SPEnterpriseSearchCrawlMapping -MockWith {
                    return @(
                        @{
                            Source = "http://other.sharepoint.com"
                            Target = "http://site.sharepoint.com"
                        },
                        @{
                            Source = "http://site.sharepoint.com"
                            Target = "http://site2.sharepoint.com"
                        }
                    )
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the Get Remove New -SPEnterpriseSearchCrawlMapping update the crawl mapping" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPEnterpriseSearchCrawlMapping
                }
            }

            Context -Name "When a crawl mapping exists, but isn't configured correctly" -Fixture {
                $testParams = @{
                    ServiceAppName = "Search Service Application"
                    Url            = "http://crawl.sharepoint.com"
                    Target         = "http://site.sharepoint.com"
                    Ensure         = "Present"
                }

                Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith {
                    return @{
                        Name = "Search Service Application"
                    }
                }


                Mock -CommandName Get-SPEnterpriseSearchCrawlMapping -MockWith {
                    return @(
                        @{
                            Source = "http://other.sharepoint.com"
                            Target = "http://site.sharepoint.com"
                        },
                        @{
                            Source = "http://site.sharepoint.com"
                            Target = "http://site2.sharepoint.com"
                        },
                        @{
                            Source = $testParams.Url
                            Target = "http://other.sharepoint.com"
                        }
                    )
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the Get - Remove - New EnterpriseSearchCrawlMapping update the crawl mapping" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Get-SPEnterpriseSearchCrawlMapping
                    Assert-MockCalled Remove-SPEnterpriseSearchCrawlMapping
                    Assert-MockCalled New-SPEnterpriseSearchCrawlMapping
                }
            }

            Context -Name "When a crawl mapping does exists, but it shouldn't" -Fixture {
                $testParams = @{
                    ServiceAppName = "Search Service Application"
                    Url            = "http://crawl.sharepoint.com"
                    Target         = "http://site.sharepoint.com"
                    Ensure         = "Absent"
                }

                Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith {
                    return @{
                        Name = "Search Service Application"
                    }
                }


                Mock -CommandName Get-SPEnterpriseSearchCrawlMapping -MockWith {
                    return @(
                        @{
                            Source = "http://other.sharepoint.com"
                            Target = "http://site.sharepoint.com"
                        },
                        @{
                            Source = "http://site.sharepoint.com"
                            Target = "http://site2.sharepoint.com"
                        },
                        @{
                            Source = $testParams.Url
                            Target = $testParams.Target
                        }
                    )
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the Get Remove New -SPEnterpriseSearchCrawlMapping update the crawl mapping" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Get-SPEnterpriseSearchCrawlMapping
                    Assert-MockCalled Remove-SPEnterpriseSearchCrawlMapping
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
