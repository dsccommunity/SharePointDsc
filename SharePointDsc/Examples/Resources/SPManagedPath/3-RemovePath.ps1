<#
.EXAMPLE
    This example shows how to remove a wildcard managed path from a specific web application
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
            SPManagedPath TestManagedPath
            {
                WebAppUrl            = "http://sharepoint.contoso.com"
                RelativeUrl          = "teams"
                Explicit             = $false
                HostHeader           = $true
                Ensure               = "Absent"
                PsDscRunAsCredential = $SetupAccount
            }
        }
    }
