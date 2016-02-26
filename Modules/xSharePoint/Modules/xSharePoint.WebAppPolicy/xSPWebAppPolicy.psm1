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
        Write-Verbose $entry.Count
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
                    Write-Verbose "Permission level different"
                    if (-not (CheckUser $diff $policy.Username.ToLower())) {
                        $diff += @{$policy.Username.ToLower()="Different"}
                        $match = $false
                    }
                }
                if ($policy.ActAsSystemAccount -ne $setting.ActAsSystemAccount) {
                    Write-Verbose "System User different"
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
                if ($policy.ActAsSystemAccount -ne $setting.ActAsSystemAccount) {
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
