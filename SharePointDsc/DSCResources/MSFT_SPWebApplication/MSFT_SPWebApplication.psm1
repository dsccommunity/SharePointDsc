function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPoolAccount,

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
        [System.String]
        $DatabaseName,

        [Parameter()]
        [System.String]
        $DatabaseServer,

        [Parameter()]
        [System.Boolean]
        $UseSQLAuthentication,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [Parameter()]
        [System.Boolean]
        $AllowAnonymous,

        [Parameter()]
        [System.Boolean]
        $UseClassic = $false,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $SiteDataServers,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Getting web application '$Name' config"

    $osVersion = Get-SPDscOSVersion
    if ($PSBoundParameters.ContainsKey("AllowLegacyEncryption") -and `
        ($osVersion.Major -ne 10 -or $osVersion.Build -ne 20348))
    {
        Write-Verbose ("You cannot specify the AllowLegacyEncryption parameter when using " + `
                "Windows Server 2019 or earlier.")

        return @{
            Name                   = $Name
            WebAppUrl              = $WebAppUrl
            ApplicationPool        = $ApplicationPool
            ApplicationPoolAccount = $ApplicationPoolAccount
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
                Name                   = $Name
                WebAppUrl              = $WebAppUrl
                ApplicationPool        = $ApplicationPool
                ApplicationPoolAccount = $ApplicationPoolAccount
            }
        }
    }

    $result = Invoke-SPDscCommand -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $wa = Get-SPWebApplication -Identity $params.Name -ErrorAction SilentlyContinue
        if ($null -eq $wa)
        {
            return @{
                Name                   = $params.Name
                ApplicationPool        = $params.ApplicationPool
                ApplicationPoolAccount = $params.ApplicationPoolAccount
                WebAppUrl              = $params.WebAppUrl
                Ensure                 = "Absent"
            }
        }

        ### COMMENT: Are we making an assumption here, about Default Zone
        $classicAuth = $false
        $authProvider = Get-SPAuthenticationProvider -WebApplication $wa.Url -Zone "Default"
        if ($null -eq $authProvider)
        {
            $classicAuth = $true
        }

        $iisSettings = $wa.IisSettings[0]

        $IISPath = $iisSettings.Path
        if (-not [System.String]::IsNullOrEmpty($IISPath))
        {
            $IISPath = $IISPath.ToString()
        }

        $contentDb = $wa.ContentDatabases | Where-Object -FilterScript {
            $_.Name -eq $params.DatabaseName
        }

        if ($null -eq $contentDb)
        {
            $contentDb = $wa.ContentDatabases[0]
        }

        $currSiteDataServers = @()
        foreach ($entry in $wa.SiteDataServers.GetEnumerator())
        {
            $sdsEntry = @{
                $entry.Key.ToString() = $entry.Value.AbsoluteUri.TrimEnd("/")
            }
            $currSiteDataServers += $sdsEntry
        }

        return @{
            Name                    = $wa.DisplayName
            WebAppUrl               = $wa.Url
            ApplicationPool         = $wa.ApplicationPool.Name
            ApplicationPoolAccount  = $wa.ApplicationPool.Username
            Port                    = (New-Object -TypeName System.Uri $wa.Url).Port
            HostHeader              = (New-Object -TypeName System.Uri $wa.Url).Host
            CertificateThumbprint   = $iisSettings.SecureBindings[0].Certificate.Thumbprint
            UseServerNameIndication = $iisSettings.SecureBindings[0].UseServerNameIndication
            AllowLegacyEncryption   = -not $iisSettings.SecureBindings[0].DisableLegacyTls
            Path                    = $IISPath
            DatabaseName            = $contentDb.Name
            DatabaseServer          = $contentDb.Server
            AllowAnonymous          = $authProvider.AllowAnonymous
            UseClassic              = $classicAuth
            SiteDataServers         = $currSiteDataServers
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
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPoolAccount,

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
        [System.String]
        $DatabaseName,

        [Parameter()]
        [System.String]
        $DatabaseServer,

        [Parameter()]
        [System.Boolean]
        $UseSQLAuthentication,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [Parameter()]
        [System.Boolean]
        $AllowAnonymous,

        [Parameter()]
        [System.Boolean]
        $UseClassic = $false,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $SiteDataServers,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Setting web application '$Name' config"

    $PSBoundParameters.UseClassic = $UseClassic

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

            $wa = Get-SPWebApplication -Identity $params.Name -ErrorAction SilentlyContinue
            if ($null -eq $wa)
            {
                Write-Verbose -Message "Creating new web application"

                $newWebAppParams = @{
                    Name            = $params.Name
                    ApplicationPool = $params.ApplicationPool
                    Url             = $params.WebAppUrl
                }

                # Get a reference to the Administration WebService
                $admService = Get-SPDscContentService
                $appPools = $admService.ApplicationPools | Where-Object -FilterScript {
                    $_.Name -eq $params.ApplicationPool
                }
                if ($null -eq $appPools)
                {
                    # Application pool does not exist, create a new one.
                    # Test if the specified managed account exists. If so, add
                    # ApplicationPoolAccount parameter to create the application pool
                    try
                    {
                        Get-SPManagedAccount $params.ApplicationPoolAccount -ErrorAction Stop | Out-Null
                        $newWebAppParams.Add("ApplicationPoolAccount", $params.ApplicationPoolAccount)
                    }
                    catch
                    {
                        if ($_.Exception.Message -like "*No matching accounts were found*")
                        {
                            $message = ("The specified managed account was not found. Please make " + `
                                    "sure the managed account exists before continuing.")
                            Add-SPDscEvent -Message $message `
                                -EntryType 'Error' `
                                -EventID 100 `
                                -Source $eventSource
                            throw $message
                        }
                        else
                        {
                            $message = ("Error occurred. Web application was not created. Error " + `
                                    "details: $($_.Exception.Message)")
                            Add-SPDscEvent -Message $message `
                                -EntryType 'Error' `
                                -EventID 100 `
                                -Source $eventSource
                            throw $message
                        }
                    }
                }

                if ($params.UseClassic -eq $false)
                {
                    $ap = New-SPAuthenticationProvider
                    $newWebAppParams.Add("AuthenticationProvider", $ap)
                }

                if ($params.ContainsKey("AllowAnonymous") -eq $true)
                {
                    $newWebAppParams.Add("AllowAnonymousAccess", $params.AllowAnonymous)
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
                    $newWebAppParams.Add("Certificate", $cert)
                }
                if ($params.ContainsKey("UseServerNameIndication") -eq $true)
                {
                    $newWebAppParams.Add("UseServerNameIndication", $params.UseServerNameIndication)
                }
                if ($params.ContainsKey("AllowLegacyEncryption") -eq $true)
                {
                    $newWebAppParams.Add("AllowLegacyEncryption", $params.AllowLegacyEncryption)
                }
                if ($params.ContainsKey("DatabaseName") -eq $true)
                {
                    $newWebAppParams.Add("DatabaseName", $params.DatabaseName)
                }
                if ($params.ContainsKey("DatabaseServer") -eq $true)
                {
                    $newWebAppParams.Add("DatabaseServer", $params.DatabaseServer)
                }
                if ($params.ContainsKey("HostHeader") -eq $true)
                {
                    $newWebAppParams.Add("HostHeader", $params.HostHeader)
                }
                if ($params.ContainsKey("Path") -eq $true)
                {
                    $newWebAppParams.Add("Path", $params.Path)
                }
                if ($params.ContainsKey("Port") -eq $true)
                {
                    $newWebAppParams.Add("Port", $params.Port)
                }
                if ((New-Object -TypeName System.Uri $params.WebAppUrl).Scheme -eq "https")
                {
                    $newWebAppParams.Add("SecureSocketsLayer", $true)
                }
                if ($params.useSQLAuthentication -eq $true)
                {
                    Write-Verbose -Message "Using SQL authentication to create web app as `$useSQLAuthentication is set to $($params.useSQLAuthentication)."
                    $newWebAppParams.Add("DatabaseCredentials", $params.DatabaseCredentials)
                }
                else
                {
                    Write-Verbose -Message "`$useSQLAuthentication is false or not specified; using default Windows authentication."
                }

                Write-Verbose -Message "Creating web application with these parameters: $(Convert-SPDscHashtableToString -Hashtable $newWebAppParams)"
                New-SPWebApplication @newWebAppParams | Out-Null
            }
            else
            {
                Write-Verbose -Message "Update existing web application"
                $updateWebApplication = $false

                if ($params.ContainsKey("DatabaseName") -eq $true)
                {
                    Write-Verbose -Message "Checking content database '$($params.DatabaseName)'"
                    $contentDb = $wa.ContentDatabases | Where-Object -FilterScript {
                        $_.Name -eq $params.DatabaseName
                    }

                    if ($null -eq $contentDb)
                    {
                        Write-Verbose -Message "Specified content database does not exist, creating database"
                        $dbParams = @{
                            WebApplication = $params.WebAppUrl
                            Name           = $params.DatabaseName
                        }
                        if ($params.ContainsKey("DatabaseServer") -eq $true)
                        {
                            $dbParams.Add("DatabaseServer", $params.DatabaseServer)
                        }

                        try
                        {
                            $null = Mount-SPContentDatabase @dbParams -ErrorAction Stop
                        }
                        catch
                        {
                            $message = ("Error occurred while mounting content database. " + `
                                    "Content database is not mounted. " + `
                                    "Error details: $($_.Exception.Message)")
                            Add-SPDscEvent -Message $message `
                                -EntryType 'Error' `
                                -EventID 100 `
                                -Source $eventSource
                            throw $message
                        }
                    }
                }

                # Application Pool
                if ($wa.ApplicationPool.Name -ne $params.ApplicationPool)
                {
                    Write-Verbose -Message "Updating application pool for web application"

                    $admService = Get-SPDscContentService
                    $newAppPool = $admService.ApplicationPools | Where-Object -FilterScript {
                        $_.Name -eq $params.ApplicationPool
                    }
                    if ($null -eq $newAppPool)
                    {
                        Write-Verbose -Message "Checking Managed Account for specified Application Pool account"
                        $managedAccount = Get-SPManagedAccount -Identity $params.ApplicationPoolAccount `
                            -ErrorAction SilentlyContinue

                        if ($null -eq $managedAccount)
                        {
                            $message = ("Specified ApplicationPoolAccount '$($params.ApplicationPoolAccount)' " + `
                                    "is not a managed account")
                            Add-SPDscEvent -Message $message `
                                -EntryType 'Error' `
                                -EventID 100 `
                                -Source $eventSource
                            throw $message
                        }

                        try
                        {
                            Write-Verbose -Message "Specified application pool doesn't exist. Creating new application pool."
                            $newAppPool = New-Object Microsoft.SharePoint.Administration.SPApplicationPool($params.ApplicationPool, $admService)
                            $newAppPool.CurrentIdentityType = "SpecificUser"
                            $newAppPool.Username = $params.ApplicationPoolAccount
                            $newAppPool.Update($true)
                            $newAppPool.Provision()
                        }
                        catch
                        {
                            $message = ("Error while creating new application pool. " +
                                "Error details: $($_.Exception.Message)")
                            Add-SPDscEvent -Message $message `
                                -EntryType 'Error' `
                                -EventID 100 `
                                -Source $eventSource
                            throw $message
                        }
                    }

                    Write-Verbose -Message "Applying new application pool"
                    $wa.ApplicationPool = $newAppPool
                    $updateWebApplication = $true
                }

                if ($params.ContainsKey("SiteDataServers") -eq $true)
                {
                    $currentSiteDataServers = $wa.SiteDataServers
                    $currentZones = [array]$currentSiteDataServers.Keys
                    foreach ($currentSDServerZone in $currentZones)
                    {
                        $targetSDServers = $params.SiteDataServers | Where-Object -FilterScript {
                            $_.Zone -eq $currentSDServerZone
                        }

                        if ($null -eq $targetSDServers)
                        {
                            $null = $currentSiteDataServers.Remove($currentSDServerZone)
                        }
                    }

                    foreach ($targetSDServer in $params.SiteDataServers)
                    {
                        $zone = [Microsoft.SharePoint.Administration.SPUrlZone]$targetSDServer.Zone #Specify zone name
                        if ($currentSiteDataServers.ContainsKey($zone))
                        {
                            # Zone exists, check value
                            if ($null -ne (Compare-Object -ReferenceObject $currentSiteDataServers[$zone].AbsoluteUri.TrimEnd("/") -DifferenceObject $targetSDServer.Uri))
                            {
                                $null = $currentSiteDataServers.Remove($zone)

                                $uriList = New-Object System.Collections.Generic.List[System.Uri](1)
                                foreach ($uri in $targetSDServer.Uri)
                                {
                                    $target = New-Object System.Uri($uri)
                                    $uriList.Add($target)
                                }
                                $currentSiteDataServers.Add($zone, $uriList)
                            }
                        }
                        else
                        {
                            # Zone does not exist, add value
                            $uriList = New-Object System.Collections.Generic.List[System.Uri](1)
                            foreach ($uri in $targetSDServer.Uri)
                            {
                                $target = New-Object System.Uri($uri)
                                $uriList.Add($target)
                            }
                            $currentSiteDataServers.Add($zone, $uriList)
                        }
                    }

                    $updateWebApplication = $true
                }

                if ($updateWebApplication -eq $true)
                {
                    $wa.Update()
                    $wa.ProvisionGlobally()
                }

                $updateWebAppParams = @{
                    Identity = $params.WebAppUrl
                    Zone     = 'Default'
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

                    if ((New-Object -TypeName System.Uri $params.WebAppUrl).Scheme -eq "https")
                    {
                        $updateWebAppParams.Add("SecureSocketsLayer", $true)
                    }
                }

                Write-Verbose -Message "Updating web application with these parameters: $(Convert-SPDscHashtableToString -Hashtable $updateWebAppParams)"
                Set-SPWebApplication @updateWebAppParams | Out-Null
            }
        }
    }

    if ($Ensure -eq "Absent")
    {
        Invoke-SPDscCommand -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            $wa = Get-SPWebApplication -Identity $params.Name -ErrorAction SilentlyContinue
            if ($null -ne $wa)
            {
                Write-Verbose -Message "Deleting web application $($params.Name)"
                $wa | Remove-SPWebApplication -Confirm:$false -DeleteIISSite
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
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPoolAccount,

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
        [System.String]
        $DatabaseName,

        [Parameter()]
        [System.String]
        $DatabaseServer,

        [Parameter()]
        [System.Boolean]
        $UseSQLAuthentication,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [Parameter()]
        [System.Boolean]
        $AllowAnonymous,

        [Parameter()]
        [System.Boolean]
        $UseClassic = $false,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $SiteDataServers,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Testing for web application '$Name' config"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($PSBoundParameters.ContainsKey("SiteDataServers"))
    {
        $inDesiredState = $true

        $currentSiteDataServers = $CurrentValues.SiteDataServers
        foreach ($currentSDServerZone in $currentSiteDataServers.Keys)
        {
            $targetSDServers = $PSBoundParameters.SiteDataServers | Where-Object { $_.Zone -eq $currentSDServerZone }
            if ($null -eq $targetSDServers)
            {
                $inDesiredState = $false
            }
        }

        foreach ($targetSDServer in $PSBoundParameters.SiteDataServers)
        {
            $currentZone = $currentSiteDataServers | Where-Object { $_.GetEnumerator().Name -eq $targetSDServer.Zone }
            if ($null -ne $currentZone)
            {
                if ($null -ne (Compare-Object -ReferenceObject $currentZone.($targetSDServer.Zone) -DifferenceObject $targetSDServer.Uri))
                {
                    $inDesiredState = $false
                }
            }
            else
            {
                $inDesiredState = $false
            }
        }

        Write-Verbose -Message "Test-TargetResource returned $inDesiredState"

        return $inDesiredState
    }

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @(
        "AllowLegacyEncryption",
        "ApplicationPool",
        "CertificateThumbprint",
        "DatabaseName",
        "Ensure",
        "UseServerNameIndication"
    )

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $content = ''
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath "\DSCResources\MSFT_SPWebApplication\MSFT_SPWebApplication.psm1" -Resolve

    $spWebApplications = Get-SPWebApplication | Sort-Object -Property Name

    $i = 1;
    $total = $spWebApplications.Length
    foreach ($spWebApp in $spWebApplications)
    {
        try
        {
            Write-Host "Scanning SPWebApplication [$i/$total] {$webAppName}"
            $partialContent = "        SPWebApplication " + $spWebApp.Name.Replace(" ", "") + "`r`n        {`r`n"

            $params = Get-DSCFakeParameters -ModulePath $module
            $params.Name = $spWebApp.name

            $results = Get-TargetResource @params

            $results = Repair-Credentials -results $results

            $appPoolAccount = Get-Credentials $results.ApplicationPoolAccount
            $convertToVariable = $false
            if ($appPoolAccount)
            {
                $convertToVariable = $true
                $results.ApplicationPoolAccount = (Resolve-Credentials -UserName $results.ApplicationPoolAccount) + ".UserName"
            }

            if ($null -eq $results.Get_Item("AllowAnonymous"))
            {
                $results.Remove("AllowAnonymous")
            }

            if ($results.SiteDataServers.Count -ne 0)
            {
                $results.SiteDataServers = Convert-SPDscArrayToCIMInstanceString -Params $results.SiteDataServers -CIMInstanceName "MSFT_SPWebAppSiteDataServers"
            }

            Add-ConfigurationDataEntry -Node "NonNodeData" -Key "DatabaseServer" -Value $results.DatabaseServer -Description "Name of the Database Server associated with the destination SharePoint Farm;"
            $results.DatabaseServer = "`$ConfigurationData.NonNodeData.DatabaseServer"
            $results["Path"] = $results["Path"].ToString()
            $currentDSCBlock = Get-DSCBlock -Params $results -ModulePath $PSScriptRoot
            if ($convertToVariable)
            {
                $currentDSCBlock = Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock -ParameterName "ApplicationPoolAccount"
            }
            $currentDSCBlock = Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock -ParameterName "DatabaseServer"
            $currentDSCBlock = Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock -ParameterName "SiteDataServers" -IsCIMArray $true
            $currentDSCBlock = Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock -ParameterName "PsDscRunAsCredential"

            $partialContent += $currentDSCBlock
            $partialContent += "        }`r`n"

            if ($Global:ExtractionModeValue -ge 2)
            {
                Write-Host "    -> Scanning SharePoint Designer Settings"
                #Read-SPDesignerSettings -WebAppUrl $results.WebAppUrl.ToString() -Scope "WebApplication" -WebAppName $spWebApp.Name.Replace(" ", "")
            }

            <# SPWebApplication Feature Section #>
            if (($Global:ExtractionModeValue -eq 3 -and $Quiet) -or $Global:ComponentsToExtract.Contains("SPFeature"))
            {
                $properties = @{
                    Scope     = "WebApplication"
                    Url       = $SpWebApp.Url
                    DependsOn = "[SPWebApplication]$($spWebApp.Name.Replace(' ', ''))"
                }
                $partialContent += Read-TargetResource -ResourceName 'SPFeature' `
                    -ExportParams $properties
            }
            $properties = @{
                WebAppUrl = $spWebApp.Url
                DependsOn = "[SPWebApplication]$($spWebApp.Name.Replace(' ', ''))"
            }
            $partialContent += Read-TargetResource -ResourceName 'SPOutgoingEmailSettings' `
                -ExportParams $properties
            $i++
        }
        catch
        {
            $_
            $Global:ErrorLog += "[Web Application]" + $spWebApp.Name + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }

        $content += $partialContent
    }
    return $content
}

Export-ModuleMember -Function *-TargetResource
