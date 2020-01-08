
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
 This example adds a new user profile service application to the local farm

#>

    Configuration Example
    {
        param(
            [Parameter(Mandatory = $true)]
            [PSCredential]
            $SetupAccount,

            [Parameter(Mandatory = $true)]
            [PSCredential]
            $FarmAccount
        )
        Import-DscResource -ModuleName SharePointDsc

        node localhost {
            SPUserProfileServiceApp UserProfileServiceApp
            {
                Name                 = "User Profile Service Application"
                ApplicationPool      = "SharePoint Service Applications"
                MySiteHostLocation   = "http://my.sharepoint.contoso.local"
                MySiteManagedPath    = "personal"
                ProfileDBName        = "SP_UserProfiles"
                ProfileDBServer      = "SQL.contoso.local\SQLINSTANCE"
                SocialDBName         = "SP_Social"
                SocialDBServer       = "SQL.contoso.local\SQLINSTANCE"
                SyncDBName           = "SP_ProfileSync"
                SyncDBServer         = "SQL.contoso.local\SQLINSTANCE"
                EnableNetBIOS        = $false
                NoILMUsed            = $true
                PsDscRunAsCredential = $SetupAccount
            }
        }
    }
