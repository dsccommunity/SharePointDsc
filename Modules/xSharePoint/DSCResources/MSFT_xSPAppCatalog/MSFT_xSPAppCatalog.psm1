function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)] [System.String] $AppCatalogUrl ,
        [parameter(Mandatory = $true)]  [System.String] $WebApp, 
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount

    )

    Write-Verbose -Message "Checking app urls settings"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
         $wa = Get-SPWebApplication $param.WebApp
        $feature = $wa.Features | ?{ $_.ID -eq [Guid]::Parse("f8bea737-255e-4758-ab82-e34bb46f5828")}
        if($feature -eq $null ){
            throw "not an app catalog"
        }
        $feature 
        $site = Get-SPSite $feature.Properties["__AppCatSiteId"].Value
 
        return @{
            AppCatalogUrl = $site.Url #this needs to be update so it reads correct info
            WebApp= $params.WebApp
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
        [parameter(Mandatory = $true)] [System.String] $AppCatalogUrl ,
        [parameter(Mandatory = $true)]  [System.String] $WebApp 
    )

  

    Write-Verbose -Message "Updating app domain settings "
    Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        if($AppCatalogUrl.Substring(0,1) -ine "/")
        {
            $AppCatalogUrl= "/" + $AppCatalogUrl
        }
        Update-SPAppCatalogConfiguration -site $WebApp + $AppCatalogUrl -Confirm:$false


    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $true)] [System.String] $AppCatalogUrl ,
        [parameter(Mandatory = $true)]  [System.String] $WebApp 
    )


    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing app domain settings"
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("AppCatalogUrl", "WebApp") 
}


Export-ModuleMember -Function *-TargetResource

