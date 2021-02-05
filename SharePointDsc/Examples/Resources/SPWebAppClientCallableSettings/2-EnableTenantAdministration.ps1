
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
 This example shows how to enable tenant administration for a web application in a SharePoint 2013 farm

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
        $proxyLibraries = @()
        $proxyLibraries += MSFT_SPProxyLibraryEntry {
            AssemblyName             = "Microsoft.Online.SharePoint.Dedicated.TenantAdmin.ServerStub, Version=15.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c"
            SupportAppAuthentication = $true
        }

        SPWebAppClientCallableSettings TenantAdministration
        {
            WebAppUrl            = "http://example.contoso.local"
            ProxyLibraries       = $proxyLibraries
            PsDscRunAsCredential = $SetupAccount
        }
    }
}
