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

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting site collection $Url"

    $session = Get-xSharePointAuthenticatedPSSession -Credential $InstallAccount

    $result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        $site = Get-SPSite $params.Url -ErrorAction SilentlyContinue

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

        [System.UInt32]
        $CompatibilityLevel = $null,

        [System.String]
        $ContentDatabase = $null,

        [System.String]
        $Description = $null,

        [System.String]
        $HostHeaderWebApplication = $null,

        [System.UInt32]
        $Language = $null,

        [System.String]
        $Name = $null,

        [System.String]
        $OwnerEmail = $null,

        [System.String]
        $QuotaTemplate = $null,

        [System.String]
        $SecondaryEmail = $null,

        [System.String]
        $SecondaryOwnerAlias = $null,

        [System.String]
        $Template = $null,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Creating site collection $Url"

    $session = Get-xSharePointAuthenticatedPSSession -Credential $InstallAccount

    $result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        $params = Remove-xSharePointNullParamValues -Params $params
        $params.Remove("InstallAccount") | Out-Null

        $site = Get-SPSite $params.Url -ErrorAction SilentlyContinue

        if ($null -eq $site) {
            New-SPSite @params | Out-Null
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

        [System.UInt32]
        $CompatibilityLevel = $null,

        [System.String]
        $ContentDatabase = $null,

        [System.String]
        $Description = $null,

        [System.String]
        $HostHeaderWebApplication = $null,

        [System.UInt32]
        $Language = $null,

        [System.String]
        $Name = $null,

        [System.String]
        $OwnerEmail = $null,

        [System.String]
        $QuotaTemplate = $null,

        [System.String]
        $SecondaryEmail = $null,

        [System.String]
        $SecondaryOwnerAlias = $null,

        [System.String]
        $Template = $null,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    $result = Get-TargetResource -Url $Url -OwnerAlias $OwnerAlias -InstallAccount $InstallAccount
    Write-Verbose -Message "Testing site collection $Url"
    if ($result.Count -eq 0) { return $false }
    else {
        
    }
    return $true
}


Export-ModuleMember -Function *-TargetResource

