function GetAndRemove-Parameter($params, $name){
    $result =$null
    if($params.ContainsKey($name))
    {
        $result = $params.$name 
        $params.Remove( $name)
    }
    return $result;
}
function Sanitize-ComplexTypes{
   param(
        [Parameter(Position = 0)]
        $params
    )
    return @{
        GeneralSettings  = GetAndRemove-Parameter $params "GeneralSettings"
        WorkflowSettings = GetAndRemove-Parameter $params "WorkflowSettings"
        Extensions = GetAndRemove-Parameter $params "Extensions"
        ThrottlingSettings = GetAndRemove-Parameter $params "ThrottlingSettings"
        BlockedFileTypes = GetAndRemove-Parameter $params "BlockedFileTypes"
    }
}

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $Name,
        [parameter(Mandatory = $true)]  [System.String]  $ApplicationPool,
        [parameter(Mandatory = $true)]  [System.String]  $ApplicationPoolAccount,
        [parameter(Mandatory = $true)]  [System.String]  $Url,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowAnonymous,
        [parameter(Mandatory = $false)] [System.String]  $DatabaseName,
        [parameter(Mandatory = $false)] [System.String]  $DatabaseServer,
        [parameter(Mandatory = $false)] [System.String]  $HostHeader,
        [parameter(Mandatory = $false)] [System.String]  $Path,
        [parameter(Mandatory = $false)] [System.String]  $Port,
        [parameter(Mandatory = $false)] [ValidateSet("NTLM","Kerberos")] [System.String] $AuthenticationMethod,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $false)] $GeneralSettings,
        [parameter(Mandatory = $false)] $WorkflowSettings,
        [parameter(Mandatory = $false)] $ThrottlingSettings,
        [parameter(Mandatory = $false)] $BlockedFileTypes
    )

    Write-Verbose -Message "Getting web application '$Name'"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
        
        $wa = Get-SPWebApplication -Identity $params.Name -ErrorAction SilentlyContinue
        if ($null -eq $wa) { return $null }

        $authProvider = Get-SPAuthenticationProvider -WebApplication $wa.Url -Zone "Default" 
        if ($authProvider.DisableKerberos -eq $true) { $localAuthMode = "NTLM" } else { $localAuthMode = "Kerberos" }

        Import-Module (Join-Path $PSScriptRoot "..\..\Modules\xSharePoint.WebApplication\xSPWebApplication.Throttling.psm1" -Resolve)
        Import-Module (Join-Path $PSScriptRoot "..\..\Modules\xSharePoint.WebApplication\xSPWebApplication.Workflow.psm1" -Resolve)
        Import-Module (Join-Path $PSScriptRoot "..\..\Modules\xSharePoint.WebApplication\xSPWebApplication.BlockedFileTypes.psm1" -Resolve)

        return @{
            Name = $wa.DisplayName
            ApplicationPool = $wa.ApplicationPool.Name
            ApplicationPoolAccount = $wa.ApplicationPool.Username
            Url = $wa.Url
            AllowAnonymous = $authProvider.AllowAnonymous
            DatabaseName = $wa.ContentDatabases[0].Name
            DatabaseServer = $wa.ContentDatabases[0].Server
            HostHeader = (New-Object System.Uri $wa.Url).Host
            Path = $wa.IisSettings[0].Path
            Port = (New-Object System.Uri $wa.Url).Port
            AuthenticationMethod = $localAuthMode
            InstallAccount = $params.InstallAccount
            ThrottlingSettings = (Get-xSPWebApplicationThrottlingSettings -WebApplication $wa)
            WorkflowSettings = (Get-xSPWebApplicationWorkflowSettings -WebApplication $wa)
            BlockedFileTypes = (Get-xSPWebApplicationBlockedFileTypes -WebApplication $wa)
        }
    }
    return $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $Name,
        [parameter(Mandatory = $true)]  [System.String]  $ApplicationPool,
        [parameter(Mandatory = $true)]  [System.String]  $ApplicationPoolAccount,
        [parameter(Mandatory = $true)]  [System.String]  $Url,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowAnonymous,
        [parameter(Mandatory = $false)] [System.String]  $DatabaseName,
        [parameter(Mandatory = $false)] [System.String]  $DatabaseServer,
        [parameter(Mandatory = $false)] [System.String]  $HostHeader,
        [parameter(Mandatory = $false)] [System.String]  $Path,
        [parameter(Mandatory = $false)] [System.String]  $Port,
        [parameter(Mandatory = $false)] [ValidateSet("NTLM","Kerberos")] [System.String] $AuthenticationMethod,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $false)] $GeneralSettings,
        [parameter(Mandatory = $false)] $WorkflowSettings,
        [parameter(Mandatory = $false)] $ThrottlingSettings,
        [parameter(Mandatory = $false)] $BlockedFileTypes
    )

    Write-Verbose -Message "Creating web application '$Name'"
    $settings =  Sanitize-ComplexTypes $PSBoundParameters 
    $PSBoundParameters.Add("Settings", $settings)
    Write-Verbose -Message "Creating web application '$Name'"
    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $settings =$params.Settings
        $params.Remove("Settings") | Out-Null
        $wa = Get-SPWebApplication -Identity $params.Name -ErrorAction SilentlyContinue
        if ($null -eq $wa) {
            $newWebAppParams = @{
                Name = $params.Name
                ApplicationPool = $params.ApplicationPool
                ApplicationPoolAccount = $params.ApplicationPoolAccount
                Url = $params.Url
            }
            if ($params.ContainsKey("AuthenticationMethod") -eq $true) {
                if ($params.AuthenticationMethod -eq "NTLM") {
                    $ap = New-SPAuthenticationProvider -UseWindowsIntegratedAuthentication -DisableKerberos 
                } else {
                    $ap = New-SPAuthenticationProvider -UseWindowsIntegratedAuthentication
                }
                $newWebAppParams.Add("AuthenticationProvider", $ap)
            }
            if ($params.ContainsKey("AllowAnonymous")) { 
                $newWebAppParams.Add("AllowAnonymousAccess", $true)
            }
            if ($params.ContainsKey("DatabaseName") -eq $true) { $newWebAppParams.Add("DatabaseName", $params.DatabaseName) }
            if ($params.ContainsKey("DatabaseServer") -eq $true) { $newWebAppParams.Add("DatabaseServer", $params.DatabaseServer) }
            if ($params.ContainsKey("HostHeader") -eq $true) { $newWebAppParams.Add("HostHeader", $params.HostHeader) }
            if ($params.ContainsKey("Path") -eq $true) { $newWebAppParams.Add("Path", $params.Path) }
            if ($params.ContainsKey("Port") -eq $true) { $newWebAppParams.Add("Port", $params.Port) } 
         
            $wa = New-SPWebApplication @newWebAppParams
        }

        # Resource throttling settings
        if ($params.ContainsKey("ThrottlingSettings") -eq $true) {
            Import-Module (Join-Path $PSScriptRoot "..\..\Modules\xSharePoint.WebApplication\xSPWebApplication.Throttling.psm1" -Resolve)
            Set-xSPWebApplicationThrottlingSettings -WebApplication $wa -Settings $params.ThrottlingSettings
        }

        # Workflow settings
        if ($params.ContainsKey("WorkflowSettings") -eq $true) {
            Import-Module (Join-Path $PSScriptRoot "..\..\Modules\xSharePoint.WebApplication\xSPWebApplication.Workflow.psm1" -Resolve)
            Set-xSPWebApplicationWorkflowSettings -WebApplication $wa -Settings $params.ThrottlingSettings
        }

        # Blocked file types
        if ($params.ContainsKey("BlockedFileTypes") -eq $true) {
            Import-Module (Join-Path $PSScriptRoot "..\..\Modules\xSharePoint.WebApplication\xSPWebApplication.BlockedFileTypes.psm1" -Resolve)
            Set-xSPWebApplicationBlockedFileTypes -WebApplication $wa -Settings $params.BlockedFileTypes
        }

