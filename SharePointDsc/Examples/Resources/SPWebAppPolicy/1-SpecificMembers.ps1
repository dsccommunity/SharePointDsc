
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
 This example sets the specific web app policy for the specified web app to
 match the provided list below.

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
                WebAppUrl = "http://sharepoint.contoso.com"
                Members = @(
                    MSFT_SPWebPolicyPermissions {
                        Username           = "contoso\user1"
                        PermissionLevel    = "Full Control"
                        ActAsSystemAccount = $true
                    }
                    MSFT_SPWebPolicyPermissions {
                        Username        = "contoso\Group 1"
                        PermissionLevel = "Full Read"
                        IdentityType    = "Claims"
                    }
                )
                PsDscRunAsCredential = $SetupAccount
            }
        }
    }
