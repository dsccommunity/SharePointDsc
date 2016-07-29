<#
.EXAMPLE
    This example shows how to remove bindings from the internal-http zone for the 
    local SharePoint farm.
#>

    Configuration Example 
    {
        param(
            [Parameter(Mandatory = $true)]
            [PSCredential]
            $SetupAccount
        )
        Import-DscResource -ModuleName SharePointDsc

        SPOfficeOnlineServerBinding OosBinding 
        {
            Zone                 = "Internal-HTTP"
            DnsName              = "webapps.contoso.com"
            PsDscRunAsCredential = $SetupAccount
            Ensure               = "Absent"
        }
    }
