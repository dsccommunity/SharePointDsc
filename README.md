# xSharePoint

Build status: [![Build status](https://ci.appveyor.com/api/projects/status/aj6ce04iy5j4qcd4/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/xsharepoint/branch/master)

The xSharePoint PowerShell module provides DSC resources that can be used to deploy and manage a SharePoint farm. 

This module is provided AS IS, and is not supported through any Microsoft standard support program or service. 
The "x" in xSharePoint stands for experimental, which means that these resources will be fix forward and monitored by the module owner(s).

Please leave comments, feature requests, and bug reports in the Q & A tab for this module.

If you would like to modify xSharePoint module, please feel free. 
When modifying, please update the module name, resource friendly name, and MOF class name (instructions below). 
As specified in the license, you may copy or modify this resource as long as they are used on the Windows Platform.
Pleaes refer to the [Contribution Guidelines](https://github.com/PowerShell/xSharePoint/wiki/Contributing%20to%20xSharePoint) for information about style guides, testing and patterns for contributing to DSC resources.

## Installation

To install the xSharePoint module:

Unzip the content under $env:ProgramFiles\WindowsPowerShell\Modules folder 

To confirm installation:

Run Get-DSCResource to see that xSharePoint is among the DSC Resources listed. Requirements This module requires the latest version of PowerShell (v4.0, which ships in Windows 8.1 or Windows Server 2012R2). 
To easily use PowerShell 4.0 on older operating systems, install WMF 4.0. 
Please read the installation instructions that are present on both the download page and the release notes for WMF 4.0

## DSC Resources

Below is a list of DSC resource types that are currently provided by xSharePoint:

 - xBCSServiceApp
 - xSPCacheAccounts
 - xSPClearRemoteSessions
 - xSPCreateFarm
 - xSPDiagnosticLoggingSettings
 - xSPDistributedCacheService
 - xSPFeature
 - xSPInstall
 - xSPInstallPreReqs
 - xSPJoinFarm
 - xSPManagedAccount
 - xSPManagedMetadataServiceApp
 - xSPManagedPath
 - xSPSearchServiceApp
 - xSPSecureStoreServiceApp
 - xSPServiceAppPool
 - xSPServiceInstance
 - xSPSite
 - xSPStateServiceApp
 - xSPUsageApplication
 - xSPUserProfileServiceApp
 - xSPUserProfileSyncService
 - xSPWebApplication

## Preview status

Currently the xSharePoint resource is a work in progress that is not yet feature complete. 
Review the documentation on the wiki of the project on GitHub for details on current functionality, as well as any known issues as the team works towards a feature complete version 1.0

## Examples

Review the "examples" directory in the xSharePoint resource for some general examples of how the overall module can be used.
Additional detailed documentation is included on the wiki on GitHub. 

## Version History

### Unreleased


### 0.4.0.0

*Fixed issue with nested modules’ cmdlets not being found

### 0.3.0.0

* Fixed issue with detection of Identity Extensions in xSPInstallPrereqs resource
* Changes to comply with PSScriptAnalyzer rules

### 0.2.0

* Initial public release of xSharePoint
 
