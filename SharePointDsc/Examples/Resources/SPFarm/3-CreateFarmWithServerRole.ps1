
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
 all passed in to the configuration to be applied. By default the central admin site in this
 example is provisioned to port 9999 using NTLM authentication. In this example we also see
 the server role defined as "Application" which tells SharePoint 2016/2019 the role to apply to
 this server as soon as the farm is created. This property is not supported for SharePoint 2013
 and so this specific example would fail if used against that verison.

#>

Configuration Example
{
    param
    (
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

    node localhost
    {
        SPFarm SharePointFarm
        {
            IsSingleInstance         = "Yes"
            DatabaseServer           = "SQL.contoso.local\SQLINSTANCE"
            FarmConfigDatabaseName   = "SP_Config"
            AdminContentDatabaseName = "SP_AdminContent"
            ServerRole               = "Application"
            Passphrase               = $Passphrase
            FarmAccount              = $FarmAccount
            RunCentralAdmin          = $true
            PsDscRunAsCredential     = $SetupAccount
        }
    }
}
