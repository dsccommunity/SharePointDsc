# Change log for SharePointDsc

## UNRELEASED

* SPConfigWizard
  * Fixed issue with incorrect check for upgrade status of server
* SPFarm
  * Removed SingleServer as ServerRole, since this is an invalid role.
* SPFarmSolution
  * Fix for Web Application scoped solutions.
* SPInstall
  * Fixes a terminating error for sources in weird file shares
  * Corrected issue with incorrectly detecting SharePoint after it
    has been uninstalled
  * Corrected issue with detecting a paused installation
* SPInstallLanguagePack
  * Fixes a terminating error for sources in weird file shares
* SPInstallPrereqs
  * Fixes a terminating error for sources in weird file shares
* SPProductUpdate
  * Fixes a terminating error for sources in weird file shares
  * Corrected incorrect farm detection, added in earlier bugfix
* SPSite
  * Fixed issue with incorrectly updating site OwnerAlias and
    SecondaryOwnerAlias
* SPWebAppAuthentication
  * Fixes issue where Test method return false on NON-US OS.

## v3.6

* SharePointDsc generic
  * Added new launch actions to vscode to allow code coverage reports for
    the current unit test file.
* SPFarm
  * Moved check for CentralAdministrationUrl is HTTP to Set method,
    to prevent issues with ReverseDsc.
* SPInstall
  * Updated error code checks to force reboot.
* SPProductUpdate
  * Fixes an issue using ShutdownServices when no Farm is available.
* SPTrustedRootAuthority
  * Fixes issue where Set method throws an error because the
    parameter CertificateFilePath is not read correctly.
* SPTrustedSecurityTokenIssuer
  * New resource for configuring OAuth trusts

## v3.5

* SharePointDsc generic
  * Improved logging in all resource. They are now outputting
    the current and targeted values in the Test method.
  * Updated various resources to comply with coding style guidelines.
  * Updated the following resources to not return Null from the Get
    method anymore, but an hashtable which contains null values:
    SPDesignerSettings, SPDiagnosticLoggingSettings, SPFarmAdministrators,
    SPHealthAnalyzerRuleState, SPIrmSettings, SPOutgoingEmailSettings,
    SPPasswordChangeSettings, SPSearchTopology, SPServiceAppProxyGroup,
    SPTimerJobState, SPUserProfileSection, SPUserProfileSyncConnection,
    SPWebAppBlockedFileTypes, SPWebApplicationAppDomain, SPWebAppPolicy,
    SPWebAppSiteUseAndDeletion, SPWebAppThrottlingSettings,
    SPWordAutomationServiceApp.
* SPConfigWizard
  * Added check to make sure the Config Wizard is only executed when all
    servers have the binaries installed.
* SPDistributedCacheService
  * Added ability to check for incorrect service account.
* SPExcelServiceApp
  * Fixes issue where Get method throws an error when the value of
    PrivateBytesMax and UnusedObjectAgeMax are negative values.
* SPFarm
  * Throw error in Get method if CentralAdministrationUrl is HTTP.
* SPInstallPrereqs
  * Fixed bug in version check, where lower versions would be
    detected as higher versions.
* SPProductUpdate
  * Updated Readme to reflect the new patching possibilities added in v3.3.
* SPSecureStore
  * Fixed issue where the test issue returned false is the service
    application didn't exist, but the database name/server parameter
    was specified.
* SPUserProfileSyncConnection
  * Fixed issue where the parameter Server was checked in SP2016
    but isn't used there and therefore always fails.
* SPWebAppAuthentication
  * Updated the documentation to better explain the use of this resource
    when using Classic authentication.

## v3.4

* SPDistributedCacheClientSettings
  * Added 15 new SharePoint 2016 parameters.
* SPFarm
  * Implemented Null check in Get method to prevent errors
  * Add support to provision Central Administration on HTTPS
* SPInfoPathFormsServiceConfig
  * Added the AllowEventPropagation parameter.
* SPInstall
  * Improved logging ouput
  * Updated blocked setup file check to prevent errors when BinaryDir
    is a CD-ROM drive or mounted ISO
* SPInstallLanguagePack
  * Improved logging ouput
  * Updated blocked setup file check to prevent errors when BinaryDir
    is a CD-ROM drive or mounted ISO
