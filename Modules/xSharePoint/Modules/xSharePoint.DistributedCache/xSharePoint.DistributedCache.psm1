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
    $cacheService = $farm.Services | Where-Object {$_.Name -eq "AppFabricCachingService"}
    $cacheService.ProcessIdentity.CurrentIdentityType = "SpecificUser"
    $cacheService.ProcessIdentity.ManagedAccount = (Get-SPManagedAccount -Identity $ServiceAccount)
    $cacheService.ProcessIdentity.Update() 
    $cacheService.ProcessIdentity.Deploy()
}

function Remove-xSharePointDistributedCacheServer() {
    $instanceName ="SPDistributedCacheService Name=AppFabricCachingService"
    $serviceInstance = Get-SPServiceInstance | Where-Object {($_.Service.Tostring()) -eq $instanceName -and ($_.Server.Name) -eq $env:computername}  
    $serviceInstance.Delete() 
    Remove-SPDistributedCacheServiceInstance 
}

Export-ModuleMember -Function *
