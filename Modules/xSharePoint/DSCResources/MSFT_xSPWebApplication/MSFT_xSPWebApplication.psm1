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
		
		[parameter(Mandatory = $false)]
        [System.Boolean]
        $AllowAnonymous,
		
		[parameter(Mandatory = $false)]
        [ValidateSet("NTLM","Kerberos")]
        [System.String]
        $AuthenticationMethod,
		
		[parameter(Mandatory = $false)]
        [System.String]
        $DatabaseName,
		
		[parameter(Mandatory = $false)]
        [System.String]
        $DatabaseServer,
		
		[parameter(Mandatory = $false)]
        [System.String]
        $HostHeader,
		
		[parameter(Mandatory = $false)]
        [System.String]
        $Path,
		
		[parameter(Mandatory = $false)]
        [System.String]
        $Port,

		[parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting web application '$Name'"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
		$wa = Invoke-xSharePointSPCmdlet -CmdletName "Get-SPWebApplication" -Arguments @{ Identity = $params.Name } -ErrorAction SilentlyContinue
        if ($null -eq $wa) { return @{} }
        
        return @{
            Name = $wa.DisplayName
            ApplicationPool = $wa.ApplicationPool.Name
            ApplicationPoolAccount = $wa.ApplicationPool.Username
        }
    }
    return $result
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
		
		[parameter(Mandatory = $false)]
        [System.Boolean]
        $AllowAnonymous,
		
		[parameter(Mandatory = $false)]
        [ValidateSet("NTLM","Kerberos")]
        [System.String]
        $AuthenticationMethod,
		
		[parameter(Mandatory = $false)]
        [System.String]
        $DatabaseName,
		
		[parameter(Mandatory = $false)]
        [System.String]
        $DatabaseServer,
		
		[parameter(Mandatory = $false)]
        [System.String]
        $HostHeader,
		
		[parameter(Mandatory = $false)]
        [System.String]
        $Path,
		
		[parameter(Mandatory = $false)]
        [System.String]
        $Port,

		[parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Creating web application '$Name'"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        if ($AuthenticationMethod -eq "NTLM") {
            $ap = Invoke-xSharePointSPCmdlet -CmdletName "New-SPAuthenticationProvider" -Arguments @{ 
				UseWindowsIntegratedAuthentication = $true
				DisableKerberos = $true
			}
        } else {
            $ap = Invoke-xSharePointSPCmdlet -CmdletName "New-SPAuthenticationProvider" -Arguments @{ 
				UseWindowsIntegratedAuthentication = $true
			}
        }
		$params.Add("AuthenticationProvider", $ap)

        $wa = Invoke-xSharePointSPCmdlet -CmdletName "Get-SPWebApplication" -Arguments @{ Identity = $params.Name } -ErrorAction SilentlyContinue
        if ($null -eq $wa) { 
            if ($params.ContainsKey("InstallAccount")) { $params.Remove("InstallAccount") | Out-Null }
            if ($params.ContainsKey("AuthenticationMethod")) { $params.Remove("AuthenticationMethod") | Out-Null }
            if ($params.ContainsKey("AllowAnonymous")) { 
                $params.Remove("AllowAnonymous") | Out-Null 
                $params.Add("AllowAnonymousAccess", $true)
            }

            Invoke-xSharePointSPCmdlet -CmdletName "New-SPWebApplication" -Arguments $params
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
		
		[parameter(Mandatory = $false)]
        [System.Boolean]
        $AllowAnonymous,
		
		[parameter(Mandatory = $false)]
        [ValidateSet("NTLM","Kerberos")]
        [System.String]
        $AuthenticationMethod,
		
		[parameter(Mandatory = $false)]
        [System.String]
        $DatabaseName,
		
		[parameter(Mandatory = $false)]
        [System.String]
        $DatabaseServer,
		
		[parameter(Mandatory = $false)]
        [System.String]
        $HostHeader,
		
		[parameter(Mandatory = $false)]
        [System.String]
        $Path,
		
		[parameter(Mandatory = $false)]
        [System.String]
        $Port,

		[parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    $result = Get-TargetResource -Name $Name -ApplicationPool $ApplicationPool -ApplicationPoolAccount $ApplicationPoolAccount -Url $Url -InstallAccount $InstallAccount
    Write-Verbose -Message "Testing for web application '$Name'"
    if ($result.Count -eq 0) { return $false }
    else {
        if ($result.ApplicationPool -ne $ApplicationPool) { return $false }
        if ($result.ApplicationPoolAccount -ne $ApplicationPoolAccount) { return $false  }
    }
    return $true
}


Export-ModuleMember -Function *-TargetResource

