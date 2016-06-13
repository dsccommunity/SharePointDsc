Configuration SharePointServer
{
    param (
        [Parameter(Mandatory=$true)] [ValidateNotNullorEmpty()] [PSCredential] $FarmAccount,
        [Parameter(Mandatory=$true)] [ValidateNotNullorEmpty()] [PSCredential] $SPSetupAccount,
        [Parameter(Mandatory=$true)] [ValidateNotNullorEmpty()] [PSCredential] $WebPoolManagedAccount,
        [Parameter(Mandatory=$true)] [ValidateNotNullorEmpty()] [PSCredential] $ServicePoolManagedAccount,
        [Parameter(Mandatory=$true)] [ValidateNotNullorEmpty()] [PSCredential] $domainAdminCredential
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName SharePointDsc
    Import-DscResource -ModuleName xWebAdministration
    Import-DscResource -ModuleName xCredSSP

    node $AllNodes.NodeName
    {
        #**********************************************************
        # Server configuration
        #
        # This section of the configuration includes details of the
        # server level configuration, such as disks, registry
        # settings etc.
        #********************************************************** 

        xCredSSP CredSSPServer { Ensure = "Present"; Role = "Server"; DependsOn = "[xComputer]DomainJoin" } 
        xCredSSP CredSSPClient { Ensure = "Present"; Role = "Client"; DelegateComputers = "*.$($ConfigurationData.NonNodeData.DomainDetails.DomainName)"; DependsOn = "[xComputer]DomainJoin" }

        if ($Node.DisableIISLoopbackCheck -eq $true) {
            Registry DisableLoopBackCheck {
                Ensure = "Present"
                Key = "HKLM:\System\CurrentControlSet\Control\Lsa"
                ValueName = "DisableLoopbackCheck"
                ValueData = "1"
                ValueType = "Dword"
            }
        }


        #**********************************************************
        # IIS clean up
        #
        # This section removes all default sites and application
        # pools from IIS as they are not required
        #**********************************************************

        xWebAppPool RemoveDotNet2Pool         { Name = ".NET v2.0";            Ensure = "Absent"; }
        xWebAppPool RemoveDotNet2ClassicPool  { Name = ".NET v2.0 Classic";    Ensure = "Absent"; }
        xWebAppPool RemoveDotNet45Pool        { Name = ".NET v4.5";            Ensure = "Absent"; }
        xWebAppPool RemoveDotNet45ClassicPool { Name = ".NET v4.5 Classic";    Ensure = "Absent"; }
        xWebAppPool RemoveClassicDotNetPool   { Name = "Classic .NET AppPool"; Ensure = "Absent"; }
        xWebAppPool RemoveDefaultAppPool      { Name = "DefaultAppPool";       Ensure = "Absent"; }
        xWebSite    RemoveDefaultWebSite      { Name = "Default Web Site";     Ensure = "Absent"; PhysicalPath = "C:\inetpub\wwwroot"; }
        
        #**********************************************************
        # Install Binaries
        #
        # This section installs SharePoint and its Prerequisites
        #**********************************************************
        
        SPInstallPrereqs InstallPrereqs {
            Ensure            = "Present"
            InstallerPath     = (Join-Path $ConfigurationData.NonNodeData.SharePoint.Binaries.Path "prerequisiteinstaller.exe")
            OnlineMode        = $false
            SQLNCli           = (Join-Path $ConfigurationData.NonNodeData.SharePoint.Binaries.Prereqs.OfflineInstallDir "sqlncli.msi")
            PowerShell        = (Join-Path $ConfigurationData.NonNodeData.SharePoint.Binaries.Prereqs.OfflineInstallDir "Windows6.1-KB2506143-x64.msu")
            NETFX             = (Join-Path $ConfigurationData.NonNodeData.SharePoint.Binaries.Prereqs.OfflineInstallDir "dotnetfx45_full_x86_x64.exe")
            IDFX              = (Join-Path $ConfigurationData.NonNodeData.SharePoint.Binaries.Prereqs.OfflineInstallDir "Windows6.1-KB974405-x64.msu")
            Sync              = (Join-Path $ConfigurationData.NonNodeData.SharePoint.Binaries.Prereqs.OfflineInstallDir "Synchronization.msi")
            AppFabric         = (Join-Path $ConfigurationData.NonNodeData.SharePoint.Binaries.Prereqs.OfflineInstallDir "WindowsServerAppFabricSetup_x64.exe")
            IDFX11            = (Join-Path $ConfigurationData.NonNodeData.SharePoint.Binaries.Prereqs.OfflineInstallDir "MicrosoftIdentityExtensions-64.msi")
            MSIPCClient       = (Join-Path $ConfigurationData.NonNodeData.SharePoint.Binaries.Prereqs.OfflineInstallDir "setup_msipc_x64.msi")
            WCFDataServices   = (Join-Path $ConfigurationData.NonNodeData.SharePoint.Binaries.Prereqs.OfflineInstallDir "WcfDataServices.exe")
            KB2671763         = (Join-Path $ConfigurationData.NonNodeData.SharePoint.Binaries.Prereqs.OfflineInstallDir "AppFabric1.1-RTM-KB2671763-x64-ENU.exe")
            WCFDataServices56 = (Join-Path $ConfigurationData.NonNodeData.SharePoint.Binaries.Prereqs.OfflineInstallDir "WcfDataServices56.exe")
        }
        SPInstall InstallSharePoint {
            Ensure = "Present"
            BinaryDir = $ConfigurationData.NonNodeData.SharePoint.Binaries.Path
            ProductKey = $ConfigurationData.NonNodeData.SharePoint.ProductKey
            DependsOn = "[SPInstallPrereqs]InstallPrereqs"
        }

        #**********************************************************
        # Basic farm configuration
        #
        # This section creates the new SharePoint farm object, and
        # provisions generic services and components used by the
        # whole farm
        #**********************************************************

        # Determine the first app server and let it create the farm, all other servers will join that afterwards
        $FirstAppServer = ($AllNodes | Where-Object { $_.ServiceRoles.AppServer -eq $true } | Select-Object -First 1).NodeName

        if ($Node.NodeName -eq $FirstAppServer) {
            SPCreateFarm CreateSPFarm
            {
                DatabaseServer           = $ConfigurationData.NonNodeData.SQLServer.FarmDatabaseServer
                FarmConfigDatabaseName   = $ConfigurationData.NonNodeData.SharePoint.Farm.ConfigurationDatabase
                Passphrase               = $ConfigurationData.NonNodeData.SharePoint.Farm.Passphrase
                FarmAccount              = $FarmAccount
                PsDscRunAsCredential     = $SPSetupAccount
                AdminContentDatabaseName = $ConfigurationData.NonNodeData.SharePoint.Farm.AdminContentDatabase
                DependsOn                = "[SPInstall]InstallSharePoint"
            }

            $FarmWaitTask = "[SPCreateFarm]CreateSPFarm"
        } else {
            WaitForAll WaitForFarmToExist
            {
                ResourceName         = "[SPCreateFarm]CreateSPFarm"
                NodeName             = $FirstAppServer
                RetryIntervalSec     = 60
                RetryCount           = 60
                PsDscRunAsCredential = $SPSetupAccount
            }
            SPJoinFarm JoinSPFarm
            {
                DatabaseServer           = $ConfigurationData.NonNodeData.SQLServer.FarmDatabaseServer
                FarmConfigDatabaseName   = $ConfigurationData.NonNodeData.SharePoint.Farm.ConfigurationDatabase
                Passphrase               = $ConfigurationData.NonNodeData.SharePoint.Farm.Passphrase
                PsDscRunAsCredential     = $SPSetupAccount
                DependsOn                = "[WaitForAll]WaitForFarmToExist"
            }

            $FarmWaitTask = "[SPJoinFarm]JoinSPFarm"
        }


        # Apply farm wide configuration and logical components only on the first server
        if ($Node.NodeName -eq $FirstAppServer) {
            SPManagedAccount ServicePoolManagedAccount
            {
                AccountName          = $ServicePoolManagedAccount.UserName
                Account              = $ServicePoolManagedAccount
                PsDscRunAsCredential = $SPSetupAccount
                DependsOn            = $FarmWaitTask
            }
            SPManagedAccount WebPoolManagedAccount
            {
                AccountName          = $WebPoolManagedAccount.UserName
                Account              = $WebPoolManagedAccount
                PsDscRunAsCredential = $SPSetupAccount
                DependsOn            = $FarmWaitTask
            }
            SPDiagnosticLoggingSettings ApplyDiagnosticLogSettings
            {
                PsDscRunAsCredential                        = $SPSetupAccount
                LogPath                                     = $ConfigurationData.NonNodeData.SharePoint.DiagnosticLogs.Path
                LogSpaceInGB                                = $ConfigurationData.NonNodeData.SharePoint.DiagnosticLogs.MaxSize
                AppAnalyticsAutomaticUploadEnabled          = $false
                CustomerExperienceImprovementProgramEnabled = $true
                DaysToKeepLogs                              = $ConfigurationData.NonNodeData.SharePoint.DiagnosticLogs.DaysToKeep
                DownloadErrorReportingUpdatesEnabled        = $false
                ErrorReportingAutomaticUploadEnabled        = $false
                ErrorReportingEnabled                       = $false
                EventLogFloodProtectionEnabled              = $true
                EventLogFloodProtectionNotifyInterval       = 5
                EventLogFloodProtectionQuietPeriod          = 2
                EventLogFloodProtectionThreshold            = 5
                EventLogFloodProtectionTriggerPeriod        = 2
                LogCutInterval                              = 15
                LogMaxDiskSpaceUsageEnabled                 = $true
                ScriptErrorReportingDelay                   = 30
                ScriptErrorReportingEnabled                 = $true
                ScriptErrorReportingRequireAuth             = $true
                DependsOn                                   = @($FarmWaitTask, "[xDisk]LogsDisk")
            }
            SPUsageApplication UsageApplication 
            {
                Name                  = "Usage Service Application"
                DatabaseName          = $ConfigurationData.NonNodeData.SharePoint.UsageLogs.DatabaseName
                UsageLogCutTime       = 5
                UsageLogLocation      = $ConfigurationData.NonNodeData.SharePoint.UsageLogs.Path
                UsageLogMaxFileSizeKB = 1024
                PsDscRunAsCredential  = $SPSetupAccount
                DependsOn             = $FarmWaitTask
            }
            SPStateServiceApp StateServiceApp
            {
                Name                 = "State Service Application"
                DatabaseName         = $ConfigurationData.NonNodeData.SharePoint.StateService.DatabaseName
                PsDscRunAsCredential = $SPSetupAccount
                DependsOn            = $FarmWaitTask
            }

            SPOfficeOnlineServerBinding OosBinding
            {
                Zone                 = "internal-https"
                DnsName              = "office.contoso.com"
                Ensure               = "Present"
                PsDscRunAsCredential = $SPSetupAccount
                DependsOn            = $FarmWaitTask
            }
        }
        

        #**********************************************************
        # Distributed cache
        #
        # This section calculates which servers should be running
        # DCache and which servers they depend on
        #**********************************************************

        if ($Node.ServiceRoles.DistributedCache -eq $true) {
            $AllDCacheNodes = $AllNodes | Where-Object { $_.ServiceRoles.DistributedCache -eq $true }
            $CurrentDcacheNode = [Array]::IndexOf($AllDCacheNodes, $Node)

            if ($Node.NodeName -ne $FirstAppServer) {
                # Node is not the first app server so won't have the dependency for the service account
                WaitForAll WaitForServiceAccount 
                {
                    ResourceName         = "[SPManagedAccount]ServicePoolManagedAccount"
                    NodeName             = $FirstAppServer
                    RetryIntervalSec     = 60
                    RetryCount           = 20
                    PsDscRunAsCredential = $SPSetupAccount
                    DependsOn            = $FarmWaitTask 
                }
                $DCacheWaitFor = "[WaitForAll]WaitForServiceAccount"
            } else {
                $DCacheWaitFor = "[SPManagedAccount]ServicePoolManagedAccount"
            }

            if ($CurrentDcacheNode -eq 0) {
                # The first distributed cache node doesn't wait on anything
                SPDistributedCacheService EnableDistributedCache
                {
                    Name                 = "AppFabricCachingService"
                    Ensure               = "Present"
                    CacheSizeInMB        = 1024
                    ServiceAccount       = $ServicePoolManagedAccount.UserName
                    PsDscRunAsCredential = $SPSetupAccount
                    CreateFirewallRules  = $true
                    DependsOn            = @($FarmWaitTask,$DCacheWaitFor)
                }
            } else {
                # All other distributed cache nodes depend on the node previous to it
                $previousDCacheNode = $AllDCacheNodes[$CurrentDcacheNode - 1]
                WaitForAll WaitForDCache
                {
                    ResourceName         = "[SPDistributedCacheService]EnableDistributedCache"
                    NodeName             = $previousDCacheNode.NodeName
                    RetryIntervalSec     = 60
                    RetryCount           = 60
                    PsDscRunAsCredential = $SPSetupAccount
                    DependsOn            = $FarmWaitTask
                }
                SPDistributedCacheService EnableDistributedCache
                {
                    Name                 = "AppFabricCachingService"
                    Ensure               = "Present"
                    CacheSizeInMB        = 1024
                    ServiceAccount       = $ServicePoolManagedAccount.UserName
                    PsDscRunAsCredential = $SPSetupAccount
                    CreateFirewallRules  = $true
                    DependsOn            = "[WaitForAll]WaitForDCache"
                }
            }
        }
        

        #**********************************************************
        # Web applications
        #
        # This section creates the web applications in the 
        # SharePoint farm, as well as managed paths and other web
        # application settings
        #**********************************************************

        if ($Node.NodeName -eq $FirstAppServer) {
            foreach($webApp in $ConfigurationData.NonNodeData.SharePoint.WebApplications) {
                $webAppInternalName = $webApp.Name.Replace(" ", "")
                SPWebApplication $webAppInternalName
                {
                    Name                   = $webApp.Name
                    ApplicationPool        = $webApp.AppPool
                    ApplicationPoolAccount = $webApp.APpPoolAccount
                    AllowAnonymous         = $webApp.Anonymous
                    AuthenticationMethod   = $webApp.Authentication
                    DatabaseName           = $webApp.DatabaseName
                    DatabaseServer         = $ConfigurationData.NonNodeData.SQLServer.ContentDatabaseServer
                    Url                    = $webApp.Url
                    Port                   = [Uri]::new($webApp.Url).Port
                    PsDscRunAsCredential   = $SPSetupAccount
                    DependsOn              = "[SPManagedAccount]WebPoolManagedAccount"
                }

                # If using host named site collections, create the empty path based site here
                if ($webApp.UseHostNamedSiteCollections -eq $true) {
                    SPSite HNSCRootSite
                    {
                        Url                      = $webApp.Url
                        OwnerAlias               = $SPSetupAccount.Username
                        Name                     = "Root site"
                        Template                 = "STS#0"
                        PsDscRunAsCredential     = $SPSetupAccount
                        DependsOn                = "[SPWebApplication]$webAppInternalName"
                    }
                }

                foreach($managedPath in $webApp.ManagedPaths) {
                    SPManagedPath "$($webAppInternalName)Path$($managedPath.Path)" 
                    {
                        WebAppUrl            = $webApp.Url
                        PsDscRunAsCredential = $SPSetupAccount
                        RelativeUrl          = $managedPath.Path
                        Explicit             = $managedPath.Explicit
                        HostHeader           = $webApp.UseHostNamedSiteCollections
                        DependsOn            = "[SPWebApplication]$webAppInternalName"
                    }
                }
            
                SPBlobCacheSettings "ConfigureBlobCache$($webAppInternalName)" 
                {
                    WebAppUrl            = $webApp.Url
                    Zone                 = "Default"
                    EnableCache          = $webApp.BlobCache.Enabled
                    Location             = $webApp.BlobCache.Folder
                    MaxSize              = $webApp.BlobCache.MaxSize
                    FileTypes            = $webApp.BlobCache.FileTypes
                    PsDscRunAsCredential = $SPSetupAccount
                    DependsOn            = "[xSPWebApplication]$webAppInternalName"
                }

                SPCacheAccounts "$($webAppInternalName)CacheAccounts"
                {
                    WebAppUrl              = $webApp.Url
                    SuperUserAlias         = $webApp.SuperUser
                    SuperReaderAlias       = $webApp.SuperReader
                    PsDscRunAsCredential   = $SPSetupAccount
                    DependsOn              = "[SPWebApplication]$webAppInternalName"
                }

                foreach($siteCollection in $webApp.SiteCollections) {
                    $internalSiteName = "$($webAppInternalName)Site$($siteCollection.Name.Replace(' ', ''))"
                    if ($webApp.UseHostNamedSiteCollections -eq $true) {
                        SPSite $internalSiteName
                        {
                            Url                      = $siteCollection.Url
                            OwnerAlias               = $siteCollection.Owner
                            HostHeaderWebApplication = $webApp.Url
                            Name                     = $siteCollection.Name
                            Template                 = $siteCollection.Template
                            PsDscRunAsCredential     = $SPSetupAccount
                            DependsOn                = "[SPWebApplication]$webAppInternalName"
                        }
                    } else {
                        SPSite $internalSiteName
                        {
                            Url                      = $siteCollection.Url
                            OwnerAlias               = $siteCollection.Owner
                            Name                     = $siteCollection.Name
                            Template                 = $siteCollection.Template
                            PsDscRunAsCredential     = $SPSetupAccount
                            DependsOn                = "[SPWebApplication]$webAppInternalName"
                        }
                    }
                }
            }
        }

        #**********************************************************
        # Service instances
        #
        # This section describes which services should be running
        # and not running on the server
        #**********************************************************

        SPServiceInstance ClaimsToWindowsTokenServiceInstance
        {  
            Name                 = "Claims to Windows Token Service"
            Ensure               = "Present"
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn            = $FarmWaitTask
        }

        # App server service instances
        if ($Node.ServiceRoles.AppServer -eq $true) {
            SPServiceInstance UserProfileServiceInstance
            {  
                Name                 = "User Profile Service"
                Ensure               = "Present"
                PsDscRunAsCredential = $SPSetupAccount
                DependsOn            = $FarmWaitTask
            }        
            SPServiceInstance SecureStoreServiceInstance
            {  
                Name                 = "Secure Store Service"
                Ensure               = "Present"
                PsDscRunAsCredential = $SPSetupAccount
                DependsOn            = $FarmWaitTask
            }

            if ($Node.NodeName -eq $FirstAppServer) {
                SPUserProfileSyncService UserProfileSyncService
                {  
                    UserProfileServiceAppName = "User Profile Service Application"
                    Ensure                    = "Present"
                    FarmAccount               = $FarmAccount
                    PsDscRunAsCredential      = $SPSetupAccount
                    DependsOn                 = "[SPUserProfileServiceApp]UserProfileServiceApp"
                }
            }
        }
        
        # Front end service instances
        if ($Node.ServiceRoles.WebFrontEnd -eq $true) {
            SPServiceInstance ManagedMetadataServiceInstance
            {  
                Name                 = "Managed Metadata Web Service"
                Ensure               = "Present"
                PsDscRunAsCredential = $SPSetupAccount
                DependsOn            = $FarmWaitTask
            }
            SPServiceInstance BCSServiceInstance
            {  
                Name                 = "Business Data Connectivity Service"
                Ensure               = "Present"
                PsDscRunAsCredential = $SPSetupAccount
                DependsOn            = $FarmWaitTask
            }
        }
        
        SPServiceInstance SearchServiceInstance
        {  
            Name                 = "SharePoint Server Search"
            Ensure               = "Present"
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn            = $FarmWaitTask
        }     
        
        
        #**********************************************************
        # Service applications
        #
        # This section creates service applications and required
        # dependencies
        #**********************************************************

        if ($Node.NodeName -eq $FirstAppServer) {
            $serviceAppPoolName = "SharePoint Service Applications"
            SPServiceAppPool MainServiceAppPool
            {
                Name                 = $serviceAppPoolName
                ServiceAccount       = $ServicePoolManagedAccount.UserName
                PsDscRunAsCredential = $SPSetupAccount
                DependsOn            = $FarmWaitTask
            }
            SPUserProfileServiceApp UserProfileServiceApp
            {
                Name                 = "User Profile Service Application"
                ApplicationPool      = $serviceAppPoolName
                MySiteHostLocation   = $ConfigurationData.NonNodeData.SharePoint.UserProfileService.MySiteUrl
                ProfileDBName        = $ConfigurationData.NonNodeData.SharePoint.UserProfileService.ProfileDB
                ProfileDBServer      = $ConfigurationData.NonNodeData.SQLServer.ServiceAppDatabaseServer
                SocialDBName         = $ConfigurationData.NonNodeData.SharePoint.UserProfileService.SocialDB
                SocialDBServer       = $ConfigurationData.NonNodeData.SQLServer.ServiceAppDatabaseServer
                SyncDBName           = $ConfigurationData.NonNodeData.SharePoint.UserProfileService.SyncDB
                SyncDBServer         = $ConfigurationData.NonNodeData.SQLServer.ServiceAppDatabaseServer
                FarmAccount          = $FarmAccount
                PsDscRunAsCredential = $SPSetupAccount
                DependsOn            = @('[SPServiceAppPool]MainServiceAppPool', '[SPManagedMetaDataServiceApp]ManagedMetadataServiceApp', '[SPSearchServiceApp]SearchServiceApp')
            }
            SPSecureStoreServiceApp SecureStoreServiceApp
            {
                Name                  = "Secure Store Service Application"
                ApplicationPool       = $serviceAppPoolName
                AuditingEnabled       = $true
                AuditlogMaxSize       = 30
                DatabaseName          = $ConfigurationData.NonNodeData.SharePoint.SecureStoreService.DatabaseName
                PsDscRunAsCredential  = $SPSetupAccount
                DependsOn             = "[SPServiceAppPool]MainServiceAppPool"
            }
            SPManagedMetaDataServiceApp ManagedMetadataServiceApp
            {  
                Name                 = "Managed Metadata Service Application"
                PsDscRunAsCredential = $SPSetupAccount
                ApplicationPool      = $serviceAppPoolName
                DatabaseServer       = $ConfigurationData.NonNodeData.SQLServer.ServiceAppDatabaseServer
                DatabaseName         = $ConfigurationData.NonNodeData.SharePoint.ManagedMetadataService.DatabaseName
                DependsOn            = "[SPServiceAppPool]MainServiceAppPool"
            }
            SPBCSServiceApp BCSServiceApp
            {
                Name                  = "BCS Service Application"
                ApplicationPool       = $serviceAppPoolName
                DatabaseName          = $ConfigurationData.NonNodeData.SharePoint.BCSService.DatabaseName
                DatabaseServer        = $ConfigurationData.NonNodeData.SQLServer.ServiceAppDatabaseServer
                PsDscRunAsCredential  = $SPSetupAccount
                DependsOn             = @('[SPServiceAppPool]MainServiceAppPool', '[SPSecureStoreServiceApp]SecureStoreServiceApp')
            }
            SPSearchServiceApp SearchServiceApp
            {  
                Name                  = "Search Service Application"
                DatabaseName          = $ConfigurationData.NonNodeData.SharePoint.Search.DatabaseName
                DatabaseServer        = $ConfigurationData.NonNodeData.SQLServer.ServiceAppDatabaseServer
                ApplicationPool       = $serviceAppPoolName
                PsDscRunAsCredential  = $SPSetupAccount
                DependsOn             = "[xSPServiceAppPool]MainServiceAppPool"
            }

            xSPSearchCrawlRule IntranetCrawlAccount
            {
                Path                      = "https://intranet.sharepoint.contoso.com"
                ServiceAppName            = "Search Service Application"
                Ensure                    = "Present"
                Type                      = "InclusionRule"
                CrawlConfigurationRules   = "FollowLinksNoPageCrawl","CrawlComplexUrls", "CrawlAsHTTP"
                AuthenticationType        = "DefaultRuleAccess"
                AuthenticationCredentials = $SPSetupAccount
                PsDscRunAsCredential      = $SPSetupAccount
                DependsOn                 = "[xSPSearchServiceApp]SearchServiceApp"
            }
        }

        #**********************************************************
        # Local configuration manager settings
        #
        # This section contains settings for the LCM of the host
        # that this configuraiton is applied to
        #**********************************************************
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }
    }
}
