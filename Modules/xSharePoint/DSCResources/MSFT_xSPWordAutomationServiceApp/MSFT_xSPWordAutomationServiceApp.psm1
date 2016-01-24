function Get-TargetResource 
{ 
    [CmdletBinding()] 
    [OutputType([System.Collections.Hashtable])] 
    param 
    ( 
        [parameter(Mandatory = $true)]                                                [System.String]   $Name, 
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")]             [System.String]   $Ensure,
        [parameter(Mandatory = $false)]                                               [System.String]   $ApplicationPool,
        [parameter(Mandatory = $false)]                                               [System.String]   $DatabaseName, 
        [parameter(Mandatory = $false)]                                               [System.String]   $DatabaseServer,
        [parameter(Mandatory = $false)] [ValidateSet("docx","doc","mht","rtf","xml")] [System.String[]] $SupportedFileFormats,
        [parameter(Mandatory = $false)]                                               [System.Boolean]  $DisableEmbeddedFonts,
        [parameter(Mandatory = $false)] [ValidateRange(10,100)]                       [System.UInt32]   $MaximumMemoryUsage,
        [parameter(Mandatory = $false)] [ValidateRange(1,1000)]                       [System.UInt32]   $RecycleThreshold,
        [parameter(Mandatory = $false)]                                               [System.Boolean]  $DisableBinaryFileScan,
        [parameter(Mandatory = $false)] [ValidateRange(1,1000)]                       [System.UInt32]   $ConversionProcesses,
        [parameter(Mandatory = $false)] [ValidateRange(1,59)]                         [System.UInt32]   $JobConversionFrequency,
        [parameter(Mandatory = $false)]                                               [System.UInt32]   $NumberOfConversionsPerProcess,
        [parameter(Mandatory = $false)] [ValidateRange(1,60)]                         [System.UInt32]   $TimeBeforeConversionIsMonitored,
        [parameter(Mandatory = $false)] [ValidateRange(1,10)]                         [System.UInt32]   $MaximumConversionAttempts,
        [parameter(Mandatory = $false)] [ValidateRange(1,60)]                         [System.UInt32]   $MaximumSyncConversionRequests,
        [parameter(Mandatory = $false)] [ValidateRange(10,60)]                        [System.UInt32]   $KeepAliveTimeout,
        [parameter(Mandatory = $false)] [ValidateRange(60,3600)]                      [System.UInt32]   $MaximumConversionTime,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential]                     $InstallAccount 
    ) 

    Write-Verbose -Message "Getting Word Automation service app '$Name'" 

    if (($ApplicationPool -or $DatabaseName -or $DatabaseServer -or $SupportedFileFormats -or $DisableEmbeddedFonts -or $MaximumMemoryUsage -or $RecycleThreshold -or $DisableBinaryFileScan -or $ConversionProcesses -or $JobConversionFrequency -or $NumberOfConversionsPerProcess -or $TimeBeforeConversionIsMonitored -or $MaximumConversionAttempts -or $MaximumSyncConversionRequests -or $KeepAliveTimeout -or $MaximumConversionTime) -and ($Ensure -eq "Absent")) {
        throw "You cannot use any of the parameters when Ensure is specified as Absent"
    }

    if (($Ensure -eq "Present") -and -not ($ApplicationPool -and $DatabaseName)) {
        throw "An Application Pool and Database Name are required to configure the Word Automation Service Application"
    }

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock { 
        $params = $args[0] 
          
        $serviceApp = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue | Where-Object { $_.TypeName -eq "Word Automation Services" }

        switch ($params.Ensure) {
            "Present" {
                If ($null -eq $serviceApp) {  
                    return $null  
                } else { 
                    $supportedFileFormats = @()
                    if ($serviceApp.WordServiceFormats.OpenXmlDocument) { $supportedFileFormats += "docx" }
                    if ($serviceApp.WordServiceFormats.Word972003Document) { $supportedFileFormats += "doc" }
                    if ($serviceApp.WordServiceFormats.RichTextFormat) { $supportedFileFormats += "rtf" }
                    if ($serviceApp.WordServiceFormats.WebPage) { $supportedFileFormats += "mht" }
                    if ($serviceApp.WordServiceFormats.Word2003Xml) { $supportedFileFormats += "xml" }

                    $returnVal =  @{ 
                        Name = $serviceApp.DisplayName 
                        Ensure = $params.Ensure
                        ApplicationPool = $serviceApp.ApplicationPool.Name 
                        DatabaseName = $serviceApp.Database.Name 
                        DatabaseServer = $serviceApp.Database.Server.Name 
                        SupportedFileFormats = $supportedFileFormats
                        DisableEmbeddedFonts = $serviceApp.DisableEmbeddedFonts
                        MaximumMemoryUsage = $serviceApp.MaximumMemoryUsage
                        RecycleThreshold = $serviceApp.RecycleProcessThreshold
                        DisableBinaryFileScan = $serviceApp.DisableBinaryFileScan
                        ConversionProcesses = $serviceApp.TotalActiveProcesses
                        JobConversionFrequency = $serviceApp.TimerJobFrequency.TotalMinutes
                        NumberOfConversionsPerProcess = $serviceApp.ConversionsPerInstance
                        TimeBeforeConversionIsMonitored = $serviceApp.ConversionTimeout.TotalMinutes
                        MaximumConversionAttempts = $serviceApp.MaximumConversionAttempts
                        MaximumSyncConversionRequests = $serviceApp.MaximumSyncConversionRequests
                        KeepAliveTimeout = $serviceApp.KeepAliveTimeout.TotalSeconds
                        MaximumConversionTime = $serviceApp.MaximumConversionTime.TotalSeconds
                        InstallAccount = $params.InstallAccount
                    } 
                    return $returnVal 
                }
            }
            "Absent" {
                If ($null -ne $serviceApp) {  
                    return $null  
                } else { 
                    $returnVal =  @{ 
                        Name = $params.Name 
                        Ensure = $params.Ensure
                        InstallAccount = $params.InstallAccount
                    } 
                    return $returnVal 
                }
            }
        } 
    }
    
    return $result 
} 

