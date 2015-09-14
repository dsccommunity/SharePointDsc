function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $true)]  [System.String] $Url,
        [parameter(Mandatory = $true)]  [ValidateSet("Farm","WebApplication","Site","Web")] [System.String] $FeatureScope,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")] [System.String] $Ensure
    )

    Write-Verbose -Message "Getting feature $Name at $FeatureScope scope"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $feature = Invoke-xSharePointSPCmdlet -CmdletName "Get-SPFeature" -Arguments @{ Identity = $params.Name } -ErrorAction SilentlyContinue

        if ($null -eq $feature) { return @{
            Name = $params.Name
            FeatureScope = $params.FeatureScope
            Url = $params.Url
            InstalAcount = $params.InstallAccount
            Ensure = "Absent"
        } }

        $checkParams = @{}
        $checkParams.Add("Identity", $params.Name)
        if ($FeatureScope -eq "Farm") {
            $checkParams.Add($params.FeatureScope, $true)
        } else {
            $checkParams.Add($params.FeatureScope, $params.Url)
        }
        $featureAtScope = Invoke-xSharePointSPCmdlet -CmdletName "Get-SPFeature" -Arguments $checkParams -ErrorAction SilentlyContinue
        $enabled = ($null -ne $featureAtScope)
        if ($enabled) { $currentState = "Present" } else { $currentState = "Absent" }

        return @{
            Name = $params.Name
            FeatureScope = $params.FeatureScope
            Url = $params.Url
            InstalAcount = $params.InstallAccount
            Ensure = $currentState
        }
    }
    return $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $true)]  [System.String] $Url,
        [parameter(Mandatory = $true)]  [ValidateSet("Farm","WebApplication","Site","Web")] [System.String] $FeatureScope,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")] [System.String] $Ensure
    )

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $runParams = @{}
        $runParams.Add("Identity", $params.Name)
        if ($params.FeatureScope -ne "Farm") {
            $runParams.Add("Url", $params.Url)
        }

        if ($params.Ensure -eq "Present") {
            Invoke-xSharePointSPCmdlet -CmdletName "Enable-SPFeature" -Arguments $runParams
        } else {
            $runParams.Add("Confirm", $false)    
            Invoke-xSharePointSPCmdlet -CmdletName "Disable-SPFeature" -Arguments $runParams
        }
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $true)]  [System.String] $Url,
        [parameter(Mandatory = $true)]  [ValidateSet("Farm","WebApplication","Site","Web")] [System.String] $FeatureScope,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")] [System.String] $Ensure
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing for feature $Name at $FeatureScope scope"
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("Ensure")
}
Export-ModuleMember -Function *-TargetResource
