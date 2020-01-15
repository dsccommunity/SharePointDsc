
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
 This example applies the distributed cache service to the current server,
 but will not apply the rules to allow it to communicate with other cache
 hosts to the Windows Firewall. Use this approach if you have an alternate
 firewall solution.

#>

    Configuration Example
    {
        param(
            [Parameter(Mandatory = $true)]
            [PSCredential]
            $SetupAccount
        )
        Import-DscResource -ModuleName SharePointDsc

        node localhost {
            SPDistributedCacheService EnableDistributedCache
            {
                Name                 = "AppFabricCachingService"
                CacheSizeInMB        = 8192
                ServiceAccount       = "DEMO\ServiceAccount"
                PsDscRunAsCredential = $SetupAccount
                CreateFirewallRules  = $false
            }
        }
    }
