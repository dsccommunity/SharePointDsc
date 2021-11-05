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

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $AuditingEnabled,

        [Parameter()]
        [System.UInt32]
        $AuditlogMaxSize,

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
        [System.String]
        $FailoverDatabaseServer,

        [Parameter()]
        [System.Boolean]
        $PartitionMode,

        [Parameter()]
        [System.Boolean]
        $Sharing,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $MasterKey,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials
    )

    Write-Verbose -Message "Getting secure store service application '$Name'"

    $result = Invoke-SPDscCommand -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $nullReturn = @{
            Name            = $params.Name
            ApplicationPool = $params.ApplicationPool
            AuditingEnabled = $false
            Ensure          = "Absent"
        }

        $serviceApps = Get-SPServiceApplication | Where-Object -FilterScript {
            $_.Name -eq $params.Name
        }

        if ($null -eq $serviceApps)
        {
            return $nullReturn
        }
        $serviceApp = $serviceApps | Where-Object -FilterScript {
            $_.GetType().FullName -eq "Microsoft.Office.SecureStoreService.Server.SecureStoreServiceApplication"
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

            $propertyFlags = [System.Reflection.BindingFlags]::Instance `
                -bor [System.Reflection.BindingFlags]::NonPublic

            $propData = $serviceApp.GetType().GetProperties($propertyFlags)

            $dbProp = $propData | Where-Object -FilterScript {
                $_.Name -eq "Database"
            }

            $db = $dbProp.GetValue($serviceApp)

            $auditProp = $propData | Where-Object -FilterScript {
                $_.Name -eq "AuditEnabled"
            }

            $auditEnabled = $auditProp.GetValue($serviceApp)

            return  @{
                Name                   = $serviceApp.DisplayName
                ProxyName              = $proxyName
                AuditingEnabled        = $auditEnabled
                ApplicationPool        = $serviceApp.ApplicationPool.Name
                DatabaseName           = $db.Name
                DatabaseServer         = $db.NormalizedDataSource
                FailoverDatabaseServer = $db.FailoverServer
                Ensure                 = "Present"
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

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $AuditingEnabled,

        [Parameter()]
        [System.UInt32]
        $AuditlogMaxSize,

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
        [System.String]
        $FailoverDatabaseServer,

        [Parameter()]
        [System.Boolean]
        $PartitionMode,

        [Parameter()]
        [System.Boolean]
        $Sharing,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $MasterKey,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials
    )

    Write-Verbose -Message "Setting secure store service application '$Name'"

    $result = Get-TargetResource @PSBoundParameters
    $params = $PSBoundParameters

    if ($result.Ensure -eq "Absent" -and $Ensure -eq "Present")
    {
        Write-Verbose -Message "Creating Secure Store Service Application $Name"
        Invoke-SPDscCommand -Arguments $params `
            -ScriptBlock {
            $params = $args[0]

            $newParams = @{
                Name            = $params.Name
                ApplicationPool = $params.ApplicationPool
                AuditingEnabled = $params.AuditingEnabled
            }

            if ($params.UseSQLAuthentication -eq $true)
            {
                Write-Verbose -Message "Using SQL authentication to create service application as `$useSQLAuthentication is set to $($params.useSQLAuthentication)."
                $newParams.Add("DatabaseUsername", $params.DatabaseCredentials.Username)
                $newParams.Add("DatabasePassword", $params.DatabaseCredentials.Password)
            }

            $paramList = @('AuditlogMaxSize', 'DatabaseName', 'DatabaseServer', 'FailoverDatabaseServer', 'PartitionMode', 'Sharing')

            foreach ($item in ($params.GetEnumerator() | Where-Object -FilterScript { $_.Key -in $paramList }))
            {
                $newParams.Add($item.Key, $item.Value)
            }

            $pName = "$($params.Name) Proxy"

            if ($params.ContainsKey("ProxyName") -and $null -ne $params.ProxyName)
            {
                $pName = $params.ProxyName
            }

            New-SPSecureStoreServiceApplication @newParams | New-SPSecureStoreServiceApplicationProxy -Name $pName

            if ($params.ContainsKey("MasterKey"))
            {
                $newPassPhrase = $params.MasterKey.GetNetworkCredential().Password
                $proxy = Get-SPServiceApplicationProxy | Where-Object -FilterScript { $_.Name -eq $pName }
                Update-SPSecureStoreMasterKey -ServiceApplicationProxy $proxy -Passphrase $newPassPhrase
            }
        }
    }

    if ($result.Ensure -eq "Present" -and $Ensure -eq "Present")
    {
        # Added check for -notlike with a wildcard as $result.DatabaseServer might not be a FQDN when we are using an Always On AG
        if ($PSBoundParameters.ContainsKey("DatabaseServer") -and `
            ($result.DatabaseServer -ne $DatabaseServer) -and `
            ($DatabaseServer -notlike "$($result.DatabaseServer).*"))
        {
            $message = ("Specified database server does not match the actual " + `
                    "database server. This resource cannot move the database " + `
                    "to a different SQL instance.")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }

        if ($PSBoundParameters.ContainsKey("DatabaseName") -and `
            ($result.DatabaseName -ne $DatabaseName))
        {
            $message = ("Specified database name does not match the actual " + `
                    "database name. This resource cannot rename the database.")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }

        if ([string]::IsNullOrEmpty($ApplicationPool) -eq $false `
                -and $ApplicationPool -ne $result.ApplicationPool)
        {
            Write-Verbose -Message "Updating Secure Store Service Application $Name"
            Invoke-SPDscCommand -Arguments $PSBoundParameters `
                -ScriptBlock {
                $params = $args[0]

                $serviceApp = Get-SPServiceApplication | Where-Object -FilterScript {
                    $_.Name -eq $params.Name -and `
                        $_.GetType().FullName -eq "Microsoft.Office.SecureStoreService.Server.SecureStoreServiceApplication"
                }
                $appPool = Get-SPServiceApplicationPool -Identity $params.ApplicationPool
                Set-SPSecureStoreServiceApplication -Identity $serviceApp -ApplicationPool $appPool
            }
        }
    }

    if ($Ensure -eq "Absent")
    {
        # The service app should not exit
        Write-Verbose -Message "Removing Secure Store Service Application $Name"
        Invoke-SPDscCommand -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            $serviceApp = Get-SPServiceApplication | Where-Object -FilterScript {
                $_.Name -eq $params.Name -and `
                    $_.GetType().FullName -eq "Microsoft.Office.SecureStoreService.Server.SecureStoreServiceApplication"
            }

            # Remove the connected proxy(ies)
            $proxies = Get-SPServiceApplicationProxy
            foreach ($proxyInstance in $proxies)
            {
                if ($serviceApp.IsConnected($proxyInstance))
                {
                    $proxyInstance.Delete()
                }
            }

            Remove-SPServiceApplication $serviceApp -Confirm:$false
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

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $AuditingEnabled,

        [Parameter()]
        [System.UInt32]
        $AuditlogMaxSize,

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
        [System.String]
        $FailoverDatabaseServer,

        [Parameter()]
        [System.Boolean]
        $PartitionMode,

        [Parameter()]
        [System.Boolean]
        $Sharing,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $MasterKey,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials
    )

    Write-Verbose -Message "Testing secure store service application $Name"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    # Added check for -notlike with a wildcard as $CurrentValues.DatabaseServer might not be a FQDN when we are using an Always On AG
    if ($PSBoundParameters.ContainsKey("DatabaseServer") -and `
        ($null -ne $CurrentValues.DatabaseServer) -and `
        ($CurrentValues.DatabaseServer -ne $DatabaseServer) -and `
        ($DatabaseServer -notlike "$($CurrentValues.DatabaseServer).*"))
    {
        $message = ("Specified database server {$DatabaseServer} does not match the actual " + `
                "database server {$($CurrentValues.DatabaseServer)}. This resource " + `
                "cannot move the database to a different SQL instance.")
        Write-Verbose -Message $message
        Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

        Write-Verbose -Message "Test-TargetResource returned false"
        return $false
    }

    if ($PSBoundParameters.ContainsKey("DatabaseName") -and `
        ($null -ne $CurrentValues.DatabaseName) -and `
        ($CurrentValues.DatabaseName -ne $DatabaseName))
    {
        $message = ("Specified database name {$DatabaseName} does not match the " + `
                "actual database name {$($($CurrentValues.DatabaseName))}. This " + `
                "resource cannot rename the database.")
        Write-Verbose -Message $message
        Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

        Write-Verbose -Message "Test-TargetResource returned false"
        return $false
    }

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
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPSecureStoreServiceApp\MSFT_SPSecureStoreServiceApp.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module

    $ssas = Get-SPServiceApplication | Where-Object { $_.GetType().Name -eq "SecureStoreServiceApplication" }

    $i = 1
    $total = $ssas
    foreach ($ssa in $ssas)
    {
        try
        {
            $serviceName = $ssa.DisplayName
            Write-Host "Scanning Secure Store Service Application [$i/$total] {$serviceName}"

            $params.Name = $serviceName
            $PartialContent = "        SPSecureStoreServiceApp " + $ssa.Name.Replace(" ", "") + "`r`n"
            $PartialContent += "        {`r`n"
            $results = Get-TargetResource @params

            $results = Repair-Credentials -results $results

            $foundFailOver = $false
            if ($null -eq $results.FailOverDatabaseServer)
            {
                $results.Remove("FailOverDatabaseServer")
            }
            else
            {
                $foundFailOver = $true
                Add-ConfigurationDataEntry -Node "NonNodeData" -Key "SecureStoreFailOverDatabaseServer" -Value $results.FailOverDatabaseServer -Description "Name of the SQL Server that hosts the FailOver database for your SharePoint Farm's Secure Store Service Application;"
                $results.FailOverDatabaseServer = "`$ConfigurationData.NonNodeData.SecureStoreFailOverDatabaseServer"
            }

            Add-ConfigurationDataEntry -Node "NonNodeData" -Key "DatabaseServer" -Value $results.DatabaseServer -Description "Name of the Database Server associated with the destination SharePoint Farm;"
            $results.DatabaseServer = "`$ConfigurationData.NonNodeData.DatabaseServer"

            $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
            $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "DatabaseServer"
            $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
            if ($foundFailOver)
            {
                $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "FailOverDatabaseServer"
            }
            $PartialContent += $currentBlock
            $PartialContent += "        }`r`n"
            $Content += $PartialContent
            $i++
        }
        catch
        {
            $Global:ErrorLog += "[Secure Store Service Application]" + $ssa.DisplayName + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
