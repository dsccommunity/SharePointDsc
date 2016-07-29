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

        SPJoinFarm JoinFarm
        {
            DatabaseServer            = "SQL.contoso.local\SQLINSTANCE"
            FarmConfigDatabaseName    = "SP_Config"
            Passphrase                = $FarmPassPhrase
            PsDscRunAsCredential      = $SetupAccount
        }
    }
