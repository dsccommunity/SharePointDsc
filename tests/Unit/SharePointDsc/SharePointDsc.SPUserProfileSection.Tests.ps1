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
$script:DSCResourceName = 'SPUserProfileSection'
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

                $testParams = @{
                    Name               = "PersonalInformation"
                    UserProfileService = "User Profile Service Application"
                    DisplayName        = "Personal Information"
                    DisplayOrder       = 5000
                }

                try
                {
                    [Microsoft.Office.Server.UserProfiles]
                }
                catch
                {
                    try
                    {
                        Add-Type -TypeDefinition @"
                        namespace Microsoft.Office.Server.UserProfiles {
                        public enum ConnectionType { ActiveDirectory, BusinessDataCatalog };
                        public enum ProfileType { User};
                        }
"@ -ErrorAction SilentlyContinue
                    }
                    catch
                    {
                        Write-Verbose -Message "The Type was already added."
                    }
                }


                $coreProperty = @{
                    DisplayName = $testParams.DisplayName
                    Name        = $testParams.Name
                } | Add-Member -MemberType ScriptMethod Commit {
                    $Global:SPUPSPropertyCommitCalled = $true
                } -PassThru | Add-Member -MemberType ScriptMethod Delete {
                    $Global:SPUPSPropertyDeleteCalled = $true
                } -PassThru
                $subTypeProperty = @{
                    Name         = $testParams.Name
                    DisplayName  = $testParams.DisplayName
                    DisplayOrder = $testParams.DisplayOrder
                    CoreProperty = $coreProperty
                } | Add-Member -MemberType ScriptMethod Commit {
                    $Global:SPUPSPropertyCommitCalled = $true
                } -PassThru
                $userProfileSubTypePropertiesNoProperty = @{ } | Add-Member -MemberType ScriptMethod Create {
                    param($section)
                    $Global:SPUPSubTypeCreateCalled = $true
                } -PassThru | Add-Member -MemberType ScriptMethod GetSectionByName {
                    $result = $null
                    if ($Global:SPUPGetSectionByNameCalled -eq $TRUE)
                    {
                        $result = $subTypeProperty
                    }
                    $Global:SPUPGetSectionByNameCalled = $true
                    return $result
                } -PassThru | Add-Member -MemberType ScriptMethod -Name Add -Value {
                    $Global:SPUPSubTypeAddCalled = $true
                } -PassThru -Force
                $coreProperties = @{ProfileInformation = $coreProperty }
                $userProfileSubTypePropertiesProperty = @{"ProfileInformation" = $subTypeProperty } | Add-Member -MemberType ScriptMethod Create {
                    $Global:SPUPSubTypeCreateCalled = $true
                } -PassThru | Add-Member -MemberType ScriptMethod -Name Add -Value {
                    $Global:SPUPSubTypeAddCalled = $true
                } -PassThru -Force
                Mock -CommandName Get-SPDscUserProfileSubTypeManager -MockWith {
                    $result = @{ } | Add-Member -MemberType ScriptMethod GetProfileSubtype {
                        $Global:SPUPGetProfileSubtypeCalled = $true
                        return @{
                            Properties = $userProfileSubTypePropertiesNoProperty
                        }
                    } -PassThru

                    return $result
                }

                Mock -CommandName Set-SPDscObjectPropertyIfValuePresent -MockWith { return ; }
                Mock -CommandName Get-SPWebApplication -MockWith {
                    return @(
                        @{
                            IsAdministrationWebApplication = $true
                            Url                            = "caURL"
                        })
                }

                Mock -CommandName New-Object -MockWith {
                    $ProfilePropertyManager = @{"Contoso" = $null } # $connection is never set, so it will always be $null
                    return (@{
                            ProfilePropertyManager = $ProfilePropertyManager
                            ConnectionManager      = $null # $ConnnectionManager is never set, so it will always be $null
                        } | Add-Member -MemberType ScriptMethod GetPropertiesWithSection {
                            $Global:UpsConfigManagerGetPropertiesWithSectionCalled = $true;

                            $result = (
                                @{
                                    IsSection = $true
                                    Name      = 'DemoSection'
                                } | Add-Member -MemberType ScriptMethod Create {
                                    param ($section)

                                    $result = @{Name = ""
                                        DisplayName  = ""
                                        DisplayOrder = 0
                                    } | Add-Member -MemberType ScriptMethod Commit {
                                        $Global:UpsConfigManagerCommitCalled = $true;
                                    } -PassThru
                                    return $result
                                } -PassThru -Force | Add-Member -MemberType ScriptMethod GetSectionByName {
                                    $result = $null
                                    if ($Global:UpsConfigManagerGetSectionByNameCalled -eq $TRUE)
                                    {
                                        $result = $subTypeProperty
                                    }
                                    $Global:UpsConfigManagerGetSectionByNameCalled = $true
                                    return $result
                                    return $null # $userProfileSubTypePropertiesUpdateProperty is never set, so it will always be $null;
                                } -PassThru | Add-Member -MemberType ScriptMethod SetDisplayOrderBySectionName {
                                    $Global:UpsConfigManagerSetDisplayOrderBySectionNameCalled = $true;
                                    return $null # $userProfileSubTypePropertiesUpdateProperty is never set, so it will always be $null;
                                } -PassThru | Add-Member -MemberType ScriptMethod CommitDisplayOrder {
                                    $Global:UpsConfigManagerCommitDisplayOrderCalled = $true;
                                    return $null # $userProfileSubTypePropertiesUpdateProperty is never set, so it will always be $null;
                                } -PassThru | Add-Member -MemberType ScriptMethod RemoveSectionByName {
                                    $Global:UpsConfigManagerRemoveSectionByNameCalled = $true;
                                    return ($coreProperties);
                                } -PassThru
                            )
                            return $result

                        } -PassThru )
                } -ParameterFilter { $TypeName -eq "Microsoft.Office.Server.UserProfiles.UserProfileConfigManager" }

                Mock -CommandName Get-SPServiceApplication -MockWith {
                    return @{
                        Name                         = "User Profile Service Application"
                        TypeName                     = "User Profile Service Application"
                        ApplicationPool              = "SharePoint Service Applications"
                        ServiceApplicationProxyGroup = "Proxy Group"
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

            Context -Name "When section doesn't exist" {
                It "Should return null from the Get method" {
                    $Global:UpsConfigManagerGetSectionByNameCalled = $false
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                    Assert-MockCalled Get-SPServiceApplication
                    $Global:UpsConfigManagerGetSectionByNameCalled | Should -Be $true
                }

                It "Should return false when the Test method is called" {
                    $Global:UpsConfigManagerGetSectionByNameCalled = $false
                    Test-TargetResource @testParams | Should -Be $false
                    $Global:UpsConfigManagerGetSectionByNameCalled | Should -Be $true
                }

                It "Should create a new user profile section in the set method" {
                    $Global:SPUPSubTypeCreateCalled = $false
                    $Global:UpsConfigManagerSetDisplayOrderBySectionNameCalled = $false
                    $Global:SPUPSPropertyCommitCalled = $false;

                    Set-TargetResource @testParams
                    $Global:SPUPSubTypeCreateCalled | Should -Be $false
                    $Global:SPUPSPropertyCommitCalled | Should -Be $true
                    $Global:UpsConfigManagerSetDisplayOrderBySectionNameCalled | Should -Be $true
                }

            }
            Context -Name "When section exists and all properties match" {
                It "Should return valid value from the Get method" {
                    $Global:UpsConfigManagerGetSectionByNameCalled = $true

                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                    $Global:UpsConfigManagerGetSectionByNameCalled | Should -Be $true
                }

                It "Should return true when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $true
                }
                It "Should update an user profile property in the set method" {
                    $Global:UpsConfigManagerCommitCalled = $false
                    $Global:UpsConfigManagerSetDisplayOrderBySectionNameCalled = $false
                    Set-TargetResource @testParams
                    $Global:UpsConfigManagerCommitCalled | Should -Be $false
                    $Global:UpsConfigManagerSetDisplayOrderBySectionNameCalled | Should -Be $true
                }
            }

            Context -Name "When section exists and ensure equals Absent" {
                BeforeAll {
                    Mock -CommandName Get-SPDscUserProfileSubTypeManager -MockWith {
                        $result = @{ } | Add-Member -MemberType ScriptMethod GetProfileSubtype {
                            $Global:SPUPGetProfileSubtypeCalled = $true
                            return @{
                                Properties = $userProfileSubTypePropertiesProperty
                            }
                        } -PassThru

                        return $result
                    }
                    $testParams.Ensure = "Absent"
                }

                It "Should return true when the Test method is called" {
                    $Global:SPUPGetSectionByNameCalled = $true
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "deletes an user profile property in the set method" {
                    $Global:UpsConfigManagerGetSectionByNameCalled = $true
                    $Global:UpsConfigManagerRemoveSectionByNameCalled = $false
                    Set-TargetResource @testParams
                    $Global:UpsConfigManagerRemoveSectionByNameCalled | Should -Be $true
                }
            }

            Context -Name "When section exists and display name and display order are different" {
                BeforeAll {
                    Mock -CommandName Get-SPDscUserProfileSubTypeManager -MockWith {
                        $result = @{ } | Add-Member -MemberType ScriptMethod GetProfileSubtype {
                            $Global:SPUPGetProfileSubtypeCalled = $true
                            return @{
                                Properties = $userProfileSubTypePropertiesProperty
                            }
                        } -PassThru
                        return $result
                    }
                    $testParams.Ensure = "Present"
                    $testParams.DisplayOrder = 5401
                    $testParams.DisplayName = "ProfileInformationUpdate"
                }

                It "Should return valid value from the Get method" {
                    $Global:SPUPGetSectionByNameCalled = $true
                    $currentValues = Get-TargetResource @testParams
                    $currentValues.Ensure | Should -Be "Present"
                    Assert-MockCalled Get-SPServiceApplication
                }

                It "Should return false when the Test method is called" {
                    $Global:SPUPGetSectionByNameCalled = $true
                    Test-TargetResource @testParams | Should -Be $false
                }
                It "Should update an user profile property in the set method" {
                    $Global:SPUPSubTypeCreateCalled = $false
                    $Global:UpsConfigManagerSetDisplayOrderBySectionNameCalled = $false
                    $Global:SPUPGetSectionByNameCalled = $true
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-SPDscObjectPropertyIfValuePresent
                    $Global:SPUPSubTypeCreateCalled | Should -Be $false
                    $Global:UpsConfigManagerSetDisplayOrderBySectionNameCalled | Should -Be $true
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")

                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Name               = "PersonalInformationSection"
                            UserProfileService = "User Profile Service Application"
                            DisplayName        = "Personal Information"
                            DisplayOrder       = 5000
                            Ensure             = "Present"
                        }
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName    = "User Profile Service Application"
                            DisplayName = "User Profile Service Application"
                            Name        = "User Profile Service Application"
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return @{
                                Name = 'UserProfileApplication'
                            }
                        } -PassThru -Force
                        return $spServiceApp
                    }

                    Mock -CommandName Get-SPServiceContext -MockWith { return "" }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        SPUserProfileSection [0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            DisplayName          = "Personal Information";
            DisplayOrder         = 5000;
            Ensure               = "Present";
            Name                 = "PersonalInformationSection";
            PsDscRunAsCredential = \$Credsspfarm;
            UserProfileService   = "User Profile Service Application";
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
