
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
 This example shows how certain changes are made to the farm admins groups. Here any
 members in the MembersToInclude property are added, and members in the MembersToExclude
 property are removed. Any members that exist in the farm admins group that aren't listed
 in either of these properties are left alone.

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
        SPFarmAdministrators LocalFarmAdmins
        {
            IsSingleInstance     = "Yes"
            MembersToInclude     = @("CONTOSO\user1")
            MembersToExclude     = @("CONTOSO\user2")
            PsDscRunAsCredential = $SetupAccount
        }
    }
}
