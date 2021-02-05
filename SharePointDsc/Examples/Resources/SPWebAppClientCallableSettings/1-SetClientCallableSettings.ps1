
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
 This example shows how to set the client callable settings for a web application

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
        SPWebAppClientCallableSettings DefaultClientCallableSettings
        {
            WebAppUrl                          = "http://example.contoso.local"
            MaxResourcesPerRequest             = 16
            MaxObjectPaths                     = 256
            ExecutionTimeout                   = 90
            RequestXmlMaxDepth                 = 32
            EnableXsdValidation                = $true
            EnableStackTrace                   = $false
            RequestUsageExecutionTimeThreshold = 800
            EnableRequestUsage                 = $true
            LogActionsIfHasRequestException    = $true
            PsDscRunAsCredential               = $SetupAccount
        }
    }
}
