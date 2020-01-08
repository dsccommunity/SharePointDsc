
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
 This example gives admin access to the specified users for the local farm as well as
 all content databases in the local farm.

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
            SPShellAdmins ShellAdmins
            {
                IsSingleInstance = "Yes"
                Members          = "CONTOSO\user1", "CONTOSO\user2"
                Databases        = @(
                    @(MSFT_SPDatabasePermissions {
                        Name = "SharePoint_Content_1"
                        Members = "CONTOSO\user2", "CONTOSO\user3"
                    })
                    @(MSFT_SPDatabasePermissions {
                        Name = "SharePoint_Content_2"
                        Members = "CONTOSO\user3", "CONTOSO\user4"
                    })
                )
            }
        }
    }
