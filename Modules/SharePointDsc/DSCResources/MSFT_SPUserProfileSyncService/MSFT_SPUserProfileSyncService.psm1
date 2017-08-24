function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  
        [System.String] 
        $UserProfileServiceAppName,

        [parameter(Mandatory = $false)]
        [ValidateSet("Present","Absent")] 
        [System.String] $Ensure = "Present",

        [parameter(Mandatory = $true)]  
        [System.Management.Automation.PSCredential] 
        $FarmAccount,

        [parameter(Mandatory = $false)]
        [System.Boolean] 
        $RunOnlyWhenWriteable,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Getting user profile sync service for $UserProfileServiceAppName"

    if ((Get-SPDSCInstalledProductVersion).FileMajorPart -ne 15) 
    {
        throw [Exception] ("Only SharePoint 2013 is supported to deploy the user profile sync " + `
                           "service via DSC, as 2016 does not use the FIM based sync service.")
    }

    $farmAccountName = Invoke-SPDSCCommand -Credential $InstallAccount `
                                       -Arguments $PSBoundParameters `
                                       -ScriptBlock {
        return Get-SPDSCFarmAccountName
    }

    if ($null -ne $farmAccountName)
    {
        if ($PSBoundParameters.ContainsKey("InstallAccount") -eq $true) 
        {
            # InstallAccount used
            if ($InstallAccount.UserName -ne $farmAccountName)
            {
                throw ("Specified InstallAccount isn't the Farm Account. Make sure " + `
                       "the specified InstallAccount is the Farm Account and try again")
            }
        }
        else {
            # PSDSCRunAsCredential or System
            if (-not $Env:USERNAME.Contains("$"))
            {
                # PSDSCRunAsCredential used
                $localaccount = "$($Env:USERDOMAIN)\$($Env:USERNAME)"
                if ($localaccount -ne $farmAccountName)
                {
                    throw ("Specified PSDSCRunAsCredential isn't the Farm Account. Make sure " + `
                           "the specified Install Account is the Farm Account and try again")
                }
            }
        }
    }
    else
    {
        throw ("Unable to retrieve the Farm Account. Check if the farm exists.")
    }

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]
        
        $syncServices = Get-SPServiceInstance -Server $env:COMPUTERNAME `
                        -ErrorAction SilentlyContinue
        
        if ($null -eq $syncServices)
        {
            return @{
                UserProfileServiceAppName = $params.UserProfileServiceAppName
                Ensure = "Absent"
                RunOnlyWhenWriteable = $params.RunOnlyWhenWriteable
                InstallAccount = $params.InstallAccount
            }
        }
        
        $syncService = $syncServices | Where-Object -FilterScript { 
            $_.GetType().Name -eq "UserProfileServiceInstance"
        }

        if ($null -eq $syncService) 
        { 
            $domain = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain
            $currentServer = "$($env:COMPUTERNAME).$domain"
            $syncServices = Get-SPServiceInstance -Server $currentServer `
                                                  -ErrorAction SilentlyContinue
            $syncService = $syncServices | Where-Object -FilterScript { 
                $_.GetType().Name -eq "UserProfileServiceInstance" 
            }
        }

        if ($null -eq $syncService) 
        { 
            return @{
                UserProfileServiceAppName = $params.UserProfileServiceAppName
                Ensure = "Absent"
                RunOnlyWhenWriteable = $params.RunOnlyWhenWriteable
                InstallAccount = $params.InstallAccount
            } 
        }
        if ($null -ne $syncService.UserProfileApplicationGuid -and `
            $syncService.UserProfileApplicationGuid -ne [Guid]::Empty) 
        {
            $upa = Get-SPServiceInstance -Identity $syncService.UserProfileApplicationGuid `
                                         -ErrorAction SilentlyContinue
        }
        if ($syncService.Status -eq "Online") 
        { 
            $localEnsure = "Present" 
        } 
        else 
        { 
            $localEnsure = "Absent" 
        }

        return @{
            UserProfileServiceAppName = $upa.Name
            Ensure = $localEnsure
            RunOnlyWhenWriteable = $params.RunOnlyWhenWriteable
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
        [parameter(Mandatory = $true)]  
        [System.String] 
        $UserProfileServiceAppName,

        [parameter(Mandatory = $false)]
        [ValidateSet("Present","Absent")] 
        [System.String] $Ensure = "Present",

        [parameter(Mandatory = $true)]  
        [System.Management.Automation.PSCredential] 
        $FarmAccount,

        [parameter(Mandatory = $false)]
        [System.Boolean] 
        $RunOnlyWhenWriteable,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Setting user profile sync service for $UserProfileServiceAppName"

    $PSBoundParameters.Ensure = $Ensure

    if ((Get-SPDSCInstalledProductVersion).FileMajorPart -ne 15) 
    {
        throw [Exception] ("Only SharePoint 2013 is supported to deploy the user profile sync " + `
                           "service via DSC, as 2016 does not use the FIM based sync service.")
    }

    $farmAccountName = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        return Get-SPDSCFarmAccountName
    }

    if ($null -ne $farmAccountName)
    {
        if ($PSBoundParameters.ContainsKey("InstallAccount") -eq $true) 
        {
            # InstallAccount used
            if ($InstallAccount.UserName -ne $farmAccountName)
            {
                throw ("Specified InstallAccount isn't the Farm Account. Make sure " + `
                       "the specified InstallAccount is the Farm Account and try again")
            }
        }
        else {
            # PSDSCRunAsCredential or System
            if (-not $Env:USERNAME.Contains("$"))
            {
                # PSDSCRunAsCredential used
                $localaccount = "$($Env:USERDOMAIN)\$($Env:USERNAME)"
                if ($localaccount -ne $farmAccountName)
                {
                    throw ("Specified PSDSCRunAsCredential isn't the Farm Account. Make sure " + `
                           "the specified Install Account is the Farm Account and try again")
                }
            }
        }
    }
    else
    {
        throw ("Unable to retrieve the Farm Account. Check if the farm exists.")
    }

    if ($PSBoundParameters.ContainsKey("RunOnlyWhenWriteable") -eq $true)
    {
        $databaseReadOnly = Test-SPDscUserProfileDBReadOnly `
                                -UserProfileServiceAppName $UserProfileServiceAppName `
                                -InstallAccount $InstallAccount
                                
        if ($databaseReadOnly)
        {
            Write-Verbose -Message ("User profile database is read only, setting user profile " + `
                                   "sync service to not run on the local server")
            $PSBoundParameters.Ensure = "Absent"
        }
        else 
        {
            $PSBoundParameters.Ensure = "Present"
        }
    }

    # Add the Farm Account to the local Admins group, if it's not already there
    $isLocalAdmin = Test-SPDSCUserIsLocalAdmin -UserName $farmAccountName

    if (!$isLocalAdmin)
    {
        Add-SPDSCUserToLocalAdmin -UserName $farmAccountName

        # Cycle the Timer Service so that it picks up the local Admin token
        Restart-Service -Name "SPTimerV4"
    }

    try 
    {
        Invoke-SPDSCCommand -Credential $InstallAccount -Arguments ($PSBoundParameters,$farmAccountName) -ScriptBlock {
            $params = $args[0]
            $farmAccountName = $args[1]

            $currentServer = $env:COMPUTERNAME

            $syncServices = Get-SPServiceInstance -Server $currentServer `
                                                  -ErrorAction SilentlyContinue
            $syncService = $syncServices | Where-Object -FilterScript { 
                $_.GetType().Name -eq "UserProfileServiceInstance"  
            }
            if ($null -eq $syncService) 
            { 
                $domain = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain
                $currentServer = "$currentServer.$domain"
                $syncService = $syncServices | Where-Object -FilterScript { 
                    $_.GetType().Name -eq "UserProfileServiceInstance"  
                }
            }
            if ($null -eq $syncService) 
            {
                throw "Unable to locate a user profile service instance on $currentServer to start"
            }
            
            # Start the Sync service if it should be running on this server
            if (($params.Ensure -eq "Present") -and ($syncService.Status -ne "Online")) 
            {
                $serviceApps = Get-SPServiceApplication -Name $params.UserProfileServiceAppName `
                                                        -ErrorAction SilentlyContinue 
                if ($null -eq $serviceApps) { 
                    throw [Exception] ("No user profile service was found " + `
                                       "named $($params.UserProfileServiceAppName)")
                }
                $ups = $serviceApps | Where-Object -FilterScript { 
                    $_.GetType().FullName -eq "Microsoft.Office.Server.Administration.UserProfileApplication" 
                }

                $userName = $farmAccountName
                $password = $params.FarmAccount.GetNetworkCredential().Password
                $ups.SetSynchronizationMachine($currentServer, $syncService.ID, $userName, $password)

                Start-SPServiceInstance -Identity $syncService.ID 
                
                $desiredState = "Online"
            }
            # Stop the Sync service in all other cases
            else 
            {
                Stop-SPServiceInstance -Identity $syncService.ID -Confirm:$false
                $desiredState = "Disabled"
            }

            $count = 0
            $maxCount = 10

            while (($count -lt $maxCount) -and ($syncService.Status -ne $desiredState)) 
            {
                if ($syncService.Status -ne $desiredState) 
                { 
                    Start-Sleep -Seconds 60 
                }
                # Get the current status of the Sync service
                Write-Verbose ("$([DateTime]::Now.ToShortTimeString()) - Waiting for user profile " + `
                            "sync service to become '$desiredState' (waited $count of " + `
                            "$maxCount minutes)")
                $syncService = $syncServices | Where-Object -FilterScript { 
                    $_.GetType().Name -eq "UserProfileServiceInstance"  
                }
                $count++
            }
        }  
    }
    finally 
    {
        # Remove the Farm Account from the local Admins group, if it was added above
        if (!$isLocalAdmin)
        {
            Remove-SPDSCUserToLocalAdmin -UserName $farmAccountName
        }
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

        [parameter(Mandatory = $false)]
        [ValidateSet("Present","Absent")] 
        [System.String] $Ensure = "Present",

        [parameter(Mandatory = $true)]  
        [System.Management.Automation.PSCredential] 
        $FarmAccount,

        [parameter(Mandatory = $false)]
        [System.Boolean] 
        $RunOnlyWhenWriteable,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Testing user profile sync service for $UserProfileServiceAppName"

    $PSBoundParameters.Ensure = $Ensure

    if ((Get-SPDSCInstalledProductVersion).FileMajorPart -ne 15) 
    {
        throw [Exception] ("Only SharePoint 2013 is supported to deploy the user profile sync " + `
                           "service via DSC, as 2016 does not use the FIM based sync service.")
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($PSBoundParameters.ContainsKey("RunOnlyWhenWriteable") -eq $true)
    {
        $databaseReadOnly = Test-SPDscUserProfileDBReadOnly `
                                -UserProfileServiceAppName $UserProfileServiceAppName `
                                -InstallAccount $InstallAccount

        if ($databaseReadOnly)
        {
            Write-Verbose -Message ("User profile database is read only, setting user profile " + `
                                   "sync service to not run on the local server")
            $PSBoundParameters.Ensure = "Absent"
        }
        else 
        {
            $PSBoundParameters.Ensure = "Present"
        }
    }
    
    Write-Verbose -Message "Testing for User Profile Synchronization Service"
    
    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @("Ensure")
}

