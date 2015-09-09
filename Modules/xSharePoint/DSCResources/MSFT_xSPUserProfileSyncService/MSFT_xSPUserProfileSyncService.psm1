function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $UserProfileServiceAppName,

        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $FarmAccount,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )
    Write-Verbose -Message "Getting the local user profile sync service instance"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $syncService = Get-xSharePointServiceApplication -Name $params.Name -TypeName UserProfileSync
        
        if ($null -eq $syncService) { return @{} }

        return @{
            Status = $syncService.Status
        }
    }
    return $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $UserProfileServiceAppName,

        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $FarmAccount,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting User Profile Synchronization Service"
    

    $domainName = $FarmAccount.UserName.Split('\')[0]
    $userName = $FarmAccount.UserName.Split('\')[1]
    $computerName = "$env:computername"

    # Add the FarmAccount to the local Admins group, if it's not already there
    $isLocalAdmin = ([ADSI]"WinNT://$computerName/Administrators,group").PSBase.Invoke("Members") | 
        ForEach-Object {$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)} | 
        Where-Object { $_ -eq $userName }

    if (!$isLocalAdmin)
    {
        ([ADSI]"WinNT://$computerName/Administrators,group").Add("WinNT://$domainName/$userName") | Out-Null

        # Cycle the Timer Service so that it picks up the local Admin token
        Restart-Service -Name "SPTimerV4"
    }

    Invoke-xSharePointCommand -Credential $FarmAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $syncService = Get-xSharePointServiceApplication -Name $params.Name -TypeName UserProfileSync
        
         # Start the Sync service if it should be running on this server
        if (($Ensure -eq "Present") -and ($syncService.Status -ne "Online")) {
			$ups = Get-xSharePointServiceApplication -Name $params.UserProfileServiceAppName -TypeName UserProfile
            $ups.SetSynchronizationMachine($env:COMPUTERNAME, $syncService.ID, $params.FarmAccount.UserName, $params.FarmAccount.GetNetworkCredential().Password)
            
			Invoke-xSharePointSPCmdlet -CmdletName "Start-SPServiceInstance" -Arguments @{ Identity = $syncService.ID }
            
			$desiredState = "Online"
        }
        # Stop the Sync service in all other cases
        else {
            Invoke-xSharePointSPCmdlet -CmdletName "Stop-SPServiceInstance" -Arguments @{ Identity = $syncService.ID; Confirm = $false }
            $desiredState = "Disabled"
        }

        $wait = $true
        $count = 0
        $maxCount = 10
        while ($wait) {
            Start-Sleep -Seconds 60

            # Get the current status of the Sync service
            $syncService = Get-xSharePointServiceApplication -Name $params.Name -TypeName UserProfileSync

            # Continue to wait if haven't reached $maxCount or $desiredState
            $wait = (($count -lt $maxCount) -and ($syncService.Status -ne $desiredState))
            $count++             
        }
    }

    # Remove the FarmAccount from the local Admins group, if it was added above
    if (!$isLocalAdmin)
    {
        ([ADSI]"WinNT://$computerName/Administrators,group").Remove("WinNT://$domainName/$userName") | Out-Null
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
        $UserProfileServiceAppName,

        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $FarmAccount,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    $result = Get-TargetResource -UserProfileServiceAppName $UserProfileServiceAppName -Ensure $Ensure -FarmAccount $FarmAccount -InstallAccount $InstallAccount
    Write-Verbose -Message "Testing for User Profile Synchronization Service"
    if ($result.Count -eq 0) { return $false }
    else {
        if (($result.Status -eq "Online") -and ($Ensure -ne "Present")) { return $false }
        if (($result.Status -eq "Disabled") -and ($Ensure -ne "Absent")) { return $false }
    }
    return $true
}


Export-ModuleMember -Function *-TargetResource

