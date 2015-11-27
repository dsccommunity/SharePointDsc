function GetAndRemove-Parameter($params, $name){
    $result =$null
    if($params.ContainsKey($name))
    {
        $result = $params.$name 
        $params.Remove( $name)
    }
    return $result;
}
function Sanitize-ComplexTypes{
   param(
        [Parameter(Position = 0)]
        $params
    )
    return @{
        GeneralSettings  = GetAndRemove-Parameter $params "GeneralSettings"
        WorkflowSettings = GetAndRemove-Parameter $params "WorkflowSettings"
        Extensions = GetAndRemove-Parameter $params "Extensions"
        ThrottlingSettings = GetAndRemove-Parameter $params "ThrottlingSettings"
        BlockedFileTypes = GetAndRemove-Parameter $params "BlockedFileTypes"
    }
}

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $Name,
        [parameter(Mandatory = $true)]  [System.String]  $ApplicationPool,
        [parameter(Mandatory = $true)]  [System.String]  $ApplicationPoolAccount,
        [parameter(Mandatory = $true)]  [System.String]  $Url,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowAnonymous,
        [parameter(Mandatory = $false)] [System.String]  $DatabaseName,
        [parameter(Mandatory = $false)] [System.String]  $DatabaseServer,
        [parameter(Mandatory = $false)] [System.String]  $HostHeader,
        [parameter(Mandatory = $false)] [System.String]  $Path,
        [parameter(Mandatory = $false)] [System.String]  $Port,
        [parameter(Mandatory = $false)] [ValidateSet("NTLM","Kerberos")] [System.String] $AuthenticationMethod,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $false)]  $GeneralSettings,
        [parameter(Mandatory = $false)] $WorkflowSettings,
        [parameter(Mandatory = $false)] $ThrottlingSettings,
        [parameter(Mandatory = $false)] $BlockedFileTypes
    )

    Write-Verbose -Message "Getting web application '$Name'"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
        
        $wa = Get-SPWebApplication -Identity $params.Name -ErrorAction SilentlyContinue
        if ($null -eq $wa) { return $null }

        $authProvider = Get-SPAuthenticationProvider -WebApplication $wa.Url -Zone "Default" 

        if ($authProvider.DisableKerberos -eq $true) { $localAuthMode = "NTLM" } else { $localAuthMode = "Kerberos" }

        return @{
            Name = $wa.DisplayName
            ApplicationPool = $wa.ApplicationPool.Name
            ApplicationPoolAccount = $wa.ApplicationPool.Username
            Url = $wa.Url
            AllowAnonymous = $authProvider.AllowAnonymous
            DatabaseName = $wa.ContentDatabases[0].Name
            DatabaseServer = $wa.ContentDatabases[0].Server
            HostHeader = (New-Object System.Uri $wa.Url).Host
            Path = $wa.IisSettings[0].Path
            Port = (New-Object System.Uri $wa.Url).Port
            AuthenticationMethod = $localAuthMode
            InstallAccount = $params.InstallAccount
        }
    }
    return $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $Name,
        [parameter(Mandatory = $true)]  [System.String]  $ApplicationPool,
        [parameter(Mandatory = $true)]  [System.String]  $ApplicationPoolAccount,
        [parameter(Mandatory = $true)]  [System.String]  $Url,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowAnonymous,
        [parameter(Mandatory = $false)] [System.String]  $DatabaseName,
        [parameter(Mandatory = $false)] [System.String]  $DatabaseServer,
        [parameter(Mandatory = $false)] [System.String]  $HostHeader,
        [parameter(Mandatory = $false)] [System.String]  $Path,
        [parameter(Mandatory = $false)] [System.String]  $Port,
        [parameter(Mandatory = $false)] [ValidateSet("NTLM","Kerberos")] [System.String] $AuthenticationMethod,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $false)]  $GeneralSettings,
        [parameter(Mandatory = $false)] $WorkflowSettings,
        [parameter(Mandatory = $false)] $ThrottlingSettings,
        [parameter(Mandatory = $false)] $BlockedFileTypes
    )

    Write-Verbose -Message "Creating web application '$Name'"
    $settings =  Sanitize-ComplexTypes $PSBoundParameters 
    $PSBoundParameters.Add("Settings", $settings)
    Write-Verbose -Message "Creating web application '$Name'"
    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $settings =$params.Settings
        $params.Remove("Settings") | Out-Null
        $wa = Get-SPWebApplication -Identity $params.Name -ErrorAction SilentlyContinue
        if ($null -eq $wa) {
            if ($params.ContainsKey("AuthenticationMethod") -eq $true) {
                if ($params.AuthenticationMethod -eq "NTLM") {
                    $ap = New-SPAuthenticationProvider -UseWindowsIntegratedAuthentication -DisableKerberos 
                } else {
                    $ap = New-SPAuthenticationProvider -UseWindowsIntegratedAuthentication
                }
                $params.Remove("AuthenticationMethod")
                $params.Add("AuthenticationProvider", $ap)
            }
             
            if ($params.ContainsKey("InstallAccount")) { $params.Remove("InstallAccount") | Out-Null }
            if ($params.ContainsKey("AllowAnonymous")) { 
                $params.Remove("AllowAnonymous") | Out-Null 
                $params.Add("AllowAnonymousAccess", $true)
            }
         
            $wa = New-SPWebApplication @params
        }
