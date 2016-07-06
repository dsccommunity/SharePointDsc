<#
.EXAMPLE
    This example shows how to apply app URLs to the current farm. 
#>

    Configuration Example 
    {
        param(
            [Parameter(Mandatory = $true)]
            [PSCredential]
            $SetupAccount
        )
        Import-DscResource -ModuleName SharePointDsc

        SPAppDomain LocalFarmAppUrls
        {
            AppDomain            = "contosointranetapps.com"
            Prefix               = "app"
            PsDscRunAsCredential = $InstallAccount
        }
    }
