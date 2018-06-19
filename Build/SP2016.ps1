configuration SP2016
{
    $credsLocalAdmin = Get-AutomationPSCredential -Name "LocalAdmin"
    $credsDomainAdmin = Get-AutomationPSCredential -Name "DomainAdmin"
    $credsSPFarm      = Get-AutomationPSCredential -Name "FarmAccount"
    $credsSPSetup     = Get-AutomationPSCredential -Name "SetupAccount"

    Import-DscResource -ModuleName "SharePointDSC" -Moduleversion "3.0.0.0"
    Import-DscResource -ModuleName "xDownloadFile" -ModuleVersion "1.0"
    Import-DscResource -ModuleName "xDownloadISO" -ModuleVersion "1.0"
    Import-DscResource -ModuleName "xPendingReboot" -ModuleVersion "0.4.0.0"
    
    Node $AllNodes.NodeName
    {
        xDownloadISO DownloadSPTrial
        {
            SourcePath = "https://download.microsoft.com/download/0/0/4/004EE264-7043-45BF-99E3-3F74ECAE13E5/officeserver.img"
            DestinationDirectoryPath = "C:\SharePoint2016"
            PsDscRunAsCredential = $credsLocalAdmin
        }

        xDownloadFile AppFabricKBDL
        {
            SourcePath = "https://download.microsoft.com/download/7/B/5/7B51D8D1-20FD-4BF0-87C7-4714F5A1C313/AppFabric1.1-RTM-KB2671763-x64-ENU.exe"
            FileName = "AppFabric1.1-RTM-KB2671763-x64-ENU.exe"
            DestinationDirectoryPath = "C:\SharePoint2016\prerequisiteinstallerfiles"
            DependsOn = "[xDownloadISO]DownloadSPTrial"
            PsDscRunAsCredential = $credsLocalAdmin
        }

        xDownloadFile MicrosoftIdentityExtensionsDL
        {
            SourcePath = "http://download.microsoft.com/download/0/1/D/01D06854-CA0C-46F1-ADBA-EBF86010DCC6/rtm/MicrosoftIdentityExtensions-64.msi"
            FileName = "MicrosoftIdentityExtensions-64.msi"
            DestinationDirectoryPath = "C:\SharePoint2016\prerequisiteinstallerfiles"
            DependsOn = "[xDownloadFile]AppFabricKBDL"
            PsDscRunAsCredential = $credsLocalAdmin
        }

        xDownloadFile MSIPCDL
        {
            SourcePath = "http://download.microsoft.com/download/9/1/D/91DA8796-BE1D-46AF-8489-663AB7811517/setup_msipc_x64.msi"
            FileName = "setup_msipc_x64.msi"
            DestinationDirectoryPath = "C:\SharePoint2016\prerequisiteinstallerfiles"
            DependsOn = "[xDownloadFile]MicrosoftIdentityExtensionsDL"
            PsDscRunAsCredential = $credsLocalAdmin
        }

        xDownloadFile SQLNCLIDL
        {
            SourcePath = "https://download.microsoft.com/download/F/7/B/F7B7A246-6B35-40E9-8509-72D2F8D63B80/sqlncli_amd64.msi"
            FileName = "sqlncli.msi"
            DestinationDirectoryPath = "C:\SharePoint2016\prerequisiteinstallerfiles"
            DependsOn = "[xDownloadFile]MSIPCDL"
            PsDscRunAsCredential = $credsLocalAdmin
        }

        xDownloadFile SynchronizationDL
        {
            SourcePath = "http://download.microsoft.com/download/E/0/0/E0060D8F-2354-4871-9596-DC78538799CC/Synchronization.msi"
            FileName = "Synchronization.msi"
            DestinationDirectoryPath = "C:\SharePoint2016\prerequisiteinstallerfiles"
            DependsOn = "[xDownloadFile]SQLNCLIDL"
            PsDscRunAsCredential = $credsLocalAdmin
        }

        xDownloadFile WcfDataServices5DL
        {
            SourcePath = "http://download.microsoft.com/download/8/F/9/8F93DBBD-896B-4760-AC81-646F61363A6D/WcfDataServices.exe"
            FileName = "WcfDataServices5.exe"
            DestinationDirectoryPath = "C:\SharePoint2016\prerequisiteinstallerfiles"
            DependsOn = "[xDownloadFile]SynchronizationDL"
            PsDscRunAsCredential = $credsLocalAdmin
        }

        xDownloadFile WcfDataServices56DL
        {
            SourcePath = "http://download.microsoft.com/download/1/C/A/1CAA41C7-88B9-42D6-9E11-3C655656DAB1/WcfDataServices.exe"
            FileName = "WcfDataServices56.exe"
            DestinationDirectoryPath = "C:\SharePoint2016\prerequisiteinstallerfiles"
            DependsOn = "[xDownloadFile]WcfDataServices5DL"
            PsDscRunAsCredential = $credsLocalAdmin
        }

        xDownloadFile KBDL
        {
            SourcePath = "http://download.microsoft.com/download/D/7/2/D72FD747-69B6-40B7-875B-C2B40A6B2BDD/Windows6.1-KB974405-x64.msu"
            FileName = "Windows6.1-KB974405-x64.msu"
            DestinationDirectoryPath = "C:\SharePoint2016\prerequisiteinstallerfiles"
            DependsOn = "[xDownloadFile]WcfDataServices56DL"
            PsDscRunAsCredential = $credsLocalAdmin
        }

        xDownloadFile AppFabricDL
        {
            SourcePath = "http://download.microsoft.com/download/A/6/7/A678AB47-496B-4907-B3D4-0A2D280A13C0/WindowsServerAppFabricSetup_x64.exe"
            FileName = "WindowsServerAppFabricSetup_x64.exe"
            DestinationDirectoryPath = "C:\SharePoint2016\prerequisiteinstallerfiles"
            DependsOn = "[xDownloadFile]KBDL"
            PsDscRunAsCredential = $credsLocalAdmin
        }


        SPInstallPrereqs SharePointPrereqInstall
        {
            InstallerPath = "C:\SharePoint2016\prerequisiteinstaller.exe"
            OnlineMode = $true
            SQLNCli  = "C:\SharePoint2016\prerequisiteinstallerfiles\prerequisiteinstallerfiles\sqlncli.msi"
            IDFX = "C:\SharePoint2016\prerequisiteinstallerfiles\prerequisiteinstallerfiles\Windows6.1-KB974405-x64.msu"
            Sync = "C:\SharePoint2016\prerequisiteinstallerfiles\prerequisiteinstallerfiles\Synchronization.msi"
            AppFabric = "C:\SharePoint2016\prerequisiteinstallerfiles\prerequisiteinstallerfiles\WindowsServerAppFabricSetup_x64.exe"
            IDFX11 = "C:\SharePoint2016\prerequisiteinstallerfiles\prerequisiteinstallerfiles\MicrosoftIdentityExtensions-64.msi"
            MSIPCClient = "C:\SharePoint2016\prerequisiteinstallerfiles\prerequisiteinstallerfiles\setup_msipc_x64.msi"
            WCFDataServices = "C:\SharePoint2016\prerequisiteinstallerfiles\prerequisiteinstallerfiles\WcfDataServices5.exe"
            KB2671763 = "C:\SharePoint2016\prerequisiteinstallerfiles\prerequisiteinstallerfiles\AppFabric1.1-RTM-KB2671763-x64-ENU.exe"
            WCFDataServices56 = "C:\SharePoint2016\prerequisiteinstallerfiles\prerequisiteinstallerfiles\WcfDataServices56.exe"
            Ensure = "Present"
            # For On-prem - SXSPath = "D:\sources\sxs"
            PsDscRunAsCredential = $credsDomainAdmin
        }

        xPendingReboot AfterPrereqInstall
        {
            Name = "AfterPrereqInstall"
            DependsOn = "[SPInstallPrereqs]SharePointPrereqInstall"
            PsDscRunAsCredential = $credsDomainAdmin
        }

        SPInstall SharePointInstall
        {
            BinaryDir  = $ConfigurationData.SharePoint.Settings.BinaryPath
            ProductKey = $ConfigurationData.SharePoint.Settings.ProductKey
            Ensure     = "Present"
            DependsOn = "[xPendingReboot]AfterPrereqInstall"
            PsDscRunAsCredential = $credsSPSetup
        }

        xPendingReboot AfterSPInstall
        {
            Name = "AfterSPInstall"
            DependsOn = "[SPInstall]SharePointInstall"
            PsDscRunAsCredential = $credsDomainAdmin
        }

        SPFarm SharePointFarm
        {
            Ensure                    = "Present"
            FarmConfigDatabaseName    = "SP_Config"
            DatabaseServer            = $ConfigurationData.SharePoint.Settings.DatabaseServer
            FarmAccount               = $credsSPFarm
            Passphrase                = $credsSPFarm
            AdminContentDatabaseName  = "SP_Admin"
            RunCentralAdmin           = $Node.RunCentralAdmin
            CentralAdministrationPort = "7777"
            ServerRole                = "Application"
            PSDSCRunAsCredential      = $credsDomainAdmin
        }
    }
}