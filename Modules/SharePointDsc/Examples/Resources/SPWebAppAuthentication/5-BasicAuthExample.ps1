<#
.EXAMPLE
    This example shows how to configure the authentication of a web application in the local farm using NTLM
    with Basic Authentication enabled.
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
                        WindowsAuthMethod    = "NTLM"
                        UseBasicAuth         = $true
                    }
                )
                PsDscRunAsCredential = $SetupAccount
            }
        }
    }
