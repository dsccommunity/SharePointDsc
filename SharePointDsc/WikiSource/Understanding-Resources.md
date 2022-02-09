# Resource Types

## Common Resources

These resources need to be defined within every node in the farm. The parameters specify for the resources associated with Common Resources should be the same for each server (e.g. the same language packs need to be installed on all servers in the farm). As an example, the SPInstall resource, which installs the SharePoint binaries on a server, needs to be present within every node in the farm. It is not enough to have only one server with the binaries installed on in a multi-server farm. Common Resources are identified in the list below with the mention **Common**.

## Specific Resources

Just like the Common Resources, the Specific Resources need to be included within every node in the farm. Their only difference, compare to Common Resources, is that the resources' parameters may differ from one node to another in the farm. As an example, the SPServiceInstance resource, which allows us to enable specific services on a SharePoint Server, will be specified for each server in the farm, but with different "Ensure" value to allow certain services to be started on specific servers, but not on others. Specific Resources are identified in the list below with the mention **Specific**.

## Distributed Resources

This category covers the major part of the resources. Distributed Resources should ONLY be defined within ONE node in the farm. As the name states it, those are distributed which means that resources of this type are normally stored in a central database. Specifying these resources on more than one node in the farm may introduce unexpected behaviors (race condition, performance issues, etc.). For example, if you wanted to create a new Web Application using the traditional PowerShell approach, you would pick one server and run the New-SPWebApplication cmdlet on it, you would not run it on each of the servers in the farm. To define these resources, identify one server in your configuration (e.g. the first server to create/join the farm), and define all the Distributed Resources within it. Distributed Resources are identified in the list below with the mention **Distributed**.

## Utility Resources

Utility Resources are resources that do not generate an artefact per say. Their sole purpose is to help you initiate a check or apply a patch. As an example, the SPMinRoleCompliance resource simply returns true or false (in its Test-TargetResource function) if the services running on a server correspond to the services that are associated with its assigned MinRole. It does not enable, disable or even create any service instances. Utility Resources are identified in the list below with the mention **Utility** .

# Available resources

The SharePointDsc module includes the following DSC resources

