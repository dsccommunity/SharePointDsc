$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName = 'Server1'
            PSDscAllowPlainTextPassword = $true
        },
        @{
            NodeName = 'Server2'
            PSDscAllowPlainTextPassword = $true
        }
    )
}

Configuration Example
{
    param (
        [Parameter(Mandatory=$true)] [ValidateNotNullorEmpty()] [PSCredential] $FarmAccount,
        [Parameter(Mandatory=$true)] [ValidateNotNullorEmpty()] [PSCredential] $SPSetupAccount,
        [Parameter(Mandatory=$true)] [ValidateNotNullorEmpty()] [PSCredential] $WebPoolManagedAccount,
        [Parameter(Mandatory=$true)] [ValidateNotNullorEmpty()] [PSCredential] $ServicePoolManagedAccount,
        [Parameter(Mandatory=$true)] [ValidateNotNullorEmpty()] [PSCredential] $Passphrase
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName SharePointDsc
    Import-DscResource -ModuleName xWebAdministration

    node "Server1"
    {
        #**********************************************************
        # Install Binaries
        #
        # This section installs SharePoint and its Prerequisites
        #**********************************************************

        SPInstallPrereqs InstallPrereqs {
            IsSingleInstance  = "Yes"
            Ensure            = "Present"
            InstallerPath     = "C:\binaries\prerequisiteinstaller.exe"
            OnlineMode        = $true
        }

        SPInstall InstallSharePoint {
            IsSingleInstance  = "Yes"
            Ensure            = "Present"
            BinaryDir         = "C:\binaries\"
            ProductKey        = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
            DependsOn         = "[SPInstallPrereqs]InstallPrereqs"
        }

        #**********************************************************
        # Basic farm configuration
        #
        # This section creates the new SharePoint farm object, and
        # provisions generic services and components used by the
        # whole farm
        #**********************************************************
        SPFarm CreateSPFarm
        {
            IsSingleInstance          = "Yes"
            Ensure                    = "Present"
            DatabaseServer            = "sql.contoso.com"
            FarmConfigDatabaseName    = "SP_Config"
            Passphrase                = $Passphrase
            FarmAccount               = $FarmAccount
            PsDscRunAsCredential      = $SPSetupAccount
            AdminContentDatabaseName  = "SP_AdminContent"
            CentralAdministrationPort = 9999
            RunCentralAdmin           = $true
            DependsOn                 = "[SPInstall]InstallSharePoint"
        }
        SPManagedAccount ServicePoolManagedAccount
        {
            AccountName          = $ServicePoolManagedAccount.UserName
            Account              = $ServicePoolManagedAccount
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn            = "[SPFarm]CreateSPFarm"
        }
        SPManagedAccount WebPoolManagedAccount
        {
            AccountName          = $WebPoolManagedAccount.UserName
            Account              = $WebPoolManagedAccount
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn            = "[SPFarm]CreateSPFarm"
        }
        SPDiagnosticLoggingSettings ApplyDiagnosticLogSettings
        {
            IsSingleInstance                            = "Yes"
            PsDscRunAsCredential                        = $SPSetupAccount
            LogPath                                     = "C:\ULS"
            LogSpaceInGB                                = 5
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
            DependsOn                                   = "[SPFarm]CreateSPFarm"
        }
        SPUsageApplication UsageApplication
        {
            Name                  = "Usage Service Application"
            DatabaseName          = "SP_Usage"
            UsageLogCutTime       = 5
            UsageLogLocation      = "C:\UsageLogs"
            UsageLogMaxFileSizeKB = 1024
            PsDscRunAsCredential  = $SPSetupAccount
            DependsOn             = "[SPFarm]CreateSPFarm"
        }
        SPStateServiceApp StateServiceApp
        {
            Name                 = "State Service Application"
            DatabaseName         = "SP_State"
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn            = "[SPFarm]CreateSPFarm"
        }
        SPDistributedCacheService EnableDistributedCache
        {
            Name                 = "AppFabricCachingService"
            Ensure               = "Present"
            CacheSizeInMB        = 1024
            ServiceAccount       = $ServicePoolManagedAccount.UserName
            PsDscRunAsCredential = $SPSetupAccount
            CreateFirewallRules  = $true
            DependsOn            = @('[SPFarm]CreateSPFarm','[SPManagedAccount]ServicePoolManagedAccount')
        }

        #**********************************************************
        # Web applications
        #
        # This section creates the web applications in the
        # SharePoint farm, as well as managed paths and other web
        # application settings
        #**********************************************************

        SPWebApplication SharePointSites
        {
            Name                   = "SharePoint Sites"
            ApplicationPool        = "SharePoint Sites"
            ApplicationPoolAccount = $WebPoolManagedAccount.UserName
            AllowAnonymous         = $false
            DatabaseName           = "SP_Content"
            WebAppUrl              = "https://sites.contoso.com"
            HostHeader             = "sites.contoso.com"
            Port                   = 443
            PsDscRunAsCredential   = $SPSetupAccount
            DependsOn              = "[SPManagedAccount]WebPoolManagedAccount"
        }

        #**********************************************************
        # This resource depends on module xWebAdministration and
        # uses SNI to bind to a specific hostname. If you don't
        # want to use SNI, set SslFlags to 0.
        #**********************************************************
        xWebsite SslWebAppSharePointSites
        {
            Ensure      = 'Present'
            Name        = "SharePoint Sites"
            BindingInfo = @(
                    MSFT_xWebBindingInformation
                    {
                        Protocol              = 'https'
                        IPAddress             = '*'
                        Port                  = 443
                        CertificateThumbprint = '<SSL certificate thumbprint>'
                        CertificateStoreName  = 'My'
                        HostName              = 'sites.contoso.com'
                        SslFlags              = 1
                    }
            )
            DependsOn   = '[SPWebApplication]SharePointSites'
        }

        SPCacheAccounts WebAppCacheAccounts
        {
            WebAppUrl              = "https://sites.contoso.com"
            SuperUserAlias         = "CONTOSO\SP_SuperUser"
            SuperReaderAlias       = "CONTOSO\SP_SuperReader"
            PsDscRunAsCredential   = $SPSetupAccount
            DependsOn              = "[SPWebApplication]SharePointSites"
        }

        SPSite TeamSite
        {
            Url                      = "https://sites.contoso.com"
            OwnerAlias               = "CONTOSO\SP_Admin"
            Name                     = "DSC Demo Site"
            Template                 = "STS#0"
            PsDscRunAsCredential     = $SPSetupAccount
            DependsOn                = "[SPWebApplication]SharePointSites"
        }

        #**********************************************************
        # Now set up binding and AAM for Central Admin
        #**********************************************************
        xWebsite SslWebAppCentralAdmin
        {
            Ensure      = 'Present'
            Name        = 'SharePoint Central Administration v4'
            BindingInfo = @(
                MSFT_xWebBindingInformation
                {
                    Protocol              = 'https'
                    IPAddress             = '*'
                    Port                  = '443'
                    CertificateThumbprint = '<SSL certificate thumbprint>'
                    CertificateStoreName  = 'My'
                    HostName              = 'admin.contoso.com'
                    SslFlags              = 1
                }
            )
            DependsOn   = '[xWebsite]SslWebAppSharePointSites'
        }

        # Change AAM for Central Admin
        SPAlternateUrl CentralAdminAam
        {
            WebAppName           = "SharePoint Central Administration v4"
            Zone                 = "Default"
            Url                  = 'https://admin.contoso.com'
            Ensure               = "Present"
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn            = "[xWebsite]SslWebAppCentralAdmin"
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
            DependsOn            = "[SPFarm]CreateSPFarm"
        }

        SPServiceInstance SecureStoreServiceInstance
        {
            Name                 = "Secure Store Service"
            Ensure               = "Present"
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn            = "[SPFarm]CreateSPFarm"
        }

        SPServiceInstance SearchServiceInstance
        {
            Name                 = "SharePoint Server Search"
            Ensure               = "Present"
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn            = "[SPFarm]CreateSPFarm"
        }

        #**********************************************************
        # Service applications
        #
        # This section creates service applications and required
        # dependencies
        #**********************************************************

        $serviceAppPoolName = "SharePoint Service Applications"
        SPServiceAppPool MainServiceAppPool
        {
            Name                 = $serviceAppPoolName
            ServiceAccount       = $ServicePoolManagedAccount.UserName
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn            = "[SPFarm]CreateSPFarm"
        }

        SPSecureStoreServiceApp SecureStoreServiceApp
        {
            Name                  = "Secure Store Service Application"
            ApplicationPool       = $serviceAppPoolName
            AuditingEnabled       = $true
            AuditlogMaxSize       = 30
            DatabaseName          = "SP_SecureStore"
            PsDscRunAsCredential  = $SPSetupAccount
            DependsOn             = "[SPServiceAppPool]MainServiceAppPool"
        }

        SPManagedMetaDataServiceApp ManagedMetadataServiceApp
        {
            Name                 = "Managed Metadata Service Application"
            PsDscRunAsCredential = $SPSetupAccount
            ApplicationPool      = $serviceAppPoolName
            DatabaseName         = "SP_MMS"
            DependsOn            = "[SPServiceAppPool]MainServiceAppPool"
        }

        SPBCSServiceApp BCSServiceApp
        {
            Name                  = "BCS Service Application"
            ApplicationPool       = $serviceAppPoolName
            DatabaseName          = "SP_BCS"
            PsDscRunAsCredential  = $SPSetupAccount
            DependsOn             = @('[SPServiceAppPool]MainServiceAppPool', '[SPSecureStoreServiceApp]SecureStoreServiceApp')
        }

        SPSearchServiceApp SearchServiceApp
        {
            Name                  = "Search Service Application"
            DatabaseName          = "SP_Search"
            ApplicationPool       = $serviceAppPoolName
            PsDscRunAsCredential  = $SPSetupAccount
            DependsOn             = "[SPServiceAppPool]MainServiceAppPool"
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

    node "Server2"
    {
        #**********************************************************
        # Install Binaries
        #
        # This section installs SharePoint and its Prerequisites
        #**********************************************************

        SPInstallPrereqs InstallPrereqs {
            IsSingleInstance  = "Yes"
            Ensure            = "Present"
            InstallerPath     = "C:\binaries\prerequisiteinstaller.exe"
            OnlineMode        = $true
        }

        SPInstall InstallSharePoint {
            IsSingleInstance  = "Yes"
            Ensure            = "Present"
            BinaryDir         = "C:\binaries\"
            ProductKey        = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
            DependsOn         = "[SPInstallPrereqs]InstallPrereqs"
        }

        #**********************************************************
        # Basic farm configuration
        #
        # This section creates the new SharePoint farm object, and
        # provisions generic services and components used by the
        # whole farm
        #**********************************************************
        SPFarm JoinSPFarm
        {
            IsSingleInstance         = "Yes"
            Ensure                   = "Present"
            DatabaseServer           = "sql.contoso.com"
            FarmConfigDatabaseName   = "SP_Config"
            Passphrase               = $Passphrase
            FarmAccount              = $FarmAccount
            PsDscRunAsCredential     = $SPSetupAccount
            AdminContentDatabaseName = "SP_AdminContent"
            RunCentralAdmin          = $false
            DependsOn                = "[SPInstall]InstallSharePoint"
        }

        SPDistributedCacheService EnableDistributedCache
        {
            Name                 = "AppFabricCachingService"
            Ensure               = "Present"
            CacheSizeInMB        = 1024
            ServiceAccount       = $ServicePoolManagedAccount.UserName
            PsDscRunAsCredential = $SPSetupAccount
            CreateFirewallRules  = $true
            DependsOn            = "[SPFarm]JoinSPFarm"
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
            DependsOn            = "[SPFarm]JoinSPFarm"
        }

        SPServiceInstance ManagedMetadataServiceInstance
        {
            Name                 = "Managed Metadata Web Service"
            Ensure               = "Present"
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn            = "[SPFarm]JoinSPFarm"
        }

        SPServiceInstance BCSServiceInstance
        {
            Name                 = "Business Data Connectivity Service"
            Ensure               = "Present"
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn            = "[SPFarm]JoinSPFarm"
        }

        #**********************************************************
        # IMPORTANT NOTE: The following section configures the
        # bindings for the web application, so the web application
        # must already exist. Since this example configures the
        # web application on Server1, we need to either start the
        # DSC configuration on Server1 first and wait until the
        # web application has been created, or use a WaitForAll
        # resource here to ensure the SPWebApplication resource
        # finishes successfully on Server1 before configuring the
        # bindings here on Server2. Note the DependsOn below that's
        # commented out.
        #**********************************************************

        #**********************************************************
        # This resource depends on module xWebAdministration and
        # uses SNI to bind to a specific hostname. If you don't
        # want to use SNI, set SslFlags to 0.
        #**********************************************************
        xWebsite SslWebAppSharePointSites
        {
            Ensure      = 'Present'
            Name        = "SharePoint Sites"
            BindingInfo = @(
                    MSFT_xWebBindingInformation
                    {
                        Protocol              = 'https'
                        IPAddress             = '*'
                        Port                  = 443
                        CertificateThumbprint = '<SSL certificate thumbprint>'
                        CertificateStoreName  = 'My'
                        HostName              = 'sites.contoso.com'
                        SslFlags              = 1
                    }
            )
            # DependsOn   = '[WaitForAll]WebApplicationCreated'
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
