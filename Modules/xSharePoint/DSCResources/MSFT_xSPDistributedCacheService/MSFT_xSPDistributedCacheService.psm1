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

    Write-Verbose "Getting the cache host information"

    $session = Get-xSharePointAuthenticatedPSSession $InstallAccount

    $result = Invoke-Command -Session $session -ScriptBlock {
        try
        {
            Use-CacheCluster -ErrorAction SilentlyContinue
            $cacheHost = Get-CacheHost -ErrorAction SilentlyContinue
            if ($cacheHost -eq $null) { return @{} }
            $cacheHostConfig = Get-AFCacheHostConfiguration -ComputerName $cacheHost.HostName -CachePort $cacheHost.PortNo -ErrorAction SilentlyContinue
            if ($cacheHostConfig -eq $null) { return @{} }

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

    $session = Get-xSharePointAuthenticatedPSSession $InstallAccount

    if ($Ensure -eq "Present") {
        Write-Verbose "Adding the distributed cache to the server"
        Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            Add-SPDistributedCacheServiceInstance
            Update-SPDistributedCacheSize -CacheSizeInMB $params.CacheSizeInMB 
        }

        Write-Verbose "Update the identity used by AppFabric"
        Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            
            $farm = Get-SPFarm
            $cacheService = $farm.Services | where {$_.Name -eq "AppFabricCachingService"}
            $cacheService.ProcessIdentity.CurrentIdentityType = "SpecificUser"
            $cacheService.ProcessIdentity.ManagedAccount = Get-SPManagedAccount -Identity $params.ServiceAccount
            $cacheService.ProcessIdentity.Update() 
            $cacheService.ProcessIdentity.Deploy()
        }

        if($createFirewallRules) {
            Write-Verbose "Update the identity used by AppFabric"
            Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
                $params = $args[0]
                Import-Module NetSecurity

                $firewallRule = Get-NetFirewallRule -DisplayName "SharePoint Distribute Cache" -ErrorAction SilentlyContinue
                if($firewallRule -eq $null) {
                    New-NetFirewallRule -Name "SPDistCache" -DisplayName "SharePoint Distribute Cache" -Protocol TCP -LocalPort 22233-22236
                }
                Enable-NetFirewallRule -DisplayName "SharePoint Distribute Cache"
            }
            Write-Verbose "Firewall rule added"
        }
    } else {
        Write-Verbose "Removing distributed cache to the server"
        Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
            $params = $args[0]

            $farm = Get-SPFarm
            $cacheClusterName = "SPDistributedCacheCluster_" + $farm.Id.ToString() 
            $cacheClusterManager = [Microsoft.SharePoint.DistributedCaching.Utilities.SPDistributedCacheClusterInfoManager]::Local 
            $cacheClusterInfo = $cacheClusterManager.GetSPDistributedCacheClusterInfo($cacheClusterName); 
            $instanceName ="SPDistributedCacheService Name=AppFabricCachingService"
            $serviceInstance = Get-SPServiceInstance | ? {($_.Service.Tostring()) -eq $instanceName -and ($_.Server.Name) -eq $env:computername}  
            $serviceInstance.Delete() 
            Remove-SPDistributedCacheServiceInstance  
        }

        $firewallRule = Get-NetFirewallRule -DisplayName "SharePoint Distribute Cache" -ErrorAction SilentlyContinue
        if($firewallRule -eq $null) {
            Write-Verbose "Disabling firewall rules."
            Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
                $params = $args[0]
                Import-Module NetSecurity
                Disable-NetFirewallRule -DisplayName -DisplayName "SharePoint Distribute Cache"
            }    
        }
        Write-Verbose "Distributed cache removed."
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