* SPInstallPrereqs
  * Improved logging ouput
  * Added the updated check to unblock setup file if it is blocked because
    it is coming from a network location. This to prevent endless wait.
  * Added ability to install from a UNC path, by adding server
    to IE Local Intranet Zone. This will prevent an endless wait
    caused by security warning.
  * Fixed an issue that would prevent the resource failing a test when the
    prerequisites have been installed successfully on Windows Server 2019
* SPManagedMetadataServiceApp
  * Fixed issue where Get-TargetResource method throws an error when the
    service app proxy does not exist and no proxy name is specified.
* SPProductUpdate
  * Improved logging ouput
  * Updated blocked setup file check to prevent errors when SetupFile
    is a CD-ROM drive or mounted ISO
* SPSearchContent Source
  * Removed check that prevents configuring an incremental schedule when
    using continuous crawl.
* SPSitePropertyBag
  * Fixed issue where properties were set on the wrong level.
* SPSubscriptionSettingsServiceApp
  * Fixed issue where the service app proxy isn't created when it wasn't
    created during initial deployment.
* SPTrustedRootAuthority
  * Added possibility to get certificate from file.

## v3.3

* SharePointDsc generic
  * Implemented workaround for PSSA v1.18 issue. No further impact for
    the rest of the resources
  * Fixed issue where powershell session was never removed and leaded to
    memory leak
  * Added readme.md file to Examples folder, which directs users to the
    Wiki on Github
* SPAppManagementServiceApp
  * Added ability to create Service App Proxy if this is not present
* SPConfigWizard
  * Improved logging
* SPFarm
  * Corrected issue where the resource would try to join a farm, even when
    the farm was not yet created
  * Fixed issue where an error was thrown when no DeveloperDashboard
    parameter was specfied
* SPInstall
  * Added check to unblock setup file if it is blocked because it is coming
    from a network location. This to prevent endless wait
  * Added ability to install from a UNC path, by adding server
    to IE Local Intranet Zone. This will prevent an endless wait
    caused by security warning
* SPInstallLanguagePack
  * Added check to unblock setup file if it is blocked because it is coming
    from a network location. This to prevent endless wait
  * Corrected issue with Norwegian language pack not being correctly
    detected
  * Added ability to install from a UNC path, by adding server
    to IE Local Intranet Zone. This will prevent an endless wait
    caused by security warning
* SPProductUpdate
  * Added ability to install from a UNC path, by adding server
    to IE Local Intranet Zone. This will prevent an endless wait
    caused by security warning
  * Major refactor of this resource to remove the dependency on the
    existence of the farm. This allows the installation of product updates
    before farm creation.
* SPSearchContentSource
  * Corrected typo that prevented a correct check for ContinuousCrawl
* SPSearchServiceApp
  * Added possibility to manage AlertsEnabled setting
* SPSelfServiceSiteCreation
  * Added new SharePoint 2019 properties
* SPSitePropertyBag
  * Added new resource
* SPWebAppThrottlingSettings
  * Fixed issue with ChangeLogRetentionDays not being applied

## v3.2

* Changes to SharePointDsc unit testing
  * Implemented Strict Mode version 1 for all code run during unit tests.
  * Changed InstallAccount into PSDscRunAsCredential parameter
* SPAuthenticationRealm
  * New resource for setting farm authentication realm
* SPConfigWizard
  * Updated PSConfig parameters according recommendations in blog post of
    Stefan Gossner
* SPDistributedCacheService
  * Fixed exception on Stop-SPServiceInstance with SharePoint 2019
* SPFarm
  * Improved logging
  * Added ability to manage the Developer Dashboard settings
* SPFarmSolution
  * Fixed issue where uninstalling a solution would not work as expected if it
    contained web application resources.
* SPIncomingEmailSettings
  * New resource for configuring incoming email settings
* SPInstallPrereqs
  * Improved logging
  * Corrected detection for Windows Server 2019
  * Corrected support for Windows Server 2019 for SharePoint 2016
* SPProductUpgrade
  * Fixed issue where upgrading SP2013 would not properly detect the installed
    version
  * Fixed issue where the localized SharePoint 2019 CU was detected as a
    Service Pack for a Language Pack
* SPSearchAuthorativePage
  * Fixed issue where modifying search query would not target the correct
    search application
* SPSearchResultSource
  * Updated resource to allow localized ProviderTypes
* SPServiceAppSecurity
  * Updated resource to allow localized permission levels
* SPServiceInstance
  * Added -All switch to resolve "Unable to locate service application" in SP2013
* SPSite
  * Improved logging
