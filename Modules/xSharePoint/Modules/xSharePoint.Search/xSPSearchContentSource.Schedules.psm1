function Get-xSPSearchCrawlSchedule {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $false)] $Schedule
    )
    
    if ($null -eq $Schedule) {
        return @{
            ScheduleType = "None"
        }
    }
    
    $scheduleType = $Schedule.GetType().Name
    $result = @{
        CrawlScheduleRepeatDuration = $Schedule.RepeatDuration
        CrawlScheduleRepeatInterval = $Schedule.RepeatInterval
        StartHour = $Schedule.StartHour
        StartMinute = $Schedule.StartMinute
    }
    
    switch ($scheduleType) {
        "DailySchedule" { 
            $result.Add("ScheduleType", "Daily")
            $result.Add("CrawlScheduleRunEveryInterval", $Schedule.DaysInterval)
        }
        "WeeklySchedule" { 
            $result.Add("ScheduleType", "Weekly")
            $result.Add("CrawlScheduleRunEveryInterval", $Schedule.WeeksInterval)
            $result.Add("CrawlScheduleDaysOfWeek", $Schedule.DaysOfWeek)
        }
        "MonthlyDateSchedule" { 
            $result.Add("ScheduleType", "Monthly")
            $result.Add("CrawlScheduleDaysOfMonth", ($Schedule.DaysOfMonth.ToString() -replace "Day"))
            $result.Add("CrawlScheduleMonthsOfYear", $schedule.MonthsOfYear)
        }
        Default {
            throw "An unknown schedule type was detected"
        }
    }
    return $result
}

function Test-xSPSearchCrawlSchedule {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [parameter(Mandatory = $true)] $CurrentSchedule,
        [parameter(Mandatory = $true)] $DesiredSchedule
    )
    
    Import-Module (Join-Path $PSScriptRoot "..\xSharePoint.Util\xSharePoint.Util.psm1")
    
    if ($CurrentSchedule.ScheduleType -ne $DesiredSchedule.ScheduleType) { return $false }
    
    if ((Test-xSharePointObjectHasProperty -Object $DesiredSchedule -PropertyName "CrawlScheduleRepeatDuration") -eq $true -and $CurrentSchedule.CrawlScheduleRepeatDuration -ne $DesiredSchedule.CrawlScheduleRepeatDuration) { return $false }
    if ((Test-xSharePointObjectHasProperty -Object $DesiredSchedule -PropertyName "CrawlScheduleRepeatInterval") -eq $true -and $CurrentSchedule.CrawlScheduleRepeatInterval -ne $DesiredSchedule.CrawlScheduleRepeatInterval) { return $false }
    if ((Test-xSharePointObjectHasProperty -Object $DesiredSchedule -PropertyName "StartHour") -eq $true -and $CurrentSchedule.StartHour -ne $DesiredSchedule.StartHour) { return $false }
    if ((Test-xSharePointObjectHasProperty -Object $DesiredSchedule -PropertyName "StartMinute") -eq $true -and $CurrentSchedule.StartMinute -ne $DesiredSchedule.StartMinute) { return $false }
    
    switch ($CurrentSchedule.ScheduleType) {
        "Daily" { 
            if ((Test-xSharePointObjectHasProperty -Object $DesiredSchedule -PropertyName "CrawlScheduleRunEveryInterval") -eq $true -and $CurrentSchedule.CrawlScheduleRunEveryInterval -ne $DesiredSchedule.CrawlScheduleRunEveryInterval) { return $false }
        }
        "Weekly" { 
            if ((Test-xSharePointObjectHasProperty -Object $DesiredSchedule -PropertyName "CrawlScheduleRunEveryInterval") -eq $true -and $CurrentSchedule.CrawlScheduleRunEveryInterval -ne $DesiredSchedule.CrawlScheduleRunEveryInterval) { return $false }
            if ((Test-xSharePointObjectHasProperty -Object $DesiredSchedule -PropertyName "CrawlScheduleDaysOfWeek") -eq $true -and (Compare-Object -ReferenceObject $CurrentSchedule.CrawlScheduleDaysOfWeek.ToString().Split(', ', [System.StringSplitOptions]::RemoveEmptyEntries) -DifferenceObject $DesiredSchedule.CrawlScheduleDaysOfWeek) -ne $null) { return $false } 
        }
        "Monthly" { 
            if ((Test-xSharePointObjectHasProperty -Object $DesiredSchedule -PropertyName "CrawlScheduleDaysOfMonth") -eq $true -and $CurrentSchedule.CrawlScheduleDaysOfMonth -ne $DesiredSchedule.CrawlScheduleDaysOfMonth) { return $false }
            if ((Test-xSharePointObjectHasProperty -Object $DesiredSchedule -PropertyName "CrawlScheduleMonthsOfYear") -eq $true -and (Compare-Object -ReferenceObject $CurrentSchedule.CrawlScheduleMonthsOfYear.ToString().Split(', ', [System.StringSplitOptions]::RemoveEmptyEntries) -DifferenceObject $DesiredSchedule.CrawlScheduleMonthsOfYear) -eq $null) { return $false }
        }
    }    
    return $true
}

Export-ModuleMember -Function *
