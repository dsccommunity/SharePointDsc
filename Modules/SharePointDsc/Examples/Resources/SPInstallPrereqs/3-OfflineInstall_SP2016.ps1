<#
.EXAMPLE
    This module will install the prerequisites for SharePoint 2016. This resource will run in
    offline mode, running all prerequisite installations from the specified paths.
#>

    Configuration Example
    {
        param(
            [Parameter(Mandatory = $true)]
            [PSCredential]
            $SetupAccount
        )
        Import-DscResource -ModuleName SharePointDsc

        node localhost {
            SPInstallPrereqs InstallPrerequisites
            {
                InstallerPath     = "C:\SPInstall\Prerequisiteinstaller.exe"
                OnlineMode        = $false
                SXSpath          = "c:\SPInstall\Windows2012r2-SXS"
                SQLNCli           = "C:\SPInstall\prerequisiteinstallerfiles\sqlncli.msi"
                Sync              = "C:\SPInstall\prerequisiteinstallerfiles\Synchronization.msi"
                AppFabric         = "C:\SPInstall\prerequisiteinstallerfiles\WindowsServerAppFabricSetup_x64.exe"
                IDFX11            = "C:\SPInstall\prerequisiteinstallerfiles\MicrosoftIdentityExtensions-64.msi"
                MSIPCClient       = "C:\SPInstall\prerequisiteinstallerfiles\setup_msipc_x64.msi"
                WCFDataServices56 = "C:\SPInstall\prerequisiteinstallerfiles\WcfDataServices56.exe"
                MSVCRT11          = "C:\SPInstall\prerequisiteinstallerfiles\"
                MSVCRT14          = "C:\SPInstall\prerequisiteinstallerfiles\"
                KB3092423         = "C:\SPInstall\prerequisiteinstallerfiles\"
                ODBC              = "C:\SPInstall\prerequisiteinstallerfiles\"
                DotNetFx          = "C:\SPInstall\prerequisiteinstallerfiles\"
            }
        }
    }
