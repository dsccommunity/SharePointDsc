<#
.EXAMPLE
    This example shows how to apply settings to a sepcific URL in search
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
            
            SPSearchCrawlMapping IntranetCrawlMapping 
            {
                ServiceAppName = "Search Service Application"
                Url = "http://crawl.sharepoint.com"
                Target = "http://site.sharepoint.com"
                Ensure = "Present"
                InstallAccount = $SetupAccount
            }
           
        }
    }


