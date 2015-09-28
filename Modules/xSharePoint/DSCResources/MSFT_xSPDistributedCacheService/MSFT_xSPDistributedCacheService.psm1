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
        $nullReturnValue = @{
            Name = $params.Name
            Ensure = "Absent"
            InstallAccount = $params.InstallAccount
        }

        try
        {
            Use-CacheCluster -ErrorAction SilentlyContinue
            $cacheHost = Get-CacheHost -ErrorAction SilentlyContinue

            if ($null -eq $cacheHost) { return $nullReturnValue }
            $computerName = ([System.Net.Dns]::GetHostByName($env:computerName)).HostName
            $cacheHostConfig = Get-AFCacheHostConfiguration -ComputerName $computerName -CachePort $cacheHost.PortNo -ErrorAction SilentlyContinue

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
        catch {
            return $nullReturnValue
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
    
    $isLocalAdmin = Test-xSharePointUserIsLocalAdmin -UserName $ServiceAccount

    if (!$isLocalAdmin)
    {
        Add-xSharePointUserToLocalAdmin -UserName $ServiceAccount
    }

    if ($Ensure -eq "Present") {
        Write-Verbose -Message "Adding the distributed cache to the server"
        if($createFirewallRules -eq $true) {
            Write-Verbose -Message "Create a firewall rule for AppFabric"
            Invoke-xSharePointCommand -Credential $InstallAccount -ScriptBlock {
                $icmpFirewallRule = Get-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)" -ErrorAction SilentlyContinue
                if($null -eq $icmpFirewallRule ) {
                    New-NetFirewallRule -Name Allow_Ping -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)" -Description "Allow ICMPv4 ping" -Protocol ICMPv4 -IcmpType 8 -Enabled True -Profile Any -Action Allow 
                }
                Enable-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)"

                $firewallRule = Get-NetFirewallRule -DisplayName "SharePoint Distributed Cache" -ErrorAction SilentlyContinue
                if($null -eq $firewallRule) {
                    New-NetFirewallRule -Name "SPDistCache" -DisplayName "SharePoint Distributed Cache" -Protocol TCP -LocalPort 22233-22236 -Group "SharePoint"
                }
                Enable-NetFirewallRule -DisplayName "SharePoint Distributed Cache"
            }
            Write-Verbose -Message "Firewall rule added"
        }
        Write-Verbose "Current state is '$($CurrentState.Ensure)' and desired state is '$Ensure'"
        if ($CurrentState.Ensure -ne $Ensure) {
            Write-Verbose -Message "Enabling distributed cache service"
            Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
                $params = $args[0]
                
                Add-SPDistributedCacheServiceInstance
                Update-SPDistributedCacheSize -CacheSizeInMB $params.CacheSizeInMB

                $farm = Get-SPFarm
                $cacheService = $farm.Services | Where-Object { $_.Name -eq "AppFabricCachingService" }
                $cacheService.ProcessIdentity.CurrentIdentityType = "SpecificUser"

                $account = Get-SPManagedAccount -Identity $params.ServiceAccount
                $cacheService.ProcessIdentity.ManagedAccount = $account
                $cacheService.ProcessIdentity.Update() 
                $cacheService.ProcessIdentity.Deploy()
            }
        }
    } else {
        Write-Verbose -Message "Removing distributed cache to the server"
        Invoke-xSharePointCommand -Credential $InstallAccount -ScriptBlock {
            $serviceInstance = Get-SPServiceInstance | Where-Object { ($_.Service.Tostring()) -eq "SPDistributedCacheService Name=AppFabricCachingService" -and ($_.Server.Name) -eq $env:computername }
            $serviceInstance.Delete() 
            
            Remove-SPDistributedCacheServiceInstance
        }
        if ($CreateFirewallRules -eq $true) {
            Invoke-xSharePointCommand -Credential $InstallAccount -ScriptBlock {
                $firewallRule = Get-NetFirewallRule -DisplayName "SharePoint Distribute Cache" -ErrorAction SilentlyContinue
                if($null -ne $firewallRule) {
                    Write-Verbose -Message "Disabling firewall rules."
                    Disable-NetFirewallRule -DisplayName "SharePoint Distribute Cache"    
                }
            }  
        }
        Write-Verbose -Message "Distributed cache removed."
    }

    # Remove the FarmAccount from the local Administrators group, if it was added above
    if (!$isLocalAdmin)
    {
        Remove-xSharePointUserToLocalAdmin -UserName $ServiceAccount
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
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("Ensure", "CreateFirewallRules")
}


Export-ModuleMember -Function *-TargetResource

