<#
.EXAMPLE
    This example shows how to configure the authentication of a web application in the
    local farm using Classic authentication.
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
            SPWebAppAuthentication ContosoAuthentication
            {
                WebAppUrl            = "http://sharepoint.contoso.com"
                Default              = @(
                    MSFT_SPWebAppAuthenticationMode {
                        AuthenticationMethod = "Classic"
                    }
                )
                PsDscRunAsCredential = $SetupAccount
            }
        }
    }
