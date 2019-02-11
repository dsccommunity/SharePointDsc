<#
.EXAMPLE
    This example shows how to configure SharePoint Incoming Email in Automatic Mode
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
        SPIncomingEmailSettings AutomaticEmail
        {
            IsSingleInstance     = "Yes"
            Ensure               = "Present"
            UseAutomaticSettings = $true
            UseDirectoryManagementService = "No"
            ServerDisplayAddress = "contoso.com"
            PsDscRunAsCredential = $SetupAccount
        }
    }
}
