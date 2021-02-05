
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
 This module will install SharePoint Foundation 2013 to the local server

#>

Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $SetupAccount
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration

    node localhost
    {
        Package InstallSharePointFoundation
        {
            Ensure     = "Present"
            Name       = "Microsoft SharePoint Foundation 2013 Core"
            Path       = "E:\SharePoint2013\Setup.exe"
            Arguments  = "/config E:\SharePoint2013\files\setupfarmsilent\config.xml"
            ProductID  = "90150000-1014-0000-1000-0000000FF1CE"
            ReturnCode = 0
        }
    }
}
