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
        $AppDomain,

        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet("Default", "Internet", "Intranet", "Extranet", "Custom")]
        $Zone,

        [Parameter()]
        [System.String]
        $Port,

        [Parameter()]
        [System.Boolean]
        $SSL,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting app domain settings for '$AppDomain'"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]
        $webAppAppDomain = Get-SPWebApplicationAppDomain -WebApplication $params.WebAppUrl `
            -Zone $params.Zone

        if ($null -eq $webAppAppDomain)
        {
            return @{
                WebAppUrl = $params.WebAppUrl
                AppDomain = $null
                Zone      = $null
                Port      = $null
                SSL       = $null
            }
        }
        else
        {
            return @{
                WebAppUrl      = $params.WebAppUrl
                AppDomain      = $webAppAppDomain.AppDomain
                Zone           = $webAppAppDomain.UrlZone
                Port           = $webAppAppDomain.Port
                SSL            = $webAppAppDomain.IsSchemeSSL
                InstallAccount = $params.InstallAccount
            }
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
        $AppDomain,

        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet("Default", "Internet", "Intranet", "Extranet", "Custom")]
        $Zone,

        [Parameter()]
        [System.String]
        $Port,

        [Parameter()]
        [System.Boolean]
        $SSL,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting app domain settings for '$AppDomain'"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters, $CurrentValues) `
        -ScriptBlock {
        $params = $args[0]
        $CurrentValues = $args[1]

        if ($null -ne $CurrentValues.AppDomain)
        {
            Get-SPWebApplicationAppDomain -WebApplication $params.WebAppUrl `
                -Zone $params.Zone | Remove-SPWebApplicationAppDomain
            Start-Sleep -Seconds 5
        }

        $newParams = @{
            AppDomain      = $params.AppDomain
            WebApplication = $params.WebAppUrl
            Zone           = $params.Zone
        }
        if ($params.ContainsKey("Port") -eq $true)
        {
            $newParams.Add("Port", $params.Port)
        }
        if ($params.ContainsKey("SSL") -eq $true)
        {
            $newParams.Add("SecureSocketsLayer", $params.SSL)
        }

        New-SPWebApplicationAppDomain @newParams
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
        $AppDomain,

        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet("Default", "Internet", "Intranet", "Extranet", "Custom")]
        $Zone,

        [Parameter()]
        [System.String]
        $Port,

        [Parameter()]
        [System.Boolean]
        $SSL,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing app domain settings for '$AppDomain'"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("AppDomain", "Port", "SSL")

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

Export-ModuleMember -Function *-TargetResource
