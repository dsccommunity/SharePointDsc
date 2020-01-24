<#
.EXAMPLE
    This example shows how to configure a custom proxy group and specify its default Managed
    Metadata service app.
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
        SPServiceAppProxyGroup ProxyGroup1
        {
            Name                 = "Proxy Group 1"
            Ensure               = "Present"
            ServiceAppProxies    = @("User Profile Service Application", "MMS Service Application", "State Service Application")
            PsDscRunAsCredential = $SetupAccount
        }

        SPManagedMetaDataServiceAppDefault ManagedMetadataServiceAppDefault
        {
            ServiceAppProxyGroup           = "Proxy Group 1"
            DefaultSiteCollectionProxyName = "MMS Service Application Proxy"
            DefaultKeywordProxyName        = "MMS Service Application Proxy"
            PsDscRunAsCredential           = $SetupAccount
        }
    }
}

<#

.DESCRIPTION
 This example shows how to configure a custom proxy group and specify its default Managed
 Metadata service app.

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
        SPServiceAppProxyGroup ProxyGroup1
        {
            Name                 = "Proxy Group 1"
            Ensure               = "Present"
            ServiceAppProxies    = @("User Profile Service Application","MMS Service Application","State Service Application")
            PsDscRunAsCredential = $SetupAccount
        }

        SPManagedMetaDataServiceAppDefault ManagedMetadataServiceAppDefault
        {
            ServiceAppProxyGroup           = "Proxy Group 1"
            DefaultSiteCollectionProxyName = "MMS Service Application Proxy"
            DefaultKeywordProxyName        = "MMS Service Application Proxy"
            PsDscRunAsCredential           = $SetupAccount
        }
    }
}
