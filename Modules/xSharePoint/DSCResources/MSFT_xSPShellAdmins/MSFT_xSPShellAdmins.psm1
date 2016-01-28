function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)] [System.String]    $Name,
        [parameter(Mandatory = $false)] [System.String[]] $Members,
        [parameter(Mandatory = $false)] [System.String[]] $MembersToInclude,
        [parameter(Mandatory = $false)] [System.String[]] $MembersToExclude,
        [parameter(Mandatory = $false)] [Microsoft.Management.Infrastructure.CimInstance[]] $ContentDatabases,
        [parameter(Mandatory = $false)] [System.Boolean]  $AllContentDatabases,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    if ($Members -and (($MembersToInclude) -or ($MembersToExclude))) {
        Write-Verbose -Verbose "Cannot use the Members parameter together with the MembersToInclude or MembersToExclude parameters"
        return $null
    }

    if ($ContentDatabases) {
        foreach ($contentDatabase in $ContentDatabases) {
            if ($contentDatabase.Members -and (($contentDatabase.MembersToInclude) -or ($contentDatabase.MembersToExclude))) {
                Write-Verbose -Verbose "ContentDatabases: Cannot use the Members parameter together with the MembersToInclude or MembersToExclude parameters"
                return $null
            }

            if (!$contentDatabase.Members -and !$contentDatabase.MembersToInclude -and !$contentDatabase.MembersToExclude) {
                Write-Verbose -Verbose "ContentDatabases: At least one of the following parameters must be specified: Members, MembersToInclude, MembersToExclude"
                return $null
            }
        }
    } else {
        if (!$Members -and !$MembersToInclude -and !$MembersToExclude) {
            Write-Verbose -Verbose "At least one of the following parameters must be specified: Members, MembersToInclude, MembersToExclude"
            return $null
        }
    }

    if ($ContentDatabases -and $AllContentDatabases) {
        Write-Verbose -Verbose "Cannot use the ContentDatabases parameter together with the AllContentDatabases parameter"
        return $null
    }

    Write-Verbose -Message "Getting all Shell Admins"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        try {
            $spFarm = Get-SPFarm
        } catch {
            Write-Verbose -Verbose "No local SharePoint farm was detected. Health Analyzer Rule settings will not be applied"
            return $null
        }

        $shellAdmins = Get-SPShellAdmin
        $allContentDatabases = $true

        $cdbPermissions = @()
        foreach ($contentDatabase in (Get-SPContentDatabase)) {
            $cdbPermission = @{}
            
            $cdbPermission.Name = $contentDatabase.Name
            $dbShellAdmins = Get-SPShellAdmin -Database $contentDatabase.Id
            $cdbPermission.Members = $dbShellAdmins.UserName
            
            $cdbPermissions += $cdbPermission            
        } 

        return @{
            Name = $params.Name
            Members = $shellAdmins.UserName
            MembersToInclude = $params.MembersToInclude
            MembersToExclude = $params.MembersToExclude
            ContentDatabases = $cdbPermissions
            AllContentDatabases = $params.AllContentDatabases
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
        [parameter(Mandatory = $true)] [System.String]    $Name,
        [parameter(Mandatory = $false)] [System.String[]] $Members,
        [parameter(Mandatory = $false)] [System.String[]] $MembersToInclude,
        [parameter(Mandatory = $false)] [System.String[]] $MembersToExclude,
        [parameter(Mandatory = $false)] [Microsoft.Management.Infrastructure.CimInstance[]] $ContentDatabases,
        [parameter(Mandatory = $false)] [System.Boolean]  $AllContentDatabases,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Setting Shell Admin config"
    
    if ($Members -and (($MembersToInclude) -or ($MembersToExclude))) {
        Throw "Cannot use the Members parameter together with the MembersToInclude or MembersToExclude parameters"
    }

    if ($ContentDatabases) {
        foreach ($contentDatabase in $ContentDatabases) {
            if ($contentDatabase.Members -and (($contentDatabase.MembersToInclude) -or ($contentDatabase.MembersToExclude))) {
                throw "ContentDatabases: Cannot use the Members parameter together with the MembersToInclude or MembersToExclude parameters"
            }

            if (!$contentDatabase.Members -and !$contentDatabase.MembersToInclude -and !$contentDatabase.MembersToExclude) {
                throw "ContentDatabases: At least one of the following parameters must be specified: Members, MembersToInclude, MembersToExclude"
            }
        }
    } else {
        if (!$Members -and !$MembersToInclude -and !$MembersToExclude) {
            throw "At least one of the following parameters must be specified: Members, MembersToInclude, MembersToExclude"
        }
    }

    if ($ContentDatabases -and $AllContentDatabases) {
        throw "Cannot use the ContentDatabases parameter together with the AllContentDatabases parameter"
    }

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        try {
            $spFarm = Get-SPFarm
        } catch {
            throw "No local SharePoint farm was detected. Health Analyzer Rule settings will not be applied"
            return
        }

        $shellAdmins = Get-SPShellAdmin

        if ($params.Members) {
            Write-Verbose -Verbose "Processing Members"
            if ($shellAdmins) {
                $differences = Compare-Object -ReferenceObject $shellAdmins.UserName -DifferenceObject $params.Members

                if ($differences -eq $null) {
                    Write-Verbose -Verbose "Shell Admins group matches. No further processing required"
                } else {
                    Write-Verbose -Verbose "Shell Admins group does not match. Perform corrective action"
                    ForEach ($difference in $differences) {
                        if ($difference.SideIndicator -eq "=>") {
                            # Add account
                            $user = $difference.InputObject
                            Add-SPShellAdmin -UserName $user
                        } elseif ($difference.SideIndicator -eq "<=") {
                            # Remove account
                            $user = $difference.InputObject
                            Remove-SPShellAdmin -UserName $user -Confirm:$false
                        }
                    }
                }
            } else {
                foreach ($member in $params.Members) {
                    Add-SPShellAdmin -UserName $member
                }
            }
        }

        if ($params.MembersToInclude) {
            Write-Verbose -Verbose "Processing MembersToInclude"
            if ($shellAdmins) {
                foreach ($member in $params.MembersToInclude) {
                    if (-not $shellAdmins.UserName.Contains($member)) {
                        Add-SPShellAdmin -UserName $member
                    }
                }
            } else {
                foreach ($member in $params.MembersToInclude) {
                    Add-SPShellAdmin -UserName $member
                }
            }
        }

        if ($params.MembersToExclude) {
            Write-Verbose -Verbose "Processing MembersToExclude"
            if ($shellAdmins) {
                foreach ($member in $params.MembersToExclude) {
                    if ($shellAdmins.UserName.Contains($member)) {
                        Remove-SPShellAdmin -UserName $member -Confirm:$false
                    }
                }
            }
        }

        if ($params.ContentDatabases) {
            Write-Verbose "Processing ContentDatabases parameter"
            # The ContentDatabases parameter is set
            # Compare the configuration against the actual set and correct any issues

            foreach ($contentDatabase in $params.ContentDatabases) {
                # Check if configured database exists, throw error if not
                Write-Verbose -Verbose "Processing Content Database: $($contentDatabase.Name)"

                $currentCDB = Get-SPContentDatabase | Where-Object { $_.Name.ToLower() -eq $contentDatabase.Name.ToLower() }
                if ($currentCDB -ne $null) {
                    $dbShellAdmins = Get-SPShellAdmin -database $currentCDB.Id

                    if ($contentDatabase.Members) {
                        Write-Verbose -Verbose "Processing Members"
                        if ($dbShellAdmins) {
                            $differences = Compare-Object -ReferenceObject $contentDatabase.Members -DifferenceObject $dbShellAdmins.UserName
                            ForEach ($difference in $differences) {
                                if ($difference.SideIndicator -eq "<=") {
                                    # Add account
                                    $user = $difference.InputObject
                                    Add-SPShellAdmin -database $currentCDB.Id -UserName $user
                                } elseif ($difference.SideIndicator -eq "=>") {
                                    # Remove account
                                    $user = $difference.InputObject
                                    Remove-SPShellAdmin -database $currentCDB.Id -UserName $user -Confirm:$false
                                }
                            }
                        } else {
                            Foreach ($member in $contentDatabase.Members) {
                                Add-SPShellAdmin -database $currentCDB.Id -UserName $member
                            }
                        }
                    }

                    if ($contentDatabase.MembersToInclude) {
                        Write-Verbose -Verbose "Processing MembersToInclude"
                        if ($dbShellAdmins) {
                            ForEach ($member in $contentDatabase.MembersToInclude) {
                                if (-not $dbShellAdmins.UserName.Contains($member)) {
                                    Add-SPShellAdmin -database $currentCDB.Id -UserName $member
                                }
                            }
                        } else {
                            ForEach ($member in $contentDatabase.MembersToInclude) {
                                Add-SPShellAdmin -database $currentCDB.Id -UserName $member
                            }
                        }
                    }

                    if ($contentDatabase.MembersToExclude) {
                        Write-Verbose -Verbose "Processing MembersToExclude"
                        if ($dbShellAdmins) {
                            ForEach ($member in $contentDatabase.MembersToExclude) {
                                if ($dbShellAdmins.UserName.Contains($member)) {
                                    Remove-SPShellAdmin -database $currentCDB.Id -UserName $member -Confirm:$false
                                }
                            }
                        }
                    }
                } else {
                    throw "Specified database does not exist"
                }
            }
        }

        if ($params.AllContentDatabases) {
            Write-Verbose "Processing AllContentDatabases parameter"

            foreach ($contentDatabase in (Get-SPContentDatabase)) {
                $dbShellAdmins = Get-SPShellAdmin -database $contentDatabase.Id
                if ($params.Members) {
                    Write-Verbose -Verbose "Processing Content Database: $($contentDatabase.Name)"
                    if ($dbShellAdmins) {
                        $differences = Compare-Object -ReferenceObject $dbShellAdmins.UserName -DifferenceObject $params.Members

                        if ($differences -eq $null) {
                            Write-Verbose -Verbose "Shell Admins group matches. No further processing required"
                        } else {
                            Write-Verbose -Verbose "Shell Admins group does not match. Perform corrective action"
                            ForEach ($difference in $differences) {
                                if ($difference.SideIndicator -eq "=>") {
                                    # Add account
                                    $user = $difference.InputObject
                                    Add-SPShellAdmin -database $contentDatabase.Id -UserName $user
                                } elseif ($difference.SideIndicator -eq "<=") {
                                    # Remove account
                                    $user = $difference.InputObject
                                    Remove-SPShellAdmin -database $contentDatabase.Id -UserName $user -Confirm:$false
                                }
                            }
                        }
                    } else {
                        Foreach ($member in $params.Members) {
                            Add-SPShellAdmin -database $contentDatabase.Id -UserName $member
                        }
                    }
                }

                if ($params.MembersToInclude) {
                    if ($dbShellAdmins) {
                        foreach ($member in $params.MembersToInclude) {
                            if (-not $dbShellAdmins.UserName.Contains($member)) {
                                Add-SPShellAdmin -database $contentDatabase.Id -UserName $member
                            }
                        }
                    } else {
                        foreach ($member in $params.MembersToInclude) {
                            Add-SPShellAdmin -database $contentDatabase.Id -UserName $member
                        }

                    }
                }

                if ($params.MembersToExclude) {
                    if ($dbShellAdmins) {
                        foreach ($member in $params.MembersToExclude) {
                            if ($dbShellAdmins.UserName.Contains($member)) {
                                Remove-SPShellAdmin -database $contentDatabase.Id -UserName $member -Confirm:$false
                            }
                        }
                    }
                }
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
        [parameter(Mandatory = $true)] [System.String]    $Name,
        [parameter(Mandatory = $false)] [System.String[]] $Members,
        [parameter(Mandatory = $false)] [System.String[]] $MembersToInclude,
        [parameter(Mandatory = $false)] [System.String[]] $MembersToExclude,
        [parameter(Mandatory = $false)] [Microsoft.Management.Infrastructure.CimInstance[]] $ContentDatabases,
        [parameter(Mandatory = $false)] [System.Boolean]  $AllContentDatabases,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Testing Shell Admin settings"

    # Start checking
    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($null -eq $CurrentValues) { return $false }

    if ($Members) {
        Write-Verbose "Processing Members parameter"
        if (-not $CurrentValues.Members) { return $false }

        $differences = Compare-Object -ReferenceObject $CurrentValues.Members -DifferenceObject $Members

        if ($differences -eq $null) {
            Write-Verbose "Shell Admins group matches"
        } else {
            Write-Verbose "Shell Admins group does not match"
            return $false
        }
    }

    if ($MembersToInclude) {
        Write-Verbose "Processing MembersToInclude parameter"
        if (-not $CurrentValues.Members) { return $false }

        ForEach ($member in $MembersToInclude) {
            if (-not($CurrentValues.Members.Contains($member))) {
                Write-Verbose "$member is not a Shell Admin. Set result to false"
                return $false
            } else {
                Write-Verbose "$member is already a Shell Admin. Skipping"
            }
        }
    }

    if ($MembersToExclude) {
        Write-Verbose "Processing MembersToExclude parameter"
        if ($CurrentValues.Members) {
            ForEach ($member in $MembersToExclude) {
                if ($CurrentValues.Members.Contains($member)) {
                    Write-Verbose "$member is a Shell Admin. Set result to false"
                    return $false
                } else {
                    Write-Verbose "$member is not a Shell Admin. Skipping"
                }
            }
        }
    }
    
    if ($AllContentDatabases) {
        # The AllContentDatabases parameter is set
        # Check the Members group against all databases
        Write-Verbose "Processing AllContentDatabases parameter"

        foreach ($contentDatabase in $CurrentValues.ContentDatabases) {
            # Check if configured database exists, throw error if not
            Write-Verbose "Processing Content Database: $($contentDatabase.Name)"

            if ($Members) {
                if (-not $contentDatabase.Members) { return $false }

                $differences = Compare-Object -ReferenceObject $contentDatabase.Members -DifferenceObject $Members
                if ($differences -eq $null) {
                    Write-Verbose "Shell Admins group matches"
                } else {
                    Write-Verbose "Shell Admins group does not match"
                    return $false
                }
            }

            if ($MembersToInclude) {
                if (-not $contentDatabase.Members) { return $false }

                ForEach ($member in $MembersToInclude) {
                    if (-not($contentDatabase.Members.Contains($member))) {
                        Write-Verbose "$member is not a Shell Admin. Set result to false"
                        return $false
                    } else {
                        Write-Verbose "$member is already a Shell Admin. Skipping"
                    }
                }
            }

            if ($MembersToExclude) {
                if ($contentDatabase.Members) {
                    ForEach ($member in $MembersToExclude) {
                        if ($contentDatabase.Members.Contains($member)) {
                            Write-Verbose "$member is a Shell Admin. Set result to false"
                            return $false
                        } else {
                            Write-Verbose "$member is not a Shell Admin. Skipping"
                        }
                    }
                }
            }
        }
    }

    if ($ContentDatabases) {
        # The ContentDatabases parameter is set
        # Compare the configuration against the actual set
        Write-Verbose "Processing ContentDatabases parameter"

        foreach ($contentDatabase in $ContentDatabases) {
            # Check if configured database exists, throw error if not
            Write-Verbose "Processing Content Database: $($contentDatabase.Name)"

            $currentCDB = $CurrentValues.ContentDatabases | Where-Object { $_.Name.ToLower() -eq $contentDatabase.Name.ToLower() }
            if ($currentCDB -ne $null) {
                if ($contentDatabase.Members) {
                    Write-Verbose "Processing Members parameter"
                    if (-not $currentCDB.Members) { return $false }

                    $differences = Compare-Object -ReferenceObject $currentCDB.Members -DifferenceObject $contentDatabase.Members
                    if ($differences -eq $null) {
                        Write-Verbose "Shell Admins group matches"
                    } else {
                        Write-Verbose "Shell Admins group does not match"
                        return $false
                    }
                }

                if ($contentDatabase.MembersToInclude) {
                    Write-Verbose "Processing MembersToInclude parameter"
                    if (-not $currentCDB.Members) { return $false }

                    ForEach ($member in $contentDatabase.MembersToInclude) {
                        if (-not($currentCDB.Members.Contains($member))) {
                            Write-Verbose "$member is not a Shell Admin. Set result to false"
                            return $false
                        } else {
                            Write-Verbose "$member is already a Shell Admin. Skipping"
                        }
                    }
                }

                if ($contentDatabase.MembersToExclude) {
                    Write-Verbose "Processing MembersToExclude parameter"
                    if ($currentCDB.Members) {
                        ForEach ($member in $contentDatabase.MembersToExclude) {
                            if ($currentCDB.Members.Contains($member)) {
                                Write-Verbose "$member is a Shell Admin. Set result to false"
                                return $false
                            } else {
                                Write-Verbose "$member is not a Shell Admin. Skipping"
                            }
                        }
                    }
                }
            } else {
                throw "Specified database does not exist"
            }
        }
    }

    return $true
}


Export-ModuleMember -Function *-TargetResource
