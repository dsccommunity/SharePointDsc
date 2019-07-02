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
            Name                 = "ACS Trust"
            Description          = "Trust with ACS tenant TENANT.onmicrosoft.com"
            MetadataEndPoint     = "https://accounts.accesscontrol.windows.net/TENANT.onmicrosoft.com/metadata/json/1"
            IsTrustBroker        = $true
            Ensure               = "Present"
            PsDscRunAsCredential = $SetupAccount
        }
    }
}
