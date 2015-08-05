function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

        [parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPoolAccount,

        [parameter(Mandatory = $true)]
        [System.String]
        $Url,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [System.Boolean]
        $UserDefinedWorkflowsEnabled,

        [System.Boolean]
        $EmailToNoPermissionWorkflowParticipantsEnabled,

        [System.Boolean]
        $ExternalWorkflowParticipantsEnabled,
        
        [System.UInt32]
        $MaxItemsPerThrottledOperation,

        [System.Boolean]
        $AllowOMCodeOverrideThrottleSettings,

        [System.UInt32]
        $MaxItemsPerThrottledOperationOverride,

        [System.UInt32]
        $MaxQueryLookupFields,

        [System.Boolean]
        $UnthrottledPrivilegedOperationWindowEnabled,

        [System.UInt32]
        $DailyStartUnthrottledPrivilegedOperationsHour,

        [System.UInt32]
        $DailyStartUnthrottledPrivilegedOperationsMinute,

        [System.UInt32]
        $DailyUnthrottledPrivilegedOperationsDuration,

        [System.UInt32]
        $MaxUniquePermScopesPerList,

        [System.Boolean]
        $EventHandlersEnabled,

        [System.Boolean]
        $HttpThrottleEnabled,

        [System.Boolean]
        $ChangeLogExpirationEnabled,

        [System.UInt32]
        $ChangeLogRetentionPeriodInDays
    )

    Write-Verbose -Message "Getting web application '$Name'"
    $session = Get-xSharePointAuthenticatedPSSession -Credential $InstallAccount

    $result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        $wa = Get-SPWebApplication $params.Name -ErrorAction SilentlyContinue
        if ($null -eq $wa) { return @{} }
        
        return @{
            Name = $wa.DisplayName
            ApplicationPool = $wa.ApplicationPool.Name
            ApplicationPoolAccount = $wa.ApplicationPool.Username
        }
    }
    $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

        [parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPoolAccount,

        [parameter(Mandatory = $true)]
        [System.String]
        $Url,

        [System.Boolean]
        $AllowAnonymous = $false,

        [ValidateSet("NTLM","Kerberos")]
        [System.String]
        $AuthenticationMethod = "NTLM",

        [System.String]
        $DatabaseName = $null,

        [System.String]
        $DatabaseServer = $null,

        [System.String]
        $HostHeader = $null,

        [System.String]
        $Path = $null,

        [System.String]
        $Port = $null,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        <# Workflow Settings #>

        [System.Boolean]
        $UserDefinedWorkflowsEnabled = $true,

        [System.Boolean]
        $EmailToNoPermissionWorkflowParticipantsEnabled = $true,

        [System.Boolean]
        $ExternalWorkflowParticipantsEnabled = $false,

        <# Resource Throttling Settings #>

        [System.UInt32]
        $MaxItemsPerThrottledOperation = 5000,

        [System.Boolean]
        $AllowOMCodeOverrideThrottleSettings = $true,

        [System.UInt32]
        $MaxItemsPerThrottledOperationOverride = 20000,

        [System.UInt32]
        $MaxQueryLookupFields = 12,

        [System.Boolean]
        $UnthrottledPrivilegedOperationWindowEnabled = $false,

        [System.UInt32]
        $DailyStartUnthrottledPrivilegedOperationsHour = 22,

        [System.UInt32]
        $DailyStartUnthrottledPrivilegedOperationsMinute = 0,

        [System.UInt32]
        $DailyUnthrottledPrivilegedOperationsDuration = 0,

        [System.UInt32]
        $MaxUniquePermScopesPerList = 50000,

        [System.Boolean]
        $EventHandlersEnabled = $false,

        [System.Boolean]
        $HttpThrottleEnabled = $true,

        [System.Boolean]
        $ChangeLogExpirationEnabled = $true,

        [System.UInt32]
        $ChangeLogRetentionPeriodInDays = 60
    )

    Write-Verbose -Message "Creating web application '$Name'"

    $session = Get-xSharePointAuthenticatedPSSession -Credential $InstallAccount
    
    $PSBoundParameters | Add-Variable UserDefinedWorkflowsEnabled, EmailToNoPermissionWorkflowParticipantsEnabled, ExternalWorkflowParticipantsEnabled, MaxItemsPerThrottledOperation, AllowOMCodeOverrideThrottleSettings, MaxItemsPerThrottledOperationOverride, MaxQueryLookupFields, UnthrottledPrivilegedOperationWindowEnabled, DailyStartUnthrottledPrivilegedOperationsHour, DailyStartUnthrottledPrivilegedOperationsMinute, DailyUnthrottledPrivilegedOperationsDuration, MaxUniquePermScopesPerList, EventHandlersEnabled, HttpThrottleEnabled, ChangeLogExpirationEnabled, ChangeLogRetentionPeriodInDays

    Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        if ($AuthenticationMethod -eq "NTLM") {
            $ap = New-SPAuthenticationProvider -UseWindowsIntegratedAuthentication -DisableKerberos
            $params.Add("AuthenticationProvider", $ap)
        } else {
            $ap = New-SPAuthenticationProvider -UseWindowsIntegratedAuthentication
            $params.Add("AuthenticationProvider", $ap)
        }

        $wa = Get-SPWebApplication $params.Name -ErrorAction SilentlyContinue
        if ($null -eq $wa) { 

            $ParamUserDefinedWorkflowsEnabled = $params.UserDefinedWorkflowsEnabled
            $ParamEmailToNoPermissionWorkflowParticipantsEnabled = $params.EmailToNoPermissionWorkflowParticipantsEnabled
            $ParamExternalWorkflowParticipantsEnabled = $params.ExternalWorkflowParticipantsEnabled

            $ParamMaxItemsPerThrottledOperation = $params.MaxItemsPerThrottledOperation 
            $ParamAllowOMCodeOverrideThrottleSettings = $params.AllowOMCodeOverrideThrottleSettings
            $ParamMaxItemsPerThrottledOperationOverride = $params.MaxItemsPerThrottledOperationOverride
            $ParamMaxQueryLookupFields = $params.MaxQueryLookupFields
            $ParamUnthrottledPrivilegedOperationWindowEnabled = $params.UnthrottledPrivilegedOperationWindowEnabled
            $ParamDailyStartUnthrottledPrivilegedOperationsHour = $params.DailyStartUnthrottledPrivilegedOperationsHour
            $ParamDailyStartUnthrottledPrivilegedOperationsMinute = $params.DailyStartUnthrottledPrivilegedOperationsMinute
            $ParamDailyUnthrottledPrivilegedOperationsDuration = $params.DailyUnthrottledPrivilegedOperationsDuration
            $ParamMaxUniquePermScopesPerList = $params.MaxUniquePermScopesPerList
            $ParamEventHandlersEnabled = $params.EventHandlersEnabled
            $ParamHttpThrottleSettings = $params.HttpThrottleEnabled
            $ParamChangeLogExpirationEnabled = $params.ChangeLogExpirationEnabled
            $ParamChangeLogRetentionPeriodInDays = $params.ChangeLogRetentionPeriodInDays

            $params.Remove("InstallAccount") | Out-Null
            if ($params.ContainsKey("UserDefinedWorkflowsEnabled")) {$params.Remove("UserDefinedWorkflowsEnabled") | Out-Null}
            if ($params.ContainsKey("EmailToNoPermissionWorkflowParticipantsEnabled")) {$params.Remove("EmailToNoPermissionWorkflowParticipantsEnabled") | Out-Null}
            if ($params.ContainsKey("ExternalWorkflowParticipantsEnabled")) {$params.Remove("ExternalWorkflowParticipantsEnabled") | Out-Null}

            if ($params.ContainsKey("MaxItemsPerThrottledOperation")) {$params.Remove("MaxItemsPerThrottledOperation") | Out-Null}
            if ($params.ContainsKey("AllowOMCodeOverrideThrottleSettings")) {$params.Remove("AllowOMCodeOverrideThrottleSettings") | Out-Null}
            if ($params.ContainsKey("MaxItemsPerThrottledOperationOverride")) {$params.Remove("MaxItemsPerThrottledOperationOverride") | Out-Null}
            if ($params.ContainsKey("MaxQueryLookupFields")) {$params.Remove("MaxQueryLookupFields") | Out-Null}
            if ($params.ContainsKey("UnthrottledPrivilegedOperationWindowEnabled")) {$params.Remove("UnthrottledPrivilegedOperationWindowEnabled") | Out-Null}
            if ($params.ContainsKey("DailyStartUnthrottledPrivilegedOperationsHour")) {$params.Remove("DailyStartUnthrottledPrivilegedOperationsHour") | Out-Null}
            if ($params.ContainsKey("DailyStartUnthrottledPrivilegedOperationsMinute")) {$params.Remove("DailyStartUnthrottledPrivilegedOperationsMinute") | Out-Null}
            if ($params.ContainsKey("DailyUnthrottledPrivilegedOperationsDuration")) {$params.Remove("DailyUnthrottledPrivilegedOperationsDuration") | Out-Null}
            if ($params.ContainsKey("MaxUniquePermScopesPerList")) {$params.Remove("MaxUniquePermScopesPerList") | Out-Null}
            if ($params.ContainsKey("EventHandlersEnabled")) {$params.Remove("EventHandlersEnabled") | Out-Null}
            if ($params.ContainsKey("HttpThrottleEnabled")) {$params.Remove("HttpThrottleEnabled") | Out-Null}
            if ($params.ContainsKey("ChangeLogExpirationEnabled")) {$params.Remove("ChangeLogExpirationEnabled") | Out-Null}
            if ($params.ContainsKey("ChangeLogRetentionPeriodInDays")) {$params.Remove("ChangeLogRetentionPeriodInDays") | Out-Null}

            if ($params.ContainsKey("AuthenticationMethod")) { $params.Remove("AuthenticationMethod") | Out-Null }
            if ($params.ContainsKey("AllowAnonymous")) { 
                $params.Remove("AllowAnonymous") | Out-Null 
                $params.Add("AllowAnonymousAccess", $true)
            }

            $wa = New-SPWebApplication @params

            $wa.UserDefinedWorkflowsEnabled = $ParamUserDefinedWorkflowsEnabled
            $wa.EmailToNoPermissionWorkflowParticipantsEnabled = $ParamEmailToNoPermissionWorkflowParticipantsEnabled
            $wa.ExternalWorkflowParticipantsEnabled = $ParamExternalWorkflowParticipantsEnabled

        
            $wa.MaxItemsPerThrottledOperation = $ParamMaxItemsPerThrottledOperation 
            $wa.AllowOMCodeOverrideThrottleSettings = $ParamAllowOMCodeOverrideThrottleSettings
            $wa.MaxItemsPerThrottledOperationOverride = $ParamMaxItemsPerThrottledOperationOverride
            $wa.MaxQueryLookupFields = $ParamMaxQueryLookupFields
            $wa.UnthrottledPrivilegedOperationWindowEnabled = $ParamUnthrottledPrivilegedOperationWindowEnabled
            $wa.DailyStartUnthrottledPrivilegedOperationsHour = $ParamDailyStartUnthrottledPrivilegedOperationsHour
            $wa.DailyStartUnthrottledPrivilegedOperationsMinute = $ParamDailyStartUnthrottledPrivilegedOperationsMinute
            $wa.DailyUnthrottledPrivilegedOperationsDuration = $ParamDailyUnthrottledPrivilegedOperationsDuration
            $wa.MaxUniquePermScopesPerList = $ParamMaxUniquePermScopesPerList
            $wa.EventHandlersEnabled = $ParamEventHandlersEnabled
            $wa.HttpThrottleSettings.PerformThrottle = $ParamHttpThrottleEnabled
            $wa.ChangeLogExpirationEnabled = $ParamChangeLogExpirationEnabled
            $wa.ChangeLogRetentionPeriod = New-TimeSpan -Days $ParamChangeLogRetentionPeriodInDays

            $wa.Update()
        }        
    }
}

