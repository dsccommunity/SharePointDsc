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
        $ListViewThreshold,

        [Parameter()]
        [System.Boolean]
        $AllowObjectModelOverride,

        [Parameter()]
        [System.UInt32]
        $AdminThreshold,

        [Parameter()]
        [System.UInt32]
        $ListViewLookupThreshold,

        [Parameter()]
        [System.Boolean]
        $HappyHourEnabled,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $HappyHour,

        [Parameter()]
        [System.UInt32]
        $UniquePermissionThreshold,

        [Parameter()]
        [System.Boolean]
        $RequestThrottling,

        [Parameter()]
        [System.Boolean]
        $ChangeLogEnabled,

        [Parameter()]
        [System.UInt32]
        $ChangeLogExpiryDays,

        [Parameter()]
        [System.Boolean]
        $EventHandlersEnabled
    )

    Write-Verbose -Message "Getting web application '$WebAppUrl' throttling settings"

    $paramArgs = @($PSBoundParameters, $PSScriptRoot)
    $result = Invoke-SPDscCommand -Arguments $paramArgs -ScriptBlock {
        $params = $args[0]
        $ScriptRoot = $args[1]

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue
        if ($null -eq $wa)
        {
            return @{
                WebAppUrl                 = $null
                ListViewThreshold         = $null
                AllowObjectModelOverride  = $null
                AdminThreshold            = $null
                ListViewLookupThreshold   = $null
                HappyHourEnabled          = $null
                HappyHour                 = $null
                UniquePermissionThreshold = $null
                RequestThrottling         = $null
                ChangeLogEnabled          = $null
                ChangeLogExpiryDays       = $null
                EventHandlersEnabled      = $null
            }
        }

        $relPath = "..\..\Modules\SharePointDsc.WebApplication\SPWebApplication.Throttling.psm1"
        Import-Module -Name (Join-Path -Path $ScriptRoot -ChildPath $relPath -Resolve)

        $result = Get-SPDscWebApplicationThrottlingConfig -WebApplication $wa
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
        $ListViewThreshold,

        [Parameter()]
        [System.Boolean]
        $AllowObjectModelOverride,

        [Parameter()]
        [System.UInt32]
        $AdminThreshold,

        [Parameter()]
        [System.UInt32]
        $ListViewLookupThreshold,

        [Parameter()]
        [System.Boolean]
        $HappyHourEnabled,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $HappyHour,

        [Parameter()]
        [System.UInt32]
        $UniquePermissionThreshold,

        [Parameter()]
        [System.Boolean]
        $RequestThrottling,

        [Parameter()]
        [System.Boolean]
        $ChangeLogEnabled,

        [Parameter()]
        [System.UInt32]
        $ChangeLogExpiryDays,

        [Parameter()]
        [System.Boolean]
        $EventHandlersEnabled
    )

    Write-Verbose -Message "Setting web application '$WebAppUrl' throttling settings"

    $paramArgs = @($PSBoundParameters, $MyInvocation.MyCommand.Source, $PSScriptRoot)

    $null = Invoke-SPDscCommand -Arguments $paramArgs `
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

        $relPath = "..\..\Modules\SharePointDsc.WebApplication\SPWebApplication.Throttling.psm1"
        Import-Module -Name (Join-Path -Path $ScriptRoot -ChildPath $relPath -Resolve)
        Set-SPDscWebApplicationThrottlingConfig -WebApplication $wa -Settings $params
        $wa.HttpThrottleSettings.Update()
        $wa.Update()

        # Happy hour settings
        if ($params.ContainsKey("HappyHour") -eq $true)
        {
            # Happy hour settins use separate update method so use a fresh web app to update these
            $wa2 = Get-SPWebApplication -Identity $params.WebAppUrl
            Set-SPDscWebApplicationHappyHourConfig -WebApplication $wa2 -Settings $params.HappyHour
            $wa2.Update()
        }
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
        $ListViewThreshold,

        [Parameter()]
        [System.Boolean]
        $AllowObjectModelOverride,

        [Parameter()]
        [System.UInt32]
        $AdminThreshold,

        [Parameter()]
        [System.UInt32]
        $ListViewLookupThreshold,

        [Parameter()]
        [System.Boolean]
        $HappyHourEnabled,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $HappyHour,

        [Parameter()]
        [System.UInt32]
        $UniquePermissionThreshold,

        [Parameter()]
        [System.Boolean]
        $RequestThrottling,

        [Parameter()]
        [System.Boolean]
        $ChangeLogEnabled,

        [Parameter()]
        [System.UInt32]
        $ChangeLogExpiryDays,

        [Parameter()]
        [System.Boolean]
        $EventHandlersEnabled
    )

    Write-Verbose -Message "Testing web application '$WebAppUrl' throttling settings"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $relPath = "..\..\Modules\SharePointDsc.WebApplication\SPWebApplication.Throttling.psm1"
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath $relPath -Resolve)
    $result = Test-SPDscWebApplicationThrottlingConfig -CurrentSettings $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredSettings $PSBoundParameters

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPWebAppThrottlingSettings\MSFT_SPWebAppThrottlingSettings.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module

    $webApps = Get-SPWebApplication
    foreach ($wa in $webApps)
    {
        try
        {
            if ($null -ne $wa)
            {
                $params.WebAppUrl = $wa.Url
                $PartialContent = "        SPWebAppThrottlingSettings " + [System.Guid]::NewGuid().toString() + "`r`n"
                $PartialContent += "        {`r`n"
                $results = Get-TargetResource @params

                $results.HappyHour = Get-SPDscWebAppHappyHour -params $results.HappyHour
                $results = Repair-Credentials -results $results
                $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
                $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "HappyHour"
                $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
                $PartialContent += $currentBlock
                $PartialContent += "        }`r`n"
                $Content += $PartialContent
            }
        }
        catch
        {
            $_
            $Global:ErrorLog += "[Web Application Throttling Settings]" + $wa.Url + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
