$script:SPDscUtilModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SharePointDsc.Util'
Import-Module -Name $script:SPDscUtilModulePath

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
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Url,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Default", "Intranet", "Internet", "Extranet", "Custom")]
        [System.String]
        $Zone,

        [Parameter()]
        [System.Boolean]
        $AllowAnonymous,

        [Parameter()]
        [System.String]
        $HostHeader,

        [Parameter()]
        [System.String]
        $Path,

        [Parameter()]
        [System.String]
        $Port,

        [Parameter()]
        [System.Boolean]
        $UseSSL,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting web application extension '$Name' config"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue

        if ($null -eq $wa)
        {
            Write-Verbose -Message "WebApplication $($params.WebAppUrl) does not exist"
            return @{
                WebAppUrl      = $params.WebAppUrl
                Name           = $params.Name
                Url            = $null
                Zone           = $null
                AllowAnonymous = $null
                Ensure         = "Absent"
            }
        }

        $zone = [Microsoft.SharePoint.Administration.SPUrlZone]::$($params.Zone)
        $waExt = $wa.IisSettings[$zone]

        if ($null -eq $waExt)
        {
            return @{
                WebAppUrl      = $params.WebAppUrl
                Name           = $params.Name
                Url            = $params.Url
                Zone           = $params.zone
                AllowAnonymous = $params.AllowAnonymous
                Ensure         = "Absent"
            }
        }

        $publicUrl = (Get-SPAlternateURL -WebApplication $params.WebAppUrl -Zone $params.zone).PublicUrl

        if ($null -ne $waExt.SecureBindings.HostHeader) #default to SSL bindings if present
        {
            $HostHeader = $waExt.SecureBindings.HostHeader
            $Port = $waExt.SecureBindings.Port
            $UseSSL = $true
        }
        else
        {
            $HostHeader = $waExt.ServerBindings.HostHeader
            $Port = $waExt.ServerBindings.Port
            $UseSSL = $false
        }

        $waExtPath = $waExt.Path
        if (-not [System.String]::IsNullOrEmpty($waExtPath))
        {
            $waExtPath = $waExtPath.ToString()
        }
        return @{
            WebAppUrl      = $params.WebAppUrl
            Name           = $waExt.ServerComment
            Url            = $PublicURL
            AllowAnonymous = $waExt.AllowAnonymous
            HostHeader     = $HostHeader
            Path           = $waExtPath
            Port           = $Port
            Zone           = $params.zone
            UseSSL         = $UseSSL
            Ensure         = "Present"
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
        $WebAppUrl,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Url,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Default", "Intranet", "Internet", "Extranet", "Custom")]
        [System.String]
        $Zone,

        [Parameter()]
        [System.Boolean]
        $AllowAnonymous,

        [Parameter()]
        [System.String]
        $HostHeader,

        [Parameter()]
        [System.String]
        $Path,

        [Parameter()]
        [System.String]
        $Port,

        [Parameter()]
        [System.Boolean]
        $UseSSL,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting web application extension '$Name' config"

    if ($Ensure -eq "Present")
    {
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
            -ScriptBlock {
            $params = $args[0]
            $eventSource = $args[1]

            $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue
            if ($null -eq $wa)
            {
                $message = "Web Application with URL $($params.WebAppUrl) does not exist"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
                throw $message
            }


            $zone = [Microsoft.SharePoint.Administration.SPUrlZone]::$($params.Zone)
            $waExt = $wa.IisSettings[$zone]

            if ($null -eq $waExt)
            {
                $newWebAppExtParams = @{
                    Name = $params.Name
                    Url  = $params.Url
                    Zone = $params.zone
                }

                if ($params.ContainsKey("AllowAnonymous") -eq $true)
                {
                    $newWebAppExtParams.Add("AllowAnonymousAccess", $params.AllowAnonymous)
                }
                if ($params.ContainsKey("HostHeader") -eq $true)
                {
                    $newWebAppExtParams.Add("HostHeader", $params.HostHeader)
                }
                if ($params.ContainsKey("Path") -eq $true)
                {
                    $newWebAppExtParams.Add("Path", $params.Path)
                }
                if ($params.ContainsKey("Port") -eq $true)
                {
                    $newWebAppExtParams.Add("Port", $params.Port)
                }
                if ($params.ContainsKey("UseSSL") -eq $true)
                {
                    $newWebAppExtParams.Add("SecureSocketsLayer", $params.UseSSL)
                }

                $wa | New-SPWebApplicationExtension @newWebAppExtParams | Out-Null
            }
            else
            {
                if ($params.ContainsKey("AllowAnonymous") -eq $true)
                {
                    $waExt.AllowAnonymous = $params.AllowAnonymous
                    $wa.update()
                }
            }
        }
    }

    if ($Ensure -eq "Absent")
    {
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
            -ScriptBlock {
            $params = $args[0]
            $eventSource = $args[1]

            $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue
            if ($null -eq $wa)
            {
                $message = "Web Application with URL $($params.WebAppUrl) does not exist"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
                throw $message
            }
            if ($null -ne $wa)
            {
                $wa | Remove-SPWebApplication -Zone $params.zone -Confirm:$false -DeleteIISSite
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
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Url,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Default", "Intranet", "Internet", "Extranet", "Custom")]
        [System.String]
        $Zone,

        [Parameter()]
        [System.Boolean]
        $AllowAnonymous,

        [Parameter()]
        [System.String]
        $HostHeader,

        [Parameter()]
        [System.String]
        $Path,

        [Parameter()]
        [System.String]
        $Port,

        [Parameter()]
        [System.Boolean]
        $UseSSL,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing for web application extension '$Name'config"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("Ensure", "AllowAnonymous")

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPWebApplicationExtension\MSFT_SPWebApplicationExtension.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module
    $zones = @("Default", "Intranet", "Internet", "Extranet", "Custom")
    $webApps = Get-SPWebApplication
    foreach ($wa in $webApps)
    {
        try
        {
            if ($null -ne $wa)
            {
                $params.WebAppUrl = $wa.Url

                for ($i = 0; $i -lt $zones.Length; $i++)
                {
                    if ($null -ne $wa.IisSettings[$zones[$i]])
                    {
                        $params.Zone = $zones[$i]
                        $PartialContent = "        SPWebApplicationExtension " + [System.Guid]::NewGuid().toString() + "`r`n"
                        $PartialContent += "        {`r`n"
                        $results = Get-TargetResource @params

                        if ($results.Contains("InstallAccount"))
                        {
                            $results.Remove("InstallAccount")
                        }
                        if ("" -eq $results.HostHeader)
                        {
                            $results.Remove("HostHeader")
                        }
                        if ($null -eq $results.AuthenticationProvider)
                        {
                            $results.Remove("AuthenticationProvider")
                        }
                        $results = Repair-Credentials -results $results
                        $results["Path"] = $results["Path"].ToString()
                        $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
                        $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
                        $PartialContent += $currentBlock
                        $PartialContent += "        }`r`n"
                        $Content += $PartialContent
                    }
                }
            }
        }
        catch
        {
            $Global:ErrorLog += "[Web Application Extensions]" + $wa.Url + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
