function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $ServiceAppName,
        [parameter(Mandatory = $true)]  [ValidateSet("Administrators","SharingPermissions")] [System.String] $SecurityType,
        [parameter(Mandatory = $false)] [Microsoft.Management.Infrastructure.CimInstance[]] $Members,
        [parameter(Mandatory = $false)] [Microsoft.Management.Infrastructure.CimInstance[]] $MembersToInclude,
        [parameter(Mandatory = $false)] [System.String[]] $MembersToExclude,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    if ($Members -and (($MembersToInclude) -or ($MembersToExclude))) {
        Throw "Cannot use the Members parameter together with the MembersToInclude or MembersToExclude parameters"
    }

    if (!$Members -and !$MembersToInclude -and !$MembersToExclude) {
        throw "At least one of the following parameters must be specified: Members, MembersToInclude, MembersToExclude"
    }

    Write-Verbose -Message "Getting all security options for $SecurityType in $ServiceAppName"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $serviceApp = Get-SPServiceApplication -Name $params.ServiceAppName
        
        if ($null -eq $serviceApp) {
            return @{
                ServiceAppName = ""
                SecurityType = $params.SecurityType
                InstallAccount = $params.InstallAccount
            }
        }
        
        switch ($params.SecurityType) {
            "Administrators" { 
                $security = $serviceApp | Get-SPServiceApplicationSecurity -Admin
             }
            "SharingPermissions" {
                $security = $serviceApp | Get-SPServiceApplicationSecurity
            }
        }
        
        $members = @()
        foreach ($securityEntry in $security.AccessRules) {
            
            $user = $securityEntry.Name
            if ($user -like "i:*|*" -or $user -like "c:*|*") {
                $user = (New-SPClaimsPrincipal -Identity $user -IdentityType EncodedClaim).Value
                if ($user -match "^s-1-[0-59]-\d+-\d+-\d+-\d+-\d+")
                {
                    $user = Resolve-SPDscSecurityIdentifier -SID $user
                }
            }
            $members += @{
                Username    = $user
                AccessLevel = $securityEntry.AllowedRights.ToString().Replace("FullControl", "Full Control").Replace("ChangePermissions", "Change Permissions")
            }
        }
        
        return @{
            ServiceAppName   = $params.ServiceAppName
            SecurityType     = $params.SecurityType
            Members          = $members
            MembersToInclude = $params.MembersToInclude
            MembersToExclude = $params.MembersToExclude
            InstallAccount   = $params.InstallAccount
        }
    }
    return $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $ServiceAppName,
        [parameter(Mandatory = $true)]  [ValidateSet("Administrators","SharingPermissions")] [System.String] $SecurityType,
        [parameter(Mandatory = $false)] [Microsoft.Management.Infrastructure.CimInstance[]] $Members,
        [parameter(Mandatory = $false)] [Microsoft.Management.Infrastructure.CimInstance[]] $MembersToInclude,
        [parameter(Mandatory = $false)] [System.String[]] $MembersToExclude,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Setting service app security config"
    
    if ($Members -and (($MembersToInclude) -or ($MembersToExclude))) {
        Throw "Cannot use the Members parameter together with the MembersToInclude or MembersToExclude parameters"
    }

    if (!$Members -and !$MembersToInclude -and !$MembersToExclude) {
        throw "At least one of the following parameters must be specified: Members, MembersToInclude, MembersToExclude"
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters
    
    if ([System.String]::IsNullOrEmpty($CurrentValues.ServiceAppName) -eq $true) { 
        throw "Unable to locate service application $ServiceAppName"
    }
    
    Invoke-SPDSCCommand -Credential $InstallAccount -Arguments @($PSBoundParameters, $CurrentValues) -ScriptBlock {
        $params = $args[0]
        $CurrentValues = $args[1]
        
        $serviceApp = Get-SPServiceApplication -Name $params.ServiceAppName
        switch ($params.SecurityType) {
            "Administrators" { 
                $security = $serviceApp | Get-SPServiceApplicationSecurity -Admin
             }
            "SharingPermissions" {
                $security = $serviceApp | Get-SPServiceApplicationSecurity
            }
        }
         
        if ($params.ContainsKey("Members") -eq $true) {
            # Iterate the desired members to make sure they are present with correct settings
            foreach($desiredMember in $params.Members) {
                $isUser = Test-SPDSCIsADUser -IdentityName $desiredMember.Username
                if ($isUser -eq $true) {
                    $claim = New-SPClaimsPrincipal -Identity $desiredMember.Username -IdentityType WindowsSamAccountName    
                } else {
                    $claim = New-SPClaimsPrincipal -Identity $desiredMember.Username -IdentityType WindowsSecurityGroupName
                }
                                
                if ($CurrentValues.Members.Username -contains $desiredMember.Username) {
                    # The user already has a permission, check that it is correct
                    if (($CurrentValues.Members | Where-Object { $_.Username -eq $desiredMember.Username } | Select-Object -First 1).AccessLevel -ne $desiredMember.AccessLevel) {
                        # Current permission for user doesn't match what it should, remove them and re-add them        
                        Revoke-SPObjectSecurity -Identity $security -Principal $claim
                        Grant-SPObjectSecurity -Identity $security -Principal $claim -Rights $desiredMember.AccessLevel
                    }
                } else {
                    # The desired member is not on the list, add them
                    Grant-SPObjectSecurity -Identity $security -Principal $claim -Rights $desiredMember.AccessLevel
                }
            }
            
            # Iterate the current members to make sure they are in the desired list, remove those who aren't
            foreach($currentMember in $CurrentValues.Members) {
                if ($params.Members.Username -notcontains $currentMember.Username) {
                    # Current member is not in desired members list, remove it
                    $isUser = Test-SPDSCIsADUser -IdentityName $desiredMember.Username
                    if ($isUser -eq $true) {
                        $claim = New-SPClaimsPrincipal -Identity $desiredMember.Username -IdentityType WindowsSamAccountName    
                    } else {
                        $claim = New-SPClaimsPrincipal -Identity $desiredMember.Username -IdentityType WindowsSecurityGroupName
                    }
                    Revoke-SPObjectSecurity -Identity $security -Principal $claim
                }
            }
        }

        if ($params.ContainsKey("MembersToInclude") -eq $true) {
            # Iterate the desired members to make sure they are present with correct settings
            foreach($desiredMember in $params.MembersToInclude) {
                $isUser = Test-SPDSCIsADUser -IdentityName $desiredMember.Username
                if ($isUser -eq $true) {
                    $claim = New-SPClaimsPrincipal -Identity $desiredMember.Username -IdentityType WindowsSamAccountName    
                } else {
                    $claim = New-SPClaimsPrincipal -Identity $desiredMember.Username -IdentityType WindowsSecurityGroupName
                }
                if ($CurrentValues.Members.Username -contains $desiredMember.Username) {
                    # The user already has a permission, check that it is correct
                    if (($CurrentValues.Members | Where-Object { $_.Username -eq $desiredMember.Username } | Select-Object -First 1).AccessLevel -ne $desiredMember.AccessLevel) {
                        # Current permission for user doesn't match what it should, remove them and re-add them
                        Revoke-SPObjectSecurity -Identity $security -Principal $claim
                        Grant-SPObjectSecurity -Identity $security -Principal $claim -Rights $desiredMember.AccessLevel
                    }
                } else {
                    # The desired member is not on the list, add them
                    Grant-SPObjectSecurity -Identity $security -Principal $claim -Rights $desiredMember.AccessLevel
                }
            }
        }

        if ($params.ContainsKey("MembersToExclude") -eq $true) {
            # Iterate the excluded members to remove those who should not have access
            foreach($excludeMember in $params.MembersToExclude) {
                if ($CurrentValues.Members.Username -contains $excludeMember) {
                    # Member has permission, removing it
                    $isUser = Test-SPDSCIsADUser -IdentityName $desiredMember.Username
                    if ($isUser -eq $true) {
                        $claim = New-SPClaimsPrincipal -Identity $desiredMember.Username -IdentityType WindowsSamAccountName    
                    } else {
                        $claim = New-SPClaimsPrincipal -Identity $desiredMember.Username -IdentityType WindowsSecurityGroupName
                    }
                    Revoke-SPObjectSecurity -Identity $security -Principal $claim
                }
            }
        }
        
        # Commit all changes
        switch ($params.SecurityType) {
            "Administrators" { 
                $security = $serviceApp | Set-SPServiceApplicationSecurity -ObjectSecurity $security -Admin
             }
            "SharingPermissions" {
                $security = $serviceApp | Set-SPServiceApplicationSecurity -ObjectSecurity $security
            }
        }
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $ServiceAppName,
        [parameter(Mandatory = $true)]  [ValidateSet("Administrators","SharingPermissions")] [System.String] $SecurityType,
        [parameter(Mandatory = $false)] [Microsoft.Management.Infrastructure.CimInstance[]] $Members,
        [parameter(Mandatory = $false)] [Microsoft.Management.Infrastructure.CimInstance[]] $MembersToInclude,
        [parameter(Mandatory = $false)] [System.String[]] $MembersToExclude,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Testing service app security config"
    
    if ($Members -and (($MembersToInclude) -or ($MembersToExclude))) {
        Throw "Cannot use the Members parameter together with the MembersToInclude or MembersToExclude parameters"
    }

    if (!$Members -and !$MembersToInclude -and !$MembersToExclude) {
        throw "At least one of the following parameters must be specified: Members, MembersToInclude, MembersToExclude"
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ([System.String]::IsNullOrEmpty($CurrentValues.ServiceAppName) -eq $true) { return $false }
    
    if ($Members) {
        Write-Verbose "Processing Members parameter"
        $differences = Compare-Object -ReferenceObject $CurrentValues.Members.Username -DifferenceObject $Members.Username

        if ($null -eq $differences) {
            Write-Verbose "Security list matches - checking that permissions match on each object"
            foreach($currentMember in $CurrentValues.Members) {
                if ($currentMember.AccessLevel -ne ($Members | Where-Object { $_.Username -eq $currentMember.Username } | Select-Object -First 1).AccessLevel) {
                    Write-Verbose "$($currentMember.Username) has incorrect permission level. Test failed."
                    return $false
                }
            }
            return $true
        } else {
            Write-Verbose "Security list does not match"
            return $false
        }
    }

    $result = $true
    if ($MembersToInclude) {
        Write-Verbose "Processing MembersToInclude parameter"
        ForEach ($member in $MembersToInclude) {
            if (-not($CurrentValues.Members.Username -contains $member.Username)) {
                Write-Verbose "$($member.Username) does not have access. Set result to false"
                $result = $false
            } else {
                Write-Verbose "$($member.Username) already has access. Checking permission..."
                if ($member.AccessLevel -ne ($CurrentValues.Members | Where-Object { $_.Username -eq $member.Username } | Select-Object -First 1).AccessLevel) {
                    Write-Verbose "$($member.Username) has incorrect permission level. Test failed."
                    return $false
                }
            }
        }
    }

    if ($MembersToExclude) {
        Write-Verbose "Processing MembersToExclude parameter"
        ForEach ($member in $MembersToExclude) {
            if ($CurrentValues.Members.Username -contains $member.Username) {
                Write-Verbose "$member already has access. Set result to false"
                $result = $false
            } else {
                Write-Verbose "$member does not have access. Skipping"
            }
        }
    }

    return $result
}

Export-ModuleMember -Function *-TargetResource

