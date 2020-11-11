$script:resourceModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:resourceModulePath -ChildPath 'Modules'
$script:resourceHelperModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'SharePointDsc.Util'
Import-Module -Name (Join-Path -Path $script:resourceHelperModulePath -ChildPath 'SharePointDsc.Util.psm1')

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
        [System.String]
        $WebAppUrl,

        [Parameter()]
        [System.Boolean]
        $Enabled,

        [Parameter()]
        [System.String]
        $Schedule,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting timer job settings for job '$TypeName'"

    if ($TypeName -eq "Microsoft.SharePoint.Administration.Health.SPHealthAnalyzerJobDefinition")
    {
        throw ("You cannot use SPTimerJobState to change the schedule of " + `
                "health analyzer timer jobs.")
    }

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        try
        {
            $null = Get-SPFarm
        }
        catch
        {
            throw ("No local SharePoint farm was detected. Timer job " + `
                    "settings will not be applied")
        }

        $returnval = @{
            TypeName = $params.TypeName
        }

        if ($params.WebAppUrl -ne "N/A")
        {
            $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue
            if ($null -eq $wa)
            {
                throw ("Specified web application not found!")
            }

            $timerjob = Get-SPTimerJob -Type $params.TypeName `
                -WebApplication $wa

            if ($timerjob.Count -eq 0)
            {
                throw ("No timer jobs found. Please check the input values")
            }

            $returnval.WebAppUrl = $params.WebAppUrl
            $returnval.Enabled = -not $timerjob.IsDisabled
            $returnval.Schedule = $null
            if ($null -ne $timerjob.Schedule)
            {
                $returnval.Schedule = $timerjob.Schedule.ToString()
            }
        }
        else
        {
            $timerjob = Get-SPTimerJob -Type $params.TypeName
            if ($timerjob.Count -eq 1)
            {
                $returnval.WebAppUrl = "N/A"
                $returnval.Enabled = -not $timerjob.IsDisabled
                $returnval.Schedule = $null
                if ($null -ne $timerjob.Schedule)
                {
                    $returnval.Schedule = $timerjob.Schedule.ToString()
                }
            }
            else
            {
                throw ("$($timerjob.Count) timer jobs found. Check input " + `
                        "values or use the WebAppUrl parameter.")
            }
        }
        return $returnval
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
        $WebAppUrl,

        [Parameter()]
        [System.Boolean]
        $Enabled,

        [Parameter()]
        [System.String]
        $Schedule,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting timer job settings for job '$TypeName'"

    if ($TypeName -eq "Microsoft.SharePoint.Administration.Health.SPHealthAnalyzerJobDefinition")
    {
        throw ("You cannot use SPTimerJobState to change the schedule of " + `
                "health analyzer timer jobs.")
    }

    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        try
        {
            $null = Get-SPFarm
        }
        catch
        {
            throw "No local SharePoint farm was detected. Timer job settings will not be applied"
        }

        Write-Verbose -Message "Start update"

        if ($params.WebAppUrl -ne "N/A")
        {
            $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue
            if ($null -eq $wa)
            {
                throw "Specified web application not found!"
            }

            $timerjob = Get-SPTimerJob -Type $params.TypeName `
                -WebApplication $wa

            if ($timerjob.Count -eq 0)
            {
                throw ("No timer jobs found. Please check the input values")
            }

            if ($params.ContainsKey("Schedule") -eq $true)
            {
                if ($params.Schedule -ne $timerjob.Schedule.ToString())
                {
                    try
                    {
                        Set-SPTimerJob -Identity $timerjob `
                            -Schedule $params.Schedule `
                            -ErrorAction Stop
                    }
                    catch
                    {
                        if ($_.Exception.Message -like `
                                "*The time given was not given in the proper format*")
                        {
                            throw ("Incorrect schedule format used. New schedule will " + `
                                    "not be applied.")
                        }
                        else
                        {
                            throw ("Error occurred. Timer job settings will not be applied. " + `
                                    "Error details: $($_.Exception.Message)")
                        }
                    }
                }
            }

            if ($params.ContainsKey("Enabled") -eq $true)
            {
                if ($params.Enabled -ne (-not $timerjob.IsDisabled))
                {
                    if ($params.Enabled)
                    {
                        Write-Verbose -Message "Enable timer job $($params.TypeName)"
                        try
                        {
                            Enable-SPTimerJob -Identity $timerjob
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
                            Disable-SPTimerJob -Identity $timerjob
                        }
                        catch
                        {
                            throw ("Error occurred while disabling job. Timer job settings will " + `
                                    "not be applied. Error details: $($_.Exception.Message)")
                            return
                        }
                    }
                }
            }
        }
        else
        {
            $timerjob = Get-SPTimerJob -Type $params.TypeName
            if ($timerjob.Count -eq 1)
            {
                if ($params.ContainsKey("Schedule") -eq $true)
                {
                    if ($params.Schedule -ne $timerjob.Schedule.ToString())
                    {
                        try
                        {
                            Set-SPTimerJob -Identity $timerjob `
                                -Schedule $params.Schedule `
                                -ErrorAction Stop
                        }
                        catch
                        {
                            if ($_.Exception.Message -like `
                                    "*The time given was not given in the proper format*")
                            {
                                throw ("Incorrect schedule format used. New schedule will " + `
                                        "not be applied.")
                            }
                            else
                            {
                                throw ("Error occurred. Timer job settings will not be applied. " + `
                                        "Error details: $($_.Exception.Message)")
                            }
                        }
                    }
                }

                if ($params.ContainsKey("Enabled") -eq $true)
                {
                    if ($params.Enabled -ne -not $timerjob.IsDisabled)
                    {
                        if ($params.Enabled)
                        {
                            Write-Verbose -Message "Enable timer job $($params.TypeName)"
                            try
                            {
                                Enable-SPTimerJob -Identity $timerjob
                            }
                            catch
                            {
                                throw ("Error occurred while enabling job. Timer job settings will " + `
                                        "not be applied. Error details: $($_.Exception.Message)")
                            }
                        }
                        else
                        {
                            Write-Verbose -Message "Disable timer job $($params.Name)"
                            try
                            {
                                Disable-SPTimerJob -Identity $timerjob
                            }
                            catch
                            {
                                throw ("Error occurred while disabling job. Timer job settings will " + `
                                        "not be applied. Error details: $($_.Exception.Message)")
                            }
                        }
                    }
                }
            }
            else
            {
                throw ("$($timerjob.Count) timer jobs found. Check input " + `
                        "values or use the WebAppUrl parameter.")
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
        $TypeName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter()]
        [System.Boolean]
        $Enabled,

        [Parameter()]
        [System.String]
        $Schedule,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing timer job settings for job '$TypeName'"

    if ($TypeName -eq "Microsoft.SharePoint.Administration.Health.SPHealthAnalyzerJobDefinition")
    {
        throw ("You cannot use SPTimerJobState to change the schedule of " + `
                "health analyzer timer jobs.")
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


function Export-TargetResource
{
    $ParentModuleBase = Get-Module "SharePointDSC" | Select-Object -ExpandProperty Modulebase
	$module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPTimerJobState\MSFT_SPTimerJobState.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module

    $spTimers = Get-SPTimerJob
    $totalTimers = $spTimers.Length
    $i = 0;
    foreach ($timer in $spTimers)
    {
        try
        {
            $i++
            Write-Host "Scanning Timer Job {"$timer.Name"}[$i/$totalTimers]..."
            if ($null -ne $timer -and $timer.TypeName -ne "Microsoft.SharePoint.Administration.Health.SPHealthAnalyzerJobDefinition")
            {
                $params.TypeName = $timer.TypeName
                if ($null -ne $timer.WebApplication)
                {
                    $params.WebAppUrl = $timer.WebApplication.Url;
                }
                else
                {
                    $params.WebAppUrl = "N/A";
                }

                <# TODO: Remove comment tags when version 2.0.0.0 of SharePointDSC gets released;#>
                $PartialContent += "<#`r`n"
                $PartialContent = "        SPTimerJobState " + [System.Guid]::NewGuid().toString() + "`r`n"
                $PartialContent += "        {`r`n"
                $results = Get-TargetResource @params

                if($results.Contains("InstallAccount"))
                {
                    $results.Remove("InstallAccount")
                }
                $results = Repair-Credentials -results $results
                $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
                $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
                $PartialContent += $currentBlock
                $PartialContent += "        }`r`n"
                $Content += $PartialContent
                $PartialContent += "#>`r`n"
            }
        }
        catch
        {
            $Global:ErrorLog += "[Timer Job]" + $timer.TypeName + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
    }
	Return $Content
}


Export-ModuleMember -Function *-TargetResource

