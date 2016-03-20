function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $true)]  [System.String] $DatabaseName,
        [parameter(Mandatory = $false)] [System.String] $DatabaseServer,
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")] [System.String] $Ensure,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $DatabaseCredentials,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Getting state service application '$Name'"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        

        $serviceApp = Get-SPStateServiceApplication -Identity $params.Name -ErrorAction SilentlyContinue

        if ($null -eq $serviceApp) { return @{
            Name = $params.Name
            Ensure = "Absent"
            InstallAccount = $params.InstallAccount
        } }
        
        return @{
            Name = $serviceApp.DisplayName
            DatabaseName = $serviceApp.Databases.Name
            DatabaseServer = $serviceApp.Databases.Server.Name
            InstallAccount = $params.InstallAccount
            Ensure = "Present"
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
        [parameter(Mandatory = $true)]  [System.String] $DatabaseName,
        [parameter(Mandatory = $false)] [System.String] $DatabaseServer,
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")] [System.String] $Ensure,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $DatabaseCredentials,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    if ($Ensure -eq "Present") {
        Write-Verbose -Message "Creating State Service Application $Name"
        Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            
            $dbParams = @{}
            if ($params.ContainsKey("DatabaseName")) { $dbParams.Add("Name", $params.DatabaseName) }
            if ($params.ContainsKey("DatabaseServer")) { $dbParams.Add("DatabaseServer", $params.DatabaseServer) }
            if ($params.ContainsKey("DatabaseCredentials")) { $dbParams.Add("DatabaseCredentials", $params.DatabaseCredentials) }

            $database = New-SPStateServiceDatabase @dbParams
            $app = New-SPStateServiceApplication -Name $params.Name -Database $database 
            New-SPStateServiceApplicationProxy -ServiceApplication $app -DefaultProxyGroup | Out-Null
        }
    }
    if ($Ensure -eq "Absent") {
        Write-Verbose -Message "Removing State Service Application $Name"
        Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            
            $serviceApp =  Get-SPStateServiceApplication -Name $params.Name
            Remove-SPServiceApplication $serviceApp -Confirm:$false
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
        [parameter(Mandatory = $true)]  [System.String] $DatabaseName,
        [parameter(Mandatory = $false)] [System.String] $DatabaseServer,
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")] [System.String] $Ensure,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $DatabaseCredentials,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing for state service application $Name"
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("Name", "Ensure")
}


Export-ModuleMember -Function *-TargetResource

