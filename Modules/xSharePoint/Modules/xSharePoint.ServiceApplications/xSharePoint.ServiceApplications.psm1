function Get-xSharePointServiceApplication() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1)]
        [string]
        $Name,

        [parameter(Mandatory = $true,Position=2)]
        [ValidateSet("BCS")]
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
    }
}

Export-ModuleMember -Function *
