<#
.EXAMPLE
    This example sets the farm atuhentication realm.
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
            SPAuthenticationRealm AuthenticationRealm
            {
                IsSingleInstance     = "Yes"
                AuthenticationRealm  = "14757a87-4d74-4323-83b9-fb1e77e8f22f"
                PsDscRunAsCredential = $SetupAccount
            }
        }
    }
