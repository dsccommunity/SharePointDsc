
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
 This example shows how to configure SharePoint Subscription Edition
 Certificate Management settings for a new web application in the local farm

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
        SPWebApplication HTTPSWebApp
        {
            Name                    = "SharePoint Sites"
            WebAppUrl               = "http://example.contoso.local"
            ApplicationPool         = "SharePoint Sites"
            ApplicationPoolAccount  = "CONTOSO\svcSPWebApp"
            Port                    = 80
            DatabaseName            = "SP_Content_01"
            DatabaseServer          = "SQL.contoso.local\SQLINSTANCE"
            AllowAnonymous          = $false
            AllowLegacyEncryption   = $true
            CertificateThumbprint   = '7CF9E91F141FCA1049F56AB96BE2A1D7D3F9198D'
            UseServerNameIndication = $false
            Ensure                  = "Present"
            PsDscRunAsCredential    = $SetupAccount
        }
    }
}