function Add-Variable {
    param(
        [Parameter(Position = 0)]
        [AllowEmptyCollection()]
        [string[]] $Name = @(),
        [Parameter(Position = 1, ValueFromPipeline, Mandatory)]
        $InputObject
    )

    $Name |
    ? {-not $InputObject.ContainsKey($_)} |
    % {$InputObject.Add($_, (gv $_ -Scope 1 -ValueOnly))}
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

        [parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPoolAccount,

        [parameter(Mandatory = $true)]
        [System.String]
        $Url,

        [System.Boolean]
        $AllowAnonymous = $false,

        [ValidateSet("NTLM","Kerberos")]
        [System.String]
        $AuthenticationMethod = "NTLM",

        [System.String]
        $DatabaseName = $null,

        [System.String]
        $DatabaseServer = $null,

        [System.String]
        $HostHeader = $null,

        [System.String]
        $Path = $null,

        [System.String]
        $Port = $null,

        [System.Management.Automation.PSCredential]
        [parameter(Mandatory = $true)]
        $InstallAccount,

        [System.Boolean]
        $UserDefinedWorkflowsEnabled = $true,

        [System.Boolean]
        $EmailToNoPermissionWorkflowParticipantsEnabled = $true,

        [System.Boolean]
        $ExternalWorkflowParticipantsEnabled = $false,

        [System.UInt32]
        $MaxItemsPerThrottledOperation = 5000,

        [System.Boolean]
        $AllowOMCodeOverrideThrottleSettings = $true,

        [System.UInt32]
        $MaxItemsPerThrottledOperationOverride = 20000,

        [System.UInt32]
        $MaxQueryLookupFields = 12,

        [System.Boolean]
        $UnthrottledPrivilegedOperationWindowEnabled = $false,

        [System.UInt32]
        $DailyStartUnthrottledPrivilegedOperationsHour = 22,

        [System.UInt32]
        $DailyStartUnthrottledPrivilegedOperationsMinute = 0,

        [System.UInt32]
        $DailyUnthrottledPrivilegedOperationsDuration = 0,

        [System.UInt32]
        $MaxUniquePermScopesPerList = 50000,

        [System.Boolean]
        $EventHandlersEnabled = $false,

        [System.Boolean]
        $HttpThrottleEnabled = $true,

        [System.Boolean]
        $ChangeLogExpirationEnabled = $true,

        [System.UInt32]
        $ChangeLogRetentionPeriodInDays = 60
    )

    $result = Get-TargetResource -Name $Name -ApplicationPool $ApplicationPool -ApplicationPoolAccount $ApplicationPoolAccount -Url $Url -InstallAccount $InstallAccount -UserDefinedWorkflowsEnabled $UserDefinedWorkflowsEnabled -EmailToNoPermissionWorkflowParticipantsEnabled $EmailToNoPermissionWorkflowParticipantsEnabled -ExternalWorkflowParticipantsEnabled $ExternalWorkflowParticipantsEnabled -MaxItemsPerThrottledOperation $MaxItemsPerThrottledOperation -AllowOMCodeOverrideThrottleSettings $AllowOMCodeOverrideThrottleSettings -MaxItemsPerThrottledOperationOverride $MaxItemsPerThrottledOperationOverride -MaxQueryLookupFields $MaxQueryLookupFields -UnthrottledPrivilegedOperationWindowEnabled $UnthrottledPrivilegedOperationWindowEnabled -DailyStartUnthrottledPrivilegedOperationsHour $DailyStartUnthrottledPrivilegedOperationsHour -DailyStartUnthrottledPrivilegedOperationsMinute $DailyStartUnthrottledPrivilegedOperationsMinute -DailyUnthrottledPrivilegedOperationsDuration $DailyUnthrottledPrivilegedOperationsDuration -MaxUniquePermScopesPerList $MaxUniquePermScopesPerList -EventHandlersEnabled $EventHandlersEnabled -HttpThrottleEnabled $HttpThrottleEnabled -ChangeLogExpirationEnabled $ChangeLogExpirationEnabled -ChangeLogRetentionPeriodInDays $ChangeLogRetentionPeriodInDays
    Write-Verbose -Message "Testing for web application '$Name'"
    if ($result.Count -eq 0) { return $false }
    else {
        if ($result.ApplicationPool -ne $ApplicationPool) { return $false }
        if ($result.ApplicationPoolAccount -ne $ApplicationPoolAccount) { return $false  }
    }
    return $true
}


Export-ModuleMember -Function *-TargetResource