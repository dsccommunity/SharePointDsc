<#
.EXAMPLE
    This example creates a trusted security token issuer using a signing certificate retrieved from its thumbprint, and the SPAuthenticationRealm of the SharePoint farm.
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
        SPTrustedSecurityTokenIssuer HighTrustAddinsTrust
        {
            Name                           = "HighTrustAddins"
            Description                    = "Trust for Provider-hosted high-trust add-ins"
            RegisteredIssuerNameIdentifier = "22222222-2222-2222-2222-222222222222"
            IsTrustBroker                  = $true
            SigningCertificateThumbprint   = "123ABCFACE123ABCFACE123ABCFACE123ABCFACE"
            Ensure                         = "Present"
            PsDscRunAsCredential           = $SetupAccount
        }
    }
}
