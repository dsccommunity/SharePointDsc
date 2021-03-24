
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
 This example installs the SharePoint 2013 Service Pack only in the specified window.
 It also shuts down services to speed up the installation process.

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
        SPProductUpdate InstallCUMay2016
        {
            SetupFile            = "C:\Install\SP2013SP1\officeserversp2013-kb2880552-fullfile-x64-en-us.exe"
            ShutdownServices     = $true
            BinaryInstallDays    = "sat", "sun"
            BinaryInstallTime    = "12:00am to 2:00am"
            Ensure               = "Present"
            PsDscRunAsCredential = $SetupAccount
        }
    }
}