* SPUserProfileProperty
  * Fix user profile property mappings does not work
* SPUserProfileServiceApp
  * Added warning message when MySiteHostLocation is not specified. This is
    currently not required, which results in an error. Will be corrected in
    SPDsc v4.0 (is a breaking change).
* SPUserProfileSyncConnection
  * Fixed issue where test resource never would return true for any configurations
    on SharePoint 2016/2019
  * Fixed issue where updating existing connection never would work for any
    configurations on SharePoint 2016/2019
  * Updated documentation to reflect that Fore will not impact configurations for
    SharePoint 2016/2019. Updated the test method accordingly.
* SPUserProfileSyncService
  * Fixed issue where failure to configure the sync service would not throw error
* SPWebAppPeoplePickerSettings
  * Converted password for access account to secure string. Previsouly
    the resource would fail setting the password and an exeption was thrown that
    printed the password in clear text.
* SPWebAppPolicy
  * Fixed issue where parameter MembersToExclude did not work as expected
* SPWorkflowService
  * Added support for specifying scope name.
  * Added support for detecting incorrect configuration for scope name and
    WorkflowHostUri

## v3.1

* Changes to SharePointDsc
  * Updated LICENSE file to match the Microsoft Open Source Team standard.
* ProjectServerConnector
  * Added a file hash validation check to prevent the ability to load custom code
    into the module.
* SPFarm
  * Fixed localization issue where TypeName was in the local language.
* SPInstallPrereqs
  * Updated links in the Readme.md file to docs.microsoft.com.
  * Fixed required prereqs for SharePoint 2019, added MSVCRT11.
* SPManagedMetadataServiceApp
  * Fixed issue where Get-TargetResource method throws an error when the
    service app proxy does not exist.
* SPSearchContentSource
  * Corrected issue where the New-SPEnterpriseSearchCrawlContentSource cmdlet
    was called twice.
* SPSearchServiceApp
  * Fixed issue where Get-TargetResource method throws an error when the
    service application pool does not exist.
  * Implemented check to make sure cmdlets are only executed when it actually
    has something to update.
  * Deprecated WindowsServiceAccount parameter and moved functionality to
    new resource (SPSearchServiceSettings).
* SPSearchServiceSettings
  * Added new resource to configure search service settings.
* SPServiceAppSecurity
  * Fixed unavailable utility method (ExpandAccessLevel).
  * Updated the schema to no longer specify username as key for the sub class.
* SPUserProfileServiceApp
  * Fixed issue where localized versions of Windows and SharePoint would throw
    an error.
* SPUserProfileSyncConnection
  * Corrected implementation of Ensure parameter.

## v3.0

* Changes to SharePointDsc
  * Added support for SharePoint 2019
  * Added CredSSP requirement to the Readme files
  * Added VSCode Support for running SharePoint 2019 unit tests
  * Removed the deprecated resources SPCreateFarm and SPJoinFarm (replaced
    in v2.0 by SPFarm)
* SPBlobCacheSettings
  * Updated the Service Instance retrieval to be language independent
* SPConfigWizard
  * Fixed check for Ensure=Absent in the Set method
* SPInstallPrereqs
  * Added support for detecting updated installation of Microsoft Visual C++
    2015/2017 Redistributable (x64) for SharePoint 2016 and SharePoint 2019.
* SPSearchContentSource
  * Added support for Business Content Source Type
* SPSearchMetadataCategory
  * New resource added
* SPSearchServiceApp
  * Updated resource to make sure the presence of the service app proxy is
    checked and created if it does not exist
* SPSecurityTokenServiceConfig
  * The resource only tested for the Ensure parameter. Added more parameters
* SPServiceAppSecurity
  * Added support for specifying array of access levels.
  * Changed implementation to use Grant-SPObjectSecurity with Replace switch
    instead of using a combination of Revoke-SPObjectSecurity and
    Grant-SPObjectSecurity
  * Added all supported access levels as available values.
  * Removed unknown access levels: Change Permissions, Write, and Read
* SPUserProfileProperty
  * Removed obsolete parameters (MappingConnectionName, MappingPropertyName,
    MappingDirection) and introduced new parameter PropertyMappings
* SPUserProfileServiceApp
  * Updated the check for successful creation of the service app to throw an
    error if this is not done correctly

The following changes will break v2.x and earlier configurations that use these
resources:

