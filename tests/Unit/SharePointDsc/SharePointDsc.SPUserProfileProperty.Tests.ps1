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
$script:DSCResourceName = 'SPUserProfileProperty'
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

                $testParamsNewProperty = @{
                    Name                = "WorkEmailNew"
                    UserProfileService  = "User Profile Service Application"
                    DisplayName         = "WorkEmailNew"
                    Type                = "String (Single Value)"
                    Description         = ""
                    PolicySetting       = "Mandatory"
                    PrivacySetting      = "Public"
                    PropertyMappings    = @(
                        (New-CimInstance -ClassName MSFT_SPUserProfilePropertyMapping -ClientOnly -Property @{
                                ConnectionName = "contoso"
                                PropertyName   = "department"
                                Direction      = "Import"
                            })
                    )
                    Length              = 30
                    DisplayOrder        = 5496
                    IsEventLog          = $false
                    IsVisibleOnEditor   = $true
                    IsVisibleOnViewer   = $true
                    IsUserEditable      = $true
                    IsAlias             = $false
                    IsSearchable        = $false
                    IsReplicable        = $false
                    TermStore           = "Managed Metadata service"
                    TermGroup           = "People"
                    TermSet             = "Department"
                    UserOverridePrivacy = $false
                }

                $testParamsUpdateProperty = @{
                    Name                = "WorkEmailUpdate"
                    UserProfileService  = "User Profile Service Application"
                    DisplayName         = "WorkEmailUpdate"
                    Type                = "String (Single Value)"
                    Description         = ""
                    PolicySetting       = "Optin"
                    PrivacySetting      = "Private"
                    Ensure              = "Present"
                    PropertyMappings    = @(
                        (New-CimInstance -ClassName MSFT_SPUserProfilePropertyMapping -ClientOnly -Property @{
                                ConnectionName = "contoso"
                                PropertyName   = "department"
                                Direction      = "Import"
                            })
                    )
                    Length              = 25
                    DisplayOrder        = 5401
                    IsEventLog          = $true
                    IsVisibleOnEditor   = $True
                    IsVisibleOnViewer   = $true
                    IsUserEditable      = $true
                    IsAlias             = $true
                    IsSearchable        = $true
                    IsReplicable        = $true
                    TermStore           = "Managed Metadata service"
                    TermGroup           = "People"
                    TermSet             = "Location"
                    UserOverridePrivacy = $false
                }

                try
                {
                    [Microsoft.Office.Server.UserProfiles]
                }
                catch
                {
                    Add-Type @"
                        namespace Microsoft.Office.Server.UserProfiles {
                            public enum ConnectionType {
                                ActiveDirectory,
                                BusinessDataCatalog
                            };
                            public enum ProfileType {
                                User
                            };
                        }
"@ -ErrorAction SilentlyContinue
                }

                $corePropertyUpdate = @{
                    DisplayName   = "WorkEmailUpdate"
                    Name          = "WorkEmailUpdate"
                    IsMultiValued = $false
                    Type          = "String (Single Value)"
                    TermSet       = @{
                        Name      = $testParamsUpdateProperty.TermSet
                        Group     = @{
                            Name = $testParamsUpdateProperty.TermGroup
                        }
                        TermStore = @{
                            Name = $testParamsUpdateProperty.TermStore
                        }
                    }
                    Length        = 25
                    IsSearchable  = $true
                    IsReplicable  = $true
                } | Add-Member ScriptMethod Commit {
                    $Global:SPUPSPropertyCommitCalled = $true
                } -PassThru -Force | Add-Member ScriptMethod Delete {
                    $Global:SPUPSPropertyDeleteCalled = $true
                } -PassThru -Force

                $corePropertyUpdate.Type = $corePropertyUpdate.Type | Add-Member ScriptMethod GetTypeCode {
                    $Global:SPUPSPropertyGetTypeCodeCalled = $true
                    return $corePropertyUpdate.Type
                } -PassThru -Force

                $coreProperties = @{
                    WorkEmailUpdate = $corePropertyUpdate
                }

                $coreProperties = $coreProperties | Add-Member ScriptMethod Create {
                    $Global:SPUPCoreCreateCalled = $true
                    return @{
                        Name        = ""
                        DisplayName = ""
                        Type        = ""
                        TermSet     = $null
                        Length      = 10
                    }
                } -PassThru | Add-Member ScriptMethod RemovePropertyByName {
                    $Global:SPUPCoreRemovePropertyByNameCalled = $true
                } -PassThru | Add-Member ScriptMethod Add {
                    $Global:SPUPCoreAddCalled = $true
                } -PassThru -Force

                $typePropertyUpdate = @{
                    IsVisibleOnViewer = $true
                    IsVisibleOnEditor = $true
                    IsEventLog        = $true
                } | Add-Member ScriptMethod Commit {
                    $Global:SPUPPropertyCommitCalled = $true
                } -PassThru

                $subTypePropertyUpdate = @{
                    Name                = "WorkEmailUpdate"
                    DisplayName         = "WorkEmailUpdate"
                    Description         = ""
                    PrivacyPolicy       = "Optin"
                    DefaultPrivacy      = "Private"
                    DisplayOrder        = 5401
                    IsUserEditable      = $true
                    IsAlias             = $true
                    CoreProperty        = $corePropertyUpdate
                    TypeProperty        = $typePropertyUpdate
                    UserOverridePrivacy = $false
                } | Add-Member ScriptMethod Commit {
                    $Global:SPUPPropertyCommitCalled = $true
                } -PassThru

                $coreProperty = @{
                    DisplayName   = $testParamsNewProperty.DisplayName
                    Name          = $testParamsNewProperty.Name
                    IsMultiValued = $testParamsNewProperty.Type -eq "String (Multi Value)"
                    Type          = $testParamsNewProperty.Type
                    TermSet       = @{
                        Name      = $testParamsNewProperty.TermSet
                        Group     = @{
                            Name = $testParamsNewProperty.TermGroup
                        }
                        TermStore = @{
                            Name = $testParamsNewProperty.TermStore
                        }
                    }
                    Length        = $testParamsNewProperty.Length
                    IsSearchable  = $testParamsNewProperty.IsSearchable
                    IsReplicable  = $testParamsNewProperty.IsReplicable
                } | Add-Member ScriptMethod Commit {
                    $Global:SPUPSPropertyCommitCalled = $true
                } -PassThru | Add-Member ScriptMethod Delete {
                    $Global:SPUPSPropertyDeleteCalled = $true
                } -PassThru

                $typeProperty = @{
                    IsVisibleOnViewer = $testParamsNewProperty.IsVisibleOnViewer
                    IsVisibleOnEditor = $testParamsNewProperty.IsVisibleOnEditor
                    IsEventLog        = $testParamsNewProperty.IsEventLog
                } | Add-Member ScriptMethod Commit {
                    $Global:SPUPPropertyCommitCalled = $true
                } -PassThru

                $subTypeProperty = @{
                    Name                = $testParamsNewProperty.Name
                    DisplayName         = $testParamsNewProperty.DisplayName
                    Description         = $testParamsNewProperty.Description
                    PrivacyPolicy       = $testParamsNewProperty.PolicySetting
                    DefaultPrivacy      = $testParamsNewProperty.PrivacySetting
                    DisplayOrder        = $testParamsNewProperty.DisplayOrder
                    IsUserEditable      = $testParamsNewProperty.IsUserEditable
                    IsAlias             = $testParamsNewProperty.IsAlias
                    CoreProperty        = $coreProperty
                    TypeProperty        = $typeProperty
                    AllowPolicyOverride = $true
                } | Add-Member ScriptMethod Commit {
                    $Global:SPUPPropertyCommitCalled = $true
                } -PassThru

                $userProfileSubTypePropertiesNoProperty = @{
                } | Add-Member ScriptMethod Create {
                    $Global:SPUPSubTypeCreateCalled = $true
                } -PassThru | Add-Member ScriptMethod GetPropertyByName {
                    $result = $null
                    if ($Global:SPUPGetPropertyByNameCalled -eq $true)
                    {
                        $result = $subTypeProperty
                    }
                    $Global:SPUPGetPropertyByNameCalled = $true
                    return $result
                } -PassThru | Add-Member ScriptMethod Add {
                    $Global:SPUPSubTypeAddCalled = $true
                } -PassThru -Force

                $userProfileSubTypePropertiesUpdateProperty = @{
                    "WorkEmailUpdate" = $subTypePropertyUpdate
                } | Add-Member ScriptMethod Create {
                    $Global:SPUPSubTypeCreateCalled = $true
                } -PassThru | Add-Member ScriptMethod Add {
                    $Global:SPUPSubTypeAddCalled = $true
                } -PassThru -Force | Add-Member ScriptMethod GetPropertyByName {
                    $Global:SPUPGetPropertyByNameCalled = $true
                    return $subTypePropertyUpdate
                } -PassThru


                Mock -CommandName Get-SPDscUserProfileSubTypeManager -MockWith {
                    $result = @{
                    } | Add-Member ScriptMethod GetProfileSubtype {
                        $Global:SPUPGetProfileSubtypeCalled = $true
                        return @{
                            Properties = $userProfileSubTypePropertiesNoProperty
                        }
                    } -PassThru

                    return $result
                }

                Mock -CommandName Get-SPWebApplication -MockWith {
                    return @(
                        @{
                            IsAdministrationWebApplication = $true
                            Url                            = "caURL"
                        }
                    )
                }
                #IncludeCentralAdministration
                $TermSets = @{
                    Department = @{
                        Name = "Department"
                    }
                    Location   = @{
                        Name = "Location"
                    }
                }

                $TermGroups = @{
                    People = @{
                        Name     = "People"
                        TermSets = $TermSets
                    }
                }

                $TermStoresList = @{
                    "Managed Metadata service" = @{
                        Name   = "Managed Metadata service"
                        Groups = $TermGroups
                    }
                }


                Mock -CommandName New-Object -MockWith {
                    return (@{
                            TermStores = $TermStoresList
                        })
                } -ParameterFilter {
                    $TypeName -eq "Microsoft.SharePoint.Taxonomy.TaxonomySession" }

                Mock -CommandName New-Object -MockWith {
                    return (@{
                            Properties = @{

                            } | Add-Member ScriptMethod SetDisplayOrderByPropertyName {
                                $Global:UpsSetDisplayOrderByPropertyNameCalled = $true
                                return $false
                            } -PassThru | Add-Member ScriptMethod CommitDisplayOrder {
                                $Global:UpsSetDisplayOrderByPropertyNameCalled = $true
                                return $false
                            } -PassThru
                        })
                } -ParameterFilter {
                    $TypeName -eq "Microsoft.Office.Server.UserProfiles.UserProfileManager" }
                Mock Invoke-SPDscCommand {
                    return Invoke-Command -Scriptblock $ScriptBlock -ArgumentList $Arguments -NoNewScope
                }

                $propertyMappingItem = @{
                    DataSourcePropertyName = "mail"
                    IsImport               = $true
                    IsExport               = $false
                } | Add-Member ScriptMethod Delete {
                    $Global:UpsMappingDeleteCalled = $true
                    return $true
                } -PassThru

                $propertyMapping = @{ } | Add-Member ScriptMethod Item {
                    param(
                        [string]
                        $property
                    )
                    $Global:SPUPSMappingItemCalled = $true
                    if ($property -eq "WorkEmailUpdate")
                    {
                        return $propertyMappingItem
                    }
                } -PassThru -Force | Add-Member ScriptMethod AddNewExportMapping {
                    $Global:UpsMappingAddNewExportCalled = $true
                    return $true
                } -PassThru -Force | Add-Member ScriptMethod AddNewMapping {
                    $Global:UpsMappingAddNewMappingCalled = $true
                    return $true
                } -PassThru -Force

                $connection = @{
                    DisplayName     = "Contoso"
                    Server          = "contoso.com"
                    AccountDomain   = "Contoso"
                    AccountUsername = "TestAccount"
                    Type            = "ActiveDirectory"
                    PropertyMapping = $propertyMapping
                }

                $connection = $connection | Add-Member ScriptMethod Update {
                    $Global:SPUPSSyncConnectionUpdateCalled = $true
                } -PassThru | Add-Member ScriptMethod AddPropertyMapping {
                    $Global:SPUPSSyncConnectionAddPropertyMappingCalled = $true
                } -PassThru

                $ConnnectionManager = @{
                    $($connection.DisplayName) = @($connection) | Add-Member ScriptMethod  AddActiveDirectoryConnection {
                        param(
                            [Microsoft.Office.Server.UserProfiles.ConnectionType]
                            $connectionType,
                            $name,
                            $forest,
                            $useSSL,
                            $userName,
                            $pwd,
                            $namingContext,
                            $p1,
                            $p2
                        )
                        $Global:SPUPSAddActiveDirectoryConnectionCalled = $true
                    } -PassThru
                }

                Mock -CommandName New-Object -MockWith {
                    $ProfilePropertyManager = @{
                        "Contoso" = $connection
                    } | Add-Member ScriptMethod GetCoreProperties {
                        $Global:UpsConfigManagerGetCorePropertiesCalled = $true
                        return ($coreProperties)
                    } -PassThru | Add-Member ScriptMethod GetProfileTypeProperties {
                        $Global:UpsConfigManagerGetProfileTypePropertiesCalled = $true
                        return $userProfileSubTypePropertiesUpdateProperty
                    } -PassThru
                    return (
                        @{
                            ProfilePropertyManager = $ProfilePropertyManager
                            ConnectionManager      = $ConnnectionManager
                        } | Add-Member ScriptMethod IsSynchronizationRunning {
                            $Global:UpsSyncIsSynchronizationRunning = $true
                            return $false
                        } -PassThru | Add-Member ScriptMethod GetPropertiesWithSection {
                            return @(
                                @{
                                    IsSection = $false
                                    Name      = 'DemoProperty'
                                }
                            )
                        } -PassThru  )
                } -ParameterFilter {
                    $TypeName -eq "Microsoft.Office.Server.UserProfiles.UserProfileConfigManager" }

                $userProfileServiceValidConnection = @{
                    Name                         = "User Profile Service Application"
                    TypeName                     = "User Profile Service Application"
                    ApplicationPool              = "SharePoint Service Applications"
                    ServiceApplicationProxyGroup = "Proxy Group"
                    ConnectionManager            = @($connection)
                }

                Mock -CommandName Get-SPServiceApplication { return $userProfileServiceValidConnection }

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

            Context -Name "Non-Existing User Profile Service Application" {
                BeforeAll {
                    Mock -CommandName Get-SPServiceApplication { return $null }
                }

                It "Should return Ensure = Absent" {
                    $Global:SPUPGetProfileSubtypeCalled = $false
                    $Global:SPUPGetPropertyByNameCalled = $false
                    $Global:SPUPSMappingItemCalled = $false
                    (Get-TargetResource @testParamsNewProperty).Ensure | Should -Be "Absent"
                }
            }

            Context -Name "When property doesn't exist" {
                It "Should return null from the Get method" {
                    $Global:SPUPGetProfileSubtypeCalled = $false
                    $Global:SPUPGetPropertyByNameCalled = $false
                    $Global:SPUPSMappingItemCalled = $false
                    (Get-TargetResource @testParamsNewProperty).Ensure | Should -Be "Absent"
                    Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParamsNewProperty.UserProfileService }
                    $Global:SPUPGetProfileSubtypeCalled | Should -Be $true
                    $Global:SPUPGetPropertyByNameCalled | Should -Be $true
                    $Global:SPUPSMappingItemCalled | Should -Be $false
                }

                It "Should return false when the Test method is called" {
                    $Global:SPUPGetPropertyByNameCalled = $false
                    Test-TargetResource @testParamsNewProperty | Should -Be $false
                    $Global:SPUPGetPropertyByNameCalled | Should -Be $true
                }

                It "creates a new user profile property in the set method" {
                    $Global:SPUPGetProfileSubtypeCalled = $false

                    $Global:SPUPSMappingItemCalled = $false
                    Set-TargetResource @testParamsNewProperty
                    $Global:SPUPGetProfileSubtypeCalled | Should -Be $true

                    $Global:SPUPSMappingItemCalled | Should -Be $true
                }
            }

            Context -Name "When property doesn't exist, connection doesn't exist" {
                BeforeAll {
                    Mock -CommandName New-Object -MockWith {
                        $ProfilePropertyManager = @{"Contoso" = $connection } | Add-Member ScriptMethod GetCoreProperties {
                            $Global:UpsConfigManagerGetCorePropertiesCalled = $true
                            return ($coreProperties)
                        } -PassThru | Add-Member ScriptMethod GetProfileTypeProperties {
                            $Global:UpsConfigManagerGetProfileTypePropertiesCalled = $true
                            return $userProfileSubTypePropertiesUpdateProperty
                        } -PassThru
                        return (@{
                                ProfilePropertyManager = $ProfilePropertyManager
                                ConnectionManager      = @{ }
                            } | Add-Member ScriptMethod IsSynchronizationRunning {
                                $Global:UpsSyncIsSynchronizationRunning = $true
                                return $false
                            } -PassThru   )
                    } -ParameterFilter { $TypeName -eq "Microsoft.Office.Server.UserProfiles.UserProfileConfigManager" }
                }

                It "Should return null from the Get method" {
                    $Global:SPUPGetProfileSubtypeCalled = $false
                    $Global:SPUPGetPropertyByNameCalled = $false
                    $Global:SPUPSMappingItemCalled = $false
                    (Get-TargetResource @testParamsNewProperty).Ensure | Should -Be "Absent"
                    Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParamsNewProperty.UserProfileService }
                    $Global:SPUPGetProfileSubtypeCalled | Should -Be $true
                    $Global:SPUPGetPropertyByNameCalled | Should -Be $true
                    $Global:SPUPSMappingItemCalled | Should -Be $false
                }

                It "Should return false when the Test method is called" {
                    $Global:SPUPGetPropertyByNameCalled = $false
                    Test-TargetResource @testParamsNewProperty | Should -Be $false
                    $Global:SPUPGetPropertyByNameCalled | Should -Be $true
                }

                It "attempts to create a new property but fails as connection isn't available" {
                    $Global:SPUPGetProfileSubtypeCalled = $false
                    $Global:SPUPGetPropertyByNameCalled = $false
                    $Global:SPUPSMappingItemCalled = $false

                    { Set-TargetResource @testParamsNewProperty } | Should -Throw "connection not found"

                    $Global:SPUPGetProfileSubtypeCalled | Should -Be $true
                    $Global:SPUPGetPropertyByNameCalled | Should -Be $true
                    $Global:SPUPSMappingItemCalled | Should -Be $false

                }
            }

            Context -Name "When property doesn't exist, term set doesn't exist" {
                BeforeAll {
                    $termSet = $testParamsNewProperty.TermSet
                    $testParamsNewProperty.TermSet = "Invalid"
                }

                It "Should return null from the Get method" {
                    $Global:SPUPGetPropertyByNameCalled = $false
                    $Global:SPUPGetPropertyByNameCalled = $false
                    $Global:SPUPSMappingItemCalled = $false
                    (Get-TargetResource @testParamsNewProperty).Ensure | Should -Be "Absent"
                    Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParamsNewProperty.UserProfileService }
                    $Global:SPUPGetProfileSubtypeCalled | Should -Be $true
                    $Global:SPUPGetPropertyByNameCalled | Should -Be $true
                    $Global:SPUPSMappingItemCalled | Should -Be $false
                }

                It "Should return false when the Test method is called" {
                    $Global:SPUPGetPropertyByNameCalled = $false
                    Test-TargetResource @testParamsNewProperty | Should -Be $false
                    $Global:SPUPGetPropertyByNameCalled | Should -Be $true
                }

                It "creates a new user profile property in the set method" {
                    $Global:SPUPGetProfileSubtypeCalled = $false
                    $Global:SPUPSMappingItemCalled = $false

                    { Set-TargetResource @testParamsNewProperty } | Should -Throw "Term Set $($testParamsNewProperty.TermSet) not found"

                    $Global:SPUPGetProfileSubtypeCalled | Should -Be $true
                    $Global:SPUPSMappingItemCalled | Should -Be $false

                }

                AfterAll {
                    $testParamsNewProperty.TermSet = $termSet
                }
            }

            Context -Name "When required values are not all passed" {
                BeforeAll {
                    $testParamsNewProperty.TermGroup = $null
                }

                It "Should throw error from Set method" {
                    { Set-TargetResource @testParamsNewProperty } | Should -Throw "Term Group  not found"
                }
            }

            Context -Name "When ConfigurationManager is null" {
                BeforeAll {
                    Mock -CommandName New-Object -MockWith {
                        $ProfilePropertyManager = @{"Contoso" = $connection } | Add-Member ScriptMethod GetCoreProperties {
                            $Global:UpsConfigManagerGetCorePropertiesCalled = $true
                            return ($coreProperties)
                        } -PassThru | Add-Member ScriptMethod GetProfileTypeProperties {
                            $Global:UpsConfigManagerGetProfileTypePropertiesCalled = $true
                            return $userProfileSubTypePropertiesUpdateProperty
                        } -PassThru
                        return (
                            @{
                                ProfilePropertyManager = $ProfilePropertyManager
                                ConnectionManager      = $null
                            } | Add-Member ScriptMethod IsSynchronizationRunning {
                                $Global:UpsSyncIsSynchronizationRunning = $true
                                return $false
                            } -PassThru
                        )
                    } -ParameterFilter { $TypeName -eq "Microsoft.Office.Server.UserProfiles.UserProfileConfigManager" }
                }

                It "Should return Ensure = Absent from the Get method" {
                    (Get-TargetResource @testParamsNewProperty).Ensure | Should -Be "Absent"
                }
            }

            Context -Name "When Sync Connection is set to Export" {
                BeforeAll {
                    Mock -CommandName New-Object -MockWith {
                        $ProfilePropertyManager = @{"Contoso" = $connection } | Add-Member ScriptMethod GetCoreProperties {
                            $Global:UpsConfigManagerGetCorePropertiesCalled = $true
                            return ($coreProperties)
                        } -PassThru | Add-Member ScriptMethod GetProfileTypeProperties {
                            $Global:UpsConfigManagerGetProfileTypePropertiesCalled = $true
                            return $userProfileSubTypePropertiesUpdateProperty
                        } -PassThru
                        return (@{
                                ProfilePropertyManager = $ProfilePropertyManager
                                ConnectionManager      = $null
                            } | Add-Member ScriptMethod IsSynchronizationRunning {
                                $Global:UpsSyncIsSynchronizationRunning = $true
                                return $false
                            } -PassThru   )
                    } -ParameterFilter { $TypeName -eq "Microsoft.Office.Server.UserProfiles.UserProfileConfigManager" }
                }

                It "Should return Ensure = Absent from the Get method" {
                    (Get-TargetResource @testParamsNewProperty).Ensure | Should -Be "Absent"
                }
            }

            Context -Name "When property doesn't exist, term group doesn't exist" {
                BeforeAll {
                    $termGroup = $testParamsNewProperty.TermGroup
                    $testParamsNewProperty.TermGroup = "InvalidGroup"
                }

                It "Should return null from the Get method" {
                    $Global:SPUPGetPropertyByNameCalled = $false
                    $Global:SPUPGetPropertyByNameCalled = $false
                    $Global:SPUPSMappingItemCalled = $false
                    (Get-TargetResource @testParamsNewProperty).Ensure | Should -Be "Absent"
                    Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParamsNewProperty.UserProfileService }
                    $Global:SPUPGetProfileSubtypeCalled | Should -Be $true
                    $Global:SPUPGetPropertyByNameCalled | Should -Be $true
                    $Global:SPUPSMappingItemCalled | Should -Be $false
                }

                It "Should return false when the Test method is called" {
                    $Global:SPUPGetPropertyByNameCalled = $false
                    Test-TargetResource @testParamsNewProperty | Should -Be $false
                    $Global:SPUPGetPropertyByNameCalled | Should -Be $true
                }

                It "creates a new user profile property in the set method" {
                    $Global:SPUPGetProfileSubtypeCalled = $false
                    $Global:SPUPSMappingItemCalled = $false

                    { Set-TargetResource @testParamsNewProperty } | Should -Throw "Term Group $($testParamsNewProperty.TermGroup) not found"

                    $Global:SPUPGetProfileSubtypeCalled | Should -Be $true
                    $Global:SPUPSMappingItemCalled | Should -Be $false

                }

                AfterAll {
                    $testParamsNewProperty.TermGroup = $termGroup
                }
            }

            Context -Name "When property doesn't exist, term store doesn't exist" {
                BeforeAll {
                    $termStore = $testParamsNewProperty.TermStore
                    $testParamsNewProperty.TermStore = "InvalidStore"
                }

                It "Should return null from the Get method" {
                    $Global:SPUPGetPropertyByNameCalled = $false
                    $Global:SPUPGetPropertyByNameCalled = $false
                    $Global:SPUPSMappingItemCalled = $false
                    (Get-TargetResource @testParamsNewProperty).Ensure | Should -Be "Absent"
                    Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParamsNewProperty.UserProfileService }
                    $Global:SPUPGetProfileSubtypeCalled | Should -Be $true
                    $Global:SPUPGetPropertyByNameCalled | Should -Be $true
                    $Global:SPUPSMappingItemCalled | Should -Be $false
                }

                It "Should return false when the Test method is called" {
                    $Global:SPUPGetPropertyByNameCalled = $false
                    Test-TargetResource @testParamsNewProperty | Should -Be $false
                    $Global:SPUPGetPropertyByNameCalled | Should -Be $true
                }

                It "creates a new user profile property in the set method" {
                    $Global:SPUPGetProfileSubtypeCalled = $false
                    $Global:SPUPSMappingItemCalled = $false

                    { Set-TargetResource @testParamsNewProperty } | Should -Throw "Term Store $($testParamsNewProperty.TermStore) not found"

                    $Global:SPUPGetProfileSubtypeCalled | Should -Be $true
                    $Global:SPUPSMappingItemCalled | Should -Be $false
                }

                AfterAll {
                    $testParamsNewProperty.TermStore = $termStore
                }
            }

            Context -Name "When property exists and all properties match" {
                BeforeAll {
                    Mock -CommandName Get-SPDscUserProfileSubTypeManager -MockWith {
                        $result = @{ } | Add-Member ScriptMethod GetProfileSubtype {
                            $Global:SPUPGetProfileSubtypeCalled = $true
                            return @{
                                Properties = $userProfileSubTypePropertiesUpdateProperty
                            }
                        } -PassThru

                        return $result
                    }
                }

                It "Should return valid value from the Get method" {
                    $Global:SPUPGetProfileSubtypeCalled = $false
                    $Global:SPUPGetPropertyByNameCalled = $false
                    $Global:SPUPSMappingItemCalled = $false
                    (Get-TargetResource @testParamsNewProperty).Ensure | Should -Be "Present"
                    Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParamsUpdateProperty.UserProfileService }
                    $Global:SPUPGetProfileSubtypeCalled | Should -Be $true
                    $Global:SPUPGetPropertyByNameCalled | Should -Be $true
                    $Global:SPUPSMappingItemCalled | Should -Be $true
                }

                It "Should return false when the Test method is called" {
                    $Global:SPUPGetPropertyByNameCalled = $false
                    Test-TargetResource @testParamsUpdateProperty | Should -Be $false
                    $Global:SPUPGetPropertyByNameCalled | Should -Be $true
                }

                It "updates an user profile property in the set method" {
                    $Global:SPUPGetProfileSubtypeCalled = $false
                    $Global:SPUPSMappingItemCalled = $false
                    Set-TargetResource @testParamsUpdateProperty
                    $Global:SPUPGetProfileSubtypeCalled | Should -Be $true
                    $Global:SPUPSMappingItemCalled | Should -Be $true
                }

                It "Should throw an error if the MappingDirection is set to Export" {
                    $testParamsExport = $testParamsUpdateProperty
                    $connection.Type = "ActiveDirectoryImport"
                    $testParamsExport.PropertyMappings[0].Direction = "Export"
                    $propertyMappingItem.IsImport = $true

                    { Set-TargetResource @testParamsExport } | Should -Throw "not implemented"
                    $connection.Type = "ActiveDirectory"
                }
            }

            Context -Name "When property exists and type is different - throws exception" {
                BeforeAll {
                    $currentType = $testParamsUpdateProperty.Type
                    $testParamsUpdateProperty.Type = "String (Multi Value)"
                    Mock -CommandName Get-SPDscUserProfileSubTypeManager -MockWith {
                        $result = @{ } | Add-Member ScriptMethod GetProfileSubtype {
                            $Global:SPUPGetProfileSubtypeCalled = $true
                            return @{
                                Properties = $userProfileSubTypePropertiesUpdateProperty
                            }
                        } -PassThru

                        return $result
                    }
                }

                It "Should return valid value from the Get method" {
                    $Global:SPUPGetProfileSubtypeCalled = $false
                    $Global:SPUPGetPropertyByNameCalled = $false
                    $Global:SPUPSMappingItemCalled = $false
                    (Get-TargetResource @testParamsNewProperty).Ensure | Should -Be "Present"
                    Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParamsUpdateProperty.UserProfileService }
                    $Global:SPUPGetProfileSubtypeCalled | Should -Be $true
                    $Global:SPUPGetPropertyByNameCalled | Should -Be $true
                    $Global:SPUPSMappingItemCalled | Should -Be $true
                }

                It "Should return false when the Test method is called" {
                    $Global:SPUPGetPropertyByNameCalled = $false
                    Test-TargetResource @testParamsUpdateProperty | Should -Be $false
                    $Global:SPUPGetPropertyByNameCalled | Should -Be $true
                }

                It "attempts to update an user profile property in the set method" {
                    $Global:SPUPGetProfileSubtypeCalled = $false
                    $Global:SPUPGetPropertyByNameCalled = $false
                    $Global:SPUPSMappingItemCalled = $false

                    { Set-TargetResource @testParamsUpdateProperty } | Should -Throw "Can't change property type. Current Type"

                    $Global:SPUPGetProfileSubtypeCalled | Should -Be $true
                    $Global:SPUPGetPropertyByNameCalled | Should -Be $true
                    $Global:SPUPSMappingItemCalled | Should -Be $false
                }

                AfterAll {
                    $testParamsUpdateProperty.Type = $currentType
                }
            }

            Context -Name "When property exists and mapping exists, mapping config does not match" {
                BeforeAll {
                    #$propertyMappingItem.DataSourcePropertyName = "property"
                    Mock -CommandName Get-SPDscUserProfileSubTypeManager -MockWith {
                        $result = @{ } | Add-Member ScriptMethod GetProfileSubtype {
                            $Global:SPUPGetProfileSubtypeCalled = $true
                            return @{
                                Properties = $userProfileSubTypePropertiesUpdateProperty
                            }
                        } -PassThru

                        return $result
                    }
                }

                It "Should return valid value from the Get method" {
                    $Global:SPUPGetProfileSubtypeCalled = $false
                    $Global:SPUPGetPropertyByNameCalled = $false
                    $Global:SPUPSMappingItemCalled = $false
                    (Get-TargetResource @testParamsNewProperty).Ensure | Should -Be "Present"
                    Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParamsUpdateProperty.UserProfileService }
                    $Global:SPUPGetProfileSubtypeCalled | Should -Be $true
                    $Global:SPUPGetPropertyByNameCalled | Should -Be $true
                    $Global:SPUPSMappingItemCalled | Should -Be $true
                }

                It "Should return false when the Test method is called" {
                    $Global:SPUPGetPropertyByNameCalled = $false
                    Test-TargetResource @testParamsUpdateProperty | Should -Be $false
                    $Global:SPUPGetPropertyByNameCalled | Should -Be $true
                }

                It "updates an user profile property in the set method" {
                    $Global:SPUPGetProfileSubtypeCalled = $false
                    $Global:SPUPGetPropertyByNameCalled = $false
                    $Global:SPUPSMappingItemCalled = $false

                    Set-TargetResource @testParamsUpdateProperty

                    $Global:SPUPGetProfileSubtypeCalled | Should -Be $true
                    $Global:SPUPGetPropertyByNameCalled | Should -Be $true
                    $Global:SPUPSMappingItemCalled | Should -Be $true
                }
            }

            Context -Name "When property exists and mapping does not exist" {
                BeforeAll {
                    $propertyMappingItem = $null
                    Mock -CommandName Get-SPDscUserProfileSubTypeManager -MockWith {
                        $result = @{ } | Add-Member ScriptMethod GetProfileSubtype {
                            $Global:SPUPGetProfileSubtypeCalled = $true
                            return @{
                                Properties = $userProfileSubTypePropertiesUpdateProperty
                            }
                        } -PassThru

                        return $result
                    }
                }

                It "Should return valid value from the Get method" {
                    $Global:SPUPGetProfileSubtypeCalled = $false
                    $Global:SPUPGetPropertyByNameCalled = $false
                    $Global:SPUPSMappingItemCalled = $false
                    (Get-TargetResource @testParamsNewProperty).Ensure | Should -Be "Present"
                    Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParamsUpdateProperty.UserProfileService }
                    $Global:SPUPGetProfileSubtypeCalled | Should -Be $true
                    $Global:SPUPGetPropertyByNameCalled | Should -Be $true
                    $Global:SPUPSMappingItemCalled | Should -Be $true
                }

                It "Should return false when the Test method is called" {
                    $Global:SPUPGetPropertyByNameCalled = $false
                    Test-TargetResource @testParamsUpdateProperty | Should -Be $false
                    $Global:SPUPGetPropertyByNameCalled | Should -Be $true
                }

                It "updates an user profile property in the set method" {
                    $Global:SPUPGetProfileSubtypeCalled = $false
                    $Global:SPUPGetPropertyByNameCalled = $false
                    $Global:SPUPSMappingItemCalled = $false

                    Set-TargetResource @testParamsUpdateProperty

                    $Global:SPUPGetProfileSubtypeCalled | Should -Be $true
                    $Global:SPUPGetPropertyByNameCalled | Should -Be $true
                    $Global:SPUPSMappingItemCalled | Should -Be $true
                }
            }

            Context -Name "When property exists and ensure equals Absent" {
                BeforeAll {
                    Mock -CommandName Get-SPDscUserProfileSubTypeManager -MockWith {
                        $result = @{ } | Add-Member ScriptMethod GetProfileSubtype {
                            $Global:SPUPGetProfileSubtypeCalled = $true
                            return @{
                                Properties = $userProfileSubTypePropertiesUpdateProperty
                            }
                        } -PassThru

                        return $result
                    }

                    $testParamsUpdateProperty.Ensure = "Absent"
                }

                It "deletes an user profile property in the set method" {
                    $Global:SPUPGetProfileSubtypeCalled = $false
                    $Global:SPUPGetPropertyByNameCalled = $false
                    $Global:SPUPSMappingItemCalled = $false
                    $Global:SPUPCoreRemovePropertyByNameCalled = $false

                    Set-TargetResource @testParamsUpdateProperty

                    $Global:SPUPGetProfileSubtypeCalled | Should -Be $true
                    $Global:SPUPGetPropertyByNameCalled | Should -Be $true
                    $Global:SPUPSMappingItemCalled | Should -Be $false
                    $Global:SPUPCoreRemovePropertyByNameCalled | Should -Be $true
                }
            }

            Context -Name "When a AD Import Connection should be configured" {
                BeforeAll {
                    # Mocks for AD Import Connection
                    Mock -CommandName Get-SPDscUserProfileSubTypeManager -MockWith {
                        $result = @{ } | Add-Member ScriptMethod GetProfileSubtype {
                            $Global:SPUPGetProfileSubtypeCalled = $true
                            return @{
                                Properties = $userProfileSubTypePropertiesUpdateProperty
                            }
                        } -PassThru

                        return $result
                    }

                    $propertyMapping = ([PSCustomObject]@{ }) | Add-Member ScriptMethod Item {
                        param(
                            [string]
                            $property
                        )
                        $Global:SPUPSMappingItemCalled = $true
                    } -PassThru -Force | Add-Member ScriptMethod AddNewExportMapping {
                        $Global:UpsMappingAddNewExportCalled = $true
                        return $true
                    } -PassThru -Force | Add-Member ScriptMethod AddNewMapping {
                        $Global:UpsMappingAddNewMappingCalled = $true
                        return $true
                    } -PassThru -Force

                    $connection = [PSCustomObject]@{
                        DisplayName        = "Contoso"
                        IsDirectorySerivce = $true
                        Type               = "ActiveDirectoryImport"
                        PropertyMapping    = $propertyMapping
                    } | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                        return @{
                            FullName = "Microsoft.Office.Server.UserProfiles.ActiveDirectoryImportConnection"
                        } | Add-Member -MemberType ScriptMethod -Name GetMethods -Value {
                            return @{
                                Name = "ADImportPropertyMappings"
                            } | Add-Member -MemberType ScriptMethod -Name Invoke -Value {
                                return @(
                                    (([PSCustomObject]"Microsoft.Office.Server.UserProfiles.ADImport.UserProfileADImportPropertyMapping") `
                                        | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                                            return @{
                                                FullName = ""
                                            } | Add-Member -MemberType ScriptMethod -Name GetMembers -Value {
                                                return @(
                                                    (@{
                                                            MemberType = "Property"
                                                            Name       = "ProfileProperty"
                                                        } | Add-Member -MemberType ScriptMethod -Name GetValue -Value {
                                                            return "WorkEmailUpdate"
                                                        } -PassThru -Force),
                                                    (@{
                                                            MemberType = "Property"
                                                            Name       = "ADAttribute"
                                                        } | Add-Member -MemberType ScriptMethod -Name GetValue -Value {
                                                            return "department"
                                                        } -PassThru -Force)
                                                )
                                            } -PassThru -Force
                                        } -PassThru -Force
                                    ),
                                    (([PSCustomObject]"Microsoft.Office.Server.UserProfiles.ADImport.UserProfileADImportPropertyMapping") `
                                        | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                                            return @{
                                                FullName = ""
                                            } | Add-Member -MemberType ScriptMethod -Name GetMembers -Value {
                                                return @()
                                            } -PassThru -Force
                                        } -PassThru -Force
                                    )
                                )
                            } -PassThru -Force
                        } -PassThru -Force
                    } -PassThru -Force

                    $ConnnectionManager = @{
                        $($connection.DisplayName) = $connection
                        PropertyMapping            = "Fake"
                    }
                    Mock -CommandName New-Object -MockWith {
                        $ProfilePropertyManager = @{
                            "Contoso" = $connection
                        } | Add-Member ScriptMethod GetCoreProperties {
                            $Global:UpsConfigManagerGetCorePropertiesCalled = $true
                            return ($coreProperties)
                        } -PassThru | Add-Member ScriptMethod GetProfileTypeProperties {
                            $Global:UpsConfigManagerGetProfileTypePropertiesCalled = $true
                            return $userProfileSubTypePropertiesUpdateProperty
                        } -PassThru
                        return (@{
                                ProfilePropertyManager = $ProfilePropertyManager
                                ConnectionManager      = $ConnnectionManager
                            } | Add-Member ScriptMethod IsSynchronizationRunning {
                                $Global:UpsSyncIsSynchronizationRunning = $true
                                return $false
                            } -PassThru   )
                    } -ParameterFilter {
                        $TypeName -eq "Microsoft.Office.Server.UserProfiles.UserProfileConfigManager" }
                }

                It "Should return true when the Test method is called" {
                    $testParamsUpdateProperty.Ensure = "Present"
                    $testParamsUpdateProperty.PropertyMappings[0].Direction = "Import"
                    $testresults = Test-TargetResource @testParamsUpdateProperty
                    $testresults | Should -Be $true
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")

                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Name                = "WorkEmail2"
                            Ensure              = "Present"
                            UserProfileService  = "User Profile Service Application"
                            DisplayName         = "Work Email"
                            Type                = "Email"
                            Description         = ""
                            PolicySetting       = "Mandatory"
                            PrivacySetting      = "Public"
                            PropertyMappings    = @(
                                @{
                                    ConnectionName = "contoso.com"
                                    PropertyName   = "mail"
                                    Direction      = "Import"
                                }
                            )
                            Length              = 10
                            DisplayOrder        = 25
                            IsEventLog          = $false
                            IsVisibleOnEditor   = $true
                            IsVisibleOnViewer   = $true
                            IsUserEditable      = $true
                            IsAlias             = $false
                            IsSearchable        = $false
                            IsReplicable        = $false
                            TermStore           = ""
                            TermGroup           = ""
                            TermSet             = ""
                            UserOverridePrivacy = $false
                        }
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            DisplayName = "User Profile Service Application"
                            Name        = "User Profile Service Application"
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return @{
                                Name = "UserProfileApplication"
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
        SPUserProfileProperty [0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            Description          = "";
            DisplayName          = "Work Email";
            DisplayOrder         = 25;
            Ensure               = "Present";
            IsAlias              = \$False;
            IsEventLog           = \$False;
            IsReplicable         = \$False;
            IsSearchable         = \$False;
            IsUserEditable       = \$True;
            IsVisibleOnEditor    = \$True;
            IsVisibleOnViewer    = \$True;
            Length               = 10;
            Name                 = "WorkEmail2";
            PolicySetting        = "Mandatory";
            PrivacySetting       = "Public";
            PropertyMappings     = \@\(System.Collections.Hashtable\);
            PsDscRunAsCredential = \$Credsspfarm;
            Type                 = "Email";
            UserOverridePrivacy  = \$False;
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
