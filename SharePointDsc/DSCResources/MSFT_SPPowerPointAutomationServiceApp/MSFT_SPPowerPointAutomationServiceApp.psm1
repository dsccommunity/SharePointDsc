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

        [Parameter()]
        [System.String]
        $ApplicationPool,

        [Parameter()]
        [System.UInt32]
        $CacheExpirationPeriodInSeconds,

        [Parameter()]
        [System.UInt32]
        $MaximumConversionsPerWorker,

        [Parameter()]
        [System.UInt32]
        $WorkerKeepAliveTimeoutInSeconds,

        [Parameter()]
        [System.UInt32]
        $WorkerProcessCount,

        [Parameter()]
        [System.UInt32]
        $WorkerTimeoutInSeconds,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting PowerPoint Automation service app '$Name'"

    if (($ApplicationPool `
                -or $ProxyName `
                -or $CacheExpirationPeriodInSeconds `
                -or $MaximumConversionsPerWorker `
                -or $WorkerKeepAliveTimeoutInSeconds `
                -or $WorkerProcessCount `
                -or $WorkerTimeoutInSeconds) -and ($Ensure -eq "Absent"))
    {
        $message = "You cannot use any of the parameters when Ensure is specified as Absent"
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if (($Ensure -eq "Present") -and -not $ApplicationPool)
    {
        $message = ("An Application Pool is required to configure the PowerPoint " + `
                "Automation Service Application")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]
        $serviceApps = Get-SPServiceApplication | Where-Object -FilterScript {
            $_.Name -eq $params.Name
        }

        $nullReturn = @{
            Name            = $params.Name
            Ensure          = "Absent"
            ApplicationPool = $params.ApplicationPool
        }

        if ($null -eq $serviceApps)
        {
            return $nullReturn
        }

        $serviceApp = $serviceApps | Where-Object -FilterScript {
            $_.GetType().FullName -eq "Microsoft.Office.Server.PowerPoint.Administration.PowerPointConversionServiceApplication"
        }

        if ($null -eq $serviceApp)
        {
            return $nullReturn
        }

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

        $returnVal = @{
            Name                            = $serviceApp.DisplayName
            ProxyName                       = $proxyName
            ApplicationPool                 = $serviceApp.ApplicationPool.Name
            CacheExpirationPeriodInSeconds  = $serviceApp.CacheExpirationPeriodInSeconds
            MaximumConversionsPerWorker     = $serviceApp.MaximumConversionsPerWorker
            WorkerKeepAliveTimeoutInSeconds = $serviceApp.WorkerKeepAliveTimeoutInSeconds
            WorkerProcessCount              = $serviceApp.WorkerProcessCount
            WorkerTimeoutInSeconds          = $serviceApp.WorkerTimeoutInSeconds
            Ensure                          = "Present"

        }
        return $returnVal
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

        [Parameter()]
        [System.String]
        $ApplicationPool,

        [Parameter()]
        [System.UInt32]
        $CacheExpirationPeriodInSeconds,

        [Parameter()]
        [System.UInt32]
        $MaximumConversionsPerWorker,

        [Parameter()]
        [System.UInt32]
        $WorkerKeepAliveTimeoutInSeconds,

        [Parameter()]
        [System.UInt32]
        $WorkerProcessCount,

        [Parameter()]
        [System.UInt32]
        $WorkerTimeoutInSeconds,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting PowerPoint Automation service app '$Name'"

    if (($ApplicationPool `
                -or $ProxyName `
                -or $CacheExpirationPeriodInSeconds `
                -or $MaximumConversionsPerWorker `
                -or $WorkerKeepAliveTimeoutInSeconds `
                -or $WorkerProcessCount `
                -or $WorkerTimeoutInSeconds) -and ($Ensure -eq "Absent"))
    {
        $message = "You cannot use any of the parameters when Ensure is specified as Absent"
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }
    if (($Ensure -eq "Present") -and -not $ApplicationPool)
    {
        $message = ("An Application Pool is required to configure the PowerPoint " + `
                "Automation Service Application")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $result = Get-TargetResource @PSBoundParameters
    if ($result.Ensure -eq "Absent" -and $Ensure -eq "Present")
    {
        Write-Verbose -Message "Creating PowerPoint Automation Service Application $Name"
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
            -ScriptBlock {
            $params = $args[0]
            $eventSource = $args[1]

            $proxyName = $params.ProxyName
            if ($null -eq $proxyName)
            {
                $proxyName = "$($params.Name) Proxy"
            }

            $appPool = Get-SPServiceApplicationPool -Identity $params.ApplicationPool
            if ($appPool)
            {
                $serviceApp = New-SPPowerPointConversionServiceApplication -Name $params.Name -ApplicationPool $params.ApplicationPool
                $null = New-SPPowerPointConversionServiceApplicationProxy -name $proxyName -ServiceApplication $serviceApp

                if ($null -ne $params.CacheExpirationPeriodInSeconds)
                {
                    $serviceApp.CacheExpirationPeriodInSeconds = $params.CacheExpirationPeriodInSeconds
                }
                if ($null -ne $params.MaximumConversionsPerWorker)
                {
                    $serviceApp.MaximumConversionsPerWorker = $params.MaximumConversionsPerWorker
                }
                if ($null -ne $params.WorkerKeepAliveTimeoutInSeconds)
                {
                    $serviceApp.WorkerKeepAliveTimeoutInSeconds = $params.WorkerKeepAliveTimeoutInSeconds
                }
                if ($null -ne $params.WorkerProcessCount)
                {
                    $serviceApp.WorkerProcessCount = $params.WorkerProcessCount
                }
                if ($null -ne $params.WorkerTimeoutInSeconds)
                {
                    $serviceApp.WorkerTimeoutInSeconds = $params.WorkerTimeoutInSeconds
                }
                $serviceApp.Update();
            }
            else
            {
                $message = "Specified application pool does not exist"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
                throw $message
            }
        }
    }
    if ($result.Ensure -eq "Present" -and $Ensure -eq "Present")
    {
        Write-Verbose -Message "Updating PowerPoint Automation Service Application $Name"
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source, $result) `
            -ScriptBlock {
            $params = $args[0]
            $eventSource = $args[1]
            $result = $args[2]

            $serviceApps = Get-SPServiceApplication | Where-Object -FilterScript {
                $_.Name -eq $params.Name
            }

            if ($null -eq $serviceApps)
            {
                $message = "No Service applications are available in the farm."
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
                throw $message
            }
            $serviceApp = $serviceApps `
            | Where-Object -FilterScript {
                $_.GetType().FullName -eq "Microsoft.Office.Server.PowerPoint.Administration.PowerPointConversionServiceApplication"
            }
            if ($null -eq $serviceApp)
            {
                $message = "Unable to find specified service application."
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
                throw $message
            }
            if ([string]::IsNullOrEmpty($params.ApplicationPool) -eq $false `
                    -and $params.ApplicationPool -ne $result.ApplicationPool)
            {
                $appPool = Get-SPServiceApplicationPool -Identity $params.ApplicationPool
                if ($null -eq $appPool)
                {
                    $message = "The specified App Pool does not exist"
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $eventSource
                    throw $message
                }
                $serviceApp.ApplicationPool = $appPool
            }
            if ([string]::IsNullOrEmpty($params.ProxyName) -eq $false `
                    -and $params.ProxyName -ne $result.ProxyName)
            {
                $proxies = Get-SPServiceApplicationProxy
                foreach ($proxyInstance in $proxies)
                {
                    if ($serviceApp.IsConnected($proxyInstance))
                    {
                        $proxyInstance.Delete()
                    }
                }
                $null = New-SPPowerPointConversionServiceApplicationProxy -Name $params.proxyName -ServiceApplication $serviceApp
            }
            if ($null -ne $params.CacheExpirationPeriodInSeconds)
            {
                $serviceApp.CacheExpirationPeriodInSeconds = $params.CacheExpirationPeriodInSeconds
            }
            if ($null -ne $params.MaximumConversionsPerWorker)
            {
                $serviceApp.MaximumConversionsPerWorker = $params.MaximumConversionsPerWorker
            }
            if ($null -ne $params.WorkerKeepAliveTimeoutInSeconds)
            {
                $serviceApp.WorkerKeepAliveTimeoutInSeconds = $params.WorkerKeepAliveTimeoutInSeconds
            }
            if ($null -ne $params.WorkerProcessCount)
            {
                $serviceApp.WorkerProcessCount = $params.WorkerProcessCount
            }
            if ($null -ne $params.WorkerTimeoutInSeconds)
            {
                $serviceApp.WorkerTimeoutInSeconds = $params.WorkerTimeoutInSeconds
            }
            $serviceApp.Update();
        }
    }
    if ($Ensure -eq "Absent")
    {
        Write-Verbose -Message "Removing PowerPoint Automation Service Application $Name"
        Invoke-SPDscCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]

            $serviceApps = Get-SPServiceApplication | Where-Object -FilterScript {
                $_.Name -eq $params.Name
            }
            
            if ($null -eq $serviceApps)
            {
                return;
            }
            $serviceApp = $serviceApps | Where-Object -FilterScript {
                $_.GetType().FullName -eq "Microsoft.Office.Server.PowerPoint.Administration.PowerPointConversionServiceApplication"
            }
            if ($null -ne $serviceApp)
            {
                $proxies = Get-SPServiceApplicationProxy
                foreach ($proxyInstance in $proxies)
                {
                    if ($serviceApp.IsConnected($proxyInstance))
                    {
                        $proxyInstance.Delete()
                    }
                }
                Remove-SPServiceApplication -Identity $serviceApp -Confirm:$false
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

        [Parameter()]
        [System.String]
        $ProxyName,

        [Parameter()]
        [System.String]
        $ApplicationPool,

        [Parameter()]
        [System.UInt32]
        $CacheExpirationPeriodInSeconds,

        [Parameter()]
        [System.UInt32]
        $MaximumConversionsPerWorker,

        [Parameter()]
        [System.UInt32]
        $WorkerKeepAliveTimeoutInSeconds,

        [Parameter()]
        [System.UInt32]
        $WorkerProcessCount,

        [Parameter()]
        [System.UInt32]
        $WorkerTimeoutInSeconds,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing PowerPoint Automation service app '$Name'"
    if (($ApplicationPool -or `
                $ProxyName -or `
                $CacheExpirationPeriodInSeconds -or `
                $MaximumConversionsPerWorker -or `
                $WorkerKeepAliveTimeoutInSeconds -or `
                $WorkerProcessCount -or `
                $WorkerTimeoutInSeconds) -and ($Ensure -eq "Absent"))
    {
        $message = "You cannot use any of the parameters when Ensure is specified as Absent"
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if (($Ensure -eq "Present") -and -not $ApplicationPool)
    {
        $message = ("An Application Pool is required to configure the PowerPoint " + `
                "Automation Service Application")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($Ensure -eq "Absent")
    {
        $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("Ensure")
    }
    else
    {
        $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters
    }

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

Export-ModuleMember -Function *-TargetResource
