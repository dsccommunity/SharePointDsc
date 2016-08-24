<#
.EXAMPLE
    This example shows how to create a remote sharepoint search result source
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
            SPSearchResultSource RemoteSharePointFarm
            {
                Name = "External SharePoint results"
                SearchServiceAppName = "Search Service Application"
                Query = "{searchTerms}"
                ProviderType = "Remote SharePoint Provider"
                PsDscRunAsCredential = $SetupAccount
            }
        }
    }
