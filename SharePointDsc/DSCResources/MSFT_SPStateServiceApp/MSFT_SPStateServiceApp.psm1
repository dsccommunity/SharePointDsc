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
        $Name,

        [Parameter()]
        [System.String]
        $ProxyName,

        [Parameter(Mandatory = $true)]
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
        [System.Boolean]
        $UseSQLAuthentication,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting state service application '$Name'"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $serviceApp = Get-SPStateServiceApplication -Identity $params.Name `
            -ErrorAction SilentlyContinue

        if ($null -eq $serviceApp)
        {
            return @{
                Name         = $params.Name
                DatabaseName = $params.DatabaseName
                Ensure       = "Absent"
            }
        }

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
            Name           = $serviceApp.DisplayName
            ProxyName      = $proxyName
            DatabaseName   = $serviceApp.Databases.Name
            DatabaseServer = $serviceApp.Databases.NormalizedDataSource
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
        $Name,

        [Parameter()]
        [System.String]
        $ProxyName,

        [Parameter(Mandatory = $true)]
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
        [System.Boolean]
        $UseSQLAuthentication,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount

    )

    Write-Verbose -Message "Setting state service application '$Name'"

    if ($Ensure -eq "Present")
    {
        Write-Verbose -Message "Creating State Service Application $Name"
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {

            $params = $args[0]

            if ($params.ContainsKey("ProxyName"))
            {
                $pName = $params.ProxyName
            }
            if ($null -eq $pName)
            {
                $pName = "$($params.Name) Proxy"
            }

            $database = Get-SPStateServiceDatabase -Identity $params.DatabaseName
            if ($null -eq $database)
            {
                $dbParams = @{ }

                if ($params.ContainsKey("DatabaseName"))
                {
                    $dbParams.Add("Name", $params.DatabaseName)
                }
                if ($params.ContainsKey("DatabaseServer"))
                {
                    $dbParams.Add("DatabaseServer", $params.DatabaseServer)
                }
                if ($params.ContainsKey("DatabaseCredentials"))
                {
                    $dbParams.Add("DatabaseCredentials", $params.DatabaseCredentials)
                }

                $database = New-SPStateServiceDatabase @dbParams
            }

            $app = New-SPStateServiceApplication -Name $params.Name -Database $database
            $null = New-SPStateServiceApplicationProxy -Name $pName `
                -ServiceApplication $app `
                -DefaultProxyGroup
        }
    }
    if ($Ensure -eq "Absent")
    {
        Write-Verbose -Message "Removing State Service Application $Name"
        Invoke-SPDscCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]

            $serviceApp = Get-SPStateServiceApplication -Name $params.Name

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
        $DatabaseName,

        [Parameter()]
        [System.String]
        $DatabaseServer,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Boolean]
        $UseSQLAuthentication,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing for state service application $Name"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("Name", "Ensure")

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
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
        $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPStateServiceApp\MSFT_SPStateServiceApp.psm1" -Resolve
        $Content = ''
    }

    if ($null -eq $params)
    {
        $params = Get-DSCFakeParameters -ModulePath $module
    }

    $stateApplications = Get-SPStateServiceApplication

    $i = 1
    $total = $stateApplications.Length
    foreach ($stateApp in $stateApplications)
    {
        try
        {
            if ($null -ne $stateApp)
            {
                $serviceName = $stateApp.DisplayName
                Write-Host "Scanning State Service Application [$i/$total] {$serviceName}"

                $params.Name = $serviceName
                $PartialContent = "        SPStateServiceApp " + $serviceName.Replace(" ", "") + "`r`n"
                $PartialContent += "        {`r`n"
                $results = Get-TargetResource @params
                $results.DatabaseServer = "`$ConfigurationData.NonNodeData.DatabaseServer"

                $results = Repair-Credentials -results $results
                $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
                $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
                $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "DatabaseServer"
                $PartialContent += $currentBlock
                $PartialContent += "        }`r`n"
                $Content += $PartialContent
            }
            $i++
        }
        catch
        {
            $Global:ErrorLog += "[State service Application]" + $stateApp.DisplayName + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
