
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
 This example makes sure the service application exists and has a specific configuration

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
        SPPowerPointAutomationServiceApp PowerPointAutomation
        {
            Name                            = "PowerPoint Automation Service Application"
            ProxyName                       = "PowerPoint Automation Service Application Proxy"
            CacheExpirationPeriodInSeconds  = 600
            MaximumConversionsPerWorker     = 5
            WorkerKeepAliveTimeoutInSeconds = 120
            WorkerProcessCount              = 3
            WorkerTimeoutInSeconds          = 300
            ApplicationPool                 = "SharePoint Web Services"
            Ensure                          = "Present"
            PsDscRunAsCredential            = $SetupAccount
        }
    }
}
