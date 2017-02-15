function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String] 
        $AppDomain,

        [parameter(Mandatory = $true)] 
        [System.String] 
        $WebApplication,

        [parameter(Mandatory = $true)] 
        [System.String] 
        [ValidateSet("Default","Internet","Intranet","Extranet","Custom")] 
        $Zone,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $Port,

        [parameter(Mandatory = $false)] 
        [System.Boolean] 
        $SSL,

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Getting app domain settings for '$AppDomain'"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]
        $webAppAppDomain = Get-SPWebApplicationAppDomain -WebApplication $params.WebApplication `
                                                         -Zone $params.Zone

        if ($null -eq $webAppAppDomain) 
        {
            return $null
        } 
        else 
        {
            return @{
                AppDomain = $webAppAppDomain.AppDomain 
                WebApplication = $params.WebApplication
                Zone = $webAppAppDomain.UrlZone
                Port = $webAppAppDomain.Port
                SSL = $webAppAppDomain.IsSchemeSSL
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
        [parameter(Mandatory = $true)]
        [System.String] 
        $AppDomain,

        [parameter(Mandatory = $true)] 
        [System.String] 
        $WebApplication,

        [parameter(Mandatory = $true)] 
        [System.String] 
        [ValidateSet("Default","Internet","Intranet","Extranet","Custom")] 
        $Zone,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $Port,

        [parameter(Mandatory = $false)] 
        [System.Boolean] 
        $SSL,

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Setting app domain settings for '$AppDomain'"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Invoke-SPDSCCommand -Credential $InstallAccount `
                        -Arguments @($PSBoundParameters, $CurrentValues) `
                        -ScriptBlock {
        $params = $args[0]
        $CurrentValues = $args[1]

        if ($null -ne $CurrentValues) 
        {
            Get-SPWebApplicationAppDomain -WebApplication $params.WebApplication `
                                          -Zone $params.Zone | Remove-SPWebApplicationAppDomain
            Start-Sleep -Seconds 5
        }

        $newParams = @{
            AppDomain = $params.AppDomain
            WebApplication = $params.WebApplication 
            Zone = $params.Zone
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
        [parameter(Mandatory = $true)]
        [System.String] 
        $AppDomain,

        [parameter(Mandatory = $true)] 
        [System.String] 
        $WebApplication,

        [parameter(Mandatory = $true)] 
        [System.String] 
        [ValidateSet("Default","Internet","Intranet","Extranet","Custom")] 
        $Zone,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $Port,

        [parameter(Mandatory = $false)] 
        [System.Boolean] 
        $SSL,

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Testing app domain settings for '$AppDomain'"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($null -eq $CurrentValues) 
    { 
        return $false 
    }

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @("AppDomain", "Port", "SSL") 
}

Export-ModuleMember -Function *-TargetResource
