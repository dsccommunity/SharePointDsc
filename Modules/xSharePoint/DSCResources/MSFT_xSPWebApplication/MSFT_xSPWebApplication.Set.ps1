function Set-BlockedFiles($blockedFiles, $wa)
{
    
    if($blockedFiles -eq $null){return;}
    if($blockedFiles.Blocked -ne $null ){
        $wa.BlockedFileExtensions.Clear(); 
        $blockedFiles.Blocked| % {
            $wa.BlockedFileExtensions.Add($_) ;

        }
    }
    if($blockedFiles.EnsureBlocked -ne $null){
        $blockedFiles.EnsureBlocked| % {
            if(!$wa.BlockedFileExtensions.ContainExtension($_)){
                $wa.BlockedFileExtensions.Add($_) ;
            }
        }
    }
    if($blockedFiles.EnsureAllowed -ne $null){
        $blockedFiles.EnsureAllowed | % {
            if($wa.BlockedFileExtensions.ContainExtension($_)){
                $wa.BlockedFileExtensions.Remove($_) 
            }
        }
    }

}
function Get-ValueOrDefault($input, $attribute, $defaultValue)
{
    try{
        if($input."$attribute" -ne $null)
        {
            return $input."$attribute"
        }else {
            return $defaultValue
        }
    }catch
    {
    return $defaultValue
    }
}
function Set-GeneralSettings($generalSettings, $wa)
{
    if($generalSettings -eq $null){ return;}

    #TODO: Quota Template
    $wa.DefaultTimeZone =Get-ValueOrDefault $generalSettings "TimeZone" $wa.DefaultTimeZone
    $wa.AlertsEnabled = Get-ValueOrDefault  $generalSettings "Alerts" $wa.AlertsEnabled
    $wa.AlertsMaximum = Get-ValueOrDefault  $generalSettings "AlertsLimit" $wa.AlertsMaximum
    $wa.SyndicationEnabled = Get-ValueOrDefault  $generalSettings "RSS" $wa.RSS
    $wa.MetaWeblogEnabled = Get-ValueOrDefault  $generalSettings "BlogAPI" $wa.BlogAPI
    $wa.MetaWeblogAuthenticationEnabled = Get-ValueOrDefault  $generalSettings "BlogAPIAuthenticated" $wa.BlogAPIAuthenticated
    $wa.BrowserFileHandling = Get-ValueOrDefault  $generalSettings "BrowserFileHandling" $wa.BrowserFileHandling
    $wa.FormDigestSettings.Enabled = Get-ValueOrDefault  $generalSettings "SecurityValidation" $wa.FormDigestSettings.Enabled 
    $wa.MaximumFileSize = Get-ValueOrDefault  $generalSettings "MaximumUploadSize" $wa.MaximumUploadSize
    $wa.RecycleBinEnabled = Get-ValueOrDefault  $generalSettings "RecycleBinEnabled" $wa.RecycleBinEnabled
    $wa.RecycleBinCleanupEnabled =  Get-ValueOrDefault  $generalSettings "RecycleBinCleanupEnabled" $wa.RecycleBinCleanupEnabled 
    $wa.RecycleBinRetentionPeriod = Get-ValueOrDefault  $generalSettings "RecycleBinRetentionPeriod" $wa.RecycleBinRetentionPeriod
    $wa.SecondStageRecycleBinQuota = Get-ValueOrDefault  $generalSettings "SecondStageRecycleBinEnabled" $wa.SecondStageRecycleBinQuota
    $wa.BrowserCEIPEnabled = Get-ValueOrDefault  $generalSettings "CustomerExperienceProgram" $wa.BrowserCEIPEnabled 
    $wa.PresenceEnabled =  Get-ValueOrDefault  $generalSettings "Presence" $wa.BrowserCEIPEnabled 
    $wa.Update();
}
function Set-WorkflowSettings ($workflowSettings, $wa)
{
    if($workflowSettings -eq $null ){    return;}
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
    $wa.Update();
}

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

$blocked =GetAndRemove-Parameter $params "BlockedFileTypes"
    return @{
        GeneralSettings  = GetAndRemove-Parameter $params "GeneralSettings"
        WorkflowSettings = GetAndRemove-Parameter $params "WorkflowSettings"
        Extensions = GetAndRemove-Parameter $params "Extensions"
        ThrottlingSettings = GetAndRemove-Parameter $params "ThrottlingSettings"
        BlockedFileTypes = $blocked
    }
}


$params = $args[0]

$settings = Sanitize-ComplexTypes $params 
         
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