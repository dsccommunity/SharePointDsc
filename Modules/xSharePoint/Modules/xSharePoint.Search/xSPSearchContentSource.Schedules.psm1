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
    
    $scheduleType = $schedule.GetType().Name
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
}

function Test-xSPSearchCrawlSchedule {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [parameter(Mandatory = $true)] $CurrentSchedule,
        [parameter(Mandatory = $true)] $DesiredSchedule
    )
    
    if ($CurrentSchedule.ScheduleType -ne $CurrentSchedule.ScheduleType) { return $false }
    
    if ($CurrentSchedule.CrawlScheduleRepeatDuration -ne $CurrentSchedule.CrawlScheduleRepeatDuration) { return $false }
    if ($CurrentSchedule.CrawlScheduleRepeatInterval -ne $CurrentSchedule.CrawlScheduleRepeatInterval) { return $false }
    if ($CurrentSchedule.StartHour -ne $CurrentSchedule.StartHour) { return $false }
    if ($CurrentSchedule.StartMinute -ne $CurrentSchedule.StartMinute) { return $false }
    
    $scheduleType = $CurrentSchedule.GetType().Name
    switch ($scheduleType) {
        "DailySchedule" { 
            if ($CurrentSchedule.CrawlScheduleRunEveryInterval -ne $CurrentSchedule.CrawlScheduleRunEveryInterval) { return $false }
        }
        "WeeklySchedule" { 
            if ($CurrentSchedule.CrawlScheduleRunEveryInterval -ne $CurrentSchedule.CrawlScheduleRunEveryInterval) { return $false }
            if ($CurrentSchedule.CrawlScheduleDaysOfWeek -ne $CurrentSchedule.CrawlScheduleDaysOfWeek) { return $false } #TODO: Compare items in this array
        }
        "MonthlyDateSchedule" { 
            if ($CurrentSchedule.CrawlScheduleDaysOfMonth -ne $CurrentSchedule.CrawlScheduleDaysOfMonth) { return $false }
            if ($CurrentSchedule.CrawlScheduleMonthsOfYear -ne $CurrentSchedule.CrawlScheduleMonthsOfYear) { return $false } #TODO: Compare items in this array
        }
        Default {
            throw "An unknown schedule type was detected"
        }
    }    
    return $true
}

Export-ModuleMember -Function *
