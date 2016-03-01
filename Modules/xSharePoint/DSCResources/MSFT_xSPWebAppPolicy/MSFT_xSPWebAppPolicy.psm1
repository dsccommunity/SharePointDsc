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
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    if ($Members -and (($MembersToInclude) -or ($MembersToExclude))) {
        Throw "Cannot use the Members parameter together with the MembersToInclude or MembersToExclude parameters"
    }

    if (!$Members -and !$MembersToInclude -and !$MembersToExclude) {
        throw "At least one of the following parameters must be specified: Members, MembersToInclude, MembersToExclude"
    }

    Write-Verbose -Message "Getting web app policy for $UserName at $WebAppUrl"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue

        if ($null -eq $wa) { return $null }

        $members = @()
        foreach ($policy in $wa.Policies) {
            $member = @{}
            $member.Username = $policy.UserName
            $member.PermissionLevel = ($policy.PolicyRoleBindings | Select-Object -First 1).Name
            $member.ActAsSystemAccount = $policy.IsSystemUser
            $members += $member
        }

        return @{
                WebAppUrl = $params.WebAppUrl
                Members = $members
                MembersToInclude = $params.MembersToInclude
                MembersToExclude = $params.MembersToExclude
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
        [parameter(Mandatory = $true)]  [System.String] $WebAppUrl,
        [parameter(Mandatory = $false)] [Microsoft.Management.Infrastructure.CimInstance[]] $Members,
        [parameter(Mandatory = $false)] [Microsoft.Management.Infrastructure.CimInstance[]] $MembersToInclude,
        [parameter(Mandatory = $false)] [Microsoft.Management.Infrastructure.CimInstance[]] $MembersToExclude,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Setting web app policy for $UserName at $WebAppUrl"

    if ($Members -and (($MembersToInclude) -or ($MembersToExclude))) {
        Throw "Cannot use the Members parameter together with the MembersToInclude or MembersToExclude parameters"
    }

    if (!$Members -and !$MembersToInclude -and !$MembersToExclude) {
        throw "At least one of the following parameters must be specified: Members, MembersToInclude, MembersToExclude"
    }

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments @($PSBoundParameters,$PSScriptRoot) -ScriptBlock {
		$params = $args[0]
        $ScriptRoot = $args[1]

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue

        if ($null -eq $wa) { return $null }

        $denyAll     = $wa.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::DenyAll)
		$denyWrite   = $wa.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::DenyWrite)
        $fullControl = $wa.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl)
        $fullRead    = $wa.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullRead)

		$members = @()
        foreach ($policy in $wa.Policies) {
            $member = @{}
            $member.Username = $policy.UserName
            $member.PermissionLevel = ($policy.PolicyRoleBindings | Select-Object -First 1).Name
            $member.ActAsSystemAccount = $policy.IsSystemUser
            $members += $member
        }

		if ($params.Members) {
            Write-Verbose -Verbose "Processing Members parameter"
            Import-Module (Join-Path $ScriptRoot "..\..\Modules\xSharePoint.WebAppPolicy\xSPWebAppPolicy.psm1" -Resolve)
			$differences = ComparePolicies $members $params.Members

			foreach ($difference in $differences) {
				$user = $difference.Keys[0]
				$change = $difference[$user]
				switch ($change) {
					Additional
						{
							## Policy contains additional account, remove this account
							Write-Verbose -Verbose "Removing $user"
                            $wa.Policies.Remove($user)
						}
					Different
						{
							## Account exists but has the incorrect settings, correct this account
							Write-Verbose -Verbose "Changing $user"
							$policy = $wa.Policies | Where-Object { $_.UserName -eq $user }
							$usersettings = GetUserFromCollection $params.Members $user
							if ($usersettings.ActAsSystemAccount -ne $policy.IsSystemUser) { $policy.IsSystemUser = $usersettings.ActAsSystemAccount }
							if ($usersettings.PermissionLevel -ne $policy.RoleBindings.Name) { 
                                $policy.PolicyRoleBindings.RemoveAll()
								switch ($usersettings.PermissionLevel) {
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
					Missing
						{
							## Account is missing, add this account
							Write-Verbose -Verbose "Adding $user"
							$usersettings = GetUserFromCollection $params.Members $user
							$newPolicy = $wa.Policies.Add($user, $user)
							switch ($usersettings.PermissionLevel) {
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
							if ($usersettings.ActAsSystemAccount) {
								$newPolicy.IsSystemUser = $usersettings.ActAsSystemAccount
							}
						}
				}
                $wa.Update()
			}
		}

		if ($params.MembersToInclude) {
            Write-Verbose -Verbose "Processing MembersToInclude parameter"
            Import-Module (Join-Path $ScriptRoot "..\..\Modules\xSharePoint.WebAppPolicy\xSPWebAppPolicy.psm1" -Resolve)
            $wapolicies = $wa.Policies
            
			foreach ($member in $params.MembersToInclude) {
                $userpol = GetUserFromCollection $wapolicies $member.UserName

                if ($userpol -ne $null) {
                    # User exists. Check permissions
                    Write-Verbose -Verbose "User $user exists, correcting permissions"
                    if ($member.ActAsSystemAccount -ne $userpol.IsSystemUser) { $userpol.IsSystemUser = $member.ActAsSystemAccount }
                    if ($member.PermissionLevel -ne $userpol.RoleBindings.Name) { 
                        $userpol.PolicyRoleBindings.RemoveAll()
                        switch ($member.PermissionLevel) {
                            "Deny All" {
                                $userpol.PolicyRoleBindings.Add($denyAll)
                            }
                            "Deny Write" {
                                $userpol.PolicyRoleBindings.Add($denyWrite)
                            }
                            "Full Control" {
                                $userpol.PolicyRoleBindings.Add($fullControl)
                            }
                            "Full Read" {
                                $userpol.PolicyRoleBindings.Add($fullRead)
                            }
                        }
                    }
                } else {
                    # User does not exist. Add user
                    Write-Verbose -Verbose "Adding $user"
                    $usersettings = GetUserFromCollection $params.Members $user
                    $newPolicy = $wa.Policies.Add($user, $user)
                    switch ($usersettings.PermissionLevel) {
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
                    if ($usersettings.ActAsSystemAccount) {
                        $newPolicy.IsSystemUser = $usersettings.ActAsSystemAccount
                    }
                }
                $wa.Update()
			}
		}

		if ($params.MembersToExclude) {
            Write-Verbose -Verbose "Processing MembersToInclude parameter"
            Import-Module (Join-Path $ScriptRoot "..\..\Modules\xSharePoint.WebAppPolicy\xSPWebAppPolicy.psm1" -Resolve)
            $wapolicies = $wa.Policies
            
			foreach ($member in $params.MembersToInclude) {
                $userpol = GetUserFromCollection $wapolicies $member.UserName

                if ($userpol -ne $null) {
                    # User exists. Delete user
                    $wa.Policies.Remove($member.UserName)
                }
                $wa.Update()
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
        [parameter(Mandatory = $true)]  [System.String] $WebAppUrl,
        [parameter(Mandatory = $false)] [Microsoft.Management.Infrastructure.CimInstance[]] $Members,
        [parameter(Mandatory = $false)] [Microsoft.Management.Infrastructure.CimInstance[]] $MembersToInclude,
        [parameter(Mandatory = $false)] [Microsoft.Management.Infrastructure.CimInstance[]] $MembersToExclude,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    if ($Members -and (($MembersToInclude) -or ($MembersToExclude))) {
        Throw "Cannot use the Members parameter together with the MembersToInclude or MembersToExclude parameters"
    }

    if (!$Members -and !$MembersToInclude -and !$MembersToExclude) {
        throw "At least one of the following parameters must be specified: Members, MembersToInclude, MembersToExclude"
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing web app policy for $UserName at $WebAppUrl"
    if ($null -eq $CurrentValues) { return $false }

    if ($Members) {
        Write-Verbose "Processing Members - Start Test"
        Import-Module (Join-Path $PsScriptRoot "..\..\Modules\xSharePoint.WebAppPolicy\xSPWebAppPolicy.psm1" -Resolve)
		$differences = ComparePolicies $CurrentValues.Members $Members

		if ($differences.Count -eq 0) { return $true } else { return $false }
	}

    if ($MembersToInclude) {
        Write-Verbose "Processing MembersToInclude - Start Test"
		foreach ($member in $MembersToInclude) {
			foreach ($policy in $CurrentValues.Members) {
				if ($policy.Username -eq $member.Username) {
					### CHECK PermissionLevel and SystemUser
					if ($policy.ActAsSystemAccount -ne $member.ActAsSystemAccount) { return $false }
					if ($policy.PermissionLevel -ne $member.PermissionLevel) { return $false }
				} else { return $false }
			}
		}
    }

    if ($MembersToExclude) {
        Write-Verbose "Processing MembersToExclude - Start Test"
		foreach ($member in $MembersToExclude) {
			foreach ($policy in $CurrentValues.Members) {
				if ($policy.Username -eq $member.Username) {
					return $false
				}
			}
		}
    }

	return $true
}

Export-ModuleMember -Function *-TargetResource
