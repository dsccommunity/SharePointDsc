
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
 This example shows to set outgoing email settings for the entire farm. Use the URL
 of the central admin site for the web app URL to apply for the entire farm.

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
            SPOutgoingEmailSettings FarmWideEmailSettings
            {
                WebAppUrl             = "http://sharepoint1:2013"
                SMTPServer            = "smtp.contoso.com"
                FromAddress           = "sharepoint`@contoso.com"
                ReplyToAddress        = "noreply`@contoso.com"
                CharacterSet          = "65001"
                PsDscRunAsCredential  = $SetupAccount
            }
        }
    }
