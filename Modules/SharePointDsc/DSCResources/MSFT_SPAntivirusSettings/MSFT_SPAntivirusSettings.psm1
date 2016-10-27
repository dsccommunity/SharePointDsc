function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)] 
        [System.Boolean] 
        $ScanOnDownload,

        [parameter(Mandatory = $false)] 
        [System.Boolean] 
        $ScanOnUpload,

        [parameter(Mandatory = $false)] 
        [System.Boolean] 
        $AllowDownloadInfected,

        [parameter(Mandatory = $false)] 
        [System.Boolean] 
        $AttemptToClean,

        [parameter(Mandatory = $false)] 
        [System.UInt16] 
        $TimeoutDuration,

        [parameter(Mandatory = $false)] 
        [System.UInt16] 
        $NumberOfThreads,

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Getting antivirus configuration settings"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
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
                # Set the antivirus settings
                AllowDownloadInfected = $false
                ScanOnDownload = $false
                ScanOnUpload = $false
                AttemptToClean = $false
                NumberOfThreads = 0
                TimeoutDuration = 0
                InstallAccount = $params.InstallAccount
            }
        }

        # Get a reference to the Administration WebService
        $admService = Get-SPDSCContentService
        
        return @{
            # Set the antivirus settings
            AllowDownloadInfected = $admService.AntivirusSettings.AllowDownload
            ScanOnDownload = $admService.AntivirusSettings.DownloadScanEnabled
            ScanOnUpload = $admService.AntivirusSettings.UploadScanEnabled
            AttemptToClean = $admService.AntivirusSettings.CleaningEnabled
            NumberOfThreads = $admService.AntivirusSettings.NumberOfThreads
            TimeoutDuration = $admService.AntivirusSettings.Timeout.TotalSeconds
            InstallAccount = $params.InstallAccount
        }
    }
    return $result
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)] 
        [System.Boolean] 
        $ScanOnDownload,

        [parameter(Mandatory = $false)] 
        [System.Boolean] 
        $ScanOnUpload,

        [parameter(Mandatory = $false)] 
        [System.Boolean] 
        $AllowDownloadInfected,

        [parameter(Mandatory = $false)] 
        [System.Boolean] 
        $AttemptToClean,

        [parameter(Mandatory = $false)] 
        [System.UInt16] 
        $TimeoutDuration,

        [parameter(Mandatory = $false)] 
        [System.UInt16] 
        $NumberOfThreads,

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Setting antivirus configuration settings"

    Invoke-SPDSCCommand -Credential $InstallAccount `
                        -Arguments $PSBoundParameters `
                        -ScriptBlock {
        $params = $args[0]

        try 
        {
            $spFarm = Get-SPFarm
        } 
        catch 
        {
            throw "No local SharePoint farm was detected. Antivirus settings will not be applied"
            return
        }
        
        Write-Verbose -Message "Start update"
        $admService = Get-SPDSCContentService

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
        [parameter(Mandatory = $true)] 
        [System.Boolean] 
        $ScanOnDownload,

        [parameter(Mandatory = $false)] 
        [System.Boolean] 
        $ScanOnUpload,

        [parameter(Mandatory = $false)] 
        [System.Boolean] 
        $AllowDownloadInfected,

        [parameter(Mandatory = $false)] 
        [System.Boolean] 
        $AttemptToClean,

        [parameter(Mandatory = $false)] 
        [System.UInt16] 
        $TimeoutDuration,

        [parameter(Mandatory = $false)] 
        [System.UInt16] 
        $NumberOfThreads,

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Testing antivirus configuration settings"
    
    return Test-SPDscParameterState -CurrentValues (Get-TargetResource @PSBoundParameters) `
                                    -DesiredValues $PSBoundParameters
}

Export-ModuleMember -Function *-TargetResource
