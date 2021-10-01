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
        $Category,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Counter,

        [Parameter()]
        [System.String]
        $CounterInstance = "",

        [Parameter()]
        [System.UInt32[]]
        $HealthScoreBuckets,

        [Parameter()]
        [System.Boolean]
        $IsDescending = $false,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting web application '$WebAppUrl' HTTP Throttling Monitoring settings"

    if ($Ensure -eq 'Present')
    {
        if ($PSBoundParameters.ContainsKey("HealthScoreBuckets") -eq $false)
        {
            Write-Verbose -Message 'NOTE: The HealthScoreBuckets parameter is required when Ensure=Present'
        }
    }

    if ($PSBoundParameters.ContainsKey("HealthScoreBuckets"))
    {
        if ($HealthScoreBuckets[0] -gt $HealthScoreBuckets[1])
        {
            Write-Verbose -Message "Order of HealthScoreBuckets is Descending"
            $bucketsDescending = $true
        }
        else
        {
            Write-Verbose -Message "Order of HealthScoreBuckets is Ascending"
            $bucketsDescending = $false
        }

        if ($bucketsDescending -ne $IsDescending)
        {
            Write-Verbose -Message 'NOTE: The order of HealthScoreBuckets and IsDescending do not match. Make sure they do.'
        }
    }

    $PSBoundParameters.IsDescending = $IsDescending
    $PSBoundParameters.CounterInstance = $CounterInstance

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $nullReturn = @{
            WebAppUrl          = $params.WebAppUrl
            Category           = $params.Category
            Counter            = $params.Counter
            CounterInstance    = $params.CounterInstance
            IsDescending       = $params.IsDescending
            HealthScoreBuckets = $null
            Ensure             = "Absent"
        }

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue
        if ($null -eq $wa)
        {
            return $nullReturn
        }

        [Array]$httpTM = $null
        if ([String]::IsNullOrEmpty($CounterInstance))
        {
            $httpTM = (Get-SPWebApplicationHttpThrottlingMonitor $params.webappUrl) | Where-Object -FilterScript {
                ($_.Category -eq $params.Category) -and `
                ($_.Counter -eq $params.Counter)
            }
        }
        else
        {
            $httpTM = (Get-SPWebApplicationHttpThrottlingMonitor $params.webappUrl) | Where-Object -FilterScript {
                ($_.Category -eq $params.Category) -and `
                ($_.Counter -eq $params.Counter) -and `
                ($_.Instance -eq $params.CounterInstance)
            }
        }

        if ($null -eq $httpTM)
        {
            return $nullReturn
        }

        if ($httpTM.Count -gt 1)
        {
            throw "The specified Category and Counter returned more than one result. Please also specify a CounterInstance."
        }

        $healthScoreBuckets = $httpTM.AssociatedHealthScoreCalculator.GetScoreBuckets()
        if ($healthScoreBuckets[0] -gt $healthScoreBuckets[1])
        {
            $isDescending = $true
        }
        else
        {
            $isDescending = $false
        }

        $result = @{
            WebAppUrl          = $params.WebAppUrl
            Category           = $params.Category
            Counter            = $params.Counter
            CounterInstance    = $params.CounterInstance
            HealthScoreBuckets = $healthScoreBuckets
            IsDescending       = $isDescending
            Ensure             = "Present"
        }

        return $result
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
        $Category,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Counter,

        [Parameter()]
        [System.String]
        $CounterInstance = "",

        [Parameter()]
        [System.UInt32[]]
        $HealthScoreBuckets,

        [Parameter()]
        [System.Boolean]
        $IsDescending = $false,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting web application '$WebAppUrl' HTTP Throttling Monitoring settings"

    if ($Ensure -eq 'Present')
    {
        if ($PSBoundParameters.ContainsKey("HealthScoreBuckets") -eq $false)
        {
            throw 'The HealthScoreBuckets parameter is required when Ensure=Present'
        }
    }

    if ($PSBoundParameters.ContainsKey("HealthScoreBuckets"))
    {
        if ($HealthScoreBuckets[0] -gt $HealthScoreBuckets[1])
        {
            Write-Verbose -Message "Order of HealthScoreBuckets is Descending"
            $bucketsDescending = $true
        }
        else
        {
            Write-Verbose -Message "Order of HealthScoreBuckets is Ascending"
            $bucketsDescending = $false
        }

        if ($bucketsDescending -ne $IsDescending)
        {
            throw 'The order of HealthScoreBuckets and IsDescending do not match. Make sure they do.'
        }
    }

    $PSBoundParameters.IsDescending = $IsDescending
    $PSBoundParameters.CounterInstance = $CounterInstance

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source, $CurrentValues) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]
        $CurrentValues = $args[2]

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue
        if ($null -eq $wa)
        {
            $message = "Web application $($params.WebAppUrl) was not found"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }

        if ($params.Ensure -eq "Present")
        {
            $sortParams = @{
                Descending = $params.IsDescending
            }
            $healthScoreBuckets = $params.HealthScoreBuckets | Sort-Object @sortParams
            if ($CurrentValues.Ensure -eq "Absent")
            {
                Write-Verbose -Message 'Specified monitor does not exist, creating it!'
                $throttle = $wa.HttpThrottleSettings
                $throttle.AddPerformanceMonitor($params.Category, $params.Counter, $params.CounterInstance, $healthScoreBuckets, -not $params.IsDescending)
                $throttle.Update()
            }
            else
            {
                Write-Verbose -Message 'Specified monitor exists, update it!'
                $newParams = @{
                    Identity           = $params.WebAppUrl
                    Category           = $params.Category
                    Counter            = $params.Counter
                    HealthScoreBuckets = $healthScoreBuckets
                    IsDesc             = $params.IsDescending
                }

                if ([String]::IsNullOrEmpty($params.CounterInstance) -eq $false)
                {
                    $newParams.Instance = $params.CounterInstance
                }

                Set-SPWebApplicationHttpThrottlingMonitor @newParams
            }
        }

        if ($params.Ensure -eq "Absent" -and $CurrentValues.Ensure -eq "Present")
        {
            Write-Verbose -Message 'Specified monitor exists, deleting it!'
            $throttle = $wa.HttpThrottleSettings
            if ([String]::IsNullOrEmpty($params.CounterInstance))
            {
                $throttle.RemovePerformanceMonitor($params.Category, $params.Counter)
            }
            else
            {
                $throttle.RemovePerformanceMonitor($params.Category, $params.Counter, $params.CounterInstance)
            }
            $throttle.Update()
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
        $Category,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Counter,

        [Parameter()]
        [System.String]
        $CounterInstance = "",

        [Parameter()]
        [System.UInt32[]]
        $HealthScoreBuckets,

        [Parameter()]
        [System.Boolean]
        $IsDescending = $false,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing web application '$WebAppUrl' HTTP Throttling Monitoring settings"

    $PSBoundParameters.IsDescending = $IsDescending
    $PSBoundParameters.CounterInstance = $CounterInstance

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($Ensure -eq "Present" -and `
            $CurrentValues.Ensure -eq "Present" -and `
            $PSBoundParameters.ContainsKey("HealthScoreBuckets") -and `
            $CurrentValues.ContainsKey("HealthScoreBuckets"))
    {
        if ($null -ne (Compare-Object -ReferenceObject $HealthScoreBuckets -DifferenceObject $CurrentValues.HealthScoreBuckets))
        {
            Write-Verbose "HealthScoreBucket values do not match."
            Write-Verbose -Message "Test-TargetResource returned False"
            return $false
        }
    }

    $valuesToCheck = @(
        "WebAppUrl",
        "Category",
        "Counter",
        "CounterInstance",
        "IsDescending",
        "Ensure"
    )

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck $valuesToCheck

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPWebAppHttpThrottlingMonitor\MSFT_SPWebAppHttpThrottlingMonitor.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module
    $webApps = Get-SPWebApplication
    $i = 1
    $total = $webApps.Length
    foreach ($webApp in $webApps)
    {
        try
        {
            Write-Host "Scanning HTTP Throttling Monitoring for Web App [$i/$total] {$($webApp.Url)}"
            $params.WebAppUrl = $webApp.Url

            $monitors = Get-SPWebApplicationHttpThrottlingMonitor -Identity $webApp.Url
            foreach ($monitor in $monitors)
            {
                $params.Category = $monitor.Category
                $params.Counter = $monitor.Counter
                $params.CounterInstance = $monitor.Instance

                $PartialContent = "        SPWebAppHttpThrottlingMonitor " + [System.Guid]::NewGuid().ToString() + "`r`n"
                $PartialContent += "        {`r`n"

                $results = Get-TargetResource @params

                $results = Repair-Credentials -results $results
                $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
                $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
                $PartialContent += $currentBlock
                $PartialContent += "        }`r`n"
                $Content += $PartialContent
            }
        }
        catch
        {
            $Global:ErrorLog += "[SPWebAppHttpThrottlingMonitor] Couldn't properly retrieve all HTTP Throttling Monitors from Web Application {$($webApp.Url)}`r`n"
        }
        $i++
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
