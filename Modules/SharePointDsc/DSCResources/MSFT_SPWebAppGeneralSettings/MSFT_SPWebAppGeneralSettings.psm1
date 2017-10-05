function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]  
        [System.String]  
        $Url,

        [Parameter(Mandatory = $false)] 
        [System.UInt32]  
        $TimeZone,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $Alerts,

        [Parameter(Mandatory = $false)] 
        [System.UInt32] 
        $AlertsLimit,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $RSS,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $BlogAPI,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $BlogAPIAuthenticated,

        [Parameter(Mandatory = $false)] 
        [ValidateSet("Strict","Permissive")] 
        [System.String] 
        $BrowserFileHandling,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $SecurityValidation,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $SecurityValidationExpires,

        [Parameter(Mandatory = $false)] 
        [System.Uint32]  
        $SecurityValidationTimeoutMinutes,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $RecycleBinEnabled,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $RecycleBinCleanupEnabled,

        [Parameter(Mandatory = $false)] 
        [System.UInt32]  
        $RecycleBinRetentionPeriod,

        [Parameter(Mandatory = $false)] 
        [System.UInt32]  
        $SecondStageRecycleBinQuota,

        [Parameter(Mandatory = $false)] 
        [System.UInt32]  
        $MaximumUploadSize,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $CustomerExperienceProgram,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $PresenceEnabled,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $AllowOnlineWebPartCatalog,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $SelfServiceSiteCreationEnabled,

        [Parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Getting web application '$url' general settings"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments @($PSBoundParameters,$PSScriptRoot) `
                                  -ScriptBlock {
        $params = $args[0]
        $ScriptRoot = $args[1]
                
        $wa = Get-SPWebApplication -Identity $params.Url -ErrorAction SilentlyContinue
        if ($null -eq $wa)
        {
            return $null 
        }

        $modulePath = "..\..\Modules\SharePointDsc.WebApplication\SPWebApplication.GeneralSettings.psm1"
        Import-Module -Name (Join-Path -Path $ScriptRoot -ChildPath $modulePath -Resolve)

        $result = Get-SPDSCWebApplicationGeneralConfig -WebApplication $wa
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
        [Parameter(Mandatory = $true)]  
        [System.String]  
        $Url,

        [Parameter(Mandatory = $false)] 
        [System.UInt32]  
        $TimeZone,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $Alerts,

        [Parameter(Mandatory = $false)] 
        [System.UInt32] 
        $AlertsLimit,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $RSS,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $BlogAPI,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $BlogAPIAuthenticated,

        [Parameter(Mandatory = $false)] 
        [ValidateSet("Strict","Permissive")] 
        [System.String] 
        $BrowserFileHandling,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $SecurityValidation,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $SecurityValidationExpires,

        [Parameter(Mandatory = $false)] 
        [System.Uint32]  
        $SecurityValidationTimeoutMinutes,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $RecycleBinEnabled,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $RecycleBinCleanupEnabled,

        [Parameter(Mandatory = $false)] 
        [System.UInt32]  
        $RecycleBinRetentionPeriod,

        [Parameter(Mandatory = $false)] 
        [System.UInt32]  
        $SecondStageRecycleBinQuota,

        [Parameter(Mandatory = $false)] 
        [System.UInt32]  
        $MaximumUploadSize,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $CustomerExperienceProgram,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $PresenceEnabled,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $AllowOnlineWebPartCatalog,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $SelfServiceSiteCreationEnabled,

        [Parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Setting web application '$url' general settings"
    
    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments @($PSBoundParameters,$PSScriptRoot) `
                                  -ScriptBlock {
        $params = $args[0]
        $ScriptRoot = $args[1]

        $wa = Get-SPWebApplication -Identity $params.Url -ErrorAction SilentlyContinue
        if ($null -eq $wa)
        {
            throw "Web application $($params.Url) was not found"
            return
        }

        $modulePath = "..\..\Modules\SharePointDsc.WebApplication\SPWebApplication.GeneralSettings.psm1"
        Import-Module -Name (Join-Path -Path $ScriptRoot -ChildPath $modulePath -Resolve)

        Set-SPDSCWebApplicationGeneralConfig -WebApplication $wa -Settings $params
        $wa.Update()
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
     (
        [Parameter(Mandatory = $true)]  
        [System.String]  
        $Url,

        [Parameter(Mandatory = $false)] 
        [System.UInt32]  
        $TimeZone,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $Alerts,

        [Parameter(Mandatory = $false)] 
        [System.UInt32] 
        $AlertsLimit,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $RSS,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $BlogAPI,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $BlogAPIAuthenticated,

        [Parameter(Mandatory = $false)] 
        [ValidateSet("Strict","Permissive")] 
        [System.String] 
        $BrowserFileHandling,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $SecurityValidation,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $SecurityValidationExpires,

        [Parameter(Mandatory = $false)] 
        [System.Uint32]  
        $SecurityValidationTimeoutMinutes,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $RecycleBinEnabled,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $RecycleBinCleanupEnabled,

        [Parameter(Mandatory = $false)] 
        [System.UInt32]  
        $RecycleBinRetentionPeriod,

        [Parameter(Mandatory = $false)] 
        [System.UInt32]  
        $SecondStageRecycleBinQuota,

        [Parameter(Mandatory = $false)] 
        [System.UInt32]  
        $MaximumUploadSize,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $CustomerExperienceProgram,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $PresenceEnabled,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $AllowOnlineWebPartCatalog,

        [Parameter(Mandatory = $false)] 
        [System.Boolean] 
        $SelfServiceSiteCreationEnabled,

        [Parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Testing web application '$url' general settings"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($null -eq $CurrentValues)
    {
        return $false 
    }

    $modulePath = "..\..\Modules\SharePointDsc.WebApplication\SPWebApplication.GeneralSettings.psm1"
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath $modulePath -Resolve)

    return Test-SPDSCWebApplicationGeneralConfig -CurrentSettings $CurrentValues -DesiredSettings $PSBoundParameters
}

Export-ModuleMember -Function *-TargetResource
