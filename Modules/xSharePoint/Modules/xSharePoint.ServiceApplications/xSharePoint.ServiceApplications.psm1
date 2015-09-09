function Get-xSharePointServiceApplication() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1)]
        [string]
        $Name,

        [parameter(Mandatory = $true,Position=2)]
        [ValidateSet("BCS", "MMS", "Search", "SecureStore", "Usage", "UserProfile", "UserProfileSync")]
        [string]
        $TypeName
    )

    $serviceApps = Invoke-xSharePointSPCmdlet -CmdletName "Get-SPServiceApplication" -Arguments @{ Name = $Name }
    $serviceApp = $serviceApps | Where-Object { $_.TypeName -eq (Get-xSharePointServiceApplicationName -Name $TypeName) }
    return $serviceApp
}

function Get-xSharePointServiceApplicationName() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1)]
        [string]
        $Name
    )
    Switch($Name) {
        "BCS" { return "Business Data Connectivity Service Application" }
        "MMS" { return "Managed Metadata Service" }
        "Search" { return "Search Service Application" }
        "SecureStore" { return "Secure Store Service Application" }
        "Usage" { return "Usage and Health Data Collection Service Application" }
        "UserProfile" { return "User Profile Service Application" }
        "UserProfileSync" { return "User Profile Synchronization Service" }
    }
}

Export-ModuleMember -Function *
