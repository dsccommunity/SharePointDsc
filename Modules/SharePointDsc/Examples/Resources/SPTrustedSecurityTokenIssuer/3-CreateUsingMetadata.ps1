<#
.EXAMPLE
    This example creates a trusted security token issuer that will be configured using the metadata file of the ACS tenant.
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
