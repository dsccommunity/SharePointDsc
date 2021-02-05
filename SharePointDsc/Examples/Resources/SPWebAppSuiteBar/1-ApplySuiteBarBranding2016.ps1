
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
 This example sets the branding for the suite bar of a given
 Web Application in SharePoint 2016/2019.

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
        SPWebAppSuiteBar SP2016Branding
        {
            WebAppUrl                         = "https://intranet.sharepoint.contoso.com"
            SuiteNavBrandingLogoNavigationUrl = "http://sites.sharepoint.com"
            SuiteNavBrandingLogoTitle         = "This is my logo"
            SuiteNavBrandingLogoUrl           = "http://sites.sharepoint.com/images/logo.gif"
            SuiteNavBrandingText              = "SharePointDSC WebApp"
            PsDscRunAsCredential              = $SetupAccount
        }
    }
}
