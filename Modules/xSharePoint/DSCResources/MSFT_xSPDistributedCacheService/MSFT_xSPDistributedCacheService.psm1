function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $Name,
        [parameter(Mandatory = $true)]  [System.UInt32]  $CacheSizeInMB,
        [parameter(Mandatory = $true)]  [System.String]  $ServiceAccount,
        [parameter(Mandatory = $true)]  [System.Boolean] $CreateFirewallRules,
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")] [System.String] $Ensure,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount        
    )

    Write-Verbose -Message "Getting the cache host information"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        try
        {
            Invoke-xSharePointDCCmdlet -CmdletName "Use-CacheCluster" -ErrorAction SilentlyContinue
            $cacheHost = Invoke-xSharePointDCCmdlet -CmdletName "Get-CacheHost" -ErrorAction SilentlyContinue
            if ($null -eq $cacheHost) { return @{} }
            $computerName = ([System.Net.Dns]::GetHostByName($env:computerName)).HostName
            $cacheHostConfig = Invoke-xSharePointDCCmdlet -CmdletName "Get-AFCacheHostConfiguration" -Arguments @{ 
                ComputerName = $computerName
                CachePort = $cacheHost.PortNo 
            } -ErrorAction SilentlyContinue
            if ($null -eq $cacheHostConfig) { return @{
                Name = $params.Name
                Ensure = "Absent"
                InstallAccount = $params.InstallAccount
            } }

            $windowsService = Get-WmiObject "win32_service" -Filter "Name='AppFabricCachingService'"
            $firewallRule = Get-NetFirewallRule -DisplayName "SharePoint Distributed Cache" -ErrorAction SilentlyContinue
            
            return @{
                Name = $params.Name
                CacheSizeInMB = $cacheHostConfig.Size
                ServiceAccount = $windowsService.StartName
                CreateFirewallRules = ($firewallRule -ne $null)
                Ensure = "Present"
                InstallAccount = $params.InstallAccount
            }
        }
        catch{
            return @{
                Name = $params.Name
                Ensure = "Absent"
                InstallAccount = $params.InstallAccount
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
        [parameter(Mandatory = $true)]  [System.String]  $Name,
        [parameter(Mandatory = $true)]  [System.UInt32]  $CacheSizeInMB,
        [parameter(Mandatory = $true)]  [System.String]  $ServiceAccount,
        [parameter(Mandatory = $true)]  [System.Boolean] $CreateFirewallRules,
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")] [System.String] $Ensure,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentState = Get-TargetResource @PSBoundParameters

    if ($Ensure -eq "Present") {
        Write-Verbose -Message "Adding the distributed cache to the server"
        if($createFirewallRules) {
            Write-Verbose -Message "Create a firewall rule for AppFabric"
            Invoke-xSharePointCommand -Credential $InstallAccount -ScriptBlock {
                Enable-xSharePointDCIcmpFireWallRule
                Enable-xSharePointDCFireWallRule
            }
            Write-Verbose -Message "Firewall rule added"
        }
        if ($CurrentState.Ensure -ne $Ensure) {
                Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
                $params = $args[0]
                Add-xSharePointDistributedCacheServer -CacheSizeInMB $params.CacheSizeInMB -ServiceAccount $params.ServiceAccount
            }
        }
    } else {
        Write-Verbose -Message "Removing distributed cache to the server"
        Invoke-xSharePointCommand -Credential $InstallAccount -ScriptBlock {
            Remove-xSharePointDistributedCacheServer
        }
        Invoke-xSharePointCommand -Credential $InstallAccount -ScriptBlock {
            Disable-xSharePointDCFireWallRule
        }  
        Write-Verbose -Message "Distributed cache removed."
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $Name,
        [parameter(Mandatory = $true)]  [System.UInt32]  $CacheSizeInMB,
        [parameter(Mandatory = $true)]  [System.String]  $ServiceAccount,
        [parameter(Mandatory = $true)]  [System.Boolean] $CreateFirewallRules,
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")] [System.String] $Ensure,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing for distributed cache configuration"
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("CacheSizeInMB", "Ensure", "CreateFirewallRules")
}


Export-ModuleMember -Function *-TargetResource