#region General settings
            
       $generalSettings = $settings.GeneralSettings   
        if($generalSettings -ne $null){ 
            #TODO: Quota Template
            if($generalSettings.TimeZone -ne $null){
                $wa.DefaultTimeZone =$generalSettings.TimeZone
            }
            if($generalSettings.Alerts -ne $null){
                $wa.AlertsEnabled = $generalSettings.Alerts
            }
            if($generalSettings.AlertsLimit -ne $null){
                $wa.AlertsMaximum = $generalSettings.AlertsLimit
            }
            if($generalSettings.RSS -ne $null){
                $wa.SyndicationEnabled = $generalSettings.RSS
            }
            if($generalSettings.AlertsLimit){
                $wa.MetaWeblogEnabled = $generalSettings.BlogAPI
            }
            if($generalSettings.BlogAPIAuthenticated){
                $wa.MetaWeblogAuthenticationEnabled = $generalSettings.BlogAPIAuthenticated
            }
            if($generalSettings.BrowserFileHandling){
                $wa.BrowserFileHandling = $generalSettings.BrowserFileHandling
            }
            if($generalSettings.SecurityValidation){
                $wa.FormDigestSettings.Enabled = $generalSettings.SecurityValidation
            }
            if($generalSettings.MaximumUploadSize){
                $wa.MaximumFileSize = $generalSettings.MaximumUploadSize
            }
            if($generalSettings.RecycleBinEnabled){
                $wa.RecycleBinEnabled = $generalSettings.RecycleBinEnabled
            }
            if($generalSettings.RecycleBinCleanupEnabled){
                $wa.RecycleBinCleanupEnabled =  $generalSettings.RecycleBinCleanupEnabled
            }
            if($generalSettings.RecycleBinRetentionPeriod){
                $wa.RecycleBinRetentionPeriod = $generalSettings.RecycleBinRetentionPeriod
            }
            if($generalSettings.SecondStageRecycleBinEnabled){
                $wa.SecondStageRecycleBinQuota = $generalSettings.SecondStageRecycleBinEnabled
            }
            if($generalSettings.CustomerExperienceProgram){
                $wa.BrowserCEIPEnabled = $generalSettings.CustomerExperienceProgram
             }
            if($generalSettings.Presence -ne $null){
                $wa.PresenceEnabled =  $generalSettings.Presence
            }
        }
        if( ($settings.WorkflowSettings -ne $null) -or
            ($settings.GeneralSettings -ne $null) -or
            ($settings.ThrottlingSettings -ne $null) -or
            ($settings.BlockedFileTypes -ne $null) 
            ){
                $wa.Update()
            }
