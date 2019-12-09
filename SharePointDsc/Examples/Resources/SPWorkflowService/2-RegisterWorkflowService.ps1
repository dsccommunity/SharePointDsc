<#
.EXAMPLE
    This example registers the workflow service specifying a custom scope name.
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
                WorkflowHostUri      = "http://workflow.sharepoint.contoso.com"
                ScopeName            = "SharePointWorkflow"
                SPSiteUrl            = "http://sites.sharepoint.com"
                AllowOAuthHttp       = $true
                PsDscRunAsCredential = $SetupAccount
            }
        }
    }
