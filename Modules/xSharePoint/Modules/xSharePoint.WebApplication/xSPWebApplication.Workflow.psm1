function Get-xSPWebApplicationWorkflowSettings {
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

function Set-xSPWebApplicationWorkflowSettings {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)] $WebApplication,
        [parameter(Mandatory = $true)] $Settings
    )
    if($Settings.UserDefinedWorkflowsEnabled -ne $null){
        $WebApplication.UserDefinedWorkflowsEnabled =  $Settings.UserDefinedWorkflowsEnabled;
    }
    if($Settings.EmailToNoPermissionWorkflowParticipantsEnable -ne $null){
        $WebApplication.EmailToNoPermissionWorkflowParticipantsEnabled = $Settings.EmailToNoPermissionWorkflowParticipantsEnable;
    }
    if($Settings.ExternalWorkflowParticipantsEnabled -ne $null){
        $WebApplication.ExternalWorkflowParticipantsEnabled = $Settings.ExternalWorkflowParticipantsEnabled;
    }                
    $WebApplication.UpdateWorkflowConfigurationSettings();
}

function Test-xSPWebApplicationWorkflowSettings {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [parameter(Mandatory = $true)] $CurrentSettings,
        [parameter(Mandatory = $true)] $DesiredSettings
    )

    $testReturn = Test-xSharePointSpecificParameters -CurrentValues $CurrentSettings `
                                                     -DesiredValues $DesiredSettings
    return $testReturn
}

