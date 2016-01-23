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
        [parameter(Mandatory = $false)] [System.Boolean]  $AllContentDatabases,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    if ($Members -and (($MembersToInclude) -or ($MembersToExclude))) {
        Throw "Cannot use the Members parameter together with the MembersToInclude or MembersToExclude parameters"
    }

    if (!$Members -and !$MembersToInclude -and !$MembersToExclude) {
        throw "At least one of the following parameters must be specified: Members, MembersToInclude, MembersToExclude"
    }

    Write-Verbose -Message "Getting all Shell Admins"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $shellAdmins = Get-SPShellAdmin
        $allContentDatabases = $true

        if ($params.AllContentDatabases) {
            if ($params.Members) {
                Write-Verbose -Verbose "Looping through content databases"
                foreach ($contentDatabase in (Get-SPContentDatabase)) {
                    Write-Verbose -Verbose "Checking content database $contentDatabase"
                    $dbShellAdmins = Get-SPShellAdmin -Database $contentDatabase.Id
                    foreach ($member in $params.Members) {
                        if (-not $dbShellAdmins.UserName.Contains($member)) {
                            $allContentDatabases = $false
                        }
                    }
                } 
            }

            if ($params.MembersToInclude) {
                foreach ($contentDatabase in (Get-SPContentDatabase)) {
                    $dbShellAdmins = Get-SPShellAdmin -Database $contentDatabase.Id
                    foreach ($member in $params.MembersToInclude) {
                        if (-not $dbShellAdmins.UserName.Contains($member)) {
                            $allContentDatabases = $false
                        }
                    }
                } 
            }

            if ($params.MembersToExclude) {
                foreach ($contentDatabase in (Get-SPContentDatabase)) {
                    $dbShellAdmins = Get-SPShellAdmin -Database $contentDatabase.Id
                    foreach ($member in $params.MembersToExclude) {
                        if ($dbShellAdmins.UserName.Contains($member)) {
                            $allContentDatabases = $false
                        }
                    }
                } 
            }
        } else {
            $allContentDatabases = $false
        }

        return @{
            Name = $params.Name
            Members = $shellAdmins.UserName
            MembersToInclude = $params.MembersToInclude
            MembersToExclude = $params.MembersToExclude
            AllContentDatabases = $allContentDatabases
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

            if ($params.AllContentDatabases) {
                foreach ($contentDatabase in (Get-SPContentDatabase)) {
                    $dbShellAdmins = Get-SPShellAdmin -Database $contentDatabase.Id

                    $differences = Compare-Object -ReferenceObject $dbShellAdmins.UserName -DifferenceObject $params.Members

                    if ($differences -eq $null) {
                        Write-Verbose "Shell Admins for database $($contentDatabase.Name) group matches. No further processing required"
                    } else {
                        Write-Verbose "Shell Admins for database $($contentDatabase.Name) group does not match. Perform corrective action"
                        ForEach ($difference in $differences) {
                            if ($difference.SideIndicator -eq "=>") {
                                # Add account
                                $user = $difference.InputObject
                                Add-SPShellAdmin -UserName $user -Database $contentDatabase.Id
                            } elseif ($difference.SideIndicator -eq "<=") {
                                # Remove account
                                $user = $difference.InputObject
                                Remove-SPShellAdmin -UserName $user -Database $contentDatabase.Id -Confirm:$false
                            }
                        }
                    }
                } 
            }
        }

        if ($params.MembersToInclude) {
            foreach ($member in $params.MembersToInclude) {
                if (-not $shellAdmins.UserName.Contains($member)) {
                    Add-SPShellAdmin -UserName $member
                }

                if ($params.AllContentDatabases) {
                    foreach ($contentDatabase in (Get-SPContentDatabase)) {
                        $dbShellAdmins = Get-SPShellAdmin -Database $contentDatabase.Id
                        if (-not $dbShellAdmins.UserName.Contains($member)) {
                            Add-SPShellAdmin -UserName $member -Database $contentDatabase.Id
                        }
                    }
                }
            }
        }

        if ($params.MembersToExclude) {
            foreach ($member in $params.MembersToInclude) {
                if ($shellAdmins.UserName.Contains($member)) {
                    Remove-SPShellAdmin -UserName $member -Confirm:$false
                }

                if ($params.AllContentDatabases) {
                    foreach ($contentDatabase in (Get-SPContentDatabase)) {
                        $dbShellAdmins = Get-SPShellAdmin -Database $contentDatabase.Id
                        if ($dbShellAdmins.UserName.Contains($member)) {
                            Remove-SPShellAdmin -UserName $member -Database $contentDatabase.Id -Confirm:$false
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

    Write-Verbose -Message "Testing Farm Administrator settings"
    
    if ($Members -and (($MembersToInclude) -or ($MembersToExclude))) {
        Throw "Cannot use the Members parameter together with the MembersToInclude or MembersToExclude parameters"
    }

    if (!$Members -and !$MembersToInclude -and !$MembersToExclude) {
        throw "At least one of the following parameters must be specified: Members, MembersToInclude, MembersToExclude"
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($null -eq $CurrentValues) { return $false }
    
    if ($CurrentValues.AllContentDatabases -eq $AllContentDatabases) {
        if ($Members) {
            Write-Verbose "Processing Members parameter"
            $differences = Compare-Object -ReferenceObject $CurrentValues.Members -DifferenceObject $Members

            if ($differences -eq $null) {
                Write-Verbose "Shell Admins group matches"
                return $true
            } else {
                Write-Verbose "Shell Admins group does not match"
                return $false
            }
        }

        $result = $true
        if ($MembersToInclude) {
            Write-Verbose "Processing MembersToInclude parameter"
            ForEach ($member in $MembersToInclude) {
                if (-not($CurrentValues.Members.Contains($member))) {
                    Write-Verbose "$member is not a Shell Admin. Set result to false"
                    $result = $false
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
                    $result = $false
                } else {
                    Write-Verbose "$member is not a Shell Admin. Skipping"
                }
            }
        }

        return $result
    } else {
        return $false
    }
}


Export-ModuleMember -Function *-TargetResource

