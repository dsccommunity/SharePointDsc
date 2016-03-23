function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $WebAppUrl,
        [parameter(Mandatory = $true)]  [System.String]  $SuperUserAlias,
        [parameter(Mandatory = $true)]  [System.String]  $SuperReaderAlias,
        [parameter(Mandatory = $false)] [System.Boolean] $SetWebAppPolicy = $true,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Getting cache accounts for $WebAppUrl"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue

        if ($null -eq $wa) { return @{
            WebAppUrl = $params.WebAppUrl
            SuperUserAlias = $null
            SuperReaderAlias = $null
            SetWebAppPolicy = $false
            InstallAccount = $params.InstallAccount
        } }
        
        $returnVal = @{}
        $returnVal.Add("WebAppUrl", $params.WebAppUrl)
        if ($wa.Properties.ContainsKey("portalsuperuseraccount")) { 
            $returnVal.Add("SuperUserAlias", $wa.Properties["portalsuperuseraccount"])
        } else {
            $returnVal.Add("SuperUserAlias", "")
        }
        if ($wa.Properties.ContainsKey("portalsuperreaderaccount")) { 
            $returnVal.Add("SuperReaderAlias", $wa.Properties["portalsuperreaderaccount"])
        } else {
            $returnVal.Add("SuperReaderAlias", "")
        }
        $returnVal.Add("InstallAccount", $params.InstallAccount)
        
        $policiesSet = $true
        if ($wa.Policies.UserName -notcontains $params.SuperReaderAlias) { $policiesSet = $false }
        if ($wa.Policies.UserName -notcontains $params.SuperUserAlias) { $policiesSet = $false }
        
        if ($wa.Policies.UserName -notcontains ((New-SPClaimsPrincipal -Identity $params.SuperReaderAlias -IdentityType WindowsSamAccountName).ToEncodedString())) { $policiesSet = $false }
        if ($wa.Policies.UserName -notcontains ((New-SPClaimsPrincipal -Identity $params.SuperUserAlias -IdentityType WindowsSamAccountName).ToEncodedString())) { $policiesSet = $false }
        
        $returnVal.Add("SetWebAppPolicy", $policiesSet)
        
        return $returnVal
    }
    return $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $WebAppUrl,
        [parameter(Mandatory = $true)]  [System.String]  $SuperUserAlias,
        [parameter(Mandatory = $true)]  [System.String]  $SuperReaderAlias,
        [parameter(Mandatory = $false)] [System.Boolean] $SetWebAppPolicy = $true,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Setting cache accounts for $WebAppUrl"
    
    $PSBoundParameters.SetWebAppPolicy = $SetWebAppPolicy
    
    Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue
        if ($null -eq $wa) { 
            throw [Exception] "The web applications $($params.WebAppUrl) can not be found to set cache accounts"
        }
        
        if ($wa.Properties.ContainsKey("portalsuperuseraccount")) { 
            $wa.Properties["portalsuperuseraccount"] = $params.SuperUserAlias
        } else {
            $wa.Properties.Add("portalsuperuseraccount", $params.SuperUserAlias)
        }
        if ($wa.Properties.ContainsKey("portalsuperreaderaccount")) { 
            $wa.Properties["portalsuperreaderaccount"] = $params.SuperReaderAlias
        } else {
            $wa.Properties.Add("portalsuperreaderaccount", $params.SuperReaderAlias)
        }
        
        if ($params.SetWebAppPolicy -eq $true) {
            if ($wa.Policies.UserName -contains $params.SuperReaderAlias) { 
                $wa.Policies.Remove($params.SuperReaderAlias)
            }
            $readPolicy = $wa.Policies.Add($params.SuperReaderAlias, $params.SuperReaderAlias)
            $readPolicyRole = $wa.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullRead)
            $readPolicy.PolicyRoleBindings.Add($readPolicyRole)
            
            if ($wa.Policies.UserName -contains $params.SuperUserAlias) { 
                $wa.Policies.Remove($params.SuperUserAlias)
            }
            $policy = $wa.Policies.Add($params.SuperUserAlias, $params.SuperUserAlias)
            $policyRole = $wa.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl)
            $policy.PolicyRoleBindings.Add($policyRole)
            
            $claimsReader = (New-SPClaimsPrincipal -Identity $params.SuperReaderAlias -IdentityType WindowsSamAccountName).ToEncodedString()
            if ($wa.Policies.UserName -contains $claimsReader) { 
                $wa.Policies.Remove($claimsReader)
            }
            $policy = $wa.Policies.Add($claimsReader, $claimsReader)
            $policyRole = $wa.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullRead)
            $policy.PolicyRoleBindings.Add($policyRole)
            
            $claimsSuper = (New-SPClaimsPrincipal -Identity $params.SuperUserAlias -IdentityType WindowsSamAccountName).ToEncodedString()
            if ($wa.Policies.UserName -contains $claimsSuper) { 
                $wa.Policies.Remove($claimsSuper)
            }
            $policy = $wa.Policies.Add($claimsSuper, $claimsSuper)
            $policyRole = $wa.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl)
            $policy.PolicyRoleBindings.Add($policyRole)
        }
        
        $wa.Update()
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $WebAppUrl,
        [parameter(Mandatory = $true)]  [System.String]  $SuperUserAlias,
        [parameter(Mandatory = $true)]  [System.String]  $SuperReaderAlias,
        [parameter(Mandatory = $false)] [System.Boolean] $SetWebAppPolicy = $true,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    $PSBoundParameters.SetWebAppPolicy = $SetWebAppPolicy
    Write-Verbose -Message "Testing cache accounts for $WebAppUrl"
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("SuperUserAlias", "SuperReaderAlias", "SetWebAppPolicy")
}

Export-ModuleMember -Function *-TargetResource
