<#
.EXAMPLE
    This example shows how to create a new web application in the local farm
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
            SPWebApplication HostNameSiteCollectionWebApp
            {
                Name                   = "SharePoint Sites"
                ApplicationPool        = "SharePoint Sites"
                ApplicationPoolAccount = "CONTOSO\svcSPWebApp"
                AllowAnonymous         = $false
                AuthenticationMethod   = "NTLM"
                DatabaseName           = "SP_Content_01"
                DatabaseServer         = "SQL.contoso.local\SQLINSTANCE"
                Url                    = "http://example.contoso.local"
                Port                   = 80
                Ensure                 = "Present"
                PsDscRunAsCredential   = $SetupAccount
            }
        }
    }
