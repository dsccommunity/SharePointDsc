function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $Url,
        [parameter(Mandatory = $false)] [System.UInt32]  $TimeZone,
        [parameter(Mandatory = $false)] [System.Boolean] $Alerts,
        [parameter(Mandatory = $false)] [System.UInt32]  $AlertsLimit,
        [parameter(Mandatory = $false)] [System.Boolean] $RSS,
        [parameter(Mandatory = $false)] [System.Boolean] $BlogAPI,
        [parameter(Mandatory = $false)] [System.Boolean] $BlogAPIAuthenticated,
        [parameter(Mandatory = $false)] [ValidateSet("Strict","Permissive")] [System.String] $BrowserFileHandling,
        [parameter(Mandatory = $false)] [System.Boolean] $SecurityValidation,
        [parameter(Mandatory = $false)] [System.Boolean] $RecycleBinEnabled,
        [parameter(Mandatory = $false)] [System.Boolean] $RecycleBinCleanupEnabled,
        [parameter(Mandatory = $false)] [System.UInt32]  $RecycleBinRetentionPeriod,
        [parameter(Mandatory = $false)] [System.UInt32]  $SecondStageRecycleBinQuota,
        [parameter(Mandatory = $false)] [System.UInt32]  $MaximumUploadSize,
        [parameter(Mandatory = $false)] [System.Boolean] $CustomerExperienceProgram,
        [parameter(Mandatory = $false)] [System.Boolean] $PresenceEnabled,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Getting web application '$url' general settings"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments @($PSBoundParameters,$PSScriptRoot) -ScriptBlock {
        $params = $args[0]
        $ScriptRoot = $args[1]
        
        
        $wa = Get-SPWebApplication -Identity $params.Url -ErrorAction SilentlyContinue
        if ($null -eq $wa) { return $null }

        Import-Module (Join-Path $ScriptRoot "..\..\Modules\xSharePoint.WebApplication\xSPWebApplication.GeneralSettings.psm1" -Resolve)

        $result = Get-xSPWebApplicationGeneralSettings -WebApplication $wa
        $result.Add("Url", $params.Url)
        $result.Add("InstallAccount", $params.InstallAccount)
        return $result
    }
    return $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $Url,
        [parameter(Mandatory = $false)] [System.UInt32]  $TimeZone,
        [parameter(Mandatory = $false)] [System.Boolean] $Alerts,
        [parameter(Mandatory = $false)] [System.UInt32]  $AlertsLimit,
        [parameter(Mandatory = $false)] [System.Boolean] $RSS,
        [parameter(Mandatory = $false)] [System.Boolean] $BlogAPI,
        [parameter(Mandatory = $false)] [System.Boolean] $BlogAPIAuthenticated,
        [parameter(Mandatory = $false)] [ValidateSet("Strict","Permissive")] [System.String] $BrowserFileHandling,
        [parameter(Mandatory = $false)] [System.Boolean] $SecurityValidation,
        [parameter(Mandatory = $false)] [System.Boolean] $RecycleBinEnabled,
        [parameter(Mandatory = $false)] [System.Boolean] $RecycleBinCleanupEnabled,
        [parameter(Mandatory = $false)] [System.UInt32]  $RecycleBinRetentionPeriod,
        [parameter(Mandatory = $false)] [System.UInt32]  $SecondStageRecycleBinQuota,
        [parameter(Mandatory = $false)] [System.UInt32]  $MaximumUploadSize,
        [parameter(Mandatory = $false)] [System.Boolean] $CustomerExperienceProgram,
        [parameter(Mandatory = $false)] [System.Boolean] $PresenceEnabled,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Applying general settings '$Url'"
    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments @($PSBoundParameters,$PSScriptRoot) -ScriptBlock {
        $params = $args[0]
        $ScriptRoot = $args[1]

        $wa = Get-SPWebApplication -Identity $params.Url -ErrorAction SilentlyContinue
        if ($null -eq $wa) {
            throw "Web application $($params.Url) was not found"
            return
        }

        Import-Module (Join-Path $ScriptRoot "..\..\Modules\xSharePoint.WebApplication\xSPWebApplication.GeneralSettings.psm1" -Resolve)
        Set-xSPWebApplicationGeneralSettings -WebApplication $wa -Settings $params
        $wa.Update()
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $Url,
        [parameter(Mandatory = $false)] [System.UInt32]  $TimeZone,
        [parameter(Mandatory = $false)] [System.Boolean] $Alerts,
        [parameter(Mandatory = $false)] [System.UInt32]  $AlertsLimit,
        [parameter(Mandatory = $false)] [System.Boolean] $RSS,
        [parameter(Mandatory = $false)] [System.Boolean] $BlogAPI,
        [parameter(Mandatory = $false)] [System.Boolean] $BlogAPIAuthenticated,
        [parameter(Mandatory = $false)] [ValidateSet("Strict","Permissive")] [System.String] $BrowserFileHandling,
        [parameter(Mandatory = $false)] [System.Boolean] $SecurityValidation,
        [parameter(Mandatory = $false)] [System.Boolean] $RecycleBinEnabled,
        [parameter(Mandatory = $false)] [System.Boolean] $RecycleBinCleanupEnabled,
        [parameter(Mandatory = $false)] [System.UInt32]  $RecycleBinRetentionPeriod,
        [parameter(Mandatory = $false)] [System.UInt32]  $SecondStageRecycleBinQuota,
        [parameter(Mandatory = $false)] [System.UInt32]  $MaximumUploadSize,
        [parameter(Mandatory = $false)] [System.Boolean] $CustomerExperienceProgram,
        [parameter(Mandatory = $false)] [System.Boolean] $PresenceEnabled,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing for web application general settings '$Url'"
    if ($null -eq $CurrentValues) { return $false }

    Import-Module (Join-Path $PSScriptRoot "..\..\Modules\xSharePoint.WebApplication\xSPWebApplication.GeneralSettings.psm1" -Resolve)
    return Test-xSPWebApplicationGeneralSettings -CurrentSettings $CurrentValues -DesiredSettings $PSBoundParameters
}


Export-ModuleMember -Function *-TargetResource

