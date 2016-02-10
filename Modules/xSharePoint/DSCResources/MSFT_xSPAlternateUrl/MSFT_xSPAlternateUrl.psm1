function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $WebAppUrl,
        [parameter(Mandatory = $true)]  [ValidateSet("Default","Intranet","Extranet","Custom","Internet")] [System.String] $Zone,
        [parameter(Mandatory = $true)]  [System.String] $Url,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount

    )

    Write-Verbose -Message "Getting Alternate URL for $Zone in $WebAppUrl"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $aam = Get-SPAlternateURL -WebApplication $params.WebAppUrl -Zone $params.Zone | Select -First 1
        $url = $null
        if ($aam -ne $null) {
            $url = $aam.PublicUrl
        }
        
        return @{
            WebAppUrl = $params.WebAppUrl
            Zone = $params.Zone
            Url = $url
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
        [parameter(Mandatory = $true)]  [System.String] $WebAppUrl,
        [parameter(Mandatory = $true)]  [ValidateSet("Default","Intranet","Extranet","Custom","Internet")] [System.String] $Zone,
        [parameter(Mandatory = $true)]  [System.String] $Url,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount

    )

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Updating app domain settings for $SiteUrl"
    
    Invoke-xSharePointCommand -Credential $InstallAccount -Arguments ($PSBoundParameters, $CurrentValues) -ScriptBlock {
        $params = $args[0]
        $CurrentValues = $args[1]

        if ([string]::IsNullOrEmpty($CurrentValues.Url)) {
            New-SPAlternateURL -WebApplication $params.WebAppUrl -Url $params.Url -Zone $params.Zone
        } else {
            Set-SPAlternateURL -Identity $params.WebAppUrl -Url $params.Url -Zone $params.Zone
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
        [parameter(Mandatory = $true)]  [ValidateSet("Default","Intranet","Extranet","Custom","Internet")] [System.String] $Zone,
        [parameter(Mandatory = $true)]  [System.String] $Url,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount

    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing alternate URL configuration"
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("Url") 
}

