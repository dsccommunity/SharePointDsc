
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
 This example shows how to apply some of the available general settings to the
 specified web app

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
        SPWebAppHttpThrottlingMonitor PrimaryWebAppHTTPThrottlingSettings
        {
            WebAppUrl            = 'http://example.contoso.local'
            Category             = 'Memory'
            Counter              = 'Available Mbytes'
            HealthScoreBuckets   = @(1000, 500, 400, 300, 200, 100, 80, 60, 40, 20)
            IsDescending         = $true
            Ensure               = 'Present'
            PsDscRunAsCredential = $SetupAccount
        }
    }
}
