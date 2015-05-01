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
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )

    Write-Verbose -Message "Getting service instance '$Name'"

    $session = Get-xSharePointAuthenticatedPSSession -Credential $InstallAccount

    $result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $si = Get-SPServiceInstance -Server $env:COMPUTERNAME | Where-Object { $_.TypeName -eq $params.Name }
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

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )

    $session = Get-xSharePointAuthenticatedPSSession -Credential $InstallAccount

    if ($Ensure -eq "Present") {
        Write-Verbose -Message "Provisioning service instance '$Name'"

        Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
            $params = $args[0]

            $si = Get-SPServiceInstance -Server $env:COMPUTERNAME | Where-Object { $_.TypeName -eq $params.Name }
            if ($null -eq $si) { return $false }
            Start-SPServiceInstance $si
        }
    } else {
        Write-Verbose -Message "Deprovioning service instance '$Name'"

        Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
            $params = $args[0]

            $si = Get-SPServiceInstance -Server $env:COMPUTERNAME | Where-Object { $_.TypeName -eq $params.Name }
            if ($null -eq $si) { return $false }
            Stop-SPServiceInstance $si
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
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )

    $result = Get-TargetResource -Name $Name -InstallAccount $InstallAccount -Ensure $Ensure 
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

