<#
.EXAMPLE
    This example shows how to create a Search Authoratative Page
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
            SPSearchAuthoratativePage AuthoratativePage
            {
                ServiceAppName       = "Search Service Application"
                Path                 = "http://site.sharepoint.com/Pages/authoratative.aspx"
                Action               = "Authoratative"
                Level                = 0.0
                Ensure               = "Present"
                PsDscRunAsCredential = $SetupAccount
            }
        }
    }
