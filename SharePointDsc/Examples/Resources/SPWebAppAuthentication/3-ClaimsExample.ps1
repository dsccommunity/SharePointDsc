
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
 This example shows how to configure the authentication of a web application
 in the local farm using a custom claim provider. A SPTrustedIdentityTokenIssuer
 is created named Contoso, then this SPTrustedIdentityTokenIssuer is referenced
 by the SPWebAppAuthentication as the AuthenticationProvider and the
 AuthenticationMethod is set to "Federated" value.

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
            Realm                        = "https://sharepoint.contoso.com"
            SignInUrl                    = "https://adfs.contoso.com/adfs/ls/"
            IdentifierClaim              = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
            ClaimsMappings               = @(
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
            SigningCertificateThumbPrint = "F3229E7CCA1DA812E29284B0ED75A9A019A83B08"
            ClaimProviderName            = "LDAPCP"
            ProviderSignOutUri           = "https://adfs.contoso.com/adfs/ls/"
            Ensure                       = "Present"
            PsDscRunAsCredential         = $SetupAccount
        }

        SPWebAppAuthentication ContosoAuthentication
        {
            WebAppUrl            = "http://sharepoint.contoso.com"
            Default              = @(
                MSFT_SPWebAppAuthenticationMode {
                    AuthenticationMethod = "WindowsAuthentication"
                    WindowsAuthMethod    = "NTLM"
                }
            )
            Internet             = @(
                MSFT_SPWebAppAuthenticationMode {
                    AuthenticationMethod   = "Federated"
                    AuthenticationProvider = "Contoso"
                }
            )
            PsDscRunAsCredential = $SetupAccount
            DependsOn            = "[SPTrustedIdentityTokenIssuer]SampleSPTrust"
        }
    }
}