|Resource|Type|Requires CredSSP|
|--|--|--|
|[SPAccessServiceApp](SPAccessServiceApp) | Distributed | - |
|[SPAccessServices2010](SPAccessServices2010) | Distributed | - |
|[SPAlternateUrl](SPAlternateUrl) | Distributed | - |
|[SPAntivirusSettings](SPAntivirusSettings) | Distributed | - |
|[SPAppCatalog](SPAppCatalog) | Distributed | Yes |
|[SPAppDomain](SPAppDomain) | Distributed | - |
|[SPAppManagementServiceApp](SPAppManagementServiceApp) | Distributed | - |
|[SPAppStoreSettings](SPAppStoreSettings) | Distributed | - |
|[SPAuthenticationRealm](SPAuthenticationRealm) | Distributed | - |
|[SPAzureAccessControlServiceAppProxy](SPAzureAccessControlServiceAppProxy) | Distributed | - |
|[SPBCSServiceApp](SPBCSServiceApp) | Distributed | - |
|[SPBlobCacheSettings](SPBlobCacheSettings) | Specific | - |
|[SPCacheAccounts](SPCacheAccounts) | Distributed | - |
|[SPCertificate](SPCertificate) | Distributed | - |
|[SPCertificateSettings](SPCertificate) | Distributed | - |
|[SPConfigWizard](SPConfigWizard) | Utility | - |
|[SPContentDatabase](SPContentDatabase) | Distributed | - |
|[SPDatabaseAAG](SPDatabaseAAG) | Distributed | - |
|[SPDesignerSettings](SPDesignerSettings) | Distributed | - |
|[SPDiagnosticLoggingSettings](SPDiagnosticLoggingSettings) | Distributed | - |
|[SPDiagnosticsProvider](SPDiagnosticsProvider) | Distributed | - |
|[SPDistributedCacheClientSettings](SPDistributedCacheClientSettings) | Distributed | - |
|[SPDistributedCacheService](SPDistributedCacheService) | Specific | - |
|[SPDocIcon](SPDocIcon) | Common | - |
|[SPExcelServiceApp](SPExcelServiceApp) | Distributed | - |
|[SPFarm](SPFarm) | Specific | - |
|[SPFarmAdministrators](SPFarmAdministrators) | Distributed | - |
|[SPFarmPropertyBag](SPFarmPropertyBag) | Distributed | - |
|[SPFarmSolution](SPFarmSolution) | Distributed | - |
|[SPFeature](SPFeature) | Distributed | - |
|[SPHealthAnalyzerRuleState](SPHealthAnalyzerRuleState) | Distributed | - |
|[SPIncomingEmailSettings](SPIncomingEmailSettings) | Distributed | - |
|[SPInfoPathFormsServiceConfig](SPInfoPathFormsServiceConfig) | Distributed | - |
|[SPInstall](SPInstall) | Common | - |
|[SPInstallLanguagePack](SPInstallLanguagePack) | Common | - |
|[SPInstallPrereqs](SPInstallPrereqs) | Common | - |
|[SPIrmSettings](SPIrmSettings) | Distributed | - |
|[SPLogLevel](SPLogLevel) | Distributed | - |
|[SPMachineTranslationServiceApp](SPMachineTranslationServiceApp) | Distributed | - |
|[SPManagedAccount](SPManagedAccount) | Distributed | - |
|[SPManagedMetaDataServiceApp](SPManagedMetaDataServiceApp) | Distributed | - |
|[SPManagedMetaDataServiceAppDefault](SPManagedMetaDataServiceAppDefault) | Distributed | - |
|[SPManagedPath](SPManagedPath) | Distributed | - |
|[SPMinRoleCompliance](SPMinRoleCompliance) | Utility | - |
|[SPOAppPrincipalMgmtServiceAppProxy](SPOAppPrincipalMgmtServiceAppProxy) | Distributed | - |
|[SPOfficeOnlineServerBinding](SPOfficeOnlineServerBinding) | Distributed | - |
|[SPOfficeOnlineServerSupressionSettings](SPOfficeOnlineServerSupressionSettings) | Distributed | - |
|[SPOutgoingEmailSettings](SPOutgoingEmailSettings) | Distributed | - |
|[SPPasswordChangeSettings](SPPasswordChangeSettings) | Distributed | - |
|[SPPerformancePointServiceApp](SPPerformancePointServiceApp) | Distributed | - |
|[SPPowerPointAutomationServiceApp](SPPowerPointAutomationServiceApp) | Distributed | - |
|[SPProductUpdate](SPProductUpdate) | Common | - |
|[SPProjectServerAdditionalSettings](SPProjectServerAdditionalSettings) | Distributed | - |
|[SPProjectServerADResourcePoolSync](SPProjectServerADResourcePoolSync) | Distributed | - |
|[SPProjectServerGlobalPermissions](SPProjectServerGlobalPermissions) | Distributed | - |
|[SPProjectServerGroup](SPProjectServerGroup) | Distributed | - |
|[SPProjectServerLicense](SPProjectServerLicense) | Distributed | - |
|[SPProjectServerPermissionMode](SPProjectServerPermissionMode) | Distributed | - |
|[SPProjectServerServiceApp](SPProjectServerServiceApp) | Distributed | - |
|[SPProjectServerTimeSheetSettings](SPProjectServerTimeSheetSettings) | Distributed | - |
|[SPProjectServerUserSyncSettings](SPProjectServerUserSyncSettings) | Distributed | - |
|[SPProjectServerWssSettings](SPProjectServerWssSettings) | Distributed | - |
|[SPPublishServiceApplication](SPPublishServiceApplication) | Distributed | - |
|[SPQuotaTemplate](SPQuotaTemplate) | Distributed | - |
|[SPRemoteFarmTrust](SPRemoteFarmTrust) | Distributed | - |
|[SPSearchAuthoritivePage](SPSearchAuthoritivePage) | Distributed | - |
|[SPSearchContentSource](SPSearchContentSource) | Distributed | - |
|[SPSearchCrawlerImpactRule](SPSearchCrawlerImpactRule) | Distributed | - |
|[SPSearchCrawlMapping](SPSearchCrawlMapping) | Distributed | - |
|[SPSearchCrawlRule](SPSearchCrawlRule) | Distributed | - |
|[SPSearchFileType](SPSearchFileType) | Distributed | - |
|[SPSearchIndexPartition](SPSearchIndexPartition) | Distributed | - |
|[SPSearchManagedProperty](SPSearchManagedProperty) | Distributed | - |
|[SPSearchMetadataCategory](SPSearchMetadataCategory) | Distributed | - |
|[SPSearchResultSource](SPSearchResultSource) | Distributed | - |
|[SPSearchServiceApp](SPSearchServiceApp) | Distributed | - |
|[SPSearchServiceSettings](SPSearchServiceSettings) | Distributed | - |
|[SPSearchTopology](SPSearchTopology) | Distributed | - |
|[SPSecureStoreServiceApp](SPSecureStoreServiceApp) | Distributed | - |
|[SPSecurityTokenServiceConfig](SPSecurityTokenServiceConfig) | Distributed | - |
|[SPSelfServiceSiteCreation](SPSelfServiceSiteCreation) | Distributed | - |
|[SPService](SPService) | Distributed | - |
|[SPServiceAppPool](SPServiceAppPool) | Distributed | - |
|[SPServiceAppProxyGroup](SPServiceAppProxyGroup) | Distributed | - |
|[SPServiceAppSecurity](SPServiceAppSecurity) | Distributed | - |
|[SPServiceIdentity](SPServiceIdentity) | Distributed | - |
|[SPServiceInstance](SPServiceInstance) | Specific | - |
|[SPSessionStateService](SPSessionStateService) | Distributed | - |
|[SPShellAdmins](SPShellAdmins) | Distributed | - |
|[SPSite](SPSite) | Distributed | - |
|[SPSitePropertyBag](SPSitePropertyBag) | Distributed | - |
|[SPSiteUrl](SPSiteUrl) | Distributed | - |
|[SPStateServiceApp](SPStateServiceApp) | Distributed | - |
|[SPSubscriptionSettingsServiceApp](SPSubscriptionSettingsServiceApp) | Distributed | - |
|[SPTimerJobState](SPTimerJobState) | Distributed | - |
|[SPTrustedIdentityTokenIssuer](SPTrustedIdentityTokenIssuer) | Distributed | - |
|[SPTrustedIdentityTokenIssuerProviderRealms](SPTrustedIdentityTokenIssuerProviderRealms) | Distributed | - |
|[SPTrustedRootAuthority](SPTrustedRootAuthority) | Distributed | - |
|[SPTrustedSecurityTokenIssuer](SPTrustedSecurityTokenIssuer) | Distributed | - |
|[SPUsageApplication](SPUsageApplication) | Distributed | - |
|[SPUsageDefinition](SPUsageDefinition) | Distributed | - |
|[SPUserProfileProperty](SPUserProfileProperty) | Distributed | - |
|[SPUserProfileSection](SPUserProfileSection) | Distributed | - |
|[SPUserProfileServiceApp](SPUserProfileServiceApp) | Distributed | - | Yes |
|[SPUserProfileServiceAppPermissions](SPUserProfileServiceAppPermissions) | Distributed | - |
|[SPUserProfileSyncConnection](SPUserProfileSyncConnection) | Distributed | - |
|[SPUserProfileSyncService](SPUserProfileSyncService) | Specific | Yes |
|[SPVisioServiceApp](SPVisioServiceApp) | Distributed | - |
|[SPWeb](SPWeb) | Distributed | - |
|[SPWebAppAuthentication](SPWebAppAuthentication) | Distributed | - |
|[SPWebAppBlockedFileTypes](SPWebAppBlockedFileTypes) | Distributed | - |
|[SPWebAppClientCallableSettings](SPWebAppClientCallableSettings) | Distributed | - |
|[SPWebAppGeneralSettings](SPWebAppGeneralSettings) | Distributed | - |
|[SPWebAppHttpThrottlingMonitor](SPWebAppHttpThrottlingMonitor) | Distributed | - |
|[SPWebApplication](SPWebApplication) | Distributed | - |
|[SPWebApplicationAppDomain](SPWebApplicationAppDomain) | Distributed | - |
|[SPWebApplicationExtension](SPWebApplicationExtension) | Distributed | - |
|[SPWebAppPeoplePickerSettings](SPWebAppPeoplePickerSettings) | Distributed | - |
|[SPWebAppPermissions](SPWebAppPermissions) | Distributed | - |
|[SPWebAppPolicy](SPWebAppPolicy) | Distributed | - |
|[SPWebAppPropertyBag](SPWebAppPropertyBag) | Distributed | - |
|[SPWebAppProxyGroup](SPWebAppProxyGroup) | Distributed | - |
|[SPWebAppSiteUseAndDeletion](SPWebAppSiteUseAndDeletion) | Distributed | - |
|[SPWebAppSuiteBar](SPWebAppSuiteBar) | Distributed | - |
|[SPWebAppThrottlingSettings](SPWebAppThrottlingSettings) | Distributed | - |
|[SPWebAppWorkflowSettings](SPWebAppWorkflowSettings) | Distributed | - |
|[SPWordAutomationServiceApp](SPWordAutomationServiceApp) | Distributed | - |
|[SPWorkflowService](SPWorkflowService) | Distributed | - |
|[SPWorkManagementServiceApp](SPWorkManagementServiceApp) | Distributed | - |

## Using the Script resource in configurations with SharePointDsc

Check-out this [article](Using-the-Script-resource-in-configurations-that-use-SharePointDsc) if you want to use the Script resource to implement custom functionality that is not included in SharePointDsc.

> Of course you can also create an issue in the issue list to request the functionality to be added. Sharing code that you already have will greatly speed up the development effort.