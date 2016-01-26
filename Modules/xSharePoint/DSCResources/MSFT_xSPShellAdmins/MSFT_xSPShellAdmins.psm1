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
        [parameter(Mandatory = $false)] [Microsoft.Management.Infrastructure.CimInstance] $ContentDatabases,
        [parameter(Mandatory = $false)] [System.Boolean]  $AllContentDatabases,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    if ($Members -and (($MembersToInclude) -or ($MembersToExclude))) {
        Throw "Cannot use the Members parameter together with the MembersToInclude or MembersToExclude parameters"
    }

    if (!$Members -and !$MembersToInclude -and !$MembersToExclude) {
        throw "At least one of the following parameters must be specified: Members, MembersToInclude, MembersToExclude"
    }

    if ($ContentDatabases -and $AllContentDatabases) {
        throw "Cannot use the ContentDatabases parameter together with the AllContentDatabases parameter"
    }

    Write-Verbose -Message "Getting all Shell Admins"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $shellAdmins = Get-SPShellAdmin
        $allContentDatabases = $true

        $cdbPermissions = @()
        Write-Verbose -Verbose "Looping through content databases"
        foreach ($contentDatabase in (Get-SPContentDatabase)) {
            Write-Verbose -Verbose "Checking content database $contentDatabase"
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
        [parameter(Mandatory = $false)] [System.Boolean]  $AllContentDatabases,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Setting Shell Admin config"
    
    if ($Members -and (($MembersToInclude) -or ($MembersToExclude))) {
        Throw "Cannot use the Members parameter together with the MembersToInclude or MembersToExclude parameters"
    }

    if (!$Members -and !$MembersToInclude -and !$MembersToExclude) {
        throw "At least one of the following parameters must be specified: Members, MembersToInclude, MembersToExclude"
    }

    if ($ContentDatabases -and $AllContentDatabases) {
        throw "Cannot use the ContentDatabases parameter together with the AllContentDatabases parameter"
    }

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $shellAdmins = Get-SPShellAdmin

        if ($params.Members) {
            $differences = Compare-Object -ReferenceObject $shellAdmins.UserName -DifferenceObject $params.Members

            if ($differences -eq $null) {
                Write-Verbose "Shell Admins group matches. No further processing required"
            } else {
                Write-Verbose "Shell Admins group does not match. Perform corrective action"
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
        }

        if ($params.MembersToInclude) {
            foreach ($member in $params.MembersToInclude) {
                if (-not $shellAdmins.UserName.Contains($member)) {
                    Add-SPShellAdmin -UserName $member
                }
            }
        }

        if ($params.MembersToExclude) {
            foreach ($member in $params.MembersToInclude) {
                if ($shellAdmins.UserName.Contains($member)) {
                    Remove-SPShellAdmin -UserName $member -Confirm:$false
                }
            }
        }

        if ($params.ContentDatabases) {
            # The ContentDatabases parameter is set
            # Compare the configuration against the actual set and correct any issues

            foreach ($contentDatabase in $params.ContentDatabases) {
                # Check if configured database exists, throw error if not
                Write-Verbose "Processing Content Database: $($contentDatabase.Name)"

                $currentCDB = Get-SPContentDatabase | Where-Object { $_.Name.ToLower() -eq $contentDatabase.Name.ToLower() }
                if ($currentCDB -ne $null) {
                    $dbShellAdmins = Get-SPShellAdmins -database $currentCDB.Id
                    if ($contentDatabase.Members) {
                        $differences = Compare-Object -ReferenceObject $currentCDB.Members -DifferenceObject $dbShellAdmins.UserName
                        ForEach ($difference in $differences) {
                            if ($difference.SideIndicator -eq "=>") {
                                # Add account
                                $user = $difference.InputObject
                                Add-SPShellAdmin -database $currentCDB.Id -UserName $user
                            } elseif ($difference.SideIndicator -eq "<=") {
                                # Remove account
                                $user = $difference.InputObject
                                Remove-SPShellAdmin -database $currentCDB.Id -UserName $user -Confirm:$false
                            }
                        }
                    }

                    if ($contentDatabase.MembersToInclude) {
                        ForEach ($member in $contentDatabase.MembersToInclude) {
                            if (-not $dbShellAdmins.UserName.Contains($member)) {
                                Add-SPShellAdmin -UserName $member
                            }
                        }
                    }

                    if ($contentDatabase.MembersToExclude) {
                        ForEach ($member in $contentDatabase.MembersToExclude) {
                            if ($shellAdmins.UserName.Contains($member)) {
                                Remove-SPShellAdmin -UserName $member -Confirm:$false
                            }
                        }
                    }
                } else {
                    throw "Specified database does not exist"
                }
            }
        }

        if ($params.AllContentDatabases) {
            foreach ($contentDatabase in (Get-SPContentDatabase)) {
                $dbShellAdmins = Get-SPShellAdmin -database $contentDatabase.Id
                if ($params.Members) {
                    $differences = Compare-Object -ReferenceObject $dbShellAdmins.UserName -DifferenceObject $params.Members

                    if ($differences -eq $null) {
                        Write-Verbose "Shell Admins group matches. No further processing required"
                    } else {
                        Write-Verbose "Shell Admins group does not match. Perform corrective action"
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
                }

                if ($params.MembersToInclude) {
                    foreach ($member in $params.MembersToInclude) {
                        if (-not $dbShellAdmins.UserName.Contains($member)) {
                            Add-SPShellAdmin -UserName $member
                        }
                    }
                }

                if ($params.MembersToExclude) {
                    foreach ($member in $params.MembersToInclude) {
                        if ($dbShellAdmins.UserName.Contains($member)) {
                            Remove-SPShellAdmin -UserName $member -Confirm:$false
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
        [parameter(Mandatory = $false)] [System.Boolean]  $AllContentDatabases,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Testing Shell Admin settings"
    
    if ($Members -and (($MembersToInclude) -or ($MembersToExclude))) {
        Throw "Cannot use the Members parameter together with the MembersToInclude or MembersToExclude parameters"
    }

    if (!$Members -and !$MembersToInclude -and !$MembersToExclude) {
        throw "At least one of the following parameters must be specified: Members, MembersToInclude, MembersToExclude"
    }

    if ($ContentDatabases -and $AllContentDatabases) {
        throw "Cannot use the ContentDatabases parameter together with the AllContentDatabases parameter"
    }

    # Start checking
    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($null -eq $CurrentValues) { return $false }

    if ($Members) {
        Write-Verbose "Processing Members parameter"
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
        ForEach ($member in $MembersToExclude) {
            if ($CurrentValues.Members.Contains($member)) {
                Write-Verbose "$member is a Shell Admin. Set result to false"
                return $false
            } else {
                Write-Verbose "$member is not a Shell Admin. Skipping"
            }
        }
    }
    
    if ($AllContentDatabases) {
        # The AllContentDatabases parameter is set
        # Check the Members group against all databases

        foreach ($contentDatabase in $CurrentValues.ContentDatabases) {
            # Check if configured database exists, throw error if not
            Write-Verbose "Processing Content Database: $($contentDatabase.Name)"

            if ($Members) {
                $differences = Compare-Object -ReferenceObject $contentDatabase.Members -DifferenceObject $Members
                if ($differences -eq $null) {
                    Write-Verbose "Shell Admins group matches"
                } else {
                    Write-Verbose "Shell Admins group does not match"
                    return $false
                }
            }

            if ($MembersToInclude) {
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

    if ($ContentDatabases) {
        # The ContentDatabases parameter is set
        # Compare the configuration against the actual set

        foreach ($contentDatabase in $ContentDatabases) {
            # Check if configured database exists, throw error if not
            Write-Verbose "Processing Content Database: $($contentDatabase.Name)"

            $currentCDB = $CurrentValues.ContentDatabases | Where-Object { $_.Name.ToLower() -eq $contentDatabase.Name.ToLower() }
            if ($currentCDB -ne $null) {
                if ($contentDatabase.Members) {
                    $differences = Compare-Object -ReferenceObject $currentCDB.Members -DifferenceObject $contentDatabase.Members
                    if ($differences -eq $null) {
                        Write-Verbose "Shell Admins group matches"
                    } else {
                        Write-Verbose "Shell Admins group does not match"
                        return $false
                    }
                }

                if ($contentDatabase.MembersToInclude) {
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
                    ForEach ($member in $contentDatabase.MembersToExclude) {
                        if ($currentCDB.Members.Contains($member)) {
                            Write-Verbose "$member is a Shell Admin. Set result to false"
                            return $false
                        } else {
                            Write-Verbose "$member is not a Shell Admin. Skipping"
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

