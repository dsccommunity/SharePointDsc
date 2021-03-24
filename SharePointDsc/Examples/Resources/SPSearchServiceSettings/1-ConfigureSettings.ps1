
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
 This example creates a new search service app in the local farm

#>

Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $SetupAccount,

        [Parameter(Mandatory = $true)]
        [PSCredential]
        $SearchAccount
    )

    Import-DscResource -ModuleName SharePointDsc

    node localhost
    {
        SPSearchServiceSettings SearchServiceSettings
        {
            IsSingleInstance      = "Yes"
            PerformanceLevel      = "Maximum"
            ContactEmail          = "sharepoint@contoso.com"
            WindowsServiceAccount = $SearchAccount
            PsDscRunAsCredential  = $SetupAccount
        }
    }
}
