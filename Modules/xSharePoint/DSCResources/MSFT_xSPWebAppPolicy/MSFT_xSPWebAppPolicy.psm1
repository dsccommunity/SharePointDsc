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
            $member.PermissionLevel = ($policy.PolicyRoleBindings.Name | Select-Object -First 1).Name
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

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
		$params = $args[0]

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue

        $denyAll     = $wa.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::DenyAll)
		$denyWrite   = $wa.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::DenyWrite)
        $fullControl = $wa.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl)
        $fullRead    = $wa.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullRead)

        if ($null -eq $wa) { return $null }

		$members = @()
        foreach ($policy in $wa.Policies) {
            $member = @{}
            $member.Username = $policy.UserName
            $member.PermissionLevel = ($policy.PolicyRoleBindings.Name | Select-Object -First 1).Name
            $member.ActAsSystemAccount = $policy.IsSystemUser
            $members += $member
        }

		if ($params.Members) {
			$differences = ComparePolicies $members $params.Members

			foreach ($difference in $differences) {
				$user = $difference.Keys[0]
				$change = $difference[$user]
				switch ($change) {
					Additional
						{
							## Policy contains additional account, remove this account
							$wa.Policies.Remove($user)
						}
					Different
						{
							## Account exists but has the incorrect settings, correct this account
							$policy = $wa.Policies[$user]
							$usersettings = GetUser $params.Members $user
							if ($usersettings.ActAsSystemAccount -ne $policy.IsSystemUser) { $policy.IsSystemUser = $usersettings.ActAsSystemAccount }
							if ($usersettings.PermissionLevel -ne $policy.RoleBindings.Name) { 
								switch ($usersettings.PermissionLevel) {
									"Deny All" {
										$policy.PolicyRoleBindings.RemoveAll()
										$policy.PolicyRoleBindings.Add($denyAll)
									}
									"Deny Write" {
										$policy.PolicyRoleBindings.RemoveAll()
										$policy.PolicyRoleBindings.Add($denyWrite)
									}
									"Full Control" {
										$policy.PolicyRoleBindings.RemoveAll()
										$policy.PolicyRoleBindings.Add($fullControl)
									}
									"Full Read" {
										$policy.PolicyRoleBindings.RemoveAll()
										$policy.PolicyRoleBindings.Add($fullRead)
									}
								}
							}
							$wa.Update()
						}
					Missing
						{
							## Account is missing, add this account
							$usersettings = GetUser $params.Members $user
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
							if ($usersettings.ContainsKey("ActAsSystemUser") -eq $true) {
								$newPolicy.IsSystemUser = $usersettings.ActAsSystemUser
							}

							$wa.Update()
						}
				}
			}

		}

		if ($params.MembersToInclude) {

		}

		if ($params.MembersToExclude) {

		}




		# (New-SPClaimsPrincipal acme\adminyk -IdentityType WindowsSamAccountName).ToEncodedString()

        switch($params.PermissionLevel) {
            "Deny All" {
                $newRole = $wa.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::DenyAll)    
            }
            "Deny Write" {
                $newRole = $wa.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::DenyWrite)    
            }
            "Full Control" {
                $newRole = $wa.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl)    
            }
            "Full Read" {
                $newRole = $wa.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullRead)    
            }
        }
        
        if ($wa.Policies.UserName -contains $params.UserName) {
            $policyObject = $wa.Policies | Where-Object { $_.UserName -eq $params.UserName }
        } else {
            foreach($userName in $wa.Policies.UserName) {
                $claimsPrincipal = New-SPClaimsPrincipal -EncodedClaim $userName -ErrorAction SilentlyContinue
                if (($null -ne $claimsPrincipal) -and ($claimsPrincipal.Value -eq $params.UserName)) {
                    $policyObject = $wa.Policies | Where-Object { $_.UserName -eq $userName }
                }
            }
        }

        if ($null -ne $policyObject) {
            if ($params.ContainsKey("ActAsSystemUser") -eq $true) {
                $policyObject.IsSystemUser = $params.ActAsSystemUser
            }
            $policyObject.PolicyRoleBindings.RemoveAll()
            $policyObject.PolicyRoleBindings.Add($newRole)
            
            $wa.Update()
        } else {
            ##### Check if user exists before adding. Claims user ook
            $newPolicy = $wa.Policies.Add($params.UserName, $params.UserName)
            $newPolicy.PolicyRoleBindings.Add($newRole)
            if ($params.ContainsKey("ActAsSystemUser") -eq $true) {
                $newPolicy.IsSystemUser = $params.ActAsSystemUser
            }

            $wa.Update()
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
		$differences = ComparePolicies $currentValues.Members $Members

		if ($differences.Count -eq 0) { return $false } else { return $true }
	}

    if ($MembersToInclude) {
		foreach ($member in $MembersToInclude) {
			foreach ($policy in $CurrentValues.Members) {
				if ($policy.Username -eq $member.Username) {
					### CHECK PermissionLevel and SystemUser
					if ($policy.ActAsSystemUser -ne $member.ActAsSystemUser) { return $false }
					if ($policy.PermissionLevel -ne $member.PermissionLevel) { return $false }
				} else { return $false }
			}
		}
    }

    if ($MembersToExclude) {
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

############ Supporting functions ############

function GetUser() {
	Param (
        [Parameter(Mandatory=$true)] 
        [Array] $dscsettings,
        [Parameter(Mandatory=$true)] 
        [String] $user
	)

	foreach ($setting in $dscsettings) {
		if ($setting.Username -eq $user) { return $setting }
	}

	return $null
}

function CheckUser() {
    Param (
        [Array] $source,
        [string] $str
    )

    ForEach ($entry in $source) {
        if($entry.ContainsKey($str)) { return $true }
    }
    return $false
}

function ComparePolicies() {
    Param (
        [Parameter(Mandatory=$true)] 
        [Array] $wapolicies,
        [Parameter(Mandatory=$true)] 
        [Array] $dscsettings
    )

    $diff = @()

    $match=$true
    foreach ($policy in $wapolicies) {
        $memberexists = $false
        foreach($setting in $dscsettings) {
            if ($policy.Username.ToLower() -eq $setting.Username.ToLower()) {
                $memberexists = $true
                if ($policy.PermissionLevel.ToLower() -ne $setting.PermissionLevel.ToLower()) {
                    if (-not (CheckUser $diff $policy.Username.ToLower())) {
                         $diff += @{$policy.Username.ToLower()="Different"}
                        $match = $false
                    }
                }
                if ($policy.ActAsSystemUser -ne $setting.ActAsSystemUser) {
                    if (-not (CheckUser $diff $policy.Username.ToLower())) {
                         $diff += @{$policy.Username.ToLower()="Different"}
                        $match = $false
                    }
                }
            }
        }
        if (-not $memberexists) {
            if (-not (CheckUser $diff $policy.Username.ToLower())) {
                $diff += @{$policy.Username.ToLower()="Additional"}
                $match = $false
            }
        }
    }

    foreach ($setting in $dscsettings) {
        $memberexists = $false
        foreach($policy in $wapolicies) {
            if ($policy.Username.ToLower() -eq $setting.Username.ToLower()) {
                $memberexists = $true
                if ($policy.PermissionLevel.ToLower() -ne $setting.PermissionLevel.ToLower()) {
                    if (-not (CheckUser $diff $policy.Username.ToLower())) {
                        $diff += @{$setting.Username.ToLower()="Different"}
                        $match = $false
                    }
                }
                if ($policy.ActAsSystemUser -ne $setting.ActAsSystemUser) {
                    if (-not (CheckUser $diff $policy.Username.ToLower())) {
                        $diff += @{$setting.Username.ToLower()="Different"}
                        $match = $false
                    }
                }
            }
        }
        if (-not $memberexists) {
            if (-not (CheckUser $diff $setting.Username.ToLower())) {
                $diff += @{$setting.Username.ToLower()="Missing"}
                $match = $false
            }
        }
    }
    return $diff
}


Export-ModuleMember -Function *-TargetResource
