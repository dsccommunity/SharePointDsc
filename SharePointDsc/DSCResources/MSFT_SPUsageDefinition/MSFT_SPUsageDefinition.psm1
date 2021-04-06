$script:SPDscUtilModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SharePointDsc.Util'
Import-Module -Name $script:SPDscUtilModulePath

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateRange(1, 31)]
        [System.UInt32]
        $DaysRetained,

        [Parameter()]
        [System.UInt32]
        $DaysToKeepUsageFiles,

        [Parameter()]
        [System.UInt64]
        $MaxTotalSizeInBytes,

        [Parameter()]
        [System.Boolean]
        $Enabled,

        [Parameter()]
        [System.Boolean]
        $UsageDatabaseEnabled,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting configuration for Usage Definition {$Name}"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $usageDefinition = Get-SPUsageDefinition | Where-Object { $_.Name -eq $params.Name }
        $nullReturn = @{
            Name                 = $params.Name
            DaysRetained         = $params.DaysRetained
            DaysToKeepUsageFiles = $params.DaysToKeepUsageFiles
            MaxTotalSizeInBytes  = $params.MaxTotalSizeInBytes
            Enabled              = $params.Enabled
            UsageDatabaseEnabled = $params.UsageDatabaseEnabled
            Ensure               = "Absent"
        }
        if ($null -eq $usageDefinition)
        {
            return $nullReturn
        }

        return @{
            Name                 = $params.Name
            DaysRetained         = $usageDefinition.Retention
            DaysToKeepUsageFiles = $usageDefinition.DaysToKeepUsageFiles
            MaxTotalSizeInBytes  = $usageDefinition.MaxTotalSizeInBytes
            Enabled              = $usageDefinition.Enabled
            UsageDatabaseEnabled = $usageDefinition.UsageDatabaseEnabled
            Ensure               = "Present"
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

        [Parameter()]
        [ValidateRange(1, 31)]
        [System.UInt32]
        $DaysRetained,

        [Parameter()]
        [System.UInt32]
        $DaysToKeepUsageFiles,

        [Parameter()]
        [System.UInt64]
        $MaxTotalSizeInBytes,

        [Parameter()]
        [System.Boolean]
        $Enabled,

        [Parameter()]
        [System.Boolean]
        $UsageDatabaseEnabled,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting configuration for Usage Definition {$Name}"

    if ($Ensure -eq "Absent")
    {
        $message = "This resource cannot remove a Usage Definition. Please use ensure equals Present."
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if ($PSBoundParameters.ContainsKey("DaysRetained") -eq $false -and `
            $PSBoundParameters.ContainsKey("DaysToKeepUsageFiles") -eq $false -and `
            $PSBoundParameters.ContainsKey("MaxTotalSizeInBytes") -eq $false -and `
            $PSBoundParameters.ContainsKey("Enabled") -eq $false -and `
            $PSBoundParameters.ContainsKey("UsageDatabaseEnabled") -eq $false)
    {
        $message = ("You have to at least specify one parameter: DaysRetained, DaysToKeepUsageFiles, " + `
                "MaxTotalSizeInBytes, Enabled or UsageDatabaseEnabled.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if ((Get-SPDscInstalledProductVersion).FileMajorPart -eq 15 -and `
            $PSBoundParameters.ContainsKey("UsageDatabaseEnabled") -eq $true)
    {
        $message = ("Parameter UsageDatabaseEnabled not supported in SharePoint 2013. Please " + `
                "remove it from the configuration.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]

        $usageDefinition = Get-SPUsageDefinition | Where-Object { $_.Name -eq $params.Name }

        if ($null -eq $usageDefinition)
        {
            $message = "The specified Usage Definition {" + $params.Name + "} could not be found."
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }

        $newParams = @{
            Identity = $params.Name
        }

        if ($params.ContainsKey("DaysRetained"))
        {
            $newParams.DaysRetained = $params.DaysRetained
        }

        if ($params.ContainsKey("DaysToKeepUsageFiles"))
        {
            $newParams.DaysToKeepUsageFiles = $params.DaysToKeepUsageFiles
        }

        if ($params.ContainsKey("MaxTotalSizeInBytes"))
        {
            $newParams.MaxTotalSizeInBytes = $params.MaxTotalSizeInBytes
        }

        if ($params.ContainsKey("Enabled"))
        {
            $newParams.Enable = $params.Enabled
        }

        if ($params.ContainsKey("UsageDatabaseEnabled"))
        {
            $newParams.UsageDatabaseEnabled = $params.UsageDatabaseEnabled
        }

        Set-SPUsageDefinition @newParams
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

        [Parameter()]
        [ValidateRange(1, 31)]
        [System.UInt32]
        $DaysRetained,

        [Parameter()]
        [System.UInt32]
        $DaysToKeepUsageFiles,

        [Parameter()]
        [System.UInt64]
        $MaxTotalSizeInBytes,

        [Parameter()]
        [System.Boolean]
        $Enabled,

        [Parameter()]
        [System.Boolean]
        $UsageDatabaseEnabled,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing configuration for Usage Definition {$Name}"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("Ensure",
        "Name",
        "DaysRetained",
        "DaysToKeepUsageFiles",
        "MaxTotalSizeInBytes",
        "Enabled",
        "UsageDatabaseEnabled"
    )

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath "\DSCResources\MSFT_SPUsageDefinition\MSFT_SPUsageDefinition.psm1" -Resolve

    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module

    $usageDefinitions = Get-SPUsageDefinition
    foreach ($usageDefinition in $usageDefinitions)
    {
        $PartialContent = "        SPUsageDefinition UsageDefinition_" + $($usageDefinition.Name -replace " ", '') + "`r`n"
        $PartialContent += "        {`r`n"
        $params.Name = $usageDefinition.Name
        $params.Ensure = "Present"
        $results = Get-TargetResource @params

        $results = Repair-Credentials -results $results

        $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
        $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"

        $PartialContent += $currentBlock
        $PartialContent += "        }`r`n"
        $Content += $PartialContent
    }

    return $Content
}

Export-ModuleMember -Function *-TargetResource