#region throttling settings

        $throttlingSettings = $settings.ThrottlingSettings

        if($throttlingSettings -ne $null){ 
            if($throttlingSettings.ListViewThreshold -ne $null ){
                $wa.MaxItemsPerThrottledOperation = $throttlingSettings.ListViewThreshold
            }
            if($throttlingSettings.AllowObjectModelOverride -ne $null){
                $wa.AllowOMCodeOverrideThrottleSettings =  $throttlingSettings.AllowObjectModelOverride
            }
            if($throttlingSettings.AdminThreshold -ne $null){
                $wa.MaxItemsPerThrottledOperationOverride = $throttlingSettings.AdminThreshold
            }
            if($throttlingSettings.ListViewLookupThreshold -ne $null){
                $wa.MaxQueryLookupFields =  $throttlingSettings.ListViewLookupThreshold
            }
            if($throttlingSettings.HappyHourEnabled -ne $null){
                $wa.UnthrottledPrivilegedOperationWindowEnabled =$throttlingSettings.HappyHourEnabled
            }
            if($throttlingSettings.HappyHour -ne $null){
                $happyHour =$throttlingSettings.HappyHour;
                if(($happyHour.Hour -ne $null) -and ($happyHour.Minute -ne $null) -and ($happyHour.Duration -ne $null)){
                    if(($happyHour.Hour -le 24) -and ($happyHour.Minute -le 24) -and ($happyHour.Duration -le 24)){
                        $wa.DailyStartUnthrottledPrivilegedOperationsHour = $happyHour.Hour 
                        $wa.DailyStartUnthrottledPrivilegedOperationsMinute = $happyHour.Minute
                        $wa.DailyUnthrottledPrivilegedOperationsDuration = $happyHour.Duration
                    }else{
                        throw "the valid  hour, minute and duration range is 0-24";
                        }
                    
                }else {
                    throw "You need to Provide Hour, Minute and Duration when providing HappyHour settings";
                }
            }
            if($throttlingSettings.UniquePermissionThreshold){
                $wa.MaxUniquePermScopesPerList = $throttlingSettings.UniquePermissionThreshold
            }
            if($throttlingSettings.EventHandlersEnabled){
                $wa.EventHandlersEnabled = $throttlingSettings.EventHandlersEnabled
            }
            if($throttlingSettings.RequestThrottling){
                $wa.HttpThrottleSettings.PerformThrottle = $throttlingSettings.RequestThrottling
            }
            if($throttlingSettings.ChangeLogEnabled){
                $wa.ChangeLogExpirationEnabled = $throttlingSettings.ChangeLogEnabled
            }
            if($throttlingSettings.ChangeLogExpiryDays){
                $wa.ChangeLogRetentionPeriod = New-TimeSpan -Days $throttlingSettings.ChangeLogExpiryDays
            }
        }
#endregion
#region WorkflowSettings       
        #Set-WorkflowSettings $settings.WorkflowSettings  $wa
        $workflowSettings = $settings.WorkflowSettings  
        if($workflowSettings -ne $null ){    
            if($workflowSettings.UserDefinedWorkflowsEnabled -ne $null){
                $wa.UserDefinedWorkflowsEnabled =  $workflowSettings.UserDefinedWorkflowsEnabled;
            }
            if($workflowSettings.EmailToNoPermissionWorkflowParticipantsEnable -ne $null){
                $wa.EmailToNoPermissionWorkflowParticipantsEnabled = $workflowSettings.EmailToNoPermissionWorkflowParticipantsEnable;
            }
            if($workflowSettings.ExternalWorkflowParticipantsEnabled -ne $null){
                $wa.ExternalWorkflowParticipantsEnabled = $workflowSettings.ExternalWorkflowParticipantsEnabled;
            }
                
            $wa.UpdateWorkflowConfigurationSettings();
        }
#endregion
        Write-Verbose "applying extended settings"
