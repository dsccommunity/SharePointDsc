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
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting BCS service app '$Name'"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $serviceApps = Get-SPServiceApplication | Where-Object -FilterScript {
            $_.Name -eq $params.Name
        }

        $nullReturn = @{
            Name            = $params.Name
            ApplicationPool = $params.ApplicationPool
            DatabaseName    = $null
            DatabaseServer  = $null
            Ensure          = "Absent"
        }
        if ($null -eq $serviceApps)
        {
            return $nullReturn
        }
        $serviceApp = $serviceApps | Where-Object -FilterScript {
            $_.GetType().FullName -eq "Microsoft.SharePoint.BusinessData.SharedService.BdcServiceApplication"
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

            $returnVal = @{
                Name            = $serviceApp.DisplayName
                ProxyName       = $proxyName
                ApplicationPool = $serviceApp.ApplicationPool.Name
                DatabaseName    = $serviceApp.Database.Name
                DatabaseServer  = $serviceApp.Database.NormalizedDataSource
                Ensure          = "Present"
            }
            return $returnVal
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
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting BCS service app '$Name'"

    if ($Ensure -eq "Present" -and
        ($PSBoundParameters.ContainsKey("DatabaseName") -eq $false -or
            $PSBoundParameters.ContainsKey("DatabaseServer") -eq $false))
    {
        $message = "Parameter DatabaseName and DatabaseServer are required when Ensure=Present"
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $result = Get-TargetResource @PSBoundParameters

    if ($result.Ensure -eq "Absent" -and $Ensure -eq "Present")
    {
        # The service app doesn't exist but should
        Write-Verbose -Message "Creating BCS Service Application $Name"
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            if ($params.UseSQLAuthentication -eq $true)
            {
                Write-Verbose -Message "Using SQL authentication to create service application as `$useSQLAuthentication is set to $($params.useSQLAuthentication)."
                $databaseCredentialsParam = @{
                    DatabaseCredentials = $params.DatabaseCredentials
                }
            }
            else
            {
                $databaseCredentialsParam = ""
            }

            $bcsServiceApp = New-SPBusinessDataCatalogServiceApplication -Name $params.Name `
                -ApplicationPool $params.ApplicationPool `
                -DatabaseName $params.DatabaseName `
                -DatabaseServer $params.DatabaseServer `
                @databaseCredentialsParam

            if ($params.ContainsKey("ProxyName"))
            {
                # The New-SPBusinessDataCatalogServiceApplication cmdlet creates a proxy by default
                # If a name is specified, we first need to delete the created one
                $proxies = Get-SPServiceApplicationProxy
                foreach ($proxyInstance in $proxies)
                {
                    if ($bcsServiceApp.IsConnected($proxyInstance))
                    {
                        $proxyInstance.Delete()
                    }
                }

                New-SPBusinessDataCatalogServiceApplicationProxy -Name $params.ProxyName `
                    -ServiceApplication $bcsServiceApp | Out-Null
            }
        }
    }

    if ($result.Ensure -eq "Present" -and $Ensure -eq "Present")
    {
        # The service app exists but has the wrong application pool
        if ($ApplicationPool -ne $result.ApplicationPool)
        {
            Write-Verbose -Message "Updating BCS Service Application $Name"
            Invoke-SPDscCommand -Credential $InstallAccount `
                -Arguments $PSBoundParameters `
                -ScriptBlock {
                $params = $args[0]

                $appPool = Get-SPServiceApplicationPool -Identity $params.ApplicationPool

                Get-SPServiceApplication | Where-Object -FilterScript {
                    $_.Name -eq $params.Name -and `
                        $_.GetType().FullName -eq "Microsoft.SharePoint.BusinessData.SharedService.BdcServiceApplication"
                } `
                | Set-SPBusinessDataCatalogServiceApplication -ApplicationPool $appPool
            }
        }
    }

    if ($Ensure -eq "Absent")
    {
        # The service app should not exit
        Write-Verbose -Message "Removing BCS Service Application $Name"
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            $app = Get-SPServiceApplication | Where-Object -FilterScript {
                $_.Name -eq $params.Name -and `
                    $_.GetType().FullName -eq "Microsoft.SharePoint.BusinessData.SharedService.BdcServiceApplication"
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
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing BCS service app '$Name'"

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
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter()]
        [System.String]
        $ModulePath,

        [Parameter()]
        [System.Collections.Hashtable]
        $Params
    )

    $VerbosePreference = "SilentlyContinue"
    if ([System.String]::IsNullOrEmpty($modulePath) -eq $false)
    {
        $module = Resolve-Path $modulePath
    }
    else
    {
        $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
        $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPBCSServiceApp\MSFT_SPBCSServiceApp.psm1" -Resolve
    }
    $Content = ''

    if ($null -eq $params)
    {
        $params = Get-DSCFakeParameters -ModulePath $module
    }

    $bcsa = Get-SPServiceApplication | Where-Object { $_.GetType().Name -eq "BdcServiceApplication" }

    foreach ($bcsaInstance in $bcsa)
    {
        try
        {
            if ($null -ne $bcsaInstance)
            {
                $PartialContent = "        SPBCSServiceApp " + $bcsaInstance.Name.Replace(" ", "") + "`r`n"
                $PartialContent += "        {`r`n"
                $params.Name = $bcsaInstance.DisplayName
                $results = Get-TargetResource @params

                if ($results.Contains("InstallAccount"))
                {
                    $results.Remove("InstallAccount")
                }
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
            $Global:ErrorLog += "[Business Connectivity Service Application]" + $bcsaInstance.DisplayName + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
