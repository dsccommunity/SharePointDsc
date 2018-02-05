<#
.EXAMPLE
    This example adds provider realms to existing trusted token issuer.
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
            $ProviderRealms = @()
            $ProviderRealms += MSFT_SPProviderRealm {
                                    RealmUrl = "https://search.contoso.com"
                                    RealmUrn = "urn:sharepoint:contoso:search"
                                }
            $ProviderRealms += MSFT_SPProviderRealm {
                                    RealmUrl = "https://intranet.contoso.com"
                                    RealmUrn = "urn:sharepoint:contoso:intranet"
                                }
            SPTrustedIdentityTokenIssuerProviderRealms TeamSite
            {
                IssuerName               = "Contoso"
                ProviderRealms           = $ProviderRealms
                Ensure                   = "Present"
                PsDscRunAsCredential     = $SetupAccount
            }
        }
    }
