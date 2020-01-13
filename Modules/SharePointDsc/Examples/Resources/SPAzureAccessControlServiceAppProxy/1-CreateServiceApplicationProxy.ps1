<#
.EXAMPLE
    This example shows how to create a new Azure Access Control Service Application Proxy in the farm
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
            SPAzureAccessControlServiceAppProxy SPOACS
            {
                Name                       = "SPO ACS"
                MetadataServiceEndpointUri = "https://accounts.accesscontrol.windows.net/contoso.onmicrosoft.com/metadata/json/1"
                PsDscRunAsCredential       = $SetupAccount
            }
        }
    }
