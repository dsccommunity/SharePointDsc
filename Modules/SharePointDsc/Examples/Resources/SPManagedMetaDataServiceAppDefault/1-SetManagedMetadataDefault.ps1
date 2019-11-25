<#
.EXAMPLE
    This example shows how to configure a default Managed Metadata service app for the default
    proxy group.
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
        SPManagedMetaDataServiceAppDefault ManagedMetadataServiceAppDefault
        {
            ServiceAppProxyGroup           = "Default"
            DefaultSiteCollectionProxyName = "Managed Metadata Service Application Proxy"
            DefaultKeywordProxyName        = "Managed Metadata Service Application Proxy"
            PsDscRunAsCredential           = $SetupAccount
        }
    }
}
