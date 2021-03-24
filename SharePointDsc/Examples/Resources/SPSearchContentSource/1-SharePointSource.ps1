
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
 This example shows how to create a SharePoint sites content source

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
        SPSearchContentSource LocalSharePointSites
        {
            Name                 = "Local SharePoint Sites"
            ServiceAppName       = "Search Service Application"
            ContentSourceType    = "SharePoint"
            Addresses            = @("http://sharepointsite1.contoso.com", "http://sharepointsite2.contoso.com")
            CrawlSetting         = "CrawlSites"
            ContinuousCrawl      = $true
            FullSchedule         = $null
            Priority             = "Normal"
            Ensure               = "Present"
            PsDscRunAsCredential = $SetupAccount
        }
    }
}
