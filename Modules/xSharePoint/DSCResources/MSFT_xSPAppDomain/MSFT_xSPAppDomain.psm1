function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $false)] [System.String] $AppDomain,
        [parameter(Mandatory = $true)]  [System.String] $Prefix,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount

    )

    Write-Verbose -Message "Checking app urls settings"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        $appDomain =  Get-SPAppDomain
        $prefix = "";
        if($params.ContainsKey("Prefix")){
            $prefix = Get-SPAppSiteSubscriptionName
        }

        return @{
            AppDomain = $appDomain
            Prefix= $prefix
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
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $true)] [System.String] $AppDomain,
        [parameter(Mandatory = $false)]  [System.String] $Prefix

    )

  

    Write-Verbose -Message "Updating app domain settings "
    Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
        Set-SPAppDomain $params.AppDomain
        if($params.ContainsKey("Prefix")){
            Set-SPAppSiteSubscriptionName -Name $params.Prefix -Confirm:$false
        }
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $true)] [System.String] $AppDomain,
        [parameter(Mandatory = $false)]  [System.String] $Prefix
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing app domain settings"
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("AppDomain", "Prefix") 
}


Export-ModuleMember -Function *-TargetResource

