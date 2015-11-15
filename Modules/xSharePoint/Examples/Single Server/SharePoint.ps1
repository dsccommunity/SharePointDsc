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
    Import-DscResource -ModuleName xSharePoint
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
        
        xCredSSP CredSSPServer { Ensure = "Present"; Role = "Server"; } 
        xCredSSP CredSSPClient { Ensure = "Present"; Role = "Client"; DelegateComputers = "*.$($ConfigurationData.NonNodeData.DomainDetails.DomainName)" }
        
        #**********************************************************
        # IIS clean up
        #
        # This section removes all default sites and application
        # pools from IIS as they are not required
        #**********************************************************

        xWebAppPool RemoveDotNet2Pool         { Name = ".NET v2.0";            Ensure = "Absent" }
        xWebAppPool RemoveDotNet2ClassicPool  { Name = ".NET v2.0 Classic";    Ensure = "Absent" }
        xWebAppPool RemoveDotNet45Pool        { Name = ".NET v4.5";            Ensure = "Absent"; }
        xWebAppPool RemoveDotNet45ClassicPool { Name = ".NET v4.5 Classic";    Ensure = "Absent"; }
        xWebAppPool RemoveClassicDotNetPool   { Name = "Classic .NET AppPool"; Ensure = "Absent" }
        xWebAppPool RemoveDefaultAppPool      { Name = "DefaultAppPool";       Ensure = "Absent" }
        xWebSite    RemoveDefaultWebSite      { Name = "Default Web Site";     Ensure = "Absent"; PhysicalPath = "C:\inetpub\wwwroot" }
        

        #**********************************************************
        # Basic farm configuration
        #
        # This section creates the new SharePoint farm object, and
        # provisions generic services and components used by the
        # whole farm
        #**********************************************************
        xSPCreateFarm CreateSPFarm
        {
            DatabaseServer           = $ConfigurationData.NonNodeData.SQLServer.FarmDatabaseServer
            FarmConfigDatabaseName   = $ConfigurationData.NonNodeData.SharePoint.Farm.ConfigurationDatabase
            Passphrase               = $ConfigurationData.NonNodeData.SharePoint.Farm.Passphrase
            FarmAccount              = $FarmAccount
            PsDscRunAsCredential     = $SPSetupAccount
            AdminContentDatabaseName = $ConfigurationData.NonNodeData.SharePoint.Farm.AdminContentDatabase
        }
        xSPManagedAccount ServicePoolManagedAccount
        {
            AccountName          = $ServicePoolManagedAccount.UserName
            Account              = $ServicePoolManagedAccount
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn            = "[xSPCreateFarm]CreateSPFarm"
        }
        xSPManagedAccount WebPoolManagedAccount
        {
            AccountName          = $WebPoolManagedAccount.UserName
            Account              = $WebPoolManagedAccount
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn            = "[xSPCreateFarm]CreateSPFarm"
        }
        xSPDiagnosticLoggingSettings ApplyDiagnosticLogSettings
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
            DependsOn                                   = @("[xSPCreateFarm]CreateSPFarm", "[xDisk]LogsDisk")
        }
        xSPUsageApplication UsageApplication 
        {
            Name                  = "Usage Service Application"
            DatabaseName          = $ConfigurationData.NonNodeData.SharePoint.UsageLogs.DatabaseName
            UsageLogCutTime       = 5
            UsageLogLocation      = $ConfigurationData.NonNodeData.SharePoint.UsageLogs.Path
            UsageLogMaxFileSizeKB = 1024
            PsDscRunAsCredential  = $SPSetupAccount
            DependsOn             = "[xSPCreateFarm]CreateSPFarm"
        }
        xSPStateServiceApp StateServiceApp
        {
            Name                 = "State Service Application"
            DatabaseName         = $ConfigurationData.NonNodeData.SharePoint.StateService.DatabaseName
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn            = "[xSPCreateFarm]CreateSPFarm"
        }
        xSPDistributedCacheService EnableDistributedCache
        {
            Name                 = "AppFabricCachingService"
            Ensure               = "Present"
            CacheSizeInMB        = 1024
            ServiceAccount       = $ServicePoolManagedAccount.UserName
            PsDscRunAsCredential = $SPSetupAccount
            CreateFirewallRules  = $true
            DependsOn            = @('[xSPCreateFarm]CreateSPFarm','[xSPManagedAccount]ServicePoolManagedAccount')
        }

        #**********************************************************
        # Web applications
        #
        # This section creates the web applications in the 
        # SharePoint farm, as well as managed paths and other web
        # application settings
        #**********************************************************

        foreach($webApp in $ConfigurationData.NonNodeData.SharePoint.WebApplications) {
            $webAppInternalName = $webApp.Name.Replace(" ", "")
            xSPWebApplication $webAppInternalName
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
                DependsOn              = "[xSPManagedAccount]WebPoolManagedAccount"
            }

            foreach($managedPath in $webApp.ManagedPaths) {
                xSPManagedPath "$($webAppInternalName)Path$($managedPath.Path)" 
                {
                    WebAppUrl            = $webApp.Url
                    PsDscRunAsCredential = $SPSetupAccount
                    RelativeUrl          = $managedPath.Path
                    Explicit             = $managedPath.Explicit
                    HostHeader           = $webApp.UseHostNamedSiteCollections
                    DependsOn            = "[xSPWebApplication]$webAppInternalName"
                }
            }
            
            xSPCacheAccounts "$($webAppInternalName)CacheAccounts"
            {
                WebAppUrl              = $webApp.Url
                SuperUserAlias         = $webApp.SuperUser
                SuperReaderAlias       = $webApp.SuperReader
                PsDscRunAsCredential   = $SPSetupAccount
                DependsOn              = "[xSPWebApplication]$webAppInternalName"
            }

            foreach($siteCollection in $webApp.SiteCollections) {
                $internalSiteName = "$($webAppInternalName)Site$($siteCollection.Name.Replace(' ', ''))"
                if ($webApp.UseHostNamedSiteCollections -eq $true) {
                    xSPSite $internalSiteName
                    {
                        Url                      = $siteCollection.Url
                        OwnerAlias               = $siteCollection.Owner
                        HostHeaderWebApplication = $webApp.Url
                        Name                     = $siteCollection.Name
                        Template                 = $siteCollection.Template
                        PsDscRunAsCredential     = $SPSetupAccount
                        DependsOn                = "[xSPWebApplication]$webAppInternalName"
                    }
                } else {
                    xSPSite $internalSiteName
                    {
                        Url                      = $siteCollection.Url
                        OwnerAlias               = $siteCollection.Owner
                        Name                     = $siteCollection.Name
                        Template                 = $siteCollection.Template
                        PsDscRunAsCredential     = $SPSetupAccount
                        DependsOn                = "[xSPWebApplication]$webAppInternalName"
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

        xSPServiceInstance ClaimsToWindowsTokenServiceInstance
        {  
            Name                 = "Claims to Windows Token Service"
            Ensure               = "Present"
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn            = "[xSPCreateFarm]CreateSPFarm"
        }

        # App server service instances
        if ($Node.ServiceRoles.AppServer -eq $true) {
            xSPServiceInstance UserProfileServiceInstance
            {  
                Name                 = "User Profile Service"
                Ensure               = "Present"
                PsDscRunAsCredential = $SPSetupAccount
                DependsOn            = "[xSPCreateFarm]CreateSPFarm"
            }        
            xSPServiceInstance SecureStoreServiceInstance
            {  
                Name                 = "Secure Store Service"
                Ensure               = "Present"
                PsDscRunAsCredential = $SPSetupAccount
                DependsOn            = "[xSPCreateFarm]CreateSPFarm"
            }

            xSPUserProfileSyncService UserProfileSyncService
            {  
                UserProfileServiceAppName = "User Profile Service Application"
                Ensure                    = "Present"
                FarmAccount               = $FarmAccount
                PsDscRunAsCredential      = $SPSetupAccount
                DependsOn                 = "[xSPUserProfileServiceApp]UserProfileServiceApp"
            }
        }
        
        # Front end service instances
        if ($Node.ServiceRoles.WebFrontEnd -eq $true) {
            xSPServiceInstance ManagedMetadataServiceInstance
            {  
                Name                 = "Managed Metadata Web Service"
                Ensure               = "Present"
                PsDscRunAsCredential = $SPSetupAccount
                DependsOn            = "[xSPCreateFarm]CreateSPFarm"
            }
            xSPServiceInstance BCSServiceInstance
            {  
                Name                 = "Business Data Connectivity Service"
                Ensure               = "Present"
                PsDscRunAsCredential = $SPSetupAccount
                DependsOn            = "[xSPCreateFarm]CreateSPFarm"
            }
        }
        
        # Search front or back end instances
        if ($Node.ServiceRoles.SearchFrontEnd -eq $true -or $Node.ServiceRoles.SearchBackEnd -eq $true) {
            xSPServiceInstance SearchServiceInstance
            {  
                Name                 = "SharePoint Server Search"
                Ensure               = "Present"
                PsDscRunAsCredential = $SPSetupAccount
                DependsOn            = "[xSPCreateFarm]CreateSPFarm"
            }
        }
        
        #**********************************************************
        # Service applications
        #
        # This section creates service applications and required
        # dependencies
        #**********************************************************

        $serviceAppPoolName = "SharePoint Service Applications"
        xSPServiceAppPool MainServiceAppPool
        {
            Name                 = $serviceAppPoolName
            ServiceAccount       = $ServicePoolManagedAccount.UserName
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn            = "[xSPCreateFarm]CreateSPFarm"
        }
        xSPUserProfileServiceApp UserProfileServiceApp
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
            DependsOn            = @('[xSPServiceAppPool]MainServiceAppPool', '[xSPManagedMetaDataServiceApp]ManagedMetadataServiceApp', '[xSPSearchServiceApp]SearchServiceApp')
        }
        xSPSecureStoreServiceApp SecureStoreServiceApp
        {
            Name                  = "Secure Store Service Application"
            ApplicationPool       = $serviceAppPoolName
            AuditingEnabled       = $true
            AuditlogMaxSize       = 30
            DatabaseName          = $ConfigurationData.NonNodeData.SharePoint.SecureStoreService.DatabaseName
            PsDscRunAsCredential  = $SPSetupAccount
            DependsOn             = "[xSPServiceAppPool]MainServiceAppPool"
        }
        xSPManagedMetaDataServiceApp ManagedMetadataServiceApp
        {  
            Name                 = "Managed Metadata Service Application"
            PsDscRunAsCredential = $SPSetupAccount
            ApplicationPool      = $serviceAppPoolName
            DatabaseServer       = $ConfigurationData.NonNodeData.SQLServer.ServiceAppDatabaseServer
            DatabaseName         = $ConfigurationData.NonNodeData.SharePoint.ManagedMetadataService.DatabaseName
            DependsOn            = "[xSPServiceAppPool]MainServiceAppPool"
        }
        xSPBCSServiceApp BCSServiceApp
        {
            Name                  = "BCS Service Application"
            ApplicationPool       = $serviceAppPoolName
            DatabaseName          = $ConfigurationData.NonNodeData.SharePoint.BCSService.DatabaseName
            DatabaseServer        = $ConfigurationData.NonNodeData.SQLServer.ServiceAppDatabaseServer
            PsDscRunAsCredential  = $SPSetupAccount
            DependsOn             = @('[xSPServiceAppPool]MainServiceAppPool', '[xSPSecureStoreServiceApp]SecureStoreServiceApp')
        }
        xSPSearchServiceApp SearchServiceApp
        {  
            Name                  = "Search Service Application"
            DatabaseName          = $ConfigurationData.NonNodeData.SharePoint.Search.DatabaseName
            DatabaseServer        = $ConfigurationData.NonNodeData.SQLServer.ServiceAppDatabaseServer
            ApplicationPool       = $serviceAppPoolName
            PsDscRunAsCredential  = $SPSetupAccount
            DependsOn             = "[xSPServiceAppPool]MainServiceAppPool"
        }
        xSPSearchRoles LocalSearchRoles
        {
            Ensure                  = "Present"
            Admin                   = $true
            Crawler                 = $true
            ContentProcessing       = $true
            AnalyticsProcessing     = $true
            QueryProcessing         = $true
            ServiceAppName          = "Search Service Application"
            PsDscRunAsCredential    = $SPSetupAccount
            FirstPartitionIndex     = 0
            FirstPartitionDirectory = "$($ConfigurationData.NonNodeData.SharePoint.Search.IndexRootPath.TrimEnd("\"))\0"
            FirstPartitionServers   = $env:COMPUTERNAME
            DependsOn               = "[xSPSearchServiceApp]SearchServiceApp"
        }
        xSPSearchIndexPartition MainSearchPartition
        {
            Ensure               = "Present"
            Servers              = $env:COMPUTERNAME
            Index                = 1
            RootDirectory        = "$($ConfigurationData.NonNodeData.SharePoint.Search.IndexRootPath.TrimEnd("\"))\1"
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn            = "[xSPSearchRoles]LocalSearchRoles"
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