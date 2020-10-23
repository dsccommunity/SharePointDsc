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
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
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
        [ValidateSet("docx", "doc", "mht", "rtf", "xml")]
        [System.String[]]
        $SupportedFileFormats,

        [Parameter()]
        [System.Boolean]
        $DisableEmbeddedFonts,

        [Parameter()]
        [ValidateRange(10, 100)]
        [System.UInt32]
        $MaximumMemoryUsage,

        [Parameter()]
        [ValidateRange(1, 1000)]
        [System.UInt32]
        $RecycleThreshold,

        [Parameter()]
        [System.Boolean]
        $DisableBinaryFileScan,

        [Parameter()]
        [ValidateRange(1, 1000)]
        [System.UInt32]
        $ConversionProcesses,

        [Parameter()]
        [ValidateRange(1, 59)]
        [System.UInt32]
        $JobConversionFrequency,

        [Parameter()]
        [System.UInt32]
        $NumberOfConversionsPerProcess,

        [Parameter()]
        [ValidateRange(1, 60)]
        [System.UInt32]
        $TimeBeforeConversionIsMonitored,

        [Parameter()]
        [ValidateRange(1, 10)]
        [System.UInt32]
        $MaximumConversionAttempts,

        [Parameter()]
        [ValidateRange(1, 60)]
        [System.UInt32]
        $MaximumSyncConversionRequests,

        [Parameter()]
        [ValidateRange(10, 60)]
        [System.UInt32]
        $KeepAliveTimeout,

        [Parameter()]
        [ValidateRange(60, 3600)]
        [System.UInt32]
        $MaximumConversionTime,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting Word Automation service app '$Name'"

    $PSBoundParameters.Ensure = $Ensure

    if (($ApplicationPool -or `
                $DatabaseName -or `
                $DatabaseServer -or `
                $SupportedFileFormats -or `
                $DisableEmbeddedFonts -or `
                $MaximumMemoryUsage -or `
                $RecycleThreshold -or `
                $DisableBinaryFileScan -or `
                $ConversionProcesses -or `
                $JobConversionFrequency -or `
                $NumberOfConversionsPerProcess -or `
                $TimeBeforeConversionIsMonitored -or `
                $MaximumConversionAttempts -or `
                $MaximumSyncConversionRequests -or `
                $KeepAliveTimeout -or `
                $MaximumConversionTime) -and `
        ($Ensure -eq "Absent"))
    {
        $message = "You cannot use any of the parameters when Ensure is specified as Absent"
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if (($Ensure -eq "Present") -and -not ($ApplicationPool -and $DatabaseName))
    {
        $message = ("An Application Pool and Database Name are required to configure the Word " + `
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

        $serviceApps = Get-SPServiceApplication -Name $params.Name `
            -ErrorAction SilentlyContinue
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
            $_.GetType().FullName -eq "Microsoft.Office.Word.Server.Service.WordServiceApplication"
        }

        if ($null -eq $serviceApp)
        {
            return $nullReturn
        }

        $supportedFileFormats = @()
        if ($serviceApp.WordServiceFormats.OpenXmlDocument)
        {
            $supportedFileFormats += "docx"
        }
        if ($serviceApp.WordServiceFormats.Word972003Document)
        {
            $supportedFileFormats += "doc"
        }
        if ($serviceApp.WordServiceFormats.RichTextFormat)
        {
            $supportedFileFormats += "rtf"
        }
        if ($serviceApp.WordServiceFormats.WebPage)
        {
            $supportedFileFormats += "mht"
        }
        if ($serviceApp.WordServiceFormats.Word2003Xml)
        {
            $supportedFileFormats += "xml"
        }

        $returnVal = @{
            Name                            = $serviceApp.DisplayName
            Ensure                          = "Present"
            ApplicationPool                 = $serviceApp.ApplicationPool.Name
            DatabaseName                    = $serviceApp.Database.Name
            DatabaseServer                  = $serviceApp.Database.NormalizedDataSource
            SupportedFileFormats            = $supportedFileFormats
            DisableEmbeddedFonts            = $serviceApp.DisableEmbeddedFonts
            MaximumMemoryUsage              = $serviceApp.MaximumMemoryUsage
            RecycleThreshold                = $serviceApp.RecycleProcessThreshold
            DisableBinaryFileScan           = $serviceApp.DisableBinaryFileScan
            ConversionProcesses             = $serviceApp.TotalActiveProcesses
            JobConversionFrequency          = $serviceApp.TimerJobFrequency.TotalMinutes
            NumberOfConversionsPerProcess   = $serviceApp.ConversionsPerInstance
            TimeBeforeConversionIsMonitored = $serviceApp.ConversionTimeout.TotalMinutes
            MaximumConversionAttempts       = $serviceApp.MaximumConversionAttempts
            MaximumSyncConversionRequests   = $serviceApp.MaximumSyncConversionRequests
            KeepAliveTimeout                = $serviceApp.KeepAliveTimeout.TotalSeconds
            MaximumConversionTime           = $serviceApp.MaximumConversionTime.TotalSeconds
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
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
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
        [ValidateSet("docx", "doc", "mht", "rtf", "xml")]
        [System.String[]]
        $SupportedFileFormats,

        [Parameter()]
        [System.Boolean]
        $DisableEmbeddedFonts,

        [Parameter()]
        [ValidateRange(10, 100)]
        [System.UInt32]
        $MaximumMemoryUsage,

        [Parameter()]
        [ValidateRange(1, 1000)]
        [System.UInt32]
        $RecycleThreshold,

        [Parameter()]
        [System.Boolean]
        $DisableBinaryFileScan,

        [Parameter()]
        [ValidateRange(1, 1000)]
        [System.UInt32]
        $ConversionProcesses,

        [Parameter()]
        [ValidateRange(1, 59)]
        [System.UInt32]
        $JobConversionFrequency,

        [Parameter()]
        [System.UInt32]
        $NumberOfConversionsPerProcess,

        [Parameter()]
        [ValidateRange(1, 60)]
        [System.UInt32]
        $TimeBeforeConversionIsMonitored,

        [Parameter()]
        [ValidateRange(1, 10)]
        [System.UInt32]
        $MaximumConversionAttempts,

        [Parameter()]
        [ValidateRange(1, 60)]
        [System.UInt32]
        $MaximumSyncConversionRequests,

        [Parameter()]
        [ValidateRange(10, 60)]
        [System.UInt32]
        $KeepAliveTimeout,

        [Parameter()]
        [ValidateRange(60, 3600)]
        [System.UInt32]
        $MaximumConversionTime,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting Word Automation service app '$Name'"

    if (($ApplicationPool -or `
                $DatabaseName -or `
                $DatabaseServer -or `
                $SupportedFileFormats -or `
                $DisableEmbeddedFonts -or `
                $MaximumMemoryUsage -or `
                $RecycleThreshold -or `
                $DisableBinaryFileScan -or `
                $ConversionProcesses -or `
                $JobConversionFrequency -or `
                $NumberOfConversionsPerProcess -or `
                $TimeBeforeConversionIsMonitored -or `
                $MaximumConversionAttempts -or `
                $MaximumSyncConversionRequests -or `
                $KeepAliveTimeout -or `
                $MaximumConversionTime) -and `
        ($Ensure -eq "Absent"))
    {
        $message = "You cannot use any of the parameters when Ensure is specified as Absent"
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $PSBoundParameters.Ensure = $Ensure

    if (($Ensure -eq "Present") -and -not ($ApplicationPool -and $DatabaseName))
    {
        $message = ("An Application Pool and Database Name are required to configure the Word " + `
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
        Write-Verbose -Message "Creating Word Automation Service Application $Name"
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
            -ScriptBlock {
            $params = $args[0]
            $eventSource = $args[1]

            $appPool = Get-SPServiceApplicationPool -Identity $params.ApplicationPool
            if ($appPool)
            {
                $cmdletparams = @{
                    Name            = $params.Name
                    ApplicationPool = $params.ApplicationPool
                }
                if ($params.ContainsKey("DatabaseName"))
                {
                    $cmdletparams.DatabaseName = $params.DatabaseName
                }
                if ($params.ContainsKey("DatabaseServer"))
                {
                    $cmdletparams.DatabaseServer = $params.DatabaseServer
                }

                if ($params.useSQLAuthentication -eq $true)
                {
                    Write-Verbose -Message "Using SQL authentication to create service application as `$useSQLAuthentication is set to $($params.useSQLAuthentication)."
                    $cmdletparams.Add("DatabaseCredentials", $params.DatabaseCredentials)
                }
                else
                {
                    Write-Verbose -Message "`$useSQLAuthentication is false or not specified; using default Windows authentication."
                }

                $null = New-SPWordConversionServiceApplication @cmdletparams
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

        # Retrieving updated current state, so additionally
        # specified parameters are also updated.
        $result = Get-TargetResource @PSBoundParameters
    }

    if ($result.Ensure -eq "Present" -and $Ensure -eq "Present")
    {
        Write-Verbose -Message "Updating Word Automation Service Application $Name"
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
            -ScriptBlock {
            $params = $args[0]
            $eventSource = $args[1]

            $serviceApp = Get-SPServiceApplication -Name $params.Name `
            | Where-Object -FilterScript {
                $_.GetType().FullName -eq "Microsoft.Office.Word.Server.Service.WordServiceApplication"
            }

            # Check if the specified Application Pool is different and change if so
            if ([string]::IsNullOrEmpty($ApplicationPool) -eq $false `
                    -and $ApplicationPool -ne $result.ApplicationPool)
            {
                $appPool = Get-SPServiceApplicationPool -Identity $params.ApplicationPool
                Set-SPWordConversionServiceApplication -Identity $serviceApp -ApplicationPool $appPool
            }
            # Check if the specified Database Name and Server are different and change if so
            if ($params.DatabaseName)
            {
                if ($params.DatabaseServer)
                {
                    if ($serviceApp.Database.NormalizedDataSource -ne $params.DatabaseServer)
                    {
                        Set-SPWordConversionServiceApplication -Identity $serviceApp `
                            -DatabaseServer $params.DatabaseServer `
                            -DatabaseName $params.DatabaseName
                    }
                }
                else
                {
                    if ($serviceApp.Database.Name -ne $params.DatabaseName)
                    {
                        Set-SPWordConversionServiceApplication -Identity $serviceApp `
                            -DatabaseName $params.DatabaseName
                    }
                }
            }

            if ($params.SupportedFileFormats)
            {
                if ($params.SupportedFileFormats.Contains("docx"))
                {
                    $serviceApp.WordServiceFormats.OpenXmlDocument = $true
                }
                else
                {
                    $serviceApp.WordServiceFormats.OpenXmlDocument = $false
                }
                if ($params.SupportedFileFormats.Contains("doc"))
                {
                    $serviceApp.WordServiceFormats.Word972003Document = $true
                }
                else
                {
                    $serviceApp.WordServiceFormats.Word972003Document = $false
                }
                if ($params.SupportedFileFormats.Contains("rtf"))
                {
                    $serviceApp.WordServiceFormats.RichTextFormat = $true
                }
                else
                {
                    $serviceApp.WordServiceFormats.RichTextFormat = $false
                }
                if ($params.SupportedFileFormats.Contains("mht"))
                {
                    $serviceApp.WordServiceFormats.WebPage = $true
                }
                else
                {
                    $serviceApp.WordServiceFormats.WebPage = $false
                }
                if ($params.SupportedFileFormats.Contains("xml"))
                {
                    $serviceApp.WordServiceFormats.Word2003Xml = $true
                }
                else
                {
                    $serviceApp.WordServiceFormats.Word2003Xml = $false
                }
            }

            if ($params.DisableEmbeddedFonts)
            {
                $serviceApp.DisableEmbeddedFonts = $params.DisableEmbeddedFonts
            }
            if ($params.MaximumMemoryUsage)
            {
                $serviceApp.MaximumMemoryUsage = $params.MaximumMemoryUsage
            }
            if ($params.RecycleThreshold)
            {
                $serviceApp.RecycleProcessThreshold = $params.RecycleThreshold
            }
            if ($params.DisableBinaryFileScan)
            {
                $serviceApp.DisableBinaryFileScan = $params.DisableBinaryFileScan
            }
            if ($params.ConversionProcesses)
            {
                $serviceApp.TotalActiveProcesses = $params.ConversionProcesses
            }
            if ($params.JobConversionFrequency)
            {
                # Check for TimerJob and change schedule
                $wordAutomationTimerjob = Get-SPTimerJob $params.Name
                if ($wordAutomationTimerjob.Count -eq 1)
                {
                    $schedule = "every $($params.JobConversionFrequency) minutes between 0 and 0"
                    Set-SPTimerJob $wordAutomationTimerjob -Schedule $schedule
                }
                else
                {
                    $message = "Timerjob could not be found"
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $eventSource
                    throw $message
                }
            }
            if ($params.NumberOfConversionsPerProcess)
            {
                $serviceApp.ConversionsPerInstance = $params.NumberOfConversionsPerProcess
            }
            if ($params.TimeBeforeConversionIsMonitored)
            {
                $timespan = New-TimeSpan -Minutes $params.TimeBeforeConversionIsMonitored
                $serviceApp.ConversionTimeout = $timespan
            }
            if ($params.MaximumConversionAttempts)
            {
                $serviceApp.MaximumConversionAttempts = $params.MaximumConversionAttempts
            }
            if ($params.MaximumSyncConversionRequests)
            {
                $serviceApp.MaximumSyncConversionRequests = $params.MaximumSyncConversionRequests
            }
            if ($params.KeepAliveTimeout)
            {
                $timespan = New-TimeSpan -Seconds $params.KeepAliveTimeout
                $serviceApp.KeepAliveTimeout = $timespan
            }
            if ($params.MaximumConversionTime)
            {
                $timespan = New-TimeSpan -Seconds $params.MaximumConversionTime
                $serviceApp.MaximumConversionTime = $timespan
            }

            $serviceApp.Update()
        }
    }

    if ($Ensure -eq "Absent")
    {
        Write-Verbose -Message "Removing Word Automation Service Application $Name"
        Invoke-SPDscCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]

            $serviceApp = Get-SPServiceApplication -Name $params.Name | Where-Object -FilterScript {
                $_.GetType().FullName -eq "Microsoft.Office.Word.Server.Service.WordServiceApplication"
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

                # Service app existed, deleting
                Remove-SPServiceApplication -Identity $serviceApp -RemoveData -Confirm:$false
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
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
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
        [ValidateSet("docx", "doc", "mht", "rtf", "xml")]
        [System.String[]]
        $SupportedFileFormats,

        [Parameter()]
        [System.Boolean]
        $DisableEmbeddedFonts,

        [Parameter()]
        [ValidateRange(10, 100)]
        [System.UInt32]
        $MaximumMemoryUsage,

        [Parameter()]
        [ValidateRange(1, 1000)]
        [System.UInt32]
        $RecycleThreshold,

        [Parameter()]
        [System.Boolean]
        $DisableBinaryFileScan,

        [Parameter()]
        [ValidateRange(1, 1000)]
        [System.UInt32]
        $ConversionProcesses,

        [Parameter()]
        [ValidateRange(1, 59)]
        [System.UInt32]
        $JobConversionFrequency,

        [Parameter()]
        [System.UInt32]
        $NumberOfConversionsPerProcess,

        [Parameter()]
        [ValidateRange(1, 60)]
        [System.UInt32]
        $TimeBeforeConversionIsMonitored,

        [Parameter()]
        [ValidateRange(1, 10)]
        [System.UInt32]
        $MaximumConversionAttempts,

        [Parameter()]
        [ValidateRange(1, 60)]
        [System.UInt32]
        $MaximumSyncConversionRequests,

        [Parameter()]
        [ValidateRange(10, 60)]
        [System.UInt32]
        $KeepAliveTimeout,

        [Parameter()]
        [ValidateRange(60, 3600)]
        [System.UInt32]
        $MaximumConversionTime,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing Word Automation service app '$Name'"

    $PSBoundParameters.Ensure = $Ensure

    if (($ApplicationPool -or `
                $DatabaseName -or `
                $DatabaseServer -or `
                $SupportedFileFormats -or `
                $DisableEmbeddedFonts -or `
                $MaximumMemoryUsage -or `
                $RecycleThreshold -or `
                $DisableBinaryFileScan -or `
                $ConversionProcesses -or `
                $JobConversionFrequency -or `
                $NumberOfConversionsPerProcess -or `
                $TimeBeforeConversionIsMonitored -or `
                $MaximumConversionAttempts -or `
                $MaximumSyncConversionRequests -or `
                $KeepAliveTimeout -or `
                $MaximumConversionTime) -and `
        ($Ensure -eq "Absent"))
    {
        $message = "You cannot use any of the parameters when Ensure is specified as Absent"
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if (($Ensure -eq "Present") -and -not ($ApplicationPool -and $DatabaseName))
    {
        $message = ("An Application Pool and Database Name are required to configure the Word " + `
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

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

Export-ModuleMember -Function *-TargetResource
