function Get-TargetResource 
{ 
    [CmdletBinding()] 
    [OutputType([System.Collections.Hashtable])] 
    param 
    ( 
        [parameter(Mandatory = $true)]                                                [System.String]   $Name, 
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")]             [System.String]   $Ensure,
<#        [parameter(Mandatory = $false)]                                               [System.String]   $ApplicationPool,
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
        [parameter(Mandatory = $false)] [ValidateRange(60,4294967295)]                [System.UInt32]   $MaximumConversionTime,#>
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential]                     $InstallAccount 
    ) 

    DynamicParam {
         if ($Ensure -eq "Present") {
            #create a new Application Pool attribute
            $appPoolAttribute = New-Object System.Management.Automation.ParameterAttribute
            $appPoolAttribute.Mandatory = $false
            $appPoolAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $appPoolAttributeCollection.Add($appPoolAttribute)
            $appPoolParam = New-Object System.Management.Automation.RuntimeDefinedParameter('ApplicationPool', [System.String], $appPoolAttributeCollection)

            #create a new DatabaseName attribute
            $dbNameAttribute = New-Object System.Management.Automation.ParameterAttribute
            $dbNameAttribute.Mandatory = $false
            $dbNameAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $dbNameAttributeCollection.Add($dbNameAttribute)
            $dbNameParam = New-Object System.Management.Automation.RuntimeDefinedParameter('DatabaseName', [System.String], $dbNameAttributeCollection)

            #create a new DatabaseName attribute
            $dbServerAttribute = New-Object System.Management.Automation.ParameterAttribute
            $dbServerAttribute.Mandatory = $false
            $dbServerAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $dbServerAttributeCollection.Add($dbServerAttribute)
            $dbServerParam = New-Object System.Management.Automation.RuntimeDefinedParameter('DatabaseServer', [System.String], $dbServerAttributeCollection)

            #create a new SupportedFileFormats attribute
            $suppFileFormatAttribute = New-Object System.Management.Automation.ParameterAttribute
            $suppFileFormatAttribute.Mandatory = $false
            $suppFileFormatAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $suppFileFormatAttributeCollection.Add($suppFileFormatAttribute)
            $suppFileFormatAttributeCollection.Add(((New-Object System.Management.Automation.ValidateSetAttribute(("docx","doc","mht","rtf","xml")))))
            $suppFileFormatParam = New-Object System.Management.Automation.RuntimeDefinedParameter('SupportedFileFormats', [string[]], $suppFileFormatAttributeCollection)
              
            #create a new DisableEmbeddedFonts attribute
            $disEmbFontsAttribute = New-Object System.Management.Automation.ParameterAttribute
            $disEmbFontsAttribute.Mandatory = $false
            $disEmbFontsAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $disEmbFontsAttributeCollection.Add($disEmbFontsAttribute)
            $disEmbFontsParam = New-Object System.Management.Automation.RuntimeDefinedParameter('DisableEmbeddedFonts', [Boolean], $disEmbFontsAttributeCollection)

            #create a new MaximumMemoryUsage attribute
            $maxMemUsageAttribute = New-Object System.Management.Automation.ParameterAttribute
            $maxMemUsageAttribute.Mandatory = $false
            $maxMemUsageAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $maxMemUsageAttributeCollection.Add($maxMemUsageAttribute)
            $maxMemUsageAttributeCollection.Add(((New-Object System.Management.Automation.ValidateRangeAttribute((10,100)))))
            $maxMemUsageParam = New-Object System.Management.Automation.RuntimeDefinedParameter('MaximumMemoryUsage', [Int32], $maxMemUsageAttributeCollection)

            #create a new RecycleThreshold attribute
            $recycleThresholdAttribute = New-Object System.Management.Automation.ParameterAttribute
            $recycleThresholdAttribute.Mandatory = $false
            $recycleThresholdAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $recycleThresholdAttributeCollection.Add($recycleThresholdAttribute)
            $recycleThresholdAttributeCollection.Add(((New-Object System.Management.Automation.ValidateRangeAttribute((1,1000)))))
            $recycleThresholdParam = New-Object System.Management.Automation.RuntimeDefinedParameter('RecycleThreshold', [Int32], $recycleThresholdAttributeCollection)

            #create a new DisableWordDocDocumentScanning attribute
            $disWordScanningAttribute = New-Object System.Management.Automation.ParameterAttribute
            $disWordScanningAttribute.Mandatory = $false
            $disWordScanningAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $disWordScanningAttributeCollection.Add($disWordScanningAttribute)
            $disWordScanningParam = New-Object System.Management.Automation.RuntimeDefinedParameter('DisableWordDocDocumentScanning', [Boolean], $disWordScanningAttributeCollection)

            #create a new ConversionProcesses attribute
            $convProcessesAttribute = New-Object System.Management.Automation.ParameterAttribute
            $convProcessesAttribute.Mandatory = $false
            $convProcessesAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $convProcessesAttributeCollection.Add($convProcessesAttribute)
            $convProcessesAttributeCollection.Add(((New-Object System.Management.Automation.ValidateRangeAttribute((1,1000)))))
            $convProcessesParam = New-Object System.Management.Automation.RuntimeDefinedParameter('ConversionProcesses', [Int32], $convProcessesAttributeCollection)
              
            #create a new JobConversionFrequency attribute
            $jobConvFreqAttribute = New-Object System.Management.Automation.ParameterAttribute
            $jobConvFreqAttribute.Mandatory = $false
            $jobConvFreqAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $jobConvFreqAttributeCollection.Add($jobConvFreqAttribute)
            $jobConvFreqAttributeCollection.Add(((New-Object System.Management.Automation.ValidateRangeAttribute((1,59)))))
            $jobConvFreqParam = New-Object System.Management.Automation.RuntimeDefinedParameter('JobConversionFrequency', [Int32], $jobConvFreqAttributeCollection)
              
            #create a new NumberOfConversionsPerProcess attribute
            $numConvPerProcAttribute = New-Object System.Management.Automation.ParameterAttribute
            $numConvPerProcAttribute.Mandatory = $false
            $numConvPerProcAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $numConvPerProcAttributeCollection.Add($numConvPerProcAttribute)
            $numConvPerProcParam = New-Object System.Management.Automation.RuntimeDefinedParameter('NumberOfConversionsPerProcess', [Int32], $numConvPerProcAttributeCollection)

            #create a new TimeBeforeConversionIsMonitored attribute
            $timeConvMonAttribute = New-Object System.Management.Automation.ParameterAttribute
            $timeConvMonAttribute.Mandatory = $false
            $timeConvMonAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $timeConvMonAttributeCollection.Add($timeConvMonAttribute)
            $timeConvMonAttributeCollection.Add(((New-Object System.Management.Automation.ValidateRangeAttribute((1,60)))))
            $timeConvMonParam = New-Object System.Management.Automation.RuntimeDefinedParameter('TimeBeforeConversionIsMonitored', [Int32], $timeConvMonAttributeCollection)

            #create a new MaximumConversionAttempts attribute
            $maxConvAttemptsAttribute = New-Object System.Management.Automation.ParameterAttribute
            $maxConvAttemptsAttribute.Mandatory = $false
            $maxConvAttemptsAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $maxConvAttemptsAttributeCollection.Add($maxConvAttemptsAttribute)
            $maxConvAttemptsAttributeCollection.Add(((New-Object System.Management.Automation.ValidateRangeAttribute((1,10)))))
            $maxConvAttemptsParam = New-Object System.Management.Automation.RuntimeDefinedParameter('MaximumConversionAttempts', [Int32], $maxConvAttemptsAttributeCollection)

            #create a new MaximumSyncConversionRequests attribute
            $maxSyncConvReqAttribute = New-Object System.Management.Automation.ParameterAttribute
            $maxSyncConvReqAttribute.Mandatory = $false
            $maxSyncConvReqAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $maxSyncConvReqAttributeCollection.Add($maxSyncConvReqAttribute)
            $maxSyncConvReqAttributeCollection.Add(((New-Object System.Management.Automation.ValidateRangeAttribute((1,60)))))
            $maxSyncConvReqParam = New-Object System.Management.Automation.RuntimeDefinedParameter('MaximumSyncConversionRequests', [Int32], $maxSyncConvReqAttributeCollection)

            #create a new KeepAliveTimeout attribute
            $keepAliveAttribute = New-Object System.Management.Automation.ParameterAttribute
            $keepAliveAttribute.Mandatory = $false
            $keepAliveAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $keepAliveAttributeCollection.Add($keepAliveAttribute)
            $keepAliveAttributeCollection.Add(((New-Object System.Management.Automation.ValidateRangeAttribute((1,10)))))
            $keepAliveParam = New-Object System.Management.Automation.RuntimeDefinedParameter('KeepAliveTimeout', [Int32], $keepAliveAttributeCollection)

            #create a new MaximumConversionTime attribute
            $maxConvTimeAttribute = New-Object System.Management.Automation.ParameterAttribute
            $maxConvTimeAttribute.Mandatory = $false
            $maxConvTimeAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $maxConvTimeAttributeCollection.Add($maxConvTimeAttribute)
            $maxConvTimeAttributeCollection.Add(((New-Object System.Management.Automation.ValidateRangeAttribute((1,60)))))
            $maxConvTimeParam = New-Object System.Management.Automation.RuntimeDefinedParameter('MaximumConversionTime', [Int32], $maxConvTimeAttributeCollection)

            #expose the name of our parameter
            $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            $paramDictionary.Add('ApplicationPool', $appPoolParam)
            $paramDictionary.Add('DatabaseName', $dbNameParam)
            $paramDictionary.Add('DatabaseServer', $dbServerParam)
            $paramDictionary.Add('SupportedFileFormats', $suppFileFormatParam)
            $paramDictionary.Add('DisableEmbeddedFonts', $disEmbFontsParam)
            $paramDictionary.Add('MaximumMemoryUsage', $maxMemUsageParam)
            $paramDictionary.Add('RecycleThreshold', $recycleThresholdParam)
            $paramDictionary.Add('DisableWordDocDocumentScanning', $disWordScanningParam)
            $paramDictionary.Add('ConversionProcesses', $convProcessesParam)
            $paramDictionary.Add('JobConversionFrequency', $jobConvFreqParam)
            $paramDictionary.Add('NumberOfConversionsPerProcess', $numConvPerProcParam)
            $paramDictionary.Add('TimeBeforeConversionIsMonitored', $timeConvMonParam)
            $paramDictionary.Add('MaximumConversionAttempts', $maxConvAttemptsParam)
            $paramDictionary.Add('MaximumSyncConversionRequests', $maxSyncConvReqParam)
            $paramDictionary.Add('KeepAliveTimeout', $keepAliveParam)
            $paramDictionary.Add('MaximumConversionTime', $maxConvTimeParam)
            return $paramDictionary
        }
    }
    
    Process { 
        Write-Verbose -Message "Getting Word Automation service app '$Name'" 

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
                            JobConversionFrequency = $serviceApp.TimerJobFrequency
                            NumberOfConversionsPerProcess = $serviceApp.ConversionsPerInstance
                            TimeBeforeConversionIsMonitored = $serviceApp.ConversionTimeout
                            MaximumConversionAttempts = $serviceApp.MaximumConversionAttempts
                            MaximumSyncConversionRequests = $serviceApp.MaximumSyncConversionRequests
                            KeepAliveTimeout = $serviceApp.KeepAliveTimeout
                            MaximumConversionTime = $serviceApp.MaximumConversionTime
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
} 

