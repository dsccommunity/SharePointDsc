function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [ValidateSet("Farm","WebApplication","Site","Web")]
        [System.String]
        $FeatureScope,

        [parameter(Mandatory = $true)]
        [System.String]
        $Url,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )

    Write-Verbose -Message "Getting feature $Name at $FeatureScope scope"

    $session = Get-xSharePointAuthenticatedPSSession -Credential $InstallAccount

    $result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        $feature = Get-SPFeature $params.Name -ErrorAction SilentlyContinue

        if ($null -eq $feature) { return @{} }

        $checkParams = @{}
        $checkParams.Add("Identity", $params.Name)
        if ($FeatureScope -eq "Farm") {
            $checkParams.Add($params.FeatureScope, $true)
        } else {
            $checkParams.Add($params.FeatureScope, $params.Url)
        }
        $checkParams.Add("ErrorAction", "SilentlyContinue")
        $featureAtScope = Get-SPFeature @checkParams
        $enabled = ($null -ne $featureAtScope)

        return @{
            Name = $params.Name
            Id = $feature.Id
            Version = $feature.Version
            Enabled = $enabled
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
        $Name,

        [parameter(Mandatory = $true)]
        [ValidateSet("Farm","WebApplication","Site","Web")]
        [System.String]
        $FeatureScope,

        [parameter(Mandatory = $true)]
        [System.String]
        $Url,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )

    $session = Get-xSharePointAuthenticatedPSSession -Credential $InstallAccount

    $result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $runParams = @{}
        $runParams.Add("Identity", $params.Name)
        if ($params.FeatureScope -ne "Farm") {
            $runParams.Add("Url", $params.Url)
        }

        if ($params.Ensure -eq "Present") {
            Enable-SPFeature @runParams
        } else {
            $runParams.Add("Confirm", $false)    
            Disable-SPFeature @runParams
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
        $Name,

        [parameter(Mandatory = $true)]
        [ValidateSet("Farm","WebApplication","Site","Web")]
        [System.String]
        $FeatureScope,

        [parameter(Mandatory = $true)]
        [System.String]
        $Url,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )

    $result = Get-TargetResource -Name $Name -FeatureScope $FeatureScope -Url $Url -InstallAccount $InstallAccount -Ensure $Ensure
    Write-Verbose -Message "Testing for feature $Name at $FeatureScope scope"

    if ($result.Count -eq 0) { 
        throw "Unable to locate feature '$Name' in the current SharePoint farm, check that the name is correct and that the feature has been deployed to the file system."
    } else {
        if ($Ensure -eq "Present" -and $result.Enabled -eq $false) { return $false }
        if ($Ensure -eq "Absent" -and $result.Enabled -eq $true) { return $false }
    }
    return $true
}
Export-ModuleMember -Function *-TargetResource
