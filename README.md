# xSharePoint

Build status: [![Build status](https://ci.appveyor.com/api/projects/status/aj6ce04iy5j4qcd4/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/xsharepoint/branch/master)

[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/PowerShell/xSharePoint?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

The xSharePoint PowerShell module provides DSC resources that can be used to deploy and manage a SharePoint farm. 

This module is provided AS IS, and is not supported through any Microsoft standard support program or service. 
The "x" in xSharePoint stands for experimental, which means that these resources will be fix forward and monitored by the module owner(s).

Please leave comments, feature requests, and bug reports in the Q & A tab for this module.

If you would like to modify xSharePoint module, please feel free. 
When modifying, please update the module name, resource friendly name, and MOF class name (instructions below). 
As specified in the license, you may copy or modify this resource as long as they are used on the Windows Platform.
Please refer to the [Contribution Guidelines](https://github.com/PowerShell/xSharePoint/wiki/Contributing%20to%20xSharePoint) for information about style guides, testing and patterns for contributing to DSC resources.

## Installation

To install the xSharePoint module:

Unzip the content under $env:ProgramFiles\WindowsPowerShell\Modules folder 

To confirm installation:

Run Get-DSCResource to see that xSharePoint is among the DSC Resources listed. Requirements This module requires the latest version of PowerShell (v4.0, which ships in Windows 8.1 or Windows Server 2012R2). 
To easily use PowerShell 4.0 on older operating systems, install WMF 4.0. 
Please read the installation instructions that are present on both the download page and the release notes for WMF 4.0

## DSC Resources

Below is a list of DSC resource types that are currently provided by xSharePoint:

 - xSPAntivirusSettings
 - xSPAppCatalog
 - xSPAppDomain
 - xSPAppManagementServiceApp
 - xSPBCSServiceApp
 - xSPCacheAccounts
 - xSPCreateFarm
 - xSPDesignerSettings
 - xSPDiagnosticLoggingSettings
 - xSPDistributedCacheService
 - xSPFarmAdministrators
 - xSPFeature
 - xSPHealthAnalyzerRuleState
 - xSPInstall
 - xSPInstallPreReqs
 - xSPJoinFarm
 - xSPManagedAccount
 - xSPManagedMetadataServiceApp
 - xSPManagedPath
 - xSPOutgoingEmailSettings
 - xSPPasswordChangeSettings
 - xSPQuotaTemplate
 - xSPSearchIndexPartition
 - xSPSearchServiceApp
 - xSPSearchTopology
 - xSPSecureStoreServiceApp
 - xSPServiceAppPool
 - xSPServiceInstance
 - xSPSessionStateService
 - xSPShellAdmin
 - xSPSite
 - xSPStateServiceApp
 - xSPSubscriptionSettingsServiceApp
 - xSPTimerJobState
 - xSPUsageApplication
 - xSPUserProfileServiceApp
 - xSPUserProfileSyncService
 - xSPVisioServiceApp
 - xSPWebAppBlockedFileTypes
 - xSPWebAppGeneralSettings
 - xSPWebApplication
 - xSPWebApplicationAppDomain
 - xSPWebAppPolicy
 - xSPWebAppSiteUseAndDeletion
 - xSPWebAppThrottlingSettings
 - xSPWebAppWorkflowSettings
 - xSPWordAutomationServiceApp

## Preview status

Currently the xSharePoint resource is a work in progress that is not yet feature complete. 
Review the documentation on the wiki of the project on GitHub for details on current functionality, as well as any known issues as the team works towards a feature complete version 1.0

## Examples

Review the "examples" directory in the xSharePoint resource for some general examples of how the overall module can be used.
Additional detailed documentation is included on the wiki on GitHub. 

## Version History

### Unreleased

 * Fixed bug in managed account schedule get method
 * Fixed incorrect output of server name in xSPOutgoingEmailSettings 
 * Added ensure properties to multiple resources to standardise schemas
 * Added xSPSearchContentSource, xSPServiceAppSecurity, xSPAccessServiceApp, xSPExcelServiceApp and xSPPerformancePointServiceApp resources
 * Fixed a bug in xSPInstallPrereqs that would cause an updated version of AD rights management to fail the test method for SharePoint 2013
 * Fixed bug in xSPFarmAdministrators where testing for users was case sensitive
 * Fixed a bug with reboot detection in xSPInstallPrereqs
 * Added SearchCenterUrl property to xSPSearchServiceApp
 * Fixed a bug in xSPAlternateUrl to account for a default zone URL being changed
 * Added content type hub URL option to xSPManagedMetadataServiceApp for when it provisions a service app
 * Updated xSPWebAppPolicy to allow addition and removal of accounts, including the Cache Accounts, to the web application policy.
 * Fixed bug with claims accounts not being added to web app policy in xSPCacheAccounts
 * Added option to not apply cache accounts policy to the web app in xSPCacheAccounts
 * Farm Passphrase now uses a PSCredential object, in order to pass the value as a securestring on xSPCreateFarm and xSPJoinFarm
 * xSPCreateFarm supports specifying Kerberos authentication for the Central Admin site with the CentralAdministrationAuth property
 * Added xSPContentDatabase resource
 * Fixed nuget package format for development feed from AppVeyor
 * Fixed bug with get output of xSPUSageApplication
 * Added SXSpath parameter to xSPInstallPrereqs for installing Windows features in offline environments
 * Added additional parameters to xSPWebAppGeneralSettings for use in hardened environments
 * Added timestamps to verbose logging for resources that pause for responses from SharePoint
 * Added options to customise the installation directories used when installing SharePoint with xSPInstall
 * Aligned testing to common DSC resource test module
 * Fixed bug in the xSPWebApplication which prevented a web application from being created in an existing application pool
 * Updated xSPInstallPrereqs to align with SharePoint 2016 RTM changes
 * Added support for cloud search index to xSPSearchServiceApp

### 0.12.0.0

 * Removed Visual Studio project files, added VSCode PowerShell extensions launch file
 * Added xSPDatabaseAAG, xSPFarmSolution and xSPAlternateUrl resources
 * Fixed bug with xSPWorkManagementServiceApp schema
 * Added support to xSPSearchServiceApp to configure the default content access account
 * Added support for SSL web apps to xSPWebApplication
 * Added support for xSPDistributedCacheService to allow provisioning across multiple servers in a specific sequence
 * Added version as optional parameter for the xSPFeature resource to allow upgrading features to a specific version
 * Fixed a bug with xSPUserProfileSyncConnection to ensure it gets the correct context 
 * Added MOF descriptions to all resources to improve editing experience in PowerShell ISE
 * Added a check to warn about issue when installing SharePoint 2013 on a server with .NET 4.6 installed
 * Updated examples to include installation resources
 * Fixed issues with kerberos and anonymous access in xSPWebApplication
 * Add support for SharePoint 2016 on Windows Server 2016 Technical Preview to xSPInstallPrereqs
 * Fixed bug for provisioning of proxy for Usage app in xSPUsageApplication

### 0.10.0.0

 * Added xSPWordAutomationServiceApp, xSPHealthAnalyzerRuleState, xSPUserProfileProperty, xSPWorkManagementApp, xSPUserProfileSyncConnection and xSPShellAdmin resources
 * Fixed issue with MinRole support in xSPJoinFarm

### 0.9.0.0

 * Added xSPAppCatalog, xSPAppDomain, xSPWebApplicationAppDomain, xSPSessionStateService, xSPDesignerSettings, xSPQuotaTemplate, xSPWebAppSiteUseAndDeletion, xSPSearchTopology, xSPSearchIndexPartition, xSPWebAppPolicy and xSPTimerJobState resources
 * Fixed issue with wrong parameters in use for SP2016 beta 2 prerequisite installer

### 0.8.0.0

 * Added xSPAntivirusSettings, xSPFarmAdministrators, xSPOutgoingEmailSettings, xSPPasswordChangeSettings, xSPWebAppBlockedFileTypes, xSPWebAppGeneralSettings, xSPWebAppThrottlingSettings and xSPWebAppWorkflowSettings
 * Fixed issue with xSPInstallPrereqs using wrong parameters in offline install mode
 * Fixed issue with xSPInstallPrereqs where it would not validate that installer paths exist
 * Fixed xSPSecureStoreServiceApp and xSPUsageApplication to use PSCredentials instead of plain text username/password for database credentials
 * Added built in PowerShell help (for calling "Get-Help about_[resource]", such as "Get-Help about_xSPCreateFarm")

### 0.7.0.0

 * Support for MinRole options in SharePoint 2016
 * Fix to distributed cache deployment of more than one server
 * Additional bug fixes and stability improvements

### 0.6.0.0

 * Added support for PsDscRunAsCredential in PowerShell 5 resource use
 * Removed timeout loop in xSPJoinFarm in favour of WaitForAll resource in PowerShell 5

### 0.5.0.0

* Fixed bug with detection of version in create farm
* Minor fixes
* Added support for SharePoint 2016 installation
* MSFT_xSPCreateFarm: Added CentraladministrationPort parameter
* Fixed issue with PowerShell session timeouts

### 0.4.0

* Fixed issue with nested modules cmdlets not being found

### 0.3.0

* Fixed issue with detection of Identity Extensions in xSPInstallPrereqs resource
* Changes to comply with PSScriptAnalyzer rules

### 0.2.0

* Initial public release of xSharePoint
 
