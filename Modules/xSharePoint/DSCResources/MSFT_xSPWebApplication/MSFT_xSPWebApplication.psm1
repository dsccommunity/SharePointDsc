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
        $ExternalWorkflowParticipantsEnabled
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

        [System.Boolean]
        $UserDefinedWorkflowsEnabled = $true,

        [System.Boolean]
        $EmailToNoPermissionWorkflowParticipantsEnabled = $true,

        [System.Boolean]
        $ExternalWorkflowParticipantsEnabled = $false
    )

    Write-Verbose -Message "Creating web application '$Name'"

    $session = Get-xSharePointAuthenticatedPSSession -Credential $InstallAccount

    $result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        <# Workflow Settings #>
        $ParamUserDefinedWorkflowsEnabled = $params.UserDefinedWorkflowsEnabled
        $ParamEmailToNoPermissionWorkflowParticipantsEnabled = $params.EmailToNoPermissionWorkflowParticipantsEnabled
        $ParamExternalWorkflowParticipantsEnabled = $params.ExternalWorkflowParticipantsEnabled

        if ($AuthenticationMethod -eq "NTLM") {
            $ap = New-SPAuthenticationProvider -UseWindowsIntegratedAuthentication -DisableKerberos
            $params.Add("AuthenticationProvider", $ap)
        } else {
            $ap = New-SPAuthenticationProvider -UseWindowsIntegratedAuthentication
            $params.Add("AuthenticationProvider", $ap)
        }

        $wa = Get-SPWebApplication $params.Name -ErrorAction SilentlyContinue
        if ($null -eq $wa) { 
            $params.Remove("InstallAccount") | Out-Null
            if ($params.ContainsKey("UserDefinedWorkflowsEnabled")) {$params.Remove("UserDefinedWorkflowsEnabled") | Out-Null}
            if ($params.ContainsKey("EmailToNoPermissionWorkflowParticipantsEnabled")) {$params.Remove("EmailToNoPermissionWorkflowParticipantsEnabled") | Out-Null}
            if ($params.ContainsKey("ExternalWorkflowParticipantsEnabled")) {$params.Remove("ExternalWorkflowParticipantsEnabled") | Out-Null}
            if ($params.ContainsKey("AuthenticationMethod")) { $params.Remove("AuthenticationMethod") | Out-Null }
            if ($params.ContainsKey("AllowAnonymous")) { 
                $params.Remove("AllowAnonymous") | Out-Null 
                $params.Add("AllowAnonymousAccess", $true)
            }

            $wa = New-SPWebApplication @params
        }

        $wa.UserDefinedWorkflowsEnabled = $ParamUserDefinedWorkflowsEnabled
        $wa.EmailToNoPermissionWorkflowParticipantsEnabled = $ParamEmailToNoPermissionWorkflowParticipantsEnabled
        $wa.ExternalWorkflowParticipantsEnabled = $ParamExternalWorkflowParticipantsEnabled
        $wa.Update()
    }
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
        $ExternalWorkflowParticipantsEnabled = $false
    )

    $result = Get-TargetResource -Name $Name -ApplicationPool $ApplicationPool -ApplicationPoolAccount $ApplicationPoolAccount -Url $Url -InstallAccount $InstallAccount -UserDefinedWorkflowsEnabled $UserDefinedWorkflowsEnabled -EmailToNoPermissionWorkflowParticipantsEnabled $EmailToNoPermissionWorkflowParticipantsEnabled -ExternalWorkflowParticipantsEnabled $ExternalWorkflowParticipantsEnabled
    Write-Verbose -Message "Testing for web application '$Name'"
    if ($result.Count -eq 0) { return $false }
    else {
        if ($result.ApplicationPool -ne $ApplicationPool) { return $false }
        if ($result.ApplicationPoolAccount -ne $ApplicationPoolAccount) { return $false  }
    }
    return $true
}


Export-ModuleMember -Function *-TargetResource

