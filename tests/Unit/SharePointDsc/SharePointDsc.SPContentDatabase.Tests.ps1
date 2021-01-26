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
$script:DSCResourceName = 'SPContentDatabase'
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
                try
                {
                    [Microsoft.SharePoint.Administration.SPObjectStatus]
                }
                catch
                {
                    Add-Type -TypeDefinition @"
namespace Microsoft.SharePoint.Administration {
    public enum SPObjectStatus { Online, Disabled };
}
"@
                }

                # Mocks for all contexts
                Mock -CommandName Dismount-SPContentDatabase -MockWith { }
                Mock -CommandName Get-SPWebApplication -MockWith {
                    return @{
                        Url = "http://sharepoint.contoso.com/"
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
            Context -Name "DatabaseServer parameter does not match actual setting" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name             = "SharePoint_Content_01"
                        DatabaseServer   = "SQLSrv"
                        WebAppUrl        = "http://sharepoint.contoso.com"
                        Enabled          = $true
                        WarningSiteCount = 2000
                        MaximumSiteCount = 5000
                        Ensure           = "Present"
                    }

                    Mock -CommandName Get-SPDatabase -MockWith {
                        $returnval = @{
                            Name             = "SharePoint_Content_01"
                            Type             = "Content Database"
                            Server           = "WrongSQLSrv"
                            WebApplication   = @{
                                Url = "http://sharepoint.contoso.com/"
                            }
                            Status           = "Online"
                            WarningSiteCount = 2000
                            MaximumSiteCount = 5000
                        }
                        $returnVal = $returnVal | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                            return @{
                                FullName = "Microsoft.SharePoint.Administration.SPContentDatabase"
                            }
                        } -PassThru -Force
                        return $returnval
                    }
                    Mock -CommandName Get-SPWebApplication -MockWith {
                        return @{
                            Url = "http://sharepoint.contoso.com/"
                        }
                    }
                }

                It "Should return Ensure=Present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false and display message to indicate the databaseserver parameter does not match" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the test method to say the databaseserver parameter does not match" {
                    { Set-TargetResource @testParams } | Should -Throw "Specified database server does not match the actual database server. This resource cannot move the database to a different SQL instance."
                }
            }

            Context -Name "Specified Web application does not exist" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name             = "SharePoint_Content_01"
                        DatabaseServer   = "SQLSrv"
                        WebAppUrl        = "http://sharepoint.contoso.com"
                        Enabled          = $true
                        WarningSiteCount = 2000
                        MaximumSiteCount = 5000
                        Ensure           = "Present"
                    }

                    Mock -CommandName Get-SPDatabase -MockWith {
                        $returnval = @{
                            Name             = "SharePoint_Content_01"
                            Type             = "Content Database"
                            Server           = "SQLSrv"
                            WebApplication   = @{
                                Url = "http://sharepoint2.contoso.com/"
                            }
                            Status           = "Online"
                            WarningSiteCount = 2000
                            MaximumSiteCount = 5000
                        }
                        $returnVal = $returnVal | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                            return @{
                                FullName = "Microsoft.SharePoint.Administration.SPContentDatabase"
                            }
                        } -PassThru -Force
                        return $returnval
                    }
                    Mock -CommandName Get-SPWebApplication -MockWith {
                        return @()
                    }
                }

                It "Should return Ensure=Present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method to say the web application does not exist" {
                    { Set-TargetResource @testParams } | Should -Throw "Specified web application does not exist."
                }
            }

            Context -Name "Mount database throws an error" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name             = "SharePoint_Content_01"
                        DatabaseServer   = "SQLSrv"
                        WebAppUrl        = "http://sharepoint.contoso.com"
                        Enabled          = $true
                        WarningSiteCount = 2000
                        MaximumSiteCount = 5000
                        Ensure           = "Present"
                    }

                    Mock -CommandName Get-SPDatabase -MockWith {
                        $returnVal = @{ }
                        $returnVal = $returnVal | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscContentDatabaseUpdated = $true
                        } -PassThru
                        return $returnVal
                    }

                    Mock -CommandName Mount-SPContentDatabase -MockWith {
                        throw "MOUNT ERROR"
                    }
                }

                It "mounting a content database generates an error" {
                    { Set-TargetResource @testParams } | Should -Throw "Error occurred while mounting content database. Content database is not mounted."
                }
            }

            Context -Name "Content database does not exist, but has to be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name             = "SharePoint_Content_01"
                        DatabaseServer   = "SQLSrv"
                        WebAppUrl        = "http://sharepoint.contoso.com"
                        Enabled          = $true
                        WarningSiteCount = 2000
                        MaximumSiteCount = 5000
                        Ensure           = "Present"
                    }

                    Mock -CommandName Get-SPDatabase -MockWith {
                        $returnVal = @{ }
                        $returnVal = $returnVal | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscContentDatabaseUpdated = $true
                        } -PassThru
                        return $returnVal
                    }

                    Mock -CommandName Get-SPWebApplication { return @{ Url = "http://sharepoint.contoso.com/" } }
                    Mock Mount-SPContentDatabase {
                        $returnval = @{
                            Name             = "SharePoint_Content_01"
                            Server           = "SQLSrv"
                            WebApplication   = @{ Url = "http://sharepoint.contoso.com/" }
                            Status           = "Online"
                            WarningSiteCount = 2000
                            MaximumSiteCount = 5000
                        }
                        $returnVal = $returnVal | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscContentDatabaseUpdated = $true
                        } -PassThru
                        return $returnVal
                    }
                }

                It "Should return Ensure=Absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                $Global:SPDscContentDatabaseUpdated = $false
                It "mounts a (new) content database" {
                    Set-TargetResource @testParams
                    $Global:SPDscContentDatabaseUpdated | Should -Be $true
                }
            }

            Context -Name "Content database exists, but has incorrect settings" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name             = "SharePoint_Content_01"
                        DatabaseServer   = "SQLSrv"
                        WebAppUrl        = "http://sharepoint.contoso.com"
                        Enabled          = $true
                        WarningSiteCount = 2000
                        MaximumSiteCount = 5000
                        Ensure           = "Present"
                    }

                    Mock -CommandName Get-SPDatabase -MockWith {
                        $returnVal = @{
                            Name             = "SharePoint_Content_01"
                            Type             = "Content Database"
                            Server           = "SQLSrv"
                            WebApplication   = @{ Url = "http://sharepoint.contoso.com/" }
                            Status           = "Disabled"
                            WarningSiteCount = 1000
                            MaximumSiteCount = 2000
                        }
                        $returnVal = $returnVal | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscContentDatabaseUpdated = $true
                        } -PassThru
                        $returnVal = $returnVal | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                            return @{
                                FullName = "Microsoft.SharePoint.Administration.SPContentDatabase"
                            }
                        } -PassThru -Force

                        return $returnVal
                    }
                }

                It "Should return Ensure=Present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the content database settings" {
                    $Global:SPDscContentDatabaseUpdated = $false
                    Set-TargetResource @testParams
                    $Global:SPDscContentDatabaseUpdated | Should -Be $true
                }
            }

            Context -Name "Content database exists, but Ensure is set to Absent" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name             = "SharePoint_Content_01"
                        DatabaseServer   = "SQLSrv"
                        WebAppUrl        = "http://sharepoint.contoso.com"
                        Enabled          = $true
                        WarningSiteCount = 2000
                        MaximumSiteCount = 5000
                        Ensure           = "Absent"
                    }

                    Mock -CommandName Get-SPDatabase -MockWith {
                        $returnVal = @{
                            Name             = "SharePoint_Content_01"
                            Type             = "Content Database"
                            Server           = "SQLSrv"
                            WebApplication   = @{ Url = "http://sharepoint.contoso.com/" }
                            Status           = "Disabled"
                            WarningSiteCount = 1000
                            MaximumSiteCount = 2000
                        }
                        $returnVal = $returnVal | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscContentDatabaseUpdated = $true
                        } -PassThru
                        $returnVal = $returnVal | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                            return @{
                                FullName = "Microsoft.SharePoint.Administration.SPContentDatabase"
                            }
                        } -PassThru -Force
                        return $returnVal
                    }
                }

                It "Should return Ensure=Present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the content database settings" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Dismount-SPContentDatabase
                }
            }

            Context -Name "Content database is mounted to the incorrect web application" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name             = "SharePoint_Content_01"
                        DatabaseServer   = "SQLSrv"
                        WebAppUrl        = "http://sharepoint.contoso.com"
                        Enabled          = $true
                        WarningSiteCount = 2000
                        MaximumSiteCount = 5000
                        Ensure           = "Present"
                    }

                    Mock -CommandName Get-SPDatabase -MockWith {
                        $returnVal = @{
                            Name             = "SharePoint_Content_01"
                            Type             = "Content Database"
                            Server           = "SQLSrv"
                            WebApplication   = @{ Url = "http://sharepoint2.contoso.com/" }
                            Status           = "Online"
                            WarningSiteCount = 2000
                            MaximumSiteCount = 5000
                        }
                        $returnVal = $returnVal | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                            return @{
                                FullName = "Microsoft.SharePoint.Administration.SPContentDatabase"
                            }
                        } -PassThru -Force
                        return $returnVal
                    }

                    Mock -CommandName Get-SPWebApplication { return @{ Url = "http://sharepoint.contoso.com/" } }
                    Mock Dismount-SPContentDatabase { }
                    Mock Mount-SPContentDatabase {
                        $returnVal = @{
                            Name             = "SharePoint_Content_01"
                            Server           = "SQLSrv"
                            WebApplication   = @{ Url = "http://sharepoint.contoso.com/" }
                            Status           = "Online"
                            WarningSiteCount = 2000
                            MaximumSiteCount = 5000
                        }
                        $returnVal = $returnVal | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscContentDatabaseUpdated = $true
                        } -PassThru
                        return $returnVal
                    }
                }

                It "Should return Ensure=Present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                $Global:SPDscContentDatabaseUpdated = $false
                It "move the content database to the specified web application via set method" {
                    Set-TargetResource @testParams
                    $Global:SPDscContentDatabaseUpdated | Should -Be $true
                }
            }

            Context -Name "Content database is present with correct settings and Ensure is Present" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name             = "SharePoint_Content_01"
                        DatabaseServer   = "SQLSrv"
                        WebAppUrl        = "http://sharepoint.contoso.com"
                        Enabled          = $true
                        WarningSiteCount = 2000
                        MaximumSiteCount = 5000
                        Ensure           = "Present"
                    }

                    Mock -CommandName Get-SPDatabase -MockWith {
                        $returnVal = @{
                            Name             = "SharePoint_Content_01"
                            Type             = "Content Database"
                            Server           = "SQLSrv"
                            WebApplication   = @{ Url = "http://sharepoint.contoso.com/" }
                            Status           = "Online"
                            WarningSiteCount = 2000
                            MaximumSiteCount = 5000
                        }
                        $returnVal = $returnVal | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                            return @{
                                FullName = "Microsoft.SharePoint.Administration.SPContentDatabase"
                            }
                        } -PassThru -Force
                        return $returnVal
                    }
                }

                It "Should return Ensure=Present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Content database is absent and Ensure is Absent" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name             = "SharePoint_Content_01"
                        DatabaseServer   = "SQLSrv"
                        WebAppUrl        = "http://sharepoint.contoso.com"
                        Enabled          = $true
                        WarningSiteCount = 2000
                        MaximumSiteCount = 5000
                        Ensure           = "Absent"
                    }

                    Mock -CommandName Get-SPDatabase -MockWith {
                        $returnVal = @{ }
                        return $returnVal
                    }
                }

                It "Should return Ensure=Absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")

                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Name             = 'Content01DB'
                            DatabaseServer   = 'SQL01'
                            WebAppUrl        = 'https://sharepoint.contoso.com'
                            Enabled          = $true
                            WarningSiteCount = 2000
                            MaximumSiteCount = 5000
                            Ensure           = "Present"
                        }
                    }

                    Mock -CommandName Get-SPContentDatabase -MockWith {
                        $spContentDB = [PSCustomObject]@{
                            Name           = "Content01DB"
                            WebApplication = @{
                                Url = 'https://sharepoint.contoso.com'
                            }
                        }
                        return $spContentDB
                    }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        SPContentDatabase Content01DB
        {
            DatabaseServer       = $ConfigurationData.NonNodeData.DatabaseServer;
            Enabled              = $True;
            Ensure               = "Present";
            MaximumSiteCount     = 5000;
            Name                 = "Content01DB";
            PsDscRunAsCredential = $Credsspfarm;
            WarningSiteCount     = 2000;
            WebAppUrl            = "https://sharepoint.contoso.com";
        }

'@
                }

                It "Should return valid DSC block from the Export method" {
                    Export-TargetResource | Should -Be $result
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
