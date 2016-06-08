function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $WebAppUrl,
        [parameter(Mandatory = $true)]  [ValidateSet("Default", "Intranet", "Internet", "Custom", "Extranet")] [System.String] $Zone,
        [parameter(Mandatory = $true)]  [System.Boolean] $EnableCache,
        [parameter(Mandatory = $false)] [System.String] $Location,
        [parameter(Mandatory = $false)] [System.UInt16] $MaxSizeInGB,
        [parameter(Mandatory = $false)] [System.UInt32] $MaxAgeInSeconds,
        [parameter(Mandatory = $false)] [System.String] $FileTypes,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )
        
    Write-Verbose -Message "Getting blob cache settings for $WebAppUrl"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue

        if ($null -eq $wa) {
            throw "Specified web application was not found."
        }

        switch ($params.Zone) {
            "Default"  {
                $zone = [Microsoft.SharePoint.Administration.SPUrlZone]::Default
            }
            "Intranet" {
                $zone = [Microsoft.SharePoint.Administration.SPUrlZone]::Intranet
            }
            "Internet" {
                $zone = [Microsoft.SharePoint.Administration.SPUrlZone]::Internet
            }
            "Custom"   {
                $zone = [Microsoft.SharePoint.Administration.SPUrlZone]::Custom
            }
            "Extranet" {
                $zone = [Microsoft.SharePoint.Administration.SPUrlZone]::Extranet
            }
        }

        $sitePath = $wa.IisSettings[$zone].Path
        $webconfiglocation = Join-Path $sitePath "web.config"

        [xml]$webConfig = Get-Content -Path $webConfigLocation

        if ($webconfig.configuration.SharePoint.BlobCache.enabled -eq "true") {
            $cacheEnabled = $true
        } else {
            $cacheEnabled = $false
        }

        try {
            $maxsize = [Convert]::ToUInt16($webconfig.configuration.SharePoint.BlobCache.maxSize)
        }
        catch [FormatException] {
            $maxsize = 0
        }
        catch {
            throw "Error: $($_.Exception.Message)"
        }

        try {
            $maxage = [Convert]::ToUInt32($webconfig.configuration.SharePoint.BlobCache."max-age")
        }
        catch [FormatException] {
            $maxage = 0
        }
        catch {
            throw "Error: $($_.Exception.Message)"
        }


        $returnval = @{
                WebAppUrl = $params.WebAppUrl
                Zone = $params.Zone
                EnableCache = $cacheEnabled
                Location = $webconfig.configuration.SharePoint.BlobCache.location
                MaxSizeInGB = $maxsize
                MaxAgeInSeconds = $maxage
                FileTypes = $webconfig.configuration.SharePoint.BlobCache.path
                InstallAccount = $params.InstallAccount
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
        [parameter(Mandatory = $true)]  [System.String] $WebAppUrl,
        [parameter(Mandatory = $true)]  [ValidateSet("Default", "Intranet", "Internet", "Custom", "Extranet")] [System.String] $Zone,
        [parameter(Mandatory = $true)]  [System.Boolean] $EnableCache,
        [parameter(Mandatory = $false)] [System.String] $Location,
        [parameter(Mandatory = $false)] [System.UInt16] $MaxSizeInGB,
        [parameter(Mandatory = $false)] [System.UInt32] $MaxAgeInSeconds,
        [parameter(Mandatory = $false)] [System.String] $FileTypes,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Setting blob cache settings for $WebAppUrl"

    $CurrentValues = Get-TargetResource @PSBoundParameters
    
    $changes = @{}
    
    if ($PSBoundParameters.ContainsKey("EnableCache")) {
        if ($CurrentValues.EnableCache -ne $EnableCache) { $changes.EnableCache = $EnableCache }
    }
    
    if ($PSBoundParameters.ContainsKey("Location")) {
        if ($CurrentValues.Location -ne $Location) { $changes.Location = $Location }
    }
    
    if ($PSBoundParameters.ContainsKey("MaxSizeInGB")) {
        if ($CurrentValues.MaxSizeInGB -ne $MaxSizeInGB) { $changes.MaxSizeInGB = $MaxSizeInGB }
    }

    if ($PSBoundParameters.ContainsKey("MaxAgeInSeconds")) {
        if ($CurrentValues.MaxAgeInSeconds -ne $MaxAgeInSeconds) { $changes.MaxAgeInSeconds = $MaxAgeInSeconds }
    }
    
    if ($PSBoundParameters.ContainsKey("FileTypes")) {
        if ($CurrentValues.FileTypes -ne $FileTypes) { $changes.FileTypes = $FileTypes }
    }

    if ($changes.Count -ne 0) {
        ## Perform changes
        Invoke-SPDSCCommand -Credential $InstallAccount -Arguments @($PSBoundParameters, $changes) -ScriptBlock {
            $params  = $args[0]
            $changes = $args[1]

            $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue

            if ($null -eq $wa) {
                throw "Specified web application could not be found."
            }

            Write-Verbose -Verbose "Processing changes"

            switch ($params.Zone) {
                "Default"  {
                    $zone = [Microsoft.SharePoint.Administration.SPUrlZone]::Default
                }
                "Intranet" {
                    $zone = [Microsoft.SharePoint.Administration.SPUrlZone]::Intranet
                }
                "Internet" {
                    $zone = [Microsoft.SharePoint.Administration.SPUrlZone]::Internet
                }
                "Custom"   {
                    $zone = [Microsoft.SharePoint.Administration.SPUrlZone]::Custom
                }
                "Extranet" {
                    $zone = [Microsoft.SharePoint.Administration.SPUrlZone]::Extranet
                }
            }
            $sitePath = $wa.IisSettings[$zone].Path
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $webconfiglocation = Join-Path $sitePath "web.config"
            $webconfigbackuplocation = Join-Path $sitePath "web_config-$timestamp.backup"
            Copy-Item $webconfiglocation $webconfigbackuplocation

            [xml]$webConfig = Get-Content -Path $webConfigLocation

            if ($changes.ContainsKey("EnableCache")) {
                $webconfig.configuration.SharePoint.BlobCache.enabled = $changes.EnableCache.ToString()
            }

            if ($changes.ContainsKey("Location")) {
                $webconfig.configuration.SharePoint.BlobCache.location = $changes.Location
            }

            if ($changes.ContainsKey("MaxSizeInGB")) {
                $webconfig.configuration.SharePoint.BlobCache.maxSize = $changes.MaxSizeInGB.ToString()
            }

            if ($changes.ContainsKey("MaxAgeInSeconds")) {
                $webconfig.configuration.SharePoint.BlobCache."max-age" = $changes.MaxAgeInSeconds.ToString()
            }
            
            if ($changes.ContainsKey("FileTypes")) {
                $webconfig.configuration.SharePoint.BlobCache.path = $changes.FileTypes
            }

            $webconfig.Save($webconfiglocation)
        }
    }    
    
    ## Check Blob Cache folder
    if ($Location) {
        if (-not(Test-Path $Location)) {
            Write-Verbose "Create Blob Cache Folder $Location"
            try {
                New-Item $Location -ItemType Directory | Out-Null
            }
            catch [DriveNotFoundException] {
                throw "Specified drive does not exist"
            }
            catch {
                throw "Error creating Blob Cache folder: $($_.Exception.Message)"
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
        [parameter(Mandatory = $true)]  [System.String] $WebAppUrl,
        [parameter(Mandatory = $true)]  [ValidateSet("Default", "Intranet", "Internet", "Custom", "Extranet")] [System.String] $Zone,
        [parameter(Mandatory = $true)]  [System.Boolean] $EnableCache,
        [parameter(Mandatory = $false)] [System.String] $Location,
        [parameter(Mandatory = $false)] [System.UInt16] $MaxSizeInGB,
        [parameter(Mandatory = $false)] [System.UInt32] $MaxAgeInSeconds,
        [parameter(Mandatory = $false)] [System.String] $FileTypes,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    
    Write-Verbose -Message "Testing blob cache settings for $WebAppUrl"
    
    if ($null -eq $CurrentValues) { return $false }
    
    if ($Location) {
        if (-not(Test-Path $Location)) {
            Write-Verbose "Blob Cache Folder $Location does not exist"
            return $false
        }
    }
    
    return Test-SPDSCSpecificParameters -CurrentValues $CurrentValues `
                                              -DesiredValues $PSBoundParameters `
                                              -ValuesToCheck @("EnableCache", "Location", "MaxSizeInGB", "FileType", "MaxAgeInSeconds")
}

Export-ModuleMember -Function *-TargetResource
