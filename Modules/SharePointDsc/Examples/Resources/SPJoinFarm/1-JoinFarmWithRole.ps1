<#
.EXAMPLE
    This example shows how to join an existing SharePoint farm using a specific
    server role (applies to SharePoint 2016 only).
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
            ServerRole                = "WebFrontEnd"
            Passphrase                = $FarmPassPhrase
            PsDscRunAsCredential      = $SetupAccount
        }
    }
