# Changelog for SharePointDsc

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [vNext]

### Added (v5.0)

- SPInstallPrereqs
  - Added support for SharePoint vNext

## [Unreleased]

### Added

- SPLogLevel
  - Added ReverseDsc export support to this resource
- SPWebApplication
  - Added logic to check if specified content database exists in the web
    application
  - Added possibility to update application pool

### Changed

- SharePointDsc
  - Updated build pipeline to use the correct vm image

### Fixed

- SharePointDsc
  - Fixed issue where the snapin was generating the "An item with the same
    key has already been added" error
- ReverseDsc
  - Fixed issue where the export would contain duplicate configuration
  - Fixed issue where the example export cmdlets was in the incorrect format
- SPDocIcon
  - Fixed issue where the resource was using hardcoded SP2016 and later paths
    and therefore didn't work in SP2013
- SPSearchServiceApp
  - Disabled Farm account DB ownership updating functions when using SQL Auth
- SPServiceAppPool
  - Fixed issue in Export method where the PsDscRunAsCredential was stored as
    a string instead of a PsCredential object
- SPSite
  - Fixed issue where the code continues when the creation of the site failed,
    throwing even more errors

## [4.8.0] - 2021-08-31

### Added

- SPSearchServiceApp
  - Added additional logging at checking db permissions
- SPWebAppHttpThrottlingMonitor
  - Added new resource to manage web application Http Throttling Monitor settings

### Changed

- SPFarm
  - Added parameter SkipRegisterAsDistributedCacheHost
- SPSearchServiceApp
  - Fixed an issue if the analytics database where not provisioned with a
    hardcoded name
  - Fixed an issue if search databases had names containing one or more spaces
- SPWebAppAuthentication
  - Updated the description for the new zone setting parameters
- SPWebAppClientCallableSettings
  - Updated the description for the proxy library settings parameters

### Fixed

- SPAppDomain
  - Corrected Verbose logging in Test method
  - Corrected issue in Get method where ErrorAction had to be SilentlyContinue
- SPContentDatabase
  - Fixed issue where WebAppUrl in the Desired State would cause the test to fail, always resulting
    in False.
- SPExcelServiceApp
  - Updated links to Docs instead of old TechNet
- SPInstallLanguagePack
  - Fixed detection of Norwegian language pack
- SPManagedMetaDataServiceApp
  - Fix issue where a missing Service App Proxy was not detected correctly and therefore not
    created, resulting in other errors.
- SPSearchTopology
  - Fixed issue where an error was thrown if the specified RootDirectory didn't exist on the
    current server but did exist on the target server. 
  - Fixed issue with using FQDNs instead of NetBIOS server names.
- SPSite
  - Implemented workaround to prevent issue with creating site collections immediately after
    farm creation (Error "Invalid field name. {cbb92da4-fd46-4c7d-af6c-3128c2a5576e}")
- SPTrustedIdentityTokenIssuer
  - Fixed issue where the IdentifierClaim was not properly detected in the Set method
- SPWorkManagementServiceApp
  - Updated links to Docs instead of old TechNet

## [4.7.0] - 2021-06-10

### Added

- SPSearchServiceApp
  - Added ability to correct database permissions for the farm account, to prevent issue
    as described in the Readme of the resource
- SPSecurityTokenServiceConfig
  - Added support for LogonTokenCacheExpirationWindow, WindowsTokenLifetime and FormsTokenLifetime settings
- SPService
  - New resource
 - SPSecurityTokenServiceConfig
  - Added support for LogonTokenCacheExpirationWindow, WindowsTokenLifetime and FormsTokenLifetime settings
- SPUsageDefinition
  - New resource
- SPUserProfileProperty
  - Added check for unique ConnectionNames in PropertyMappings, which is required by SharePoint
- SPWebAppAuthentication
  - Added ability to configure generic authentication settings per zone, like allow
    anonymous authentication or a custom signin page

### Fixed

- SharePointDsc
  - Fixed code coverage in pipeline
- SPConfigWizard
  - Fixed issue with executing PSCONFIG remotely.
