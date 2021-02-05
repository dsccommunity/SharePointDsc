
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
 This example adds provider realms to existing trusted token issuer.
 Existing will be removed.

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
        $ProviderRealms = @()
        $ProviderRealms += MSFT_SPProviderRealm {
            RealmUrl = "https://search.contoso.com"
            RealmUrn = "urn:sharepoint:contoso:search"
        }

        $ProviderRealms += MSFT_SPProviderRealm {
            RealmUrl = "https://intranet.contoso.com"
            RealmUrn = "urn:sharepoint:contoso:intranet"
        }

        SPTrustedIdentityTokenIssuerProviderRealms Farm1OverwriteExample
        {
            IssuerName           = "Contoso"
            ProviderRealms       = $ProviderRealms
            Ensure               = "Present"
            PsDscRunAsCredential = $SetupAccount
        }
    }
}
