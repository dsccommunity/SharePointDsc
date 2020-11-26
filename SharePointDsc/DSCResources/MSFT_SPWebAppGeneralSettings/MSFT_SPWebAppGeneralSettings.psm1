$script:resourceModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:resourceModulePath -ChildPath 'Modules'
$script:resourceHelperModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'SharePointDsc.Util'
Import-Module -Name (Join-Path -Path $script:resourceHelperModulePath -ChildPath 'SharePointDsc.Util.psm1')

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter()]
        [System.UInt32]
        $TimeZone,

        [Parameter()]
        [System.Boolean]
        $Alerts,

        [Parameter()]
        [System.UInt32]
        $AlertsLimit,

        [Parameter()]
        [System.Boolean]
        $RSS,

        [Parameter()]
        [System.Boolean]
        $BlogAPI,

        [Parameter()]
        [System.Boolean]
        $BlogAPIAuthenticated,

        [Parameter()]
        [ValidateSet("Strict", "Permissive")]
        [System.String]
        $BrowserFileHandling,

        [Parameter()]
        [System.Boolean]
        $SecurityValidation,

        [Parameter()]
        [System.Boolean]
        $SecurityValidationExpires,

        [Parameter()]
        [System.Uint32]
        $SecurityValidationTimeoutMinutes,

        [Parameter()]
        [System.Boolean]
        $RecycleBinEnabled,

        [Parameter()]
        [System.Boolean]
        $RecycleBinCleanupEnabled,

        [Parameter()]
        [System.UInt32]
        $RecycleBinRetentionPeriod,

        [Parameter()]
        [System.UInt32]
        $SecondStageRecycleBinQuota,

        [Parameter()]
        [System.UInt32]
        $MaximumUploadSize,

        [Parameter()]
        [System.Boolean]
        $CustomerExperienceProgram,

        [Parameter()]
        [System.Boolean]
        $PresenceEnabled,

        [Parameter()]
        [System.Boolean]
        $AllowOnlineWebPartCatalog,

        [Parameter()]
        [System.Boolean]
        $SelfServiceSiteCreationEnabled,

        [Parameter()]
        [System.String]
        $DefaultQuotaTemplate,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting web application '$WebAppUrl' general settings"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters, $PSScriptRoot) `
        -ScriptBlock {
        $params = $args[0]
        $ScriptRoot = $args[1]

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue
        if ($null -eq $wa)
        {
            return @{
                WebAppUrl                        = $params.WebAppUrl
                TimeZone                         = $null
                Alerts                           = $null
                AlertsLimit                      = $null
                RSS                              = $null
                BlogAPI                          = $null
                BlogAPIAuthenticated             = $null
                BrowserFileHandling              = $null
                SecurityValidation               = $null
                SecurityValidationExpires        = $null
                SecurityValidationTimeoutMinutes = $null
                RecycleBinEnabled                = $null
                RecycleBinCleanupEnabled         = $null
                RecycleBinRetentionPeriod        = $null
                SecondStageRecycleBinQuota       = $null
                MaximumUploadSize                = $null
                CustomerExperienceProgram        = $null
                PresenceEnabled                  = $null
                AllowOnlineWebPartCatalog        = $null
                SelfServiceSiteCreationEnabled   = $null
                DefaultQuotaTemplate             = $null
            }
        }

        $modulePath = "..\..\Modules\SharePointDsc.WebApplication\SPWebApplication.GeneralSettings.psm1"
        Import-Module -Name (Join-Path -Path $ScriptRoot -ChildPath $modulePath -Resolve)

        $result = Get-SPDscWebApplicationGeneralConfig -WebApplication $wa
        $result.Add("WebAppUrl", $params.WebAppUrl)
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
        $WebAppUrl,

        [Parameter()]
        [System.UInt32]
        $TimeZone,

        [Parameter()]
        [System.Boolean]
        $Alerts,

        [Parameter()]
        [System.UInt32]
        $AlertsLimit,

        [Parameter()]
        [System.Boolean]
        $RSS,

        [Parameter()]
        [System.Boolean]
        $BlogAPI,

        [Parameter()]
        [System.Boolean]
        $BlogAPIAuthenticated,

        [Parameter()]
        [ValidateSet("Strict", "Permissive")]
        [System.String]
        $BrowserFileHandling,

        [Parameter()]
        [System.Boolean]
        $SecurityValidation,

        [Parameter()]
        [System.Boolean]
        $SecurityValidationExpires,

        [Parameter()]
        [System.Uint32]
        $SecurityValidationTimeoutMinutes,

        [Parameter()]
        [System.Boolean]
        $RecycleBinEnabled,

        [Parameter()]
        [System.Boolean]
        $RecycleBinCleanupEnabled,

        [Parameter()]
        [System.UInt32]
        $RecycleBinRetentionPeriod,

        [Parameter()]
        [System.UInt32]
        $SecondStageRecycleBinQuota,

        [Parameter()]
        [System.UInt32]
        $MaximumUploadSize,

        [Parameter()]
        [System.Boolean]
        $CustomerExperienceProgram,

        [Parameter()]
        [System.Boolean]
        $PresenceEnabled,

        [Parameter()]
        [System.Boolean]
        $AllowOnlineWebPartCatalog,

        [Parameter()]
        [System.Boolean]
        $SelfServiceSiteCreationEnabled,

        [Parameter()]
        [System.String]
        $DefaultQuotaTemplate,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting web application '$WebAppUrl' general settings"

    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source, $PSScriptRoot) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]
        $ScriptRoot = $args[2]

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue
        if ($null -eq $wa)
        {
            $message = "Web application $($params.WebAppUrl) was not found"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }

        if ($params.ContainsKey("DefaultQuotaTemplate"))
        {
            $admService = Get-SPDscContentService

            $quotaTemplate = $admService.QuotaTemplates[$params.DefaultQuotaTemplate]
            if ($null -eq $quotaTemplate)
            {
                $message = "Quota template $($params.DefaultQuotaTemplate) was not found"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
                throw $message
            }
        }

        $modulePath = "..\..\Modules\SharePointDsc.WebApplication\SPWebApplication.GeneralSettings.psm1"
        Import-Module -Name (Join-Path -Path $ScriptRoot -ChildPath $modulePath -Resolve)

        Set-SPDscWebApplicationGeneralConfig -WebApplication $wa -Settings $params
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
        $WebAppUrl,

        [Parameter()]
        [System.UInt32]
        $TimeZone,

        [Parameter()]
        [System.Boolean]
        $Alerts,

        [Parameter()]
        [System.UInt32]
        $AlertsLimit,

        [Parameter()]
        [System.Boolean]
        $RSS,

        [Parameter()]
        [System.Boolean]
        $BlogAPI,

        [Parameter()]
        [System.Boolean]
        $BlogAPIAuthenticated,

        [Parameter()]
        [ValidateSet("Strict", "Permissive")]
        [System.String]
        $BrowserFileHandling,

        [Parameter()]
        [System.Boolean]
        $SecurityValidation,

        [Parameter()]
        [System.Boolean]
        $SecurityValidationExpires,

        [Parameter()]
        [System.Uint32]
        $SecurityValidationTimeoutMinutes,

        [Parameter()]
        [System.Boolean]
        $RecycleBinEnabled,

        [Parameter()]
        [System.Boolean]
        $RecycleBinCleanupEnabled,

        [Parameter()]
        [System.UInt32]
        $RecycleBinRetentionPeriod,

        [Parameter()]
        [System.UInt32]
        $SecondStageRecycleBinQuota,

        [Parameter()]
        [System.UInt32]
        $MaximumUploadSize,

        [Parameter()]
        [System.Boolean]
        $CustomerExperienceProgram,

        [Parameter()]
        [System.Boolean]
        $PresenceEnabled,

        [Parameter()]
        [System.Boolean]
        $AllowOnlineWebPartCatalog,

        [Parameter()]
        [System.Boolean]
        $SelfServiceSiteCreationEnabled,

        [Parameter()]
        [System.String]
        $DefaultQuotaTemplate,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing web application '$WebAppUrl' general settings"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $modulePath = "..\..\Modules\SharePointDsc.WebApplication\SPWebApplication.GeneralSettings.psm1"
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath $modulePath -Resolve)

    $result = Test-SPDscWebApplicationGeneralConfig -CurrentSettings $CurrentValues `
        -DesiredSettings $PSBoundParameters

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}


function Export-TargetResource
{
    if (!(Get-PSSnapin Microsoft.SharePoint.Powershell -ErrorAction SilentlyContinue))
    {
        Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction 0
    }
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDSC" | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPWebAppGeneralSettings\MSFT_SPWebAppGeneralSettings.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module
    $webApps = Get-SPWebApplication
    $i = 1
    $total = $webApps.Length
    foreach ($webApp in $webApps)
    {
        try
        {
            Write-Host "Scanning Web App General Settings [$i/$total] {$($webApp.Url)}"
            $params.WebAppUrl = $webApp.Url
            $PartialContent = "        SPWebAppGeneralSettings " + [System.Guid]::NewGuid().ToString() + "`r`n"
            $PartialContent += "        {`r`n"

            $results = Get-TargetResource @params

            if ($results.DefaultQuotaTemplate -eq "No Quota" -or $results.DefaultQuotaTemplate -eq "")
            {
                $results.Remove("DefaultQuotaTemplate")
            }

            $results = Repair-Credentials -results $results
            if ($results.TimeZone -eq -1 -or $null -eq $results.TimeZone)
            {
                $results.Remove("TimeZone")
            }
            $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
            $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
            $PartialContent += $currentBlock
            $PartialContent += "        }`r`n"
            $Content += $PartialContent
        }
        catch
        {
            $Global:ErrorLog += "[SPWebApplicationGeneralSettings] Couldn't properly retrieve all General Settings from Web Application {$($webApp.Url)}`r`n"
        }
        $i++
    }
    return $Content
}


Export-ModuleMember -Function *-TargetResource

