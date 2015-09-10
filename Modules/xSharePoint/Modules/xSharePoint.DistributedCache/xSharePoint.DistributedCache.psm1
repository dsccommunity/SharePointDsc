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

function Invoke-xSharePointDCCmdlet() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1)]
        [string]
        $CmdletName,

        [parameter(Mandatory = $false,Position=2)]
        [HashTable]
        $Arguments
    )

    Write-Verbose "Preparing to execute SharePoint command - $CmdletName"

    if ($null -ne $Arguments -and $Arguments.Count -gt 0) {
        $argumentsString = ""
        $Arguments.Keys | ForEach-Object {
            $argumentsString += "$($_): $($Arguments.$_); "
        }
        Write-Verbose "Arguments for $CmdletName - $argumentsString"
    }

    if ($null -eq $Arguments) {
        $script = ([scriptblock]::Create("$CmdletName; `$params = `$null"))
        $result = Invoke-Command -ScriptBlock $script -NoNewScope
    } else {
        $script = ([scriptblock]::Create("`$params = `$args[0]; $CmdletName @params; `$params = `$null"))
        $result = Invoke-Command -ScriptBlock $script -ArgumentList $Arguments -NoNewScope
    }
    return $result
}

function Enable-xSharePointDCIcmpFireWallRule() {
    Import-Module -Name NetSecurity

    $firewallRule = Get-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)" -ErrorAction SilentlyContinue
    if($null -eq $firewallRule) {
        New-NetFirewallRule -Name Allow_Ping -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)" -Description "Allow ICMPv4 ping" -Protocol ICMPv4 -IcmpType 8 -Enabled True -Profile Any -Action Allow 
    }
    Enable-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)"
}

function Enable-xSharePointDCFireWallRule() {
    Import-Module -Name NetSecurity

    $firewallRule = Get-NetFirewallRule -DisplayName "SharePoint Distributed Cache" -ErrorAction SilentlyContinue
    if($null -eq $firewallRule) {
        New-NetFirewallRule -Name "SPDistCache" -DisplayName "SharePoint Distributed Cache" -Protocol TCP -LocalPort 22233-22236
    }
    Enable-NetFirewallRule -DisplayName "SharePoint Distributed Cache"
}

function Disable-xSharePointDCFireWallRule() {
    Import-Module -Name NetSecurity

    $firewallRule = Get-NetFirewallRule -DisplayName "SharePoint Distribute Cache" -ErrorAction SilentlyContinue
    if($null -eq $firewallRule) {
        Write-Verbose -Message "Disabling firewall rules."
        Disable-NetFirewallRule -DisplayName -DisplayName "SharePoint Distribute Cache"    
    }
}

Export-ModuleMember -Function *
