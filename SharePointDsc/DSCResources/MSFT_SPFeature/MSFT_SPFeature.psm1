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
            Name         = $params.Name
            FeatureScope = $params.FeatureScope
            Url          = $params.Url
            Version      = $featureAtScope.Version
            Ensure       = $currentState
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
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("Ensure", "Version")

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [System.String]
        $Scope,

        [Parameter()]
        [System.String]
        $URL,

        [Parameter()]
        [System.String]
        $DependsOn
    )
    if (!(Get-PSSnapin Microsoft.SharePoint.Powershell -ErrorAction SilentlyContinue))
    {
        Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction 0
    }
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDSC" | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath "\DSCResources\MSFT_SPFeature\MSFT_SPFeature.psm1" -Resolve
    Import-Module $module -Scope Local
    $params = Get-DSCFakeParameters -ModulePath $module

    $spMajorVersion = (Get-SPDscInstalledProductVersion).FileMajorPart
    $versionFilter = $spMajorVersion.ToString() + "*"
    $Features = Get-SPFeature | Where-Object { $_.Scope -eq $Scope -and $_.Version -like $versionFilter }

    $j = 1
    $totalFeat = $Features.Length
    $Content = ""
    foreach ($Feature in $Features)
    {
        try
        {
            $displayName = $Feature.DisplayName
            Write-Host "    -> Scanning Feature [$j/$totalFeat] {$displayName}"
            $params.Name = $displayName
            $params.FeatureScope = $Scope
            if ($URL)
            {
                $params.Url = $Url
            }
            $results = Get-TargetResource @params

            if ($results.Get_Item("Ensure").ToLower() -eq "present")
            {
                $partialContent = "        SPFeature " + [System.Guid]::NewGuid().ToString() + "`r`n"
                $partialContent += "        {`r`n"

                <# Manually add the InstallAccount param due to a bug in 1.6.0.0 that returns a param named InstalAccount (typo) instead.
                https://github.com/PowerShell/SharePointDsc/issues/481 #>
                if ($results.ContainsKey("InstalAccount"))
                {
                    $results.Remove("InstalAccount")
                }
                $results = Repair-Credentials -results $results
                if ($DependsOn)
                {
                    $results.add("DependsOn", $DependsOn)
                }
                $currentDSCBlock = Get-DSCBlock -Params $results -ModulePath $module
                $currentDSCBlock = Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock -ParameterName "PsDscRunAsCredential"
                $partialContent += $currentDSCBlock
                $partialContent += "        }`r`n"
            }
            $Content += $partialContent
            $j++
        }
        catch
        {
            $_
            $Global:ErrorLog += "[Web Application Feature]" + $Feature.DisplayName + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
