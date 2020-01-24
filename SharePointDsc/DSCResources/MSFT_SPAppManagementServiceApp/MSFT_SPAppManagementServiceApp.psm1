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

        [Parameter()]
        [System.String]
        $DatabaseName,

        [Parameter()]
        [System.String]
        $DatabaseServer,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting App management service app '$Name'"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $serviceApps = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue
        $nullReturn = @{
            Name            = $params.Name
            ApplicationPool = $params.ApplicationPool
            Ensure          = "Absent"
            InstallAccount  = $params.InstallAccount
        }
        if ($null -eq $serviceApps)
        {
            return $nullReturn
        }
        $serviceApp = $serviceApps | Where-Object -FilterScript {
            $_.GetType().FullName -eq "Microsoft.SharePoint.AppManagement.AppManagementServiceApplication"
        }

        if ($null -eq $serviceApp)
        {
            return  $nullReturn
        }
        else
        {
            $proxyName = ""

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

            return  @{
                Name            = $serviceApp.DisplayName
                ProxyName       = $proxyName
                ApplicationPool = $serviceApp.ApplicationPool.Name
                DatabaseName    = $serviceApp.Databases.Name
                DatabaseServer  = $serviceApp.Databases.NormalizedDataSource
                Ensure          = "Present"
                InstallAccount  = $params.InstallAccount
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
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting App management service app '$Name'"

    $result = Get-TargetResource @PSBoundParameters

    if ($result.Ensure -eq "Absent" -and $Ensure -eq "Present")
    {
        # The service app doesn't exist but should

        Write-Verbose -Message "Creating App management Service Application $Name"
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
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

            $appService = New-SPAppManagementServiceApplication @newParams
            if ($null -eq $params.ProxyName)
            {
                $pName = "$($params.Name) Proxy"
            }
            else
            {
                $pName = $params.ProxyName
            }
            New-SPAppManagementServiceApplicationProxy -Name $pName `
                -UseDefaultProxyGroup `
                -ServiceApplication $appService `
                -ErrorAction Stop | Out-Null
        }
    }

    if ($result.Ensure -eq "Present" -and $Ensure -eq "Present")
    {
        Write-Verbose -Message "Updating App management Service Application $Name"

        # Check if the service app has a proxy
        if ($result.ProxyName -eq "")
        {
            Write-Verbose -Message "Proxy not found, creating proxy"
            Invoke-SPDscCommand -Credential $InstallAccount `
                -Arguments $PSBoundParameters `
                -ScriptBlock {
                $params = $args[0]

                $app = Get-SPServiceApplication -Name $params.Name | Where-Object -FilterScript {
                    $_.GetType().FullName -eq "Microsoft.SharePoint.AppManagement.AppManagementServiceApplication"
                }

                if ($null -eq $params.ProxyName)
                {
                    $pName = "$($params.Name) Proxy"
                }
                else
                {
                    $pName = $params.ProxyName
                }
                New-SPAppManagementServiceApplicationProxy -Name $pName `
                    -UseDefaultProxyGroup `
                    -ServiceApplication $app `
                    -ErrorAction Stop | Out-Null
            }
        }

        # Check if the service app has the correct application pool
        if ($ApplicationPool -ne $result.ApplicationPool)
        {
            Write-Verbose -Message "Updating Application Pool"
            Invoke-SPDscCommand -Credential $InstallAccount `
                -Arguments $PSBoundParameters `
                -ScriptBlock {
                $params = $args[0]
                $appPool = Get-SPServiceApplicationPool -Identity $params.ApplicationPool

                $app = Get-SPServiceApplication -Name $params.Name | Where-Object -FilterScript {
                    $_.GetType().FullName -eq "Microsoft.SharePoint.AppManagement.AppManagementServiceApplication"
                }
                $app.ApplicationPool = $appPool
                $app.Update()
            }
        }
    }

    if ($Ensure -eq "Absent")
    {
        # The service app should not exit
        Write-Verbose -Message "Removing App management Service Application $Name"
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            $app = Get-SPServiceApplication -Name $params.Name | Where-Object -FilterScript {
                $_.GetType().FullName -eq "Microsoft.SharePoint.AppManagement.AppManagementServiceApplication"
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
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing App management service app '$Name'"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($CurrentValues.ProxyName -eq "")
    {
        return $false
    }

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("ApplicationPool", `
            "Ensure")
}

Export-ModuleMember -Function *-TargetResource
