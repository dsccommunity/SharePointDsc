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
        $InstallAccount
    )

    Write-Verbose "Getting web application '$Name'"
    $session = Get-xSharePointAuthenticatedPSSession $InstallAccount

    $result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        $wa = Get-SPWebApplication $params.Name -ErrorAction SilentlyContinue
        if ($wa -eq $null) { return @{} }
        
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
        $AllowAnonymous,

        [ValidateSet("NTLM","Kerberos")]
        [System.String]
        $AuthenticationMethod,

        [System.String]
        $DatabaseName,

        [System.String]
        $DatabaseServer,

        [System.String]
        $HostHeader,

        [System.String]
        $Path,

        [System.String]
        $Port,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose "Creating web application '$Name'"

    $session = Get-xSharePointAuthenticatedPSSession $InstallAccount

    $result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        if ([string]::IsNullOrEmpty($params.AuthenticationMethod) -eq $false) 
        {
            if ($AuthenticationMethod -eq "NTLM") {
                $ap = New-SPAuthenticationProvider -UseWindowsIntegratedAuthentication -DisableKerberos
                $params.Add("AuthenticationProvider", $ap)
            } else {
                $ap = New-SPAuthenticationProvider -UseWindowsIntegratedAuthentication
                $params.Add("AuthenticationProvider", $ap)
            }
        }

        $wa = Get-SPWebApplication $params.Name -ErrorAction SilentlyContinue
        if ($wa -eq $null) { 
            $params.Remove("InstallAccount") | Out-Null
            if ($params.ContainsKey("AuthenticationMethod")) { $params.Remove("AuthenticationMethod") | Out-Null }
            if ($params.ContainsKey("AllowAnonymous")) { 
                $params.Remove("AllowAnonymous") | Out-Null 
                $params.Add("AllowAnonymousAccess", $true)
            }

            New-SPWebApplication @params
        }
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
        $AllowAnonymous,

        [ValidateSet("NTLM","Kerberos")]
        [System.String]
        $AuthenticationMethod,

        [System.String]
        $DatabaseName,

        [System.String]
        $DatabaseServer,

        [System.String]
        $HostHeader,

        [System.String]
        $Path,

        [System.String]
        $Port,

        [System.Management.Automation.PSCredential]
        [parameter(Mandatory = $true)]
        $InstallAccount
    )

    $result = Get-TargetResource -Name $Name -ApplicationPool $ApplicationPool -ApplicationPoolAccount $ApplicationPoolAccount -Url $Url -InstallAccount $InstallAccount
    Write-Verbose "Testing for web application '$Name'"
    if ($result.Count -eq 0) { return $false }
    else {
        if ($result.ApplicationPool -ne $ApplicationPool) { return $false }
        if ($result.ApplicationPoolAccount -ne $ApplicationPoolAccount) { return $false  }
    }
    return $true
}


Export-ModuleMember -Function *-TargetResource

