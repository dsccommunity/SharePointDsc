
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
 This example deploys a trusted token issuer for OIDC protocol,
 using manually specified parameters.

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
            Name                       = "Contoso"
            Description                = "Contoso"
            DefaultClientIdentifier    = "11111111-1111-1111-1111-111111111111"
            RegisteredIssuerName       = "https://adfs.contoso.local/adfs"
            AuthorizationEndPointUri   = "https://adfs.contoso.local/adfs/oauth2/authorize"
            SignOutUrl                 = "https://adfs.contoso.local/adfs/oauth2/logout"
            SigningCertificateFilePath = "$SetupPath\Certificates\ADFS Signing.cer"
            IdentifierClaim            = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn"
            ClaimsMappings             = @(
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
            ClaimProviderName          = "LDAPCPSE"
            Ensure                     = "Present"
            PsDscRunAsCredential       = $FarmAdminAccount
        }
    }
}
