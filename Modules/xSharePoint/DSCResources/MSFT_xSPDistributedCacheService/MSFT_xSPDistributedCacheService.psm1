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
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.UInt32]
        $CacheSizeInMB,

        [parameter(Mandatory = $true)]
        [System.String]
        $ServiceAccount,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $CreateFirewallRules
    )

    Write-Verbose -Message "Getting the cache host information"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -ScriptBlock {
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
            if ($null -eq $cacheHostConfig) { return @{} }

            return @{
                HostName = $computerName
                Port = $cacheHost.PortNo
                CacheSizeInMB = $cacheHostConfig.Size
            }
        }
        catch{
            return @{}
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
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.UInt32]
        $CacheSizeInMB,

        [parameter(Mandatory = $true)]
        [System.String]
        $ServiceAccount,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $CreateFirewallRules
    )

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
        Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            Add-xSharePointDistributedCacheServer -CacheSizeInMB $params.CacheSizeInMB -ServiceAccount $params.ServiceAccount
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
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.UInt32]
        $CacheSizeInMB,

        [parameter(Mandatory = $true)]
        [System.String]
        $ServiceAccount,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $createFirewallRules
    )

    $result = Get-TargetResource @PSBoundParameters
    
    if ($Ensure -eq "Present") {
        if ($result.Count -eq 0) { return $false }
        else {
            if ($result.CacheSizeInMB -ne $CacheSizeInMB) { return $false }
        }
        return $true
    } else {
        if ($result.Count -eq 0) { return $true }
        return $false
    }
}


Export-ModuleMember -Function *-TargetResource

