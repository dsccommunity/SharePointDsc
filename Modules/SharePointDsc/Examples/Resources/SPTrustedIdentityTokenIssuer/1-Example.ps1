<#
.EXAMPLE
    This example deploys a trusted token issuer to the local farm.
#>

    Configuration Example 
    {
        param(
            [Parameter(Mandatory = $true)]
            [PSCredential]
            $SetupAccount
        )
        Import-DscResource -ModuleName SharePointDsc

        node localhost {
            SPTrustedIdentityTokenIssuer SampleSPTrust
            {
                Name                         = "Contoso"
                Description                  = "Contoso"
                Realm                        = "https://sharepoint.contoso.com"
                SignInUrl                    = "https://adfs.contoso.com/adfs/ls/"
                IdentifierClaim              = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                ClaimsMappings               = @( @{Name = "Email"; IncomingClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"}, @{Name = "Account name"; IncomingClaimType = "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"; LocalClaimType = "http://schemas.xmlsoap.org/customSPGroupClaimType"} )
                SigningCertificateThumbPrint = "F3229E7CCA1DA812E29284B0ED75A9A019A83B08"
                ClaimProviderName            = "LDAPCP"
                ProviderSignOutUri           = "https://adfs.contoso.com/adfs/ls/"
                Ensure                       = "Present"
                PsDscRunAsCredential         = $SetupAccount
            }
        }
    }
