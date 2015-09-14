function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $UserProfileServiceAppName,
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")] [System.String] $Ensure,
        [parameter(Mandatory = $true)]  [System.Management.Automation.PSCredential] $FarmAccount,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )
    Write-Verbose -Message "Getting the local user profile sync service instance"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $syncService = Invoke-xSharePointSPCmdlet -CmdletName "Get-SPServiceInstance" -Arguments @{ Server = $env:COMPUTERNAME } | Where-Object { $_.TypeName -eq (Get-xSharePointServiceApplicationName -Name UserProfileSync) }

        if ($syncService.UserProfileApplicationGuid -ne [Guid]::Empty) {
            $upa = Invoke-xSharePointSPCmdlet -CmdletName "Get-SPServiceInstance" -Arguments @{ Identity = $syncService.UserProfileApplicationGuid } -ErrorAction SilentlyContinue
        }        
        if ($null -eq $syncService) { return @{} }

        if ($syncService.Status -eq "Online") { $localEnsure = "Present" } else { $localEnsure = "Absent" }

        $spFarm = Invoke-xSharePointSPCmdlet -CmdletName "Get-SPFarm"

            if ($params.FarmAccount.UserName -eq $spFarm.DefaultServiceAccount.Name) {
                $farmAccount = $params.FarmAccount
            } else {
                $farmAccount = $spFarm.DefaultServiceAccount.Name
            }

        return @{
            UserProfileServiceAppName = $upa.Name
            Ensure = $localEnsure
            FarmAccount = $farmAccount
            InstallAccount = $params.InstallAccount
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
        [parameter(Mandatory = $true)]  [System.String] $UserProfileServiceAppName,
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")] [System.String] $Ensure,
        [parameter(Mandatory = $true)]  [System.Management.Automation.PSCredential] $FarmAccount,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Setting User Profile Synchronization Service"

    # Add the FarmAccount to the local Admins group, if it's not already there
    $isLocalAdmin = Test-xSharePointUserIsLocalAdmin -UserName $FarmAccount.UserName

    if (!$isLocalAdmin)
    {
        Add-xSharePointUserToLocalAdmin -UserName $FarmAccount.UserName

        # Cycle the Timer Service so that it picks up the local Admin token
        Restart-Service -Name "SPTimerV4"
    }

    Invoke-xSharePointCommand -Credential $FarmAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $syncService = Invoke-xSharePointSPCmdlet -CmdletName "Get-SPServiceInstance" -Arguments @{ Server = $env:COMPUTERNAME } | Where-Object { $_.TypeName -eq (Get-xSharePointServiceApplicationName -Name UserProfileSync) }
        
         # Start the Sync service if it should be running on this server
        if (($Ensure -eq "Present") -and ($syncService.Status -ne "Online")) {

            Set-xSharePointUserProfileSyncMachine -UserProfileServiceAppName $params.UserProfileServiceAppName -SyncServiceId $syncService.ID -FarmAccount $params.FarmAccount            
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

        while (($count -lt $maxCount) -and ($syncService.Status -ne $desiredState)) {
            # Get the current status of the Sync service
            $syncService = Invoke-xSharePointSPCmdlet -CmdletName "Get-SPServiceInstance" -Arguments @{ Server = $env:COMPUTERNAME } | Where-Object { $_.TypeName -eq (Get-xSharePointServiceApplicationName -Name UserProfileSync) }

            if ($syncService.Status -ne $desiredState) { Start-Sleep -Seconds 60 }
            $count++
        }
    }

    # Remove the FarmAccount from the local Admins group, if it was added above
    if (!$isLocalAdmin)
    {
        Remove-xSharePointUserToLocalAdmin -UserName $FarmAccount.UserName
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $UserProfileServiceAppName,
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")] [System.String] $Ensure,
        [parameter(Mandatory = $true)]  [System.Management.Automation.PSCredential] $FarmAccount,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing for User Profile Synchronization Service"
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("Ensure")
}


Export-ModuleMember -Function *-TargetResource

