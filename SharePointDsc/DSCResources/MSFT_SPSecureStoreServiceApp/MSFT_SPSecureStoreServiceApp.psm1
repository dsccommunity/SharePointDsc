$script:resourceModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:resourceModulePath -ChildPath 'Modules'
$script:resourceHelperModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'SharePointDsc.Util'
Import-Module -Name (Join-Path -Path $script:resourceHelperModulePath -ChildPath 'SharePointDsc.Util.psm1')

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
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting secure store service application '$Name'"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $nullReturn = @{
            Name            = $params.Name
            ApplicationPool = $params.ApplicationPool
            AuditingEnabled = $false
            Ensure          = "Absent"
        }

        $serviceApps = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue
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
                InstallAccount         = $params.InstallAccount
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
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting secure store service application '$Name'"

    $result = Get-TargetResource @PSBoundParameters
    $params = $PSBoundParameters

    if ($result.Ensure -eq "Absent" -and $Ensure -eq "Present")
    {
        Write-Verbose -Message "Creating Secure Store Service Application $Name"
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $params `
            -ScriptBlock {
            $params = $args[0]

            if ($params.ContainsKey("Ensure"))
            {
                $params.Remove("Ensure") | Out-Null
            }
            if ($params.ContainsKey("InstallAccount"))
            {
                $params.Remove("InstallAccount") | Out-Null
            }

            if ($params.UseSQLAuthentication -eq $true)
            {
                Write-Verbose -Message "Using SQL authentication to create service application as `$useSQLAuthentication is set to $($params.useSQLAuthentication)."
                $params.Add("DatabaseUsername", $params.DatabaseCredentials.Username)
                $params.Add("DatabasePassword", $params.DatabaseCredentials.Password)
            }
            $params.Remove("UseSQLAuthentication") | Out-Null
            $params.Remove("DatabaseCredentials") | Out-Null

            $pName = "$($params.Name) Proxy"

            if ($params.ContainsKey("ProxyName") -and $null -ne $params.ProxyName)
            {
                $pName = $params.ProxyName
                $params.Remove("ProxyName") | Out-Null
            }

            New-SPSecureStoreServiceApplication @params | New-SPSecureStoreServiceApplicationProxy -Name $pName
        }
    }

    if ($result.Ensure -eq "Present" -and $Ensure -eq "Present")
    {
        # Added check for -notlike with a wildcard as $result.DatabaseServer might not be a FQDN when we are using an Always On AG
        if ($PSBoundParameters.ContainsKey("DatabaseServer") -and `
            ($result.DatabaseServer -ne $DatabaseServer) -and `
            ($DatabaseServer -notlike "$($result.DatabaseServer).*"))
        {
            throw ("Specified database server does not match the actual " + `
                    "database server. This resource cannot move the database " + `
                    "to a different SQL instance.")
        }

        if ($PSBoundParameters.ContainsKey("DatabaseName") -and `
            ($result.DatabaseName -ne $DatabaseName))
        {
            throw ("Specified database name does not match the actual " + `
                    "database name. This resource cannot rename the database.")
        }

        if ([string]::IsNullOrEmpty($ApplicationPool) -eq $false `
                -and $ApplicationPool -ne $result.ApplicationPool)
        {
            Write-Verbose -Message "Updating Secure Store Service Application $Name"
            Invoke-SPDscCommand -Credential $InstallAccount `
                -Arguments $PSBoundParameters `
                -ScriptBlock {
                $params = $args[0]

                $serviceApp = Get-SPServiceApplication -Name $params.Name | Where-Object -FilterScript {
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
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            $serviceApp = Get-SPServiceApplication -Name $params.Name | Where-Object -FilterScript {
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
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
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
        Write-Verbose -Message ("Specified database server does not match the actual " + `
                "database server. This resource cannot move the database " + `
                "to a different SQL instance.")
        return $false
    }

    if ($PSBoundParameters.ContainsKey("DatabaseName") -and `
        ($null -ne $CurrentValues.DatabaseName) -and `
        ($CurrentValues.DatabaseName -ne $DatabaseName))
    {
        Write-Verbose -Message ("Specified database name does not match the actual " + `
                "database name. This resource cannot rename the database.")
        return $false
    }

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("ApplicationPool", "Ensure")
}

Export-ModuleMember -Function *-TargetResource
