# Change log for SharePointDsc

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- ReverseDSC
  - Native support to allow for configuration extraction

### Added

- SharePointDsc
  - Added logging to the event log when the code throws an exception
  - Added support for trusted domains to Test-SPDscIsADUser helper function
- SPInstall
  - Added documentation about a SharePoint 2019 installer issue

### Changed

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

## [4.2.0] - 2020-06-12

### Fixed

- SharePointDsc
  - Renamed custom event log to SPDsc to prevent event log naming issue.

## [4.1.0] - 2020-06-10

### Added

- SharePointDsc
  - Added Wiki generation to build task
  - Re-enabled Unit tests for Sharepoint 2016 and 2019
- SPAppCatalog
  - Added more logging in the Get method to ease troubleshooting
- SPServiceInstance
  - Added logic to wait for a service start/stop, to make sure no conflicts
    can occur because of the asynchronous nature of service instance starts.

### Changed

- SPProductUpdate
  - Updated Get method to display a Verbose message when the setup file is
    not found
- SPWebAppPermissions
  - Changed Get method not to throw an exception when the web application
    cannot be found to prevent issue
- SPWebAppSuiteBar
  - This resource does not work on SharePoint 2019. Changed resource to display
    a Verbose message when on 2019

### Fixed

- SharePointDsc
  - Fixed an issue where Test-SPDscParameterState would throw an error due to duplicate
    keys when a desired value is of type CimInstance[] and multiple values
    are specified.
  - Fixed issue with logging to the custom event log where the event log
    wasn't created correctly.
  - Fixed various unit tests for Sharepoint 2016 and 2019
  - Corrected export of Get-SPDscInstalledProductVersion function, which is used
    by ReverseDsc
- SPConfigWizard
  - Fixed a call to Get-SPFarm without loading the snap-in first
- SPInstallLanguagePack
  - Fixed issue with detection of Chinese language pack in SharePoint 2019
- SPSearchTopology
  - Fixed issue where an issue was thrown when the FirstPartitionDirectory didn't
    exist on the local server (which isn't always required)
- SPSite
  - Fixed issue where the default groups were checked, even though
    that parameter wasn't specified in the config
  - Fixed issue where the Get method threw an error when the site owner was
    still in classic format (caused by an earlier migration).
- SPTrustedSecurityTokenIssuer
  - Fixed incorrect storing the default value of IsTrustBroker in the Set
    and Test method

### Removed

- SharePointDsc
  - Removed returning the InstallAccount parameter from all Get methods.
    These are not used and only add noise during troubleshooting

## [4.0.0] - 2020-04-28

### Added

- SharePointDsc
  - Added verbose logging of the test results in the Test method
  - Added function to create SharePointDsc event log and add log entries
  - Added the logging of all test results to the new SharePointDsc event log
  - Added support in several resources for creating/connecting to farm
    and service applications using a (single) SQL-based credential
    instead of the default Windows credentials. Needed when e.g. using
    Azure SQL Managed Instance as SharePoint's database server.
    UseSQLAuthentication and DatabaseCredentials parameters will need
    to be considered.

### Changed

- SPTrustedRootAuthority
  - It's now possible to specify both CertificateFilePath and CertificateThumbprint
    so that the certificate thumbprint can be verified before importing.
- SPTrustedSecurityTokenIssuer
  - It's now possible to specify both SigningCertificateFilePath and
    SigningCertificateThumbprint so that the certificate thumbprint can be verified
    before importing.

The following changes will break v3.x and earlier configurations that use these
resources:

- SPManagedMetaDataServiceAppDefault
  - Updated resource to allow the configuration of default per service application
    proxy groups instead of per farm
- SPSearchContentSource
  - Discontinued CrawlEverything, CrawlFirstOnly and null as allowable CrawlSetting
    values for a SharePoint based content source, requiring CrawlVirtualServers or
    CrawlSites
- SPUserProfileServiceApp
  - Changed the MySiteHostLocation parameter to a required parameter
- SPWebAppAuthentication
  - Updated resource to add support for Basic Authentication

### Fixed

- SPFarmSolution
  - Corrected bug running Solution Job wait for an Absent solution.
  - Corrected bug trying to remove an already Absent solution.
- SPSearchAuthoritativePage
  - Corrected bug when checking for an existing Demoted Action
- SPWebAppAuthentication
  - Updated to support passing of null/empty collections for zones not utilized.

### Removed

The following changes will break v3.x and earlier configurations that use these
resources:

- SPSearchServiceApp
  - Removed the WindowsServiceAccount parameter that was depricated in v3.1
- SPUserProfileSyncService
  - Removed the FarmAccount parameter that was depricated in v2.2

## [3.8.0] - 2020-02-27

### Added

- SharePointDsc
  - Added automatic release with a new CI pipeline
  - Updated PULL_REQUEST_TEMPLATE.md to match DSC standard
  - Prepared Conceptual Help and Wiki Content generation
- SPAzureAccessControlServiceAppProxy
  - Added new resource to create Azure Access Control Service Application Proxy
- SPExcelServiceApp
  - Documentation update for SharePoint 2016/2019 deprecation.
- SPInstallPrereqs
  - Documentation update for SharePoint 2019 offline install parameters.
- SPFarm
  - Added possibility to set application credential key.
- SPOAppPrincipalMgmtServiceAppProxy
  - Added new resource to create SharePoint Online Application Principal
    Management Service Application Proxy
- SPTrustedSecurityTokenIssuer
  - Fixed RegisteredIssuerNameRealm not applied if specified.
- SPUserProfileProperty
  - Added IsReplicable property.

### Changed

- SharePointDsc
  - Updated all resources and Invoke-SPDscCommand function to automatically
    load Utils module, which broke with the new CI
  - Extended Convert-SPDscHashtableToString function to support complex types
    in arrays and the CIMInstance type
- SPConfigWizard
  - Updated checks in Set method to make sure the resource also runs when
    a language pack is installed
- SPContentDatabase
  - Updated DatabaseServer parameter to support null value
- SPSearchIndexPartition
  - Updated documentation to specifically mention that each index partition
    requires its own dedicated RootDirectory
- SPUserProfileServiceApp
  - Implemented ability to fix incorrectly linked proxy groups
- SPWebApplicationExtension
  - Forced the conversion of Paths to string

### Fixed

- SharePointDsc
  - Corrected schema.mof files of SPSubscriptionSettingServiceApp and
    SPPasswordChangeSettings resources, which caused failed Wiki generation
- SPSearchContentSource
  - Add CrawlVirtualServers and CrawlSites CrawlSetting for SharePoint content
    sources.
- SPSubscriptionSettingServiceApp
  - Corrected incorrect information in Readme file
- SPUserProfileProperty
  - Fixed typo in user profile property test for IsSearchable.

For older change log history see the [historic changelog](HISTORIC_CHANGELOG.md).
