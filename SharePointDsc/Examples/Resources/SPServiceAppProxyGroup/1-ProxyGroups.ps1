
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
 This example creates two seperate proxy groups of service apps that can be
 assigned to web apps in the farm

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
            SPServiceAppProxyGroup ProxyGroup1
            {
                Name                = "Proxy Group 1"
                Ensure              = "Present"
                ServiceAppProxies   = "Web 1 User Profile Service Application","Web 1 MMS Service Application","State Service Application"
            }

            SPServiceAppProxyGroup ProxyGroup2
            {
                Name                = "Proxy Group 2"
                Ensure              = "Present"
                ServiceAppProxiesToInclude = "Web 2 User Profile Service Application"
            }
        }
    }
