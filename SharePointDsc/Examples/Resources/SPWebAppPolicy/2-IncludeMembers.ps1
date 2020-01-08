
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
 This example shows how to include specific members while excluding other members
 from the policy of the web app.

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
            SPWebAppPolicy WebAppPolicy
            {
                WebAppUrl            = "http://sharepoint.contoso.com"
                MembersToInclude = @(
                    @(MSFT_SPWebPolicyPermissions {
                        Username        = "contoso\user1"
                        PermissionLevel = "Full Control"
                    })
                    @(MSFT_SPWebPolicyPermissions {
                        Username        = "contoso\user2"
                        PermissionLevel = "Full Read"
                    })
                )
                MembersToExclude = @(
                    @(MSFT_SPWebPolicyPermissions {
                        Username = "contoso\user3"
                    })
                )
                SetCacheAccountsPolicy = $true
                PsDscRunAsCredential   = $SetupAccount
            }
        }
    }
