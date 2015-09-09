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

    Invoke-xSharePointSPCmdlet -CmdletName "Add-SPDistributedCacheServiceInstance"
    Invoke-xSharePointSPCmdlet -CmdletName "Update-SPDistributedCacheSize" -Arguments @{ CacheSizeInMB = $CacheSizeInMB }

    $farm = Invoke-xSharePointSPCmdlet -CmdletName "Get-SPFarm"
    $cacheService = $farm.Services | Where-Object {$_.Name -eq "AppFabricCachingService"}
    $cacheService.ProcessIdentity.CurrentIdentityType = "SpecificUser"
    $cacheService.ProcessIdentity.ManagedAccount = (Get-SPManagedAccount -Identity $ServiceAccount)
    $cacheService.ProcessIdentity.Update() 
    $cacheService.ProcessIdentity.Deploy()
}

function Remove-xSharePointDistributedCacheServer() {
    $instanceName ="SPDistributedCacheService Name=AppFabricCachingService"
    $serviceInstance = Invoke-xSharePointSPCmdlet -CmdletName "Get-SPServiceInstance" | Where-Object {($_.Service.Tostring()) -eq $instanceName -and ($_.Server.Name) -eq $env:computername}  
    $serviceInstance.Delete() 
    Invoke-xSharePointSPCmdlet -CmdletName "Remove-SPDistributedCacheServiceInstance"
}

Export-ModuleMember -Function *
