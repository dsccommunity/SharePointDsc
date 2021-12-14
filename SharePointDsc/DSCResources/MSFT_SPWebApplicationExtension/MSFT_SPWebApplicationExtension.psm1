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
        [ValidateSet("Default", "Intranet", "Internet", "Extranet", "Custom")]
        [System.String]
        $Zone,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Url,

        [Parameter()]
        [System.String]
        $Port,

        [Parameter()]
        [System.String]
        $HostHeader,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [System.Boolean]
        $UseServerNameIndication,

        [Parameter()]
        [System.Boolean]
        $AllowLegacyEncryption,

        [Parameter()]
        [System.String]
        $Path,

        [Parameter()]
        [System.Boolean]
        $AllowAnonymous,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Getting web application extension '$Name' config"

    $osVersion = Get-SPDscOSVersion
    if ($PSBoundParameters.ContainsKey("AllowLegacyEncryption") -and `
        ($osVersion.Major -ne 10 -or $osVersion.Build -ne 20348))
    {
        Write-Verbose ("You cannot specify the AllowLegacyEncryption parameter when using " + `
                "Windows Server 2019 or earlier.")

        return @{
            WebAppUrl = $WebAppUrl
            Zone      = $Zone
        }
    }

    if ($PSBoundParameters.ContainsKey("CertificateThumbprint") -or `
            $PSBoundParameters.ContainsKey("UseServerNameIndication") -or `
            $PSBoundParameters.ContainsKey("AllowLegacyEncryption"))
    {
        $productVersion = Get-SPDscInstalledProductVersion
        if ($productVersion.FileMajorPart -ne 16 -or `
                $productVersion.FileBuildPart -lt 13000)
        {
            Write-Verbose ("The parameters AllowLegacyEncryption, CertificateThumbprint or " + `
                    "UseServerNameIndication are only supported with SharePoint Server " + `
                    "Subscription Edition.")

            return @{
                WebAppUrl = $WebAppUrl
                Zone      = $Zone
            }
        }
    }

    $result = Invoke-SPDscCommand -Arguments $PSBoundParameters `
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
        }
        else
        {
            $HostHeader = $waExt.ServerBindings.HostHeader
            $Port = $waExt.ServerBindings.Port
        }

        $waExtPath = $waExt.Path
        if (-not [System.String]::IsNullOrEmpty($waExtPath))
        {
            $waExtPath = $waExtPath.ToString()
        }

        return @{
            WebAppUrl               = $params.WebAppUrl
            Zone                    = $params.zone
            Name                    = $waExt.ServerComment
            Url                     = $PublicURL
            Port                    = $Port
            HostHeader              = $HostHeader
            CertificateThumbprint   = $waExt.SecureBindings[0].Certificate.Thumbprint
            UseServerNameIndication = $waExt.SecureBindings[0].UseServerNameIndication
            AllowLegacyEncryption   = -not $waExt.SecureBindings[0].DisableLegacyTls
            Path                    = $waExtPath
            AllowAnonymous          = $waExt.AllowAnonymous
            Ensure                  = "Present"
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
        [ValidateSet("Default", "Intranet", "Internet", "Extranet", "Custom")]
        [System.String]
        $Zone,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Url,

        [Parameter()]
        [System.String]
        $Port,

        [Parameter()]
        [System.String]
        $HostHeader,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [System.Boolean]
        $UseServerNameIndication,

        [Parameter()]
        [System.Boolean]
        $AllowLegacyEncryption,

        [Parameter()]
        [System.String]
        $Path,

        [Parameter()]
        [System.Boolean]
        $AllowAnonymous,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Setting web application extension '$Name' config"

    if ($PSBoundParameters.ContainsKey("Port") -eq $false)
    {
        $PSBoundParameters.Port = (New-Object -TypeName System.Uri $WebAppUrl).Port
    }

    $osVersion = Get-SPDscOSVersion
    if ($PSBoundParameters.ContainsKey("AllowLegacyEncryption") -and `
        ($osVersion.Major -ne 10 -or $osVersion.Build -ne 20348))
    {
        $message = ("You cannot specify the AllowLegacyEncryption parameter when using " + `
                "Windows Server 2019 or earlier.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if ($PSBoundParameters.ContainsKey("CertificateThumbprint") -or `
            $PSBoundParameters.ContainsKey("UseServerNameIndication") -or `
            $PSBoundParameters.ContainsKey("AllowLegacyEncryption"))
    {
        $productVersion = Get-SPDscInstalledProductVersion
        if ($productVersion.FileMajorPart -ne 16 -or `
                $productVersion.FileBuildPart -lt 13000)
        {
            $message = ("The parameters AllowLegacyEncryption, CertificateThumbprint or " + `
                    "UseServerNameIndication are only supported with SharePoint Server " + `
                    "Subscription Edition.")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }
    }

    if ($Ensure -eq "Present")
    {
        Invoke-SPDscCommand -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
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
                if ($params.ContainsKey("CertificateThumbprint") -eq $true)
                {
                    $cert = Get-SPCertificate -Thumbprint $params.CertificateThumbprint -Store "EndEntity"
                    if ($null -eq $cert)
                    {
                        $message = ("No certificate found with the specified thumbprint: " + `
                                "$($params.CertificateThumbprint). Make sure the certificate " + `
                                "is added to Certificate Management first!")
                        Add-SPDscEvent -Message $message `
                            -EntryType 'Error' `
                            -EventID 100 `
                            -Source $eventSource
                        throw $message
                    }
                    $newWebAppExtParams.Add("Certificate", $cert)
                }
                if ($params.ContainsKey("UseServerNameIndication") -eq $true)
                {
                    $newWebAppExtParams.Add("UseServerNameIndication", $params.UseServerNameIndication)
                }
                if ($params.ContainsKey("AllowLegacyEncryption") -eq $true)
                {
                    $newWebAppExtParams.Add("AllowLegacyEncryption", $params.AllowLegacyEncryption)
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
                if ((New-Object -TypeName System.Uri $params.Url).Scheme -eq "https")
                {
                    $newWebAppExtParams.Add("SecureSocketsLayer", $true)
                }

                $wa | New-SPWebApplicationExtension @newWebAppExtParams | Out-Null
            }
            else
            {
                if ($params.ContainsKey("AllowAnonymous") -eq $true)
                {
                    $waExt.AllowAnonymous = $params.AllowAnonymous
                    $wa.Update()
                }

                $updateWebAppParams = @{
                    Identity = $params.WebAppUrl
                    Zone     = $params.Zone
                }

                if ($params.ContainsKey("CertificateThumbprint") -eq $true)
                {
                    $cert = Get-SPCertificate -Thumbprint $params.CertificateThumbprint -Store "EndEntity"
                    if ($null -eq $cert)
                    {
                        $message = ("No certificate found with the specified thumbprint: " + `
                                "$($params.CertificateThumbprint). Make sure the certificate " + `
                                "is added to Certificate Management first!")
                        Add-SPDscEvent -Message $message `
                            -EntryType 'Error' `
                            -EventID 100 `
                            -Source $eventSource
                        throw $message
                    }
                    $updateWebAppParams.Add("Certificate", $cert)
                }
                if ($params.ContainsKey("UseServerNameIndication") -eq $true)
                {
                    $updateWebAppParams.Add("UseServerNameIndication", $params.UseServerNameIndication)
                }
                if ($params.ContainsKey("AllowLegacyEncryption") -eq $true)
                {
                    $updateWebAppParams.Add("AllowLegacyEncryption", $params.AllowLegacyEncryption)
                }

                if ((New-Object -TypeName System.Uri $params.Url).Scheme -eq "https")
                {
                    $updateWebAppParams.Add("SecureSocketsLayer", $true)
                }

                $productVersion = Get-SPDscInstalledProductVersion
                if ($productVersion.FileMajorPart -eq 16 -and `
                        $productVersion.FileBuildPart -ge 13000)
                {
                    if ($params.ContainsKey("HostHeader") -eq $true)
                    {
                        $updateWebAppParams.Add("HostHeader", $params.HostHeader)
                    }

                    if ($params.ContainsKey("Port") -eq $true)
                    {
                        $updateWebAppParams.Add("Port", $params.Port)
                    }
                }

                Write-Verbose -Message "Updating web application extension with these parameters: $(Convert-SPDscHashtableToString -Hashtable $updateWebAppParams)"
                Set-SPWebApplication @updateWebAppParams | Out-Null
            }
        }
    }

    if ($Ensure -eq "Absent")
    {
        Invoke-SPDscCommand -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
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
        [ValidateSet("Default", "Intranet", "Internet", "Extranet", "Custom")]
        [System.String]
        $Zone,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Url,

        [Parameter()]
        [System.String]
        $Port,

        [Parameter()]
        [System.String]
        $HostHeader,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [System.Boolean]
        $UseServerNameIndication,

        [Parameter()]
        [System.Boolean]
        $AllowLegacyEncryption,

        [Parameter()]
        [System.String]
        $Path,

        [Parameter()]
        [System.Boolean]
        $AllowAnonymous,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Testing for web application extension '$Name'config"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @(
        "AllowAnonymous",
        "AllowLegacyEncryption",
        "CertificateThumbprint",
        "Ensure",
        "UseServerNameIndication"
    )

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
