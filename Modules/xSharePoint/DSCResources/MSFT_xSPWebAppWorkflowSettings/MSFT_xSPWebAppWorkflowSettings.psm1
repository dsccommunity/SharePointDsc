function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $Url,
        [parameter(Mandatory = $false)] [System.Boolean] $ExternalWorkflowParticipantsEnabled,
        [parameter(Mandatory = $false)] [System.Boolean] $UserDefinedWorkflowsEnabled,
        [parameter(Mandatory = $false)] [System.Boolean] $EmailToNoPermissionWorkflowParticipantsEnable,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Getting web application '$url' workflow settings"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments @($PSBoundParameters,$PSScriptRoot) -ScriptBlock {
        $params = $args[0]
        $ScriptRoot = $args[1]
        
        
        $wa = Get-SPWebApplication -Identity $params.Url -ErrorAction SilentlyContinue
        if ($null -eq $wa) { return $null }

        Import-Module (Join-Path $ScriptRoot "..\..\Modules\xSharePoint.WebApplication\xSPWebApplication.Workflow.psm1" -Resolve)

        $result = Get-xSPWebApplicationWorkflowSettings -WebApplication $wa
        $result.Add("Url", $params.Url)
        $result.Add("InstallAccount", $params.InstallAccount)
        return $result
    }
    return $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $Url,
        [parameter(Mandatory = $false)] [System.Boolean] $ExternalWorkflowParticipantsEnabled,
        [parameter(Mandatory = $false)] [System.Boolean] $UserDefinedWorkflowsEnabled,
        [parameter(Mandatory = $false)] [System.Boolean] $EmailToNoPermissionWorkflowParticipantsEnable,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Setting web application '$Url' workflow settings"
    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments @($PSBoundParameters,$PSScriptRoot) -ScriptBlock {
        $params = $args[0]
        $ScriptRoot = $args[1]

        $wa = Get-SPWebApplication -Identity $params.Url -ErrorAction SilentlyContinue
        if ($null -eq $wa) {
            throw "Web application $($params.Url) was not found"
            return
        }

        Import-Module (Join-Path $ScriptRoot "..\..\Modules\xSharePoint.WebApplication\xSPWebApplication.Workflow.psm1" -Resolve)
        Set-xSPWebApplicationWorkflowSettings -WebApplication $wa -Settings $params
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $Url,
        [parameter(Mandatory = $false)] [System.Boolean] $ExternalWorkflowParticipantsEnabled,
        [parameter(Mandatory = $false)] [System.Boolean] $UserDefinedWorkflowsEnabled,
        [parameter(Mandatory = $false)] [System.Boolean] $EmailToNoPermissionWorkflowParticipantsEnable,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing for web application '$Url' workflow settings"
    if ($null -eq $CurrentValues) { return $false }

    Import-Module (Join-Path $PSScriptRoot "..\..\Modules\xSharePoint.WebApplication\xSPWebApplication.Workflow.psm1" -Resolve)
    return Test-xSPWebApplicationWorkflowSettings -CurrentSettings $CurrentValues -DesiredSettings $PSBoundParameters
}


Export-ModuleMember -Function *-TargetResource

