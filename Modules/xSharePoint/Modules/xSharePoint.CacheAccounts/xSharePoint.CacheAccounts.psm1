function Set-xSharePointCacheReaderPolicy() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1)]
        $WebApplication,

        [parameter(Mandatory = $true,Position=2)]
        [string]
        $UserName
    )
    $policy = $WebApplication.Policies.Add($UserName, $UserName)
    $policyRole = $wa.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullRead)
    $policy.PolicyRoleBindings.Add($policyRole)
}

function Set-xSharePointCacheOwnerPolicy() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1)]
        $WebApplication,

        [parameter(Mandatory = $true,Position=2)]
        [string]
        $UserName
    )
    $policy = $WebApplication.Policies.Add($UserName, $UserName)
    $policyRole = $wa.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl)
    $policy.PolicyRoleBindings.Add($policyRole)
}

Export-ModuleMember -Function *