
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
 This module will install the prerequisites for SharePoint 2016/2019. This resource will run in
 offline mode, running all prerequisite installations from the specified paths.

#>

Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $SetupAccount
    )

    Import-DscResource -ModuleName SharePointDsc

    node localhost
    {
        SPInstallPrereqs 'InstallPrerequisitesSPSE'
        {
            IsSingleInstance  = "Yes"
            InstallerPath     = "C:\SPInstall\Prerequisiteinstaller.exe"
            OnlineMode        = $false
            SXSpath           = "C:\SPInstall\Windows2012r2-SXS"
            DotNet48          = 'C:\SPInstall\ndp48-x86-x64-allos-enu.exe'
            MSVCRT142         = 'C:\SPInstall\VC_redist.x64.exe'
        }
    }
}
