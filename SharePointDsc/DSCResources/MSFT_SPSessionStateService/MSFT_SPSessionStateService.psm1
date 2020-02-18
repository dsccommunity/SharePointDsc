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
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseServer,

        [Parameter()]
        [System.Boolean]
        $UseSQLAuthentication,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.UInt32]
        $SessionTimeout,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting SPSessionStateService info"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $svc = Get-SPSessionStateService
        $Ensure = "Absent"
        if ($svc.SessionStateEnabled -eq $true)
        {
            $Ensure = "Present"
        }
        return @{
            DatabaseName   = $svc.CatalogName
            DatabaseServer = $svc.ServerName
            Ensure         = $Ensure
            SessionTimeout = $svc.Timeout.TotalMinutes
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
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseServer,

        [Parameter()]
        [System.Boolean]
        $UseSQLAuthentication,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.UInt32]
        $SessionTimeout,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting SPSessionStateService info"

    if ($SessionTimeout -eq 0)
    {
        $SessionTimeout = 60
    }

    if ($Ensure -eq "Present")
    {
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            $svc = Get-SPSessionStateService
            if ($svc.SessionStateEnabled)
            {
                if ($svc.Timeout.TotalMinutes -ne $params.SessionTimeout)
                {
                    Write-Verbose -Message "Configuring SPSessionState timeout"
                    Set-SPSessionStateService -SessionTimeout $params.SessionTimeout
                }
            }
            else
            {
                Write-Verbose -Message "Enabling SPSessionState"
                if ($params.UseSQLAuthentication -eq $true)
                {
                    Write-Verbose -Message "Using SQL authentication to create service application as `$useSQLAuthentication is set to $($params.useSQLAuthentication)."
                    $databaseCredentialsParam = @{
                        DatabaseCredentials = $params.DatabaseCredentials
                    }
                }
                else
                {
                    $databaseCredentialsParam = ""
                }
                Enable-SPSessionStateService -DatabaseName $params.DatabaseName `
                    -DatabaseServer $params.DatabaseServer `
                    -SessionTimeout $params.SessionTimeout `
                    @databaseCredentialsParam
            }
        }
    }
    if ($Ensure -eq "Absent")
    {
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $svc = Get-SPSessionStateService
            if ($svc.SessionStateEnabled)
            {
                Write-Verbose -Message "Disabling SPSessionState"
                Disable-SPSessionStateService
            }
            else
            {
                Write-Verbose -Message "Keeping SPSessionState disabled"
            }
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
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseServer,

        [Parameter()]
        [System.Boolean]
        $UseSQLAuthentication,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.UInt32]
        $SessionTimeout,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing SPSessionStateService info"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($Ensure -eq "Present")
    {
        return Test-SPDscParameterState -CurrentValues $CurrentValues `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("Ensure", "SessionTimeout")
    }
    else
    {
        return Test-SPDscParameterState -CurrentValues $CurrentValues `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("Ensure")
    }
}

Export-ModuleMember -Function *-TargetResource
