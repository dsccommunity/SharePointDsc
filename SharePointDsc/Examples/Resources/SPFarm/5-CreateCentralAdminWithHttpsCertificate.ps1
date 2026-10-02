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
 This example provisions Central Administration on a vanity HTTPS URL and binds a managed
 certificate to its binding on SharePoint Server Subscription Edition. SharePoint Certificate
 Management requires an existing farm, so the SPCertificate resource depends on SPFarm and
 imports the certificate into the store after the farm has been created. The Central
 Administration certificate binding converges once the certificate is present in the store (on a
 subsequent DSC pass if the certificate is imported in the same run). UseServerNameIndication
 enables Server Name Indication (SNI) on the binding.

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
        }

        # Certificate Management requires an existing farm, so the certificate is imported after
        # SPFarm. On the first pass SPFarm provisions the HTTPS Central Administration and
        # SPCertificate imports the certificate into the store; the binding then converges once the
        # certificate is present.
        SPCertificate CentralAdminCertificate
        {
            CertificateFilePath  = "C:\Certificates\CentralAdmin.pfx"
            CertificatePassword  = $CertificatePassword
            Store                = "EndEntity"
            Exportable           = $true
            Ensure               = "Present"
            PsDscRunAsCredential = $SetupAccount
            DependsOn            = "[SPFarm]SharePointFarm"
        }
    }
}
