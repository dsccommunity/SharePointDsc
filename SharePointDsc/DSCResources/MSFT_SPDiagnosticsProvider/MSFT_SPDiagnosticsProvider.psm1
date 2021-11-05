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
        [System.UInt16]
        $Retention,

        [Parameter()]
        [System.UInt64]
        $MaxTotalSizeInBytes,

        [Parameter()]
        [System.Boolean]
        $Enabled,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Getting the Diagnostics Provider"

    $result = Invoke-SPDscCommand -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $diagnosticProvider = Get-SPDiagnosticsProvider | Where-Object { $_.Name -eq $params.Name }
        $nullReturn = @{
            Name                = $params.Name
            Retention           = $params.Retention
            MaxTotalSizeInBytes = $params.MaxTotalSizeInBytes
            Enabled             = $params.Enabled
            Ensure              = "Absent"
        }
        if ($null -eq $diagnosticProvider)
        {
            return $nullReturn
        }

        return @{
            Name                = $diagnosticProvider.Name
            Retention           = $diagnosticProvider.Retention
            MaxTotalSizeInBytes = $diagnosticProvider.MaxTotalSizeInBytes
            Enabled             = $diagnosticProvider.Enabled
            Ensure              = "Present"
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
        [System.UInt16]
        $Retention,

        [Parameter()]
        [System.UInt64]
        $MaxTotalSizeInBytes,

        [Parameter()]
        [System.Boolean]
        $Enabled,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Setting configuration for the Diagnostics Provider"

    if ($Ensure -eq "Absent")
    {
        $message = "This resource cannot remove Diagnostics Provider. Please use ensure equals Present."
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    Invoke-SPDscCommand -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]

        $diagnosticProvider = Get-SPDiagnosticsProvider | Where-Object { $_.Name -eq $params.Name }

        if ($null -eq $diagnosticProvider)
        {
            $message = "The specified Diagnostic Provider {" + $params.Name + "} could not be found."
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }

        $newParams = @{
            Identity = $params.Name
        }

        if ($params.ContainsKey("Retention"))
        {
            $newParams.DaysRetained = $params.Retention
        }

        if ($params.ContainsKey("MaxTotalSizeInBytes"))
        {
            $newParams.MaxTotalSizeInBytes = $params.MaxTotalSizeInBytes
        }

        if ($params.ContainsKey("Enabled"))
        {
            $newParams.Enable = $params.Enabled
        }

        Set-SPDiagnosticsProvider @newParams
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
        [System.UInt16]
        $Retention,

        [Parameter()]
        [System.UInt64]
        $MaxTotalSizeInBytes,

        [Parameter()]
        [System.Boolean]
        $Enabled,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Testing the Diagnostic Provider"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("Ensure",
        "Name",
        "Retention",
        "MaxTotalSizeInBytes",
        "Enabled")

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

Export-ModuleMember -Function *-TargetResource
