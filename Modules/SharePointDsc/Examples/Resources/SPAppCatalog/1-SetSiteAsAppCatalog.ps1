<#
.EXAMPLE
    This example shows how to apply specific anti-virus configuration to the farm
#>

    Configuration Example 
    {
        param(
            [Parameter(Mandatory = $true)]
            [PSCredential]
            $SetupAccount
        )
        Import-DscResource -ModuleName SharePointDsc

        SPAppCatalog MainAppCatalog
        {
            SiteUrl              = "https://content.sharepoint.contoso.com/sites/AppCatalog"
            PsDscRunAsCredential = $SPSetupAccount
        }
    }
