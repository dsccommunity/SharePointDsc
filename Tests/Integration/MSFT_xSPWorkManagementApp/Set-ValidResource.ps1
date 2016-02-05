#
# Set_ValidResource.ps1
#
Configuration WorkManagementServiceApp
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xSharePoint
    $cred = get-credential
    Node  "localhost"
    { 
        xSPWorkManagementServiceApp WorkManagementServiceApp
            {
                Name = "Work Management Service Application"
                ApplicationPool = "SharePoint Web Services System"
                MinimumTimeBetweenEwsSyncSubscriptionSearches = 10 
                MinimumTimeBetweenProviderRefreshes = 9        
                MinimumTimeBetweenSearchQueries=8
                NumberOfSubscriptionSyncsPerEwsSyncRun=7
                NumberOfUsersEwsSyncWillProcessAtOnce=6
                NumberOfUsersPerEwsSyncBatch=5
                Ensure="Present"
                PsDscRunAsCredential = $cred
             }
    }
}
$ConfigData = @{
        AllNodes = @(
            @{
                NodeName = 'localhost'
                PSDscAllowDomainUser = $true
                PSDscAllowPlainTextPassword = $true
            }
        )
    }
WorkManagementServiceApp -ConfigurationData $ConfigData

Remove-DscConfigurationDocument -Stage Current, Pending, Previous -Verbose
Start-DscConfiguration .\WorkManagementServiceApp -ComputerName "localhost" -Wait -Verbose

