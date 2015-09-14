function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Url,

        [parameter(Mandatory = $true)]
        [System.String]
        $OwnerAlias,
        
        [parameter(Mandatory = $false)]
        [System.UInt32]
        $CompatibilityLevel,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $ContentDatabase,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $Description,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $HostHeaderWebApplication,
        
        [parameter(Mandatory = $false)]
        [System.UInt32]
        $Language,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $Name,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $OwnerEmail,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $QuotaTemplate,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $SecondaryEmail,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $SecondaryOwnerAlias,

        [parameter(Mandatory = $false)]
        [System.String]
        $Template,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting site collection $Url"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        $site = Invoke-xSharePointSPCmdlet -CmdletName "Get-SPSite" -Arguments @{ Identity = $params.Url } -ErrorAction SilentlyContinue

        if ($null -eq $site) { return @{} }
        else {
            return @{
                Url = $site.Url
                OwnerAlias = $site.OwnerAlias
            }
        }
    }
    $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Url,

        [parameter(Mandatory = $true)]
        [System.String]
        $OwnerAlias,
        
        [parameter(Mandatory = $false)]
        [System.UInt32]
        $CompatibilityLevel,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $ContentDatabase,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $Description,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $HostHeaderWebApplication,
        
        [parameter(Mandatory = $false)]
        [System.UInt32]
        $Language,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $Name,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $OwnerEmail,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $QuotaTemplate,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $SecondaryEmail,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $SecondaryOwnerAlias,

        [parameter(Mandatory = $false)]
        [System.String]
        $Template,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Creating site collection $Url"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        $params = Remove-xSharePointNullParamValues -Params $params
        $params.Remove("InstallAccount") | Out-Null

        $site = Invoke-xSharePointSPCmdlet -CmdletName "Get-SPSite" -Arguments @{ Identity = $params.Url } -ErrorAction SilentlyContinue

        if ($null -eq $site) {
            Invoke-xSharePointSPCmdlet -CmdletName "New-SPSite" -Arguments $params | Out-Null
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
        $Url,

        [parameter(Mandatory = $true)]
        [System.String]
        $OwnerAlias,
        
        [parameter(Mandatory = $false)]
        [System.UInt32]
        $CompatibilityLevel,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $ContentDatabase,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $Description,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $HostHeaderWebApplication,
        
        [parameter(Mandatory = $false)]
        [System.UInt32]
        $Language,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $Name,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $OwnerEmail,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $QuotaTemplate,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $SecondaryEmail,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $SecondaryOwnerAlias,

        [parameter(Mandatory = $false)]
        [System.String]
        $Template,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    $result = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing site collection $Url"
    if ($result.Count -eq 0) { return $false }
    else {
        
    }
    return $true
}


Export-ModuleMember -Function *-TargetResource

