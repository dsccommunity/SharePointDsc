
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
 This example deploys a trusted token issuer for SAML protocol,
 using a certificate in the local certificate store.

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
        SPTrustedIdentityTokenIssuer SampleSPTrust
        {
            Name                         = "Contoso"
            Description                  = "Contoso"
            Realm                        = "urn:sharepoint:spsites"
            SigningCertificateThumbPrint = "F0D3D9D8E38C1D55A3CEF3AAD1C18AD6A90D5628"
            SignInUrl                    = "https://adfs.contoso.local/adfs/ls/"
            ProviderSignOutUri           = "https://adfs.contoso.local/adfs/ls/"
            IdentifierClaim              = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn"
            ClaimsMappings               = @(
                MSFT_SPClaimTypeMapping
                {
                    Name              = "upn"
                    IncomingClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn"
                }
                MSFT_SPClaimTypeMapping
                {
                    Name              = "group"
                    IncomingClaimType = "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"
                }
            )
            ClaimProviderName            = "LDAPCPSE"
            Ensure                       = "Present"
            PsDscRunAsCredential         = $FarmAdminAccount
        }
    }
}
