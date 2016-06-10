function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $WebAppUrl,
        [parameter(Mandatory = $true)]  [ValidateSet("Default","Intranet","Extranet","Custom","Internet")] [System.String] $Zone,
        [parameter(Mandatory = $false)] [System.String] $Url,
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] [System.String] $Ensure = "Present",
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount

    )

    Write-Verbose -Message "Getting Alternate URL for $Zone in $WebAppUrl"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $aam = Get-SPAlternateURL -WebApplication $params.WebAppUrl -Zone $params.Zone -ErrorAction SilentlyContinue | Select -First 1
        $url = $null
        $Ensure = "Absent"
        
        if (($aam -eq $null) -and ($params.Zone -eq "Default")) {
            # The default zone URL will change the URL of the web app, so assuming it has been applied
            # correctly then the first call there will fail as the WebAppUrl parameter will no longer
            # be the URL of the web app. So the assumption is that if a matching default entry with
            # the new public URL is found then it can be returned and will pass a test.
            $aam = Get-SPAlternateURL -Zone $params.Zone | Where-Object { $_.PublicUrl -eq $params.Url } | Select -First 1
        }
        
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
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] [System.String] $Ensure = "Present",
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount

    )

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Updating app domain settings for $SiteUrl"
    
    if ($Ensure -eq "Present") {
        if ([string]::IsNullOrEmpty($Url)) {
            throw "URL must be specified when ensure is set to present"
        }

        Invoke-SPDSCCommand -Credential $InstallAccount -Arguments ($PSBoundParameters, $CurrentValues) -ScriptBlock {
            $params = $args[0]
            $CurrentValues = $args[1]

            if ([string]::IsNullOrEmpty($CurrentValues.Url)) {
                New-SPAlternateURL -WebApplication $params.WebAppUrl -Url $params.Url -Zone $params.Zone
            } else {
                Get-SPAlternateURL -WebApplication $params.WebAppUrl -Zone $params.Zone | Set-SPAlternateURL -Url $params.Url
            }
        }
    } else {
        Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
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
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] [System.String] $Ensure = "Present",
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount

    )

    $PSBoundParameters.Ensure = $Ensure
    
    if ([string]::IsNullOrEmpty($Url) -and $Ensure -eq "Present") {
        throw "URL must be specified when ensure is set to present"
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing alternate URL configuration"
    return Test-SPDSCSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("Url", "Ensure") 
}

