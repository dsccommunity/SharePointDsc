# Change log for SharePointDsc

## 1.5

* Fixed issue with SPManagedMetaDataServiceApp if ContentTypeHubUrl parameter is
  null
* Added minimum PowerShell version to module manifest
* Added testing for valid markdown syntax to unit tests
* Added support for MinRole enhancements added in SP2016 Feature Pack 1
* Fixed bug with search topology that caused issues with names of servers needing
  to all be the same case
* Fixed bug in SPInstallLanguagePack where language packs could not be installed
  on SharePoint 2016
* Added new resource SPSearchFileType
* Updated SPDatabaseAAG to allow database name patterns
* Fixed a bug were PerformancePoint and Excel Services Service Application
  proxies would not be added to the default proxy group when they are
  provisioned
* Added an error catch to provide more detail about running SPAppCatalog with
  accounts other than the farm account

## 1.4

* Set-TargetResource of Service Application now also removes all associated
  proxies
* Fixed issue with all SPServiceApplication for OS not in En-Us language,
  add GetType().FullName method in:
  * SPAccessServiceApp
  * SPAppManagementServiceApp
  * SPBCSServiceApp
  * SPExcelServiceApp
  * SPManagedMetaDataServiceApp
  * SPPerformancePointServiceApp
  * SPSearchServiceApp
  * SPSearchCrawlRule
  * SPSecureStoreServiceApp
  * SPSubscriptionSettingsServiceApp
  * SPUsageApplication
  * SPUserProfileServiceApp
  * SPVisioServiceApp
  * SPWordAutomationServiceApp
  * SPWorkManagementServiceApp
* Fixed issue with SPServiceInstance for OS not in En-Us language, add
  GetType().Name method in:
  * SPDistributedCacheService
  * SPUserProfileSyncService
* Fixed issue with SPInstallLanguagePack to install before farm creation
* Fixed issue with mounting SPContentDatabase
* Fixed issue with SPShellAdmin and Content Database method
* Fixed issue with SPServiceInstance (Set-TargetResource) for OS not in
  En-Us language
* Added .Net 4.6 support check to SPInstall and SPInstallPrereqs
* Improved code styling
* SPVisioServiceapplication now creates proxy and lets you specify a name for
  it
* New resources: SPAppStoreSettings
* Fixed bug with SPInstallPrereqs to allow minor version changes to prereqs for
  SP2016
* Refactored unit tests to consolidate and streamline test approaches
* Updated SPExcelServiceApp resource to add support for trusted file locations
  and most other properties of the service app
* Added support to SPMetadataServiceApp to allow changing content type hub URL
  on existing service apps
* Fixed a bug that would cause SPSearchResultSource to throw exceptions when
  the enterprise search centre URL has not been set
* Updated documentation of SPProductUpdate to reflect the required install
  order of product updates

## 1.3

* Fixed typo on return value in SPServiceAppProxyGroup
* Fixed SPJoinFarm to not write output during successful farm join
* Fixed issue with SPSearchTopology to keep array of strings in the hashtable
  returned by Get-Target
* Fixed issue with SPSearchTopology that prevented topology from updating where
  ServerName was not returned on each component
* Added ProxyName parameter to all service application resources
* Changed SPServiceInstance to look for object type names instead of the display
  name to ensure consistency with language packs
* Fixed typos in documentation for InstallAccount parameter on most resources
* Fixed a bug where SPQuotaTemplate would not allow warning and limit values to
  be equal
* New resources: SPConfigWizard, SPProductUpdate and SPPublishServiceApplication
* Updated style of all script in module to align with PowerShell team standards
* Changed parameter ClaimsMappings in SPTrustedIdentityTokenIssuer to consume an
  array of custom object MSFT_SPClaimTypeMapping
* Changed SPTrustedIdentityTokenIssuer to throw an exception if certificate
  specified has a private key, since SharePoint doesn't accept it
* Fixed issue with SPTrustedIdentityTokenIssuer to stop if cmdlet
  New-SPTrustedIdentityTokenIssuer returns null
* Fixed issue with SPTrustedIdentityTokenIssuer to correctly get parameters
  ClaimProviderName and ProviderSignOutUri
* Fixed issue with SPTrustedIdentityTokenIssuer to effectively remove the
  SPTrustedAuthenticationProvider from all zones before deleting the
  SPTrustedIdentityTokenIssuer

