<#
.EXAMPLE
    This example shows how to remove an alternate URL from a specified zone for a specific
    web application.
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
            SPAlternateUrl CentralAdminAAM
            {
                WebAppUrl            = "http://sharepoint1:9999"
                Zone                 = "Intranet"
                Ensure               = "Absent"
                PsDscRunAsCredential = $SetupAccount
            }
        }
    }
