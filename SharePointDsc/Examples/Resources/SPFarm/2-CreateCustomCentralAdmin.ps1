
<#PSScriptInfo

.VERSION 1.0.0

.GUID 80d306fa-8bd4-4a8d-9f7a-bf40df95e661

.AUTHOR DSC Community

.COMPANYNAME DSC Community

.COPYRIGHT DSC Community contributors. All rights reserved.

.TAGS

.LICENSEURI https://github.com/dsccommunity/SharePointDsc/blob/master/LICENSE

.PROJECTURI https://github.com/dsccommunity/SharePointDsc

.ICONURI https://dsccommunity.org/images/DSC_Logo_300p.png

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
Updated author, copyright notice, and URLs.

.PRIVATEDATA

#>

<#

.DESCRIPTION
 This example shows how a basic SharePoint farm can be created. The database server and names
 are specified, and the accounts to run the setup as, the farm account and the passphrase are
 all passed in to the configuration to be applied. Here the port for the central admin site to
 run on, as well as the authentication mode for the site are also specified.

#>

    Configuration Example
    {
        param(
            [Parameter(Mandatory = $true)]
            [PSCredential]
            $FarmAccount,

            [Parameter(Mandatory = $true)]
            [PSCredential]
            $SetupAccount,

            [Parameter(Mandatory = $true)]
            [PSCredential]
            $Passphrase
        )
        Import-DscResource -ModuleName SharePointDsc

        node localhost {
            SPFarm SharePointFarm
            {
                IsSingleInstance          = "Yes"
                DatabaseServer            = "SQL.contoso.local\SQLINSTANCE"
                FarmConfigDatabaseName    = "SP_Config"
                AdminContentDatabaseName  = "SP_AdminContent"
                CentralAdministrationPort = 5000
                CentralAdministrationAuth = "Kerberos"
                Passphrase                = $Passphrase
                FarmAccount               = $FarmAccount
                RunCentralAdmin           = $true
                PsDscRunAsCredential      = $SetupAccount
            }
        }
    }
