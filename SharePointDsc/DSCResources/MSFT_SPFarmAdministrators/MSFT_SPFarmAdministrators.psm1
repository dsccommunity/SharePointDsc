function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter()]
        [System.String[]]
        $Members,

        [Parameter()]
        [System.String[]]
        $MembersToInclude,

        [Parameter()]
        [System.String[]]
        $MembersToExclude,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting Farm Administrators configuration"

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

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $nullReturn = @{
            IsSingleInstance = "Yes"
            Members          = $null
            MembersToInclude = $null
            MembersToExclude = $null
        }

        $webApps = Get-SPWebApplication -IncludeCentralAdministration
        $caWebapp = $webApps | Where-Object -FilterScript {
            $_.IsAdministrationWebApplication
        }

        if ($null -eq $caWebapp)
        {
            Write-Verbose "Unable to locate central administration website"
            return $nullReturn
        }
        $caWeb = Get-SPWeb($caWebapp.Url)
        $farmAdminGroup = $caWeb.AssociatedOwnerGroup
        $farmAdministratorsGroup = $caWeb.SiteGroups.GetByName($farmAdminGroup)

        return @{
            IsSingleInstance = "Yes"
            Members          = $farmAdministratorsGroup.users.UserLogin
            MembersToInclude = $params.MembersToInclude
            MembersToExclude = $params.MembersToExclude
        }
    }
    return $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter()]
        [System.String[]]
        $Members,

        [Parameter()]
        [System.String[]]
        $MembersToInclude,

        [Parameter()]
        [System.String[]]
        $MembersToExclude,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting Farm Administrators configuration"

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

    $CurrentValues = Get-TargetResource @PSBoundParameters
    if ($null -eq $CurrentValues.Members)
    {
        $message = "Unable to locate central administration website"
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $changeUsers = @{ }
    $runChange = $false

    if ($Members)
    {
        Write-Verbose "Processing Members parameter"

        $differences = Compare-Object -ReferenceObject $CurrentValues.Members `
            -DifferenceObject $Members

        if ($null -eq $differences)
        {
            Write-Verbose "Farm Administrators group matches. No further processing required"
        }
        else
        {
            Write-Verbose "Farm Administrators group does not match. Perform corrective action"
            $addUsers = @()
            $removeUsers = @()
            foreach ($difference in $differences)
            {
                if ($difference.SideIndicator -eq "=>")
                {
                    # Add account
                    $user = $difference.InputObject
                    Write-Verbose "Add $user to Add list"
                    $addUsers += $user
                }
                elseif ($difference.SideIndicator -eq "<=")
                {
                    # Remove account
                    $user = $difference.InputObject
                    Write-Verbose "Add $user to Remove list"
                    $removeUsers += $user
                }
            }

            if ($addUsers.count -gt 0)
            {
                Write-Verbose "Adding $($addUsers.Count) users to the Farm Administrators group"
                $changeUsers.Add = $addUsers
                $runChange = $true
            }

            if ($removeUsers.count -gt 0)
            {
                Write-Verbose "Removing $($removeUsers.Count) users from the Farm Administrators group"
                $changeUsers.Remove = $removeUsers
                $runChange = $true
            }
        }
    }

    if ($MembersToInclude)
    {
        Write-Verbose "Processing MembersToInclude parameter"

        $addUsers = @()
        foreach ($member in $MembersToInclude)
        {
            if (-not($CurrentValues.Members -contains $member))
            {
                Write-Verbose "$member is not a Farm Administrator. Add user to Add list"
                $addUsers += $member
            }
            else
            {
                Write-Verbose "$member is already a Farm Administrator. Skipping"
            }
        }

        if ($addUsers.count -gt 0)
        {
            Write-Verbose "Adding $($addUsers.Count) users to the Farm Administrators group"
            $changeUsers.Add = $addUsers
            $runChange = $true
        }
    }

    if ($MembersToExclude)
    {
        Write-Verbose "Processing MembersToExclude parameter"

        $removeUsers = @()
        foreach ($member in $MembersToExclude)
        {
            if ($CurrentValues.Members -contains $member)
            {
                Write-Verbose "$member is a Farm Administrator. Add user to Remove list"
                $removeUsers += $member
            }
            else
            {
                Write-Verbose "$member is not a Farm Administrator. Skipping"
            }
        }

        if ($removeUsers.count -gt 0)
        {
            Write-Verbose "Removing $($removeUsers.Count) users from the Farm Administrators group"
            $changeUsers.Remove = $removeUsers
            $runChange = $true
        }
    }

    if ($runChange)
    {
        Write-Verbose "Apply changes"
        Merge-SPDscFarmAdminList $changeUsers
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter()]
        [System.String[]]
        $Members,

        [Parameter()]
        [System.String[]]
        $MembersToInclude,

        [Parameter()]
        [System.String[]]
        $MembersToExclude,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing Farm Administrators configuration"

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

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($null -eq $CurrentValues.Members)
    {
        $message = "There are no users configured as Farm Administrator"
        Write-Verbose -Message $message
        Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

        Write-Verbose -Message "Test-TargetResource returned false"
        return $false
    }

    if ($Members)
    {
        Write-Verbose "Processing Members parameter"
        $differences = Compare-Object -ReferenceObject $CurrentValues.Members `
            -DifferenceObject $Members

        if ($null -eq $differences)
        {
            Write-Verbose -Message "Farm Administrators group matches the specified Members"

            Write-Verbose -Message "Test-TargetResource returned true"
            return $true
        }
        else
        {
            $message = ("Farm Administrators group does not match the specified Members" + `
                    "Actual: $($CurrentValues.Members -join ", "). Desired: $($Members -join ", ")")
            Write-Verbose -Message $message
            Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

            Write-Verbose -Message "Test-TargetResource returned false"
            return $false
        }
    }

    $result = $true
    if ($MembersToInclude)
    {
        Write-Verbose "Processing MembersToInclude parameter"
        foreach ($member in $MembersToInclude)
        {
            if (-not($CurrentValues.Members -contains $member))
            {
                $message = ("$member is not a Farm Administrator, but is included in MembersToInclude: " + `
                        "$($MembersToInclude -join ", ")")
                Write-Verbose -Message $message
                Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

                $result = $false
            }
            else
            {
                Write-Verbose "$member is already a Farm Administrator. Skipping"
            }
        }
    }

    if ($MembersToExclude)
    {
        Write-Verbose "Processing MembersToExclude parameter"
        foreach ($member in $MembersToExclude)
        {
            if ($CurrentValues.Members -contains $member)
            {
                $message = ("$member is a Farm Administrator, but is included in MembersToExclude: " + `
                        "$($MembersToExclude -join ", ")")
                Write-Verbose -Message $message
                Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

                $result = $false
            }
            else
            {
                Write-Verbose "$member is not a Farm Administrator. Skipping"
            }
        }
    }

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Merge-SPDscFarmAdminList
{
    param (
        [Parameter()]
        [Hashtable]
        $changeUsers
    )

    $null = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($changeUsers, $MyInvocation.MyCommand.Source) `
        -ScriptBlock {
        $changeUsers = $args[0]
        $eventSource = $args[1]

        $webApps = Get-SPWebApplication -IncludeCentralAdministration
        $caWebapp = $webApps | Where-Object -FilterScript {
            $_.IsAdministrationWebApplication
        }
        if ($null -eq $caWebapp)
        {
            $message = "Unable to locate central administration website"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }
        $caWeb = Get-SPWeb($caWebapp.Url)
        $farmAdminGroup = $caWeb.AssociatedOwnerGroup

        if ($changeUsers.ContainsKey("Add"))
        {
            foreach ($loginName in $changeUsers.Add)
            {
                $caWeb.SiteGroups.GetByName($farmAdminGroup).AddUser($loginName, "", "", "")
            }
        }

        if ($changeUsers.ContainsKey("Remove"))
        {
            foreach ($loginName in $changeUsers.Remove)
            {
                $removeUser = get-spuser $loginName -web $caWebapp.Url
                $caWeb.SiteGroups.GetByName($farmAdminGroup).RemoveUser($removeUser)
            }
        }
    }
}

Export-ModuleMember -Function *-TargetResource
