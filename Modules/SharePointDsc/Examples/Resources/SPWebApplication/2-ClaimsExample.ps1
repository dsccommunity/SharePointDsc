<#
.EXAMPLE
    This example shows how to create a new web application in the local farm
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

            ##Ensure the Custom Claims Provider
            SPFarmSolution ClaimsProviderWsp
            {
                Name                 = "LDAPCP.wsp"
                LiteralPath          = "C:\src\LDAPCP.wsp"
                Ensure               = "Present"
                Version              = "1.0.0"
                PsDscRunAsCredential = $SetupAccount
            }
            #Ensure the SPTrustedIdentityTokenIssuer
             SPTrustedIdentityTokenIssuer SampleSPTrust
            {
                Name                         = "Contoso"
                Description                  = "Contoso"
                Realm                        = "https://sharepoint.contoso.com"
                SignInUrl                    = "https://adfs.contoso.com/adfs/ls/"
                IdentifierClaim              = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                ClaimsMappings               = @(
                    MSFT_SPClaimTypeMapping{
                        Name = "Email"
                        IncomingClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                    }
                    MSFT_SPClaimTypeMapping{
                        Name = "Role"
                        IncomingClaimType = "http://schemas.xmlsoap.org/ExternalSTSGroupType"
                        LocalClaimType = "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"
                    }
                )
                SigningCertificateThumbPrint = "F3229E7CCA1DA812E29284B0ED75A9A019A83B08"
                ClaimProviderName            = "LDAPCP"
                ProviderSignOutUri           = "https://adfs.contoso.com/adfs/ls/"
                Ensure                       = "Present"
                PsDscRunAsCredential         = $SetupAccount
                DependsOn = "[SPFarmSolution]ClaimsProviderWsp"
            }
            
            
            SPWebApplication HostNameSiteCollectionWebApp
            {
                Name                   = "SharePoint Sites"
                ApplicationPool        = "SharePoint Sites"
                ApplicationPoolAccount = "CONTOSO\svcSPWebApp"
                AllowAnonymous         = $false
                AuthenticationMethod   = "Claims"
                AuthenticationProvider = "Contoso"
                DatabaseName           = "SP_Content_01"
                DatabaseServer         = "SQL.contoso.local\SQLINSTANCE"
                Url                    = "http://example.contoso.local"
                Port                   = 80
                Ensure                 = "Present"
                PsDscRunAsCredential   = $SetupAccount
                DependsOn = "[SPTrustedIdentityTokenIssuer]SampleSPTrust"
            }
        }
    }
