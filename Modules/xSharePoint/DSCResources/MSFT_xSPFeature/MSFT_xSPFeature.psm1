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
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")] [System.String] $Ensure,
        [parameter(Mandatory = $false)] [System.String] $Version
    )

    Write-Verbose -Message "Getting feature $Name at $FeatureScope scope"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $checkParams = @{ Identity = $params.Name }
        if ($params.FeatureScope -eq "Farm") {
            $checkParams.Add($params.FeatureScope, $true)
        } else {
            $checkParams.Add($params.FeatureScope, $params.Url)
        }
        $featureAtScope = Get-SPFeature @checkParams -ErrorAction SilentlyContinue
        $enabled = ($null -ne $featureAtScope)
        if ($enabled -eq $true) { $currentState = "Present" } else { $currentState = "Absent" }

        return @{
            Name = $params.Name
            FeatureScope = $params.FeatureScope
            Url = $params.Url
            InstalAcount = $params.InstallAccount
            Ensure = $currentState
            Version = $featureAtScope.Version
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
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")] [System.String] $Ensure,
        [parameter(Mandatory = $false)] [System.String] $Version
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters

    $PSBoundParameters.Add("CurrentValues", $CurrentValues)

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        
        $params = $args[0]
        $currentValues = $params["CurrentValues"]

        $runParams = @{ Identity = $params.Name }

        if ($params.FeatureScope -ne "Farm") {
            $runParams.Add("Url", $params.Url)
        }
        
        if ($params.Ensure -eq "Present") {
            if ($currentValues.Ensure -eq "Present"){
                    
                # Disable the feature first if it already exists.
                $runParams.Add("Confirm", $false)    
                Write-Verbose "Disable Feature '$($params.Name)' because it is already active at scope '$($params.FeatureScope)'..."
                Disable-SPFeature @runParams
            }

            Write-Verbose "Enable Feature '$($params.Name)' at scope '$($params.FeatureScope)'..."
            Enable-SPFeature @runParams

        } else {

            $runParams.Add("Confirm", $false)   
            Write-Verbose "Disable Feature '$($params.Name)' because 'Ensure' is '$($params.Ensure)'..." 
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
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $true)]  [System.String] $Url,
        [parameter(Mandatory = $true)]  [ValidateSet("Farm","WebApplication","Site","Web")] [System.String] $FeatureScope,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")] [System.String] $Ensure,
        [parameter(Mandatory = $false)] [System.String] $Version
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing for feature $Name at $FeatureScope scope"

    $valuesToCheck = @("Ensure", "Version")

    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck $valuesToCheck
}

Export-ModuleMember -Function *-TargetResource
