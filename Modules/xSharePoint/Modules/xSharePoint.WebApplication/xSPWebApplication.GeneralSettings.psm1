function Get-xSPWebApplicationGeneralSettings {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [parameter(Mandatory = $true)] $WebApplication
    )
    
    return @{
        TimeZone = $WebApplication.DefaultTimeZone
        Alerts = $WebApplication.AlertsEnabled
        AlertsLimit = $WebApplication.AlertsMaximum
        RSS = $WebApplication.SyndicationEnabled
        BlogAPI = $WebApplication.MetaWeblogEnabled
        BlogAPIAuthenticated = $WebApplication.MetaWeblogAuthenticationEnabled
        BrowserFileHandling = $WebApplication.BrowserFileHandling
        SecurityValidation = $WebApplication.FormDigestSettings.Enabled
        RecycleBinEnabled = $WebApplication.RecycleBinEnabled
        RecycleBinCleanupEnabled = $WebApplication.RecycleBinCleanupEnabled
        RecycleBinRetentionPeriod = $WebApplication.RecycleBinRetentionPeriod
        SecondStageRecycleBinQuota = $WebApplication.SecondStageRecycleBinQuota
        MaximumUploadSize = $WebApplication.MaximumFileSize
        CustomerExperienceProgram = $WebApplication.BrowserCEIPEnabled
        PresenceEnabled = $WebApplication.PresenceEnabled
    }
}

function Set-xSPWebApplicationGeneralSettings {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)] $WebApplication,
        [parameter(Mandatory = $true)] $Settings
    )

    # Format here is SPWebApplication property = Custom settings property
    $mapping = @{
        DefaultTimeZone = "TimeZone"
        AlertsEnabled = "Alerts"
        AlertsMaximum = "AlertsLimit"
        SyndicationEnabled = "RSS"
        MetaWeblogEnabled = "BlogAPI"
        MetaWeblogAuthenticationEnabled = "BlogAPIAuthenticated"
        BrowserFileHandling = "BrowserFileHandling"
        MaximumFileSize = "MaximumUploadSize"
        RecycleBinEnabled = "RecycleBinEnabled"
        RecycleBinCleanupEnabled = "RecycleBinCleanupEnabled"
        RecycleBinRetentionPeriod = "RecycleBinRetentionPeriod"
        SecondStageRecycleBinQuota = "SecondStageRecycleBinQuota"
        BrowserCEIPEnabled = "CustomerExperienceProgram"
        PresenceEnabled = "Presence"
    } 
    $mapping.Keys | ForEach-Object {
        Set-xSharePointObjectPropertyIfValueExists -ObjectToSet $WebApplication `
                                                   -PropertyToSet $_ `
                                                   -ParamsValue $settings `
                                                   -ParamKey $mapping[$_]
    }

    # Set form digest setting child property
    Set-xSharePointObjectPropertyIfValueExists -ObjectToSet $WebApplication.FormDigestSettings `
                                               -PropertyToSet "Enabled" `
                                               -ParamsValue $settings `
                                               -ParamKey "SecurityValidation"
}

function Test-xSPWebApplicationGeneralSettings {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [parameter(Mandatory = $true)] $CurrentSettings,
        [parameter(Mandatory = $true)] $DesiredSettings
    )


    Import-Module (Join-Path $PSScriptRoot "..\..\Modules\xSharePoint.Util\xSharePoint.Util.psm1" -Resolve)
    $testReturn = Test-xSharePointSpecificParameters -CurrentValues $CurrentSettings `
                                                     -DesiredValues $DesiredSettings `
                                                     -ValuesToCheck @("TimeZone", "Alerts", "AlertsLimit", "RSS", "BlogAPI", "BlogAPIAuthenticated", "BrowserFileHandling", "SecurityValidation", "RecycleBinEnabled", "RecycleBinCleanupEnabled", "RecycleBinRetentionPeriod", "SecondStageRecycleBinQuota", "MaximumUploadSize", "CustomerExperienceProgram", "PresenceEnabled")
    return $testReturn
}

