function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $WebAppUrl,
        [parameter(Mandatory = $true)]  [System.String] $UserName,
        [parameter(Mandatory = $true)]  [ValidateSet("Deny All","Deny Write","Full Read", "Full Control")] [System.String] $PermissionLevel,
        [parameter(Mandatory = $false)] [System.String] $ActAsSystemUser,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Getting cache accounts for $WebAppUrl"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue

        if ($null -eq $wa) { return $null }
        
        if ($wa.Policies.UserName -contains $params.UserName) {
            $policyObject = $wa.Policies | Where-Object { $_.UserName -eq $params.UserName }
            return @{
                WebAppUrl = $params.WebAppUrl
                UserName = $params.UserName
                PermissionLevel = $policyObject.PolicyRoleBindings[0].Name
                ActAsSystemUser = $policyObject.IsSystemUser
                InstallAccount = $params.InstallAccount
            }
        } else { return $null }
    }
    return $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $WebAppUrl,
        [parameter(Mandatory = $true)]  [System.String] $UserName,
        [parameter(Mandatory = $true)]  [ValidateSet("DenyAll","DenyWrite","FullRead", "FullControl")] [System.String] $PermissionLevel,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Setting cache accounts for $WebAppUrl"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue

        if ($null -eq $wa) { return $null }

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
            if ($params.ContainsKey("ActAsSystemUser") -eq $true) {
                $policyObject.IsSystemUser = $params.ActAsSystemUser
            }
            $policyObject.PolicyRoleBindings.RemoveAll()
            $policyObject.PolicyRoleBindings.Add($newRole)
            
            $wa.Update()
            
        } else {
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
        [parameter(Mandatory = $true)]  [System.String] $UserName,
        [parameter(Mandatory = $true)]  [ValidateSet("DenyAll","DenyWrite","FullRead", "FullControl")] [System.String] $PermissionLevel,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing cache accounts for $WebAppUrl"
    if ($null -eq $CurrentValues) {return $false }
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $params -ValuesToCheck @("PermissionLevel", "ActAsSystemUser")
}

Export-ModuleMember -Function *-TargetResource
