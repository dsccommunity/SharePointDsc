function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Default", "Intranet", "Extranet", "Custom", "Internet")]
        [System.String]
        $Zone,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Url,

        [Parameter()]
        [System.Boolean]
        $Internal = $false,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting Alternate URL for $Zone in $WebAppName"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $aam = Get-SPAlternateURL -Identity $params.Url `
            -ErrorAction SilentlyContinue

        if ($null -eq $aam)
        {
            return @{
                WebAppName = $params.WebAppName
                Zone       = $params.Zone
                Url        = $params.Url
                Ensure     = "Absent"
            }
        }

        $internal = $false
        if ($aam.PublicUrl -ne $aam.IncomingUrl)
        {
            $internal = $true
        }

        $wa = Get-SPWebApplication -Identity $aam.PublicUrl

        return @{
            WebAppName = $wa.DisplayName
            Zone       = $aam.Zone
            Url        = $aam.IncomingUrl
            Internal   = $internal
            Ensure     = "Present"
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
        $WebAppName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Default", "Intranet", "Extranet", "Custom", "Internet")]
        [System.String]
        $Zone,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Url,

        [Parameter()]
        [System.Boolean]
        $Internal = $false,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount

    )

    Write-Verbose -Message "Setting Alternate URL for $Zone in $WebAppName"

    if ($Ensure -eq "Present")
    {
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
            -ScriptBlock {
            $params = $args[0]
            $eventSource = $args[1]

            $webapp = Get-SPWebApplication -IncludeCentralAdministration | Where-Object -FilterScript {
                $_.DisplayName -eq $params.WebAppName
            }

            if ($null -eq $webapp)
            {
                $message = "Web application was not found. Please check WebAppName parameter!"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
                throw $message
            }

            $urlAam = Get-SPAlternateURL -Identity $params.Url `
                -ErrorAction SilentlyContinue

            $webAppAams = Get-SPAlternateURL -WebApplication $webapp `
                -Zone $params.Zone `
                -ErrorAction SilentlyContinue

            if ($null -eq $webAppAams)
            {
                # No AAM found on specified WebApp in specified Zone
                if ($null -eq $urlAam)
                {
                    # urlAAM not found, so it is safe to create AAM on specified zone
                    $cmdParams = @{
                        WebApplication = $webapp
                        Url            = $params.Url
                        Zone           = $params.Zone
                    }
                    if ($params.ContainsKey("Internal") -eq $true)
                    {
                        $cmdParams.Add("Internal", $params.Internal)
                    }
                    New-SPAlternateURL @cmdParams | Out-Null
                }
                else
                {
                    $message = ("Specified URL found on different WebApp/Zone: WebApp " + `
                            "$($urlAam.PublicUrl) in zone $($urlAam.Zone)")
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $eventSource
                    throw $message
                }
            }
            else
            {
                # WebApp has one or more AAMs, check for URL
                $aamForUrl = $webAppAams | Where-Object -FilterScript {
                    $_.IncomingUrl -eq $params.Url.TrimEnd('/')
                }

                if ($null -eq $aamForUrl)
                {
                    # URL not configured on WebApp
                    if ($null -eq $urlAam)
                    {
                        # urlAAM not found, so it is safe to create AAM on specified zone (or modify existing if CA)
                        # If this is Central Admin and Default zone, we want to update the existing AAM instead of adding a new one
                        if ($webapp.IsAdministrationWebApplication -and $params.Zone -eq "Default")
                        {
                            # web app is Central Administration and Default zone

                            # If CA has more than 1 AAM in Default zone, Set-SPAlternateUrl should consolidate into 1
                            # For additional CA servers, use other zones instead of Default

                            Set-SPAlternateURL -Identity $webApp.Url -Url $params.Url -Zone $params.Zone | Out-Null
                        }
                        else
                        {
                            $cmdParams = @{
                                WebApplication = $webapp
                                Url            = $params.Url
                                Zone           = $params.Zone
                            }
                            if (($params.ContainsKey("Internal") -eq $true))
                            {
                                $cmdParams.Add("Internal", $params.Internal)
                            }
                            New-SPAlternateURL @cmdParams | Out-Null
                        }
                    }
                    else
                    {
                        $message = ("Specified URL ($($params.Url)) found on different WebApp/Zone: " + `
                                "WebApp $($urlAam.PublicUrl) in zone $($urlAam.Zone)")
                        Add-SPDscEvent -Message $message `
                            -EntryType 'Error' `
                            -EventID 100 `
                            -Source $eventSource
                        throw $message
                    }
                }
                else
                {
                    if ($params.Internal -eq $false)
                    {
                        if (($urlAam.PublicUrl -eq $aamForUrl.PublicUrl) -and `
                            ($urlAam.Zone -eq $aamForUrl.Zone))
                        {
                            $webAppAams | Set-SPAlternateURL -Url $params.Url | Out-Null
                        }
                        else
                        {
                            $message = ("Specified URL found on different WebApp/Zone: WebApp " + `
                                    "$($urlAam.PublicUrl) in zone $($urlAam.Zone)")
                            Add-SPDscEvent -Message $message `
                                -EntryType 'Error' `
                                -EventID 100 `
                                -Source $eventSource
                            throw $message
                        }
                    }
                    else
                    {
                        Write-Verbose -Message "URL already exists!"
                    }
                }
            }
        }
    }
    else
    {
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]
            $aam = Get-SPAlternateURL -Identity $params.Url `
                -ErrorAction SilentlyContinue

            Remove-SPAlternateURL -Identity $aam -Confirm:$false
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
        $WebAppName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Default", "Intranet", "Extranet", "Custom", "Internet")]
        [System.String]
        $Zone,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Url,

        [Parameter()]
        [System.Boolean]
        $Internal = $false,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount

    )

    Write-Verbose -Message "Testing Alternate URL for $Zone in $WebAppName"

    $PSBoundParameters.Ensure = $Ensure
    $PSBoundParameters.Internal = $Internal

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($Ensure -eq "Present")
    {
        $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("WebAppName", `
                "Zone", `
                "Url", `
                "Ensure", `
                "Internal")
    }
    else
    {
        $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("Ensure")
    }

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDSC" | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath "\DSCResources\MSFT_SPAlternateUrl\MSFT_SPAlternateUrl.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module

    $webApps = Get-SPWebApplication
    foreach ($webApp in $webApps)
    {
        $alternateUrls = Get-SPAlternateUrl -WebApplication $webApp

        foreach ($alternateUrl in $alternateUrls)
        {
            $PartialContent = "        SPAlternateUrl " + [System.Guid]::NewGuid().toString() + "`r`n"
            $PartialContent += "        {`r`n"
            $params.WebAppName = $webApp.Name
            $params.Zone = $alternateUrl.UrlZone
            $params.Url = $alternateUrl.IncomingUrl
            $results = Get-TargetResource @params
            $results = Repair-Credentials -results $results
            $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
            $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
            $PartialContent += $currentBlock
            $PartialContent += "        }`r`n"
            $Content += $PartialContent
        }
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
