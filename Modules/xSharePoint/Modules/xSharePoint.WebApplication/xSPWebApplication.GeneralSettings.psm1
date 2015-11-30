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

    if ($Settings.ContainsKey("TimeZone") -eq $true)                   { $WebApplication.DefaultTimeZone = $Settings.TimeZone }
    if ($Settings.ContainsKey("Alerts") -eq $true)                     { $WebApplication.AlertsEnabled = $Settings.Alerts }
    if ($Settings.ContainsKey("AlertsLimit") -eq $true)                { $WebApplication.AlertsMaximum = $Settings.AlertsLimit }
    if ($Settings.ContainsKey("RSS") -eq $true)                        { $WebApplication.SyndicationEnabled = $Settings.RSS }
    if ($Settings.ContainsKey("AlertsLimit") -eq $true)                { $WebApplication.MetaWeblogEnabled = $Settings.BlogAPI }
    if ($Settings.ContainsKey("BlogAPIAuthenticated") -eq $true)       { $WebApplication.MetaWeblogAuthenticationEnabled = $Settings.BlogAPIAuthenticated }
    if ($Settings.ContainsKey("BrowserFileHandling") -eq $true)        { $WebApplication.BrowserFileHandling = $Settings.BrowserFileHandling }
    if ($Settings.ContainsKey("SecurityValidation") -eq $true)         { $WebApplication.FormDigestSettings.Enabled = $Settings.SecurityValidation }
    if ($Settings.ContainsKey("MaximumUploadSize") -eq $true)          { $WebApplication.MaximumFileSize = $Settings.MaximumUploadSize }
    if ($Settings.ContainsKey("RecycleBinEnabled") -eq $true)          { $WebApplication.RecycleBinEnabled = $Settings.RecycleBinEnabled }
    if ($Settings.ContainsKey("RecycleBinCleanupEnabled") -eq $true)   { $WebApplication.RecycleBinCleanupEnabled = $Settings.RecycleBinCleanupEnabled }
    if ($Settings.ContainsKey("RecycleBinRetentionPeriod") -eq $true)  { $WebApplication.RecycleBinRetentionPeriod = $Settings.RecycleBinRetentionPeriod }
    if ($Settings.ContainsKey("SecondStageRecycleBinQuota") -eq $true) { $WebApplication.SecondStageRecycleBinQuota = $Settings.SecondStageRecycleBinQuota }
    if ($Settings.ContainsKey("CustomerExperienceProgram") -eq $true)  { $WebApplication.BrowserCEIPEnabled = $Settings.CustomerExperienceProgram }
    if ($Settings.ContainsKey("Presence") -eq $true)                   { $WebApplication.PresenceEnabled = $Settings.Presence }
}

function Test-xSPWebApplicationGeneralSettings {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [parameter(Mandatory = $true)] $CurrentSettings,
        [parameter(Mandatory = $true)] $DesiredSettings
    )
    $testReturn = Test-xSharePointSpecificParameters -CurrentValues $CurrentSettings `
                                                     -DesiredValues $DesiredSettings
    return $testReturn
}

