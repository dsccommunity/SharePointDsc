[CmdletBinding()]
param(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
            -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
        -ChildPath "..\UnitTestHelper.psm1" `
        -Resolve)

$Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
    -DscResource "SPProjectServerTimeSheetSettings"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major)
        {
            15
            {
                Context -Name "All methods throw exceptions as Project Server support in SharePointDsc is only for 2016" -Fixture {
                    It "Should throw on the get method" {
                        { Get-TargetResource @testParams } | Should Throw
                    }

                    It "Should throw on the test method" {
                        { Test-TargetResource @testParams } | Should Throw
                    }

                    It "Should throw on the set method" {
                        { Set-TargetResource @testParams } | Should Throw
                    }
                }
            }
            16
            {
                $modulePath = "Modules\SharePointDsc\Modules\SharePointDsc.ProjectServer\ProjectServerConnector.psm1"
                Import-Module -Name (Join-Path -Path $Global:SPDscHelper.RepoRoot -ChildPath $modulePath -Resolve)

                Mock -CommandName "Import-Module" -MockWith { }

                Mock -CommandName Get-SPSite -MockWith {
                    return @{
                        WebApplication = @{
                            Url = "http://server"
                        }
                    }
                }

                Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                    return @{
                        DisableKerberos = $true
                    }
                }

                try
                {
                    [SPDscTests.DummyWebService] | Out-Null
                }
                catch
                {
                    Add-Type -TypeDefinition @"
                        namespace SPDscTests
                        {
                            public class DummyWebService : System.IDisposable
                            {
                                public void Dispose()
                                {

                                }
                            }
                        }
"@
                }

                function New-SPDscTimeSheetSettingsTable
                {
                    param(
                        [Parameter(Mandatory = $true)]
                        [System.Collections.Hashtable]
                        $Values
                    )
                    $ds = New-Object -TypeName "System.Data.DataSet"
                    $ds.Tables.Add("TimeSheetSettings")
                    $Values.Keys | ForEach-Object -Process {
                        $ds.Tables[0].Columns.Add($_, [System.Object]) | Out-Null
                    }
                    $row = $ds.Tables[0].NewRow()
                    $Values.Keys | ForEach-Object -Process {
                        $row[$_] = $Values.$_
                    }
                    $ds.Tables[0].Rows.Add($row) | Out-Null
                    return $ds
                }

                Mock -CommandName "New-SPDscProjectServerWebService" -MockWith {
                    $service = [SPDscTests.DummyWebService]::new()
                    $service = $service | Add-Member -MemberType ScriptMethod `
                        -Name ReadTimeSheetSettings `
                        -Value {
                        return $global:SPDscCurrentTimeSheetSettings
                    } -PassThru -Force `
                    | Add-Member -MemberType ScriptMethod `
                        -Name UpdateTimeSheetSettings `
                        -Value {
                        $global:SPDscUpdateTimeSheetSettingsCalled = $true
                    } -PassThru -Force
                    return $service
                }

                Context -Name "Timesheet settings cannot be read" -Fixture {
                    $testParams = @{
                        Url                                        = "http://sites.contoso.com/pwa"
                        EnableOvertimeAndNonBillableTracking       = $true
                        DefaultTimesheetCreationMode               = "CurrentProjects"
                        DefaultTrackingUnit                        = "Days"
                        DefaultReportingUnit                       = "Days"
                        HoursInStandardDay                         = 8
                        HoursInStandardWeek                        = 40
                        MaxHoursPerTimesheet                       = 100
                        MinHoursPerTimesheet                       = 0
                        MaxHoursPerDay                             = 18
                        AllowFutureTimeReporting                   = $true
                        AllowNewPersonalTasks                      = $true
                        AllowTopLevelTimeReporting                 = $true
                        RequireTaskStatusManagerApproval           = $true
                        RequireLineApprovalBeforeTimesheetApproval = $true
                        EnableTimesheetAuditing                    = $true
                        FixedApprovalRouting                       = $true
                        SingleEntryMode                            = $true
                        DefaultTrackingMode                        = "PercentComplete"
                        ForceTrackingModeForAllProjects            = $true
                    }

                    $global:SPDscCurrentTimeSheetSettings = $null

                    It "should return null values on properties from the get method" {
                        (Get-TargetResource @testParams).DefaultTimesheetCreationMode | Should BeNullOrEmpty
                    }
                }

                Context -Name "Timesheet settings exist but are not set correctly" -Fixture {
                    $testParams = @{
                        Url                                        = "http://sites.contoso.com/pwa"
                        EnableOvertimeAndNonBillableTracking       = $true
                        DefaultTimesheetCreationMode               = "CurrentProjects"
                        DefaultTrackingUnit                        = "Days"
                        DefaultReportingUnit                       = "Days"
                        HoursInStandardDay                         = 8
                        HoursInStandardWeek                        = 40
                        MaxHoursPerTimesheet                       = 100
                        MinHoursPerTimesheet                       = 0
                        MaxHoursPerDay                             = 18
                        AllowFutureTimeReporting                   = $true
                        AllowNewPersonalTasks                      = $true
                        AllowTopLevelTimeReporting                 = $true
                        RequireTaskStatusManagerApproval           = $true
                        RequireLineApprovalBeforeTimesheetApproval = $true
                        EnableTimesheetAuditing                    = $true
                        FixedApprovalRouting                       = $true
                        SingleEntryMode                            = $true
                        DefaultTrackingMode                        = "PercentComplete"
                        ForceTrackingModeForAllProjects            = $true
                    }

                    $global:SPDscCurrentTimeSheetSettings = @{
                        TimeSheetSettings = (New-SPDscTimeSheetSettingsTable -Values @{
                                WADMIN_TS_DEF_DISPLAY_ENUM             = 0
                                WADMIN_TS_CREATE_MODE_ENUM             = 0
                                WADMIN_TS_DEF_ENTRY_MODE_ENUM          = 1
                                WADMIN_TS_REPORT_UNIT_ENUM             = 0
                                WADMIN_TS_HOURS_PER_DAY                = 450000
                                WADMIN_TS_HOURS_PER_WEEK               = 2250000
                                WADMIN_TS_MAX_HR_PER_TS                = 6600000
                                WADMIN_TS_MIN_HR_PER_TS                = 60000
                                WADMIN_TS_MAX_HR_PER_DAY               = 480000
                                WADMIN_TS_IS_FUTURE_REP_ALLOWED        = $false
                                WADMIN_TS_IS_UNVERS_TASK_ALLOWED       = $false
                                WADMIN_TS_ALLOW_PROJECT_LEVEL          = $false
                                WADMIN_TS_PROJECT_MANAGER_COORDINATION = $false
                                WADMIN_TS_PROJECT_MANAGER_APPROVAL     = $false
                                WADMIN_TS_IS_AUDIT_ENABLED             = $false
                                WADMIN_TS_FIXED_APPROVAL_ROUTING       = $false
                                WADMIN_TS_TIED_MODE                    = $false
                                WADMIN_DEFAULT_TRACKING_METHOD         = 0
                                WADMIN_IS_TRACKING_METHOD_LOCKED       = $false
                            }).Tables[0]
                    }

                    It "Should return the current values from the get method" {
                        (Get-TargetResource @testParams).DefaultTimesheetCreationMode | Should Be "NoPrepopulation"
                    }

                    It "Should return false from the test method" {
                        Test-TargetResource @testParams | Should Be $false
                    }

                    It "Should call update in the set method" {
                        $global:SPDscUpdateTimeSheetSettingsCalled = $false
                        Set-TargetResource @testParams
                        $global:SPDscUpdateTimeSheetSettingsCalled | Should Be $true
                    }
                }

                Context -Name "Timesheet settings exist and are set correctly" -Fixture {
                    $testParams = @{
                        Url                                        = "http://sites.contoso.com/pwa"
                        EnableOvertimeAndNonBillableTracking       = $true
                        DefaultTimesheetCreationMode               = "CurrentProjects"
                        DefaultTrackingUnit                        = "Days"
                        DefaultReportingUnit                       = "Days"
                        HoursInStandardDay                         = 8
                        HoursInStandardWeek                        = 40
                        MaxHoursPerTimesheet                       = 100
                        MinHoursPerTimesheet                       = 0
                        MaxHoursPerDay                             = 18
                        AllowFutureTimeReporting                   = $true
                        AllowNewPersonalTasks                      = $true
                        AllowTopLevelTimeReporting                 = $true
                        RequireTaskStatusManagerApproval           = $true
                        RequireLineApprovalBeforeTimesheetApproval = $true
                        EnableTimesheetAuditing                    = $true
                        FixedApprovalRouting                       = $true
                        SingleEntryMode                            = $true
                        DefaultTrackingMode                        = "PercentComplete"
                        ForceTrackingModeForAllProjects            = $true
                    }

                    $global:SPDscCurrentTimeSheetSettings = @{
                        TimeSheetSettings = (New-SPDscTimeSheetSettingsTable -Values @{
                                WADMIN_TS_DEF_DISPLAY_ENUM             = 7
                                WADMIN_TS_CREATE_MODE_ENUM             = 2
                                WADMIN_TS_DEF_ENTRY_MODE_ENUM          = 0
                                WADMIN_TS_REPORT_UNIT_ENUM             = 1
                                WADMIN_TS_HOURS_PER_DAY                = 480000
                                WADMIN_TS_HOURS_PER_WEEK               = 2400000
                                WADMIN_TS_MAX_HR_PER_TS                = 6000000
                                WADMIN_TS_MIN_HR_PER_TS                = 0
                                WADMIN_TS_MAX_HR_PER_DAY               = 1080000
                                WADMIN_TS_IS_FUTURE_REP_ALLOWED        = $true
                                WADMIN_TS_IS_UNVERS_TASK_ALLOWED       = $true
                                WADMIN_TS_ALLOW_PROJECT_LEVEL          = $true
                                WADMIN_TS_PROJECT_MANAGER_COORDINATION = $true
                                WADMIN_TS_PROJECT_MANAGER_APPROVAL     = $true
                                WADMIN_TS_IS_AUDIT_ENABLED             = $true
                                WADMIN_TS_FIXED_APPROVAL_ROUTING       = $true
                                WADMIN_TS_TIED_MODE                    = $true
                                WADMIN_DEFAULT_TRACKING_METHOD         = 2
                                WADMIN_IS_TRACKING_METHOD_LOCKED       = $true
                            }).Tables[0]
                    }

                    It "Should return the current values from the get method" {
                        (Get-TargetResource @testParams).DefaultTimesheetCreationMode | Should Be "CurrentProjects"
                    }

                    It "Should return true from the test method" {
                        Test-TargetResource @testParams | Should Be $true
                    }
                }
            }
            Default
            {
                throw [Exception] "A supported version of SharePoint was not used in testing"
            }
        }
    }
}
