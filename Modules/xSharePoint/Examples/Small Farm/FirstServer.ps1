Configuration SharePointFarmServer
{
    param (
        [Parameter(Mandatory=$true)] [ValidateNotNullorEmpty()] [string]       $CredSSPDelegates,
        [Parameter(Mandatory=$true)] [ValidateNotNullorEmpty()] [string]       $SPBinaryPath,
        [Parameter(Mandatory=$true)] [ValidateNotNullorEmpty()] [string]       $ULSViewerPath,
        [Parameter(Mandatory=$true)] [ValidateNotNullorEmpty()] [PSCredential] $SPBinaryPathCredential,
        [Parameter(Mandatory=$true)] [ValidateNotNullorEmpty()] [PSCredential] $FarmAccount,
        [Parameter(Mandatory=$true)] [ValidateNotNullorEmpty()] [PSCredential] $InstallAccount,
        [Parameter(Mandatory=$true)] [ValidateNotNullorEmpty()] [string]       $ProductKey,
        [Parameter(Mandatory=$true)] [ValidateNotNullorEmpty()] [string]       $DatabaseServer,
        [Parameter(Mandatory=$true)] [ValidateNotNullorEmpty()] [string]       $FarmPassPhrase,
        [Parameter(Mandatory=$true)] [ValidateNotNullorEmpty()] [PSCredential] $WebPoolManagedAccount,
        [Parameter(Mandatory=$true)] [ValidateNotNullorEmpty()] [PSCredential] $ServicePoolManagedAccount,
        [Parameter(Mandatory=$true)] [ValidateNotNullorEmpty()] [string]       $WebAppUrl,
        [Parameter(Mandatory=$true)] [ValidateNotNullorEmpty()] [string]       $MySiteHostUrl,
        [Parameter(Mandatory=$true)] [ValidateNotNullorEmpty()] [string]       $TeamSiteUrl,
        [Parameter(Mandatory=$true)] [ValidateNotNullorEmpty()] [int]          $CacheSizeInMB
    )
    Import-DscResource -ModuleName xSharePoint
    Import-DscResource -ModuleName xWebAdministration
    Import-DscResource -ModuleName xCredSSP
    Import-DscResource -ModuleName xDisk

    node "localhost"
    {
        #**********************************************************
        # Server configuration
        #
        # This section of the configuration includes details of the
        # server level configuration, such as disks, registry
        # settings etc.
        #********************************************************** 

        xDisk LogsDisk { DiskNumber = 2; DriveLetter = "l" }
        xDisk IndexDisk { DiskNumber = 3; DriveLetter = "i" }
        xCredSSP CredSSPServer { Ensure = "Present"; Role = "Server" } 
        xCredSSP CredSSPClient { Ensure = "Present"; Role = "Client"; DelegateComputers = $CredSSPDelegates }


        #**********************************************************
        # Software downloads
        #
        # This section details where any binary downloads should
        # be downloaded from and put locally on the server before
        # installation takes place
        #********************************************************** 

        File SPBinaryDownload
        {
            DestinationPath = "C:\SPInstall"
            Credential      = $SPBinaryPathCredential
            Ensure          = "Present"
            SourcePath      = $SPBinaryPath
            Type            = "Directory"
            Recurse         = $true
        }
        File UlsViewerDownload
        {
            DestinationPath = "L:\UlsViewer.exe"
            Credential      = $SPBinaryPathCredential
            Ensure          = "Present"
            SourcePath      = $ULSViewerPath
            Type            = "File"
            DependsOn       = "[xDisk]LogsDisk"
        }

        #**********************************************************
        # Binary installation
        #
        # This section triggers installation of both SharePoint
        # as well as the prerequisites required
        #********************************************************** 

        xSPClearRemoteSessions ClearRemotePowerShellSessions
        {
            ClearRemoteSessions = $true
        }
        xSPInstallPrereqs InstallPrerequisites
        {
            InstallerPath     = "C:\SPInstall\Prerequisiteinstaller.exe"
            OnlineMode        = $true
            SQLNCli           = "C:\SPInstall\prerequisiteinstallerfiles\sqlncli.msi"
            PowerShell        = "C:\SPInstall\prerequisiteinstallerfiles\Windows6.1-KB2506143-x64.msu"
            NETFX             = "C:\SPInstall\prerequisiteinstallerfiles\dotNetFx45_Full_setup.exe"
            IDFX              = "C:\SPInstall\prerequisiteinstallerfiles\Windows6.1-KB974405-x64.msu"
            Sync              = "C:\SPInstall\prerequisiteinstallerfiles\Synchronization.msi"
            AppFabric         = "C:\SPInstall\prerequisiteinstallerfiles\WindowsServerAppFabricSetup_x64.exe"
            IDFX11            = "C:\SPInstall\prerequisiteinstallerfiles\MicrosoftIdentityExtensions-64.msi"
            MSIPCClient       = "C:\SPInstall\prerequisiteinstallerfiles\setup_msipc_x64.msi"
            WCFDataServices   = "C:\SPInstall\prerequisiteinstallerfiles\WcfDataServices.exe"
            KB2671763         = "C:\SPInstall\prerequisiteinstallerfiles\AppFabric1.1-RTM-KB2671763-x64-ENU.exe"
            WCFDataServices56 = "C:\SPInstall\prerequisiteinstallerfiles\WcfDataServices56.exe"
            DependsOn         = "[xSPClearRemoteSessions]ClearRemotePowerShellSessions"
        }
        xSPInstall InstallBinaries
        {
            BinaryDir  = "C:\SPInstall"
            ProductKey = $ProductKey
            DependsOn  = "[xSPInstallPrereqs]InstallPrerequisites"
        }

        #**********************************************************
        # IIS clean up
        #
        # This section removes all default sites and application
        # pools from IIS as they are not required
        #**********************************************************

        xWebAppPool RemoveDotNet2Pool         { Name = ".NET v2.0";            Ensure = "Absent"; DependsOn = "[xSPInstallPrereqs]InstallPrerequisites" }
        xWebAppPool RemoveDotNet2ClassicPool  { Name = ".NET v2.0 Classic";    Ensure = "Absent"; DependsOn = "[xSPInstallPrereqs]InstallPrerequisites" }
        xWebAppPool RemoveDotNet45Pool        { Name = ".NET v4.5";            Ensure = "Absent"; DependsOn = "[xSPInstallPrereqs]InstallPrerequisites"; }
        xWebAppPool RemoveDotNet45ClassicPool { Name = ".NET v4.5 Classic";    Ensure = "Absent"; DependsOn = "[xSPInstallPrereqs]InstallPrerequisites"; }
        xWebAppPool RemoveClassicDotNetPool   { Name = "Classic .NET AppPool"; Ensure = "Absent"; DependsOn = "[xSPInstallPrereqs]InstallPrerequisites" }
        xWebAppPool RemoveDefaultAppPool      { Name = "DefaultAppPool";       Ensure = "Absent"; DependsOn = "[xSPInstallPrereqs]InstallPrerequisites" }
        xWebSite    RemoveDefaultWebSite      { Name = "Default Web Site";     Ensure = "Absent"; PhysicalPath = "C:\inetpub\wwwroot"; DependsOn = "[xSPInstallPrereqs]InstallPrerequisites" }
        

        #**********************************************************
        # Basic farm configuration
        #
        # This section creates the new SharePoint farm object, and
        # provisions generic services and components used by the
        # whole farm
        #**********************************************************

        xSPCreateFarm CreateSPFarm
        {
            DatabaseServer           = $DatabaseServer
            FarmConfigDatabaseName   = "SP_Config"
            Passphrase               = $FarmPassPhrase
            FarmAccount              = $FarmAccount
            InstallAccount           = $InstallAccount
            AdminContentDatabaseName = "SP_AdminContent"
            DependsOn                = "[xSPInstall]InstallBinaries"
        }
        xSPManagedAccount ServicePoolManagedAccount
        {
            AccountName    = $ServicePoolManagedAccount.UserName
            Account        = $ServicePoolManagedAccount
            Schedule       = ""
            InstallAccount = $InstallAccount
            DependsOn      = "[xSPCreateFarm]CreateSPFarm"
        }
        xSPManagedAccount WebPoolManagedAccount
        {
            AccountName    = $WebPoolManagedAccount.UserName
            Account        = $WebPoolManagedAccount
            Schedule       = ""
            InstallAccount = $InstallAccount
            DependsOn      = "[xSPCreateFarm]CreateSPFarm"
        }
        xSPDiagnosticLoggingSettings ApplyDiagnosticLogSettings
        {
            InstallAccount                              = $InstallAccount
            LogPath                                     = "L:\ULSLogs"
            LogSpaceInGB                                = 10
            AppAnalyticsAutomaticUploadEnabled          = $false
            CustomerExperienceImprovementProgramEnabled = $true
            DaysToKeepLogs                              = 7
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
            DatabaseName          = "SP_Usage"
            UsageLogCutTime       = 5
            UsageLogLocation      = "L:\UsageLogs"
            UsageLogMaxFileSizeKB = 1024
            InstallAccount        = $InstallAccount
            DependsOn             = "[xSPCreateFarm]CreateSPFarm"
        }
        xSPStateServiceApp StateServiceApp
        {
            Name           = "State Service Application"
            DatabaseName   = "SP_State"
            InstallAccount = $InstallAccount
            DependsOn      = "[xSPCreateFarm]CreateSPFarm"
        }

        #**********************************************************
        # Web applications
        #
        # This section creates the web applications in the 
        # SharePoint farm, as well as managed paths and other web
        # application settings
        #**********************************************************

        xSPWebApplication HostNameSiteCollectionWebApp
        {
            Name                   = "SharePoint Sites"
            ApplicationPool        = "SharePoint Sites"
            ApplicationPoolAccount = $WebPoolManagedAccount.UserName
            AllowAnonymous         = $false
            AuthenticationMethod   = "NTLM"
            DatabaseName           = "SP_Content_01"
            DatabaseServer         = $DatabaseServer
            Url                    = $WebAppUrl
            Port                   = 80
            InstallAccount         = $InstallAccount
            DependsOn              = "[xSPManagedAccount]WebPoolManagedAccount"
        }
        xSPManagedPath TeamsManagedPath 
        {
            WebAppUrl      = "http://$WebAppUrl"
            InstallAccount = $InstallAccount
            RelativeUrl    = "teams"
            Explicit       = $false
            HostHeader     = $true
            DependsOn      = "[xSPWebApplication]HostNameSiteCollectionWebApp"
        }
        xSPManagedPath PersonalManagedPath 
        {
            WebAppUrl      = "http://$WebAppUrl"
            InstallAccount = $InstallAccount
            RelativeUrl    = "personal"
            Explicit       = $false
            HostHeader     = $true
            DependsOn      = "[xSPWebApplication]HostNameSiteCollectionWebApp"
        }
        xSPCacheAccounts SetCacheAccounts
        {
            WebAppUrl        = "http://$WebAppUrl"
            SuperUserAlias   = "DEMO\svxSPSuperUser"
            SuperReaderAlias = "DEMO\svxSPReader"
            InstallAccount   = $InstallAccount
            DependsOn        = "[xSPWebApplication]HostNameSiteCollectionWebApp"
        }

        #**********************************************************
        # Service instances
        #
        # This section describes which services should be running
        # and not running on the server
        #**********************************************************

        xSPServiceInstance ClaimsToWindowsTokenServiceInstance
        {  
            Name           = "Claims to Windows Token Service"
            Ensure         = "Present"
            InstallAccount = $InstallAccount
            DependsOn      = "[xSPCreateFarm]CreateSPFarm"
        } 
        xSPServiceInstance UserProfileServiceInstance
        {  
            Name           = "User Profile Service"
            Ensure         = "Present"
            InstallAccount = $InstallAccount
            DependsOn      = "[xSPCreateFarm]CreateSPFarm"
        }        
        xSPUserProfileSyncService UserProfileSyncService
        {  
            UserProfileServiceAppName   = "User Profile Service Application"
            Ensure                      = "Present"
            FarmAccount                 = $FarmAccount
            InstallAccount              = $InstallAccount
            DependsOn                   = "[xSPUserProfileServiceApp]UserProfileServiceApp"
        }

        #**********************************************************
        # Service applications
        #
        # This section creates service applications and required
        # dependencies
        #**********************************************************

        xSPServiceAppPool MainServiceAppPool
        {
            Name           = "SharePoint Service Applications"
            ServiceAccount = $ServicePoolManagedAccount.UserName
            InstallAccount = $InstallAccount
            DependsOn      = "[xSPCreateFarm]CreateSPFarm"
        }
        xSPUserProfileServiceApp UserProfileServiceApp
        {
            Name                = "User Profile Service Application"
            ApplicationPool     = "SharePoint Service Applications"
            MySiteHostLocation = "http://$MySiteHostUrl"
            ProfileDBName       = "SP_UserProfiles"
            ProfileDBServer     = $DatabaseServer
            SocialDBName        = "SP_Social"
            SocialDBServer      = $DatabaseServer
            SyncDBName          = "SP_ProfileSync"
            SyncDBServer        = $DatabaseServer
            FarmAccount         = $FarmAccount
            InstallAccount      = $InstallAccount
            DependsOn           = @('[xSPServiceAppPool]MainServiceAppPool', '[xSPManagedPath]PersonalManagedPath', '[xSPSite]MySiteHost', '[xSPManagedMetaDataServiceApp]ManagedMetadataServiceApp', '[xSPSearchServiceApp]SearchServiceApp')
        }
        xSPSecureStoreServiceApp SecureStoreServiceApp
        {
            Name            = "Secure Store Service Application"
            ApplicationPool = "SharePoint Service Applications"
            AuditingEnabled = $true
            AuditlogMaxSize = 30
            DatabaseName    = "SP_SecureStore"
            InstallAccount  = $InstallAccount
            DependsOn       = "[xSPServiceAppPool]MainServiceAppPool"
        }
        xSPManagedMetaDataServiceApp ManagedMetadataServiceApp
        {  
            Name              = "Managed Metadata Service Application"
            InstallAccount    = $InstallAccount
            ApplicationPool   = "SharePoint Service Applications"
            DatabaseServer    = $DatabaseServer
            DatabaseName      = "SP_ManagedMetadata"
            DependsOn         = "[xSPServiceAppPool]MainServiceAppPool"
        }
        xSPSearchServiceApp SearchServiceApp
        {  
            Name            = "Search Service Application"
            DatabaseName    = "SP_Search"
            ApplicationPool = "SharePoint Service Applications"
            InstallAccount  = $InstallAccount
            DependsOn       = "[xSPServiceAppPool]MainServiceAppPool"
        }
        xSPBCSServiceApp BCSServiceApp
        {
            Name            = "BCS Service Application"
            ApplicationPool = "SharePoint Service Applications"
            DatabaseName    = "SP_BCS"
            DatabaseServer  = $DatabaseServer
            InstallAccount  = $InstallAccount
            DependsOn       = @('[xSPServiceAppPool]MainServiceAppPool', '[xSPSecureStoreServiceApp]SecureStoreServiceApp')
        }

        #**********************************************************
        # Site Collections
        #
        # This section contains the site collections to provision
        #**********************************************************
        
        xSPSite TeamSite
        {
            Url                      = "http://$TeamSiteUrl"
            OwnerAlias               = $InstallAccount.UserName
            HostHeaderWebApplication = "http://$WebAppUrl"
            Name                     = "Team Sites"
            Template                 = "STS#0"
            InstallAccount           = $InstallAccount
            DependsOn                = "[xSPWebApplication]HostNameSiteCollectionWebApp"
        }
        xSPSite MySiteHost
        {
            Url                      = "http://$MySiteHostUrl"
            OwnerAlias               = $InstallAccount.UserName
            HostHeaderWebApplication = "http://$WebAppUrl"
            Name                     = "My Site Host"
            Template                 = "SPSMSITEHOST#0"
            InstallAccount           = $InstallAccount
            DependsOn                = "[xSPWebApplication]HostNameSiteCollectionWebApp"
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