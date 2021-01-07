[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param
(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
            -Resolve)
)

$script:DSCModuleName = 'SharePointDsc'
$script:DSCResourceName = 'SPDesignerSettings'
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
                Invoke-Command -Scriptblock $Global:SPDscHelper.InitializeScript -NoNewScope

                # Mocks for all contexts
                Mock -CommandName Get-SPFarm -MockWith {
                    return @{ }
                }

                function Add-SPDscEvent
                {
                    param (
                        [Parameter(Mandatory = $true)]
                        [System.String]
                        $Message,

                        [Parameter(Mandatory = $true)]
                        [System.String]
                        $Source,

                        [Parameter()]
                        [ValidateSet('Error', 'Information', 'FailureAudit', 'SuccessAudit', 'Warning')]
                        [System.String]
                        $EntryType,

                        [Parameter()]
                        [System.UInt32]
                        $EventID
                    )
                }
            }

            # Test contexts
            Context -Name "The server is not part of SharePoint farm" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl                              = "https://intranet.sharepoint.contoso.com"
                        SettingsScope                          = "WebApplication"
                        AllowSharePointDesigner                = $false
                        AllowDetachPagesFromDefinition         = $false
                        AllowCustomiseMasterPage               = $false
                        AllowManageSiteURLStructure            = $false
                        AllowCreateDeclarativeWorkflow         = $false
                        AllowSavePublishDeclarativeWorkflow    = $false
                        AllowSaveDeclarativeWorkflowAsTemplate = $false
                    }

                    Mock -CommandName Get-SPFarm -MockWith {
                        throw "Unable to detect local farm"
                    }
                }

                It "Should return null from the get method" {
                    (Get-TargetResource @testParams).AllowSharePointDesigner | Should -Be $null
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method to say there is no local farm" {
                    { Set-TargetResource @testParams } | Should -Throw "No local SharePoint farm was detected"
                }
            }

            Context -Name "The server is in a farm, target web application and the incorrect settings have been applied" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl                              = "https://intranet.sharepoint.contoso.com"
                        SettingsScope                          = "WebApplication"
                        AllowSharePointDesigner                = $false
                        AllowDetachPagesFromDefinition         = $false
                        AllowCustomiseMasterPage               = $false
                        AllowManageSiteURLStructure            = $false
                        AllowCreateDeclarativeWorkflow         = $false
                        AllowSavePublishDeclarativeWorkflow    = $false
                        AllowSaveDeclarativeWorkflowAsTemplate = $false
                    }

                    Mock -CommandName Get-SPDesignerSettings -MockWith { return @{
                            AllowDesigner                          = $true
                            AllowRevertFromTemplate                = $true
                            AllowMasterPageEditing                 = $true
                            ShowURLStructure                       = $true
                            AllowCreateDeclarativeWorkflow         = $true
                            AllowSavePublishDeclarativeWorkflow    = $true
                            AllowSaveDeclarativeWorkflowAsTemplate = $true
                        }
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $result = @{ }
                        $result.DisplayName = "Test"
                        $result.Url = "https://intranet.sharepoint.contoso.com"

                        $result = $result | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscDesignerUpdated = $true
                        } -PassThru

                        return $result
                    }
                }

                It "Should return values from the get method" {
                    (Get-TargetResource @testParams).AllowSharePointDesigner | Should -Be $true
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                $Global:SPDscDesignerUpdated = $false
                It "Should update the SharePoint Designer settings" {
                    Set-TargetResource @testParams
                    $Global:SPDscDesignerUpdated | Should -Be $true
                }
            }

            Context -Name "The server is in a farm, target site collection and the incorrect settings have been applied" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl                              = "https://intranet.sharepoint.contoso.com"
                        SettingsScope                          = "SiteCollection"
                        AllowSharePointDesigner                = $false
                        AllowDetachPagesFromDefinition         = $false
                        AllowCustomiseMasterPage               = $false
                        AllowManageSiteURLStructure            = $false
                        AllowCreateDeclarativeWorkflow         = $false
                        AllowSavePublishDeclarativeWorkflow    = $false
                        AllowSaveDeclarativeWorkflowAsTemplate = $false
                    }

                    Mock -CommandName Get-SPSite -MockWith {
                        return @{
                            Url                                    = "https://intranet.sharepoint.contoso.com"
                            AllowDesigner                          = $true
                            AllowRevertFromTemplate                = $true
                            AllowMasterPageEditing                 = $true
                            ShowURLStructure                       = $true
                            AllowCreateDeclarativeWorkflow         = $true
                            AllowSavePublishDeclarativeWorkflow    = $true
                            AllowSaveDeclarativeWorkflowAsTemplate = $true
                        }
                    }

                    Mock -CommandName Test-SPDscRunAsCredential { return $true }
                }

                It "Should return values from the get method" {
                    (Get-TargetResource @testParams).AllowSharePointDesigner | Should -Be $true
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the SharePoint Designer settings" {
                    Set-TargetResource @testParams
                }
            }

            Context -Name "The server is in a farm, target site collection and InstallAccount is used" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl                              = "https://intranet.sharepoint.contoso.com"
                        SettingsScope                          = "SiteCollection"
                        AllowSharePointDesigner                = $false
                        AllowDetachPagesFromDefinition         = $false
                        AllowCustomiseMasterPage               = $false
                        AllowManageSiteURLStructure            = $false
                        AllowCreateDeclarativeWorkflow         = $false
                        AllowSavePublishDeclarativeWorkflow    = $false
                        AllowSaveDeclarativeWorkflowAsTemplate = $false
                    }
                    Mock -CommandName Get-SPSite -MockWith {
                        return @{
                            Url                                    = "https://intranet.sharepoint.contoso.com"
                            AllowDesigner                          = $true
                            AllowRevertFromTemplate                = $true
                            AllowMasterPageEditing                 = $true
                            ShowURLStructure                       = $true
                            AllowCreateDeclarativeWorkflow         = $true
                            AllowSavePublishDeclarativeWorkflow    = $true
                            AllowSaveDeclarativeWorkflowAsTemplate = $true
                        }
                    }
                    Mock -CommandName Test-SPDscRunAsCredential { return $false }
                }

                It "Should throw an exception in the get method to say that this is not supported" {
                    { Get-TargetResource @testParams } | Should -Throw "http://aka.ms/SharePointDscRemoteIssues"
                }

                It "Should throw an exception in the test method to say that this is not supported" {
                    { Test-TargetResource @testParams } | Should -Throw "http://aka.ms/SharePointDscRemoteIssues"
                }

                It "Should throw an exception in the set method to say that this is not supported" {
                    { Set-TargetResource @testParams } | Should -Throw "http://aka.ms/SharePointDscRemoteIssues"
                }
            }

            Context -Name "The server is in a farm, target is web application and the correct settings have been applied" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl                              = "https://intranet.sharepoint.contoso.com"
                        SettingsScope                          = "SiteCollection"
                        AllowSharePointDesigner                = $false
                        AllowDetachPagesFromDefinition         = $false
                        AllowCustomiseMasterPage               = $false
                        AllowManageSiteURLStructure            = $false
                        AllowCreateDeclarativeWorkflow         = $false
                        AllowSavePublishDeclarativeWorkflow    = $false
                        AllowSaveDeclarativeWorkflowAsTemplate = $false
                    }

                    Mock -CommandName Get-SPSite -MockWith {
                        $returnVal = @{
                            Url                                    = "https://intranet.sharepoint.contoso.com"
                            AllowDesigner                          = $false
                            AllowRevertFromTemplate                = $false
                            AllowMasterPageEditing                 = $false
                            ShowURLStructure                       = $false
                            AllowCreateDeclarativeWorkflow         = $false
                            AllowSavePublishDeclarativeWorkflow    = $false
                            AllowSaveDeclarativeWorkflowAsTemplate = $false
                        }
                        $returnVal = $returnVal | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscDesignerUpdated = $true
                        } -PassThru
                        return $returnVal
                    }

                    Mock -CommandName Test-SPDscRunAsCredential { return $true }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        $result = @{ }
                        $result.DisplayName = "Test"
                        $result.Url = "https://intranet.sharepoint.contoso.com"

                        return $result
                    }
                }

                It "Should return values from the get method" {
                    (Get-TargetResource @testParams).AllowSharePointDesigner | Should -Be $false
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The server is in a farm, target is site collection and the correct settings have been applied" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl                              = "https://intranet.sharepoint.contoso.com"
                        SettingsScope                          = "SiteCollection"
                        AllowSharePointDesigner                = $false
                        AllowDetachPagesFromDefinition         = $false
                        AllowCustomiseMasterPage               = $false
                        AllowManageSiteURLStructure            = $false
                        AllowCreateDeclarativeWorkflow         = $false
                        AllowSavePublishDeclarativeWorkflow    = $false
                        AllowSaveDeclarativeWorkflowAsTemplate = $false
                    }

                    Mock -CommandName Get-SPSite -MockWith {
                        $returnVal = @{
                            Url                                    = "https://intranet.sharepoint.contoso.com"
                            AllowDesigner                          = $false
                            AllowRevertFromTemplate                = $false
                            AllowMasterPageEditing                 = $false
                            ShowURLStructure                       = $false
                            AllowCreateDeclarativeWorkflow         = $false
                            AllowSavePublishDeclarativeWorkflow    = $false
                            AllowSaveDeclarativeWorkflowAsTemplate = $false
                        }
                        $returnVal = $returnVal | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscDesignerUpdated = $true
                        } -PassThru
                        return $returnVal
                    }

                    Mock -CommandName Test-SPDscRunAsCredential -MockWith { return $true }
                }

                It "Should return values from the get method" {
                    (Get-TargetResource @testParams).AllowSharePointDesigner | Should -Be $false
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            WebAppUrl                              = 'https://sharepoint.contoso.com'
                            SettingsScope                          = 'WebApplication'
                            AllowSharePointDesigner                = $false
                            AllowDetachPagesFromDefinition         = $false
                            AllowCustomiseMasterPage               = $false
                            AllowManageSiteURLStructure            = $false
                            AllowCreateDeclarativeWorkflow         = $false
                            AllowSavePublishDeclarativeWorkflow    = $false
                            AllowSaveDeclarativeWorkflowAsTemplate = $false
                        }
                    }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        SPDesignerSettings WebApplication[0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            AllowCreateDeclarativeWorkflow         = \$False;
            AllowCustomiseMasterPage               = \$False;
            AllowDetachPagesFromDefinition         = \$False;
            AllowManageSiteURLStructure            = \$False;
            AllowSaveDeclarativeWorkflowAsTemplate = \$False;
            AllowSavePublishDeclarativeWorkflow    = \$False;
            AllowSharePointDesigner                = \$False;
            PsDscRunAsCredential                   = \$Credsspfarm;
            SettingsScope                          = "WebApplication";
            WebAppUrl                              = "https://sharepoint.contoso.com";
        }

'@
                }

                It "Should return valid DSC block from the Export method" {
                    Export-TargetResource -Url 'https://sharepoint.contoso.com' -Scope 'WebApplication' | Should -Match $result
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
