<#
.EXAMPLE
    This example shows how to configure SharePoint Incoming Email in Advanced Mode
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
            UseAutomaticSettings = $false
            UseDirectoryManagementService = "No"
            ServerDisplayAddress = "contoso.com"
            DropFolder           = "\\MailServer\Pickup"
            PsDscRunAsCredential = $SetupAccount
        }
    }
}
