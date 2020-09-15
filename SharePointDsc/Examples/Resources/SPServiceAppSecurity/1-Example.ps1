
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
 This example shows how full control permission can be given to the farm
 account and service app pool account to the user profile service app's
 sharing permission.
 It also shows granting access to specific areas to a user.

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
        $membersToInclude = @()
        $membersToInclude += MSFT_SPServiceAppSecurityEntry {
            Username     = "CONTOSO\SharePointFarmAccount"
            AccessLevels = @("Full Control")
        }
        $membersToInclude += MSFT_SPServiceAppSecurityEntry {
            Username     = "CONTOSO\SharePointServiceApps"
            AccessLevels = @("Full Control")
        }
        $membersToInclude += MSFT_SPServiceAppSecurityEntry {
            Username     = "CONTOSO\User1"
            AccessLevels = @("Manage Profiles", "Manage Social Data")
        }
        SPServiceAppSecurity UserProfileServiceSecurity
        {
            ServiceAppName       = "User Profile Service Application"
            SecurityType         = "Administrators"
            MembersToInclude     = $membersToInclude
            MembersToExclude     = @("CONTOSO\BadAccount1", "CONTOSO\BadAccount2")
            PsDscRunAsCredential = $SetupAccount
        }
    }
}