* Implemented IsSingleInstance parameter to force that the resource can only
  be used once in a configuration for the following resources:
  * SPAntivirusSettings
  * SPConfigWizard
  * SPDiagnosticLoggingSettings
  * SPFarm
  * SPFarmAdministrators
  * SPInfoPathFormsServiceConfig
  * SPInstall
  * SPInstallPrereqs
  * SPIrmSettings
  * SPMinRoleCompliance
  * SPPasswordChangeSettings
  * SPProjectServerLicense
  * SPSecurityTokenServiceConfig
  * SPShellAdmin
* Standardized Url/WebApplication parameter to default WebAppUrl parameter
  for the following resources:
  * SPDesignerSettings
  * SPFarmSolution
  * SPSelfServiceSiteCreation
  * SPWebAppBlockedFileTypes
  * SPWebAppClientCallableSettings
  * SPWebAppGeneralSettings
  * SPWebApplication
  * SPWebApplicationAppDomain
  * SPWebAppSiteUseAndDeletion
  * SPWebAppThrottlingSettings
  * SPWebAppWorkflowSettings
* Introduced new mandatory parameters
  * SPSearchResultSource: Added option to create Result Sources at different scopes.
  * SPServiceAppSecurity: Changed parameter AccessLevel to AccessLevels in
    MSFT_SPServiceAppSecurityEntry to support array of access levels.
  * SPUserProfileProperty: New parameter PropertyMappings

## 2.6

* SPFarm
  * Fixed issue where Central Admin service was not starting for non-english farms
* SPManagedMetadataServiceApp
  * Added additional content type settings (ContentTypePushdownEnabled &
    ContentTypeSyndicationEnabled).
  * Fixed issue where Get method would throw an error when the proxy did not exist.
  * Fixed an issue where the resource checks if the proxy exists and if not, it is
    created.
* SPSearchContentSource
  * Fixed issue with numerical Content Sources name
  * Fixed issue where the code throws an error when the content source cannot be
    successfully created
* SPSearchManagedProperty
  * Added a new resource to support Search Managed Properties
  * Fix for multiple aliases
* SPSearchResultSource
  * Added a new ScopeUrl parameter to allow for local source creation
* SPSearchTopology
  * Updated Readme.md to remove some incorrect information
  * Fixed logic to handle the FirstPartitionDirectory in Get-TargetResource
* SPSelfServiceSiteCreation
  * New resource to manage self-service site creation
* SPServiceAppSecurity
  * Added local farm token.
  * Fixed issues that prevented the resource to work as expected in many situations.
* SPSite
  * Added the possibility for creating the default site groups
  * Added the possibility to set AdministrationSiteType
  * Fixed test method that in some cases always would return false
  * Fixed a typo in the values to check for AdministrationSiteType
  * Fixed an access denied issue when creating default site groups
    when the run as account does not have proper permissions for the site
* SPTrustedIdentityTokenIssuer
  * Added parameter UseWReplyParameter
* SPUserProfileServiceApp
  * Fixed issue which was introduced in v2.5 where the service application proxy
    was not created.
  * Updated resource to grant the InstallAccount permissions to a newly created service
    application to prevent issues in the Get method.
* SPUserProfileSyncConnection
  * Fixed issue where empty IncludedOUs and ExcludedOUs would throw an error
* SPWebAppClientCallableSettings
  * New resource to manage web application client callable settings including
    proxy libraries.
* SPWebAppPropertyBag
  * New resource to manage web application property bag
* SPWebAppSuiteBar
  * Fixed incorrect test method that resulted in this resource to never apply changes.
  * Enable usage of SuiteBarBrandingElementHtml for SharePoint 2016
    (only supported if using a SharePoint 2013 masterpage)

## 2.5

* SPAppCatalog
  * Updated resource to retrieve the Farm account instead of requiring it
    to be specifically used
* SPDatabaseAAG
  * Updated readme.md to specify that this resource also updates the database
    connection string
* SPDiagnosticsProvider
  * Fixed issue where enabling providers did not work
* SPFarm
  * Added ability to check and update CentralAdministrationPort
* SPLogLevel
  * Added High as TraceLevel, which was not included yet
* SPRemoteFarmTrust
  * Updated readme.md file to add a link that was lost during earlier updates
* SPSearchServiceApp
  * Updated Set method to check if service application pool exists. Resource
    will throw an error if it does not exist
* SPSearchTopology
  * Fixed issue where Get method threw an error when the specified service
    application didn't exist yet
  * Fixed issue where the resource would fail is the FQDN was specified
