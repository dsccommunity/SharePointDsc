#
# Set_ValidResource.ps1
#
    $cred = get-credential
    @{"bla" ="1"  
    app="1" }

Import-Module C:\Users\camilo.CONTOSO\Source\Repos\xSharePoint\Modules\xSharePoint\DSCResources\MSFT_xSPWorkManagementServiceApp\MSFT_xSPWorkManagementServiceApp.psm1
Get-TargetResource   {
                Name = "Work Management Service Application"
                ApplicationPool = "SharePoint Web Services System"
                MinimumTimeBetweenEwsSyncSubscriptionSearches = 10 
                MinimumTimeBetweenProviderRefreshes = 9        
                MinimumTimeBetweenSearchQueries=8
                NumberOfSubscriptionSyncsPerEwsSyncRun=7
                NumberOfUsersEwsSyncWillProcessAtOnce=6
                NumberOfUsersPerEwsSyncBatch=5
                Ensure="Present"
               InstallAccount = $cred
             }

Set-TargetResource   {
                Name = "Work Management Service Application"
                ApplicationPool = "SharePoint Web Services System"
                MinimumTimeBetweenEwsSyncSubscriptionSearches = 10 
                MinimumTimeBetweenProviderRefreshes = 9        
                MinimumTimeBetweenSearchQueries=8
                NumberOfSubscriptionSyncsPerEwsSyncRun=7
                NumberOfUsersEwsSyncWillProcessAtOnce=6
                NumberOfUsersPerEwsSyncBatch=5
                Ensure="Present"
               InstallAccount = $cred
             }