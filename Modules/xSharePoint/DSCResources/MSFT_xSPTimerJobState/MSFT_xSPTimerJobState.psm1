function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $Name,
        [parameter(Mandatory = $false)] [System.String]  $WebApplication,
        [parameter(Mandatory = $false)] [System.Boolean] $Enabled,
        [parameter(Mandatory = $false)] [System.String]  $Schedule,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Getting timer job settings"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
        try {
            $spFarm = Get-SPFarm
        } catch {
            Write-Verbose -Verbose "No local SharePoint farm was detected. Timer job settings will not be applied"
            return $null
        }

        # Get a reference to the timer job
        if ($params.ContainsKey("WebApplication")) {
            $timerjob = Get-SPTimerJob $params.Name -WebApplication $params.WebApplication
        } else {
            $timerjob = Get-SPTimerJob $params.Name
        }

        # Check if timer job if found
        if ($timerjob -eq $null) { return $null }
        
        if ($timerjob.WebApplication -eq $null) {
            # Timer job is not associated to web application
            return @{
                Name = $params.Name
                Enabled = -not $timerjob.IsDisabled
                Schedule = $timerjob.Schedule
                InstallAccount = $params.InstallAccount
            }
        } else {
            # Timer job is associated to web application
            return @{
                Name = $params.Name
                WebApplication = $timerjob.WebApplication.Url
                Enabled = -not $timerjob.IsDisabled
                Schedule = $timerjob.Schedule
                InstallAccount = $params.InstallAccount
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
        [parameter(Mandatory = $true)]  [System.String]  $Name,
        [parameter(Mandatory = $false)] [System.String]  $WebApplication,
        [parameter(Mandatory = $false)] [System.Boolean] $Enabled,
        [parameter(Mandatory = $false)] [System.String]  $Schedule,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Setting timer job settings"

    Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        try {
            $spFarm = Get-SPFarm
        } catch {
            throw "No local SharePoint farm was detected. Timer job settings will not be applied"
            return
        }
        
        Write-Verbose -Message "Start update"

        #find Timer Job
        if ($params.ContainsKey("WebApplication") -eq $true) {
            $job = Get-SPTimerJob $params.Name -WebApplication $params.WebApplication
        } else {
            $job = Get-SPTimerJob $params.Name
        }

        if ($job.GetType().IsArray -eq $false) {
            # Set the timer job settings
            if ($params.ContainsKey("Enabled") -eq $true) { 
                # Enable/Disable timer job
                if ($params.Enabled) {
                    Write-Verbose -Verbose "Enable timer job $($params.Name)"
                    try {
                        Enable-SPTimerJob $job
                    } catch {
                        throw "Error occurred while enabling job. Timer job settings will not be applied. Error details: $($_.Exception.Message)"
                        return
                    }
                } else {
                    Write-Verbose -Verbose "Disable timer job $($params.Name)"
                    try {
                        Disable-SPTimerJob $job
                    } catch {
                        throw "Error occurred while disabling job. Timer job settings will not be applied. Error details: $($_.Exception.Message)"
                        return
                    }
                }
            }

            if ($params.ContainsKey("Schedule") -eq $true) {
                # Set timer job schedule
                Write-Verbose -Verbose "Set timer job $($params.Name) schedule"
                try {
                    Set-SPTimerJob $job -Schedule $params.Schedule -ErrorAction Stop
                } catch {
                    if ($_.Exception.Message -like "*The time given was not given in the proper format*") {
                        throw "Incorrect schedule format used. New schedule will not be applied."
                        return
                    } else {
                        throw "Error occurred. Timer job settings will not be applied. Error details: $($_.Exception.Message)"
                        return
                    }
                }
            }
        } else {
            throw "Could not find specified job. Total jobs found: $($job.Count)"
            return
        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $Name,
        [parameter(Mandatory = $false)] [System.String]  $WebApplication,
        [parameter(Mandatory = $false)] [System.Boolean] $Enabled,
        [parameter(Mandatory = $false)] [System.String]  $Schedule,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Testing timer job settings"
    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($null -eq $CurrentValues) { return $false }

    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters
}

Export-ModuleMember -Function *-TargetResource