* SPShellAdmins
  * Added ExcludeDatabases parameter for AllDatabases
* SPSite
  * Added ability to check and update QuotaTemplate, OwnerAlias and SecondaryOwnerAlias
* SPSiteUrl
  * New resource to manage site collection urls for host named site collections
* SPTrustedIdentityTokenIssuerProviderRealm
  * Fixed issue where Get method threw an error when the realm didn't exist yet
* SPUserProfileServiceApp
  * Fix for issue where an update conflict error was thrown when new service
    application was created
  * Added SiteNamingConflictResolution parameter to the resource

## 2.4

* SPCacheAccounts
  * Fixed issue where the Test method would fail if SetWebAppPolicy was set to
    false.
* SPDistributedCacheService
  * Updated resource to allow updating the cache size
* SPFarm
  * Implemented ability to deploy Central Administration site to a server at a
    later point in time
* SPInfoPathFormsServiceConfig
  * Fixed issue with trying to set the MaxSizeOfUserFormState parameter
* SPProductUpdate
  * Fixed an issue where the resource failed when the search was already paused
* SPProjectServerLicense
  * Fixed issue with incorrect detection of the license
* SPSearchContentSource
  * Fixed issue where the Get method returned a conversion error when the content
    source contained just one address
  * Fixed issue 840 where the parameter StartHour was never taken into account
* SPSearchServiceApp
  * Fixed issue where the service account was not set correctly when the service
    application was first created
  * Fixed issue where the Get method throws an error when the service app wasn't
    created properly
* SPSearchTopology
  * Fixed issue where Get method threw an error when the specified service
    application didn't exist yet.
* SPServiceAppSecurity
  * Fixed issue where error was thrown when no permissions were set on the
    service application
* SPShellAdmins
  * Updated documentation to specify required permissions for successfully using
    this resource
* SPTrustedIdentityTokenIssuerProviderRealms
  * Fixed code styling issues
* SPUserProfileServiceApp
  * Fixed code styling issues

## 2.3

* Changes to SharePointDsc
  * Added a Branches section to the README.md with Codecov and build badges for
    both master and dev branch.
* All Resources
  * Added information about the Resource Type in each ReadMe.md files.
* SPFarm
  * Fixed issue where the resource throws an exception if the farm already
    exists and the server has been joined using the FQDN (issue 795)
* SPTimerJobState
  * Fixed issue where the Set method for timerjobs deployed to multiple web
    applications failed.
* SPTrustedIdentityTokenIssuerProviderRealms
  * Added the resource.
* SPUserProfileServiceApp
  * Now supported specifying the host Managed path, and properly sets the host.
  * Changed error for running with Farm Account into being a warning
* SPUserProfileSyncConnection
  * Added support for filtering disabled users
  * Fixed issue where UseSSL was set to true resulted in an error
  * Fixed issue where the connection was recreated when the name contained a
    dot (SP2016)

## 2.2

* SPAlternateURL
  * If resource specifies Central Admin webapp and Default Zone, the existing
    AAM will be updated instead of adding a new one.
* SPContentDatabase
  * Fixed issue where mounting a content database which had to be upgraded
    resulted in a reboot.
* SPDistributedCacheClientSettings
  * Added the new resource
* SPFarmAdministrators
  * Fixed issue where member comparisons was case sensitive. This had
    to be case insensitive.
* SPManagedMetadataServiceApp
  * Fixed issue with creating the Content Type Hub on an existing MMS
    service app without Content Type Hub.
* SPManagedMetadataServiceAppDefault
  * Fixed issue where .GetType().FullName and TypeName were not used
    properly.
* SPTimerJobState
  * Updated description of WebAppUrl parameter to make it clear that
    "N/A" has to be used to specify a global timer job.
* SPUserProfileServiceApp
  * Fixed issue introduced in v2.0, where the Farm Account had to have
    local Administrator permissions for the resource to function properly.
  * Updated resource to retrieve the Farm account from the Managed Accounts
    instead of requiring it as a parameter.
* SPUserProfileSyncService
  * Fixed issue introduced in v2.0, where the Farm Account had to have
    local Administrator permissions for the resource to function properly.
  * Updated resource to retrieve the Farm account from the Managed Accounts
    instead of requiring it as a parameter.
  * The FarmAccount parameter is deprecated and no longer required. Is ignored
    in the code and will be removed in v3.0.
