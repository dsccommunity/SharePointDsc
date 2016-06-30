function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $UserProfileServiceAppName,
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] [System.String] $Ensure = "Present",
        [parameter(Mandatory = $true)]  [System.Management.Automation.PSCredential] $FarmAccount,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    if ((Get-SPDSCInstalledProductVersion).FileMajorPart -ne 15) {
        throw [Exception] "Only SharePoint 2013 is supported to deploy the user profile sync service via DSC, as 2016 does not use the FIM based sync service."
    }

    Write-Verbose -Message "Getting the local user profile sync service instance"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        

        $syncService = Get-SPServiceInstance -Server $env:COMPUTERNAME | Where-Object { $_.TypeName -eq "User Profile Synchronization Service" }
        if ($null -eq $syncService) { 
            $domain = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain
            $currentServer = "$($env:COMPUTERNAME).$domain"
            $syncService = Get-SPServiceInstance -Server $currentServer | Where-Object { $_.TypeName -eq "User Profile Synchronization Service" }
        }

        if ($null -eq $syncService) { return @{
            UserProfileServiceAppName = $params.UserProfileServiceAppName
            Ensure = "Absent"
            FarmAccount = $params.FarmAccount
            InstallAccount = $params.InstallAccount
        } }
        if ($null -ne $syncService.UserProfileApplicationGuid -and $syncService.UserProfileApplicationGuid -ne [Guid]::Empty) {
            $upa = Get-SPServiceInstance -Identity $syncService.UserProfileApplicationGuid -ErrorAction SilentlyContinue
        }
        if ($syncService.Status -eq "Online") { $localEnsure = "Present" } else { $localEnsure = "Absent" }

        $spFarm = Get-SPFarm

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
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] [System.String] $Ensure = "Present",
        [parameter(Mandatory = $true)]  [System.Management.Automation.PSCredential] $FarmAccount,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $PSBoundParameters.Ensure = $Ensure
    if ((Get-SPDSCInstalledProductVersion).FileMajorPart -ne 15) {
        throw [Exception] "Only SharePoint 2013 is supported to deploy the user profile sync service via DSC, as 2016 does not use the FIM based sync service."
    }

    Write-Verbose -Message "Setting User Profile Synchronization Service"

    # Add the FarmAccount to the local Admins group, if it's not already there
    $isLocalAdmin = Test-SPDSCUserIsLocalAdmin -UserName $FarmAccount.UserName

    if (!$isLocalAdmin)
    {
        Add-SPDSCUserToLocalAdmin -UserName $FarmAccount.UserName

        # Cycle the Timer Service so that it picks up the local Admin token
        Restart-Service -Name "SPTimerV4"
    }

    Invoke-SPDSCCommand -Credential $FarmAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
        $currentServer = $env:COMPUTERNAME
        $syncService = Get-SPServiceInstance -Server $currentServer | Where-Object { $_.TypeName -eq "User Profile Synchronization Service" }
        if ($null -eq $syncService) { 
            $domain = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain
            $currentServer = "$currentServer.$domain"
            $syncService = Get-SPServiceInstance -Server $currentServer | Where-Object { $_.TypeName -eq "User Profile Synchronization Service" }
        }
        if ($null -eq $syncService) {
            throw "Unable to locate a user profile service instance on $currentServer to start"
        }
        
         # Start the Sync service if it should be running on this server
        if (($params.Ensure -eq "Present") -and ($syncService.Status -ne "Online")) {
            $serviceApps = Get-SPServiceApplication -Name $params.UserProfileServiceAppName -ErrorAction SilentlyContinue 
            if ($null -eq $serviceApps) { 
                throw [Exception] "No user profile service was found named $($params.UserProfileServiceAppName)"
            }
            $ups = $serviceApps | Where-Object { $_.TypeName -eq "User Profile Service Application" }
            $ups.SetSynchronizationMachine($currentServer, $syncService.ID, $params.FarmAccount.UserName, $params.FarmAccount.GetNetworkCredential().Password)

            Start-SPServiceInstance -Identity $syncService.ID 
            
            $desiredState = "Online"
        }
        # Stop the Sync service in all other cases
        else {
            Stop-SPServiceInstance -Identity $syncService.ID -Confirm:$false
            $desiredState = "Disabled"
        }

        $count = 0
        $maxCount = 10

        while (($count -lt $maxCount) -and ($syncService.Status -ne $desiredState)) {
            if ($syncService.Status -ne $desiredState) { Start-Sleep -Seconds 60 }
            # Get the current status of the Sync service
            Write-Verbose "$([DateTime]::Now.ToShortTimeString()) - Waiting for user profile sync service to become '$desiredState' (waited $count of $maxCount minutes)"
            $syncService = Get-SPServiceInstance -Server $currentServer | Where-Object { $_.TypeName -eq "User Profile Synchronization Service" }
            $count++
        }
    }

    # Remove the FarmAccount from the local Admins group, if it was added above
    if (!$isLocalAdmin)
    {
        Remove-SPDSCUserToLocalAdmin -UserName $FarmAccount.UserName
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $UserProfileServiceAppName,
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] [System.String] $Ensure = "Present",
        [parameter(Mandatory = $true)]  [System.Management.Automation.PSCredential] $FarmAccount,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    if ((Get-SPDSCInstalledProductVersion).FileMajorPart -ne 15) {
        throw [Exception] "Only SharePoint 2013 is supported to deploy the user profile sync service via DSC, as 2016 does not use the FIM based sync service."
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing for User Profile Synchronization Service"
    $PSBoundParameters.Ensure = $Ensure
    return Test-SPDSCSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("Ensure")
}


Export-ModuleMember -Function *-TargetResource

