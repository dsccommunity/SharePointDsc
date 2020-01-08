
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
 This example shows how to create a new managed account in a local farm, using
 the automatic password change schedule

#>

    Configuration Example
    {
        param(
            [Parameter(Mandatory = $true)]
            [PSCredential]
            $SetupAccount,

            [Parameter(Mandatory = $true)]
            [PSCredential]
            $ManagedAccount
        )
        Import-DscResource -ModuleName SharePointDsc

        node localhost {
            SPManagedAccount NewManagedAccount
            {
                AccountName          = $ManagedAccount.UserName
                Account              = $ManagedAccount
                Ensure               = "Present"
                Schedule             = "monthly between 7 02:00:00 and 7 03:00:00"
                PsDscRunAsCredential = $SetupAccount
            }
        }
    }