#region blockedFiles
        $blockedFiles= $settings.BlockedFileTypes  
        if($blockedFiles -ne $null){
            if($blockedFiles.Blocked -ne $null ){
                $wa.BlockedFileExtensions.Clear(); 
                $blockedFiles.Blocked| % {
                    $wa.BlockedFileExtensions.Add($_);

                }
            }
            if($blockedFiles.EnsureBlocked -ne $null){
                $blockedFiles.EnsureBlocked| % {
                    if(!$wa.BlockedFileExtensions.ContainExtension($_)){
                        $wa.BlockedFileExtensions.Add($_);
                    }
                }
            }
            if($blockedFiles.EnsureAllowed -ne $null){
                $blockedFiles.EnsureAllowed | % {
                    if($wa.BlockedFileExtensions.ContainExtension($_)){
                        $wa.BlockedFileExtensions.Remove($_);
                    }
                }
            }
        }

#endregion

#region General settings
            
       $generalSettings = $settings.GeneralSettings   
        if($generalSettings -ne $null){ 
            #TODO: Quota Template
            if($generalSettings.TimeZone -ne $null){
                $wa.DefaultTimeZone =$generalSettings.TimeZone
            }
            if($generalSettings.Alerts -ne $null){
                $wa.AlertsEnabled = $generalSettings.Alerts
            }
            if($generalSettings.AlertsLimit -ne $null){
                $wa.AlertsMaximum = $generalSettings.AlertsLimit
            }
            if($generalSettings.RSS -ne $null){
                $wa.SyndicationEnabled = $generalSettings.RSS
            }
            if($generalSettings.AlertsLimit){
                $wa.MetaWeblogEnabled = $generalSettings.BlogAPI
            }
            if($generalSettings.BlogAPIAuthenticated){
                $wa.MetaWeblogAuthenticationEnabled = $generalSettings.BlogAPIAuthenticated
            }
            if($generalSettings.BrowserFileHandling){
                $wa.BrowserFileHandling = $generalSettings.BrowserFileHandling
            }
            if($generalSettings.SecurityValidation){
                $wa.FormDigestSettings.Enabled = $generalSettings.SecurityValidation
            }
            if($generalSettings.MaximumUploadSize){
                $wa.MaximumFileSize = $generalSettings.MaximumUploadSize
            }
            if($generalSettings.RecycleBinEnabled){
                $wa.RecycleBinEnabled = $generalSettings.RecycleBinEnabled
            }
            if($generalSettings.RecycleBinCleanupEnabled){
                $wa.RecycleBinCleanupEnabled =  $generalSettings.RecycleBinCleanupEnabled
            }
            if($generalSettings.RecycleBinRetentionPeriod){
                $wa.RecycleBinRetentionPeriod = $generalSettings.RecycleBinRetentionPeriod
            }
            if($generalSettings.SecondStageRecycleBinEnabled){
                $wa.SecondStageRecycleBinQuota = $generalSettings.SecondStageRecycleBinEnabled
            }
            if($generalSettings.CustomerExperienceProgram){
                $wa.BrowserCEIPEnabled = $generalSettings.CustomerExperienceProgram
             }
            if($generalSettings.Presence -ne $null){
                $wa.PresenceEnabled =  $generalSettings.Presence
            }
        }
        if( ($settings.WorkflowSettings -ne $null) -or
            ($settings.GeneralSettings -ne $null) -or
            ($settings.ThrottlingSettings -ne $null) -or
            ($settings.BlockedFileTypes -ne $null) 
            ){
                $wa.Update()
            }
#endregion
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $Name,
        [parameter(Mandatory = $true)]  [System.String]  $ApplicationPool,
        [parameter(Mandatory = $true)]  [System.String]  $ApplicationPoolAccount,
        [parameter(Mandatory = $true)]  [System.String]  $Url,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowAnonymous,
        [parameter(Mandatory = $false)] [System.String]  $DatabaseName,
        [parameter(Mandatory = $false)] [System.String]  $DatabaseServer,
        [parameter(Mandatory = $false)] [System.String]  $HostHeader,
        [parameter(Mandatory = $false)] [System.String]  $Path,
        [parameter(Mandatory = $false)] [System.String]  $Port,
        [parameter(Mandatory = $false)] [ValidateSet("NTLM","Kerberos")] [System.String] $AuthenticationMethod,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $false)]  $GeneralSettings,
        [parameter(Mandatory = $false)] $WorkflowSettings,
        [parameter(Mandatory = $false)] $ThrottlingSettings,
        [parameter(Mandatory = $false)] $BlockedFileTypes
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing for web application '$Name'"
    if ($null -eq $CurrentValues) { return $false }
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("ApplicationPool")
}


Export-ModuleMember -Function *-TargetResource

