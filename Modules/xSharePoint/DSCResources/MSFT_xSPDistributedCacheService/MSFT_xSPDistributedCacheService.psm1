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

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $CreateFirewallRules
    )

    Write-Verbose -Message "Getting the cache host information"

    $session = Get-xSharePointAuthenticatedPSSession -Credential $InstallAccount

    $result = Invoke-Command -Session $session -ScriptBlock {
        try
        {
            Use-CacheCluster -ErrorAction SilentlyContinue
            $cacheHost = Get-CacheHost -ErrorAction SilentlyContinue
            if ($null -eq $cacheHost) { return @{} }
            $cacheHostConfig = Get-AFCacheHostConfiguration -ComputerName $cacheHost.HostName -CachePort $cacheHost.PortNo -ErrorAction SilentlyContinue
            if ($null -eq $cacheHostConfig) { return @{} }

            return @{
                HostName = $cacheHost.HostName
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

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $CreateFirewallRules
    )

    $session = Get-xSharePointAuthenticatedPSSession -Credential $InstallAccount

    if ($Ensure -eq "Present") {
        Write-Verbose -Message "Adding the distributed cache to the server"
        if($createFirewallRules) {
            Write-Verbose -Message "Create a firewall rule for AppFabric"
            Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
                $params = $args[0]
                Import-Module -Name NetSecurity

                $icmpRuleName = "File and Printer Sharing (Echo Request - ICMPv4-In)"
                $icmpPingFirewallRule = Get-NetFirewallRule -DisplayName $icmpRuleName -ErrorAction SilentlyContinue
                if($icmpPingFirewallRule) {
                    Enable-NetFirewallRule -DisplayName $icmpRuleName
                }
                else {
                    New-NetFirewallRule -Name Allow_Ping -DisplayName $icmpRuleName -Description "Allow ICMPv4 ping" -Protocol ICMPv4 -IcmpType 8 -Enabled True -Profile Any -Action Allow 
                }

                $firewallRule = Get-NetFirewallRule -DisplayName "SharePoint Distribute Cache" -ErrorAction SilentlyContinue
                if($null -eq $firewallRule) {
                    New-NetFirewallRule -Name "SPDistCache" -DisplayName "SharePoint Distribute Cache" -Protocol TCP -LocalPort 22233-22236
                }
                Enable-NetFirewallRule -DisplayName "SharePoint Distribute Cache"
            }
            Write-Verbose -Message "Firewall rule added"
        }
        Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            Add-xSharePointDistributedCacheServer -CacheSizeInMB $params.CacheSizeInMB -ServiceAccount $params.ServiceAccount
        }
    } else {
        Write-Verbose -Message "Removing distributed cache to the server"
        Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            Remove-xSharePointDistributedCacheServer
        }

        $firewallRule = Get-NetFirewallRule -DisplayName "SharePoint Distribute Cache" -ErrorAction SilentlyContinue
        if($null -eq $firewallRule) {
            Write-Verbose -Message "Disabling firewall rules."
            Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
                $params = $args[0]
                Import-Module -Name NetSecurity
                Disable-NetFirewallRule -DisplayName -DisplayName "SharePoint Distribute Cache"
            }    
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

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $createFirewallRules
    )

    $result = Get-TargetResource -Name $Name -Ensure $Ensure -CacheSizeInMB $CacheSizeInMB -ServiceAccount $ServiceAccount -InstallAccount $InstallAccount -CreateFirewallRules $createFirewallRules
    
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

