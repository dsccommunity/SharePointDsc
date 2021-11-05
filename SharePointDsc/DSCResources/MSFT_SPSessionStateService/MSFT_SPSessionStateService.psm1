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
        $SessionTimeout
    )

    Write-Verbose -Message "Getting SPSessionStateService info"

    $result = Invoke-SPDscCommand -Arguments $PSBoundParameters `
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
        $SessionTimeout
    )

    Write-Verbose -Message "Setting SPSessionStateService info"

    if ($SessionTimeout -eq 0)
    {
        $SessionTimeout = 60
    }

    if ($Ensure -eq "Present")
    {
        Invoke-SPDscCommand -Arguments $PSBoundParameters `
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
        Invoke-SPDscCommand -Arguments $PSBoundParameters `
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
        $SessionTimeout
    )

    Write-Verbose -Message "Testing SPSessionStateService info"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($Ensure -eq "Present")
    {
        $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("Ensure", "SessionTimeout")
    }
    else
    {
        $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("Ensure")
    }

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPSessionStateService\MSFT_SPSessionStateService.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module
    $svc = Get-SPSessionStateService
    if ("" -ne $svc.CatalogName)
    {
        $params.DatabaseName = $svc.CatalogName
        $results = Get-TargetResource @params
        $PartialContent = "        SPSessionStateService " + [System.Guid]::NewGuid().ToString() + "`r`n"
        $PartialContent += "        {`r`n"
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
