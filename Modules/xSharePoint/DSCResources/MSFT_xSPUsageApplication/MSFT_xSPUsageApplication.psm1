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

    Write-Verbose -Message "Getting usage application '$Name'"

    $session = Get-xSharePointAuthenticatedPSSession -Credential $InstallAccount

    $result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        $serviceApp = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue |
                        Where-Object { $_.TypeName -eq "Usage and Health Data Collection Service Application" }
        If ($null -eq $serviceApp)
        {
            return @{}
        }
        else
        {
            $service = Get-SPUsageService
            return @{
                Name = $serviceApp.DisplayName
                UsageLogCutTime = $service.UsageLogCutTime
                UsageLogDir = $service.UsageLogDir
                UsageLogMaxFileSize = $service.UsageLogMaxFileSize
                UsageLogMaxSpaceGB = $service.UsageLogMaxSpaceGB
            }
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

        [System.String]
        $DatabaseName = $null,

        [System.String]
        $DatabasePassword = $null,

        [System.String]
        $DatabaseServer = $null,

        [System.String]
        $DatabaseUsername = $null,

        [System.String]
        $FailoverDatabaseServer = $null,

        [System.UInt32]
        $UsageLogCutTime = 5,

        [System.String]
        $UsageLogLocation = $null,

        [System.UInt32]
        $UsageLogMaxFileSizeKB = 1024,

        [System.UInt32]
        $UsageLogMaxSpaceGB = $null
    )

    Write-Verbose -Message "Setting usage application $Name"

    $session = Get-xSharePointAuthenticatedPSSession -Credential $InstallAccount
    Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
        $app = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue

        if ($null -eq $app) { 
            $newParams = @{}
            $newParams.Add("Name", $params.Name)
            if ($params.ContainsKey("DatabaseName")) { $newParams.Add("DatabaseName", $params.DatabaseName) }
            if ($params.ContainsKey("DatabasePassword")) { $newParams.Add("DatabasePassword", $params.DatabasePassword) }
            if ($params.ContainsKey("DatabaseServer")) { $newParams.Add("DatabaseServer", $params.DatabaseServer) }
            if ($params.ContainsKey("DatabaseUsername")) { $newParams.Add("DatabaseUsername", $params.DatabaseUsername) }
            if ($params.ContainsKey("FailoverDatabaseServer")) { $newParams.Add("FailoverDatabaseServer", $params.FailoverDatabaseServer) }

            New-SPUsageApplication @newParams
        }
    }

    Write-Verbose -Message "Configuring usage application $Name"
    Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        $params = Remove-xSharePointNullParamValues -Params $params

        $setParams = @{}
        $setParams.Add("LoggingEnabled", $true)
        if ($params.ContainsKey("UsageLogCutTime")) { $setParams.Add("UsageLogCutTime", $params.UsageLogCutTime) }
        if ($params.ContainsKey("UsageLogLocation")) { $setParams.Add("UsageLogLocation", $params.UsageLogLocation) }
        if ($params.ContainsKey("UsageLogMaxFileSizeKB")) { $setParams.Add("UsageLogMaxFileSizeKB", $params.UsageLogMaxFileSizeKB) }
        if ($params.ContainsKey("UsageLogMaxSpaceGB")) { $setParams.Add("UsageLogMaxSpaceGB", $params.UsageLogMaxSpaceGB) }
        Set-SPUsageService @setParams
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

        [System.String]
        $DatabaseName = $null,

        [System.String]
        $DatabasePassword = $null,

        [System.String]
        $DatabaseServer = $null,

        [System.String]
        $DatabaseUsername = $null,

        [System.String]
        $FailoverDatabaseServer = $null,

        [System.UInt32]
        $UsageLogCutTime = 5,

        [System.String]
        $UsageLogLocation = $null,

        [System.UInt32]
        $UsageLogMaxFileSizeKB = 1024,

        [System.UInt32]
        $UsageLogMaxSpaceGB = $null
    )

    $result = Get-TargetResource -Name $Name -InstallAccount $InstallAccount
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

