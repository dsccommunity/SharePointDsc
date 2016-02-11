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
        [parameter(Mandatory = $false)] [System.String[]] $ServerProvisionOrder,
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
            $cacheHostConfig = Get-AFCacheHostConfiguration -ComputerName $computerName -CachePort ($cacheHost | Where-Object { $_.HostName -eq $computerName }).PortNo -ErrorAction SilentlyContinue

            $windowsService = Get-WmiObject "win32_service" -Filter "Name='AppFabricCachingService'"
            $firewallRule = Get-NetFirewallRule -DisplayName "SharePoint Distributed Cache" -ErrorAction SilentlyContinue

            return @{
                Name = $params.Name
                CacheSizeInMB = $cacheHostConfig.Size
                ServiceAccount = $windowsService.StartName
                CreateFirewallRules = ($firewallRule -ne $null)
                Ensure = "Present"
                ServerProvisionOrder = $params.ServerProvisionOrder
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
        [parameter(Mandatory = $false)] [System.String[]] $ServerProvisionOrder,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentState = Get-TargetResource @PSBoundParameters

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

                if ($params.ContainsKey("ServerProvisionOrder")) {
                    # Determine where in the order the current server sits

                    #lowercase the server name array
                    $i = 0
                    while ($i -lt $params.ServerProvisionOrder.Length) {
                        $params.ServerProvisionOrder[$i] = $params.ServerProvisionOrder[$i].ToString().ToLower()
                        $i++
                    }
                    $CurrentDcacheNode = [Array]::IndexOf($params.ServerProvisionOrder, $env:COMPUTERNAME.ToLower())

                    if ($CurrentDcacheNode -lt 0) {
                        throw "The server $($env:COMPUTERNAME) was not found in the array for distributed cache servers"
                    }

                    if ($CurrentDcacheNode -gt 0) {
                        # if its not the first in the queue, we need to wait for the server before it

                        $previousServer = $params.ServerProvisionOrder[$CurrentDcacheNode - 1]

                        $count = 0
                        $maxCount = 30
                        while (($count -lt $maxCount) -and ((Get-SPServiceInstance -Server $previousServer | ? { $_.TypeName -eq "Distributed Cache" -and $_.Status -ne "Online" }) -ne $null)) {
                            Start-Sleep -Seconds 60
                            $count++
                        }

                        if ((Get-SPServiceInstance -Server $previousServer | ? { $_.TypeName -eq "Distributed Cache" -and $_.Status -eq "Online" }) -eq $null) {
                            Write-Warning "Server $previousServer is not running distributed cache after waiting 30 minutes. No longer waiting for this server to begin"
                        }
                    }
                }


                Add-SPDistributedCacheServiceInstance

                Get-SPServiceInstance | Where-Object { $_.TypeName -eq "Distributed Cache" } | Stop-SPServiceInstance -Confirm:$false

                $count = 0
                $maxCount = 30
                while (($count -lt $maxCount) -and ((Get-SPServiceInstance | ? { $_.TypeName -eq "Distributed Cache" -and $_.Status -ne "Disabled" }) -ne $null)) {
                    Start-Sleep -Seconds 60
                    $count++
                }

                Update-SPDistributedCacheSize -CacheSizeInMB $params.CacheSizeInMB

                Get-SPServiceInstance | Where-Object { $_.TypeName -eq "Distributed Cache" } | Start-SPServiceInstance 

                $count = 0
                $maxCount = 30
                while (($count -lt $maxCount) -and ((Get-SPServiceInstance | ? { $_.TypeName -eq "Distributed Cache" -and $_.Status -ne "Online" }) -ne $null)) {
                    Start-Sleep -Seconds 60
                    $count++
                }

                $farm = Get-SPFarm
                $cacheService = $farm.Services | Where-Object { $_.Name -eq "AppFabricCachingService" }

                if ($cacheService.ProcessIdentity.ManagedAccount.Username -ne $params.ServiceAccount) {
                    $cacheService.ProcessIdentity.CurrentIdentityType = "SpecificUser"
                    $account = Get-SPManagedAccount -Identity $params.ServiceAccount
                    $cacheService.ProcessIdentity.ManagedAccount = $account
                    $cacheService.ProcessIdentity.Update() 
                    $cacheService.ProcessIdentity.Deploy()
                }
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
        [parameter(Mandatory = $false)] [System.String[]] $ServerProvisionOrder,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing for distributed cache configuration"
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("Ensure", "CreateFirewallRules")
}


Export-ModuleMember -Function *-TargetResource

