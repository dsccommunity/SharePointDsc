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
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Getting the Diagnostics Provider"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]

        $diagnosticProvider = Get-SPDiagnosticsProvider | Where-Object {$_.Name -eq $params.Name}
        $nullReturn = @{
            Name = $params.Name
            Retention = $params.Retention
            MaxTotalSizeInBytes = $params.MaxTotalSizeInBytes
            Enabled = $params.Enabled
            Ensure = "Absent"
            InstallAccount = $params.InstallAccount
        }
        if ($null -eq $diagnosticProvider)
        {
            return $nullReturn
        }

        return @{
            Name = $diagnosticProvider.Name
            Retention = $diagnosticProvider.Retention
            MaxTotalSizeInBytes = $diagnosticProvider.MaxTotalSizeInBytes
            Enabled = $diagnosticProvider.Enabled
            Ensure = "Present"
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
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Setting configuration for the Diagnostics Provider"

    if($Ensure -eq "Absent")
    {
        throw "This resource cannot remove Diagnostics Provider. Please use ensure equals Present."
    }

    Invoke-SPDSCCommand -Credential $InstallAccount `
                        -Arguments $PSBoundParameters `
                        -ScriptBlock {
        $params = $args[0]
        $diagnosticProvider = Get-SPDiagnosticsProvider | Where-Object {$_.Name -eq $params.Name}

        if($null -eq $diagnosticProvider)
        {
            throw "The specified Diagnostic Provider {" + $params.Name + "} could not be found."
        }

        if($params.ContainsKey("Retention"))
        {
            $diagnosticProvider.Retention = $params.Retention
        }

        if($params.ContainsKey("MaxTotalSizeInBytes"))
        {
            $diagnosticProvider.MaxTotalSizeInBytes = $params.MaxTotalSizeInBytes
        }

        if($params.ContainsKey("Enabled"))
        {
            $diagnosticProvider.Enabled = $params.Enabled
        }

        $diagnosticProvider.Update()
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
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Testing the Diagnostic Provider"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @("Ensure",
                                                     "Name",
                                                     "Retention",
                                                     "MaxTotalSizeInBytes",
                                                     "Enabled")
}

Export-ModuleMember -Function *-TargetResource