function Test-SPDscUserProfileDBReadOnly() 
{
    param(
        [Parameter(Mandatory = $true)]
        [String]
        $UserProfileServiceAppName,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    $databaseReadOnly = Invoke-SPDSCCommand -Credential $InstallAccount `
                                            -Arguments $UserProfileServiceAppName `
                                            -ScriptBlock {
        $UserProfileServiceAppName = $args[0]

        $serviceApps = Get-SPServiceApplication -Name $UserProfileServiceAppName `
                                                -ErrorAction SilentlyContinue 
        if ($null -eq $serviceApps) 
        { 
            throw [Exception] ("No user profile service was found " + `
                               "named $UserProfileServiceAppName")
        }
        $ups = $serviceApps | Where-Object -FilterScript { 
            $_.GetType().FullName -eq "Microsoft.Office.Server.Administration.UserProfileApplication"
        }

        $propType = $ups.GetType()
        $propData = $propType.GetProperties([System.Reflection.BindingFlags]::Instance -bor `
                                            [System.Reflection.BindingFlags]::NonPublic)
        $profileProp = $propData | Where-Object -FilterScript {
            $_.Name -eq "ProfileDatabase"
        }
        $profileDBName = $profileProp.GetValue($ups).Name

        $database = Get-SPDatabase | Where-Object -FilterScript { 
            $_.Name -eq $profileDBName
        }
        return $database.IsReadyOnly
    }
    return $databaseReadOnly
}

Export-ModuleMember -Function *-TargetResource

