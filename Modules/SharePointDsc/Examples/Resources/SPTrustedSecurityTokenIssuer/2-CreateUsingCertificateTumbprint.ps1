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