* SPVisioServiceApp
  * Fixed an issue where the proxy is not properly getting created

## 2.1

* General
  * Updated the integration tests for building the Azure environment
    * Works in any Azure environment.
    * Updated the SqlServer configuration to use SqlServerDsc version 10.0.0.0.
* SPAlternateURL
  * Added the ability to manage the Central Administration AAMs
* SPDiagnosticsProvider
  * Added the resource
* SPFarm
  * Corrected issue where ServerRole parameter is returned in SP2013
* SPInfoPathFormsServiceConfig
  * Added the resource
* SPInstallPrereqs
  * Fixed two typos in to be installed Windows features for SharePoint 2016
* SPSearchAutoritativePage
  * Added missing readme.md
* SPSearchCrawlerImpactRule
  * Fixed issue where an error was thrown when retrieving Crawl Impact rules
  * Added missing readme.md
* SPSearchCrawlMapping
  * Added missing readme.md
* SPSecureStoreServiceApp
  * Fixed issue in Get-TargetResource to return AuditingEnabled property
* SPSecurityTokenServiceConfig
  * Added the resource
* SPServiceIdentity
  * Fixed issue with correctly retrieving the process identity for the
    Search instance
  * Added support for LocalSystem, LocalService and NetworkService
* SPUserProfileProperty
  * Fixed issues with the User Profile properties for 2016
* SPUserProfileServiceAppPermissions
  * Removed the mandatory requirement from secondary parameters
* SPUserProfileSyncConnection
  * Fixed issues with the User Profile Sync connection for SharePoint
    2016
* SPUserProfileSyncService
  * Added returning the FarmAccount to the Get method
* SPWebAppAuthentication
  * Corrected issue where parameter validation wasn't performed correctly
* SPWebApplicationExtension
  * Fixed issue with test always failing when Ensure was set to Absent
* SPWorkManagementServiceApp
  * Added check for SharePoint 2016, since this functionality has been
    removed in SharePoint 2016

## 2.0

* General
  * Added VSCode workspace settings to meet coding guidelines
  * Corrected comment in CodeCov.yml
  * Fixed several PSScriptAnalyzer warnings
* SPAppManagementServiceApp
  * Fixed an issue where the instance name wasn't detected correctly
* SPBCSServiceApp
  * Added custom Proxy Name support
  * Fixed an issue where the instance name wasn't detected correctly
* SPBlobCacheSettings
  * Update to set non-default or missing blob cache properties
* SPContentDatabase
  * Fixed localized issue
* SPDesignerSettings
  * Fixed issue where URL with capitals were not accepted correctly
* SPDistributedCacheService
  * Fixed issue where reprovisioning the Distributed Cache
    did not work
* SPFarm
  * Implemented ToDo to return Central Admin Auth mode
  * Fixed an issue where the instance name wasn't detected correctly
* SPInstall
  * Updated to document the requirements for an English ISO
* SPInstallPrereqs
  * Updated to document which parameter is required for which
    version of SharePoint
  * Added SharePoint 2016 example
* SPLogLevel
  * New resource
* SPMachineTranslationServiceApp
  * Added custom Proxy Name support
  * Fixed an issue where the instance name wasn't detected correctly
* SPManagedMetadataAppDefault
  * New resource
* SPManagedMetadataServiceApp
  * Update to allow the configuration of the default and
    working language
  * Fixed issue where the termstore could not be retrieved if the
    MMS service instance was stopped
  * Fixed an issue where the instance name wasn't detected correctly
* SPMinRoleCompliance
  * New resource
* SPPerformancePointServiceApp
  * Fixed an issue where the instance name wasn't detected correctly
* SPProjectServer
  * New resources to add Project Server 2016 support:
  SPProjectServerLicense, SPProjectServerAdditionalSettings,
  SPProjectServerADResourcePoolSync, SPProjectServerGlobalPermissions,
  SPProjectServerGroup, SPProjectServerTimeSheetSettings,
  SPProjectServerUserSyncSettings, SPProjectServerWssSettings
* SPSearchContentSource
  * Fixed examples
* SPSearchIndexPartition
  * Fixed to return the RootFolder parameter
* SPSearchServiceApp
  * Fixed an issue where the instance name wasn't detected correctly
* SPSearchTopology
  * Updated to better document how the resource works
  * Fixed issue to only return first index partition to prevent
    conflicts with SPSearchIndexPartition
