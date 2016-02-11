function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $WebAppUrl,
        [parameter(Mandatory = $true)]  [ValidateSet("Default","Intranet","Extranet","Custom","Internet")] [System.String] $Zone,
        [parameter(Mandatory = $false)] [System.String] $Url,
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")] [System.String] $Ensure,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount

    )

    Write-Verbose -Message "Getting Alternate URL for $Zone in $WebAppUrl"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $aam = Get-SPAlternateURL -WebApplication $params.WebAppUrl -Zone $params.Zone | Select -First 1
        $url = $null
        $Ensure = "Absent"
        if ($aam -ne $null) {
            $url = $aam.PublicUrl
            $Ensure = "Present"
        }
        
        return @{
            WebAppUrl = $params.WebAppUrl
            Zone = $params.Zone
            Url = $url
            Ensure = $Ensure
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
        [parameter(Mandatory = $false)] [System.String] $Url,
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")] [System.String] $Ensure,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount

    )

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Updating app domain settings for $SiteUrl"
    
    if ($Ensure -eq "Present") {
        if ([string]::IsNullOrEmpty($Url)) {
            throw "URL must be specified when ensure is set to present"
        }

        Invoke-xSharePointCommand -Credential $InstallAccount -Arguments ($PSBoundParameters, $CurrentValues) -ScriptBlock {
            $params = $args[0]
            $CurrentValues = $args[1]

            if ([string]::IsNullOrEmpty($CurrentValues.Url)) {
                New-SPAlternateURL -WebApplication $params.WebAppUrl -Url $params.Url -Zone $params.Zone
            } else {
                Get-SPAlternateURL -WebApplication $params.WebAppUrl -Zone $params.Zone | Set-SPAlternateURL -Url $params.Url
            }
        }
    } else {
        Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            Get-SPAlternateURL -WebApplication $params.WebAppUrl -Zone $params.Zone | Remove-SPAlternateURL -Confirm:$false
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
        [parameter(Mandatory = $false)] [System.String] $Url,
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")] [System.String] $Ensure,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount

    )

    if ([string]::IsNullOrEmpty($Url) -and $Ensure -eq "Present") {
        throw "URL must be specified when ensure is set to present"
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing alternate URL configuration"
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("Url", "Ensure") 
}

