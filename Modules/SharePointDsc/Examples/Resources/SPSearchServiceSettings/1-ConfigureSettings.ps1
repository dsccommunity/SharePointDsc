<#
.EXAMPLE
    This example creates a new search service app in the local farm
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
            SPSearchServiceSettings SearchServiceSettings
            {
                IsSingleInstance      = "Yes"
                PerformanceLevel      = "Maximum"
                ContactEmail          = "sharepoint@contoso.com"
                WindowsServiceAccount = $credential
                PsDscRunAsCredential  = $SetupAccount
            }
        }
    }
