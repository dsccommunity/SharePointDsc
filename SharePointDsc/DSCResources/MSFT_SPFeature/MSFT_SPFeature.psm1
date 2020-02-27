$script:resourceModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:resourceModulePath -ChildPath 'Modules'
$script:resourceHelperModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'SharePointDsc.Util'
Import-Module -Name (Join-Path -Path $script:resourceHelperModulePath -ChildPath 'SharePointDsc.Util.psm1')

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Url,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Farm", "WebApplication", "Site", "Web")]
        [System.String]
        $FeatureScope,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.String]
        $Version
    )

    Write-Verbose -Message "Getting feature $Name at $FeatureScope scope"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $checkParams = @{
            Identity = $params.Name
        }
        if ($params.FeatureScope -eq "Farm")
        {
            $checkParams.Add($params.FeatureScope, $true)
        }
        else
        {
            $checkParams.Add($params.FeatureScope, $params.Url)
        }
        $featureAtScope = Get-SPFeature @checkParams -ErrorAction SilentlyContinue
        $enabled = ($null -ne $featureAtScope)
        if ($enabled -eq $true)
        {
            $currentState = "Present"
        }
        else
        {
            $currentState = "Absent"
        }

        return @{
            Name           = $params.Name
            FeatureScope   = $params.FeatureScope
            Url            = $params.Url
            Version        = $featureAtScope.Version
            Ensure         = $currentState
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
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Url,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Farm", "WebApplication", "Site", "Web")]
        [System.String]
        $FeatureScope,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.String]
        $Version
    )

    Write-Verbose -Message "Setting feature $Name at $FeatureScope scope"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    $PSBoundParameters.Add("CurrentValues", $CurrentValues)
    $PSBoundParameters.Ensure = $Ensure

    if ($Ensure -eq "Present")
    {
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]
            $currentValues = $params["CurrentValues"]

            $runParams = @{
                Identity = $params.Name
            }

            if ($params.FeatureScope -ne "Farm")
            {
                $runParams.Add("Url", $params.Url)
            }

            if ($currentValues.Ensure -eq "Present")
            {
                # Disable the feature first if it already exists.
                $runParams.Add("Confirm", $false)
                Write-Verbose -Message ("Disable Feature '$($params.Name)' because it is " + `
                        "already active at scope '$($params.FeatureScope)'...")
                Disable-SPFeature @runParams
            }

            Write-Verbose -Message ("Enable Feature '$($params.Name)' at scope " + `
                    "'$($params.FeatureScope)'...")
            Enable-SPFeature @runParams
        }
    }
    if ($Ensure -eq "Absent")
    {
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {

            $params = $args[0]
            $currentValues = $params["CurrentValues"]

            $runParams = @{
                Identity = $params.Name
            }

            if ($params.FeatureScope -ne "Farm")
            {
                $runParams.Add("Url", $params.Url)
            }

            $runParams.Add("Confirm", $false)
            Write-Verbose -Message ("Disable Feature '$($params.Name)' because 'Ensure' is " + `
                    "'$($params.Ensure)'...")
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
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Url,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Farm", "WebApplication", "Site", "Web")]
        [System.String]
        $FeatureScope,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.String]
        $Version
    )

    Write-Verbose -Message "Testing feature $Name at $FeatureScope scope"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("Ensure", "Version")

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

Export-ModuleMember -Function *-TargetResource
