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

    if ($Settings.TimeZone -ne $null)         { $WebApplication.DefaultTimeZone = $Settings.TimeZone }
    if ($Settings.Alerts -ne $null)           { $WebApplication.AlertsEnabled = $Settings.Alerts }
    if ($Settings.AlertsLimit -ne $null)      { $WebApplication.AlertsMaximum = $Settings.AlertsLimit }
    if ($Settings.RSS -ne $null)              { $WebApplication.SyndicationEnabled = $Settings.RSS }
    if ($Settings.AlertsLimit)                { $WebApplication.MetaWeblogEnabled = $Settings.BlogAPI }
    if ($Settings.BlogAPIAuthenticated)       { $WebApplication.MetaWeblogAuthenticationEnabled = $Settings.BlogAPIAuthenticated }
    if ($Settings.BrowserFileHandling)        { $WebApplication.BrowserFileHandling = $Settings.BrowserFileHandling }
    if ($Settings.SecurityValidation)         { $WebApplication.FormDigestSettings.Enabled = $Settings.SecurityValidation }
    if ($Settings.MaximumUploadSize)          { $WebApplication.MaximumFileSize = $Settings.MaximumUploadSize }
    if ($Settings.RecycleBinEnabled)          { $WebApplication.RecycleBinEnabled = $Settings.RecycleBinEnabled }
    if ($Settings.RecycleBinCleanupEnabled)   { $WebApplication.RecycleBinCleanupEnabled = $Settings.RecycleBinCleanupEnabled }
    if ($Settings.RecycleBinRetentionPeriod)  { $WebApplication.RecycleBinRetentionPeriod = $Settings.RecycleBinRetentionPeriod }
    if ($Settings.SecondStageRecycleBinQuota) { $WebApplication.SecondStageRecycleBinQuota = $Settings.SecondStageRecycleBinQuota }
    if ($Settings.CustomerExperienceProgram)  { $WebApplication.BrowserCEIPEnabled = $Settings.CustomerExperienceProgram }
    if ($Settings.Presence -ne $null)         { $WebApplication.PresenceEnabled = $Settings.Presence }
}

function Test-xSPWebApplicationGeneralSettings {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [parameter(Mandatory = $true)] $CurrentSettings,
        [parameter(Mandatory = $true)] $DesiredSettings
    )

}

