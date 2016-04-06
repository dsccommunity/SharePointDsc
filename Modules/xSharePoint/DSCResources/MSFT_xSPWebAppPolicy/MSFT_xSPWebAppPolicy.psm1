function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $WebAppUrl,
        [parameter(Mandatory = $false)] [Microsoft.Management.Infrastructure.CimInstance[]] $Members,
        [parameter(Mandatory = $false)] [Microsoft.Management.Infrastructure.CimInstance[]] $MembersToInclude,
        [parameter(Mandatory = $false)] [Microsoft.Management.Infrastructure.CimInstance[]] $MembersToExclude,
        [parameter(Mandatory = $false)] [System.Boolean] $SetCacheAccountsPolicy,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    if ($Members -and (($MembersToInclude) -or ($MembersToExclude))) {
        Write-Verbose -Verbose "Cannot use the Members parameter together with the MembersToInclude or MembersToExclude parameters"
        return $null
    }

    if (!$Members -and !$MembersToInclude -and !$MembersToExclude) {
        Write-Verbose -Verbose "At least one of the following parameters must be specified: Members, MembersToInclude, MembersToExclude"
        return $null
    }

    foreach ($member in $Members) {
        if (($member.ActAsSystemAccount -eq $true) -and ($member.PermissionLevel -ne "Full Control")) {
            Write-Verbose -Verbose "Members Parameter: You cannot specify ActAsSystemAccount with any other permission than Full Control"        
            return $null
        }
    }

    foreach ($member in $MembersToInclude) {
        if (($member.ActAsSystemAccount -eq $true) -and ($member.PermissionLevel -ne "Full Control")) {
            Write-Verbose -Verbose "MembersToInclude Parameter: You cannot specify ActAsSystemAccount with any other permission than Full Control"        
            return $null
        }
    }
    
    Write-Verbose -Message "Getting web app policy for $UserName at $WebAppUrl"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue

        if ($null -eq $wa) { return $null }

        $SetCacheAccountsPolicy = $false
        if ($param.SetCacheAccountsPolicy) {
            if ($wa.Properties.ContainsKey("portalsuperuseraccount") -and $wa.Properties.ContainsKey("portalsuperreaderaccount")) {
                $correctPSU = $false
                $correctPSR = $false

                $psu = $wa.Policies[$wa.Properties["portalsuperuseraccount"]]
                if ($psu -ne $null) {
                    if ($psu.PolicyRoleBindings.Name -contains "Full Control") { $correctPSU = $true }
                }

                $psr = $wa.Policies[$wa.Properties["portalsuperreaderaccount"]]
                if ($psr -ne $null) {
                    if ($psr.PolicyRoleBindings.Name -contains "Full Read") { $correctPSR = $true }
                }

                if ($correctPSU -eq $true -and $correctPSR -eq $true) {
                    $SetCacheAccountsPolicy = $true
                }
            }
        }
           
        $members = @()
        foreach ($policy in $wa.Policies) {
            $member = @{}
            $member.Username = $policy.UserName
            $member.PermissionLevel = $policy.PolicyRoleBindings.Name
            $member.ActAsSystemAccount = $policy.IsSystemUser
            $members += $member
        }

        $returnval = @{
                WebAppUrl = $params.WebAppUrl
                Members = $members
                MembersToInclude = $params.MembersToInclude
                MembersToExclude = $params.MembersToExclude
                SetCacheAccountsPolicy = $SetCacheAccountsPolicy
                InstallAccount = $params.InstallAccount
        }
        
        return $returnval
    }
    return $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $WebAppUrl,
        [parameter(Mandatory = $false)] [Microsoft.Management.Infrastructure.CimInstance[]] $Members,
        [parameter(Mandatory = $false)] [Microsoft.Management.Infrastructure.CimInstance[]] $MembersToInclude,
        [parameter(Mandatory = $false)] [Microsoft.Management.Infrastructure.CimInstance[]] $MembersToExclude,
        [parameter(Mandatory = $false)] [System.Boolean] $SetCacheAccountsPolicy,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Setting web app policy for $UserName at $WebAppUrl"

    if ($Members -and (($MembersToInclude) -or ($MembersToExclude))) {
        Throw "Cannot use the Members parameter together with the MembersToInclude or MembersToExclude parameters"
    }

    if (!$Members -and !$MembersToInclude -and !$MembersToExclude) {
        throw "At least one of the following parameters must be specified: Members, MembersToInclude, MembersToExclude"
    }

    foreach ($member in $Members) {
        if (($member.ActAsSystemAccount -eq $true) -and ($member.PermissionLevel -ne "Full Control")) {
            throw "Members Parameter: You cannot specify ActAsSystemAccount with any other permission than Full Control"        
        }
    }

    foreach ($member in $MembersToInclude) {
        if (($member.ActAsSystemAccount -eq $true) -and ($member.PermissionLevel -ne "Full Control")) {
            throw "MembersToInclude Parameter: You cannot specify ActAsSystemAccount with any other permission than Full Control"        
        }
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters
    
    if ($CurrentValues -eq $null) {
        throw "Web application does not exist"
    }

    $cacheAccounts = Get-CacheAccounts @PSBoundParameters
    
    if ($SetCacheAccountsPolicy) {
        if ($cacheAccounts.SuperUserAccount -eq "" -or $cacheAccounts.SuperReaderAccount -eq "") {
            throw "Cache accounts not configured properly. PortalSuperUserAccount or PortalSuperReaderAccount property is not configured."
        }
    }        

    $changeUsers = @()
        
    if ($Members) {
        Write-Verbose "Processing Members - Start Set"
        
        $allMembers = @()
        foreach ($member in $Members) {
            $allMembers += $member
        }

        if ($SetCacheAccountsPolicy) {
            Write-Verbose "SetCacheAccountsPolicy is True. Adding Cache Accounts to list"
            $psuAccount = @{
                UserName = $cacheAccounts.SuperUserAccount
                PermissionLevel = "Full Control"
            }
            $allMembers += $psuAccount
            
            $psrAccount = @{
                UserName = $cacheAccounts.SuperReaderAccount
                PermissionLevel = "Full Read"
            }
            $allMembers += $psrAccount
        }

        Import-Module (Join-Path $PsScriptRoot "..\..\Modules\xSharePoint.WebAppPolicy\xSPWebAppPolicy.psm1" -Resolve)
        $differences = ComparePolicies $CurrentValues.Members $allMembers

        foreach ($difference in $differences) {
            $username = $difference.Keys[0]
            $change = $difference[$username]
            $usersettings = GetUserFromCollection $allMembers $username
            switch ($change) {
                Additional {
                    $user = @{
                        Type     = "Delete"
                        Username = $username
                    }
                }
                Different {
                    $user = @{
                        Type     = "Change"
                        Username = $username
                        PermissionLevel    = $usersettings.PermissionLevel
                        ActAsSystemAccount = $usersettings.ActAsSystemAccount
                    }
                }
                Missing {
                    $user = @{
                        Type     = "Add"
                        Username = $username
                        PermissionLevel    = $usersettings.PermissionLevel
                        ActAsSystemAccount = $usersettings.ActAsSystemAccount
                    }
                }
            }
            $changeUsers += $user
        }
    }

    if ($MembersToInclude) {
        Write-Verbose "Processing MembersToInclude - Start Set"

        $allMembers = @()
        foreach ($member in $MembersToInclude) {
            $allMembers += $member
        }

        if ($SetCacheAccountsPolicy) {
            Write-Verbose "SetCacheAccountsPolicy is True. Adding Cache Accounts to list"
            $psuAccount = @{
                UserName = $cacheAccounts.SuperUserAccount
                PermissionLevel = "Full Control"
            }
            $allMembers += $psuAccount
            
            $psrAccount = @{
                UserName = $cacheAccounts.SuperReaderAccount
                PermissionLevel = "Full Read"
            }
            $allMembers += $psrAccount
        }
        
        foreach ($member in $allMembers) {
            $policy = $CurrentValues.Members | Where-Object { $_.UserName -eq $member.UserName }
            
            if ($policy -ne $null) {
                $user = @{
                    Type     = "Change"
                    Username = $member.UserName
                    PermissionLevel    = $member.PermissionLevel
                    ActAsSystemAccount = $member.ActAsSystemAccount
                }
            } else {
                $user = @{
                    Type     = "Add"
                    Username = $member.UserName
                    PermissionLevel    = $member.PermissionLevel
                    ActAsSystemAccount = $member.ActAsSystemAccount
                }                
            }
            $changeUsers += $user
        }
    }

    if ($MembersToExclude) {
        Write-Verbose "Processing MembersToExclude - Start Set"

        foreach ($member in $MembersToExclude) {
            $policy = $CurrentValues.Members | Where-Object { $_.UserName -eq $member.UserName }

            if (($cacheAccounts.SuperUserAccount -eq $member.Username) -or ($cacheAccounts.SuperReaderAccount -eq $member.Username)) {
                throw "You cannot exclude the Cache accounts from the Web Application Policy"
            }

            if ($policy -ne $null) {
                $user = @{
                    Type     = "Delete"
                    Username = $member.UserName
                }
            }
            $changeUsers += $user
        }
    }
    
    ## Perform changes
    Invoke-xSharePointCommand -Credential $InstallAccount -Arguments @($PSBoundParameters,$PSScriptRoot,$changeUsers) -ScriptBlock {
        $params      = $args[0]
        $scriptRoot  = $args[1]
        $changeUsers = $args[2]

        Import-Module (Join-Path $scriptRoot "..\..\Modules\xSharePoint.WebAppPolicy\xSPWebAppPolicy.psm1" -Resolve)

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue

        if ($null -eq $wa) {
            throw "Specified web application could not be found."
        }

        $denyAll     = $wa.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::DenyAll)
        $denyWrite   = $wa.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::DenyWrite)
        $fullControl = $wa.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl)
        $fullRead    = $wa.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullRead)

        Write-Verbose -Verbose "Processing changes"

        foreach ($user in $changeUsers) {
            switch ($user.Type) {
                "Add"    {
                    # User does not exist. Add user
                    Write-Verbose -Verbose "Adding $($user.Username)"
                    $newPolicy = $wa.Policies.Add($user.UserName, $user.UserName)
                    foreach ($permissionLevel in $user.PermissionLevel) {
                        switch ($permissionLevel) {
                            "Deny All" {
                                $newPolicy.PolicyRoleBindings.Add($denyAll)
                            }
                            "Deny Write" {
                                $newPolicy.PolicyRoleBindings.Add($denyWrite)
                            }
                            "Full Control" {
                                $newPolicy.PolicyRoleBindings.Add($fullControl)
                            }
                            "Full Read" {
                                $newPolicy.PolicyRoleBindings.Add($fullRead)
                            }
                        }
                    }
                    if ($user.ActAsSystemAccount) {
                        $newPolicy.IsSystemUser = $user.ActAsSystemAccount
                    }                    
                }
                "Change" {
                    # User exists. Check permissions
                    $policy = $wa.Policies | Where-Object { $_.UserName -eq $user.Username }

                    Write-Verbose -Verbose "User $($user.Username) exists, checking permissions"
                    if ($user.ActAsSystemAccount -ne $policy.IsSystemUser) { $policy.IsSystemUser = $user.ActAsSystemAccount }

                    $polbinddiff = Compare-Object -ReferenceObject $policy.PolicyRoleBindings.Name -DifferenceObject $user.PermissionLevel
                    if ($polbinddiff -ne $null) {
                        $policy.PolicyRoleBindings.RemoveAll()
                        foreach ($permissionLevel in $user.PermissionLevel) {
                            switch ($permissionLevel) {
                                "Deny All" {
                                    $policy.PolicyRoleBindings.Add($denyAll)
                                }
                                "Deny Write" {
                                    $policy.PolicyRoleBindings.Add($denyWrite)
                                }
                                "Full Control" {
                                    $policy.PolicyRoleBindings.Add($fullControl)
                                }
                                "Full Read" {
                                    $policy.PolicyRoleBindings.Add($fullRead)
                                }
                            }
                        }
                    }
                }
                "Delete" {
                    Write-Verbose -Verbose "Removing $($user.Username)"
                    Remove-WebAppPolicy $wa.Policies $user.Username
                }
            }
        }
 
        $wa.Update()
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $WebAppUrl,
        [parameter(Mandatory = $false)] [Microsoft.Management.Infrastructure.CimInstance[]] $Members,
        [parameter(Mandatory = $false)] [Microsoft.Management.Infrastructure.CimInstance[]] $MembersToInclude,
        [parameter(Mandatory = $false)] [Microsoft.Management.Infrastructure.CimInstance[]] $MembersToExclude,
        [parameter(Mandatory = $false)] [System.Boolean] $SetCacheAccountsPolicy,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    
    Write-Verbose -Message "Testing web app policy for $UserName at $WebAppUrl"
    
    Import-Module (Join-Path $PSScriptRoot "..\..\Modules\xSharePoint.WebAppPolicy\xSPWebAppPolicy.psm1" -Resolve)

    if ($null -eq $CurrentValues) { return $false }

    $cacheAccounts = Get-CacheAccounts @PSBoundParameters
    if ($SetCacheAccountsPolicy) {
        if ($cacheAccounts.SuperUserAccount -eq "" -or $cacheAccounts.SuperReaderAccount -eq "") {
            throw "Cache accounts not configured properly. PortalSuperUserAccount or PortalSuperReaderAccount property is not configured."
        }
    }
    
    if ($Members) {
        Write-Verbose "Processing Members - Start Test"
        
        $allMembers = @()
        foreach ($member in $Members) {
            $allMembers += $member
        }

        if ($SetCacheAccountsPolicy) {
            Write-Verbose "SetCacheAccountsPolicy is True. Adding Cache Accounts to list"
            $psuAccount = @{
                UserName = $cacheAccounts.SuperUserAccount
                PermissionLevel = "Full Control"
            }
            $allMembers += $psuAccount
            
            $psrAccount = @{
                UserName = $cacheAccounts.SuperReaderAccount
                PermissionLevel = "Full Read"
            }
            $allMembers += $psrAccount
        }

        Import-Module (Join-Path $PsScriptRoot "..\..\Modules\xSharePoint.WebAppPolicy\xSPWebAppPolicy.psm1" -Resolve)
        $differences = ComparePolicies $CurrentValues.Members $allMembers

        if ($differences.Count -eq 0) { return $true } else { return $false }
    }

    if ($MembersToInclude) {
        Write-Verbose "Processing MembersToInclude - Start Test"

        $allMembers = @()
        foreach ($member in $MembersToInclude) {
            $allMembers += $member
        }

        if ($SetCacheAccountsPolicy) {
            Write-Verbose "SetCacheAccountsPolicy is True. Adding Cache Accounts to list"
            $psuAccount = @{
                UserName = $cacheAccounts.SuperUserAccount
                PermissionLevel = "Full Control"
            }
            $allMembers += $psuAccount
            
            $psrAccount = @{
                UserName = $cacheAccounts.SuperReaderAccount
                PermissionLevel = "Full Read"
            }
            $allMembers += $psrAccount
        }
        
        foreach ($member in $allMembers) {            
            $match = $false
            foreach ($policy in $CurrentValues.Members) {
                if ($policy.Username -eq $member.Username) {
                    $match = $true
                    if ($member.ActAsSystemAccount) {
                        if ($policy.ActAsSystemAccount -ne $member.ActAsSystemAccount) { $match = $false }
                    }

                    $polbinddiff = Compare-Object -ReferenceObject $policy.PermissionLevel.ToLower() -DifferenceObject $member.PermissionLevel.ToLower()
                    if ($polbinddiff -ne $null) { $match = $false }
                }
            }
            if ($match -eq $false) { return $match }
        }
        return $true
    }

    if ($MembersToExclude) {
        Write-Verbose "Processing MembersToExclude - Start Test"
        foreach ($member in $MembersToExclude) {
            if (($cacheAccounts.SuperUserAccount -eq $member.Username) -or ($cacheAccounts.SuperReaderAccount -eq $member.Username)) {
                throw "You cannot exclude the Cache accounts from the Web Application Policy"
            }
            
            foreach ($policy in $CurrentValues.Members) {
                if ($policy.Username.ToLower() -eq $member.Username.ToLower()) {
                    return $false
                }
            }
        }
        return $true
    }
}

Export-ModuleMember -Function *-TargetResource

function Get-CacheAccounts() {
    Param (
        $InputParameters
    )
    
    $cacheAccounts = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $InputParameters -ScriptBlock {
        $params = $args[0]

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue

        if ($null -eq $wa) {
            throw "Specified web application could not be found."
        }

        $returnval = @{
            SuperUserAccount = ""               
            SuperReaderAccount = ""
        }

        if ($wa.Properties.ContainsKey("portalsuperuseraccount")) {
            $returnval.SuperUserAccount = $wa.Properties["portalsuperuseraccount"]
        }
        if ($wa.Properties.ContainsKey("portalsuperreaderaccount")) {
            $returnval.SuperReaderAccount = $wa.Properties["portalsuperreaderaccount"]
        }
        
        return $returnval
    }

    return $cacheAccounts
}

#Verplaatsen methode naar eigen utils module
