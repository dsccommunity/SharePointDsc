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
        $ServiceAccount,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting service application pool '$Name'"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $sap = Invoke-xSharePointSPCmdlet -CmdletName "Get-SPServiceApplicationPool" -Arguments @{ Identity = $params.Name } -ErrorAction SilentlyContinue
        if ($null -eq $sap) { return @{} }
        
        return @{
            Name = $sap.Name
            ProcessAccountName = $sap.ProcessAccountName
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
        $ServiceAccount,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Creating service application pool '$Name'"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $sap = Invoke-xSharePointSPCmdlet -CmdletName "Get-SPServiceApplicationPool" -Arguments @{ Identity = $params.Name } -ErrorAction SilentlyContinue
        if ($null -eq $sap) { 
            Invoke-xSharePointSPCmdlet -CmdletName "New-SPServiceApplicationPool" -Arguments @{
				Name = $params.Name 
				Account = $params.ServiceAccount
			}
        } else {
            if ($sap.ProcessAccountName -ne $params.ServiceAccount) {  
                Invoke-xSharePointSPCmdlet -CmdletName "Set-SPServiceApplicationPool" -Arguments @{
					Identity = $params.Name 
					Account = $params.ServiceAccount
				}
            }
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
        $ServiceAccount,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    $result = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing service application pool '$Name'"
    if ($result.Count -eq 0) { return $false }
    else {
        if ($ServiceAccount -ne $result.ProcessAccountName) { return $false }
    }
    return $true
}


Export-ModuleMember -Function *-TargetResource

