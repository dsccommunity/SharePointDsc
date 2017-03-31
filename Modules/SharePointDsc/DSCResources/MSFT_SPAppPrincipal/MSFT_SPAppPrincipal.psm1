function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $DisplayName,

        [parameter(Mandatory = $true)]
        [System.String]
        $AppId,

        [parameter(Mandatory = $true)]
        [System.String]
        $Site,

        [parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet("Web","Site","Subscription")]
        $Scope,

        [parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet("Read","Write","Manage","Full Control")]
        $Right,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [System.Management.Automation.PSCredential]
        $InstallAccount
    )
    Write-Verbose -Message "Getting App Principal '$DisplayName'"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]

        Write-Verbose -Message "Getting Site '$($params.Site)'"
        $site = Get-SPSite -Identity $params.Site -ErrorAction SilentlyContinue

        if($null -eq $site)
        {
            throw "The specified site: $($params.Site) was not found"
        }
        $web = $site.OpenWeb()
        Write-Verbose -Message "Getting Authentication Realm"
        $realm = Get-SPAuthenticationRealm -ServiceContext $site;
        $nameIdentifier = "$($params.AppId)@$($realm)"
        $appPrincipal = Get-SPAppPrincipal -NameIdentifier $nameIdentifier -Site $web  -ErrorAction SilentlyContinue

        if($null -eq $appPrincipal)
        {
            $nullReturn = @{
                DisplayName = ""
                AppId = $params.AppId
                Site = $params.Site
                Ensure = "Absent"
            }
            return $nullReturn
        }
        else 
        {
            $ret = @{
                DisplayName = $appPrincipal.DisplayName
                AppId = $params.AppId
                Site = $params.Site
                Ensure = "Present"
            }
            return $ret;
        }
    }

    return $result
    
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $DisplayName,

        [parameter(Mandatory = $true)]
        [System.String]
        $AppId,

        [parameter(Mandatory = $true)]
        [System.String]
        $Site,
        
        [parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet("Web","Site","Subscription")]
        $Scope,

        [parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet("Read","Write","Manage","Full Control")]
        $Right,
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting App Principal '$DisplayName'"

    $result = Get-TargetResource @PSBoundParameters

    if ($result.Ensure -eq "Absent" -and $Ensure -eq "Present") 
    {
        Write-Verbose -Message "Creating App Principal $DisplayName"
        Invoke-SPDSCCommand -Credential $InstallAccount `
                            -Arguments $PSBoundParameters `
                            -ScriptBlock {
                                 
            $params = $args[0]
            $site = Get-SPSite -Identity $params.Site -ErrorAction SilentlyContinue
            $web = $site.OpenWeb()
            $realm = Get-SPAuthenticationRealm -ServiceContext $site;
            $nameIdentifier = "$($params.AppId)@$($realm)"
            
            Register-SPAppPrincipal -DisplayName "$params.DisplayName" `
                                    -NameIdentifier "$nameIdentifier" `
                                    -Site $web

        }
    }
    if ($Ensure -eq "Absent") 
    {
        Write-Verbose -Message "Removing App Principal $DisplayName"
        Invoke-SPDSCCommand -Credential $InstallAccount `
                            -Arguments $PSBoundParameters `
                            -ScriptBlock {

            $params = $args[0]
            $site = Get-SPSite -Identity $params.Site -ErrorAction SilentlyContinue
            $web = $site.OpenWeb()
            $manager = [Microsoft.SharePoint.SPAppPrincipalManager]::GetManager($web);
            $provider = [Microsoft.SharePoint.SPAppPrincipalIdentityProvider]::External
            $principalId = [Microsoft.SharePoint.SPAppPrincipalName]::CreateFromAppPrincipalIdentifier($params.AppId)
            $principal = $manager.LookupAppPrincipal($provider, $principalId)
            
            if($null -ne $principal)
            {
                $manager.DeleteAppPrincipal($principal)  
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
        [parameter(Mandatory = $true)]
        [System.String]
        $DisplayName,

        [parameter(Mandatory = $true)]
        [System.String]
        $AppId,

        [parameter(Mandatory = $true)]
        [System.String]
        $Site,
        
        [parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet("Web","Site","Subscription")]
        $Scope,

        [parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet("Read","Write","Manage","Full Control")]
        $Right,
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing App Principal '$DisplayName'"
    
    $PSBoundParameters.Ensure = $Ensure
    $CurrentValues = Get-TargetResource @PSBoundParameters
    
    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @("Ensure")
    
}

Export-ModuleMember -Function *-TargetResource
