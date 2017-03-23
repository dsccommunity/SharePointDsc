<#
.EXAMPLE
    This example shows how to remove an App Principal to a site
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
            SPAppPrincipal ContosoAppPrincipal
            {
                DisplayName            = "Contoso App"
                Site                   = "http://site.sharepoint.com"
                AppId                  = "40c0ab1a-6cbc-4bfa-a84e-940356d76c28"
                Ensure                 = "Absent"
                PsDscRunAsCredential = $SetupAccount
            }
        }
    }
