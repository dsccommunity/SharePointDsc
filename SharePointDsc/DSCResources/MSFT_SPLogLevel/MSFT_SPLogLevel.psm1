function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $SPLogLevelSetting
    )


    foreach ($DesiredSetting in $SPLogLevelSetting)
    {
        if ((($DesiredSetting.Area) | Measure-Object).Count -ne 1 -or ($DesiredSetting.Area).contains(",") )
        {
            Write-Verbose -Message "Exactly one log area, or the wildcard character '*' must be provided for each log item area"
            return @{
                Name              = $Name
                SPLogLevelSetting = $null
            }
        }

        if ((($DesiredSetting.Name) | Measure-Object).Count -ne 1 -or ($DesiredSetting.Name).contains(",") )
        {
            Write-Verbose -Message "Exactly one log name, or the wildcard character '*' must be provided for each log item name"
            return @{
                Name              = $Name
                SPLogLevelSetting = $null
            }
        }

        if ($null -eq $DesiredSetting.TraceLevel -and $null -eq $DesiredSetting.EventLevel)
        {
            Write-Verbose -Message "TraceLevel and / or EventLevel must be provided for each Area"
            return @{
                Name              = $Name
                SPLogLevelSetting = $null
            }
        }

        if ($null -ne $DesiredSetting.TraceLevel -and @("None", "Unexpected", "Monitorable", "High", "Medium", "Verbose", "VerboseEx", "Default") -notcontains $DesiredSetting.TraceLevel)
        {
            Write-Verbose -Message "TraceLevel $($DesiredSetting.TraceLevel) is not valid, must specify exactly one of None,Unexpected,Monitorable,High,Medium,Verbose,VerboseEx, or Default"
            return @{
                Name              = $Name
                SPLogLevelSetting = $null
            }
        }

        if ($null -ne $DesiredSetting.EventLevel -and @("None", "ErrorCritical", "Error", "Warning", "Information", "Verbose", "Default") -notcontains $DesiredSetting.EventLevel)
        {
            Write-Verbose -Message "EventLevel $($DesiredSetting.EventLevel) is not valid, must specify exactly one of None,ErrorCritical,Error,Warning,Informational,Verbose, or Default"
            return @{
                Name              = $Name
                SPLogLevelSetting = $null
            }
        }
    }

    Write-Verbose -Message "Getting SP Log Level Settings for provided Areas"

    $result = Invoke-SPDscCommand -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $CurrentLogLevelSettings = @()
        foreach ($DesiredSetting in $params.SPLogLevelSetting)
        {
            Write-Verbose -Message "Getting SP Log Level Settings for $($DesiredSetting.Area):$($DesiredSetting.Name)"
            $CurrentLogItemSettings = Get-SPLogLevel -Identity "$($DesiredSetting.Area):$($DesiredSetting.Name)"

            #Validate valid log area/name specified.
            if ($null -eq $CurrentLogItemSettings)
            {
                Write-Verbose -Message "Invalid SP Log Area/Name $($DesiredSetting.Area):$($DesiredSetting.Name)"
                return $null
            }

            foreach ($currentItem in $CurrentLogItemSettings)
            {
                #TraceLevels
                #if we desire defaults, we will check for default for each item and return as such
                if ($DesiredSetting.TraceLevel -eq "Default")
                {
                    if ($currentItem.TraceSeverity -eq $currentItem.DefaultTraceSeverity)
                    {
                        $Tracelevel = 'Default'
                    }
                    else
                    {
                        #return a csv list of current unique trace level settings for the provided Area/Name
                        $Tracelevel = $currentItem.TraceSeverity
                    }
                }
                #default was not specified, so we return the unique current trace severity across all provided settings.
                else
                {
                    $Tracelevel = $currentItem.TraceSeverity
                }

                #EventLevels
                #if we desire defaults, we will check for default and return as such
                if ($DesiredSetting.EventLevel -eq "Default")
                {
                    if ($currentItem.EventSeverity -eq $currentItem.DefaultEventSeverity)
                    {
                        $Eventlevel = 'Default'
                    }
                    else
                    {
                        #return a csv list of current unique Event level settings for the provided Area/Name
                        $Eventlevel = $currentItem.Eventseverity
                    }
                }
                #default was not specified, so we return the unique current Event severity across all provided settings.
                else
                {
                    $Eventlevel = $currentItem.Eventseverity
                }

                $CurrentLogLevelSettings += New-Object -TypeName PSObject -Property @{
                    Area       = $currentItem.Area
                    Name       = $currentItem.Name
                    TraceLevel = $TraceLevel
                    EventLevel = $EventLevel
                }
            }
        }

        return @{
            Name              = $params.Name
            SPLogLevelSetting = $CurrentLogLevelSettings
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
        $Name,

        [Parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $SPLogLevelSetting
    )

    foreach ($DesiredSetting in $SPLogLevelSetting)
    {
        if ((($DesiredSetting.Area) | Measure-Object).Count -ne 1 -or ($DesiredSetting.Area).contains(",") )
        {
            $message = "Exactly one log area, or the wildcard character '*' must be provided for each log item"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }

        if ((($DesiredSetting.Name) | Measure-Object).Count -ne 1 -or ($DesiredSetting.Name).contains(",") )
        {
            $message = "Exactly one log name, or the wildcard character '*' must be provided for each log item"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }

        if ($null -eq $DesiredSetting.TraceLevel -and $null -eq $DesiredSetting.EventLevel)
        {
            $message = "TraceLevel and / or EventLevel must be provided for each Area"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }

        if ($null -ne $DesiredSetting.TraceLevel -and @("None", "Unexpected", "Monitorable", "High", "Medium", "Verbose", "VerboseEx", "Default") -notcontains $DesiredSetting.TraceLevel)
        {
            $message = "TraceLevel $($DesiredSetting.TraceLevel) is not valid, must specify exactly one of None,Unexpected,Monitorable,High,Medium,Verbose,VerboseEx, or Default"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }

        if ($null -ne $DesiredSetting.EventLevel -and @("None", "ErrorCritical", "Error", "Warning", "Information", "Verbose", "Default") -notcontains $DesiredSetting.EventLevel)
        {
            $message = "EventLevel $($DesiredSetting.EventLevel) is not valid, must specify exactly one of None,ErrorCritical,Error,Warning,Information,Verbose, or Default"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }
    }

    Write-Verbose -Message "Setting SP Log Level settings for the provided areas"

    Invoke-SPDscCommand -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]

        foreach ($DesiredSetting in $params.SPLogLevelSetting)
        {
            Write-Verbose -Message "Setting SP Log Level Settings for $($DesiredSetting.Area):$($DesiredSetting.Name)"

            $AllSettings = Get-SPLogLevel -Identity "$($DesiredSetting.Area):$($DesiredSetting.Name)"

            #Validate valid log area/name specified.
            if ($null -eq $AllSettings)
            {
                $message = "Invalid SP Log Area/Name $($DesiredSetting.Area):$($DesiredSetting.Name)"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
                throw $message
            }

            if ($null -ne $DesiredSetting.TraceLevel)
            {
                if ($DesiredSetting.TraceLevel -eq 'Default')
                {
                    #default settings can vary, so we must loop through each one.
                    foreach ($setting in $AllSettings)
                    {
                        Set-SPLogLevel -Identity "$($setting.Area):$($setting.Name)" -TraceSeverity $setting.DefaultTraceSeverity
                    }
                }
                else
                {
                    Set-SPLogLevel -Identity "$($DesiredSetting.Area):$($DesiredSetting.Name)" -TraceSeverity $DesiredSetting.TraceLevel
                }
            }

            if ($null -ne $DesiredSetting.EventLevel)
            {
                if ($DesiredSetting.EventLevel -eq 'Default')
                {
                    #default settings can vary, so we must loop through each one.
                    foreach ($setting in $AllSettings)
                    {
                        Set-SPLogLevel -Identity "$($setting.Area):$($setting.Name)" -EventSeverity $setting.DefaultEventSeverity
                    }
                }
                else
                {
                    Set-SPLogLevel -Identity "$($DesiredSetting.Area):$($DesiredSetting.Name)" -EventSeverity $DesiredSetting.EventLevel
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
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $SPLogLevelSetting
    )

    Write-Verbose -Message "Testing SP Log Level settings for the provided areas"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($null -eq $CurrentValues.SPLogLevelSetting)
    {
        $message = "Error retrieving SPLogLevelSetting for $Name"
        Write-Verbose -Message $message
        Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

        Write-Verbose -Message "Test-TargetResource returned false"
        return $false
    }

    $mismatchedSettingFound = $false
    $mismatchedSettings = @()

    foreach ($DesiredSetting in $SPLogLevelSetting)
    {
        Write-Verbose -Message "Testing SP Log Level setting for $($DesiredSetting.Area):$($DesiredSetting.Name)"

        if ($DesiredSetting.Area -eq "*")
        {
            if ($DesiredSetting.Name -eq "*")
            {
                $CurrentSettings = $CurrentValues.SPLogLevelSetting
            }
            else
            {
                $CurrentSettings = $CurrentValues.SPLogLevelSetting | Where-Object -FilterScript { $_.Name -eq $DesiredSetting.Name }
            }
        }
        else
        {
            if ($DesiredSetting.Name -eq "*")
            {
                $CurrentSettings = $CurrentValues.SPLogLevelSetting | Where-Object -FilterScript { $_.Area -eq $DesiredSetting.Area }
            }
            else
            {
                $CurrentSettings = $CurrentValues.SPLogLevelSetting | Where-Object -FilterScript { $_.Area -eq $DesiredSetting.Area -and $_.Name -eq $DesiredSetting.Name }
            }
        }

        foreach ($currentSetting in $CurrentSettings)
        {
            if (($null -ne $DesiredSetting.TraceLevel -and $currentSetting.TraceLevel -ne $DesiredSetting.TraceLevel) -or ($null -ne $DesiredSetting.EventLevel -and $currentSetting.EventLevel -ne $DesiredSetting.EventLevel))
            {
                $mismatchedSettings += @{
                    Name           = $Name
                    DesiredSetting = $DesiredSetting
                    CurrentSetting = $currentSetting
                }
                Write-Verbose -Message "SP Log Level setting for $($currentSetting.Area):$($currentSetting.Name) is not in the desired state"
                $mismatchedSettingFound = $true
            }
        }
    }

    if ($mismatchedSettingFound)
    {
        $EventMessage = "<SPDscEvent>`r`n"
        $EventMessage += "    <ConfigurationDrift Source=`"$($MyInvocation.MyCommand.Source)`">`r`n"

        $EventMessage += "        <ParametersNotInDesiredState>`r`n"
        $driftedValue = ''
        foreach ($setting in $mismatchedSettings)
        {
            $EventMessage += "            <LogLevel Area=`"$($setting.CurrentSetting.Area)`" Name=`"$($setting.CurrentSetting.Area)`"> TraceLevel: " + $setting.CurrentSetting.TraceLevel + " - EventLevel: " + $setting.CurrentSetting.EventLevel + "</Param>`r`n"
        }
        $EventMessage += "        </ParametersNotInDesiredState>`r`n"
        $EventMessage += "    </ConfigurationDrift>`r`n"
        $EventMessage += "    <DesiredValues>`r`n"
        foreach ($setting in $mismatchedSettings)
        {
            $EventMessage += "            <LogLevel Area=`"$($setting.DesiredSetting.Area)`" Name=`"$($setting.DesiredSetting.Area)`"> TraceLevel: " + $setting.DesiredSetting.TraceLevel + " - EventLevel: " + $setting.DesiredSetting.EventLevel + "</Param>`r`n"
        }
        $EventMessage += "    }"
        $EventMessage += "    </DesiredValues>`r`n"
        $EventMessage += "</SPDscEvent>"
        Add-SPDscEvent -Message $EventMessage -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

        $result = $false
    }
    else
    {
        $result = $true
    }

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath "\DSCResources\MSFT_SPLogLevel\MSFT_SPLogLevel.psm1" -Resolve

    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module
    $PartialContent = "        SPLogLevel AllLogLevels`r`n"
    $PartialContent += "        {`r`n"

    try
    {
        $params.SPLogLevelSetting = @()
        $params.SPLogLevelSetting += New-CimInstance -ClassName MSFT_SPLogLevelItem -Property @{
            Area       = "*"
            Name       = "*"
            TraceLevel = "Default"
            EventLevel = "Default"
        } -ClientOnly
        $results = Get-TargetResource @params

        $results = Repair-Credentials -results $results

        $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
        $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"

        # Change hashtable format into CIM Instance format
        $currentBlock = $currentBlock -replace "@{", "`r`n                MSFT_SPLogLevelItem {" -replace "}", "}," -replace ",\);", "`r`n            );" -replace "=", "=`"" -replace "; ", "`"; " -replace "}", "`"}"

        $PartialContent += $currentBlock
        $PartialContent += "        }`r`n"
        $Content += $PartialContent
    }
    catch
    {
        $Global:ErrorLog += "[Diagnostic Logging Level]`r`n"
        $Global:ErrorLog += "$_`r`n`r`n"
    }

    return $Content
}

Export-ModuleMember -Function *-TargetResource
