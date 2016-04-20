function Get-SPDSCWebApplicationWorkflowSettings {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [parameter(Mandatory = $true)] $WebApplication
    )
    return @{
        ExternalWorkflowParticipantsEnabled = $WebApplication.ExternalWorkflowParticipantsEnabled
        UserDefinedWorkflowsEnabled = $WebApplication.UserDefinedWorkflowsEnabled
        EmailToNoPermissionWorkflowParticipantsEnable = $WebApplication.EmailToNoPermissionWorkflowParticipantsEnabled
    }
}

function Set-SPDSCWebApplicationWorkflowSettings {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)] $WebApplication,
        [parameter(Mandatory = $true)] $Settings
    )
    if($Settings.ContainsKey("UserDefinedWorkflowsEnabled") -eq $true) {
        $WebApplication.UserDefinedWorkflowsEnabled =  $Settings.UserDefinedWorkflowsEnabled;
    }
    if($Settings.ContainsKey("EmailToNoPermissionWorkflowParticipantsEnable") -eq $true) {
        $WebApplication.EmailToNoPermissionWorkflowParticipantsEnabled = $Settings.EmailToNoPermissionWorkflowParticipantsEnable;
    }
    if($Settings.ContainsKey("ExternalWorkflowParticipantsEnabled") -eq $true) {
        $WebApplication.ExternalWorkflowParticipantsEnabled = $Settings.ExternalWorkflowParticipantsEnabled;
    }                
    $WebApplication.UpdateWorkflowConfigurationSettings();
}

function Test-SPDSCWebApplicationWorkflowSettings {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [parameter(Mandatory = $true)] $CurrentSettings,
        [parameter(Mandatory = $true)] $DesiredSettings
    )
    
    Import-Module (Join-Path $PSScriptRoot "..\..\Modules\SharePointDSC.Util\SharePointDSC.Util.psm1" -Resolve)
    $testReturn = Test-SPDSCSpecificParameters -CurrentValues $CurrentSettings `
                                                     -DesiredValues $DesiredSettings `
                                                     -ValuesToCheck @("UserDefinedWorkflowsEnabled","EmailToNoPermissionWorkflowParticipantsEnable","ExternalWorkflowParticipantsEnabled")
    return $testReturn
}

