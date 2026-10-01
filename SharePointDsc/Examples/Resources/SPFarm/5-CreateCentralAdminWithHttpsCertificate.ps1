<#PSScriptInfo

.VERSION 1.0.0

.GUID 2653a675-0c44-4a94-afd6-d4f2a11d9a94

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
 This example shows how to provision Central Administration on a vanity HTTPS URL and bind a
 managed certificate to its binding on SharePoint Server Subscription Edition. The certificate
 is first imported into SharePoint Certificate Management using the SPCertificate resource, and
 SPFarm binds it to the Central Administration HTTPS binding. The DependsOn makes sure the
 certificate is imported before the binding is created. UseServerNameIndication enables Server
 Name Indication (SNI) on the binding.

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
        $Passphrase,

        [Parameter(Mandatory = $true)]
        [PSCredential]
        $CertificatePassword
    )

    Import-DscResource -ModuleName SharePointDsc

    node localhost
    {
        SPCertificate CentralAdminCertificate
        {
            CertificateFilePath  = "C:\Certificates\CentralAdmin.pfx"
            CertificatePassword  = $CertificatePassword
            Store                = "EndEntity"
            Exportable           = $true
            Ensure               = "Present"
            PsDscRunAsCredential = $SetupAccount
        }

        SPFarm SharePointFarm
        {
            IsSingleInstance                           = "Yes"
            DatabaseServer                             = "SQL.contoso.local\SQLINSTANCE"
            FarmConfigDatabaseName                     = "SP_Config"
            AdminContentDatabaseName                   = "SP_AdminContent"
            Passphrase                                 = $Passphrase
            FarmAccount                                = $FarmAccount
            RunCentralAdmin                            = $true
            CentralAdministrationUrl                   = "https://admin.contoso.com"
            CentralAdministrationPort                  = 443
            CentralAdministrationCertificateThumbprint = "C66D8D6EC9C6E5C6D8A8A0E0F9A0B1C2D3E4F5A6"
            UseServerNameIndication                    = $true
            PsDscRunAsCredential                       = $SetupAccount
            DependsOn                                  = "[SPCertificate]CentralAdminCertificate"
        }
    }
}
