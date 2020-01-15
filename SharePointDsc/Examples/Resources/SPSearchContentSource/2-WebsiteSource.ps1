
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
 This example shows how to create a website content source

#>

    Configuration Example
    {
        param(
            [Parameter(Mandatory = $true)]
            [PSCredential]
            $SetupAccount
        )
        Import-DscResource -ModuleName SharePointDsc

        node localhost {
            SPSearchContentSource WebsiteSource
            {
                Name                 = "Contoso website"
                ServiceAppName       = "Search Service Application"
                ContentSourceType    = "Website"
                Addresses            = @("http://www.contoso.com")
                CrawlSetting         = "Custom"
                LimitPageDepth       = 5
                IncrementalSchedule  = MSFT_SPSearchCrawlSchedule{
                                        ScheduleType = "Daily"
                                        StartHour = "0"
                                        StartMinute = "0"
                                        CrawlScheduleRepeatDuration = "1440"
                                        CrawlScheduleRepeatInterval = "5"
                                       }
                FullSchedule         = MSFT_SPSearchCrawlSchedule{
                                        ScheduleType = "Weekly"
                                        CrawlScheduleDaysOfWeek = @("Monday", "Wednesday", "Friday")
                                        StartHour = "3"
                                        StartMinute = "0"
                                       }
                Priority             = "Normal"
                Ensure               = "Present"
                PsDscRunAsCredential = $SetupAccount
            }
        }
    }
