<#
.EXAMPLE
    This example registers the workflow service over http.
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
            SPWorkflowService WorkflowService
            {
                WorkflowServiceUri                      = "http://workflow.sharepoint.contoso.com"
                SPSiteUrl                               = "http://sites.sharepoint.com"
                SuiteNavBrandingLogoTitle               = "This is my logo"
                AllowOAuthHttp                          = $true
                PsDscRunAsCredential                    = $SetupAccount
            }
        }
    }
