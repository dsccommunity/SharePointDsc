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
        $InstallAccount
    )

    Write-Verbose "Getting state service application '$Name'"

    $session = Get-xSharePointAuthenticatedPSSession $InstallAccount

    $result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $app = Get-SPStateServiceApplication -Identity $params.Name -ErrorAction SilentlyContinue

        if ($app -eq $null) { return @{} }
        
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

        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [System.String]
        $DatabaseName,

        [System.String]
        $DatabaseServer,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose "Creating state service application $Name"

    $session = Get-xSharePointAuthenticatedPSSession $InstallAccount

    $result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $app = Get-SPStateServiceApplication -Identity $params.Name -ErrorAction SilentlyContinue
        if ($app -eq $null) { 
            
            $dbParams = @{}
            if ($params.ContainsKey("DatabaseName")) { $dbParams.Add("Name", $params.DatabaseName) }
            if ($params.ContainsKey("DatabaseServer")) { $dbParams.Add("DatabaseServer", $params.DatabaseServer) }
            if ($params.ContainsKey("DatabaseCredentials")) { $dbParams.Add("DatabaseCredentials", $params.DatabaseCredentials) }

            New-SPStateServiceDatabase @dbParams| New-SPStateServiceApplication -Name $params.Name | New-SPStateServiceApplicationProxy -DefaultProxyGroup
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

        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [System.String]
        $DatabaseName,

        [System.String]
        $DatabaseServer,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    $result = Get-TargetResource -Name $Name -InstallAccount $InstallAccount
    Write-Verbose "Testing for state service application $Name"
    if ($result.Count -eq 0) { return $false }
    else {
        
    }
    return $true
}


Export-ModuleMember -Function *-TargetResource

