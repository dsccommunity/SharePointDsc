
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
 This example deploys a subsite in a specific location and enables
 access requests for this web

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
        SPWeb TeamSite
        {
            Url                  = "http://sharepoint.contoso.com/sites/site/subweb"
            Name                 = "Team Sites"
            Ensure               = "Present"
            Description          = "A place to share documents with your team."
            Template             = "STS#0"
            Language             = 1033
            AddToTopNav          = $true
            UniquePermissions    = $true
            RequestAccessEmail   = "sample@contoso.com"
            PsDscRunAsCredential = $SetupAccount
        }
    }
}
