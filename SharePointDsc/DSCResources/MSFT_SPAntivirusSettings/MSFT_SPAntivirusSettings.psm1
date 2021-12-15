function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter()]
        [System.Boolean]
        $ScanOnDownload,

        [Parameter()]
        [System.Boolean]
        $ScanOnUpload,

        [Parameter()]
        [System.Boolean]
        $AllowDownloadInfected,

        [Parameter()]
        [System.Boolean]
        $AttemptToClean,

        [Parameter()]
        [System.UInt16]
        $TimeoutDuration,

        [Parameter()]
        [System.UInt16]
        $NumberOfThreads
    )

    Write-Verbose -Message "Getting antivirus configuration settings"

    $result = Invoke-SPDscCommand -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        try
        {
            $spFarm = Get-SPFarm
        }
        catch
        {
            Write-Verbose -Message ("No local SharePoint farm was detected. Antivirus " + `
                    "settings will not be applied")
            return @{
                IsSingleInstance      = "Yes"
                # Set the antivirus settings
                AllowDownloadInfected = $false
                ScanOnDownload        = $false
                ScanOnUpload          = $false
                AttemptToClean        = $false
                NumberOfThreads       = 0
                TimeoutDuration       = 0
            }
        }

        # Get a reference to the Administration WebService
        $admService = Get-SPDscContentService

        return @{
            IsSingleInstance      = "Yes"
            # Set the antivirus settings
            AllowDownloadInfected = $admService.AntivirusSettings.AllowDownload
            ScanOnDownload        = $admService.AntivirusSettings.DownloadScanEnabled
            ScanOnUpload          = $admService.AntivirusSettings.UploadScanEnabled
            AttemptToClean        = $admService.AntivirusSettings.CleaningEnabled
            NumberOfThreads       = $admService.AntivirusSettings.NumberOfThreads
            TimeoutDuration       = $admService.AntivirusSettings.Timeout.TotalSeconds
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
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter()]
        [System.Boolean]
        $ScanOnDownload,

        [Parameter()]
        [System.Boolean]
        $ScanOnUpload,

        [Parameter()]
        [System.Boolean]
        $AllowDownloadInfected,

        [Parameter()]
        [System.Boolean]
        $AttemptToClean,

        [Parameter()]
        [System.UInt16]
        $TimeoutDuration,

        [Parameter()]
        [System.UInt16]
        $NumberOfThreads
    )

    Write-Verbose -Message "Setting antivirus configuration settings"

    Invoke-SPDscCommand -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]

        try
        {
            $spFarm = Get-SPFarm
        }
        catch
        {
            $message = "No local SharePoint farm was detected. Antivirus settings will not be applied"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }

        Write-Verbose -Message "Start update"
        $admService = Get-SPDscContentService

        # Set the antivirus settings
        if ($params.ContainsKey("AllowDownloadInfected"))
        {
            Write-Verbose -Message "Setting Allow Download"
            $admService.AntivirusSettings.AllowDownload = $params.AllowDownloadInfected
        }
        if ($params.ContainsKey("ScanOnDownload"))
        {
            $admService.AntivirusSettings.DownloadScanEnabled = $params.ScanOnDownload
        }
        if ($params.ContainsKey("ScanOnUpload"))
        {
            $admService.AntivirusSettings.UploadScanEnabled = $params.ScanOnUpload
        }
        if ($params.ContainsKey("AttemptToClean"))
        {
            $admService.AntivirusSettings.CleaningEnabled = $params.AttemptToClean
        }
        if ($params.ContainsKey("NumberOfThreads"))
        {
            $admService.AntivirusSettings.NumberOfThreads = $params.NumberOfThreads
        }
        if ($params.ContainsKey("TimeoutDuration"))
        {
            $timespan = New-TimeSpan -Seconds $params.TimeoutDuration
            $admService.AntivirusSettings.Timeout = $timespan
        }
        $admService.Update()
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter()]
        [System.Boolean]
        $ScanOnDownload,

        [Parameter()]
        [System.Boolean]
        $ScanOnUpload,

        [Parameter()]
        [System.Boolean]
        $AllowDownloadInfected,

        [Parameter()]
        [System.Boolean]
        $AttemptToClean,

        [Parameter()]
        [System.UInt16]
        $TimeoutDuration,

        [Parameter()]
        [System.UInt16]
        $NumberOfThreads
    )

    Write-Verbose -Message "Testing antivirus configuration settings"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPAntivirusSettings\MSFT_SPAntivirusSettings.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module
    $PartialContent = "        SPAntivirusSettings AntivirusSettings`r`n"
    $PartialContent += "        {`r`n"
    $results = Get-TargetResource @params
    $results = Repair-Credentials -results $results
    $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
    $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
    $PartialContent += $currentBlock
    $PartialContent += "        }`r`n"
    $Content += $PartialContent
    return $Content
}

Export-ModuleMember -Function *-TargetResource
