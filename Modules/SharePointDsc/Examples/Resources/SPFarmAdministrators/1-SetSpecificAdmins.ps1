<#
.EXAMPLE
    This example shows how to set a specific list of members for the farm admins group.
    Any members not in this list will be removed. 
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
            SPFarmAdministrators LocalFarmAdmins
            {
                Name                 = "Farm Administrators"
                Members              = @("CONTOSO\user1", "CONTOSO\user2")
                PsDscRunAsCredential = $SetupAccount
            }
        }
    }
