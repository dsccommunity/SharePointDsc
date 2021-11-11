function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $AppDomain,

        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet("Default", "Internet", "Intranet", "Extranet", "Custom")]
        $Zone,

        [Parameter()]
        [System.String]
        $Port,

        [Parameter()]
        [System.Boolean]
        $SSL
    )

    Write-Verbose -Message "Getting app domain settings for '$AppDomain'"

    $result = Invoke-SPDscCommand -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]
        $webAppAppDomain = Get-SPWebApplicationAppDomain -WebApplication $params.WebAppUrl `
            -Zone $params.Zone

        if ($null -eq $webAppAppDomain)
        {
            return @{
                WebAppUrl = $params.WebAppUrl
                AppDomain = $null
                Zone      = $null
                Port      = $null
                SSL       = $null
            }
        }
        else
        {
            return @{
                WebAppUrl = $params.WebAppUrl
                AppDomain = $webAppAppDomain.AppDomain
                Zone      = $webAppAppDomain.UrlZone
                Port      = $webAppAppDomain.Port
                SSL       = $webAppAppDomain.IsSchemeSSL
            }
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
        $AppDomain,

        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet("Default", "Internet", "Intranet", "Extranet", "Custom")]
        $Zone,

        [Parameter()]
        [System.String]
        $Port,

        [Parameter()]
        [System.Boolean]
        $SSL
    )

    Write-Verbose -Message "Setting app domain settings for '$AppDomain'"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Invoke-SPDscCommand -Arguments @($PSBoundParameters, $CurrentValues) `
        -ScriptBlock {
        $params = $args[0]
        $CurrentValues = $args[1]

        if ($null -ne $CurrentValues.AppDomain)
        {
            Get-SPWebApplicationAppDomain -WebApplication $params.WebAppUrl `
                -Zone $params.Zone | Remove-SPWebApplicationAppDomain
            Start-Sleep -Seconds 5
        }

        $newParams = @{
            AppDomain      = $params.AppDomain
            WebApplication = $params.WebAppUrl
            Zone           = $params.Zone
        }
        if ($params.ContainsKey("Port") -eq $true)
        {
            $newParams.Add("Port", $params.Port)
        }
        if ($params.ContainsKey("SSL") -eq $true)
        {
            $newParams.Add("SecureSocketsLayer", $params.SSL)
        }

        New-SPWebApplicationAppDomain @newParams
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
        $AppDomain,

        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet("Default", "Internet", "Intranet", "Extranet", "Custom")]
        $Zone,

        [Parameter()]
        [System.String]
        $Port,

        [Parameter()]
        [System.Boolean]
        $SSL
    )

    Write-Verbose -Message "Testing app domain settings for '$AppDomain'"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("AppDomain", "Port", "SSL")

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPWebApplicationAppDomain\MSFT_SPWebApplicationAppDomain.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module
    $webApps = Get-SPWebApplication
    $i = 1
    $countWebApp = $webApps.Length
    foreach ($webApp in $webApps)
    {
        try
        {
            Write-Host "Scanning App Domains for Web Application [$i/$countWebApp] {$($webApp.Url)}"
            $webApplicationAppDomains = Get-SPWebApplicationAppDomain -WebApplication $webApp.Url
            $count = $webApplicationAppDomains.Length
            $j = 1
            foreach ($appDomain in $webApplicationAppDomains)
            {
                try
                {
                    Write-Host "    -> Scanning App Domain [$j/$count] {$($appDomain.AppDomain)}"
                    $params.WebAppUrl = $webApp.Url
                    $PartialContent = "        SPWebApplicationAppDomain " + [System.Guid]::NewGuid().ToString() + "`r`n"
                    $PartialContent += "        {`r`n"
                    $results = Get-TargetResource @params

                    $results = Repair-Credentials -results $results

                    $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
                    $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
                    $PartialContent += $currentBlock
                    $PartialContent += "        }`r`n"
                    $Content += $PartialContent

                }
                catch
                {
                    $_
                    $Global:ErrorLog += "[WebApplicationAppDomain] Couldn't obtain information from App Domain {$($appDomain.AppDomain)} for Web Application {$($webApp.Url)}`r`n"
                }
                $j++
            }
        }
        catch
        {
            $_
            $Global:ErrorLog += "[SPWebApplicationAppDomain] Couldn't properly retrieve all App Domain from Web Application {$($webApp.Url)}`r`n"
        }
        $i++
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
