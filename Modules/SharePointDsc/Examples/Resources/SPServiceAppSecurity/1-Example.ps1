<#
.EXAMPLE
    This example shows how full control permission can be given to the farm 
    account and service app pool account to the user profile service app's 
    sharing permission.
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
                                    Username    = "CONTOSO\SharePointFarmAccount"
                                    AccessLevel = "Full Control"
                                }
            $membersToInclude += MSFT_SPServiceAppSecurityEntry {
                                    Username    = "CONTOSO\SharePointServiceApps"
                                    AccessLevel = "Full Control"
                                }
            SPServiceAppSecurity UserProfileServiceSecurity
            {
                ServiceAppName       = "User Profile Service Application"
                SecurityType         = "SharingPermissions"
                MembersToInclude     = $membersToInclude
                MembersToExclude     = @("CONTOSO\BadAccount1", "CONTOSO\BadAccount2")
                PsDscRunAsCredential = $SetupAccount 
            }
        }
    }