- SPFarm
  - Fixed issue where developer dashboard could not be configured on first farm setup.
  - Fixed issue with PSConfig in SharePoint 2019 when executed remotely
  - Corrected issue where the setup account didn't have permissions to create the Lock
    table in the TempDB. Updated to use a global temporary table, which users are always
    allowed to create

## [4.6.0] - 2021-04-02

### Added

- SharePointDsc
  - Export-SPDscDiagnosticData cmdlet to create a diagnostic package which can
    easily be shared for troubleshooting
- ReverseDsc
  - Added a check in Export-SPConfiguration/Start-SharePointDSCExtract to check if
    ReverseDsc is present or not. Show instructions if it isn't
  - Added DocIcon to export GUI
  - Renamed export cmdlet to Export-SPConfiguration, to match Microsoft365DSC naming.
    Added old Start-SharePointDSCExtract as alias

### Changed

- SPFarmAdministrators
  - Added check to see if a central admin site is returned and stop if it isn't
- SPManagedMetaDataServiceApp
  - Added check to see if a central admin site is returned and stop if it isn't
- SPSite
  - Added check to see if a central admin site is returned and stop if it isn't
- ReverseDsc
  - Made the export GUI logic more dynamic

### Fixed

- SPAccessServiceApp, SPAccessServices2010, SPAppManagementServiceApp, SPBCSServiceApp,
  SPExcelServiceApp, SPMachineTranslationServiceApp, SPManagedMetadataServiceApp,
  SPPerformancePointServiceApp, SPPowerPointAutomationServiceApp, SPProjectServerServiceApp,
  SPPublishServiceApplication, SPSearchCrawlRule, SPSearchFileType, SPSearchServiceApp,
  SPSecureStoreServiceApp, SPServiceAppSecurity, SPSubscriptionSettingsServiceApp,
  SPUsageApplication, SPUserProfileProperty, SPUserProfileSection, SPUserProfileServiceApp,
  SPUserProfileSyncConnection, SPUserProfileSyncService, SPVisioServiceApp,
  SPWordAutomationServiceApp, SPWorkManagementServiceApp
  - Fixed issue with the Name parameter of Get-SPServiceApplication, which is case
    sensitive
- SPExcelServiceApp
  - Fixed issue where PSBoundParameters was used multiple times, but manipulated at an early
    stage, breaking all subsequent usages
- SPInstallLanguagePack
  - Fixed issue in the Norwegian Language Pack detection
- SPSearchManagedProperty
  - Fixed issue where setting Searchable=True resulted in an error
- SPSearchResultSource
  - Clarified the use of ScopeName and ScopeUrl with SSA as ScopeName and added examples
- SPUserProfileServiceApp
  - Fixed issue where MySiteHostLocation was return from Get method including port number,
    which causes the Test method to fail
- SPWebAppAuthentication
  - Fix issue in Get method to return Null when zone does not exist. That way the Test and
    Set method can detect a non-existent zone and throw a proper error.
- SPWordAutomation
  - Fixed issue where the resource never went into desired state when using AddToDefault

### Removed

- SharePointDsc
  - Removed the ReverseDsc dependency for the SharePointDsc module since the module
    is only required when performing an export

## [4.5.1] - 2021-02-05

### Fixed

- SharePointDsc
  - Fixed regression in v4.5

## [4.5.0] - 2021-01-30

### Added

- SharePointDsc
  - Added native support for ReverseDsc
- SPDocIcon
  - New resource
- SPUserProfileSyncConnection
  - Added ability to update UseSSL and UseDisabledFilter parameters
- SPWordAutomationServiceApp
  - Added ability to specify that the new service app should be added
    to the default proxy group

### Changed

- SharePointDsc
  - Updated pipeline build scripts
- SPProjectServerConnector
  - Updated logic to check to required DLL file
- SPFarmAdministrators
  - Update the event log messages so they are better formatted
- SPQuotaTemplate
  - Updated resource to prevent errors when specified limits are conflicting
    configured values. E.g. new warning is high than the current max limit.
- SPTrustedIdentityTokenIssuer
  - Do not set property ProviderSignOutUri in SharePoint 2013 as it does
    not exist