## 1.2

* Fixed bugs SPWebAppPolicy and SPServiceApPSecurity that prevented the get
  methods from returning AD group names presented as claims tokens
* Minor tweaks to the PowerShell module manifest
* Modified all resources to ensure $null values are on the left of
  comparisson operations
* Added RunOnlyWhenWriteable property to SPUserProfileSyncService resource
* Added better logging to all test method output to make it clear what property
  is causing a test to fail
* Added support for NetBIOS domain names resolution to SPUserProfileServiceApp
* Removed chocolatey from the AppVeyor build process in favour of the
  PowerShell Gallery build of Pester
* Fixed the use of plural nouns in cmdlet names within the module
* Fixed a bug in SPContentDatabase that caused it to not function correctly.
* Fixed the use of plural nouns in cmdlet names within the module
* Removed dependency on Win32_Product from SPInstall
* Added SPTrustedIdentityTokenIssuer, SPRemoteFarmTrust and
  SPSearchResultSource resources
* Added HostHeader parameter in examples for Web Application, so subsequent web
  applications won't error out
* Prevented SPCreateFarm and SPJoinFarm from executing set methods where the
  local server is already a member of a farm

## 1.1

* Added SPBlobCacheSettings, SPOfficeOnlineServerBinding, SPWebAppPermissions,
  SPServiceAppProxyGroup, SPWebAppProxyGroup and
  SPUserProfileServiceAppPermissions resources
* SPUserProfileSyncService Remove Status field from Get-TargResource: not in
  MOF, redundant with Ensure
* Improvement with SPInstallPrereqs on SPS2013 to accept 2008 R2 or 2012 SQL
  native client not only 2008 R2
* Fixed a bug with SPTimerJobState that prevented a custom schedule being
  applied to a timer job
* Fixed a bug with the detection of group principals vs. user principals in
  SPServiceAppSecurity and SPWebAppPolicy
* Removed redundant value for KB2898850 from SPInstallPrereqs, also fixed old
  property name for DotNetFX
* Fixed a bug with SPAlternateUrl that prevented the test method from returning
  "true" when a URL was absent if the optional URL property was specified in
  the config
* Fixed bugs in SPAccessServiceApp and SPPerformancePointServiceApp with type
  names not being identified correctly
* Added support for custom database name and server to
  SPPerformancePointServiceApp
* Added solution level property to SPFarmSolution
* Fixed a bug with SPSearchServiceApp that prevents the default crawl account
  from being managed after it is initially set
* Removed dependency on Win32_Prouct from SPInstallPrereqs

## 1.0

* Renamed module from xSharePoint to SharePointDsc
* Fixed bug in managed account schedule get method
* Fixed incorrect output of server name in xSPOutgoingEmailSettings
* Added ensure properties to multiple resources to standardise schemas
* Added xSPSearchContentSource, xSPContentDatabase, xSPServiceAppSecurity,
  xSPAccessServiceApp, xSPExcelServiceApp, xSPPerformancePointServiceApp,
  xSPIrmSettings resources
* Fixed a bug in xSPInstallPrereqs that would cause an updated version of AD
  rights management to fail the test method for SharePoint 2013
* Fixed bug in xSPFarmAdministrators where testing for users was case sensitive
* Fixed a bug with reboot detection in xSPInstallPrereqs
* Added SearchCenterUrl property to xSPSearchServiceApp
* Fixed a bug in xSPAlternateUrl to account for a default zone URL being
  changed
* Added content type hub URL option to xSPManagedMetadataServiceApp for when
  it provisions a service app
* Updated xSPWebAppPolicy to allow addition and removal of accounts, including
  the Cache Accounts, to the web application policy.
* Fixed bug with claims accounts not being added to web app policy in
  xSPCacheAccounts
* Added option to not apply cache accounts policy to the web app in
  xSPCacheAccounts
* Farm Passphrase now uses a PSCredential object, in order to pass the value
  as a securestring on xSPCreateFarm and xSPJoinFarm
* xSPCreateFarm supports specifying Kerberos authentication for the Central
  Admin site with the CentralAdministrationAuth property
* Fixed nuget package format for development feed from AppVeyor
* Fixed bug with get output of xSPUSageApplication
* Added SXSpath parameter to xSPInstallPrereqs for installing Windows features
  in offline environments
