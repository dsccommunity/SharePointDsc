function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)] [System.Boolean] $ScanOnDownload,
        [parameter(Mandatory = $false)] [System.Boolean] $ScanOnUpload,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowDownloadInfected,
        [parameter(Mandatory = $false)] [System.Boolean] $AttemptToClean,
        [parameter(Mandatory = $false)] [System.UInt16] $TimeoutDuration,
        [parameter(Mandatory = $false)] [System.UInt16] $NumberOfThreads,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Getting antivirus configuration settings"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
<<<<<<< HEAD
        [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint") | Out-Null

        # Get a reference to the Administration WebService
        $admService = [Microsoft.SharePoint.Administration.SPWebService]::ContentService

        if ($null -eq $admService) { return $null }
=======
        try {
            $spFarm = Get-SPFarm
        } catch {
            Write-Verbose -Verbose "No local SharePoint farm was detected. Antivirus settings will not be applied"
            return $null
        }

        # Get a reference to the Administration WebService
        $admService = Get-xSharePointContentService
>>>>>>> 5984775ce4f46b599147591dfe21ea0fae930982
        
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
        [parameter(Mandatory = $true)] [System.Boolean] $ScanOnDownload,
        [parameter(Mandatory = $false)] [System.Boolean] $ScanOnUpload,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowDownloadInfected,
        [parameter(Mandatory = $false)] [System.Boolean] $AttemptToClean,
        [parameter(Mandatory = $false)] [System.UInt16] $TimeoutDuration,
        [parameter(Mandatory = $false)] [System.UInt16] $NumberOfThreads,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Setting antivirus configuration settings"

    Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
<<<<<<< HEAD
        
        Write-Verbose -Message "Start update"
        # Load the SharePoint Assembly, using old style for backward compatibility with V1
        [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint") | Out-Null

        # Get a reference to the Administration WebService
        $admService = [Microsoft.SharePoint.Administration.SPWebService]::ContentService
=======

        try {
            $spFarm = Get-SPFarm
        } catch {
            throw "No local SharePoint farm was detected. Antivirus settings will not be applied"
            return
        }
        
        Write-Verbose -Message "Start update"
        $admService = Get-xSharePointContentService
>>>>>>> 5984775ce4f46b599147591dfe21ea0fae930982

        # Set the antivirus settings
        if ($params.ContainsKey("AllowDownloadInfected")) { 
            Write-Verbose -Message "Setting Allow Download"
            $admService.AntivirusSettings.AllowDownload = $params.AllowDownloadInfected
        }
        if ($params.ContainsKey("ScanOnDownload")) { $admService.AntivirusSettings.DownloadScanEnabled = $params.ScanOnDownload }
        if ($params.ContainsKey("ScanOnUpload")) { $admService.AntivirusSettings.UploadScanEnabled = $params.ScanOnUpload }
        if ($params.ContainsKey("AttemptToClean")) { $admService.AntivirusSettings.CleaningEnabled = $params.AttemptToClean }
        if ($params.ContainsKey("NumberOfThreads")) { $admService.AntivirusSettings.NumberOfThreads = $params.NumberOfThreads }
        if ($params.ContainsKey("TimeoutDuration")) { 
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
        [parameter(Mandatory = $true)] [System.Boolean] $ScanOnDownload,
        [parameter(Mandatory = $false)] [System.Boolean] $ScanOnUpload,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowDownloadInfected,
        [parameter(Mandatory = $false)] [System.Boolean] $AttemptToClean,
        [parameter(Mandatory = $false)] [System.UInt16] $TimeoutDuration,
        [parameter(Mandatory = $false)] [System.UInt16] $NumberOfThreads,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Testing antivirus configuration settings"
    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($null -eq $CurrentValues) { return $false }

    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters
}

<<<<<<< HEAD

=======
>>>>>>> 5984775ce4f46b599147591dfe21ea0fae930982
Export-ModuleMember -Function *-TargetResource
