<#
.EXAMPLE
    This example shows how to ensure that the Business Data Connectivity Service 
    is not running on the local server. 
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
            SPPublishServiceApplication UnpublishSecureStoreServiceApp
            {  
                Name           = "Secure Store Service Application"
                Ensure         = "Absent"
                InstallAccount = $SetupAccount
            }
        }
    }
