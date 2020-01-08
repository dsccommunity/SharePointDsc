
<#PSScriptInfo

.VERSION 1.0.0

.GUID 80d306fa-8bd4-4a8d-9f7a-bf40df95e661

.AUTHOR DSC Community

.COMPANYNAME DSC Community

.COPYRIGHT DSC Community contributors. All rights reserved.

.TAGS

.LICENSEURI https://github.com/dsccommunity/SharePointDsc/blob/master/LICENSE

.PROJECTURI https://github.com/dsccommunity/SharePointDsc

.ICONURI https://dsccommunity.org/images/DSC_Logo_300p.png

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
Updated author, copyright notice, and URLs.

.PRIVATEDATA

#>

<#

.DESCRIPTION
 This module will install the prerequisites for SharePoint 2013. This resource will run in
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
                IsSingleInstance  = "Yes"
                InstallerPath     = "C:\SPInstall\Prerequisiteinstaller.exe"
                OnlineMode        = $false
                SXSpath          = "c:\SPInstall\Windows2012r2-SXS"
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
            }
        }
    }
