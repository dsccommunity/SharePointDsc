
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
 This example configures the Security Token Service

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
        SPSecurityTokenServiceConfig SecurityTokenService
        {
            IsSingleInstance      = "Yes"
            Name                  = "SPSecurityTokenService"
            NameIdentifier        = "00000003-0000-0ff1-ce00-000000000000@9f11c5ea-2df9-4950-8dcf-da8cd7aa4eff"
            UseSessionCookies     = $false
            AllowOAuthOverHttp    = $false
            AllowMetadataOverHttp = $false
            PsDscRunAsCredential  = $SetupAccount
        }
    }
}