* SPSecureStoreServiceApp
  * Fixed issue with not returning AuditEnabled parameter in Get method
  * Fixed an issue where the instance name wasn't detected correctly
* SPServiceAppSecurity
  * Fixed issue with NullException when no accounts are configured
    in SharePoint
* SPStateServiceApp
  * Added custom Proxy Name support
  * Fixed an issue where the instance name wasn't detected correctly
* SPSubscriptionSettings
  * Fixed an issue where the instance name wasn't detected correctly
* SPTrustedRootAuthority
  * Updated to enable using private key certificates.
* SPUsageApplication
  * Fixed an issue where the instance name wasn't detected correctly
* SPUserProfileProperty
  * Fixed two NullException issues
* SPUserProfileServiceApp
  * Fixed an issue where the instance name wasn't detected correctly
* SPUserProfileSynConnection
  * Fix an issue with ADImportConnection
* SPWeb
  * Update to allow the management of the access requests settings
* SPWebAppGeneralSettings
  * Added DefaultQuotaTemplate parameter
* SPWebApplicationExtension
  * Update to fix how property AllowAnonymous is returned in the
    hashtable
* SPWebAppPeoplePickerSettings
  * New resource
* SPWebAppPolicy
  * Fixed issue where the SPWebPolicyPermissions couldn't be used
    twice with the exact same values
* SPWebAppSuiteBar
  * New resource
* SPWebApplication.Throttling
  * Fixed issue with where the RequestThrottling parameter was
    not applied
* SPWordAutomationServiceApp
  * Fixed an issue where the instance name wasn't detected correctly
* SPWorkflowService
  * New resource

The following changes will break 1.x configurations that use these resources:

* SPAlternateUrl
  * Added the Internal parameter, which implied a change to the key parameters
* SPCreateFarm
  * Removed resource, please update your configurations to use SPFarm.
    See http://aka.ms/SPDsc-SPFarm for details.
* SPJoinFarm
  * Removed resource, please update your configurations to use SPFarm.
    See http://aka.ms/SPDsc-SPFarm for details.
* SPManagedMetadataServiceApp
  * Changed implementation of resource. This resource will not set any defaults
    for the keyword and site collection term store. The new resource
    SPManagedMetadataServiceAppDefault has to be used for this setting.
* SPShellAdmin
  * Updated so it also works for non-content databases
* SPTimerJobState
  * Updated to make the WebAppUrl parameter a key parameter.
    The resource can now be used to configure the same job for multiple
    web applications. Also changed the Name parameter to TypeName, due to
    a limitation with the SPTimerJob cmdlets
* SPUserProfileProperty
  * Fixed an issue where string properties were not created properly
* SPUSerProfileServiceApp
  * Updated to remove the requirement for CredSSP
* SPUserProfileSyncService
  * Updated to remove the requirement for CredSSP
* SPWebAppAuthentication
  * New resource
* SPWebApplication
  * Changed implementation of the Web Application authentication configuration.
    A new resource has been added and existing properties have been removed
* SPWebApplicationExtension
  * Updated so it infers the UseSSL value from the URL
  * Changed implementation of the Web Application authentication configuration.
    A new resource has been added and existing properties have been removed

## 1.9

* New resource: SPServiceIdentity

## 1.8

* Fixed issue in SPServiceAppProxyGroup causing some service names to return as null
* Added TLS and SMTP port support for SharePoint 2016
* Fixed issue in SPWebApplication where the Get method didn't return Classic
  web applications properly
* Fixed issue in SPSubscriptionSettingsServiceApp not returning database values
* Updated Readme of SPInstall to include SharePoint Foundation is not supported
* Fixed issue with Access Denied in SPDesignerSettings
* Fixed missing brackets in error message in SPExcelServiceApp
* Removed the requirement for the ConfigWizard in SPInstallLanguagePack
* Fixed Language Pack detection issue in SPInstallLanguagePack
* Added support to set Windows service accounts for search related services to
  SPSearchServiceApp resource
* Fixed issue in SPCreateFarm and SPJoinFarm where an exception was not handled
  correctly
* Fixed issue in SPSessionStateService not returning correct database server
  and name
* Fixed missing Ensure property default in SPRemoteFarmTrust
* Fixed issue in SPWebAppGeneralSettings where -1 was returned for the TimeZone
* Fixed incorrect UsagePoint check in SPQuotaTemplate
* Fixed issue in SPWebAppPolicy module where verbose messages are causing errors
* Fixed incorrect parameter naming in Get method of SPUserProfilePropery
* Fixed issue in SPBlobCacheSettings when trying to declare same URL with
  different zone
