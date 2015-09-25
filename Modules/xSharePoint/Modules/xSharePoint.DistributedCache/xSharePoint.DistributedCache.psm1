function Add-xSharePointDistributedCacheServer() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1)]
        [System.Uint32]
        $CacheSizeInMB,

        [parameter(Mandatory = $true,Position=2)]
        [System.String]
        $ServiceAccount
    )
    

    Add-SPDistributedCacheServiceInstance
    Update-SPDistributedCacheSize -CacheSizeInMB $CacheSizeInMB

    $farm = Get-SPFarm
    $cacheService = $farm.Services | Where-Object { $_.Name -eq "AppFabricCachingService" }
    $cacheService.ProcessIdentity.CurrentIdentityType = "SpecificUser"

    $account = Get-SPManagedAccount -Identity $ServiceAccount
    $cacheService.ProcessIdentity.ManagedAccount = $account

    Update-xSharePointDistributedCacheService -CacheService $cacheService
}

function Update-xSharePointDistributedCacheService() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1)]
        [object]
        $CacheService
    )
    $CacheService.ProcessIdentity.Update() 
    $CacheService.ProcessIdentity.Deploy()
}

function Remove-xSharePointDistributedCacheServer() {
    $instanceName ="SPDistributedCacheService Name=AppFabricCachingService"
    $serviceInstance = Get-SPServiceInstance | Where-Object { ($_.Service.Tostring()) -eq $instanceName -and ($_.Server.Name) -eq $env:computername }
    $serviceInstance.Delete() 
    Remove-SPDistributedCacheServiceInstance
}

function Enable-xSharePointDCIcmpFireWallRule() {
    $firewallRule = Get-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)" -ErrorAction SilentlyContinue
    if($null -eq $firewallRule) {
        New-NetFirewallRule -Name Allow_Ping -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)" -Description "Allow ICMPv4 ping" -Protocol ICMPv4 -IcmpType 8 -Enabled True -Profile Any -Action Allow 
    }
    Enable-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)"
}

function Enable-xSharePointDCFireWallRule() {
    $firewallRule = Get-NetFirewallRule -DisplayName "SharePoint Distributed Cache" -ErrorAction SilentlyContinue
    if($null -eq $firewallRule) {
        New-NetFirewallRule -Name "SPDistCache" -DisplayName "SharePoint Distributed Cache" -Protocol TCP -LocalPort 22233-22236 -Group "SharePoint"
    }
    Enable-NetFirewallRule -DisplayName "SharePoint Distributed Cache"
}

function Disable-xSharePointDCFireWallRule() {
    $firewallRule = Get-NetFirewallRule -DisplayName "SharePoint Distribute Cache" -ErrorAction SilentlyContinue
    if($null -ne $firewallRule) {
        Write-Verbose -Message "Disabling firewall rules."
        Disable-NetFirewallRule -DisplayName "SharePoint Distribute Cache"    
    }
}

Export-ModuleMember -Function *
