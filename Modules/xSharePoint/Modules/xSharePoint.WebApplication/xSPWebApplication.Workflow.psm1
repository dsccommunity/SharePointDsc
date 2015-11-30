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
        [parameter(Mandatory = $true)] [Microsoft.Management.Infrastructure.CimInstance] $Settings
    )
    if((Test-xSharePointObjectHasProperty $Settings "UserDefinedWorkflowsEnabled") -eq $true) {
        $WebApplication.UserDefinedWorkflowsEnabled =  $Settings.UserDefinedWorkflowsEnabled;
    }
    if((Test-xSharePointObjectHasProperty $Settings "EmailToNoPermissionWorkflowParticipantsEnable") -eq $true) {
        $WebApplication.EmailToNoPermissionWorkflowParticipantsEnabled = $Settings.EmailToNoPermissionWorkflowParticipantsEnable;
    }
    if((Test-xSharePointObjectHasProperty $Settings "ExternalWorkflowParticipantsEnabled") -eq $true) {
        $WebApplication.ExternalWorkflowParticipantsEnabled = $Settings.ExternalWorkflowParticipantsEnabled;
    }                
    $WebApplication.UpdateWorkflowConfigurationSettings();
}

function Test-xSPWebApplicationWorkflowSettings {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [parameter(Mandatory = $true)] $CurrentSettings,
        [parameter(Mandatory = $true)] [Microsoft.Management.Infrastructure.CimInstance] $DesiredSettings
    )

    $testReturn = Test-xSharePointSpecificParameters -CurrentValues $CurrentSettings `
                                                     -DesiredValues $DesiredSettings `
                                                     -ValuesToCheck @("UserDefinedWorkflowsEnabled","EmailToNoPermissionWorkflowParticipantsEnable","ExternalWorkflowParticipantsEnabled")
    return $testReturn
}

