function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $true)]  [System.String] $ServiceAccount,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Getting service application pool '$Name'"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        

        $sap = Get-SPServiceApplicationPool -Identity $params.Name -ErrorAction SilentlyContinue
        if ($null -eq $sap) { return $null }
        
        return @{
            Name = $sap.Name
            ServiceAccount = $sap.ProcessAccountName
            InstallAccount = $params.InstallAccount
        }
    }
    return $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $true)]  [System.String] $ServiceAccount,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Creating service application pool '$Name'"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        

        $sap = Get-SPServiceApplicationPool -Identity $params.Name -ErrorAction SilentlyContinue
        if ($null -eq $sap) { 
            New-SPServiceApplicationPool -Name $params.Name  -Account $params.ServiceAccount
        } else {
            if ($sap.ProcessAccountName -ne $params.ServiceAccount) {  
                Set-SPServiceApplicationPool -Identity $params.Name  -Account $params.ServiceAccount
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
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $true)]  [System.String] $ServiceAccount,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing service application pool '$Name'"
    if ($null -eq $CurrentValues) { return $false }
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("ServiceAccount")
}


Export-ModuleMember -Function *-TargetResource

