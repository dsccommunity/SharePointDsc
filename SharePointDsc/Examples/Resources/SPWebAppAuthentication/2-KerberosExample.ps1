
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
 This example shows how to configure the authentication of a web application
 in the local farm using Kerberos Windows Authentication.

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
