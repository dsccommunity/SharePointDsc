function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $false)] [System.String] $DatabaseName,
        [parameter(Mandatory = $false)] [System.String] $DatabaseServer,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $DatabaseCredentials,
        [parameter(Mandatory = $false)] [System.String] $FailoverDatabaseServer,
        [parameter(Mandatory = $false)] [System.UInt32] $UsageLogCutTime,
        [parameter(Mandatory = $false)] [System.String] $UsageLogLocation,
        [parameter(Mandatory = $false)] [System.UInt32] $UsageLogMaxFileSizeKB,
        [parameter(Mandatory = $false)] [System.UInt32] $UsageLogMaxSpaceGB
    )

    Write-Verbose -Message "Getting usage application '$Name'"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        

        $serviceApps = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue 
        if ($null -eq $serviceApps) { 
            return $null 
        }
        $serviceApp = $serviceApps | Where-Object { $_.TypeName -eq "Usage and Health Data Collection Service Application" }

        If ($null -eq $serviceApp)
        {
            return $null
        }
        else
        {
            $service = Get-SPUsageService
            return @{
                Name = $serviceApp.DisplayName
                InstallAccount = $params.InstallAccount
                DatabaseName = $serviceApp.UsageDatabase.Name
                DatabaseServer = $serviceApp.UsageDatabase.Server.Name
                DatabasePassword = $serviceApp.UsageDatabase.Password
                DatabaseUsername = $serviceApp.UsageDatabase.Username
                FailoverDatabaseServer = $serviceApp.UsageDatabase.FailoverServer
                UsageLogCutTime = $service.UsageLogCutTime
                UsageLogLocation = $service.UsageLogDir
                UsageLogMaxFileSizeKB = $service.UsageLogMaxFileSize / 1024
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
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $false)] [System.String] $DatabaseName,
        [parameter(Mandatory = $false)] [System.String] $DatabaseServer,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $DatabaseCredentials,
        [parameter(Mandatory = $false)] [System.String] $FailoverDatabaseServer,
        [parameter(Mandatory = $false)] [System.UInt32] $UsageLogCutTime,
        [parameter(Mandatory = $false)] [System.String] $UsageLogLocation,
        [parameter(Mandatory = $false)] [System.UInt32] $UsageLogMaxFileSizeKB,
        [parameter(Mandatory = $false)] [System.UInt32] $UsageLogMaxSpaceGB
    )

    Write-Verbose -Message "Setting usage application $Name"

    $CurrentState = Get-TargetResource @PSBoundParameters

    if ($null -eq $CurrentState) {
        Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
        
            $newParams = @{}
            $newParams.Add("Name", $params.Name)
            if ($params.ContainsKey("DatabaseName")) { $newParams.Add("DatabaseName", $params.DatabaseName) }
            if ($params.ContainsKey("DatabaseCredentials")) {
                $params.Add("DatabaseUsername", $params.DatabaseCredentials.Username)
                $params.Add("DatabasePassword", (ConvertTo-SecureString $params.DatabaseCredentials.GetNetworkCredential().Password -AsPlainText -Force))
            }
            if ($params.ContainsKey("DatabaseServer")) { $newParams.Add("DatabaseServer", $params.DatabaseServer) }
            if ($params.ContainsKey("FailoverDatabaseServer")) { $newParams.Add("FailoverDatabaseServer", $params.FailoverDatabaseServer) }

            New-SPUsageApplication @newParams
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
        Set-SPUsageService @setParams
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $false)] [System.String] $DatabaseName,
        [parameter(Mandatory = $false)] [System.String] $DatabaseServer,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $DatabaseCredentials,
        [parameter(Mandatory = $false)] [System.String] $FailoverDatabaseServer,
        [parameter(Mandatory = $false)] [System.UInt32] $UsageLogCutTime,
        [parameter(Mandatory = $false)] [System.String] $UsageLogLocation,
        [parameter(Mandatory = $false)] [System.UInt32] $UsageLogMaxFileSizeKB,
        [parameter(Mandatory = $false)] [System.UInt32] $UsageLogMaxSpaceGB
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing for usage application '$Name'"
    if ($null -eq $CurrentValues) { return $false }
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("UsageLogCutTime", "UsageLogLocation", "UsageLogMaxFileSizeKB", "UsageLogMaxSpaceGB")
}


Export-ModuleMember -Function *-TargetResource

