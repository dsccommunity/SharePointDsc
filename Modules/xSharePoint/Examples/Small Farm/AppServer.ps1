Configuration SharePointAppServer
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
            DependsOn  = "[xSPClearRemoteSessions]ClearRemotePowerShellSessions"
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

        xSPJoinFarm JoinSPFarm
        {
            DatabaseServer           = $DatabaseServer
            FarmConfigDatabaseName   = "SP_Config"
            Passphrase               = $FarmPassPhrase
            InstallAccount           = $InstallAccount
            DependsOn                = "[xSPInstall]InstallBinaries"
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
            DependsOn      = "[xSPJoinFarm]JoinSPFarm"
        } 
        xSPServiceInstance UserProfileServiceInstance
        {  
            Name           = "User Profile Service"
            Ensure         = "Present"
            InstallAccount = $InstallAccount
            DependsOn      = "[xSPJoinFarm]JoinSPFarm"
        }        

        #**********************************************************
        # Local configuration manager settings
        #
        # This section contains settings for the LCM of the host
        # that this configuration is applied to
        #**********************************************************
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }
    }
}
