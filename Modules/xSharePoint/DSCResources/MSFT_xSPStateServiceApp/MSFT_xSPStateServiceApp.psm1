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
        $DatabaseCredentials,

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabaseName,

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabaseServer,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting state service application '$Name'"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $app = Invoke-xSharePointSPCmdlet -CmdletName "Get-SPStateServiceApplication" -Arguments @{ Identity = $params.Name } -ErrorAction SilentlyContinue

        if ($null -eq $app) { return @{} }
        
        return @{
            Name = $app.DisplayName
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
        $DatabaseCredentials,

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabaseName,

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabaseServer,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Creating state service application $Name"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $app = Invoke-xSharePointSPCmdlet -CmdletName "Get-SPStateServiceApplication" -Arguments @{ Identity = $params.Name } -ErrorAction SilentlyContinue
        if ($null -eq $app) { 
            
            $dbParams = @{}
            if ($params.ContainsKey("DatabaseName")) { $dbParams.Add("Name", $params.DatabaseName) }
            if ($params.ContainsKey("DatabaseServer")) { $dbParams.Add("DatabaseServer", $params.DatabaseServer) }
            if ($params.ContainsKey("DatabaseCredentials")) { $dbParams.Add("DatabaseCredentials", $params.DatabaseCredentials) }

            Invoke-xSharePointSPCmdlet -CmdletName "New-SPStateServiceDatabase" -Arguments $dbParams | `
                Invoke-xSharePointSPCmdlet -CmdletName "New-SPStateServiceApplication" -Arguments @{ Name = $params.Name } | `
                Invoke-xSharePointSPCmdlet -CmdletName "New-SPStateServiceApplicationProxy" -Arguments @{ DefaultProxyGroup = $true }
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
        $DatabaseCredentials,

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabaseName,

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabaseServer,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    $result = Get-TargetResource -Name $Name -InstallAccount $InstallAccount
    Write-Verbose -Message "Testing for state service application $Name"
    if ($result.Count -eq 0) { return $false }
    return $true
}


Export-ModuleMember -Function *-TargetResource

