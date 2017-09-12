function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]  
        [System.String] 
        $Url,
        
        [Parameter(Mandatory = $false)]  
        [System.Boolean]
        $EnableOvertimeAndNonBillableTracking,

        [Parameter(Mandatory = $false)] 
        [ValidateSet("CurrentTaskAssignments","CurrentProjects","NoPrepopulation")]
        [System.String] 
        $DefaultTimesheetCreationMode,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Days","Weeks")]
        [System.String] 
        $DefaultTrackingUnit,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Hours","Days")]
        [System.String] 
        $DefaultReportingUnit,

        [Parameter(Mandatory = $true)]  
        [System.Single] 
        $HoursInStandardDay,

        [Parameter(Mandatory = $true)]  
        [System.Single] 
        $HoursInStandardWeek,

        [Parameter(Mandatory = $true)]  
        [System.Single] 
        $MaxHoursPerTimesheet,

        [Parameter(Mandatory = $true)]  
        [System.Single] 
        $MinHoursPerTimesheet,

        [Parameter(Mandatory = $true)]  
        [System.Single] 
        $MaxHoursPerDay,

        [Parameter(Mandatory = $false)]  
        [System.Boolean]
        $AllowFutureTimeReporting,

        [Parameter(Mandatory = $false)]  
        [System.Boolean]
        $AllowNewPersonalTasks,

        [Parameter(Mandatory = $false)]  
        [System.Boolean]
        $AllowTopLevelTimeReporting,

        [Parameter(Mandatory = $false)]  
        [System.Boolean]
        $RequireTaskStatusManagerApproval,

        [Parameter(Mandatory = $false)]  
        [System.Boolean]
        $RequireLineApprovalBeforeTimesheetApproval,

        [Parameter(Mandatory = $false)]  
        [System.Boolean]
        $EnableTimesheetAuditing,

        [Parameter(Mandatory = $false)]  
        [System.Boolean]
        $FixedApprovalRouting,

        [Parameter(Mandatory = $false)]  
        [System.Boolean]
        $SingleEntryMode,

        [Parameter(Mandatory = $false)]
        [ValidateSet("PercentComplete","ActualDoneAndRemaining","HoursPerPeriod","FreeForm")]
        [System.String] 
        $DefaultTrackingMode,

        [Parameter(Mandatory = $false)]  
        [System.Boolean]
        $ForceTrackingModeForAllProjects,

        [Parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Getting AD Resource Pool Sync settings for $Url"

    if ((Get-SPDSCInstalledProductVersion).FileMajorPart -lt 16) 
    {
        throw [Exception] ("Support for Project Server in SharePointDsc is only valid for " + `
                           "SharePoint 2016.")
    }

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments @($PSBoundParameters, $PSScriptRoot) `
                                  -ScriptBlock {
        $params = $args[0]
        $scriptRoot = $args[1]
        
        $modulePath = "..\..\Modules\SharePointDsc.ProjectServer\ProjectServerConnector.psm1"
        Import-Module -Name (Join-Path -Path $scriptRoot -ChildPath $modulePath -Resolve)

        $adminService = New-SPDscProjectServerWebService -PwaUrl $params.Url -EndpointName Admin

        $script:currentSettings = $null
        Use-SPDscProjectServerWebService -Service $adminService -ScriptBlock {
            $script:currentSettings = $adminService.ReadTimeSheetSettings().TimeSheetSettings
        }

        if ($null -eq $script:currentSettings)
        {
            return @{
                Url = $params.Url
                EnableOvertimeAndNonBillableTracking = $false
                DefaultTimesheetCreationMode = ""
                DefaultTrackingUnit = ""
                DefaultReportingUnit = ""
                HoursInStandardDay = 0
                HoursInStandardWeek = 0
                MaxHoursPerTimesheet = 0
                MinHoursPerTimesheet = 0
                MaxHoursPerDay = 0
                AllowFutureTimeReporting = $false
                AllowNewPersonalTasks  = $false
                AllowTopLevelTimeReporting = $false
                RequireTaskStatusManagerApproval = $false
                RequireLineApprovalBeforeTimesheetApproval = $false
                EnableTimesheetAuditing = $false
                FixedApprovalRouting = $false
                SingleEntryMode = $false
                DefaultTrackingMode = ""
                ForceTrackingModeForAllProjects = $false
                InstallAccount = $params.InstallAccount
            }
        }
        else
        {
            $currentDefaultTimesheetCreationMode = "Unknown"
            switch ($script:currentSettings.WADMIN_TS_CREATE_MODE_ENUM)
            {
                1 {
                    $currentDefaultTimesheetCreationMode = "CurrentTaskAssignments"
                }
                2 {
                    $currentDefaultTimesheetCreationMode = "CurrentProjects"
                }
                0 {
                    $currentDefaultTimesheetCreationMode = "NoPrepopulation"
                }
            }

            $currentDefaultTrackingUnit = "Unknown"
            switch ($script:currentSettings.WADMIN_TS_DEF_ENTRY_MODE_ENUM)
            {
                1 {
                    $currentDefaultTrackingUnit = "Weeks"
                }
                0 {
                    $currentDefaultTrackingUnit = "Days"
                }
            }

            $currentDefaultReportingUnit = "Unknown"
            switch ($script:currentSettings.WADMIN_TS_REPORT_UNIT_ENUM)
            {
                1 {
                    $currentDefaultReportingUnit = "Days"
                }
                0 {
                    $currentDefaultReportingUnit = "Hours"
                }
            }

            $currentDefaultTrackingMode = "Unknown"
            switch ($script:currentSettings.WADMIN_TS_REPORT_UNIT_ENUM)
            {
                3 {
                    $currentDefaultTrackingMode = "ActualDoneAndRemaining"
                }
                2 {
                    $currentDefaultTrackingMode = "PercentComplete"
                }
                1 {
                    $currentDefaultTrackingMode = "HoursPerPeriod"
                }
                0 {
                    $currentDefaultTrackingMode = "FreeForm"
                }
            }

            $currentEnableOvertimeAndNonBillableTracking = $false
            switch ($script:currentSettings.WADMIN_TS_DEF_DISPLAY_ENUM)
            {
                7 {
                    $currentEnableOvertimeAndNonBillableTracking = $true
                }
                0 {
                    $currentEnableOvertimeAndNonBillableTracking = $false
                }
            }

            return @{
                Url = $params.Url
                EnableOvertimeAndNonBillableTracking = $currentEnableOvertimeAndNonBillableTracking
                DefaultTimesheetCreationMode = $currentDefaultTimesheetCreationMode
                DefaultTrackingUnit = $currentDefaultTrackingUnit
                DefaultReportingUnit = $currentDefaultReportingUnit
                HoursInStandardDay = ([System.Single]::Parse($script:currentSettings.WADMIN_TS_HOURS_PER_DAY) / 60000)
                HoursInStandardWeek = ([System.Single]::Parse($script:currentSettings.WADMIN_TS_HOURS_PER_WEEK) / 60000)
                MaxHoursPerTimesheet = ([System.Single]::Parse($script:currentSettings.WADMIN_TS_MAX_HR_PER_TS) / 60000)
                MinHoursPerTimesheet = ([System.Single]::Parse($script:currentSettings.WADMIN_TS_MIN_HR_PER_TS) / 60000)
                MaxHoursPerDay = ([System.Single]::Parse($script:currentSettings.WADMIN_TS_MAX_HR_PER_DAY) / 60000)
                AllowFutureTimeReporting = $script:currentSettings.WADMIN_TS_IS_FUTURE_REP_ALLOWED
                AllowNewPersonalTasks = $script:currentSettings.WADMIN_TS_IS_UNVERS_TASK_ALLOWED
                AllowTopLevelTimeReporting = $script:currentSettings.WADMIN_TS_ALLOW_PROJECT_LEVEL
                RequireTaskStatusManagerApproval = $script:currentSettings.WADMIN_TS_PROJECT_MANAGER_COORDINATION
                RequireLineApprovalBeforeTimesheetApproval = $script:currentSettings.WADMIN_TS_PROJECT_MANAGER_APPROVAL
                EnableTimesheetAuditing = $script:currentSettings.WADMIN_TS_IS_AUDIT_ENABLED
                FixedApprovalRouting = $script:currentSettings.WADMIN_TS_FIXED_APPROVAL_ROUTING
                SingleEntryMode = $script:currentSettings.WADMIN_TS_TIED_MODE
                DefaultTrackingMode = $currentDefaultTrackingMode
                ForceTrackingModeForAllProjects = $script:currentSettings.WADMIN_IS_TRACKING_METHOD_LOCKED
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
        [Parameter(Mandatory = $true)]  
        [System.String] 
        $Url,
        
        [Parameter(Mandatory = $false)]  
        [System.Boolean]
        $EnableOvertimeAndNonBillableTracking,

        [Parameter(Mandatory = $false)] 
        [ValidateSet("CurrentTaskAssignments","CurrentProjects","NoPrepopulation")]
        [System.String] 
        $DefaultTimesheetCreationMode,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Days","Weeks")]
        [System.String] 
        $DefaultTrackingUnit,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Hours","Days")]
        [System.String] 
        $DefaultReportingUnit,

        [Parameter(Mandatory = $true)]  
        [System.Single] 
        $HoursInStandardDay,

        [Parameter(Mandatory = $true)]  
        [System.Single] 
        $HoursInStandardWeek,

        [Parameter(Mandatory = $true)]  
        [System.Single] 
        $MaxHoursPerTimesheet,

        [Parameter(Mandatory = $true)]  
        [System.Single] 
        $MinHoursPerTimesheet,

        [Parameter(Mandatory = $true)]  
        [System.Single] 
        $MaxHoursPerDay,

        [Parameter(Mandatory = $false)]  
        [System.Boolean]
        $AllowFutureTimeReporting,

        [Parameter(Mandatory = $false)]  
        [System.Boolean]
        $AllowNewPersonalTasks,

        [Parameter(Mandatory = $false)]  
        [System.Boolean]
        $AllowTopLevelTimeReporting,

        [Parameter(Mandatory = $false)]  
        [System.Boolean]
        $RequireTaskStatusManagerApproval,

        [Parameter(Mandatory = $false)]  
        [System.Boolean]
        $RequireLineApprovalBeforeTimesheetApproval,

        [Parameter(Mandatory = $false)]  
        [System.Boolean]
        $EnableTimesheetAuditing,

        [Parameter(Mandatory = $false)]  
        [System.Boolean]
        $FixedApprovalRouting,

        [Parameter(Mandatory = $false)]  
        [System.Boolean]
        $SingleEntryMode,

        [Parameter(Mandatory = $false)]
        [ValidateSet("PercentComplete","ActualDoneAndRemaining","HoursPerPeriod","FreeForm")]
        [System.String] 
        $DefaultTrackingMode,

        [Parameter(Mandatory = $false)]  
        [System.Boolean]
        $ForceTrackingModeForAllProjects,

        [Parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Setting AD Resource Pool Sync settings for $Url"

    if ((Get-SPDSCInstalledProductVersion).FileMajorPart -lt 16) 
    {
        throw [Exception] ("Support for Project Server in SharePointDsc is only valid for " + `
                           "SharePoint 2016.")
    }

    if ($Ensure -eq "Present")
    {
        Invoke-SPDSCCommand -Credential $InstallAccount `
                            -Arguments $PSBoundParameters `
                            -ScriptBlock {

            $params = $args[0]

            $groupIDs = New-Object -TypeName "System.Collections.Generic.List[System.Guid]"

            $params.GroupNames | ForEach-Object -Process {
                $groupName = $_
                $groupNTaccount = New-Object -TypeName "System.Security.Principal.NTAccount" `
                                             -ArgumentList $groupName
                $groupSid = $groupNTaccount.Translate([System.Security.Principal.SecurityIdentifier])

                $result = New-Object -TypeName "System.DirectoryServices.DirectoryEntry" `
                                     -ArgumentList "LDAP://<SID=$($groupSid.ToString())>"
                $groupIDs.Add(([Guid]::new($result.objectGUID.Value)))
            }
            
            Enable-SPProjectActiveDirectoryEnterpriseResourcePoolSync -Url $params.Url `
                                                                      -GroupUids $groupIDs.ToArray()

            if ($params.ContainsKey("AutoReactivateUsers") -eq $true)
            {
                $adminService = New-SPDscProjectServerWebService -PwaUrl $params.Url -EndpointName Admin

                Use-SPDscProjectServerWebService -Service $adminService -ScriptBlock {
                    $settings = $adminService.GetActiveDirectorySyncEnterpriseResourcePoolSettings()
                    $settings.AutoReactivateInactiveUsers  = $params.AutoReactivateUsers
                    $adminService.SetActiveDirectorySyncEnterpriseResourcePoolSettings($settings)
                }
            }
        }
    }
    else
    {
        Invoke-SPDSCCommand -Credential $InstallAccount `
                            -Arguments $PSBoundParameters `
                            -ScriptBlock {

            $params = $args[0]

            Disable-SPProjectActiveDirectoryEnterpriseResourcePoolSync -Url $params.Url
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
        $Url,
        
        [Parameter(Mandatory = $false)]  
        [System.Boolean]
        $EnableOvertimeAndNonBillableTracking,

        [Parameter(Mandatory = $false)] 
        [ValidateSet("CurrentTaskAssignments","CurrentProjects","NoPrepopulation")]
        [System.String] 
        $DefaultTimesheetCreationMode,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Days","Weeks")]
        [System.String] 
        $DefaultTrackingUnit,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Hours","Days")]
        [System.String] 
        $DefaultReportingUnit,

        [Parameter(Mandatory = $true)]  
        [System.Single] 
        $HoursInStandardDay,

        [Parameter(Mandatory = $true)]  
        [System.Single] 
        $HoursInStandardWeek,

        [Parameter(Mandatory = $true)]  
        [System.Single] 
        $MaxHoursPerTimesheet,

        [Parameter(Mandatory = $true)]  
        [System.Single] 
        $MinHoursPerTimesheet,

        [Parameter(Mandatory = $true)]  
        [System.Single] 
        $MaxHoursPerDay,

        [Parameter(Mandatory = $false)]  
        [System.Boolean]
        $AllowFutureTimeReporting,

        [Parameter(Mandatory = $false)]  
        [System.Boolean]
        $AllowNewPersonalTasks,

        [Parameter(Mandatory = $false)]  
        [System.Boolean]
        $AllowTopLevelTimeReporting,

        [Parameter(Mandatory = $false)]  
        [System.Boolean]
        $RequireTaskStatusManagerApproval,

        [Parameter(Mandatory = $false)]  
        [System.Boolean]
        $RequireLineApprovalBeforeTimesheetApproval,

        [Parameter(Mandatory = $false)]  
        [System.Boolean]
        $EnableTimesheetAuditing,

        [Parameter(Mandatory = $false)]  
        [System.Boolean]
        $FixedApprovalRouting,

        [Parameter(Mandatory = $false)]  
        [System.Boolean]
        $SingleEntryMode,

        [Parameter(Mandatory = $false)]
        [ValidateSet("PercentComplete","ActualDoneAndRemaining","HoursPerPeriod","FreeForm")]
        [System.String] 
        $DefaultTrackingMode,

        [Parameter(Mandatory = $false)]  
        [System.Boolean]
        $ForceTrackingModeForAllProjects,

        [Parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Testing AD Resource Pool Sync settings for $Url"

    $currentValues = Get-TargetResource @PSBoundParameters

    $PSBoundParameters.Ensure = $Ensure

    $paramsToCheck = @("Ensure")
    
    if ($Ensure -eq "Present")
    {
        $paramsToCheck += "GroupNames"
        if ($PSBoundParameters.ContainsKey("AutoReactivateUsers") -eq $true)
        {
            $paramsToCheck += "AutoReactivateUsers"
        }
    }

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck $paramsToCheck
}

Export-ModuleMember -Function *-TargetResource
