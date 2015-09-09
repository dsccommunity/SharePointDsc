function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )

    Write-Verbose -Message "Getting service instance '$Name'"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $si = Invoke-xSharePointSPCmdlet -CmdletName "Get-SPServiceInstance" -Arguments @{ Server = $env:COMPUTERNAME } | Where-Object { $_.TypeName -eq $params.Name }
        if ($null -eq $si) { return @{} }
        
        return @{
            Name = $params.Name
            Status = $si.Status
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

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )

    if ($Ensure -eq "Present") {
        Write-Verbose -Message "Provisioning service instance '$Name'"

        Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]

            $si = Invoke-xSharePointSPCmdlet -CmdletName "Get-SPServiceInstance" -Arguments @{ Server = $env:COMPUTERNAME } | Where-Object { $_.TypeName -eq $params.Name }
            if ($null -eq $si) { return $false }
            Invoke-xSharePointSPCmdlet -CmdletName "Start-SPServiceInstance" -Arguments @{ Identity = $si }
        }
    } else {
        Write-Verbose -Message "Deprovioning service instance '$Name'"

        Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]

            $si = Invoke-xSharePointSPCmdlet -CmdletName "Get-SPServiceInstance" -Arguments @{ Server = $env:COMPUTERNAME } | Where-Object { $_.TypeName -eq $params.Name }
            if ($null -eq $si) { return $false }
			Invoke-xSharePointSPCmdlet -CmdletName "Stop-SPServiceInstance" -Arguments @{ Identity = $si }
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

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )

    $result = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Getting service instance '$Name'"
    if ($result.Count -eq 0) { return $false }
    else {
        if ($Ensure -eq "Present" -and $result.Status -eq "Disabled") {
            return $false
        }
        if ($Ensure -eq "Absent" -and $result.Status -eq "Online") {
            return $false
        }
    }
    return $true
}


Export-ModuleMember -Function *-TargetResource

