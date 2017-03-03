<#
.EXAMPLE
    This example shows how to apply a Search Crawl Mapping rule to a search application. The
    resource takes a 'ServiceAppName' which is the name of the search service application to
    configure and provides a Url field used to 'match' the url you want to map, and a 'Target' 
    which provides your desired target value.
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
                PsDScRunAsCredential = $SetupAccount
            }
           
        }
    }