* Added additional parameters to xSPWebAppGeneralSettings for use in hardened
  environments
* Added timestamps to verbose logging for resources that pause for responses
  from SharePoint
* Added options to customise the installation directories used when installing
  SharePoint with xSPInstall
* Aligned testing to common DSC resource test module
* Fixed bug in the xSPWebApplication which prevented a web application from
  being created in an existing application pool
* Updated xSPInstallPrereqs to align with SharePoint 2016 RTM changes
* Added support for cloud search index to xSPSearchServiceApp
* Fixed bug in xSPWebAppGeneralSettings that prevented setting a security
  validation timeout value

## 0.12.0.0

* Removed Visual Studio project files, added VSCode PowerShell extensions
  launch file
* Added xSPDatabaseAAG, xSPFarmSolution and xSPAlternateUrl resources
* Fixed bug with xSPWorkManagementServiceApp schema
* Added support to xSPSearchServiceApp to configure the default content
  access account
* Added support for SSL web apps to xSPWebApplication
* Added support for xSPDistributedCacheService to allow provisioning across
  multiple servers in a specific sequence
* Added version as optional parameter for the xSPFeature resource to allow
  upgrading features to a specific version
* Fixed a bug with xSPUserProfileSyncConnection to ensure it gets the
  correct context
* Added MOF descriptions to all resources to improve editing experience
  in PowerShell ISE
* Added a check to warn about issue when installing SharePoint 2013 on a
  server with .NET 4.6 installed
* Updated examples to include installation resources
* Fixed issues with kerberos and anonymous access in xSPWebApplication
* Add support for SharePoint 2016 on Windows Server 2016 Technical Preview
  to xSPInstallPrereqs
* Fixed bug for provisioning of proxy for Usage app in xSPUsageApplication

## 0.10.0.0

* Added xSPWordAutomationServiceApp, xSPHealthAnalyzerRuleState,
  xSPUserProfileProperty, xSPWorkManagementApp, xSPUserProfileSyncConnection
  and xSPShellAdmin resources
* Fixed issue with MinRole support in xSPJoinFarm

## 0.9.0.0

* Added xSPAppCatalog, xSPAppDomain, xSPWebApplicationAppDomain,
  xSPSessionStateService, xSPDesignerSettings, xSPQuotaTemplate,
  xSPWebAppSiteUseAndDeletion, xSPSearchTopology, xSPSearchIndexPartition,
  xSPWebAppPolicy and xSPTimerJobState resources
* Fixed issue with wrong parameters in use for SP2016 beta 2 prerequisite
  installer

## 0.8.0.0

* Added xSPAntivirusSettings, xSPFarmAdministrators, xSPOutgoingEmailSettings,
  xSPPasswordChangeSettings, xSPWebAppBlockedFileTypes,
  xSPWebAppGeneralSettings, xSPWebAppThrottlingSettings and
  xSPWebAppWorkflowSettings
* Fixed issue with xSPInstallPrereqs using wrong parameters in offline install
  mode
* Fixed issue with xSPInstallPrereqs where it would not validate that installer
  paths exist
* Fixed xSPSecureStoreServiceApp and xSPUsageApplication to use PSCredentials
  instead of plain text username/password for database credentials
* Added built in PowerShell help (for calling "Get-Help about_[resource]",
  such as "Get-Help about_xSPCreateFarm")

## 0.7.0.0

* Support for MinRole options in SharePoint 2016
* Fix to distributed cache deployment of more than one server
* Additional bug fixes and stability improvements

## 0.6.0.0

* Added support for PsDscRunAsCredential in PowerShell 5 resource use
* Removed timeout loop in xSPJoinFarm in favour of WaitForAll resource in
  PowerShell 5

## 0.5.0.0

* Fixed bug with detection of version in create farm
* Minor fixes
* Added support for SharePoint 2016 installation
* xSPCreateFarm: Added CentraladministrationPort parameter
* Fixed issue with PowerShell session timeouts

## 0.4.0

* Fixed issue with nested modules cmdlets not being found

## 0.3.0

* Fixed issue with detection of Identity Extensions in xSPInstallPrereqs
  resource
* Changes to comply with PSScriptAnalyzer rules

## 0.2.0

* Initial public release of xSharePoint
