<#
.EXAMPLE
    This example disables Project Server in the current environment
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
        SPProjectServerLicense ProjectLicense
        {
            Ensure               = "Absent"
            PsDscRunAsCredential = $SetupAccount
        }
    }
}
