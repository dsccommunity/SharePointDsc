function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Members,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $MembersToInclude,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $MembersToExclude,

        [Parameter()]
        [System.Boolean]
        $SetCacheAccountsPolicy,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting web app policy for $WebAppUrl"

    $nullReturn = @{
        WebAppUrl              = $null
        Members                = $null
        MembersToInclude       = $null
        MembersToExclude       = $null
        SetCacheAccountsPolicy = $null
    }

    if ($Members -and (($MembersToInclude) -or ($MembersToExclude)))
    {
        Write-Verbose -Message ("Cannot use the Members parameter together with " + `
                "the MembersToInclude or MembersToExclude parameters")
        return $nullReturn
    }

    if (!$Members -and !$MembersToInclude -and !$MembersToExclude)
    {
        Write-Verbose -Message ("At least one of the following parameters must be specified: " + `
                "Members, MembersToInclude, MembersToExclude")
        return $nullReturn
    }

    foreach ($member in $Members)
    {
        if (($member.ActAsSystemAccount -eq $true) `
                -and ($member.PermissionLevel -ne "Full Control"))
        {
            Write-Verbose -Message ("Members Parameter: You cannot specify ActAsSystemAccount " + `
                    "with any other permission than Full Control")
            return $nullReturn
        }
    }

    foreach ($member in $MembersToInclude)
    {
        if (($member.ActAsSystemAccount -eq $true) `
                -and ($member.PermissionLevel -ne "Full Control"))
        {
            Write-Verbose -Message ("MembersToInclude Parameter: You cannot specify " + `
                    "ActAsSystemAccount with any other permission than Full " + `
                    "Control")
            return $nullReturn
        }
    }

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $nullReturn = @{
            WebAppUrl              = $null
            Members                = $null
            MembersToInclude       = $null
            MembersToExclude       = $null
            SetCacheAccountsPolicy = $null
        }

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl `
            -ErrorAction SilentlyContinue

        if ($null -eq $wa)
        {
            return $nullReturn
        }

        $SetCacheAccountsPolicy = $false
        if ($params.SetCacheAccountsPolicy)
        {
            if (($wa.Properties.ContainsKey("portalsuperuseraccount") -eq $true) -and `
                ($wa.Properties.ContainsKey("portalsuperreaderaccount") -eq $true))
            {
                $correctPSU = $false
                $correctPSR = $false

                $psu = $wa.Policies[$wa.Properties["portalsuperuseraccount"]]
                if ($null -ne $psu)
                {
                    if ($psu.PolicyRoleBindings.Type -eq 'FullControl')
                    {
                        $correctPSU = $true
                    }
                }

                $psr = $wa.Policies[$wa.Properties["portalsuperreaderaccount"]]
                if ($null -ne $psr)
                {
                    if ($psr.PolicyRoleBindings.Type -eq 'FullRead')
                    {
                        $correctPSR = $true
                    }
                }

                if ($correctPSU -eq $true -and $correctPSR -eq $true)
                {
                    $SetCacheAccountsPolicy = $true
                }
            }
        }

        $members = @()
        foreach ($policy in $wa.Policies)
        {
            $member = @{ }
            $memberName = $policy.UserName
            $identityType = "Native"
            if ($memberName -like "i:*|*" -or $memberName -like "c:*|*")
            {
                $identityType = "Claims"
                $convertedClaim = New-SPClaimsPrincipal -Identity $memberName `
                    -IdentityType EncodedClaim `
                    -ErrorAction SilentlyContinue
                if ($null -ne $convertedClaim)
                {
                    $memberName = $convertedClaim.Value
                }
            }

            if ($memberName -match "^s-1-[0-59]-\d+-\d+-\d+-\d+-\d+")
            {
                $memberName = Resolve-SPDscSecurityIdentifier -SID $memberName
            }

            switch ($policy.PolicyRoleBindings.Type)
            {
                'DenyAll'
                {
                    $memberPermissionlevel = 'Deny All'
                }
                'DenyWrite'
                {
                    $memberPermissionlevel = 'Deny Write'
                }
                'FullControl'
                {
                    $memberPermissionlevel = 'Full Control'
                }
                'FullRead'
                {
                    $memberPermissionlevel = 'Full Read'
                }
            }

            $member.Username = $memberName
            $member.PermissionLevel = $memberPermissionlevel
            $member.ActAsSystemAccount = $policy.IsSystemUser
            $member.IdentityType = $identityType
            $members += $member
        }

        $returnval = @{
            WebAppUrl              = $params.WebAppUrl
            Members                = $members
            MembersToInclude       = $params.MembersToInclude
            MembersToExclude       = $params.MembersToExclude
            SetCacheAccountsPolicy = $SetCacheAccountsPolicy
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
        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Members,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $MembersToInclude,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $MembersToExclude,

        [Parameter()]
        [System.Boolean]
        $SetCacheAccountsPolicy,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting web app policy for $WebAppUrl"

    if ($Members -and (($MembersToInclude) -or ($MembersToExclude)))
    {
        $message = ("Cannot use the Members parameter together with the " + `
                "MembersToInclude or MembersToExclude parameters")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if (!$Members -and !$MembersToInclude -and !$MembersToExclude)
    {
        $message = ("At least one of the following parameters must be specified: " + `
                "Members, MembersToInclude, MembersToExclude")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    foreach ($member in $Members)
    {
        if (($member.ActAsSystemAccount -eq $true) -and `
            ($member.PermissionLevel -ne "Full Control"))
        {
            $message = ("Members Parameter: You cannot specify ActAsSystemAccount " + `
                    "with any other permission than Full Control")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }
    }

    foreach ($member in $MembersToInclude)
    {
        if (($member.ActAsSystemAccount -eq $true) -and `
            ($member.PermissionLevel -ne "Full Control"))
        {
            $message = ("MembersToInclude Parameter: You cannot specify ActAsSystemAccount " + `
                    "with any other permission than Full Control")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters


    $modulePath = "..\..\Modules\SharePointDsc.WebAppPolicy\SPWebAppPolicy.psm1"
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath $modulePath -Resolve)

    if ($null -eq $CurrentValues.WebAppUrl)
    {
        $message = "Web application does not exist"
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $cacheAccounts = Get-SPDscCacheAccountConfiguration -WebApplicationUrl $WebAppUrl

    if ($SetCacheAccountsPolicy)
    {
        if ($cacheAccounts.SuperUserAccount -eq "" -or $cacheAccounts.SuperReaderAccount -eq "")
        {
            $message = ("Cache accounts not configured properly. PortalSuperUserAccount or " + `
                    "PortalSuperReaderAccount property is not configured.")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }
    }

    # Determine the default identity type to use for entries that do not have it specified
    $defaultIdentityType = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl
        if ($wa.UseClaimsAuthentication -eq $true)
        {
            return "Claims"
        }
        else
        {
            return "Native"
        }
    }

    $changeUsers = @()

    if ($Members -or $MembersToInclude)
    {
        $allMembers = @()
        if ($Members)
        {
            Write-Verbose -Message "Members property is set - setting full membership list"
            $membersToCheck = $Members
        }
        if ($MembersToInclude)
        {
            Write-Verbose -Message ("MembersToInclude property is set - setting membership " + `
                    "list to ensure specified members are included")
            $membersToCheck = $MembersToInclude
        }
        foreach ($member in $membersToCheck)
        {
            $allMembers += $member
        }

        # Determine if cache accounts are to be included users
        if ($SetCacheAccountsPolicy)
        {
            Write-Verbose -Message "SetCacheAccountsPolicy is True - Adding Cache Accounts to list"
            $psuAccount = @{
                UserName        = $cacheAccounts.SuperUserAccount
                PermissionLevel = "Full Control"
                IdentityMode    = $cacheAccounts.IdentityMode
            }
            $allMembers += $psuAccount

            $psrAccount = @{
                UserName        = $cacheAccounts.SuperReaderAccount
                PermissionLevel = "Full Read"
                IdentityMode    = $cacheAccounts.IdentityMode
            }
            $allMembers += $psrAccount
        }

        # Get the list of differences from the current configuration
        $differences = Compare-SPDscWebAppPolicy -WAPolicies $CurrentValues.Members `
            -DSCSettings $allMembers `
            -DefaultIdentityType $defaultIdentityType

        foreach ($difference in $differences)
        {
            switch ($difference.Status)
            {
                Additional
                {
                    # Only remove users if the "Members" property was set
                    # instead of "MembersToInclude"
                    if ($Members)
                    {
                        $user = @{
                            Type         = "Delete"
                            Username     = $difference.Username
                            IdentityMode = $difference.IdentityType
                        }
                    }
                }
                Different
                {
                    $user = @{
                        Type               = "Change"
                        Username           = $difference.Username
                        PermissionLevel    = $difference.DesiredPermissionLevel
                        ActAsSystemAccount = $difference.DesiredActAsSystemSetting
                        IdentityMode       = $difference.IdentityType
                    }
                }
                Missing
                {
                    $user = @{
                        Type               = "Add"
                        Username           = $difference.Username
                        PermissionLevel    = $difference.DesiredPermissionLevel
                        ActAsSystemAccount = $difference.DesiredActAsSystemSetting
                        IdentityMode       = $difference.IdentityType
                    }
                }
            }
            $changeUsers += $user
        }
    }

    if ($MembersToExclude)
    {
        Write-Verbose -Message ("MembersToExclude property is set - setting membership list " + `
                "to ensure specified members are not included")

        foreach ($member in $MembersToExclude)
        {
            $policy = $CurrentValues.Members | Where-Object -FilterScript {
                $_.UserName -eq $member.UserName -and $_.IdentityType -eq $member.IdentityType
            }

            if (($cacheAccounts.SuperUserAccount -eq $member.Username) -or `
                ($cacheAccounts.SuperReaderAccount -eq $member.Username))
            {
                $message = "You cannot exclude the Cache accounts from the Web Application Policy"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }

            if ($null -ne $policy)
            {
                $user = @{
                    Type     = "Delete"
                    Username = $member.UserName
                }
                $changeUsers += $user
            }
        }
    }

    ## Perform changes
    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source, $PSScriptRoot, $changeUsers) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]
        $scriptRoot = $args[2]
        $changeUsers = $args[3]

        $modulePath = "..\..\Modules\SharePointDsc.WebAppPolicy\SPWebAppPolicy.psm1"
        Import-Module -Name (Join-Path -Path $scriptRoot -ChildPath $modulePath -Resolve)

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue

        if ($null -eq $wa)
        {
            $message = "Specified web application could not be found."
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }

        $denyAll = $wa.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::DenyAll)
        $denyWrite = $wa.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::DenyWrite)
        $fullControl = $wa.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl)
        $fullRead = $wa.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullRead)

        Write-Verbose -Message "Processing changes"

        foreach ($user in $changeUsers)
        {
            switch ($user.Type)
            {
                "Add"
                {
                    # User does not exist. Add user
                    Write-Verbose -Message "Adding $($user.Username)"

                    $userToAdd = $user.Username
                    if ($user.IdentityMode -eq "Claims")
                    {
                        $isUser = Test-SPDscIsADUser -IdentityName $user.Username
                        if ($isUser -eq $true)
                        {
                            $principal = New-SPClaimsPrincipal -Identity $user.Username `
                                -IdentityType WindowsSamAccountName
                            $userToAdd = $principal.ToEncodedString()
                        }
                        else
                        {
                            $principal = New-SPClaimsPrincipal -Identity $user.Username `
                                -IdentityType WindowsSecurityGroupName
                            $userToAdd = $principal.ToEncodedString()
                        }
                    }
                    $newPolicy = $wa.Policies.Add($userToAdd, $user.UserName)
                    foreach ($permissionLevel in $user.PermissionLevel)
                    {
                        switch ($permissionLevel)
                        {
                            "Deny All"
                            {
                                $newPolicy.PolicyRoleBindings.Add($denyAll)
                            }
                            "Deny Write"
                            {
                                $newPolicy.PolicyRoleBindings.Add($denyWrite)
                            }
                            "Full Control"
                            {
                                $newPolicy.PolicyRoleBindings.Add($fullControl)
                            }
                            "Full Read"
                            {
                                $newPolicy.PolicyRoleBindings.Add($fullRead)
                            }
                        }
                    }
                    if ($user.ActAsSystemAccount)
                    {
                        $newPolicy.IsSystemUser = $user.ActAsSystemAccount
                    }
                }
                "Change"
                {
                    # User exists. Check permissions
                    $userToChange = $user.Username
                    if ($user.IdentityMode -eq "Claims")
                    {
                        $isUser = Test-SPDscIsADUser -IdentityName $user.Username
                        if ($isUser -eq $true)
                        {
                            $principal = New-SPClaimsPrincipal -Identity $user.Username `
                                -IdentityType WindowsSamAccountName
                            $userToChange = $principal.ToEncodedString()
                        }
                        else
                        {
                            $principal = New-SPClaimsPrincipal -Identity $user.Username `
                                -IdentityType WindowsSecurityGroupName
                            $userToChange = $principal.ToEncodedString()
                        }
                    }
                    $policy = $wa.Policies | Where-Object -FilterScript {
                        $_.UserName -eq $userToChange
                    }

                    Write-Verbose -Message "User $($user.Username) exists, checking permissions"
                    if ($user.ActAsSystemAccount -ne $policy.IsSystemUser)
                    {
                        $policy.IsSystemUser = $user.ActAsSystemAccount
                    }

                    switch ($policy.PolicyRoleBindings.Type)
                    {
                        'DenyAll'
                        {
                            $userPermissionlevel = 'Deny All'
                        }
                        'DenyWrite'
                        {
                            $userPermissionlevel = 'Deny Write'
                        }
                        'FullControl'
                        {
                            $userPermissionlevel = 'Full Control'
                        }
                        'FullRead'
                        {
                            $userPermissionlevel = 'Full Read'
                        }
                    }

                    $polbinddiff = Compare-Object -ReferenceObject $userPermissionlevel `
                        -DifferenceObject $user.PermissionLevel
                    if ($null -ne $polbinddiff)
                    {
                        $policy.PolicyRoleBindings.RemoveAll()
                        foreach ($permissionLevel in $user.PermissionLevel)
                        {
                            switch ($permissionLevel)
                            {
                                "Deny All"
                                {
                                    $policy.PolicyRoleBindings.Add($denyAll)
                                }
                                "Deny Write"
                                {
                                    $policy.PolicyRoleBindings.Add($denyWrite)
                                }
                                "Full Control"
                                {
                                    $policy.PolicyRoleBindings.Add($fullControl)
                                }
                                "Full Read"
                                {
                                    $policy.PolicyRoleBindings.Add($fullRead)
                                }
                            }
                        }
                    }
                }
                "Delete"
                {
                    Write-Verbose -Message "Removing $($user.Username)"
                    $userToDrop = $user.Username
                    if ($user.IdentityMode -eq "Claims")
                    {
                        $isUser = Test-SPDscIsADUser -IdentityName $user.Username
                        if ($isUser -eq $true)
                        {
                            $principal = New-SPClaimsPrincipal -Identity $user.Username `
                                -IdentityType WindowsSamAccountName
                            $userToDrop = $principal.ToEncodedString()
                        }
                        else
                        {
                            $principal = New-SPClaimsPrincipal -Identity $user.Username `
                                -IdentityType WindowsSecurityGroupName
                            $userToDrop = $principal.ToEncodedString()
                        }
                    }
                    Remove-SPDscGenericObject -SourceCollection $wa.Policies `
                        -Target $userToDrop `
                        -ErrorAction SilentlyContinue
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
        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Members,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $MembersToInclude,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $MembersToExclude,

        [Parameter()]
        [System.Boolean]
        $SetCacheAccountsPolicy,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing web app policy for $WebAppUrl"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $modulePath = "..\..\Modules\SharePointDsc.WebAppPolicy\SPWebAppPolicy.psm1"
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath $modulePath -Resolve)

    if ($null -eq $CurrentValues.WebAppUrl)
    {
        $message = "One of the specified parameters is incorrect. Please check if these are correct."
        Write-Verbose -Message $message
        Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

        Write-Verbose -Message "Test-TargetResource returned false"
        return $false
    }

    $cacheAccounts = Get-SPDscCacheAccountConfiguration -WebApplicationUrl $WebAppUrl
    if ($SetCacheAccountsPolicy)
    {
        if (($cacheAccounts.SuperUserAccount -eq "") -or `
            ($cacheAccounts.SuperReaderAccount -eq ""))
        {
            $message = "Cache accounts not configured properly. PortalSuperUserAccount or " + `
                "PortalSuperReaderAccount property is not configured."
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }
    }

    # Determine the default identity type to use for entries that do not have it specified
    $defaultIdentityType = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl
        if ($wa.UseClaimsAuthentication -eq $true)
        {
            return "Claims"
        }
        else
        {
            return "Native"
        }
    }

    # If checking the full members list, or the list of members to include then build the
    # appropriate members list and check for the output of Compare-SPDscWebAppPolicy
    if ($Members -or $MembersToInclude)
    {
        $allMembers = @()
        if ($Members)
        {
            Write-Verbose -Message "Members property is set - testing full membership list"
            $membersToCheck = $Members
        }
        if ($MembersToInclude)
        {
            Write-Verbose -Message ("MembersToInclude property is set - testing membership " + `
                    "list to ensure specified members are included")
            $membersToCheck = $MembersToInclude
        }
        foreach ($member in $membersToCheck)
        {
            $allMembers += $member
        }

        # Determine if cache accounts are to be included users
        if ($SetCacheAccountsPolicy)
        {
            Write-Verbose -Message "SetCacheAccountsPolicy is True - Adding Cache Accounts to list"
            $psuAccount = @{
                UserName        = $cacheAccounts.SuperUserAccount
                PermissionLevel = "Full Control"
                IdentityMode    = $cacheAccounts.IdentityMode
            }
            $allMembers += $psuAccount

            $psrAccount = @{
                UserName        = $cacheAccounts.SuperReaderAccount
                PermissionLevel = "Full Read"
                IdentityMode    = $cacheAccounts.IdentityMode
            }
            $allMembers += $psrAccount
        }

        # Get the list of differences from the current configuration
        [Array]$differences = Compare-SPDscWebAppPolicy -WAPolicies $CurrentValues.Members `
            -DSCSettings $allMembers `
            -DefaultIdentityType $defaultIdentityType

        # If checking members, any difference counts as a fail
        if ($Members)
        {
            if ($differences.Count -eq 0)
            {
                $result = $true
            }
            else
            {
                $source = $MyInvocation.MyCommand.Source

                $EventMessage = "<SPDscEvent>`r`n"
                $EventMessage += "    <ConfigurationDrift Source=`"$source`">`r`n"

                $EventMessage += "        <ParametersNotInDesiredState>`r`n"
                $driftedValue = ''
                foreach ($item in $differences)
                {
                    $EventMessage += "            <Param Name=`"Members`">" + $item.Username + " is " + $item.Status + "</Param>`r`n"
                }
                $EventMessage += "        </ParametersNotInDesiredState>`r`n"
                $EventMessage += "        <DesiredState>`r`n"
                $EventMessage += "            <WebAppUrl>$WebAppUrl</WebAppUrl>`r`n"
                $EventMessage += "            <Members>`r`n"
                foreach ($member in $Members)
                {
                    $EventMessage += "                <Member>`r`n"
                    $EventMessage += "                    <UserName>$($member.UserName)</UserName>`r`n"
                    $EventMessage += "                    <PermissionLevel>$($member.PermissionLevel)</PermissionLevel>`r`n"
                    $EventMessage += "                    <IdentityType>$($member.IdentityType)</IdentityType>`r`n"
                    $EventMessage += "                    <ActAsSystemAccount>$($member.ActAsSystemAccount)</ActAsSystemAccount>`r`n"
                    $EventMessage += "                </Member>`r`n"
                }
                $EventMessage += "            </Members>`r`n"
                $EventMessage += "        </DesiredState>`r`n"
                $EventMessage += "    </ConfigurationDrift>`r`n"
                $EventMessage += "</SPDscEvent>"

                Add-SPDscEvent -Message $EventMessage -EntryType 'Error' -EventID 1 -Source $source

                Write-Verbose -Message "Differences in the policy were found, returning false"
                $result = $false
            }

            Write-Verbose -Message "Test-TargetResource returned $result"
            return $result
        }

        # If only checking members to include only differences or missing records count as a fail
        if ($MembersToInclude)
        {
            $diffs = $differences | Where-Object -FilterScript {
                $_.Status -eq "Different" -or $_.Status -eq "Missing"
            }
            $diffcount = $diffs.Count
            if ($diffcount -eq 0)
            {
                $result = $true
            }
            else
            {
                $source = $MyInvocation.MyCommand.Source

                $EventMessage = "<SPDscEvent>`r`n"
                $EventMessage += "    <ConfigurationDrift Source=`"$source`">`r`n"

                $EventMessage += "        <ParametersNotInDesiredState>`r`n"
                $driftedValue = ''
                foreach ($item in $diffs)
                {
                    $EventMessage += "            <Param Name=`"MembersToInclude`">" + $item.Username + " is " + $item.Status + "</Param>`r`n"
                }
                $EventMessage += "        </ParametersNotInDesiredState>`r`n"
                $EventMessage += "        <DesiredState>`r`n"
                $EventMessage += "            <WebAppUrl>$WebAppUrl</WebAppUrl>`r`n"
                $EventMessage += "            <MembersToInclude>`r`n"
                foreach ($member in $MembersToInclude)
                {
                    $EventMessage += "                <Member>`r`n"
                    $EventMessage += "                    <UserName>$($member.UserName)</UserName>`r`n"
                    $EventMessage += "                    <PermissionLevel>$($member.PermissionLevel)</PermissionLevel>`r`n"
                    $EventMessage += "                    <IdentityType>$($member.IdentityType)</IdentityType>`r`n"
                    $EventMessage += "                    <ActAsSystemAccount>$($member.ActAsSystemAccount)</ActAsSystemAccount>`r`n"
                    $EventMessage += "                </Member>`r`n"
                }
                $EventMessage += "            </MembersToInclude>`r`n"
                $EventMessage += "        </DesiredState>`r`n"
                $EventMessage += "    </ConfigurationDrift>`r`n"
                $EventMessage += "</SPDscEvent>"

                Add-SPDscEvent -Message $EventMessage -EntryType 'Error' -EventID 1 -Source $source

                Write-Verbose -Message "Different or Missing policy was found, returning false"
                $result = $false
            }

            Write-Verbose -Message "Test-TargetResource returned $result"
            return $result
        }
    }

    # If checking members to exclude, simply compare the list of user names to the current
    # membership list
    if ($MembersToExclude)
    {
        Write-Verbose -Message ("MembersToExclude property is set - checking for permissions " + `
                "that need to be removed")

        $result = $true
        $presentAccounts = @()
        foreach ($member in $MembersToExclude)
        {
            if (($cacheAccounts.SuperUserAccount -eq $member.Username) -or `
                ($cacheAccounts.SuperReaderAccount -eq $member.Username))
            {
                $message = "You cannot exclude the Cache accounts from the Web Application Policy"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }

            foreach ($policy in $CurrentValues.Members)
            {
                if ($policy.Username -eq $member.Username)
                {
                    $presentAccounts += $member.Username
                    $result = $false
                }
            }
        }

        if ($result -eq $false)
        {
            $source = $MyInvocation.MyCommand.Source

            $EventMessage = "<SPDscEvent>`r`n"
            $EventMessage += "    <ConfigurationDrift Source=`"$source`">`r`n"
            $EventMessage += "        <ParametersNotInDesiredState>`r`n"
            $EventMessage += "            <Param Name=`"MembersToExclude`">" + ($presentAccounts -join ", ") + " is/are added to the policy</Param>`r`n"
            $EventMessage += "        </ParametersNotInDesiredState>`r`n"
            $EventMessage += "        <DesiredState>`r`n"
            $EventMessage += "            <WebAppUrl>$WebAppUrl</WebAppUrl>`r`n"
            $EventMessage += "            <MembersToExclude>`r`n"
            foreach ($member in $MembersToExclude)
            {
                $EventMessage += "                <Member>`r`n"
                $EventMessage += "                    <UserName>$($member.UserName)</UserName>`r`n"
                $EventMessage += "                    <PermissionLevel>$($member.PermissionLevel)</PermissionLevel>`r`n"
                $EventMessage += "                    <IdentityType>$($member.IdentityType)</IdentityType>`r`n"
                $EventMessage += "                    <ActAsSystemAccount>$($member.ActAsSystemAccount)</ActAsSystemAccount>`r`n"
                $EventMessage += "                </Member>`r`n"
            }
            $EventMessage += "            </MembersToExclude>`r`n"
            $EventMessage += "        </DesiredState>`r`n"
            $EventMessage += "    </ConfigurationDrift>`r`n"
            $EventMessage += "</SPDscEvent>"

            Add-SPDscEvent -Message $EventMessage -EntryType 'Error' -EventID 1 -Source $source
        }

        Write-Verbose -Message "Test-TargetResource returned $result"

        return $result
    }
}

function Get-SPDscCacheAccountConfiguration()
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter()]
        [string]
        $WebApplicationUrl
    )

    $cacheAccounts = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($WebApplicationUrl, $MyInvocation.MyCommand.Source) `
        -ScriptBlock {
        Write-Verbose -Message "Retrieving CacheAccounts"
        $webApplicationUrl = $args[0]
        $eventSource = $args[1]

        $wa = Get-SPWebApplication -Identity $webApplicationUrl -ErrorAction SilentlyContinue

        if ($null -eq $wa)
        {
            $message = "Specified web application could not be found."
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }

        $returnval = @{
            SuperUserAccount   = ""
            SuperReaderAccount = ""
        }

        if ($wa.Properties.ContainsKey("portalsuperuseraccount"))
        {
            $memberName = $wa.Properties["portalsuperuseraccount"]
            if ($wa.UseClaimsAuthentication -eq $true)
            {
                $convertedClaim = New-SPClaimsPrincipal -Identity $memberName `
                    -IdentityType EncodedClaim `
                    -ErrorAction SilentlyContinue
                if ($null -ne $convertedClaim)
                {
                    $memberName = $convertedClaim.Value
                }
            }
            $returnval.SuperUserAccount = $memberName
        }
        if ($wa.Properties.ContainsKey("portalsuperreaderaccount"))
        {
            $memberName = $wa.Properties["portalsuperreaderaccount"]
            if ($wa.UseClaimsAuthentication -eq $true)
            {
                $convertedClaim = New-SPClaimsPrincipal -Identity $memberName `
                    -IdentityType EncodedClaim `
                    -ErrorAction SilentlyContinue
                if ($null -ne $convertedClaim)
                {
                    $memberName = $convertedClaim.Value
                }
            }
            $returnval.SuperReaderAccount = $memberName
        }

        if ($wa.UseClaimsAuthentication -eq $true)
        {
            $returnval.IdentityMode = "Claims"
        }
        else
        {
            $returnval.IdentityMode = "Native"
        }

        return $returnval
    }

    return $cacheAccounts
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDSC" | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPWebAppPolicy\MSFT_SPWebAppPolicy.psm1" -Resolve
    $Content = ''

    $webApps = Get-SPWebApplication

    $i = 1
    $total = $webApps.Length
    foreach ($webApp in $webApps)
    {
        $params = Get-DSCFakeParameters -ModulePath $module
        $webAppUrl = $webApp.Url
        Write-Host "Scanning Web App Policies [$i/$total] {$webAppUrl}"

        $params.WebAppUrl = $webAppUrl
        $PartialContent = "        SPWebAppPolicy " + [System.Guid]::NewGuid().toString() + "`r`n"
        $PartialContent += "        {`r`n"

        $property = @{
            Handle = 0
        }
        $fake = New-CimInstance -ClassName Win32_Process -Property $property -Key Handle -ClientOnly

        if (!$params.Contains("Members"))
        {
            $params.Add("Members", $fake);
        }
        $results = Get-TargetResource @params

        if ($null -ne $results.Members)
        {
            $newMembers = @()
            foreach ($member in $results.Members)
            {
                if ($member.UserName.Contains("\"))
                {
                    $resultPermission = Get-SPWebPolicyPermissions -params $member
                    $newMembers += $resultPermission
                }
            }
            $results.Members = $newMembers
        }

        if ($null -eq $results.MembersToExclude)
        {
            $results.Remove("MembersToExclude")
        }

        if ($null -eq $results.MembersToInclude)
        {
            $results.Remove("MembersToInclude")
        }

        $results = Repair-Credentials -results $results
        $DSCBlock = Get-DSCBlock -Params $results -ModulePath $module
        $DSCBlock = Convert-DSCStringParamToVariable -DSCBlock $DSCBlock -ParameterName "Members" -IsCIMArray $true
        $DSCBlock = Convert-DSCStringParamToVariable -DSCBlock $DSCBlock -ParameterName "PsDscRunAsCredential"
        $PartialContent += $DSCBlock
        $PartialContent += "        }`r`n"
        $Content += $PartialContent
        $i++
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
