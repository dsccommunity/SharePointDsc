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
        $InstallAccount
    )

    Write-Verbose -Message "Getting state service application '$Name'"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        Add-PSSnapin -Name "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

        $params = $args[0]

        $app = Get-SPStateServiceApplication -Identity $params.Name -ErrorAction SilentlyContinue

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

        [System.Management.Automation.PSCredential]
        $DatabaseCredentials = $null,

        [System.String]
        $DatabaseName = $null,

        [System.String]
        $DatabaseServer = $null,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Creating state service application $Name"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        Add-PSSnapin -Name "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

        $params = $args[0]
        $params = Remove-xSharePointNullParamValues -Params $params

        $app = Get-SPStateServiceApplication -Identity $params.Name -ErrorAction SilentlyContinue
        if ($null -eq $app) { 
            
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
        $DatabaseCredentials = $null,

        [System.String]
        $DatabaseName = $null,

        [System.String]
        $DatabaseServer = $null,

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

