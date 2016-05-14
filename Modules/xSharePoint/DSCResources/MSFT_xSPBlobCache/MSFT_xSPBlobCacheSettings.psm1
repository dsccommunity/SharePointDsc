function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $WebAppUrl,
        [parameter(Mandatory = $true)]  [ValidateSet("Default", "Intranet", "Internet", "Custom", "Extranet")] [System.String] $Zone,
        [parameter(Mandatory = $false)] [System.Boolean] $EnableCache,
        [parameter(Mandatory = $false)] [System.String] $Location,
        [parameter(Mandatory = $false)] [System.UInt16] $MaxSize,
        [parameter(Mandatory = $false)] [System.String] $FileTypes,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )
        
    Write-Verbose -Message "Getting blob cache settings for $WebAppUrl"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
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

        $webconfig = New-Object XML
        $webconfig.Load($webconfiglocation)

        if ($webconfig.configuration.SharePoint.BlobCache.enabled -eq "true") {
            $cacheEnabled = $true
        } else {
            $cacheEnabled = $false
        }

        try {
            $maxsize = [Convert]::ToUInt16($webconfig.configuration.SharePoint.BlobCache.maxSize)
        }
        catch [FormatException] {
            Write-Verbose "Conversion failed"
            return $null
        }
        catch {
            Write-Verbose $_.Exception.Message
            return $null
        }

        $returnval = @{
                WebAppUrl = $params.WebAppUrl
                Zone = $params.Zone
                EnableCache = $cacheEnabled
                Location = $webconfig.configuration.SharePoint.BlobCache.location
                MaxSize = $maxsize
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
        [parameter(Mandatory = $false)] [System.Boolean] $EnableCache,
        [parameter(Mandatory = $false)] [System.String] $Location,
        [parameter(Mandatory = $false)] [System.UInt16] $MaxSize,
        [parameter(Mandatory = $false)] [System.String] $FileTypes,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Setting blob cache settings for $WebAppUrl"

    $CurrentValues = Get-TargetResource @PSBoundParameters
    
    $changes = @{}
    
    if ($CurrentValues.EnabledCache -ne $EnableCache) { $changes.EnabledCache = $EnableCache }
    if ($CurrentValues.Location -ne $Location) { $changes.Location = $Location }
    if ($CurrentValues.MaxSize -ne $MaxSize) { $changes.MaxSize = $MaxSize }
    if ($CurrentValues.FileTypes -ne $FileTypes) { $changes.FileTypes = $FileTypes }
    
    ## Perform changes
    Invoke-xSharePointCommand -Credential $InstallAccount -Arguments @($PSBoundParameters, $changeUsers) -ScriptBlock {
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
        $sitePath = $webapp.IisSettings[$zone].Path
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $webconfiglocation = Join-Path $sitePath "web.config"
        $webconfigbackuplocation = Join-Path $sitePath "web_config-$timestamp.backup"
        Copy-Item $webconfiglocation $webconfigbackuplocation

        $webconfig = New-Object XML
        $webconfig.Load($webconfiglocation)

        if ($changes.EnableCache) {
            $webconfig.configuration.SharePoint.BlobCache.enabled = $changes.EnableCache.ToString()
        }

        if ($changes.Location) {
            $webconfig.configuration.SharePoint.BlobCache.location = $changes.Location
        }

        if ($changes.MaxSize) {
            $webconfig.configuration.SharePoint.BlobCache.maxSize = $changes.MaxSize
        }
        
        if ($changes.FileTypes) {
            $webconfig.configuration.SharePoint.BlobCache.path = $changes.FileTypes
        }

        $webconfig.Save($webconfiglocation)
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
        [parameter(Mandatory = $false)] [System.Boolean] $EnableCache,
        [parameter(Mandatory = $false)] [System.String] $Location,
        [parameter(Mandatory = $false)] [System.UInt16] $MaxSize,
        [parameter(Mandatory = $false)] [System.String] $FileTypes,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    
    Write-Verbose -Message "Testing blob cache settings for $WebAppUrl"
    
    if ($null -eq $CurrentValues) { return $false }
    
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues `
                                              -DesiredValues $PSBoundParameters `
                                              -ValuesToCheck @("EnableCache", "Location", "MaxSize", "FileType")
}

Export-ModuleMember -Function *-TargetResource
