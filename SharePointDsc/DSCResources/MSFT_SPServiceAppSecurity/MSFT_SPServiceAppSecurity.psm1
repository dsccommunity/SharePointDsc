function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServiceAppName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Administrators", "SharingPermissions")]
        [System.String]
        $SecurityType,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Members,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $MembersToInclude,

        [Parameter()]
        [System.String[]]
        $MembersToExclude,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting all security options for $SecurityType in $ServiceAppName"

    if ($Members -and (($MembersToInclude) -or ($MembersToExclude)))
    {
        $message = ("Cannot use the Members parameter together with the MembersToInclude or " + `
                "MembersToExclude parameters")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if ($null -eq $Members -and $null -eq $MembersToInclude -and $null -eq $MembersToExclude)
    {
        $message = ("At least one of the following parameters must be specified: Members, " + `
                "MembersToInclude, MembersToExclude")
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

        Write-Verbose -Message "Getting Service Application $($params.ServiceAppName)"
        $serviceApp = Get-SPServiceApplication -Name $params.ServiceAppName

        $nullReturn = @{
            ServiceAppName = ""
            SecurityType   = $params.SecurityType
        }

        if ($null -eq $serviceApp)
        {
            return $nullReturn
        }

        Write-Verbose -Message "Checking if valid AccessLevels are used"
        Write-Verbose -Message "Retrieving all available localized AccessLevels"
        $availablePerms = New-Object System.Collections.ArrayList
        $appSecurity = Get-SPServiceApplicationSecurity -Identity $serviceApp
        foreach ($right in $appSecurity.NamedAccessRights)
        {
            if (-not $availablePerms.Contains($right.Name))
            {
                $availablePerms.Add($right.Name) | Out-Null
            }
        }

        $appSecurity = Get-SPServiceApplicationSecurity -Identity $serviceApp -Admin
        foreach ($right in $appSecurity.NamedAccessRights)
        {
            if (-not $availablePerms.Contains($right.Name))
            {
                $availablePerms.Add($right.Name) | Out-Null
            }
        }

        if ($params.ContainsKey("Members") -eq $true)
        {
            Write-Verbose -Message "Checking AccessLevels in Members parameter"
            foreach ($member in $params.Members)
            {
                foreach ($accessLevel in $member.AccessLevels)
                {
                    if ($availablePerms -notcontains $accessLevel)
                    {
                        Write-Verbose -Message ("Unknown AccessLevel is used ($accessLevel). " + `
                                "Allowed values are '" + `
                            ($availablePerms -join "', '") + "'")
                        return $nullReturn
                    }
                }
            }
        }

        if ($params.ContainsKey("MembersToInclude") -eq $true)
        {
            Write-Verbose -Message "Checking AccessLevels in MembersToInclude parameter"
            foreach ($member in $params.MembersToInclude)
            {
                foreach ($accessLevel in $member.AccessLevels)
                {
                    if ($availablePerms -notcontains $accessLevel)
                    {
                        Write-Verbose -Message ("Unknown AccessLevel is used ($accessLevel). " + `
                                "Allowed values are '" + `
                            ($availablePerms -join "', '") + "'")
                        return $nullReturn
                    }
                }
            }
        }

        if ($params.ContainsKey("MembersToExclude") -eq $true)
        {
            Write-Verbose -Message "Checking AccessLevels in MembersToExclude parameter"
            foreach ($member in $params.MembersToExclude)
            {
                foreach ($accessLevel in $member.AccessLevels)
                {
                    if ($availablePerms -notcontains $accessLevel)
                    {
                        Write-Verbose -Message ("Unknown AccessLevel is used ($accessLevel). " + `
                                "Allowed values are '" + `
                            ($availablePerms -join "', '") + "'")
                        return $nullReturn
                    }
                }
            }
        }

        switch ($params.SecurityType)
        {
            "Administrators"
            {
                $security = $serviceApp | Get-SPServiceApplicationSecurity -Admin
            }
            "SharingPermissions"
            {
                $security = $serviceApp | Get-SPServiceApplicationSecurity
            }
        }

        $members = @()
        foreach ($securityEntry in $security.AccessRules)
        {
            $user = $securityEntry.Name
            if ($user -like "i:*|*" -or $user -like "c:*|*")
            {
                if ($user.Chars(3) -eq "%" -and $user -ilike "*$((Get-SPFarm).Id.ToString())")
                {
                    $user = "{LocalFarm}"
                }
                else
                {
                    $user = (New-SPClaimsPrincipal -Identity $user -IdentityType EncodedClaim).Value
                    if ($user -match "^s-1-[0-59]-\d+-\d+-\d+-\d+-\d+")
                    {
                        $user = Resolve-SPDscSecurityIdentifier -SID $user
                    }
                }
            }

            $accessLevels = @()

            foreach ($namedAccessRight in $security.NamedAccessRights)
            {
                if ($namedAccessRight.Rights.IsSubsetOf($securityEntry.AllowedObjectRights))
                {
                    $accessLevels += $namedAccessRight.Name
                }
            }

            $members += @{
                Username     = $user
                AccessLevels = $accessLevels
            }
        }

        return @{
            ServiceAppName   = $params.ServiceAppName
            SecurityType     = $params.SecurityType
            Members          = $members
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
        [System.String]
        $ServiceAppName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Administrators", "SharingPermissions")]
        [System.String]
        $SecurityType,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Members,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $MembersToInclude,

        [Parameter()]
        [System.String[]]
        $MembersToExclude,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting all security options for $SecurityType in $ServiceAppName"

    if ($Members -and (($MembersToInclude) -or ($MembersToExclude)))
    {
        $message = ("Cannot use the Members parameter together with the MembersToInclude or " + `
                "MembersToExclude parameters")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if ($null -eq $Members -and $null -eq $MembersToInclude -and $null -eq $MembersToExclude)
    {
        $message = ("At least one of the following parameters must be specified: Members, " + `
                "MembersToInclude, MembersToExclude")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source, $CurrentValues) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]
        $CurrentValues = $args[2]

        $serviceApp = Get-SPServiceApplication -Name $params.ServiceAppName
        if ($null -eq $serviceApp)
        {
            $message = "Unable to locate service application $($params.ServiceAppName)"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }

        Write-Verbose -Message "Checking if valid AccessLevels are used"
        Write-Verbose -Message "Retrieving all available localized AccessLevels"
        $availablePerms = New-Object System.Collections.ArrayList
        $appSecurity = Get-SPServiceApplicationSecurity -Identity $serviceApp
        foreach ($right in $appSecurity.NamedAccessRights)
        {
            if (-not $availablePerms.Contains($right.Name))
            {
                $availablePerms.Add($right.Name) | Out-Null
            }
        }

        $appSecurity = Get-SPServiceApplicationSecurity -Identity $serviceApp -Admin
        foreach ($right in $appSecurity.NamedAccessRights)
        {
            if (-not $availablePerms.Contains($right.Name))
            {
                $availablePerms.Add($right.Name) | Out-Null
            }
        }

        if ($params.ContainsKey("Members") -eq $true)
        {
            Write-Verbose -Message "Checking AccessLevels in Members parameter"
            foreach ($member in $params.Members)
            {
                foreach ($accessLevel in $member.AccessLevels)
                {
                    if ($availablePerms -notcontains $accessLevel)
                    {
                        $message = ("Unknown AccessLevel is used ($accessLevel). Allowed values are " + `
                                "'" + ($availablePerms -join "', '") + "'")
                        Add-SPDscEvent -Message $message `
                            -EntryType 'Error' `
                            -EventID 100 `
                            -Source $eventSource
                        throw $message
                    }
                }
            }
        }

        if ($params.ContainsKey("MembersToInclude") -eq $true)
        {
            Write-Verbose -Message "Checking AccessLevels in MembersToInclude parameter"
            foreach ($member in $params.MembersToInclude)
            {
                foreach ($accessLevel in $member.AccessLevels)
                {
                    if ($availablePerms -notcontains $accessLevel)
                    {
                        $message = ("Unknown AccessLevel is used ($accessLevel). Allowed values are " + `
                                "'" + ($availablePerms -join "', '") + "'")
                        Add-SPDscEvent -Message $message `
                            -EntryType 'Error' `
                            -EventID 100 `
                            -Source $eventSource
                        throw $message
                    }
                }
            }
        }

        switch ($params.SecurityType)
        {
            "Administrators"
            {
                $security = $serviceApp | Get-SPServiceApplicationSecurity -Admin
            }
            "SharingPermissions"
            {
                $security = $serviceApp | Get-SPServiceApplicationSecurity
            }
        }

        $localFarmEncodedClaim = "c:0%.c|system|$((Get-SPFarm).Id.ToString())"

        if ($params.ContainsKey("Members") -eq $true)
        {
            foreach ($desiredMember in $params.Members)
            {
                if ($desiredMember.Username -eq "{LocalFarm}")
                {
                    $claim = New-SPClaimsPrincipal -Identity $localFarmEncodedClaim `
                        -IdentityType EncodedClaim
                }
                else
                {
                    $isUser = Test-SPDscIsADUser -IdentityName $desiredMember.Username
                    if ($isUser -eq $true)
                    {
                        $claim = New-SPClaimsPrincipal -Identity $desiredMember.Username `
                            -IdentityType WindowsSamAccountName
                    }
                    else
                    {
                        $claim = New-SPClaimsPrincipal -Identity $desiredMember.Username `
                            -IdentityType WindowsSecurityGroupName
                    }
                }

                if ($CurrentValues.Members.Username -contains $desiredMember.Username)
                {
                    $compare = Compare-Object -ReferenceObject ($CurrentValues.Members | Where-Object -FilterScript {
                            $_.Username -eq $desiredMember.Username
                        } | Select-Object -First 1).AccessLevels -DifferenceObject $desiredMember.AccessLevels
                    if ($null -ne $compare)
                    {
                        Grant-SPObjectSecurity -Identity $security `
                            -Principal $claim `
                            -Rights $desiredMember.AccessLevels `
                            -Replace
                    }
                }
                else
                {
                    Grant-SPObjectSecurity -Identity $security -Principal $claim -Rights $desiredMember.AccessLevels
                }
            }

            foreach ($currentMember in $CurrentValues.Members)
            {
                if ($params.Members.Username -notcontains $currentMember.Username)
                {
                    if ($currentMember.UserName -eq "{LocalFarm}")
                    {
                        $claim = New-SPClaimsPrincipal -Identity $localFarmEncodedClaim `
                            -IdentityType EncodedClaim
                    }
                    else
                    {
                        $isUser = Test-SPDscIsADUser -IdentityName $currentMember.Username
                        if ($isUser -eq $true)
                        {
                            $claim = New-SPClaimsPrincipal -Identity $currentMember.Username `
                                -IdentityType WindowsSamAccountName
                        }
                        else
                        {
                            $claim = New-SPClaimsPrincipal -Identity $currentMember.Username `
                                -IdentityType WindowsSecurityGroupName
                        }
                    }
                    Revoke-SPObjectSecurity -Identity $security -Principal $claim
                }
            }
        }

        if ($params.ContainsKey("MembersToInclude") -eq $true)
        {
            foreach ($desiredMember in $params.MembersToInclude)
            {
                if ($desiredMember.Username -eq "{LocalFarm}")
                {
                    $claim = New-SPClaimsPrincipal -Identity $localFarmEncodedClaim `
                        -IdentityType EncodedClaim
                }
                else
                {
                    $isUser = Test-SPDscIsADUser -IdentityName $desiredMember.Username
                    if ($isUser -eq $true)
                    {
                        $claim = New-SPClaimsPrincipal -Identity $desiredMember.Username `
                            -IdentityType WindowsSamAccountName
                    }
                    else
                    {
                        $claim = New-SPClaimsPrincipal -Identity $desiredMember.Username `
                            -IdentityType WindowsSecurityGroupName
                    }
                }

                if ($CurrentValues.Members.Username -contains $desiredMember.Username)
                {
                    $compare = Compare-Object -ReferenceObject ($CurrentValues.Members | Where-Object -FilterScript {
                            $_.Username -eq $desiredMember.Username
                        } | Select-Object -First 1).AccessLevels -DifferenceObject $desiredMember.AccessLevels
                    if ($null -ne $compare)
                    {
                        Grant-SPObjectSecurity -Identity $security `
                            -Principal $claim `
                            -Rights $desiredMember.AccessLevels `
                            -Replace
                    }
                }
                else
                {
                    Grant-SPObjectSecurity -Identity $security `
                        -Principal $claim `
                        -Rights $desiredMember.AccessLevels
                }
            }
        }

        if ($params.ContainsKey("MembersToExclude") -eq $true)
        {
            foreach ($excludeMember in $params.MembersToExclude)
            {
                if ($CurrentValues.Members.Username -contains $excludeMember)
                {
                    if ($excludeMember -eq "{LocalFarm}")
                    {
                        $claim = New-SPClaimsPrincipal -Identity $localFarmEncodedClaim `
                            -IdentityType EncodedClaim
                    }
                    else
                    {
                        $isUser = Test-SPDscIsADUser -IdentityName $excludeMember
                        if ($isUser -eq $true)
                        {
                            $claim = New-SPClaimsPrincipal -Identity $excludeMember `
                                -IdentityType WindowsSamAccountName
                        }
                        else
                        {
                            $claim = New-SPClaimsPrincipal -Identity $excludeMember `
                                -IdentityType WindowsSecurityGroupName
                        }
                    }
                    Revoke-SPObjectSecurity -Identity $security -Principal $claim
                }
            }
        }

        switch ($params.SecurityType)
        {
            "Administrators"
            {
                $security = $serviceApp | Set-SPServiceApplicationSecurity -ObjectSecurity $security `
                    -Admin
            }
            "SharingPermissions"
            {
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
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServiceAppName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Administrators", "SharingPermissions")]
        [System.String]
        $SecurityType,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Members,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $MembersToInclude,

        [Parameter()]
        [System.String[]]
        $MembersToExclude,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing all security options for $SecurityType in $ServiceAppName"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ([System.String]::IsNullOrEmpty($CurrentValues.ServiceAppName) -eq $true)
    {
        $message = "ServiceAppName is currently not configured in the environment."
        Write-Verbose -Message $message
        Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

        Write-Verbose -Message "Test-TargetResource returned false"
        return $false
    }

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters, $CurrentValues, $PSScriptRoot, $MyInvocation.MyCommand.Source) `
        -ScriptBlock {
        $params = $args[0]
        $CurrentValues = $args[1]
        $ScriptRoot = $args[2]
        $Source = $args[3]

        $relPath = "..\..\Modules\SharePointDsc.ServiceAppSecurity\SPServiceAppSecurity.psm1"
        Import-Module (Join-Path -Path $ScriptRoot -ChildPath $relPath -Resolve)

        $serviceApp = Get-SPServiceApplication -Name $params.ServiceAppName
        switch ($params.SecurityType)
        {
            "Administrators"
            {
                $security = $serviceApp | Get-SPServiceApplicationSecurity -Admin
            }
            "SharingPermissions"
            {
                $security = $serviceApp | Get-SPServiceApplicationSecurity
            }
        }

        if ($null -ne $params.Members)
        {
            Write-Verbose -Message "Processing Members parameter"

            if ($CurrentValues.Members.Count -eq 0)
            {
                if ($params.Members.Count -gt 0)
                {
                    $message = ("Security list does not match. Actual: $($CurrentValues.Members.Username -join ", "). " + `
                            "Desired: $($params.Members.Username -join ", ")")
                    Write-Verbose -Message $message
                    Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $Source

                    return $false
                }
                else
                {
                    Write-Verbose -Message "Configured and specified security lists are both empty"
                    return $true
                }
            }
            elseif ($params.Members.Count -eq 0)
            {
                $message = ("Security list does not match. Actual: $($CurrentValues.Members.Username -join ", "). " + `
                        "Desired: $($params.Members.Username -join ", ")")
                Write-Verbose -Message $message
                Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $Source

                return $false
            }

            $differences = Compare-Object -ReferenceObject $CurrentValues.Members.Username `
                -DifferenceObject $params.Members.Username

            if ($null -eq $differences)
            {
                Write-Verbose -Message "Security list matches - checking that permissions match on each object"
                foreach ($currentMember in $CurrentValues.Members)
                {
                    $expandedAccessLevels = Expand-AccessLevel -Security $security -AccessLevels ($params.Members | Where-Object -FilterScript {
                            $_.Username -eq $currentMember.Username
                        } | Select-Object -First 1).AccessLevels
                    if ($null -ne (Compare-Object -DifferenceObject $currentMember.AccessLevels -ReferenceObject $expandedAccessLevels))
                    {
                        $message = "$($currentMember.Username) has incorrect permission level. Test failed."
                        Write-Verbose -Message $message
                        Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $Source

                        return $false
                    }
                }
                return $true
            }
            else
            {
                $message = ("Security list does not match. Actual: $($CurrentValues.Members.Username -join ", "). " + `
                        "Desired: $($params.Members.Username -join ", ")")
                Write-Verbose -Message $message
                Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $Source

                return $false
            }
        }

        $result = $true
        if ($params.MembersToInclude)
        {
            Write-Verbose -Message "Processing MembersToInclude parameter"
            foreach ($member in $params.MembersToInclude)
            {
                if (-not($CurrentValues.Members.Username -contains $member.Username))
                {
                    $message = "$($member.Username) does not have access. Test failed."
                    Write-Verbose -Message $message
                    Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $Source

                    $result = $false
                }
                else
                {
                    Write-Verbose -Message "$($member.Username) already has access. Checking permission..."
                    $expandedAccessLevels = Expand-AccessLevel -Security $security -AccessLevels $member.AccessLevels

                    $compare = Compare-Object -DifferenceObject $expandedAccessLevels -ReferenceObject ($CurrentValues.Members | Where-Object -FilterScript {
                            $_.Username -eq $member.Username
                        } | Select-Object -First 1).AccessLevels
                    if ($null -ne $compare)
                    {
                        $message = "$($member.Username) has incorrect permission level. Test failed."
                        Write-Verbose -Message $message
                        Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $Source

                        return $false
                    }
                }
            }
        }

        if ($params.MembersToExclude)
        {
            Write-Verbose -Message "Processing MembersToExclude parameter"
            foreach ($member in $params.MembersToExclude)
            {
                if ($CurrentValues.Members.Username -contains $member)
                {
                    $message = "$member already has access. Set result to false"
                    Write-Verbose -Message $message
                    Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $Source

                    $result = $false
                }
                else
                {
                    Write-Verbose -Message "$member does not have access. Skipping"
                }
            }
        }

        return $result
    }

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPServiceAppSecurity\MSFT_SPServiceAppSecurity.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module
    $serviceApplications = Get-SPServiceApplication | Where-Object { $_.GetType().Name -ne "SPUsageApplication" -and $_.GetType().Name -ne "StateServiceApplication" }

    foreach ($serviceApp in $serviceApplications)
    {
        try
        {
            $params.ServiceAppName = $serviceApp.Name
            $params.SecurityType = "SharingPermissions"

            $property = @{
                Handle = 0
            }

            $fake = New-CimInstance -ClassName Win32_Process -Property $property -Key Handle -ClientOnly
            $params.Members = $fake
            $params.Remove("MembersToInclude")
            $params.Remove("MembersToExclude")
            $results = Get-TargetResource @params

            $results = Repair-Credentials -results $results
            $results.Remove("MembersToInclude")
            $results.Remove("MembersToExclude")

            if ($results.Members.Count -gt 0)
            {
                $PartialContent = ''
                $stringMember = ""
                $foundOne = $false
                foreach ($member in $results.Members)
                {
                    $stringMember = Get-SPDscServiceAppSecurityMembers $member
                    if ($null -ne $stringMember)
                    {
                        if (!$foundOne)
                        {
                            $PartialContent += "        `$members = @();`r`n"
                            $foundOne = $true
                        }
                        $PartialContent += "        `$members += " + $stringMember + ";`r`n"
                    }
                }

                if ($foundOne)
                {
                    $PartialContent += "        SPServiceAppSecurity " + [System.Guid]::NewGuid().ToString() + "`r`n"
                    $PartialContent += "        {`r`n"
                    $results.Members = "`$members"
                    $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
                    $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
                    $PartialContent += $currentBlock
                    $PartialContent += "        }`r`n"
                    $Content += $PartialContent
                }
            }

            $params.SecurityType = "Administrators"

            $results = Get-TargetResource @params

            $results = Repair-Credentials -results $results
            $results.Remove("MembersToInclude")
            $results.Remove("MembersToExclude")
            $stringMember = ""

            if ($results.Members.Count -gt 0)
            {
                $PartialContent = ''
                $foundOne = $false
                foreach ($member in $results.Members)
                {
                    $stringMember = Get-SPDscServiceAppSecurityMembers $member
                    if ($null -ne $stringMember)
                    {
                        if (!$foundOne)
                        {
                            $PartialContent += "        `$members = @();`r`n"
                            $foundOne = $true
                        }
                        $PartialContent += "        `$members += " + $stringMember + ";`r`n"
                    }
                }

                if ($foundOne)
                {
                    $PartialContent += "        SPServiceAppSecurity " + [System.Guid]::NewGuid().ToString() + "`r`n"
                    $PartialContent += "        {`r`n"
                    $results.Members = "`$members"
                    $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
                    $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
                    $PartialContent += $currentBlock
                    $PartialContent += "        }`r`n"
                    $Content += $PartialContent
                }
            }
        }
        catch
        {
            $_
            $Global:ErrorLog += "[Service Application Permissions]" + $serviceApp.Name + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
    }
    return $Content.ToString()
}

Export-ModuleMember -Function *-TargetResource
