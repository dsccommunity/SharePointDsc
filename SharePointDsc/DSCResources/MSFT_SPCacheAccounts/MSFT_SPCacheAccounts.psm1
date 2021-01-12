function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SuperUserAlias,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SuperReaderAlias,

        [Parameter()]
        [System.Boolean]
        $SetWebAppPolicy = $true,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting cache accounts for $WebAppUrl"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue

        if ($null -eq $wa)
        {
            return @{
                WebAppUrl        = $params.WebAppUrl
                SuperUserAlias   = $null
                SuperReaderAlias = $null
                SetWebAppPolicy  = $false
            }
        }

        $returnVal = @{
            WebAppUrl = $params.WebAppUrl
        }

        $policiesSet = $true
        if ($wa.UseClaimsAuthentication -eq $true)
        {
            if ($wa.Properties.ContainsKey("portalsuperuseraccount"))
            {
                $claim = New-SPClaimsPrincipal -Identity $wa.Properties["portalsuperuseraccount"] `
                    -IdentityType EncodedClaim `
                    -ErrorAction SilentlyContinue
                if ($null -ne $claim)
                {
                    $returnVal.Add("SuperUserAlias", $claim.Value)
                }
                else
                {
                    $returnVal.Add("SuperUserAlias", "")
                }
            }
            else
            {
                $returnVal.Add("SuperUserAlias", "")
            }
            if ($wa.Properties.ContainsKey("portalsuperreaderaccount"))
            {
                $claim = New-SPClaimsPrincipal -Identity $wa.Properties["portalsuperreaderaccount"] `
                    -IdentityType EncodedClaim `
                    -ErrorAction SilentlyContinue
                if ($null -ne $claim)
                {
                    $returnVal.Add("SuperReaderAlias", $claim.Value)
                }
                else
                {
                    $returnVal.Add("SuperReaderAlias", "")
                }
            }
            else
            {
                $returnVal.Add("SuperReaderAlias", "")
            }
            if ($wa.Policies.UserName -notcontains ((New-SPClaimsPrincipal -Identity $params.SuperReaderAlias `
                            -IdentityType WindowsSamAccountName).ToEncodedString()))
            {
                $policiesSet = $false
            }

            if ($wa.Policies.UserName -notcontains ((New-SPClaimsPrincipal -Identity $params.SuperUserAlias `
                            -IdentityType WindowsSamAccountName).ToEncodedString()))
            {
                $policiesSet = $false
            }
        }
        else
        {
            if ($wa.Properties.ContainsKey("portalsuperuseraccount"))
            {
                $returnVal.Add("SuperUserAlias", $wa.Properties["portalsuperuseraccount"])
            }
            else
            {
                $returnVal.Add("SuperUserAlias", "")
            }

            if ($wa.Properties.ContainsKey("portalsuperreaderaccount"))
            {
                $returnVal.Add("SuperReaderAlias", $wa.Properties["portalsuperreaderaccount"])
            }
            else
            {
                $returnVal.Add("SuperReaderAlias", "")
            }

            if ($wa.Policies.UserName -notcontains $params.SuperReaderAlias)
            {
                $policiesSet = $false
            }

            if ($wa.Policies.UserName -notcontains $params.SuperUserAlias)
            {
                $policiesSet = $false
            }
        }
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
        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SuperUserAlias,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SuperReaderAlias,

        [Parameter()]
        [System.Boolean]
        $SetWebAppPolicy = $true,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount    )

    Write-Verbose -Message "Setting cache accounts for $WebAppUrl"

    $PSBoundParameters.SetWebAppPolicy = $SetWebAppPolicy

    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue
        if ($null -eq $wa)
        {
            $message = "The web applications $($params.WebAppUrl) can not be found to set cache accounts"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }

        if ($wa.UseClaimsAuthentication -eq $true)
        {
            $wa.Properties["portalsuperuseraccount"] = (New-SPClaimsPrincipal -Identity $params.SuperUserAlias `
                    -IdentityType WindowsSamAccountName).ToEncodedString()
            $wa.Properties["portalsuperreaderaccount"] = (New-SPClaimsPrincipal -Identity $params.SuperReaderAlias `
                    -IdentityType WindowsSamAccountName).ToEncodedString()
        }
        else
        {
            $wa.Properties["portalsuperuseraccount"] = $params.SuperUserAlias
            $wa.Properties["portalsuperreaderaccount"] = $params.SuperReaderAlias
        }

        if ($params.SetWebAppPolicy -eq $true)
        {
            if ($wa.UseClaimsAuthentication -eq $true)
            {
                $claimsReader = (New-SPClaimsPrincipal -Identity $params.SuperReaderAlias `
                        -IdentityType WindowsSamAccountName).ToEncodedString()
                if ($wa.Policies.UserName -contains $claimsReader)
                {
                    $wa.Policies.Remove($claimsReader)
                }
                $policy = $wa.Policies.Add($claimsReader, "Super Reader (Claims)")
                $policyRole = $wa.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullRead)
                $policy.PolicyRoleBindings.Add($policyRole)

                $claimsSuper = (New-SPClaimsPrincipal -Identity $params.SuperUserAlias `
                        -IdentityType WindowsSamAccountName).ToEncodedString()
                if ($wa.Policies.UserName -contains $claimsSuper)
                {
                    $wa.Policies.Remove($claimsSuper)
                }
                $policy = $wa.Policies.Add($claimsSuper, "Super User (Claims)")
                $policyRole = $wa.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl)
                $policy.PolicyRoleBindings.Add($policyRole)
            }
            else
            {
                if ($wa.Policies.UserName -contains $params.SuperReaderAlias)
                {
                    $wa.Policies.Remove($params.SuperReaderAlias)
                }

                $readPolicy = $wa.Policies.Add($params.SuperReaderAlias, "Super Reader")
                $readPolicyRole = $wa.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullRead)
                $readPolicy.PolicyRoleBindings.Add($readPolicyRole)

                if ($wa.Policies.UserName -contains $params.SuperUserAlias)
                {
                    $wa.Policies.Remove($params.SuperUserAlias)
                }
                $policy = $wa.Policies.Add($params.SuperUserAlias, "Super User")
                $policyRole = $wa.PolicyRoles.GetSpecialRole([Microsoft.SharePoint.Administration.SPPolicyRoleType]::FullControl)
                $policy.PolicyRoleBindings.Add($policyRole)
            }
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
        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SuperUserAlias,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SuperReaderAlias,

        [Parameter()]
        [System.Boolean]
        $SetWebAppPolicy = $true,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount    )

    Write-Verbose -Message "Testing cache accounts for $WebAppUrl"

    $PSBoundParameters.SetWebAppPolicy = $SetWebAppPolicy

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($SetWebAppPolicy -eq $true)
    {
        $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("SuperUserAlias", `
                "SuperReaderAlias", `
                "SetWebAppPolicy")
    }
    else
    {
        $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("SuperUserAlias", `
                "SuperReaderAlias")
    }

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

<## This function retrieves information about all the "Super" accounts (Super Reader & Super User) used for caching. #>
function Export-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [System.String]
        $ModulePath,

        [Parameter()]
        [System.Collections.Hashtable]
        $Params
    )

    $VerbosePreference = "SilentlyContinue"
    if ([System.String]::IsNullOrEmpty($modulePath) -eq $false)
    {
        $module = Resolve-Path -Path $modulePath
    }
    else
    {
        $ParentModuleBase = Get-Module "SharePointDSC" | Select-Object -ExpandProperty Modulebase
        $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPCacheAccounts\MSFT_SPCacheAccounts.psm1" -Resolve
        $Content = ''
    }

    if ($null -eq $params)
    {
        $params = Get-DSCFakeParameters -ModulePath $module
    }

    $webApps = Get-SPWebApplication

    $i = 1
    $total = $webApps.Length
    foreach ($webApp in $webApps)
    {
        $webAppUrl = $webApp.Url
        Write-Host "Scanning Cache Account [$i/$total] {$webAppUrl}"

        $params.WebAppUrl = $webAppUrl
        $results = Get-TargetResource @params

        if ($results.SuperReaderAlias -ne "" -and $results.SuperUserAlias -ne "")
        {
            $PartialContent = "        SPCacheAccounts " + $webApp.DisplayName.Replace(" ", "") + "CacheAccounts`r`n"
            $PartialContent += "        {`r`n"
            $results = Repair-Credentials -results $results
            $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
            $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
            $PartialContent += $currentBlock
            $PartialContent += "        }`r`n"
            $Content += $PartialContent
        }
        $i++
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
