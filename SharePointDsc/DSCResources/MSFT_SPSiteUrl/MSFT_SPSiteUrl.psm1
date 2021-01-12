function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Url,

        [Parameter()]
        [System.String]
        $Intranet,

        [Parameter()]
        [System.String]
        $Internet,

        [Parameter()]
        [System.String]
        $Extranet,

        [Parameter()]
        [System.String]
        $Custom,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting site collection url for $Url"

    if ($PSBoundParameters.ContainsKey("Intranet") -eq $false -and
        $PSBoundParameters.ContainsKey("Internet") -eq $false -and
        $PSBoundParameters.ContainsKey("Extranet") -eq $false -and
        $PSBoundParameters.ContainsKey("Custom") -eq $false)
    {
        Write-Verbose -Message "No zone is specified"
    }

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $nullreturn = @{
            Url = $params.Url
        }

        $site = Get-SPSite -Identity $params.Url `
            -ErrorAction SilentlyContinue

        if ($null -eq $site)
        {
            Write-Verbose -Message "Specified site $($params.Url) does not exist"
            return $nullreturn
        }

        if ($site.HostHeaderIsSiteName -eq $false)
        {
            Write-Verbose -Message ("Specified site $($params.Url) is not a Host Named " + `
                    "Site Collection")
            return $nullreturn
        }

        $intranetUrl = $null
        $internetUrl = $null
        $extranetUrl = $null
        $customUrl = $null

        $siteurls = Get-SPSiteUrl -Identity $params.Url
        foreach ($siteurl in $siteurls)
        {
            switch ($siteurl.Zone)
            {
                "Default"
                {
                    Write-Verbose -Message "SiteUrl for Default zone is $($siteurl.Url)"
                }
                "Intranet"
                {
                    Write-Verbose -Message "SiteUrl for Intranet zone is $($siteurl.Url)"
                    $intranetUrl = $siteurl.Url
                }
                "Internet"
                {
                    Write-Verbose -Message "SiteUrl for Internet zone is $($siteurl.Url)"
                    $internetUrl = $siteurl.Url
                }
                "Extranet"
                {
                    Write-Verbose -Message "SiteUrl for Extranet zone is $($siteurl.Url)"
                    $extranetUrl = $siteurl.Url
                }
                "Custom"
                {
                    Write-Verbose -Message "SiteUrl for Custom zone is $($siteurl.Url)"
                    $customUrl = $siteurl.Url
                }
            }
        }
        return @{
            Url      = $params.Url
            Intranet = $intranetUrl
            Internet = $internetUrl
            Extranet = $extranetUrl
            Custom   = $customUrl
        }
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

        [Parameter()]
        [System.String]
        $Intranet,

        [Parameter()]
        [System.String]
        $Internet,

        [Parameter()]
        [System.String]
        $Extranet,

        [Parameter()]
        [System.String]
        $Custom,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting site collection url for $Url"

    if ($PSBoundParameters.ContainsKey("Intranet") -eq $false -and
        $PSBoundParameters.ContainsKey("Internet") -eq $false -and
        $PSBoundParameters.ContainsKey("Extranet") -eq $false -and
        $PSBoundParameters.ContainsKey("Custom") -eq $false)
    {
        $message = "No zone specified. Please specify a zone"
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]

        $site = Get-SPSite -Identity $params.Url `
            -ErrorAction SilentlyContinue

        if ($null -eq $site)
        {
            $message = "Specified site $($params.Url) does not exist"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }

        if ($site.HostHeaderIsSiteName -eq $false)
        {
            $message = "Specified site $($params.Url) is not a Host Named Site Collection"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }

        $siteurls = Get-SPSiteUrl -Identity $params.Url
        foreach ($siteurl in $siteurls)
        {
            switch ($siteurl.Zone)
            {
                "Default"
                {
                    Write-Verbose -Message "SiteUrl for Default zone is $($siteurl.Url)"
                }
                "Intranet"
                {
                    Write-Verbose -Message "SiteUrl for Intranet zone is $($siteurl.Url)"
                    if ($params.Intranet -ne $siteurl.Url)
                    {
                        Remove-SPSiteUrl -Url $siteurl.Url
                    }
                }
                "Internet"
                {
                    Write-Verbose -Message "SiteUrl for Internet zone is $($siteurl.Url)"
                    if ($params.Internet -ne $siteurl.Url)
                    {
                        Remove-SPSiteUrl -Url $siteurl.Url
                    }
                }
                "Extranet"
                {
                    Write-Verbose -Message "SiteUrl for Extranet zone is $($siteurl.Url)"
                    if ($params.Extranet -ne $siteurl.Url)
                    {
                        Remove-SPSiteUrl -Url $siteurl.Url
                    }
                }
                "Custom"
                {
                    Write-Verbose -Message "SiteUrl for Custom zone is $($siteurl.Url)"
                    if ($params.Custom -ne $siteurl.Url)
                    {
                        Remove-SPSiteUrl -Url $siteurl.Url
                    }
                }
            }
        }

        if ($null -ne $params.Intranet)
        {
            $siteurl = Get-SPSiteURL -Identity $params.Intranet -ErrorAction SilentlyContinue
            if ($null -eq $siteurl)
            {
                Set-SPSiteUrl -Identity $params.Url -Zone Intranet -Url $params.Intranet
            }
            else
            {
                $message = ("Specified URL $($params.Intranet) (Zone: Intranet) is already assigned " + `
                        "to a site collection: $($siteurl[0].Url)")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
                throw $message
            }
        }

        if ($null -ne $params.Internet)
        {
            $siteurl = Get-SPSiteURL -Identity $params.Internet -ErrorAction SilentlyContinue
            if ($null -eq $siteurl)
            {
                Set-SPSiteUrl -Identity $params.Url -Zone Internet -Url $params.Internet
            }
            else
            {
                $message = ("Specified URL $($params.Internet) (Zone: Internet) is already assigned " + `
                        "to a site collection: $($siteurl[0].Url)")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
                throw $message
            }
        }

        if ($null -ne $params.Extranet)
        {
            $siteurl = Get-SPSiteURL -Identity $params.Extranet -ErrorAction SilentlyContinue
            if ($null -eq $siteurl)
            {
                Set-SPSiteUrl -Identity $params.Url -Zone Extranet -Url $params.Extranet
            }
            else
            {
                $message = ("Specified URL $($params.Extranet) (Zone: Extranet) is already assigned " + `
                        "to a site collection: $($siteurl[0].Url)")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
                throw $message
            }
        }

        if ($null -ne $params.Custom)
        {
            $siteurl = Get-SPSiteURL -Identity $params.Custom -ErrorAction SilentlyContinue
            if ($null -eq $siteurl)
            {
                Set-SPSiteUrl -Identity $params.Url -Zone Custom -Url $params.Custom
            }
            else
            {
                $message = ("Specified URL $($params.Custom) (Zone: Custom) is already assigned " + `
                        "to a site collection: $($siteurl[0].Url)")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
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
        $Url,

        [Parameter()]
        [System.String]
        $Intranet,

        [Parameter()]
        [System.String]
        $Internet,

        [Parameter()]
        [System.String]
        $Extranet,

        [Parameter()]
        [System.String]
        $Custom,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing site collection url for $Url"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($null -eq $CurrentValues.Intranet -and
        $null -eq $CurrentValues.Internet -and
        $null -eq $CurrentValues.Extranet -and
        $null -eq $CurrentValues.Custom)
    {
        $message = "All zones do not have a SiteUrl configured"
        Write-Verbose -Message $message
        Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

        Write-Verbose -Message "Test-TargetResource returned false"
        return $false
    }

    if ([String]$CurrentValues.Intranet -ne $Intranet)
    {
        $message = "The Intranet zone {$($CurrentValues.Intranet)} is not configured as desired $Intranet"
        Write-Verbose -Message $message
        Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

        Write-Verbose -Message "Test-TargetResource returned false"
        return $false
    }

    if ([String]$CurrentValues.Internet -ne $Internet)
    {
        $message = "The Internet zone {$($CurrentValues.Internet)} is not configured as desired $Internet"
        Write-Verbose -Message $message
        Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

        Write-Verbose -Message "Test-TargetResource returned false"
        return $false
    }

    if ([String]$CurrentValues.Extranet -ne $Extranet)
    {
        $message = "The Extranet zone {$($CurrentValues.Extranet)} is not configured as desired $Extranet"
        Write-Verbose -Message $message
        Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

        Write-Verbose -Message "Test-TargetResource returned false"
        return $false
    }

    if ([String]$CurrentValues.Custom -ne $Custom)
    {
        $message = "The Custom zone {$($CurrentValues.Custom)} is not configured as desired $Custom"
        Write-Verbose -Message $message
        Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

        Write-Verbose -Message "Test-TargetResource returned false"
        return $false
    }

    Write-Verbose -Message "Test-TargetResource returned true"
    return $true
}

function Export-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [System.String]
        $URL,

        [Parameter()]
        [System.String[]]
        $DependsOn
    )

    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDSC" | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPSiteURL\MSFT_SPSiteURL.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module
    $params.Url = $URL
    $results = Get-TargetResource @params
    if ($null -ne $results.Intranet -or $null -ne $results.Internet -or $null -ne $results.Custom -or $null -ne $results.Extranet)
    {
        $blockGUID = New-Guid
        $PartialContent = "        SPSiteUrl " + $blockGUID.ToString() + "`r`n"
        $PartialContent += "        {`r`n"
        $results = Repair-Credentials -results $results
        if ($DependsOn)
        {
            $results.add("DependsOn", $DependsOn)
        }
        $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
        $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
        $PartialContent += $currentBlock
        $PartialContent += "        }`r`n"
        $Content += $PartialContent
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
