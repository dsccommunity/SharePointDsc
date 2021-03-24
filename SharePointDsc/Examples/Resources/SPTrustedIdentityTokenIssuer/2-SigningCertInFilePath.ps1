
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
 This example deploys a trusted token issuer to the local farm, using
 a certificate in a file path.

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
            Realm                      = "https://sharepoint.contoso.com"
            SignInUrl                  = "https://adfs.contoso.com/adfs/ls/"
            IdentifierClaim            = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
            ClaimsMappings             =  @(
                MSFT_SPClaimTypeMapping {
                    Name              = "Email"
                    IncomingClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                }
                MSFT_SPClaimTypeMapping {
                    Name              = "Role"
                    IncomingClaimType = "http://schemas.xmlsoap.org/ExternalSTSGroupType"
                    LocalClaimType    = "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"
                }
            )
            SigningCertificateFilePath = "F:\Data\DSC\FakeSigning.cer"
            ClaimProviderName          = "LDAPCP"
            ProviderSignOutUri         = "https://adfs.contoso.com/adfs/ls/"
            Ensure                     = "Present"
            PsDscRunAsCredential       = $SetupAccount
        }
    }
}
