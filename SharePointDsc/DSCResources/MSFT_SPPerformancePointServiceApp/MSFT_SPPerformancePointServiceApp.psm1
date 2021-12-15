function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $ProxyName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

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
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Getting for PerformancePoint Service Application '$Name'"

    $productVersion = Get-SPDscInstalledProductVersion
    if ($productVersion.FileMajorPart -eq 16 `
            -and $productVersion.FileBuildPart -gt 13000)
    {
        $message = ("Since SharePoint Server Subscription Edition the Performance Point Services " + `
                "does no longer exists. See https://docs.microsoft.com/en-us/sharepoint/what-s-new/what-s-deprecated-or-removed-from-sharepoint-server-2019#access-services-2013 " + `
                "for more info.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $result = Invoke-SPDscCommand -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $serviceApps = Get-SPServiceApplication | Where-Object -FilterScript {
            $_.Name -eq $params.Name
        }

        $nullReturn = @{
            Name            = $params.Name
            ApplicationPool = $params.ApplicationPool
            Ensure          = "Absent"
        }
        if ($null -eq $serviceApps)
        {
            return $nullReturn
        }
        $serviceApp = $serviceApps | Where-Object -FilterScript {
            $_.GetType().FullName -eq "Microsoft.PerformancePoint.Scorecards.BIMonitoringServiceApplication"
        }

        if ($null -eq $serviceApp)
        {
            return $nullReturn
        }
        else
        {
            $serviceAppProxies = Get-SPServiceApplicationProxy -ErrorAction SilentlyContinue
            if ($null -ne $serviceAppProxies)
            {
                $serviceAppProxy = $serviceAppProxies | Where-Object -FilterScript {
                    $serviceApp.IsConnected($_)
                }
                if ($null -ne $serviceAppProxy)
                {
                    $proxyName = $serviceAppProxy.Name
                }
            }
            return @{
                Name            = $serviceApp.DisplayName
                ProxyName       = $proxyName
                ApplicationPool = $serviceApp.ApplicationPool.Name
                DatabaseName    = $serviceApp.Database.Name
                DatabaseServer  = $serviceApp.Database.NormalizedDataSource
                Ensure          = "Present"
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
        $Name,

        [Parameter()]
        [System.String]
        $ProxyName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

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
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Setting PerformancePoint Service Application '$Name'"

    $productVersion = Get-SPDscInstalledProductVersion
    if ($productVersion.FileMajorPart -eq 16 `
            -and $productVersion.FileBuildPart -gt 13000)
    {
        $message = ("Since SharePoint Server Subscription Edition the Performance Point Services " + `
                "does no longer exists. See https://docs.microsoft.com/en-us/sharepoint/what-s-new/what-s-deprecated-or-removed-from-sharepoint-server-2019#access-services-2013 " + `
                "for more info.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $result = Get-TargetResource @PSBoundParameters

    if ($result.Ensure -eq "Absent" -and $Ensure -eq "Present")
    {
        Write-Verbose -Message "Creating PerformancePoint Service Application $Name"
        Invoke-SPDscCommand -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            $newParams = @{
                Name            = $params.Name
                ApplicationPool = $params.ApplicationPool
            }
            if ($params.ContainsKey("DatabaseName") -eq $true)
            {
                $newParams.Add("DatabaseName", $params.DatabaseName)
            }
            if ($params.ContainsKey("DatabaseServer") -eq $true)
            {
                $newParams.Add("DatabaseServer", $params.DatabaseServer)
            }

            if ($params.useSQLAuthentication -eq $true)
            {
                Write-Verbose -Message "Using SQL authentication to create service application as `$useSQLAuthentication is set to $($params.useSQLAuthentication)."
                $newParams.Add("DatabaseSQLAuthenticationCredential", $params.DatabaseCredentials)
            }
            else
            {
                Write-Verbose -Message "`$useSQLAuthentication is false or not specified; using default Windows authentication."
            }

            New-SPPerformancePointServiceApplication @newParams
            if ($null -eq $params.ProxyName)
            {
                $pName = "$($params.Name) Proxy"
            }
            else
            {
                $pName = $params.ProxyName
            }
            New-SPPerformancePointServiceApplicationProxy -Name $pName `
                -ServiceApplication $params.Name `
                -Default
        }
    }

    if ($result.Ensure -eq "Present" -and $Ensure -eq "Present")
    {
        if ($ApplicationPool -ne $result.ApplicationPool)
        {
            Write-Verbose -Message "Updating PerformancePoint Service Application $Name"
            Invoke-SPDscCommand -Arguments $PSBoundParameters `
                -ScriptBlock {
                $params = $args[0]

                $appPool = Get-SPServiceApplicationPool -Identity $params.ApplicationPool

                Get-SPServiceApplication | Where-Object -FilterScript {
                    $_.Name -eq $params.Name -and `
                        $_.GetType().FullName -eq "Microsoft.PerformancePoint.Scorecards.BIMonitoringServiceApplication"
                } | Set-SPPerformancePointServiceApplication -ApplicationPool $appPool
            }
        }
    }
    if ($Ensure -eq "Absent")
    {
        Write-Verbose -Message "Removing PerformancePoint Service Application $Name"
        Invoke-SPDscCommand -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            $app = Get-SPServiceApplication | Where-Object -FilterScript {
                $_.Name -eq $params.Name -and `
                    $_.GetType().FullName -eq "Microsoft.PerformancePoint.Scorecards.BIMonitoringServiceApplication"
            }

            $proxies = Get-SPServiceApplicationProxy
            foreach ($proxyInstance in $proxies)
            {
                if ($app.IsConnected($proxyInstance))
                {
                    $proxyInstance.Delete()
                }
            }

            Remove-SPServiceApplication -Identity $app -Confirm:$false
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

        [Parameter()]
        [System.String]
        $ProxyName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

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
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Testing PerformancePoint Service Application '$Name'"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("ApplicationPool", "Ensure")

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPPerformancePointServiceApp\MSFT_SPPerformancePointServiceApp.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module

    $was = Get-SPServiceApplication | Where-Object { $_.GetType().Name -eq "BIMonitoringServiceApplication" }
    foreach ($wa in $was)
    {
        try
        {
            if ($null -ne $wa)
            {
                $params.Name = $wa.Name
                $PartialContent = "        SPPerformancePointServiceApp " + $wa.Name.Replace(" ", "") + "`r`n"
                $PartialContent += "        {`r`n"
                $results = Get-TargetResource @params

                $results = Repair-Credentials -results $results

                Add-ConfigurationDataEntry -Node "NonNodeData" -Key "DatabaseServer" -Value $results.DatabaseServer -Description "Name of the Database Server associated with the destination SharePoint Farm;"
                $results.DatabaseServer = "`$ConfigurationData.NonNodeData.DatabaseServer"

                $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
                $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "DatabaseServer"
                $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"

                $PartialContent += $currentBlock
                $PartialContent += "        }`r`n"
                $Content += $PartialContent
            }
        }
        catch
        {
            $Global:ErrorLog += "[PerformancePoint Service Application]" + $wa.Name + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
