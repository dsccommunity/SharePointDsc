<#
.EXAMPLE
    This example shows how to configure the authentication of a web application in the local farm using a custom
    claim provider. A SPTrustedIdentityTokenIssuer is created named Contoso, then this SPTrustedIdentityTokenIssuer
    is referenced by the SPWebAppAuthentication as the AuthenticationProvider and the AuthenticationMethod is set
    to "Federated" value.
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

            SPWebAppAuthentication ContosoAuthentication
            {
                WebAppUrl   = "http://sharepoint.contoso.com"
                Default = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                        AuthenticationMethod = "NTLM"
                    } -ClientOnly)
                )
                Extranet = @(
                    (New-CimInstance -ClassName MSFT_SPWebAppAuthenticationMode -Property @{
                        AuthenticationMethod = "FBA"
                        MembershipProvider = "MemberPRovider"
                        RoleProvider = "RoleProvider"
                    } -ClientOnly)
                )
            }
        }
    }
