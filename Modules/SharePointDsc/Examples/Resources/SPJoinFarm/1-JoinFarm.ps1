<#
.EXAMPLE
    This example shows how to join an existing SharePoint farm.
#>

    Configuration Example 
    {
        param(
            [Parameter(Mandatory = $true)]
            [PSCredential]
            $SetupAccount,

            [Parameter(Mandatory = $true)]
            [PSCredential]
            $Passphrase
        )
        Import-DscResource -ModuleName SharePointDsc

        node localhost {
            SPJoinFarm JoinFarm
            {
                DatabaseServer            = "SQL.contoso.local\SQLINSTANCE"
                FarmConfigDatabaseName    = "SP_Config"
                Passphrase                = $Passphrase
                PsDscRunAsCredential      = $SetupAccount
            }
        }
    }