function Set-TargetResource 
{ 
    [CmdletBinding()] 
    [OutputType([System.Collections.Hashtable])] 
    param 
    ( 
        [parameter(Mandatory = $true)]                                                [System.String]   $Name, 
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")]             [System.String]   $Ensure,
<#        [parameter(Mandatory = $false)]                                               [System.String]   $ApplicationPool,
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
        [parameter(Mandatory = $false)] [ValidateRange(60,4294967295)]                [System.UInt32]   $MaximumConversionTime,#>
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential]                     $InstallAccount 
    ) 

    DynamicParam {
         if ($Ensure -eq "Present") {
            #create a new Application Pool attribute
            $appPoolAttribute = New-Object System.Management.Automation.ParameterAttribute
            $appPoolAttribute.Mandatory = $false
            $appPoolAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $appPoolAttributeCollection.Add($appPoolAttribute)
            $appPoolParam = New-Object System.Management.Automation.RuntimeDefinedParameter('ApplicationPool', [System.String], $appPoolAttributeCollection)

            #create a new DatabaseName attribute
            $dbNameAttribute = New-Object System.Management.Automation.ParameterAttribute
            $dbNameAttribute.Mandatory = $false
            $dbNameAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $dbNameAttributeCollection.Add($dbNameAttribute)
            $dbNameParam = New-Object System.Management.Automation.RuntimeDefinedParameter('DatabaseName', [System.String], $dbNameAttributeCollection)

            #create a new DatabaseName attribute
            $dbServerAttribute = New-Object System.Management.Automation.ParameterAttribute
            $dbServerAttribute.Mandatory = $false
            $dbServerAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $dbServerAttributeCollection.Add($dbServerAttribute)
            $dbServerParam = New-Object System.Management.Automation.RuntimeDefinedParameter('DatabaseServer', [System.String], $dbServerAttributeCollection)

            #create a new SupportedFileFormats attribute
            $suppFileFormatAttribute = New-Object System.Management.Automation.ParameterAttribute
            $suppFileFormatAttribute.Mandatory = $false
            $suppFileFormatAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $suppFileFormatAttributeCollection.Add($suppFileFormatAttribute)
            $suppFileFormatAttributeCollection.Add(((New-Object System.Management.Automation.ValidateSetAttribute(("docx","doc","mht","rtf","xml")))))
            $suppFileFormatParam = New-Object System.Management.Automation.RuntimeDefinedParameter('SupportedFileFormats', [string[]], $suppFileFormatAttributeCollection)
              
            #create a new DisableEmbeddedFonts attribute
            $disEmbFontsAttribute = New-Object System.Management.Automation.ParameterAttribute
            $disEmbFontsAttribute.Mandatory = $false
            $disEmbFontsAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $disEmbFontsAttributeCollection.Add($disEmbFontsAttribute)
            $disEmbFontsParam = New-Object System.Management.Automation.RuntimeDefinedParameter('DisableEmbeddedFonts', [Boolean], $disEmbFontsAttributeCollection)

            #create a new MaximumMemoryUsage attribute
            $maxMemUsageAttribute = New-Object System.Management.Automation.ParameterAttribute
            $maxMemUsageAttribute.Mandatory = $false
            $maxMemUsageAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $maxMemUsageAttributeCollection.Add($maxMemUsageAttribute)
            $maxMemUsageAttributeCollection.Add(((New-Object System.Management.Automation.ValidateRangeAttribute((10,100)))))
            $maxMemUsageParam = New-Object System.Management.Automation.RuntimeDefinedParameter('MaximumMemoryUsage', [Int32], $maxMemUsageAttributeCollection)

            #create a new RecycleThreshold attribute
            $recycleThresholdAttribute = New-Object System.Management.Automation.ParameterAttribute
            $recycleThresholdAttribute.Mandatory = $false
            $recycleThresholdAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $recycleThresholdAttributeCollection.Add($recycleThresholdAttribute)
            $recycleThresholdAttributeCollection.Add(((New-Object System.Management.Automation.ValidateRangeAttribute((1,1000)))))
            $recycleThresholdParam = New-Object System.Management.Automation.RuntimeDefinedParameter('RecycleThreshold', [Int32], $recycleThresholdAttributeCollection)

            #create a new DisableWordDocDocumentScanning attribute
            $disWordScanningAttribute = New-Object System.Management.Automation.ParameterAttribute
            $disWordScanningAttribute.Mandatory = $false
            $disWordScanningAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $disWordScanningAttributeCollection.Add($disWordScanningAttribute)
            $disWordScanningParam = New-Object System.Management.Automation.RuntimeDefinedParameter('DisableWordDocDocumentScanning', [Boolean], $disWordScanningAttributeCollection)

            #create a new ConversionProcesses attribute
            $convProcessesAttribute = New-Object System.Management.Automation.ParameterAttribute
            $convProcessesAttribute.Mandatory = $false
            $convProcessesAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $convProcessesAttributeCollection.Add($convProcessesAttribute)
            $convProcessesAttributeCollection.Add(((New-Object System.Management.Automation.ValidateRangeAttribute((1,1000)))))
            $convProcessesParam = New-Object System.Management.Automation.RuntimeDefinedParameter('ConversionProcesses', [Int32], $convProcessesAttributeCollection)
              
            #create a new JobConversionFrequency attribute
            $jobConvFreqAttribute = New-Object System.Management.Automation.ParameterAttribute
            $jobConvFreqAttribute.Mandatory = $false
            $jobConvFreqAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $jobConvFreqAttributeCollection.Add($jobConvFreqAttribute)
            $jobConvFreqAttributeCollection.Add(((New-Object System.Management.Automation.ValidateRangeAttribute((1,59)))))
            $jobConvFreqParam = New-Object System.Management.Automation.RuntimeDefinedParameter('JobConversionFrequency', [Int32], $jobConvFreqAttributeCollection)
              
            #create a new NumberOfConversionsPerProcess attribute
            $numConvPerProcAttribute = New-Object System.Management.Automation.ParameterAttribute
            $numConvPerProcAttribute.Mandatory = $false
            $numConvPerProcAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $numConvPerProcAttributeCollection.Add($numConvPerProcAttribute)
            $numConvPerProcParam = New-Object System.Management.Automation.RuntimeDefinedParameter('NumberOfConversionsPerProcess', [Int32], $numConvPerProcAttributeCollection)

            #create a new TimeBeforeConversionIsMonitored attribute
            $timeConvMonAttribute = New-Object System.Management.Automation.ParameterAttribute
            $timeConvMonAttribute.Mandatory = $false
            $timeConvMonAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $timeConvMonAttributeCollection.Add($timeConvMonAttribute)
            $timeConvMonAttributeCollection.Add(((New-Object System.Management.Automation.ValidateRangeAttribute((1,60)))))
            $timeConvMonParam = New-Object System.Management.Automation.RuntimeDefinedParameter('TimeBeforeConversionIsMonitored', [Int32], $timeConvMonAttributeCollection)

            #create a new MaximumConversionAttempts attribute
            $maxConvAttemptsAttribute = New-Object System.Management.Automation.ParameterAttribute
            $maxConvAttemptsAttribute.Mandatory = $false
            $maxConvAttemptsAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $maxConvAttemptsAttributeCollection.Add($maxConvAttemptsAttribute)
            $maxConvAttemptsAttributeCollection.Add(((New-Object System.Management.Automation.ValidateRangeAttribute((1,10)))))
            $maxConvAttemptsParam = New-Object System.Management.Automation.RuntimeDefinedParameter('MaximumConversionAttempts', [Int32], $maxConvAttemptsAttributeCollection)

            #create a new MaximumSyncConversionRequests attribute
            $maxSyncConvReqAttribute = New-Object System.Management.Automation.ParameterAttribute
            $maxSyncConvReqAttribute.Mandatory = $false
            $maxSyncConvReqAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $maxSyncConvReqAttributeCollection.Add($maxSyncConvReqAttribute)
            $maxSyncConvReqAttributeCollection.Add(((New-Object System.Management.Automation.ValidateRangeAttribute((1,60)))))
            $maxSyncConvReqParam = New-Object System.Management.Automation.RuntimeDefinedParameter('MaximumSyncConversionRequests', [Int32], $maxSyncConvReqAttributeCollection)

            #create a new KeepAliveTimeout attribute
            $keepAliveAttribute = New-Object System.Management.Automation.ParameterAttribute
            $keepAliveAttribute.Mandatory = $false
            $keepAliveAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $keepAliveAttributeCollection.Add($keepAliveAttribute)
            $keepAliveAttributeCollection.Add(((New-Object System.Management.Automation.ValidateRangeAttribute((1,10)))))
            $keepAliveParam = New-Object System.Management.Automation.RuntimeDefinedParameter('KeepAliveTimeout', [Int32], $keepAliveAttributeCollection)

            #create a new MaximumConversionTime attribute
            $maxConvTimeAttribute = New-Object System.Management.Automation.ParameterAttribute
            $maxConvTimeAttribute.Mandatory = $false
            $maxConvTimeAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $maxConvTimeAttributeCollection.Add($maxConvTimeAttribute)
            $maxConvTimeAttributeCollection.Add(((New-Object System.Management.Automation.ValidateRangeAttribute((1,60)))))
            $maxConvTimeParam = New-Object System.Management.Automation.RuntimeDefinedParameter('MaximumConversionTime', [Int32], $maxConvTimeAttributeCollection)

            #expose the name of our parameter
            $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            $paramDictionary.Add('ApplicationPool', $appPoolParam)
            $paramDictionary.Add('DatabaseName', $dbNameParam)
            $paramDictionary.Add('DatabaseServer', $dbServerParam)
            $paramDictionary.Add('SupportedFileFormats', $suppFileFormatParam)
            $paramDictionary.Add('DisableEmbeddedFonts', $disEmbFontsParam)
            $paramDictionary.Add('MaximumMemoryUsage', $maxMemUsageParam)
            $paramDictionary.Add('RecycleThreshold', $recycleThresholdParam)
            $paramDictionary.Add('DisableWordDocDocumentScanning', $disWordScanningParam)
            $paramDictionary.Add('ConversionProcesses', $convProcessesParam)
            $paramDictionary.Add('JobConversionFrequency', $jobConvFreqParam)
            $paramDictionary.Add('NumberOfConversionsPerProcess', $numConvPerProcParam)
            $paramDictionary.Add('TimeBeforeConversionIsMonitored', $timeConvMonParam)
            $paramDictionary.Add('MaximumConversionAttempts', $maxConvAttemptsParam)
            $paramDictionary.Add('MaximumSyncConversionRequests', $maxSyncConvReqParam)
            $paramDictionary.Add('KeepAliveTimeout', $keepAliveParam)
            $paramDictionary.Add('MaximumConversionTime', $maxConvTimeParam)
            return $paramDictionary
        }
    }

    Process {
        switch ($Ensure) {
            "Present" {
                Write-Verbose -Message "Creating and/or configuring Word Automation Service Application $Name" 
                Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock { 
                    $params = $args[0] 

                    $serviceApp = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue | Where-Object { $_.TypeName -eq "Word Automation Services" }
                    if ($null -eq $serviceApp) {
                        # Service application does not exist, create it 
                        $cmdletparams = @{}
                        $cmdletparams.Name = $params.Name
                        if ($params.Name) { $cmdletparams.DatabaseName = $params.DatabaseName }
                        if ($params.Name) { $cmdletparams.DatabaseServer = $params.DatabaseServer }
                        if ($params.Name) { $cmdletparams.ApplicationPool = $params.ApplicationPool }

                        $serviceApp = New-SPWordConversionServiceApplication @cmdletparams
                    } else {
                        # Service application existed
                        # Check if the specified Application Pool is different and change if so
                        if ($params.ApplicationPool) {
                            if ($serviceApp.ApplicationPool.Name -ne $params.ApplicationPool) { 
                                $appPool = Get-SPServiceApplicationPool -Identity $params.ApplicationPool 
                                Set-SPWordConversionServiceApplication $serviceApp -ApplicationPool $appPool
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
                    if ($params.JobConversionFrequency) { $serviceApp.TimerJobFrequency = $params.JobConversionFrequency }
                    if ($params.NumberOfConversionsPerProcess) { $serviceApp.ConversionsPerInstance = $params.NumberOfConversionsPerProcess }
                    if ($params.TimeBeforeConversionIsMonitored) {$serviceApp.ConversionTimeout = $params.TimeBeforeConversionIsMonitored }
                    if ($params.MaximumConversionAttempts) { $serviceApp.MaximumConversionAttempts = $params.MaximumConversionAttempts }
                    if ($params.MaximumSyncConversionRequests) { $serviceApp.MaximumSyncConversionRequests = $params.MaximumSyncConversionRequests }
                    if ($params.KeepAliveTimeout) { $serviceApp.KeepAliveTimeout = $params.KeepAliveTimeout }
                    if ($params.MaximumConversionTime) { $serviceApp.MaximumConversionTime = $params.MaximumConversionTime }

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
                        Remove-SPServiceApplication $params.Name -RemoveData -Confirm:$false
                    } 
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
<#        [parameter(Mandatory = $false)]                                               [System.String]   $ApplicationPool,
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
        [parameter(Mandatory = $false)] [ValidateRange(60,4294967295)]                [System.UInt32]   $MaximumConversionTime,#>
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential]                     $InstallAccount 
    ) 

        DynamicParam {
         if ($Ensure -eq "Present") {
            #create a new Application Pool attribute
            $appPoolAttribute = New-Object System.Management.Automation.ParameterAttribute
            $appPoolAttribute.Mandatory = $false
            $appPoolAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $appPoolAttributeCollection.Add($appPoolAttribute)
            $appPoolParam = New-Object System.Management.Automation.RuntimeDefinedParameter('ApplicationPool', [System.String], $appPoolAttributeCollection)

            #create a new DatabaseName attribute
            $dbNameAttribute = New-Object System.Management.Automation.ParameterAttribute
            $dbNameAttribute.Mandatory = $false
            $dbNameAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $dbNameAttributeCollection.Add($dbNameAttribute)
            $dbNameParam = New-Object System.Management.Automation.RuntimeDefinedParameter('DatabaseName', [System.String], $dbNameAttributeCollection)

            #create a new DatabaseName attribute
            $dbServerAttribute = New-Object System.Management.Automation.ParameterAttribute
            $dbServerAttribute.Mandatory = $false
            $dbServerAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $dbServerAttributeCollection.Add($dbServerAttribute)
            $dbServerParam = New-Object System.Management.Automation.RuntimeDefinedParameter('DatabaseServer', [System.String], $dbServerAttributeCollection)

            #create a new SupportedFileFormats attribute
            $suppFileFormatAttribute = New-Object System.Management.Automation.ParameterAttribute
            $suppFileFormatAttribute.Mandatory = $false
            $suppFileFormatAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $suppFileFormatAttributeCollection.Add($suppFileFormatAttribute)
            $suppFileFormatAttributeCollection.Add(((New-Object System.Management.Automation.ValidateSetAttribute(("docx","doc","mht","rtf","xml")))))
            $suppFileFormatParam = New-Object System.Management.Automation.RuntimeDefinedParameter('SupportedFileFormats', [string[]], $suppFileFormatAttributeCollection)
              
            #create a new DisableEmbeddedFonts attribute
            $disEmbFontsAttribute = New-Object System.Management.Automation.ParameterAttribute
            $disEmbFontsAttribute.Mandatory = $false
            $disEmbFontsAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $disEmbFontsAttributeCollection.Add($disEmbFontsAttribute)
            $disEmbFontsParam = New-Object System.Management.Automation.RuntimeDefinedParameter('DisableEmbeddedFonts', [Boolean], $disEmbFontsAttributeCollection)

            #create a new MaximumMemoryUsage attribute
            $maxMemUsageAttribute = New-Object System.Management.Automation.ParameterAttribute
            $maxMemUsageAttribute.Mandatory = $false
            $maxMemUsageAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $maxMemUsageAttributeCollection.Add($maxMemUsageAttribute)
            $maxMemUsageAttributeCollection.Add(((New-Object System.Management.Automation.ValidateRangeAttribute((10,100)))))
            $maxMemUsageParam = New-Object System.Management.Automation.RuntimeDefinedParameter('MaximumMemoryUsage', [Int32], $maxMemUsageAttributeCollection)

            #create a new RecycleThreshold attribute
            $recycleThresholdAttribute = New-Object System.Management.Automation.ParameterAttribute
            $recycleThresholdAttribute.Mandatory = $false
            $recycleThresholdAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $recycleThresholdAttributeCollection.Add($recycleThresholdAttribute)
            $recycleThresholdAttributeCollection.Add(((New-Object System.Management.Automation.ValidateRangeAttribute((1,1000)))))
            $recycleThresholdParam = New-Object System.Management.Automation.RuntimeDefinedParameter('RecycleThreshold', [Int32], $recycleThresholdAttributeCollection)

            #create a new DisableWordDocDocumentScanning attribute
            $disWordScanningAttribute = New-Object System.Management.Automation.ParameterAttribute
            $disWordScanningAttribute.Mandatory = $false
            $disWordScanningAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $disWordScanningAttributeCollection.Add($disWordScanningAttribute)
            $disWordScanningParam = New-Object System.Management.Automation.RuntimeDefinedParameter('DisableWordDocDocumentScanning', [Boolean], $disWordScanningAttributeCollection)

            #create a new ConversionProcesses attribute
            $convProcessesAttribute = New-Object System.Management.Automation.ParameterAttribute
            $convProcessesAttribute.Mandatory = $false
            $convProcessesAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $convProcessesAttributeCollection.Add($convProcessesAttribute)
            $convProcessesAttributeCollection.Add(((New-Object System.Management.Automation.ValidateRangeAttribute((1,1000)))))
            $convProcessesParam = New-Object System.Management.Automation.RuntimeDefinedParameter('ConversionProcesses', [Int32], $convProcessesAttributeCollection)
              
            #create a new JobConversionFrequency attribute
            $jobConvFreqAttribute = New-Object System.Management.Automation.ParameterAttribute
            $jobConvFreqAttribute.Mandatory = $false
            $jobConvFreqAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $jobConvFreqAttributeCollection.Add($jobConvFreqAttribute)
            $jobConvFreqAttributeCollection.Add(((New-Object System.Management.Automation.ValidateRangeAttribute((1,59)))))
            $jobConvFreqParam = New-Object System.Management.Automation.RuntimeDefinedParameter('JobConversionFrequency', [Int32], $jobConvFreqAttributeCollection)
              
            #create a new NumberOfConversionsPerProcess attribute
            $numConvPerProcAttribute = New-Object System.Management.Automation.ParameterAttribute
            $numConvPerProcAttribute.Mandatory = $false
            $numConvPerProcAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $numConvPerProcAttributeCollection.Add($numConvPerProcAttribute)
            $numConvPerProcParam = New-Object System.Management.Automation.RuntimeDefinedParameter('NumberOfConversionsPerProcess', [Int32], $numConvPerProcAttributeCollection)

            #create a new TimeBeforeConversionIsMonitored attribute
            $timeConvMonAttribute = New-Object System.Management.Automation.ParameterAttribute
            $timeConvMonAttribute.Mandatory = $false
            $timeConvMonAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $timeConvMonAttributeCollection.Add($timeConvMonAttribute)
            $timeConvMonAttributeCollection.Add(((New-Object System.Management.Automation.ValidateRangeAttribute((1,60)))))
            $timeConvMonParam = New-Object System.Management.Automation.RuntimeDefinedParameter('TimeBeforeConversionIsMonitored', [Int32], $timeConvMonAttributeCollection)

            #create a new MaximumConversionAttempts attribute
            $maxConvAttemptsAttribute = New-Object System.Management.Automation.ParameterAttribute
            $maxConvAttemptsAttribute.Mandatory = $false
            $maxConvAttemptsAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $maxConvAttemptsAttributeCollection.Add($maxConvAttemptsAttribute)
            $maxConvAttemptsAttributeCollection.Add(((New-Object System.Management.Automation.ValidateRangeAttribute((1,10)))))
            $maxConvAttemptsParam = New-Object System.Management.Automation.RuntimeDefinedParameter('MaximumConversionAttempts', [Int32], $maxConvAttemptsAttributeCollection)

            #create a new MaximumSyncConversionRequests attribute
            $maxSyncConvReqAttribute = New-Object System.Management.Automation.ParameterAttribute
            $maxSyncConvReqAttribute.Mandatory = $false
            $maxSyncConvReqAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $maxSyncConvReqAttributeCollection.Add($maxSyncConvReqAttribute)
            $maxSyncConvReqAttributeCollection.Add(((New-Object System.Management.Automation.ValidateRangeAttribute((1,60)))))
            $maxSyncConvReqParam = New-Object System.Management.Automation.RuntimeDefinedParameter('MaximumSyncConversionRequests', [Int32], $maxSyncConvReqAttributeCollection)

            #create a new KeepAliveTimeout attribute
            $keepAliveAttribute = New-Object System.Management.Automation.ParameterAttribute
            $keepAliveAttribute.Mandatory = $false
            $keepAliveAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $keepAliveAttributeCollection.Add($keepAliveAttribute)
            $keepAliveAttributeCollection.Add(((New-Object System.Management.Automation.ValidateRangeAttribute((1,10)))))
            $keepAliveParam = New-Object System.Management.Automation.RuntimeDefinedParameter('KeepAliveTimeout', [Int32], $keepAliveAttributeCollection)

            #create a new MaximumConversionTime attribute
            $maxConvTimeAttribute = New-Object System.Management.Automation.ParameterAttribute
            $maxConvTimeAttribute.Mandatory = $false
            $maxConvTimeAttributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
            $maxConvTimeAttributeCollection.Add($maxConvTimeAttribute)
            $maxConvTimeAttributeCollection.Add(((New-Object System.Management.Automation.ValidateRangeAttribute((1,60)))))
            $maxConvTimeParam = New-Object System.Management.Automation.RuntimeDefinedParameter('MaximumConversionTime', [Int32], $maxConvTimeAttributeCollection)

            #expose the name of our parameter
            $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            $paramDictionary.Add('ApplicationPool', $appPoolParam)
            $paramDictionary.Add('DatabaseName', $dbNameParam)
            $paramDictionary.Add('DatabaseServer', $dbServerParam)
            $paramDictionary.Add('SupportedFileFormats', $suppFileFormatParam)
            $paramDictionary.Add('DisableEmbeddedFonts', $disEmbFontsParam)
            $paramDictionary.Add('MaximumMemoryUsage', $maxMemUsageParam)
            $paramDictionary.Add('RecycleThreshold', $recycleThresholdParam)
            $paramDictionary.Add('DisableWordDocDocumentScanning', $disWordScanningParam)
            $paramDictionary.Add('ConversionProcesses', $convProcessesParam)
            $paramDictionary.Add('JobConversionFrequency', $jobConvFreqParam)
            $paramDictionary.Add('NumberOfConversionsPerProcess', $numConvPerProcParam)
            $paramDictionary.Add('TimeBeforeConversionIsMonitored', $timeConvMonParam)
            $paramDictionary.Add('MaximumConversionAttempts', $maxConvAttemptsParam)
            $paramDictionary.Add('MaximumSyncConversionRequests', $maxSyncConvReqParam)
            $paramDictionary.Add('KeepAliveTimeout', $keepAliveParam)
            $paramDictionary.Add('MaximumConversionTime', $maxConvTimeParam)
            return $paramDictionary
        }
    }

    Process {
        Write-Verbose -Message "Testing for Word Automation Service Application '$Name'" 
        $CurrentValues = Get-TargetResource @PSBoundParameters 
     
        if ($null -eq $CurrentValues) { return $false } 
        return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("ApplicationPool") 
    }
} 

Export-ModuleMember -Function *-TargetResource 
