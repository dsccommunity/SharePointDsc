<#
.EXAMPLE
    This example shows how to add contoso.com in PeoplePickerSettingsSearchADDomains for a web application
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
            SPWebAppPeoplePickerSettingsSearchADDomains ContosoDomain
            {
                Url                    = 'http://intranet.contoso.local'
                DomainName             = 'contoso.com'
                LoginName              = 'CONTOSO\SVC-SP-LdapReader'
                Ensure                 = 'Present'
                PsDscRunAsCredential   = $SetupAccount
            }
        }
    }
