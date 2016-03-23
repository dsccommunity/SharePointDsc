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

    foreach ($policy in $wapolicies) {
        $memberexists = $false
        foreach($setting in $dscsettings) {
            if ($policy.Username.ToLower() -eq $setting.Username.ToLower()) {
                $memberexists = $true

                $polbinddiff = Compare-Object -ReferenceObject $policy.PermissionLevel.ToLower() -DifferenceObject $setting.PermissionLevel.ToLower()
                if ($polbinddiff -ne $null) {
                    Write-Verbose "Permission level different"
                    if (-not (CheckUser $diff $policy.Username.ToLower())) {
                        $diff += @{$policy.Username.ToLower()="Different"}
                    }
                }
                
                if ($setting.ActAsSystemAccount) {
                    if ($policy.ActAsSystemAccount -ne $setting.ActAsSystemAccount) {
                        Write-Verbose "System User different"
                        if (-not (CheckUser $diff $policy.Username.ToLower())) {
                            $diff += @{$policy.Username.ToLower()="Different"}
                        }
                    }
                }
            }
        }
        if (-not $memberexists) {
            if (-not (CheckUser $diff $policy.Username.ToLower())) {
                $diff += @{$policy.Username.ToLower()="Additional"}
            }
        }
    }

    foreach ($setting in $dscsettings) {
        $memberexists = $false
        foreach($policy in $wapolicies) {
            if ($policy.Username.ToLower() -eq $setting.Username.ToLower()) {
                $memberexists = $true

                $polbinddiff = Compare-Object -ReferenceObject $policy.PermissionLevel.ToLower() -DifferenceObject $setting.PermissionLevel.ToLower()
                if ($polbinddiff -ne $null) {
                    if (-not (CheckUser $diff $policy.Username.ToLower())) {
                        $diff += @{$setting.Username.ToLower()="Different"}
                    }
                }

                if ($setting.ActAsSystemAccount) {
                    if ($policy.ActAsSystemAccount -ne $setting.ActAsSystemAccount) {
                        if (-not (CheckUser $diff $policy.Username.ToLower())) {
                            $diff += @{$setting.Username.ToLower()="Different"}
                        }
                    }
                }
            }
        }
        if (-not $memberexists) {
            if (-not (CheckUser $diff $setting.Username.ToLower())) {
                $diff += @{$setting.Username.ToLower()="Missing"}
            }
        }
    }
    return $diff
}

function GetUserFromCollection() {
    Param (
        [Parameter(Mandatory=$true)] 
        [Array] $collection,
        [Parameter(Mandatory=$true)] 
        [String] $user
    )

    foreach ($item in $collection) {
        if ($item.Username.ToLower() -eq $user.ToLower()) { return $item }
    }

    return $null
}
