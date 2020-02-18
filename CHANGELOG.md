# Change log for SharePointDsc

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- SharePointDsc
  - Added automatic release with a new CI pipeline
  - Updated PULL_REQUEST_TEMPLATE.md to match DSC standard
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

### Changed

- SharePointDsc
  - Updated all resources and Invoke-SPDscCommand function to automatically
    load Utils module, which broke with the new CI
- SPConfigWizard
  - Updated checks in Set method to make sure the resource also runs when
    a language pack is installed
- SPUserProfileServiceApp
  - Implemented ability to fix incorrectly linked proxy groups

### Deprecated

- None

### Removed

- None

### Fixed

- SPSearchContentSource
  - Add CrawlVirtualServers and CrawlSites CrawlSetting for SharePoint content
    sources.

### Security

- None

## [3.7.0.0] - 2019-10-30

### Added

- None

### Changed

- None

### Deprecated

- None

### Removed

- None

### Fixed

- SPConfigWizard
  - Fixed issue with incorrect check for upgrade status of server
- SPDistributedCacheService
  - Improved error message for inclusion of server name into ServerProvisionOrder
    parameters when Present or change to Ensure Absent
- SPFarm
  - Removed SingleServer as ServerRole, since this is an invalid role.
  - Handle case where null or empty CentralAdministrationUrl is passed in
  - Move CentralAdministrationPort validation into parameter definition
    to work with ReverseDsc
  - Add NotNullOrEmpty parameter validation to CentralAdministrationUrl
  - Fixed error when changing developer dashboard display level.
  - Add support for updating Central Admin Authentication Method
- SPFarmSolution
  - Fix for Web Application scoped solutions.
- SPInstall
  - Fixes a terminating error for sources in weird file shares
  - Corrected issue with incorrectly detecting SharePoint after it
    has been uninstalled
  - Corrected issue with detecting a paused installation
- SPInstallLanguagePack
  - Fixes a terminating error for sources in weird file shares
- SPInstallPrereqs
  - Fixes a terminating error for sources in weird file shares
- SPProductUpdate
  - Fixes a terminating error for sources in weird file shares
  - Corrected incorrect farm detection, added in earlier bugfix
- SPSite
  - Fixed issue with incorrectly updating site OwnerAlias and
    SecondaryOwnerAlias
- SPWebAppAuthentication
  - Fixes issue where Test method return false on NON-US OS.

### Security

- None

## [3.6.0.0] - 2019-08-07

### Added

- SPTrustedSecurityTokenIssuer
  - New resource for configuring OAuth trusts

### Changed

- None

### Deprecated

- None

### Removed

- None

### Fixed

- SharePointDsc generic
  - Added new launch actions to vscode to allow code coverage reports for
    the current unit test file.
- SPFarm
  - Moved check for CentralAdministrationUrl is HTTP to Set method,
    to prevent issues with ReverseDsc
- SPInstall
  - Updated error code checks to force reboot.
- SPProductUpdate
  - Fixes an issue using ShutdownServices when no Farm is available.
- SPTrustedRootAuthority
  - Fixes issue where Set method throws an error because the
    parameter CertificateFilePath is not read correctly.

### Security

- None

For older change log history see the [historic changelog](HISTORIC_CHANGELOG.md).
