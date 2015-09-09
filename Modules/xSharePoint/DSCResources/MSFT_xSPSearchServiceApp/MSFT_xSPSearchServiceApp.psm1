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

		[parameter(Mandatory = $false)]
        [System.String]
        $DatabaseServer,

		[parameter(Mandatory = $false)]
        [System.String]
        $DatabaseName,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting Search service application '$Name'"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

		$serviceApp = Get-xSharePointServiceApplication -Name $params.Name -TypeName Search

        If ($null -eq $serviceApp)
        {
            return @{}
        }
        else
        {
            return @{
                Name = $serviceApp.DisplayName
                ApplicationPool = $serviceApp.ApplicationPool.Name
            }
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

		[parameter(Mandatory = $false)]
        [System.String]
        $DatabaseServer,

		[parameter(Mandatory = $false)]
        [System.String]
        $DatabaseName,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    $result = Get-TargetResource @PSBoundParameters

    if ($result.Count -eq 0) { 
        Write-Verbose -Message "Creating Search Service Application $Name"
        Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
			if ($params.ContainsKey("InstallAccount")) { $params.Remove("InstallAccount") | Out-Null }

			$serviceInstance = Invoke-xSharePointSPCmdlet -CmdletName "Get-SPEnterpriseSearchServiceInstance" -Arguments @{ Local = $true }
            $serviceInstance | Invoke-xSharePointSPCmdlet -CmdletName "Start-SPEnterpriseSearchServiceInstance" -ErrorAction SilentlyContinue
            $app = Invoke-xSharePointSPCmdlet -CmdletName "New-SPEnterpriseSearchServiceApplication" -Arguments $params
            if ($app) {
                Invoke-xSharePointSPCmdlet -CmdletName "New-SPEnterpriseSearchServiceApplicationProxy" -Arguments @{ 
					Name = "$($params.Name) Proxy"
					SearchApplication = $app
				}
            }
        }
    }
    else {
        if ([string]::IsNullOrEmpty($ApplicationPool) -eq $false -and $ApplicationPool -ne $result.ApplicationPool) {
            Write-Verbose -Message "Updating Search Service Application $Name"
            Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
                $params = $args[0]

				$serviceApp = Get-xSharePointServiceApplication -Name $params.Name -TypeName Search
				Invoke-xSharePointSPCmdlet -CmdletName "Set-SPEnterpriseSearchServiceApplication" -Arguments @{
					Identity = $serviceApp
					ApplicationPool = (Invoke-xSharePointSPCmdlet -CmdletName "Get-SPServiceApplicationPool" -Arguments @{ Identity = $params.ApplicationPool } )
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
        $ApplicationPool,

		[parameter(Mandatory = $false)]
        [System.String]
        $DatabaseServer,

		[parameter(Mandatory = $false)]
        [System.String]
        $DatabaseName,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    $result = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing Search service application '$Name'"
    
    if ($result.Count -eq 0) { return $false }
    else {
        if ($ApplicationPool -ne $result.ApplicationPool) { return $false }
    }
    return $true
}

Export-ModuleMember -Function *-TargetResource
