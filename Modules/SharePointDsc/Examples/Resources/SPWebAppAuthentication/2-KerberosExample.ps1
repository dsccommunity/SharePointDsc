<#
.EXAMPLE
    This example shows how to configure the authentication of a web application in the local farm using
    Kerberos without Basic Authentication enabled.
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

        node localhost {

            SPWebAppAuthentication ContosoAuthentication
            {
                WebAppUrl            = "http://sharepoint.contoso.com"
                Default              = @(
                    MSFT_SPWebAppAuthenticationMode {
                        AuthenticationMethod = "WindowsAuthentication"
                        WindowsAuthMethod    = "Kerberos"
                    }
                )
                Extranet             = @(
                    MSFT_SPWebAppAuthenticationMode {
                        AuthenticationMethod = "FBA"
                        MembershipProvider   = "MemberPRovider"
                        RoleProvider         = "RoleProvider"
                    }
                )
                PsDscRunAsCredential = $SetupAccount
            }
        }
    }
