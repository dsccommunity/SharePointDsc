
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
 This example adds a new user profile sync connection to the specified user
 profile service app

#>

    Configuration Example
    {
        param(
            [Parameter(Mandatory = $true)]
            [PSCredential]
            $SetupAccount,

            [Parameter(Mandatory = $true)]
            [PSCredential]
            $ConnectionAccount
        )
        Import-DscResource -ModuleName SharePointDsc

        node localhost {
            SPUserProfileSyncConnection MainDomain
            {
                UserProfileService = "User Profile Service Application"
                Forest = "contoso.com"
                Name = "Contoso"
                ConnectionCredentials = $ConnectionAccount
                Server = "server.contoso.com"
                UseSSL = $false
                IncludedOUs = @("OU=SharePoint Users,DC=Contoso,DC=com")
                ExcludedOUs = @("OU=Notes Usersa,DC=Contoso,DC=com")
                Force = $false
                ConnectionType = "ActiveDirectory"
                PsDscRunAsCredential = $SetupAccount
            }
        }
    }
