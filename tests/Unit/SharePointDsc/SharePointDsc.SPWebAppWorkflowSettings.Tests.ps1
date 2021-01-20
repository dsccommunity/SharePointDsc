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
$script:DSCResourceName = 'SPWebAppWorkflowSettings'
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
            Context -Name "The web appliation exists and has the correct workflow settings" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl                                     = "http://sites.sharepoint.com"
                        ExternalWorkflowParticipantsEnabled           = $true
                        UserDefinedWorkflowsEnabled                   = $true
                        EmailToNoPermissionWorkflowParticipantsEnable = $true
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        return @(@{
                                DisplayName                                    = $testParams.Name
                                ApplicationPool                                = @{
                                    Name     = $testParams.ApplicationPool
                                    Username = $testParams.ApplicationPoolAccount
                                }
                                ContentDatabases                               = @(
                                    @{
                                        Name   = "SP_Content_01"
                                        Server = "sql.domain.local"
                                    }
                                )
                                IisSettings                                    = @(
                                    @{ Path = "C:\inetpub\wwwroot\something" }
                                )
                                Url                                            = $testParams.WebAppUrl
                                UserDefinedWorkflowsEnabled                    = $true
                                EmailToNoPermissionWorkflowParticipantsEnabled = $true
                                ExternalWorkflowParticipantsEnabled            = $true
                            })
                    }
                }

                It "Should return the current data from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The web appliation exists and uses incorrect workflow settings" -Fixture {
                BeforeAll {
                    $testParams = @{
                        WebAppUrl                                     = "http://sites.sharepoint.com"
                        ExternalWorkflowParticipantsEnabled           = $true
                        UserDefinedWorkflowsEnabled                   = $true
                        EmailToNoPermissionWorkflowParticipantsEnable = $true
                    }

                    Mock -CommandName Get-SPWebapplication -MockWith {
                        $webApp = @{
                            DisplayName                                    = $testParams.Name
                            ApplicationPool                                = @{
                                Name     = $testParams.ApplicationPool
                                Username = $testParams.ApplicationPoolAccount
                            }
                            ContentDatabases                               = @(
                                @{
                                    Name   = "SP_Content_01"
                                    Server = "sql.domain.local"
                                }
                            )
                            IisSettings                                    = @(
                                @{ Path = "C:\inetpub\wwwroot\something" }
                            )
                            Url                                            = $testParams.WebAppUrl
                            UserDefinedWorkflowsEnabled                    = $false
                            EmailToNoPermissionWorkflowParticipantsEnabled = $false
                            ExternalWorkflowParticipantsEnabled            = $false
                        }
                        $webApp = $webApp | Add-Member -MemberType ScriptMethod -Name Update -Value { } -PassThru |
                            Add-Member -MemberType ScriptMethod -Name UpdateWorkflowConfigurationSettings -Value {
                                $Global:SPDscWebApplicationUpdateWorkflowCalled = $true
                            } -PassThru
                        return @($webApp)
                    }
                }

                It "Should return the current data from the get method" {
                    Get-TargetResource @testParams | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                $Global:SPDscWebApplicationUpdateWorkflowCalled = $false
                It "Should update the workflow settings" {
                    Set-TargetResource @testParams
                    $Global:SPDscWebApplicationUpdateWorkflowCalled | Should -Be $true
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")

                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            WebAppUrl                                     = "Shttp://example.contoso.local"
                            ExternalWorkflowParticipantsEnabled           = $false
                            EmailToNoPermissionWorkflowParticipantsEnable = $false
                            UserDefinedWorkflowsEnabled                   = $true
                        }
                    }

                    Mock -CommandName Get-SPWebApplication -MockWith {
                        $spWebApp = [PSCustomObject]@{
                            Name = "SharePoint Sites"
                            Url  = "https://intranet.sharepoint.contoso.com"
                        }
                        return $spWebApp
                    }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        SPWebAppWorkflowSettings [0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            EmailToNoPermissionWorkflowParticipantsEnable = \$False;
            ExternalWorkflowParticipantsEnabled           = \$False;
            PsDscRunAsCredential                          = \$Credsspfarm;
            UserDefinedWorkflowsEnabled                   = \$True;
            WebAppUrl                                     = "Shttp://example.contoso.local";
        }

'@
                }

                It "Should return valid DSC block from the Export method" {
                    Export-TargetResource | Should -Match $result
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
