
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
 This example shows how to apply default certificate settings to the farm

#>

Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $SetupAccount
    )

    Import-DscResource -ModuleName SharePointDsc

    node localhost
    {
        SPCertificateSettings CertificateSettings
        {
            IsSingleInstance                        = 'Yes'
            OrganizationalUnit                      = 'IT'
            Organization                            = 'Contoso'
            Locality                                = 'Seattle'
            State                                   = 'Washington'
            Country                                 = 'US'
            KeyAlgorithm                            = 'RSA'
            KeySize                                 = 2048
            EllipticCurve                           = 'nistP256'
            HashAlgorithm                           = 'SHA256'
            RsaSignaturePadding                     = 'Pkcs1'
            CertificateExpirationAttentionThreshold = 60
            CertificateExpirationWarningThreshold   = 15
            CertificateExpirationErrorThreshold     = 15
            PsDscRunAsCredential                    = $SetupAccount
        }
    }
}
