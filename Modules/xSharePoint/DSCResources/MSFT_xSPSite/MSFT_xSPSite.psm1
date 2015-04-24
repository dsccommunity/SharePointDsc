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

    Write-Verbose "Getting site collection $Url"

    $session = Get-xSharePointAuthenticatedPSSession $InstallAccount

    $result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        $site = Get-SPSite $params.Url -ErrorAction SilentlyContinue

        if ($site -eq $null) { return @{} }
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
        $CompatibilityLevel,

        [System.String]
        $ContentDatabase,

        [System.String]
        $Description,

        [System.String]
        $HostHeaderWebApplication,

        [System.UInt32]
        $Language,

        [System.String]
        $Name,

        [System.String]
        $OwnerEmail,

        [System.String]
        $QuotaTemplate,

        [System.String]
        $SecondaryEmail,

        [System.String]
        $SecondaryOwnerAlias,

        [System.String]
        $Template,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose "Creating site collection $Url"

    $session = Get-xSharePointAuthenticatedPSSession $InstallAccount

    $result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        $params.Remove("InstallAccount") | Out-Null

        $site = Get-SPSite $params.Url -ErrorAction SilentlyContinue

        if ($site -eq $null) {
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
        $CompatibilityLevel,

        [System.String]
        $ContentDatabase,

        [System.String]
        $Description,

        [System.String]
        $HostHeaderWebApplication,

        [System.UInt32]
        $Language,

        [System.String]
        $Name,

        [System.String]
        $OwnerEmail,

        [System.String]
        $QuotaTemplate,

        [System.String]
        $SecondaryEmail,

        [System.String]
        $SecondaryOwnerAlias,

        [System.String]
        $Template,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    $result = Get-TargetResource -Url $Url -OwnerAlias $OwnerAlias -InstallAccount $InstallAccount
    Write-Verbose "Testing site collection $Url"
    if ($result.Count -eq 0) { return $false }
    else {
        
    }
    return $true
}


Export-ModuleMember -Function *-TargetResource

