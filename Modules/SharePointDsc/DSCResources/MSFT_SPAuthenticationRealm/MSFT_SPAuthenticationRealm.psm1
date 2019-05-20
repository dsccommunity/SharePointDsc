function Get-TargetResource()
{
    [CmdletBinding()]
    [OutputType([System.Collections.HashTable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [String]
        $AuthenticationRealm,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting farm authentication realm"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
    -ScriptBlock {
        $currentRealm = Get-SPAuthenticationRealm

        Write-Verbose -Message "Current farm authentication realm is '$currentRealm'"

        return @{
            IsSingleInstance = "Yes"
            AuthenticationRealm = $currentRealm
        }
    }

    return $result
}

function Set-TargetResource()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [String]
        $AuthenticationRealm,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting farm authentication realm to $AuthenticationRealm"

    Invoke-SPDSCCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {

        $params = $args[0]
        Set-SPAuthenticationRealm -Realm $params.AuthenticationRealm
    }
}

function Test-TargetResource()
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [String]
        $AuthenticationRealm,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing farm authentication realm"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @("AuthenticationRealm")
}

Export-ModuleMember -Function *-TargetResource
