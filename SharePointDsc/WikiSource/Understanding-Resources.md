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
|_[SPAccessServiceApp](SPAccessServiceApp)_ | Distributed | - |
|_[SPAccessServices2010](SPAccessServices2010)_ | Distributed | - |
|_[SPAlternateUrl](SPAlternateUrl)_ | Distributed | - |
|_[SPAntivirusSettings](SPAntivirusSettings)_ | Distributed | - |
|_[SPAppCatalog](SPAppCatalog)_ | Distributed | Yes |
|_[SPAppDomain](SPAppDomain)_ | Distributed | - |
|_[SPAppManagementServiceApp](SPAppManagementServiceApp)_ | Distributed | - |
|_[SPAppStoreSettings](SPAppStoreSettings)_ | Distributed | - |
|_[SPAuthenticationRealm](SPAuthenticationRealm)_ | Distributed | - |
|_[SPAzureAccessControlServiceAppProxy](SPAzureAccessControlServiceAppProxy)_ | Distributed | - |
|_[SPBCSServiceApp](SPBCSServiceApp)_ | Distributed | - |
|_[SPBlobCacheSettings](SPBlobCacheSettings)_ | Specific | - |
|_[SPCacheAccounts](SPCacheAccounts)_ | Distributed | - |
|_[SPCertificate](SPCertificate)_ | Distributed | - |
|_[SPCertificateSettings](SPCertificate)_ | Distributed | - |
|_[SPConfigWizard](SPConfigWizard)_ | Utility | - |
|_[SPContentDatabase](SPContentDatabase)_ | Distributed | - |
|_[SPDatabaseAAG](SPDatabaseAAG)_ | Distributed | - |
|_[SPDesignerSettings](SPDesignerSettings)_ | Distributed | - |
|_[SPDiagnosticLoggingSettings](SPDiagnosticLoggingSettings)_ | Distributed | - |
|_[SPDiagnosticsProvider](SPDiagnosticsProvider)_ | Distributed | - |
|_[SPDistributedCacheClientSettings](SPDistributedCacheClientSettings)_ | Distributed | - |
|_[SPDistributedCacheService](SPDistributedCacheService)_ | Specific | - |
|_[SPDocIcon](SPDocIcon)_ | Common | - |
|_[SPExcelServiceApp](SPExcelServiceApp)_ | Distributed | - |
|_[SPFarm](SPFarm)_ | Specific | - |
|_[SPFarmAdministrators](SPFarmAdministrators)_ | Distributed | - |
|_[SPFarmPropertyBag](SPFarmPropertyBag)_ | Distributed | - |
|_[SPFarmSolution](SPFarmSolution)_ | Distributed | - |
|_[SPFeature](SPFeature)_ | Distributed | - |
|_[SPHealthAnalyzerRuleState](SPHealthAnalyzerRuleState)_ | Distributed | - |
|_[SPIncomingEmailSettings](SPIncomingEmailSettings)_ | Distributed | - |
|_[SPInfoPathFormsServiceConfig](SPInfoPathFormsServiceConfig)_ | Distributed | - |
|_[SPInstall](SPInstall)_ | Common | - |
|_[SPInstallLanguagePack](SPInstallLanguagePack)_ | Common | - |
|_[SPInstallPrereqs](SPInstallPrereqs)_ | Common | - |
|_[SPIrmSettings](SPIrmSettings)_ | Distributed | - |
|_[SPLogLevel](SPLogLevel)_ | Distributed | - |
|_[SPMachineTranslationServiceApp](SPMachineTranslationServiceApp)_ | Distributed | - |
|_[SPManagedAccount](SPManagedAccount)_ | Distributed | - |
|_[SPManagedMetaDataServiceApp](SPManagedMetaDataServiceApp)_ | Distributed | - |
|_[SPManagedMetaDataServiceAppDefault](SPManagedMetaDataServiceAppDefault)_ | Distributed | - |
|_[SPManagedPath](SPManagedPath)_ | Distributed | - |
|_[SPMinRoleCompliance](SPMinRoleCompliance)_ | Utility | - |
|_[SPOAppPrincipalMgmtServiceAppProxy](SPOAppPrincipalMgmtServiceAppProxy)_ | Distributed | - |
|_[SPOfficeOnlineServerBinding](SPOfficeOnlineServerBinding)_ | Distributed | - |
|_[SPOfficeOnlineServerSupressionSettings](SPOfficeOnlineServerSupressionSettings)_ | Distributed | - |
|_[SPOutgoingEmailSettings](SPOutgoingEmailSettings)_ | Distributed | - |
|_[SPPasswordChangeSettings](SPPasswordChangeSettings)_ | Distributed | - |
|_[SPPerformancePointServiceApp](SPPerformancePointServiceApp)_ | Distributed | - |
|_[SPPowerPointAutomationServiceApp](SPPowerPointAutomationServiceApp)_ | Distributed | - |
|_[SPProductUpdate](SPProductUpdate)_ | Common | - |
|_[SPProjectServerAdditionalSettings](SPProjectServerAdditionalSettings)_ | Distributed | - |
|_[SPProjectServerADResourcePoolSync](SPProjectServerADResourcePoolSync)_ | Distributed | - |
|_[SPProjectServerGlobalPermissions](SPProjectServerGlobalPermissions)_ | Distributed | - |
|_[SPProjectServerGroup](SPProjectServerGroup)_ | Distributed | - |
|_[SPProjectServerLicense](SPProjectServerLicense)_ | Distributed | - |
|_[SPProjectServerPermissionMode](SPProjectServerPermissionMode)_ | Distributed | - |
|_[SPProjectServerServiceApp](SPProjectServerServiceApp)_ | Distributed | - |
|_[SPProjectServerTimeSheetSettings](SPProjectServerTimeSheetSettings)_ | Distributed | - |
|_[SPProjectServerUserSyncSettings](SPProjectServerUserSyncSettings)_ | Distributed | - |
|_[SPProjectServerWssSettings](SPProjectServerWssSettings)_ | Distributed | - |
|_[SPPublishServiceApplication](SPPublishServiceApplication)_ | Distributed | - |
|_[SPQuotaTemplate](SPQuotaTemplate)_ | Distributed | - |
|_[SPRemoteFarmTrust](SPRemoteFarmTrust)_ | Distributed | - |
|_[SPSearchAuthoritivePage](SPSearchAuthoritivePage)_ | Distributed | - |
|_[SPSearchContentSource](SPSearchContentSource)_ | Distributed | - |
|_[SPSearchCrawlerImpactRule](SPSearchCrawlerImpactRule)_ | Distributed | - |
|_[SPSearchCrawlMapping](SPSearchCrawlMapping)_ | Distributed | - |
|_[SPSearchCrawlRule](SPSearchCrawlRule)_ | Distributed | - |
|_[SPSearchFileType](SPSearchFileType)_ | Distributed | - |
|_[SPSearchIndexPartition](SPSearchIndexPartition)_ | Distributed | - |
|_[SPSearchManagedProperty](SPSearchManagedProperty)_ | Distributed | - |
|_[SPSearchMetadataCategory](SPSearchMetadataCategory)_ | Distributed | - |
|_[SPSearchResultSource](SPSearchResultSource)_ | Distributed | - |
|_[SPSearchServiceApp](SPSearchServiceApp)_ | Distributed | - |
|_[SPSearchServiceSettings](SPSearchServiceSettings)_ | Distributed | - |
|_[SPSearchTopology](SPSearchTopology)_ | Distributed | - |
|_[SPSecureStoreServiceApp](SPSecureStoreServiceApp)_ | Distributed | - |
|_[SPSecurityTokenServiceConfig](SPSecurityTokenServiceConfig)_ | Distributed | - |
|_[SPSelfServiceSiteCreation](SPSelfServiceSiteCreation)_ | Distributed | - |
|_[SPService](SPService)_ | Distributed | - |
|_[SPServiceAppPool](SPServiceAppPool)_ | Distributed | - |
|_[SPServiceAppProxyGroup](SPServiceAppProxyGroup)_ | Distributed | - |
|_[SPServiceAppSecurity](SPServiceAppSecurity)_ | Distributed | - |
|_[SPServiceIdentity](SPServiceIdentity)_ | Distributed | - |
|_[SPServiceInstance](SPServiceInstance)_ | Specific | - |
|_[SPSessionStateService](SPSessionStateService)_ | Distributed | - |
|_[SPShellAdmins](SPShellAdmins)_ | Distributed | - |
|_[SPSite](SPSite)_ | Distributed | - |
|_[SPSitePropertyBag](SPSitePropertyBag)_ | Distributed | - |
|_[SPSiteUrl](SPSiteUrl)_ | Distributed | - |
|_[SPStateServiceApp](SPStateServiceApp)_ | Distributed | - |
|_[SPSubscriptionSettingsServiceApp](SPSubscriptionSettingsServiceApp)_ | Distributed | - |
|_[SPTimerJobState](SPTimerJobState)_ | Distributed | - |
|_[SPTrustedIdentityTokenIssuer](SPTrustedIdentityTokenIssuer)_ | Distributed | - |
|_[SPTrustedIdentityTokenIssuerProviderRealms](SPTrustedIdentityTokenIssuerProviderRealms)_ | Distributed | - |
|_[SPTrustedRootAuthority](SPTrustedRootAuthority)_ | Distributed | - |
|_[SPTrustedSecurityTokenIssuer](SPTrustedSecurityTokenIssuer)_ | Distributed | - |
|_[SPUsageApplication](SPUsageApplication)_ | Distributed | - |
|_[SPUsageDefinition](SPUsageDefinition)_ | Distributed | - |
|_[SPUserProfileProperty](SPUserProfileProperty)_ | Distributed | - |
|_[SPUserProfileSection](SPUserProfileSection)_ | Distributed | - |
|_[SPUserProfileServiceApp](SPUserProfileServiceApp)_ | Distributed | - | Yes |
|_[SPUserProfileServiceAppPermissions](SPUserProfileServiceAppPermissions)_ | Distributed | - |
|_[SPUserProfileSyncConnection](SPUserProfileSyncConnection)_ | Distributed | - |
|_[SPUserProfileSyncService](SPUserProfileSyncService)_ | Specific | Yes |
|_[SPVisioServiceApp](SPVisioServiceApp)_ | Distributed | - |
|_[SPWeb](SPWeb)_ | Distributed | - |
|_[SPWebAppAuthentication](SPWebAppAuthentication)_ | Distributed | - |
|_[SPWebAppBlockedFileTypes](SPWebAppBlockedFileTypes)_ | Distributed | - |
|_[SPWebAppClientCallableSettings](SPWebAppClientCallableSettings)_ | Distributed | - |
|_[SPWebAppGeneralSettings](SPWebAppGeneralSettings)_ | Distributed | - |
|_[SPWebAppHttpThrottlingMonitor](SPWebAppHttpThrottlingMonitor)_ | Distributed | - |
|_[SPWebApplication](SPWebApplication)_ | Distributed | - |
|_[SPWebApplicationAppDomain](SPWebApplicationAppDomain)_ | Distributed | - |
|_[SPWebApplicationExtension](SPWebApplicationExtension)_ | Distributed | - |
|_[SPWebAppPeoplePickerSettings](SPWebAppPeoplePickerSettings)_ | Distributed | - |
|_[SPWebAppPermissions](SPWebAppPermissions)_ | Distributed | - |
|_[SPWebAppPolicy](SPWebAppPolicy)_ | Distributed | - |
|_[SPWebAppPropertyBag](SPWebAppPropertyBag)_ | Distributed | - |
|_[SPWebAppProxyGroup](SPWebAppProxyGroup)_ | Distributed | - |
|_[SPWebAppSiteUseAndDeletion](SPWebAppSiteUseAndDeletion)_ | Distributed | - |
|_[SPWebAppSuiteBar](SPWebAppSuiteBar)_ | Distributed | - |
|_[SPWebAppThrottlingSettings](SPWebAppThrottlingSettings)_ | Distributed | - |
|_[SPWebAppWorkflowSettings](SPWebAppWorkflowSettings)_ | Distributed | - |
|_[SPWordAutomationServiceApp](SPWordAutomationServiceApp)_ | Distributed | - |
|_[SPWorkflowService](SPWorkflowService)_ | Distributed | - |
|_[SPWorkManagementServiceApp](SPWorkManagementServiceApp)_ | Distributed | - |

## Using the Script resource in configurations with SharePointDsc

Check-out this [article](Using-the-Script-resource-in-configurations-that-use-SharePointDsc) if you want to use the Script resource to implement custom functionality that is not included in SharePointDsc.

> Of course you can also create an issue in the issue list to request the functionality to be added. Sharing code that you already have will greatly speed up the development effort.
