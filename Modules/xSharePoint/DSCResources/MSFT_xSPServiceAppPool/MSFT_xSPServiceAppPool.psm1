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

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting service application pool '$Name'"

    $session = Get-xSharePointAuthenticatedPSSession -Credential $InstallAccount

    $result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $sap = Get-SPServiceApplicationPool $params.Name -ErrorAction SilentlyContinue
        if ($null -eq $sap) { return @{} }
        
        return @{
            Name = $sap.Name
            ProcessAccountName = $sap.ProcessAccountName
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
        $ServiceAccount,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Creating service application pool '$Name'"
    $session = Get-xSharePointAuthenticatedPSSession -Credential $InstallAccount

    $result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $sap = Get-SPServiceApplicationPool $params.Name -ErrorAction SilentlyContinue
        if ($null -eq $sap) { 
            New-SPServiceApplicationPool -Name $params.Name -Account $params.ServiceAccount
        } else {
            if ($sap.ProcessAccountName -ne $params.ServiceAccount) {  
                Set-SPServiceApplicationPool -Identity $params.Name -Account $params.ServiceAccount
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

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    $result = Get-TargetResource -Name $Name -ServiceAccount $ServiceAccount -InstallAccount $InstallAccount
    Write-Verbose -Message "Testing service application pool '$Name'"
    if ($result.Count -eq 0) { return $false }
    else {
        if ($ServiceAccount -ne $result.ProcessAccountName) { return $false }
    }
    return $true
}


Export-ModuleMember -Function *-TargetResource

