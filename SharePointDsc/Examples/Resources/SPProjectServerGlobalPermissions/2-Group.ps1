
<#PSScriptInfo

.VERSION 1.0.0

.GUID 80d306fa-8bd4-4a8d-9f7a-bf40df95e661

.AUTHOR DSC Community

.COMPANYNAME DSC Community

.COPYRIGHT DSC Community contributors. All rights reserved.

.TAGS

.LICENSEURI https://github.com/dsccommunity/SharePointDsc/blob/master/LICENSE

.PROJECTURI https://github.com/dsccommunity/SharePointDsc

.ICONURI https://dsccommunity.org/images/DSC_Logo_300p.png

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
Updated author, copyright notice, and URLs.

.PRIVATEDATA

#>

<#

.DESCRIPTION
 This example shows how to set permissions for a specific group that exists in a PWA site

#>

Configuration Example
{
    param(
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $SetupAccount
    )
    Import-DscResource -ModuleName SharePointDsc

    node localhost
    {
        SPProjectServerGlobalPermissions Permissions
        {
            Url = "http://projects.contoso.com"
            EntityName = "Group Name"
            EntityType = "Group"
            AllowPermissions = @(
                "LogOn",
                "NewTaskAssignment",
                "AccessProjectDataService",
                "ReassignTask",
                "ManagePortfolioAnalyses",
                "ManageUsersAndGroups",
                "ManageWorkflow",
                "ManageCheckIns",
                "ManageGanttChartAndGroupingFormats",
                "ManageEnterpriseCustomFields",
                "ManageSecurity",
                "ManageEnterpriseCalendars",
                "ManageCubeBuildingService",
                "CleanupProjectServerDatabase",
                "SaveEnterpriseGlobal",
                "ManageWindowsSharePointServices",
                "ManagePrioritizations",
                "ManageViews",
                "ContributeToProjectWebAccess",
                "ManageQueue",
                "LogOnToProjectServerFromProjectProfessional",
                "ManageDrivers",
                "ManagePersonalNotifications",
                "ManageServerConfiguration",
                "ChangeWorkflow",
                "ManageActiveDirectorySettings",
                "ManageServerEvents",
                "ManageSiteWideExchangeSync",
                "ManageListsInProjectWebAccess"
            )
            DenyPermissions = @(
                "NewProject"
            )
            PSDscRunAsCredential = $SetupAccount
        }
    }
}
