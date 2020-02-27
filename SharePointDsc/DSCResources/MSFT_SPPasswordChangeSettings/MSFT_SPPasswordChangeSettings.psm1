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
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [System.String]
        $MailAddress,

        [Parameter()]
        [ValidateRange(0, 356)]
        [System.UInt32]
        $DaysBeforeExpiry,

        [Parameter()]
        [ValidateRange(0, 36000)]
        [System.UInt32]
        $PasswordChangeWaitTimeSeconds,

        [Parameter()]
        [ValidateRange(0, 99)]
        [System.UInt32]
        $NumberOfRetries,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting farm wide automatic password change settings"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $farm = Get-SPFarm
        if ($null -eq $farm )
        {
            return @{
                IsSingleInstance              = "Yes"
                MailAddress                   = $null
                PasswordChangeWaitTimeSeconds = $null
                NumberOfRetries               = $null
                DaysBeforeExpiry              = $null
            }
        }

        return @{
            IsSingleInstance              = "Yes"
            MailAddress                   = $farm.PasswordChangeEmailAddress
            PasswordChangeWaitTimeSeconds = $farm.PasswordChangeGuardTime
            NumberOfRetries               = $farm.PasswordChangeMaximumTries
            DaysBeforeExpiry              = $farm.DaysBeforePasswordExpirationToSendEmail
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
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [System.String]
        $MailAddress,

        [Parameter()]
        [ValidateRange(0, 356)]
        [System.UInt32]
        $DaysBeforeExpiry,

        [Parameter()]
        [ValidateRange(0, 36000)]
        [System.UInt32]
        $PasswordChangeWaitTimeSeconds,

        [Parameter()]
        [ValidateRange(0, 99)]
        [System.UInt32]
        $NumberOfRetries,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting farm wide automatic password change settings"

    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]
        $farm = Get-SPFarm -ErrorAction Continue

        if ($null -eq $farm )
        {
            return $null
        }

        $farm.PasswordChangeEmailAddress = $params.MailAddress
        if ($null -ne $params.PasswordChangeWaitTimeSeconds)
        {
            $farm.PasswordChangeGuardTime = $params.PasswordChangeWaitTimeSeconds
        }
        if ($null -ne $params.NumberOfRetries)
        {
            $farm.PasswordChangeMaximumTries = $params.NumberOfRetries
        }
        if ($null -ne $params.DaysBeforeExpiry)
        {
            $farm.DaysBeforePasswordExpirationToSendEmail = $params.DaysBeforeExpiry
        }
        $farm.Update();
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [System.String]
        $MailAddress,

        [Parameter()]
        [ValidateRange(0, 356)]
        [System.UInt32]
        $DaysBeforeExpiry,

        [Parameter()]
        [ValidateRange(0, 36000)]
        [System.UInt32]
        $PasswordChangeWaitTimeSeconds,

        [Parameter()]
        [ValidateRange(0, 99)]
        [System.UInt32]
        $NumberOfRetries,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing farm wide automatic password change settings"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("MailAddress",
        "DaysBeforeExpiry",
        "PasswordChangeWaitTimeSeconds",
        "NumberOfRetries")

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

Export-ModuleMember -Function *-TargetResource