#endregion
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $Name,
        [parameter(Mandatory = $true)]  [System.String]  $ApplicationPool,
        [parameter(Mandatory = $true)]  [System.String]  $ApplicationPoolAccount,
        [parameter(Mandatory = $true)]  [System.String]  $Url,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowAnonymous,
        [parameter(Mandatory = $false)] [System.String]  $DatabaseName,
        [parameter(Mandatory = $false)] [System.String]  $DatabaseServer,
        [parameter(Mandatory = $false)] [System.String]  $HostHeader,
        [parameter(Mandatory = $false)] [System.String]  $Path,
        [parameter(Mandatory = $false)] [System.String]  $Port,
        [parameter(Mandatory = $false)] [ValidateSet("NTLM","Kerberos")] [System.String] $AuthenticationMethod,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $false)] $GeneralSettings,
        [parameter(Mandatory = $false)] $WorkflowSettings,
        [parameter(Mandatory = $false)] $ThrottlingSettings,
        [parameter(Mandatory = $false)] $BlockedFileTypes
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing for web application '$Name'"
    if ($null -eq $CurrentValues) { return $false }

    $testReturn = Test-xSharePointSpecificParameters -CurrentValues $CurrentValues `
                                                     -DesiredValues $PSBoundParameters `
                                                     -ValuesToCheck @("ApplicationPool")

    if ($testReturn -eq $false) { return $false }

    # Resource throttling settings
    if ($PSBoundParameters.ContainsKey("ThrottlingSettings") -eq $true) {
        Import-Module (Join-Path $PSScriptRoot "..\..\Modules\xSharePoint.WebApplication\xSPWebApplication.Throttling.psm1" -Resolve)
        $testReturn = Test-xSPWebApplicationThrottlingSettings -CurrentSettings $CurrentValues.ThrottlingSettings -DesiredSettings $ThrottlingSettings
    }
    if ($testReturn -eq $false) { return $false }

    # Workflow settings
    if ($PSBoundParameters.ContainsKey("WorkflowSettings") -eq $true) {
        Import-Module (Join-Path $PSScriptRoot "..\..\Modules\xSharePoint.WebApplication\xSPWebApplication.Workflow.psm1" -Resolve)
        $testReturn = Test-xSPWebApplicationWorkflowSettings -CurrentSettings $CurrentValues.WorkflowSettings -DesiredSettings $WorkflowSettings
    }
    if ($testReturn -eq $false) { return $false }

    # Blocked file types
    if ($PSBoundParameters.ContainsKey("BlockedFileTypes") -eq $true) {
        Import-Module (Join-Path $PSScriptRoot "..\..\Modules\xSharePoint.WebApplication\xSPWebApplication.BlockedFileTypes.psm1" -Resolve)
        $testReturn = Test-xSPWebApplicationWorkflowSettings -CurrentSettings $CurrentValues.BlockedFileTypes -DesiredSettings $BlockedFileTypes
    }
    if ($testReturn -eq $false) { return $false }

    return $testReturn
}


Export-ModuleMember -Function *-TargetResource

