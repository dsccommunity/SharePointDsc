# Changelog for SharePointDsc

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- SharePointDsc
  - Added generic unit tests files to quickly run all or a specific unit test
  - Updated pipeline scripts to a recent version
  - Added a extensive flexible configuration to deploy a SharePoint environment
- SPTrustedIdentityTokenIssuer
  - Added parameters to support OIDC authentication in SharePoint Server Subscription Edition
- SPWebAppPeoplePickerSettings
  - Added the PeopleEditorOnlyResolveWithinSiteCollection parameter to the resource
- SPDistributedCacheService
  - Added documentation to clarify the use of the ServerProvisionOrder parameter

### Changed

- SharePointDsc
  - Updated ReverseDsc version requirement to 2.0.0.10 to fix an issue
    with Exporting an array of CIM instances
- SPFarm
  - Suppress a useless reboot that was triggered once a server joined the farm
  - Suppress a useless 5 minutes sleep triggered once a server joined the farm

### Fixed

- SPSearchIndexPartition
  - Fixed issue where the Get method returned multiple values when using multiple
    index components
- SPTrustedRootAuthority
  - Fixed issue where certificates not in the Personal store could not be used
- Add-SPDscConfigDBLock
  - Fixed issue where a Farm configuration Database could not contain a dash '-'

## [5.0.0] - 2021-12-17

### Added

- SharePointDsc
  - Added support for SharePoint Server Subscription Edition in Util module and unit tests stubs
  - Added SPSE unit tests to the Azure pipeline definitions
- SPCertificate
  - New resource for SharePoint Server Subscription Edition
- SPCertificateSettings
  - New resource for SharePoint Server Subscription Edition
- SPDatabaseAAG
  - Added support for SharePoint Server Subscription Edition
- SPDistributedCacheService
  - Added support for SharePoint Server Subscription Edition
- SPFarm
  - Added support for SharePoint Server Subscription Edition
- SPInstall
  - Added support for SharePoint Server Subscription Edition
- SPInstallPrereqs
  - Added support for SharePoint Server Subscription Edition
- SPOfficeOnlineServerSupressionSettings
  - New resource
- SPSearchServiceApp
  - Added possibility to configure Search Index Deletion Policies settings
- SPWebApplication
  - Added possibility to manage the SiteDataServers property
  - Added support for configuring AllowLegacyEncryption, CertificateThumbprint and UseServerNameIndication
- SPWebApplicationExtension
  - Added support for configuring AllowLegacyEncryption, CertificateThumbprint and UseServerNameIndication

### Changed

- General
  - Updated pipeline definition
- ReverseDsc
  - Changed form Size to dynamic Width
  - Change column width to calc /3 of Form.
  - Export form is now more dynamic / responsive
- SPAccessServiceApp
  - Service app no longer exists in SharePoint Server Subscription Edition. Added logic to check for SPSE.
- SPAccessServices2010
  - Service app no longer exists in SharePoint Server Subscription Edition. Added logic to check for SPSE.
- SPPerformancePointServiceApp
  - Service app no longer exists in SharePoint Server Subscription Edition. Added logic to check for SPSE.
- SPWebApplicationExtension
  - Updated so it infers the UseSSL value from the URL, just like the SPWebApplication resouce

### Fixed

- SPLogLevel
  - Corrected issue in creating ReverseDsc export

### Removed

- SharePointDsc
  - [BREAKING CHANGE] Removed PowerShell v4.0 support by removing the InstallAccount parameter
    from all resources.
- SPWebApplicationExtension
  - [BREAKING CHANGE] Removed UseSSL parameter

## [4.9.0] - 2021-11-06

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
  - Disabled the Farm account DB ownership check when using SQL Auth
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

For older change log history see the [historic changelog](HISTORIC_CHANGELOG.md).
