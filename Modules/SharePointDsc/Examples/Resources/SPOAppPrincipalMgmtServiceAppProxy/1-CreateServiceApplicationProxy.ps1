<#
.EXAMPLE
    This example shows how to create a new SharePoint Online management Application Proxy in the farm
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
            SPOAppPrincipalMgmtServiceAppProxy SPOAddInManagementProxy
            {
                Name                 = "SPO Add-in Management Proxy"
                OnlineTenantUri      = "https://contoso.sharepoint.com"
                PsDscRunAsCredential = $SetupAccount
            }
        }
    }
