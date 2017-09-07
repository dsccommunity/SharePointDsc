function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $TypeName,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $WebApplication,

        [Parameter(Mandatory = $false)]
        [System.Boolean]
        $Enabled,

        [Parameter(Mandatory = $false)]
        [System.String]
        $Schedule,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting timer job settings for job '$Name'"

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
            Write-Verbose -Message ("No local SharePoint farm was detected. Timer job " + `
                                    "settings will not be applied")
            return $null
        }

        $returnval = @{
            TypeName = $params.TypeName
            WebApplication = @()
        }

        if ($params.WebApplication -ne "N/A")
        {
            $enabled = ""
            $schedule = ""
            foreach ($webapp in $params.WebApplication)
            {
                $timerjobs = Get-SPTimerJob -Type $params.TypeName `
                                            -WebApplication $webapp
                
                if ($timerjobs.Count -eq 0)
                {
                    Write-Verbose -Message ("No timer jobs found. Please check the input values")
                    return $null
                }

                $returnval.WebApplication += $webapp
                
                if ($enabled -eq "")
                {
                    $enabled = -not $timerjob.IsDisabled
                }
                else
                {
                    if ($enabled -ne (-not $timerjob.IsDisabled))
                    {
                        $enabled = "multiple"
                    }
                }

                $jobSchedule = $timerjob.Schedule.ToString()
                if ($schedule -eq "")
                {
                    $schedule = $jobSchedule
                }
                else
                {
                    if ($schedule -ne $jobSchedule)
                    {
                        $schedule = "multiple"
                    }
                }

            }

            if ($enabled -eq "multiple")
            {
                $returnval.Enabled = $null
            }
            else
            {
                $returnval.Enabled = $enabled
            }
            
            if ($schedule -eq "multiple")
            {
                $returnval.Schedule = $null
            }
            else
            {
                $returnval.Schedule = $schedule
            }
        } 
        else 
        {
            $timerjob = Get-SPTimerJob -Type $params.TypeName
            if ($timerjob.Count -eq 1)
            {
                $returnval.WebApplication = "N/A"
                $returnval.Enabled        = -not $timerjob.IsDisabled
                $returnval.Schedule       = $null
                if ($null -ne $timerjob.Schedule) 
                {
                    $returnval.Schedule = $timerjob.Schedule.ToString()
                }
            }
            else
            {
                Write-Verbose -Message ("$($timerjob.Count) timer jobs found. Check input " + `
                               "values or use the WebApplication parameter.")
                return $null
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
        [Parameter(Mandatory = $true)]
        [System.String]
        $TypeName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $WebApplication,

        [Parameter(Mandatory = $false)]
        [System.Boolean]
        $Enabled,

        [Parameter(Mandatory = $false)]
        [System.String]
        $Schedule,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting timer job settings for job '$Name'"

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
            throw "No local SharePoint farm was detected. Timer job settings will not be applied"
            return
        }
        
        Write-Verbose -Message "Start update"

        #find Timer Job
        if ($params.ContainsKey("WebApplication") -eq $true) 
        {
            $job = Get-SPTimerJob $params.Name -WebApplication $params.WebApplication
        } 
        else 
        {
            $job = Get-SPTimerJob $params.Name
        }

        if ($job.GetType().IsArray -eq $false) 
        {
            # Set the timer job settings
            if ($params.ContainsKey("Enabled") -eq $true) 
            { 
                # Enable/Disable timer job
                if ($params.Enabled) 
                {
                    Write-Verbose -Message "Enable timer job $($params.Name)"
                    try 
                    {
                        Enable-SPTimerJob $job
                    }
                    catch 
                    {
                        throw ("Error occurred while enabling job. Timer job settings will " + `
                               "not be applied. Error details: $($_.Exception.Message)")
                        return
                    }
                } 
                else 
                {
                    Write-Verbose -Message "Disable timer job $($params.Name)"
                    try 
                    {
                        Disable-SPTimerJob $job
                    } 
                    catch 
                    {
                        throw ("Error occurred while disabling job. Timer job settings will " + `
                               "not be applied. Error details: $($_.Exception.Message)")
                        return
                    }
                }
            }

            if ($params.ContainsKey("Schedule") -eq $true) 
            {
                # Set timer job schedule
                Write-Verbose -Message "Set timer job $($params.Name) schedule"
                try 
                {
                    Set-SPTimerJob $job -Schedule $params.Schedule -ErrorAction Stop
                } 
                catch 
                {
                    if ($_.Exception.Message -like "*The time given was not given in the proper format*") 
                    {
                        throw "Incorrect schedule format used. New schedule will not be applied."
                        return
                    } 
                    else 
                    {
                        throw ("Error occurred. Timer job settings will not be applied. Error " + `
                               "details: $($_.Exception.Message)")
                        return
                    }
                }
            }
        } 
        else 
        {
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
        [Parameter(Mandatory = $true)]
        [System.String]
        $TypeName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $WebApplication,

        [Parameter(Mandatory = $false)]
        [System.Boolean]
        $Enabled,

        [Parameter(Mandatory = $false)]
        [System.String]
        $Schedule,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing timer job settings for job '$Name'"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($null -eq $CurrentValues) 
    { 
        return $false 
    }

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters
}

Export-ModuleMember -Function *-TargetResource