function Set-TargetResource 
{ 
    [CmdletBinding()] 
    [OutputType([System.Collections.Hashtable])] 
    param 
    ( 
        [parameter(Mandatory = $true)]                                                [System.String]   $Name, 
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")]             [System.String]   $Ensure,
        [parameter(Mandatory = $false)]                                               [System.String]   $ApplicationPool,
        [parameter(Mandatory = $false)]                                               [System.String]   $DatabaseName, 
        [parameter(Mandatory = $false)]                                               [System.String]   $DatabaseServer,
        [parameter(Mandatory = $false)] [ValidateSet("docx","doc","mht","rtf","xml")] [System.String[]] $SupportedFileFormats,
        [parameter(Mandatory = $false)]                                               [System.Boolean]  $DisableEmbeddedFonts,
        [parameter(Mandatory = $false)] [ValidateRange(10,100)]                       [System.UInt32]   $MaximumMemoryUsage,
        [parameter(Mandatory = $false)] [ValidateRange(1,1000)]                       [System.UInt32]   $RecycleThreshold,
        [parameter(Mandatory = $false)]                                               [System.Boolean]  $DisableBinaryFileScan,
        [parameter(Mandatory = $false)] [ValidateRange(1,1000)]                       [System.UInt32]   $ConversionProcesses,
        [parameter(Mandatory = $false)] [ValidateRange(1,59)]                         [System.UInt32]   $JobConversionFrequency,
        [parameter(Mandatory = $false)]                                               [System.UInt32]   $NumberOfConversionsPerProcess,
        [parameter(Mandatory = $false)] [ValidateRange(1,60)]                         [System.UInt32]   $TimeBeforeConversionIsMonitored,
        [parameter(Mandatory = $false)] [ValidateRange(1,10)]                         [System.UInt32]   $MaximumConversionAttempts,
        [parameter(Mandatory = $false)] [ValidateRange(1,60)]                         [System.UInt32]   $MaximumSyncConversionRequests,
        [parameter(Mandatory = $false)] [ValidateRange(10,60)]                        [System.UInt32]   $KeepAliveTimeout,
        [parameter(Mandatory = $false)] [ValidateRange(60,3600)]                      [System.UInt32]   $MaximumConversionTime,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential]                     $InstallAccount 
    ) 

    if (($ApplicationPool -or $DatabaseName -or $DatabaseServer -or $SupportedFileFormats -or $DisableEmbeddedFonts -or $MaximumMemoryUsage -or $RecycleThreshold -or $DisableBinaryFileScan -or $ConversionProcesses -or $JobConversionFrequency -or $NumberOfConversionsPerProcess -or $TimeBeforeConversionIsMonitored -or $MaximumConversionAttempts -or $MaximumSyncConversionRequests -or $KeepAliveTimeout -or $MaximumConversionTime) -and ($Ensure -eq "Absent")) {
        throw "You cannot use any of the parameters when Ensure is specified as Absent"
    }

    if (($Ensure -eq "Present") -and -not ($ApplicationPool -and $DatabaseName)) {
        throw "An Application Pool and Database Name are required to configure the Word Automation Service Application"
    }

    switch ($Ensure) {
        "Present" {
            Write-Verbose -Message "Creating and/or configuring Word Automation Service Application $Name" 
            Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock { 
                $params = $args[0] 

                $serviceApp = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue | Where-Object { $_.TypeName -eq "Word Automation Services" }
                if ($null -eq $serviceApp) {
                    # Service application does not exist, create it 

                    $appPool = Get-SPServiceApplicationPool -Identity $params.ApplicationPool 
                    if ($appPool) {
                        $cmdletparams = @{}
                        $cmdletparams.Name = $params.Name
                        if ($params.Name) { $cmdletparams.DatabaseName = $params.DatabaseName }
                        if ($params.Name) { $cmdletparams.DatabaseServer = $params.DatabaseServer }
                        if ($params.Name) { $cmdletparams.ApplicationPool = $params.ApplicationPool }

                        $serviceApp = New-SPWordConversionServiceApplication @cmdletparams
                    } else {
                        throw "Specified application pool does not exist"
                    }
                } else {
                    # Service application existed
                    # Check if the specified Application Pool is different and change if so
                    if ($params.ApplicationPool) {
                        if ($serviceApp.ApplicationPool.Name -ne $params.ApplicationPool) { 
                            $appPool = Get-SPServiceApplicationPool -Identity $params.ApplicationPool 
                            if ($appPool) {
                                Set-SPWordConversionServiceApplication $serviceApp -ApplicationPool $appPool
                            } else {
                                throw "Specified application pool does not exist"
                            }
                        }
                    }

                    # Check if the specified Database Name and Server are different and change if so
                    if ($params.DatabaseName) {
                        if ($params.DatabaseServer) {
                            if ($serviceApp.Database.Server.Name -ne $params.DatabaseServer) { Set-SPWordConversionServiceApplication $serviceApp -DatabaseServer $params.DatabaseServer -DatabaseName $params.DatabaseName }
                        } else {
                            if ($serviceApp.Database.Name -ne $params.DatabaseName) { Set-SPWordConversionServiceApplication $serviceApp -DatabaseName $params.DatabaseName }
                        }
                    }
                }

                if ($params.SupportedFileFormats) {
                    if ($params.SupportedFileFormats.Contains("docx")) { $serviceApp.WordServiceFormats.OpenXmlDocument = $true } else  { $serviceApp.WordServiceFormats.OpenXmlDocument = $false }
                    if ($params.SupportedFileFormats.Contains("doc")) { $serviceApp.WordServiceFormats.Word972003Document = $true } else  { $serviceApp.WordServiceFormats.Word972003Document = $false }
                    if ($params.SupportedFileFormats.Contains("rtf")) { $serviceApp.WordServiceFormats.RichTextFormat = $true } else  { $serviceApp.WordServiceFormats.RichTextFormat = $false }
                    if ($params.SupportedFileFormats.Contains("mht")) { $serviceApp.WordServiceFormats.WebPage = $true } else  { $serviceApp.WordServiceFormats.WebPage = $false }
                    if ($params.SupportedFileFormats.Contains("xml")) { $serviceApp.WordServiceFormats.Word2003Xml = $true } else  { $serviceApp.WordServiceFormats.Word2003Xml = $false }
                }

                if ($params.DisableEmbeddedFonts) { $serviceApp.DisableEmbeddedFonts = $params.DisableEmbeddedFonts }
                if ($params.MaximumMemoryUsage) { $serviceApp.MaximumMemoryUsage = $params.MaximumMemoryUsage }
                if ($params.RecycleThreshold) { $serviceApp.RecycleProcessThreshold = $params.RecycleThreshold }
                if ($params.DisableBinaryFileScan) { $serviceApp.DisableBinaryFileScan = $params.DisableBinaryFileScan }
                if ($params.ConversionProcesses) { $serviceApp.TotalActiveProcesses = $params.ConversionProcesses }
                if ($params.JobConversionFrequency) {
                    # Check for TimerJob and change schedule
                    $wordAutomationTimerjob = Get-SPTimerJob $params.Name
                    if ($wordAutomationTimerjob.Count -eq 1) {
                        $schedule = "every $($params.JobConversionFrequency) minutes between 0 and 0"
                        Set-SPTimerJob $wordAutomationTimerjob -Schedule $schedule
                    } else {
                        throw "Timerjob could not be found"
                    }
                }
                if ($params.NumberOfConversionsPerProcess) { $serviceApp.ConversionsPerInstance = $params.NumberOfConversionsPerProcess }
                if ($params.TimeBeforeConversionIsMonitored) {
                    $timespan = New-TimeSpan -Minutes $params.TimeBeforeConversionIsMonitored
                    $serviceApp.ConversionTimeout = $timespan
                }
                if ($params.MaximumConversionAttempts) { $serviceApp.MaximumConversionAttempts = $params.MaximumConversionAttempts }
                if ($params.MaximumSyncConversionRequests) { $serviceApp.MaximumSyncConversionRequests = $params.MaximumSyncConversionRequests }
                if ($params.KeepAliveTimeout) {
                    $timespan = New-TimeSpan -Seconds $params.KeepAliveTimeout
                    $serviceApp.KeepAliveTimeout = $timespan
                }
                if ($params.MaximumConversionTime) {
                    $timespan = New-TimeSpan -Seconds $params.MaximumConversionTime
                    $serviceApp.MaximumConversionTime = $timespan
                }

                $serviceApp.Update()
            } 
        }
        "Absent" {
            Write-Verbose -Message "Removing Word Automation Service Application $Name" 
            Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock { 
                $params = $args[0] 

                $serviceApp = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue | Where-Object { $_.TypeName -eq "Word Automation Services" }
                if ($null -ne $serviceApp) {
                    # Service app existed, deleting
                    Remove-SPServiceApplication $serviceApp -RemoveData -Confirm:$false
                } 
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
        [parameter(Mandatory = $true)]                                                [System.String]   $Name, 
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")]             [System.String]   $Ensure,
        [parameter(Mandatory = $false)]                                               [System.String]   $ApplicationPool,
        [parameter(Mandatory = $false)]                                               [System.String]   $DatabaseName, 
        [parameter(Mandatory = $false)]                                               [System.String]   $DatabaseServer,
        [parameter(Mandatory = $false)] [ValidateSet("docx","doc","mht","rtf","xml")] [System.String[]] $SupportedFileFormats,
        [parameter(Mandatory = $false)]                                               [System.Boolean]  $DisableEmbeddedFonts,
        [parameter(Mandatory = $false)] [ValidateRange(10,100)]                       [System.UInt32]   $MaximumMemoryUsage,
        [parameter(Mandatory = $false)] [ValidateRange(1,1000)]                       [System.UInt32]   $RecycleThreshold,
        [parameter(Mandatory = $false)]                                               [System.Boolean]  $DisableBinaryFileScan,
        [parameter(Mandatory = $false)] [ValidateRange(1,1000)]                       [System.UInt32]   $ConversionProcesses,
        [parameter(Mandatory = $false)] [ValidateRange(1,59)]                         [System.UInt32]   $JobConversionFrequency,
        [parameter(Mandatory = $false)]                                               [System.UInt32]   $NumberOfConversionsPerProcess,
        [parameter(Mandatory = $false)] [ValidateRange(1,60)]                         [System.UInt32]   $TimeBeforeConversionIsMonitored,
        [parameter(Mandatory = $false)] [ValidateRange(1,10)]                         [System.UInt32]   $MaximumConversionAttempts,
        [parameter(Mandatory = $false)] [ValidateRange(1,60)]                         [System.UInt32]   $MaximumSyncConversionRequests,
        [parameter(Mandatory = $false)] [ValidateRange(10,60)]                        [System.UInt32]   $KeepAliveTimeout,
        [parameter(Mandatory = $false)] [ValidateRange(60,3600)]                      [System.UInt32]   $MaximumConversionTime,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential]                     $InstallAccount 
    ) 

    if (($ApplicationPool -or $DatabaseName -or $DatabaseServer -or $SupportedFileFormats -or $DisableEmbeddedFonts -or $MaximumMemoryUsage -or $RecycleThreshold -or $DisableBinaryFileScan -or $ConversionProcesses -or $JobConversionFrequency -or $NumberOfConversionsPerProcess -or $TimeBeforeConversionIsMonitored -or $MaximumConversionAttempts -or $MaximumSyncConversionRequests -or $KeepAliveTimeout -or $MaximumConversionTime) -and ($Ensure -eq "Absent")) {
        throw "You cannot use any of the parameters when Ensure is specified as Absent"
    }

    if (($Ensure -eq "Present") -and -not ($ApplicationPool -and $DatabaseName)) {
        throw "An Application Pool and Database Name are required to configure the Word Automation Service Application"
    }

    Write-Verbose -Message "Testing for Word Automation Service Application '$Name'" 
    $CurrentValues = Get-TargetResource @PSBoundParameters 
     
    if ($null -eq $CurrentValues) { return $false } 
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters
} 

Export-ModuleMember -Function *-TargetResource 
