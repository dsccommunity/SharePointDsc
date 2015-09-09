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

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabaseName,

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabasePassword,

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabaseServer,

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabaseUsername,

        [parameter(Mandatory = $false)]
        [System.String]
        $FailoverDatabaseServer,

        [parameter(Mandatory = $false)]
        [System.UInt32]
        $UsageLogCutTime,

        [parameter(Mandatory = $false)]
        [System.String]
        $UsageLogLocation,

        [parameter(Mandatory = $false)]
        [System.UInt32]
        $UsageLogMaxFileSizeKB,

        [parameter(Mandatory = $false)]
        [System.UInt32]
        $UsageLogMaxSpaceGB
    )

    Write-Verbose -Message "Getting usage application '$Name'"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $serviceApp = Get-xSharePointServiceApplication -Name $params.Name -TypeName Usage

        If ($null -eq $serviceApp)
        {
            return @{}
        }
        else
        {
            $service = Invoke-xSharePointCommand -CmdletName "Get-SPUsageService"
            return @{
                Name = $serviceApp.DisplayName
                UsageLogCutTime = $service.UsageLogCutTime
                UsageLogDir = $service.UsageLogDir
                UsageLogMaxFileSize = $service.UsageLogMaxFileSize
                UsageLogMaxSpaceGB = $service.UsageLogMaxSpaceGB
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

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabaseName,

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabasePassword,

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabaseServer,

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabaseUsername,

        [parameter(Mandatory = $false)]
        [System.String]
        $FailoverDatabaseServer,

        [parameter(Mandatory = $false)]
        [System.UInt32]
        $UsageLogCutTime,

        [parameter(Mandatory = $false)]
        [System.String]
        $UsageLogLocation,

        [parameter(Mandatory = $false)]
        [System.UInt32]
        $UsageLogMaxFileSizeKB,

        [parameter(Mandatory = $false)]
        [System.UInt32]
        $UsageLogMaxSpaceGB
    )

    Write-Verbose -Message "Setting usage application $Name"

    Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
        $app = Invoke-xSharePointSPCmdlet -CmdletName "Get-SPServiceApplication" -Arguments @{ Name = $params.Name } -ErrorAction SilentlyContinue

        if ($null -eq $app) { 
            $newParams = @{}
            $newParams.Add("Name", $params.Name)
            if ($params.ContainsKey("DatabaseName")) { $newParams.Add("DatabaseName", $params.DatabaseName) }
            if ($params.ContainsKey("DatabasePassword")) { $newParams.Add("DatabasePassword", $params.DatabasePassword) }
            if ($params.ContainsKey("DatabaseServer")) { $newParams.Add("DatabaseServer", $params.DatabaseServer) }
            if ($params.ContainsKey("DatabaseUsername")) { $newParams.Add("DatabaseUsername", $params.DatabaseUsername) }
            if ($params.ContainsKey("FailoverDatabaseServer")) { $newParams.Add("FailoverDatabaseServer", $params.FailoverDatabaseServer) }

            Invoke-xSharePointSPCmdlet -CmdletName "New-SPUsageApplication" -Arguments $newParams
        }
    }

    Write-Verbose -Message "Configuring usage application $Name"
    Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        $setParams = @{}
        $setParams.Add("LoggingEnabled", $true)
        if ($params.ContainsKey("UsageLogCutTime")) { $setParams.Add("UsageLogCutTime", $params.UsageLogCutTime) }
        if ($params.ContainsKey("UsageLogLocation")) { $setParams.Add("UsageLogLocation", $params.UsageLogLocation) }
        if ($params.ContainsKey("UsageLogMaxFileSizeKB")) { $setParams.Add("UsageLogMaxFileSizeKB", $params.UsageLogMaxFileSizeKB) }
        if ($params.ContainsKey("UsageLogMaxSpaceGB")) { $setParams.Add("UsageLogMaxSpaceGB", $params.UsageLogMaxSpaceGB) }
        Invoke-xSharePointSPCmdlet -CmdletName "Set-SPUsageService" -Arguments $setParams
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

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabaseName,

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabasePassword,

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabaseServer,

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabaseUsername,

        [parameter(Mandatory = $false)]
        [System.String]
        $FailoverDatabaseServer,

        [parameter(Mandatory = $false)]
        [System.UInt32]
        $UsageLogCutTime,

        [parameter(Mandatory = $false)]
        [System.String]
        $UsageLogLocation,

        [parameter(Mandatory = $false)]
        [System.UInt32]
        $UsageLogMaxFileSizeKB,

        [parameter(Mandatory = $false)]
        [System.UInt32]
        $UsageLogMaxSpaceGB
    )

    $result = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing for usage application '$Name'"
    if ($result.Count -eq 0) { return $false }
    else {
        if ($PSBoundParameters.ContainsKey("UsageLogCutTime") -and $result.UsageLogCutTime -ne $UsageLogCutTime) { return $false }
        if ($PSBoundParameters.ContainsKey("UsageLogLocation") -and $result.UsageLogDir -ne $UsageLogLocation) { return $false }
        if ($PSBoundParameters.ContainsKey("UsageLogMaxFileSizeKB") -and $result.UsageLogMaxFileSize -ne $UsageLogMaxFileSizeKB) { return $false }
        if ($PSBoundParameters.ContainsKey("UsageLogMaxSpaceGB") -and $result.UsageLogMaxSpaceGB -ne $UsageLogMaxSpaceGB) { return $false }
    }
    return $true
}


Export-ModuleMember -Function *-TargetResource

