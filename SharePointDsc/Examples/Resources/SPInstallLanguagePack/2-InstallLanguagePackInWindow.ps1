
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
 This module will install the SharePoint Language Pack in the specified timeframe.
 The binaries for SharePoint in this scenario are stored at C:\SPInstall (so it
 will look to run C:\SPInstall\Setup.exe)

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
        SPInstallLanguagePack InstallLPBinaries
        {
            BinaryDir         = "C:\SPInstall"
            BinaryInstallDays = "sat", "sun"
            BinaryInstallTime = "12:00am to 2:00am"
            Ensure            = "Present"
        }
    }
}
