function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $SiteUrl,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount

    )

    Write-Verbose -Message "Getting app catalog status of $SiteUrl"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $site = Get-SPSite $params.SiteUrl -ErrorAction SilentlyContinue
        if ($null -eq $site) {
            return $null
        }
        $wa = $site.WebApplication
        $feature = $wa.Features.Item([Guid]::Parse("f8bea737-255e-4758-ab82-e34bb46f5828"))
        if($feature -eq $null){
            return $null
        }
        if ($site.ID -ne $feature.Properties["__AppCatSiteId"].Value) {
            return $null
        } 
        return @{
            SiteUrl = $site.Url
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
        [parameter(Mandatory = $true)]  [System.String] $SiteUrl,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Updating app domain settings for $SiteUrl"
    Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        Update-SPAppCatalogConfiguration -Site $params.SiteUrl -Confirm:$false 
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $SiteUrl,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing app domain settings"
    if($CurrentValues -eq $null){
        return $false
    }
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("SiteUrl") 
}

Export-ModuleMember -Function *-TargetResource