* Improve documentation on SPProductUpdate to specify the need to unblock downloaded
  files
* Added check if file is blocked in SPProductUpdate to prevent endless wait
* Enhance SPUserProfileServiceApp to allow for NoILM to be enabled
* Fixed issue in SPUserProfileProperty where PropertyMapping was Null

## 1.7

* Update SPSearchIndexPartition made ServiceAppName as a Key
* New resouce: SPTrustedRootAuthority
* Update SPFarmSolution to eject from loop after 30m.
* New resource: SPMachineTranslationServiceApp
* New resource: SPPowerPointAutomationServiceApp
* Bugfix in SPSearchFileType  made ServiceAppName a key property.
* New resource: SPWebApplicationExtension
* Added new resource SPAccessServices2010
* Added MSFT_SPSearchCrawlMapping Resource to manage Crawl Mappings for
  Search Service Application
* Added new resource SPSearchAuthoritativePage
* Bugfix in SPWebAppThrottlingSettings for setting large list window time.
* Fix typo in method Get-TargetResource of SPFeature
* Fix bug in SPManagedAccount not returning the correct account name value
* Fix typo in method Get-TargetResource of SPSearchIndexPartition
* Update documentation of SPInstallLanguagePack to add guidance on package
  change in SP2016
* Added returning the required RunCentralAdmin parameter to
  Get-TargetResource in SPFarm
* Added web role check for SPBlobCacheSettings
* Improved error message when rule could not be found in
  SPHealthAnalyzerRuleState
* Extended the documentation to specify that the default value of Ensure
  is Present
* Added documentation about the user of Host Header Site Collections and
  the HostHeader parameter in SPWebApplication
* Fixed missing brackets in SPWebAppPolicy module file
* Fixed issue with SPSecureStoreServiceApp not returning database information
* Fixed issue with SPManagedMetadataServiceApp not returning ContentTypeHubUrl
  in SP2016
* Updated SPTrustedIdentityTokenIssuer to allow to specify the signing
  certificate from file path as an alternative to the certificate store
* New resource: SPSearchCrawlerImpactRule
* Fixed issue in SPSite where the used template wasn't returned properly
* Fixed issue in SPWebApplicationGeneralSettings which didn't return the
  security validation timeout properly
* Fixed bug in SPCreateFarm and SPJoinFarm when a SharePoint Server is already
  joined to a farm
* Bugfix in SPContentDatabase for setting WarningSiteCount as 0.
* Fixing verbose message that identifies SP2016 as 2013 in MSFT_SPFarm
* Fixed SPProductUpdate looking for OSearch15 in SP2016 when stopping services
* Added TermStoreAdministrators property to SPManagedMetadataServiceApp
* Fixed an issue in SPSearchTopology that would leave a corrupt topology in
  place if a server was removed and re-added to a farm
* Fixed bug in SPFarm that caused issues with database names that have dashes
  in the names

## 1.6

* Updated SPWebApplication to allow Claims Authentication configuration
* Updated documentation in regards to guidance on installing binaries from
  network locations instead of locally
* New resources: SPFarmPropertyBag
* Bugfix in SPSite, which wasn't returing the quota template name in a correct way
* Bugfix in SPAppManagementServiceApp which wasn't returning the correct database
  name
* Bugfix in SPAccessServiceApp which did not return the database server
* Bugfix in SPDesignerSettings which filtered site collections with an incorrect
  parameter
* Updated the parameters in SPFarmSolution to use the full namespace
* Bugfix in SPFarmsolution where it returned non declared parameters
* Corrected typo in parameter name in Get method of SPFeature
* Added check in SPHealAnalyzerRuleState for incorrect default rule schedule of
  one rule
* Improved check for CloudSSA in SPSearchServiceApp
* Bugfix in SPSearchServiceApp in which the database and dbserver were not
  returned correctly
* Improved runtime of SPSearchTopology by streamlining wait processes
* Fixed bug with SPSearchServiceApp that would throw an error about SDDL string
* Improved output of test results for AppVeyor and VS Code based test runs
* Fixed issue with SPWebAppPolicy if OS language is not En-Us
* Added SPFarm resource, set SPCreateFarm and SPJoinFarm as deprecated to be
  removed in version 2.0

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
