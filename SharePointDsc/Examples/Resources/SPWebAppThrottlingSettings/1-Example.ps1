
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
 This example shows how to apply throttling settings to a specific web app

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
            SPWebAppThrottlingSettings PrimaryWebAppThrottlingSettings
            {
                WebAppUrl                = "http://example.contoso.local"
                ListViewThreshold        = 5000
                AllowObjectModelOverride = $false
                HappyHourEnabled         = $true
                HappyHour                = MSFT_SPWebApplicationHappyHour {
                    Hour     = 3
                    Minute   = 0
                    Duration = 1
                }
                PsDscRunAsCredential     = $SetupAccount
            }
        }
    }
