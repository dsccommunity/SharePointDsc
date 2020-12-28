function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Default", "Intranet", "Internet", "Custom", "Extranet")]
        [System.String]
        $Zone,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $EnableCache,

        [Parameter()]
        [System.String]
        $Location,

        [Parameter()]
        [System.UInt16]
        $MaxSizeInGB,

        [Parameter()]
        [System.UInt32]
        $MaxAgeInSeconds,

        [Parameter()]
        [System.String]
        $FileTypes,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting blob cache settings for $WebAppUrl"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]

        $webappsi = Get-SPServiceInstance -Server $env:COMPUTERNAME `
            -ErrorAction SilentlyContinue `
        | Where-Object -FilterScript {
            $_.GetType().Name -eq "SPWebServiceInstance" -and `
                $_.Name -eq ""
        }

        if ($null -eq $webappsi)
        {
            Write-Verbose -Message "Server isn't running the Web Application role"
            return @{
                WebAppUrl       = $null
                Zone            = $null
                EnableCache     = $false
                Location        = $null
                MaxSizeInGB     = $null
                MaxAgeInSeconds = $null
                FileTypes       = $null
            }
        }

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl `
            -ErrorAction SilentlyContinue

        if ($null -eq $wa)
        {
            Write-Verbose -Message "Specified web application was not found."
            return @{
                WebAppUrl       = $null
                Zone            = $null
                EnableCache     = $false
                Location        = $null
                MaxSizeInGB     = $null
                MaxAgeInSeconds = $null
                FileTypes       = $null
            }
        }

        $zone = [Microsoft.SharePoint.Administration.SPUrlZone]::$($params.Zone)

        $sitePath = $wa.IisSettings[$zone].Path
        $webconfiglocation = Join-Path -Path $sitePath -ChildPath "web.config"

        [xml]$webConfig = Get-Content -Path $webConfigLocation

        if ($webconfig.configuration.SharePoint.BlobCache.enabled -eq "true")
        {
            $cacheEnabled = $true
        }
        else
        {
            $cacheEnabled = $false
        }

        try
        {
            $maxsize = [Convert]::ToUInt16($webconfig.configuration.SharePoint.BlobCache.maxSize)
        }
        catch [FormatException]
        {
            $maxsize = 0
        }
        catch
        {
            $message = "Error: $($_.Exception.Message)"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }

        try
        {
            $maxage = [Convert]::ToUInt32($webconfig.configuration.SharePoint.BlobCache."max-age")
        }
        catch [FormatException]
        {
            $maxage = 0
        }
        catch
        {
            $message = "Error: $($_.Exception.Message)"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }

        $returnval = @{
            WebAppUrl       = $params.WebAppUrl
            Zone            = $params.Zone
            EnableCache     = $cacheEnabled
            Location        = $webconfig.configuration.SharePoint.BlobCache.location
            MaxSizeInGB     = $maxsize
            MaxAgeInSeconds = $maxage
            FileTypes       = $webconfig.configuration.SharePoint.BlobCache.path
        }

        return $returnval
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

        [Parameter(Mandatory = $true)]
        [ValidateSet("Default", "Intranet", "Internet", "Custom", "Extranet")]
        [System.String]
        $Zone,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $EnableCache,

        [Parameter()]
        [System.String]
        $Location,

        [Parameter()]
        [System.UInt16]
        $MaxSizeInGB,

        [Parameter()]
        [System.UInt32]
        $MaxAgeInSeconds,

        [Parameter()]
        [System.String]
        $FileTypes,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting blob cache settings for $WebAppUrl"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    $changes = @{ }

    if ($PSBoundParameters.ContainsKey("EnableCache"))
    {
        if ($CurrentValues.EnableCache -ne $EnableCache)
        {
            $changes.EnableCache = $EnableCache
        }
    }

    if ($PSBoundParameters.ContainsKey("Location"))
    {
        if ($CurrentValues.Location -ne $Location)
        {
            $changes.Location = $Location
        }
    }

    if ($PSBoundParameters.ContainsKey("MaxSizeInGB"))
    {
        if ($CurrentValues.MaxSizeInGB -ne $MaxSizeInGB)
        {
            $changes.MaxSizeInGB = $MaxSizeInGB
        }
    }

    if ($PSBoundParameters.ContainsKey("MaxAgeInSeconds"))
    {
        if ($CurrentValues.MaxAgeInSeconds -ne $MaxAgeInSeconds)
        {
            $changes.MaxAgeInSeconds = $MaxAgeInSeconds
        }
    }

    if ($PSBoundParameters.ContainsKey("FileTypes"))
    {
        if ($CurrentValues.FileTypes -ne $FileTypes)
        {
            $changes.FileTypes = $FileTypes
        }
    }

    if ($changes.Count -ne 0)
    {
        ## Perform changes
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source, $changes) `
            -ScriptBlock {
            $params = $args[0]
            $eventSource = $args[1]
            $changes = $args[2]

            $webappsi = Get-SPServiceInstance -Server $env:COMPUTERNAME `
                -ErrorAction SilentlyContinue `
            | Where-Object -FilterScript {
                $_.GetType().Name -eq "SPWebServiceInstance" -and `
                    $_.Name -eq ""
            }

            if ($null -eq $webappsi)
            {
                $message = "Server isn't running the Web Application role"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
                throw $message
            }

            $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue

            if ($null -eq $wa)
            {
                $message = "Specified web application could not be found."
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
                throw $message
            }

            Write-Verbose -Message "Processing changes"

            $zone = [Microsoft.SharePoint.Administration.SPUrlZone]::$($params.Zone)

            $sitePath = $wa.IisSettings[$zone].Path
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $webconfiglocation = Join-Path -Path $sitePath -ChildPath "web.config"
            $webconfigbackuplocation = Join-Path -Path $sitePath -ChildPath "web_config-$timestamp.backup"
            Copy-Item -Path $webconfiglocation -Destination $webconfigbackuplocation

            [xml]$webConfig = Get-Content -Path $webConfigLocation

            if ($changes.ContainsKey("EnableCache"))
            {
                $webconfig.configuration.SharePoint.BlobCache.SetAttribute("enabled", $changes.EnableCache.ToString())
            }

            if ($changes.ContainsKey("Location"))
            {
                $webconfig.configuration.SharePoint.BlobCache.SetAttribute("location", $changes.Location)
            }

            if ($changes.ContainsKey("MaxSizeInGB"))
            {
                $webconfig.configuration.SharePoint.BlobCache.SetAttribute("maxSize", $changes.MaxSizeInGB.ToString())
            }

            if ($changes.ContainsKey("MaxAgeInSeconds"))
            {
                $webconfig.configuration.SharePoint.BlobCache.SetAttribute("max-age", $($changes.MaxAgeInSeconds.ToString()))
            }

            if ($changes.ContainsKey("FileTypes"))
            {
                $webconfig.configuration.SharePoint.BlobCache.SetAttribute("path", $changes.FileTypes)
            }
            $webconfig.Save($webconfiglocation)
        }
    }

    ## Check Blob Cache folder
    if ($Location)
    {
        if (-not (Test-Path -Path $Location))
        {
            Write-Verbose "Create Blob Cache Folder $Location"
            try
            {
                New-Item -Path $Location -ItemType Directory | Out-Null
            }
            catch [DriveNotFoundException]
            {
                $message = "Specified drive does not exist"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
            catch
            {
                $message = "Error creating Blob Cache folder: $($_.Exception.Message)"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
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

        [Parameter(Mandatory = $true)]
        [ValidateSet("Default", "Intranet", "Internet", "Custom", "Extranet")]
        [System.String]
        $Zone,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $EnableCache,

        [Parameter()]
        [System.String]
        $Location,

        [Parameter()]
        [System.UInt16]
        $MaxSizeInGB,

        [Parameter()]
        [System.UInt32]
        $MaxAgeInSeconds,

        [Parameter()]
        [System.String]
        $FileTypes,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing blob cache settings for $WebAppUrl"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($Location)
    {
        if (-not (Test-Path -Path $Location))
        {
            $message = "Blob Cache Folder $Location does not exist"
            Write-Verbose -Message $message
            Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

            Write-Verbose -Message "Test-TargetResource returned false"
            return $false
        }
    }

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("EnableCache",
        "Location",
        "MaxSizeInGB",
        "FileType",
        "MaxAgeInSeconds")

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
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPBlobCacheSettings\MSFT_SPBlobCacheSettings.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module

    $webApps = Get-SPWebApplication
    foreach ($webApp in $webApps)
    {
        try
        {
            $alternateUrls = $webApp.AlternateUrl

            $zones = @("Default")
            if ($alternateUrls.Length -ge 1)
            {
                $zones = $alternateUrls | Select-Object Zone
            }
            foreach ($zone in $zones)
            {
                $PartialContent = "        SPBlobCacheSettings " + [System.Guid]::NewGuid().ToString() + "`r`n"
                $PartialContent += "        {`r`n"
                $params.WebAppUrl = $webApp.Url
                $params.Zone = $zone
                $results = Get-TargetResource @params
                $results = Repair-Credentials -results $results

                Add-ConfigurationDataEntry -Node "NonNodeData" -Key "BlobCacheLocation" -Value $results.Location -Description "Path where the Blob Cache objects will be stored on the servers;"
                $results.Location = "`$ConfigurationData.NonNodeData.BlobCacheLocation"

                $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
                $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
                $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "Location"
                $PartialContent += $currentBlock
                $PartialContent += "        }`r`n"
                $Content += $PartialContent
            }
        }
        catch
        {
            $Global:ErrorLog += "[Blob Cache Settings]" + $webApp.Url + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