- SPUserProfileServiceApp
  - Changed MySiteHostLocation to not be mandatory
  - Added validation to Set function for testing if SiteNamingConflictResolution parameter
    is defined then also MySiteHostLocation parameters has to be because it is a mandatory
    parameter in the parameter set of New-SPProfileServiceApplication when
    SiteNamingConflictResolution is used.
  - Added "MySiteHostLocation" to Test-SPDscParameterState function in Test-TargetResource

### Fixed

- SPBlobCacheSettings
  - Fixed issue where the Get method threw an error when the zone didn't exist.
- SPTrustedIdentityTokenIssuer
  - Do not set property ProviderSignOutUri in SharePoint 2013 as it does
    not exist
- SPWebAppPolicy
  - Fixed a blocking issue introduced in version 4.4.0 when extracting cache
    accounts

### Removed

- SharePointDsc
  - Removed two old files from the previous CD/CI system

## [4.4.0] - 2020-11-14

### Added

- SharePointDsc
  - Added logging to the event log when the code throws an exception
  - Added support for trusted domains to Test-SPDscIsADUser helper function
- SPInstall
  - Added documentation about a SharePoint 2019 installer issue

### Changed

- SPAlternateUrl
  - Fixed issue where trailing '/' cause Url not to be recognized.
- SharePointDsc
  - Updated Convert-SPDscHashtableToString to output the username when
    parameter is a PSCredential
- SPFarm
  - Switched from creating a Lock database to a Lock table in the TempDB.
    This to allow the use of precreated databases.
  - Updated code to properly output used credential parameters to verbose
    logging
- SPSite
  - Added more explanation to documentation on which parameters are checked
- SPWeb
  - Added more explanation to documentation on using this resource

### Fixed

- SPConfigWizard
  - Fixes issue where a CU installation wasn't registered properly in the
    config database. Added logic to run the Product Version timer job
- SPSearchTopology
  - Fixes issue where applying a topology failed when the search service
    instance was disabled instead of offline
- SPSecureStoreServiceApp
  - Fixes issue where custom database name was no longer used since v4.3
- SPShellAdmins
  - Fixed issue with Get-DscConfiguration which threw an error when only one
    item was returned by the Get method
- SPWordAutomationServiceApp
  - Fixed issue where provisioning the service app requires a second run to
    update all specified parameters
- SPWorkflowService
  - Fixed issue configuring workflow service when no workflow service is
    currently configured

## [4.3.0] - 2020-09-30

### Added

- SPProductUpdate
  - Added extra logging when the setup file was not found
- SPSecureStoreServiceApp
  - Added possibility to set the Master Key during creation of the service
    application

### Changed

- SharePointDsc
  - Changed ModuleBuilder module to latest version
  - Update Pester tests to remove legacy Pester syntax
- SPFarm
  - Added support for specifying port number in the CentralAdministrationUrl parameter.
    If CentralAdministrationPort is also specified both port numbers must match.
- SPWebAppSuiteBar
  - Unblocked usage on SharePoint 2019. Added verbose messages clarifying usage
    scenarios on SharePoint 2019.

### Fixed

- SharePointDsc
  - Fixed issue where Invoke-SPDscCommand wasn't available anymore for the script
    resource
- SPContentDatabase
  - Fixed issue where the set method didn't do anything when the Ensure parameter
    wasn't specified
- SPFarm
  - Fixed issue where the resource didn't support precreated databases.
- SPFarmAdministrators
  - Fixed issue in SP2016 where an error was thrown in the Set method since v3.8
- SPFarmSolution
  - Fixed issue where web applications weren't compared properly when the desired
    value didn't contain any slashes
- SPInstallLanguagePack
  - Fixed issue with detection of Chinese language pack in SharePoint 2019
- SPServiceAppSecurity
  - Fixed incorrect example
- SPStateServiceApp
  - Fixed issue where code failed because the State database already existed
- SPTrustedIdentityTokenIssuer
  - Run Get-SPClaimProvider only if property ClaimProviderName is omitted/null/empty
  - Property ClaimProviderName is never set
- SPWeb
  - Fixed issue with incorrect detection of SPWeb that has to be absent

For older change log history see the [historic changelog](HISTORIC_CHANGELOG.md).
