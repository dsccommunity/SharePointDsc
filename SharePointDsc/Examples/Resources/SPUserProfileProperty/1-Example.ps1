
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
 This example deploys/updates the WorkEmail2 property in the user profile service
 app

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

        SPUserProfileProperty WorkEmailProperty
        {
            Name                 = "WorkEmail2"
            Ensure               = "Present"
            UserProfileService   = "User Profile Service Application"
            DisplayName          = "Work Email"
            Type                 = "Email"
            Description          = "" #implementation isn't using it yet
            PolicySetting        = "Mandatory"
            PrivacySetting       = "Public"
            PropertyMappings     = @(
                MSFT_SPUserProfilePropertyMapping {
                    ConnectionName = "contoso.com"
                    PropertyName   = "mail"
                    Direction      = "Import"
                }
            )
            Length               = 10
            DisplayOrder         = 25
            IsEventLog           = $false
            IsVisibleOnEditor    = $true
            IsVisibleOnViewer    = $true
            IsUserEditable       = $true
            IsAlias              = $false
            IsSearchable         = $false
            TermStore            = ""
            TermGroup            = ""
            TermSet              = ""
            UserOverridePrivacy  = $false
            PsDscRunAsCredential = $SetupAccount
        }
    }
}
