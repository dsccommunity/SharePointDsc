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
        $WebAppUrl,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServiceAppProxyGroup,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting $WebAppUrl Service Proxy Group Association"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $WebApp = get-spwebapplication $params.WebAppUrl
        if (!$WebApp)
        {
            return  @{
                WebAppUrl            = $null
                ServiceAppProxyGroup = $null
                InstallAccount       = $InstallAccount
            }
        }

        if ($WebApp.ServiceApplicationProxyGroup.friendlyname -eq "[default]")
        {
            $ServiceAppProxyGroup = "Default"
        }
        else
        {
            $ServiceAppProxyGroup = $WebApp.ServiceApplicationProxyGroup.name
        }

        return @{
            WebAppUrl            = $params.WebAppUrl
            ServiceAppProxyGroup = $ServiceAppProxyGroup
            InstallAccount       = $InstallAccount
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
        $WebAppUrl,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServiceAppProxyGroup,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting $WebAppUrl Service Proxy Group Association"

    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        if ($params.ServiceAppProxyGroup -eq "Default")
        {
            $params.ServiceAppProxyGroup = "[default]"
        }

        Set-SPWebApplication -Identity $params.WebAppUrl `
            -ServiceApplicationProxyGroup $params.ServiceAppProxyGroup
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
        $WebAppUrl,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServiceAppProxyGroup,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing $WebAppUrl Service Proxy Group Association"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if (($null -eq $CurrentValues.WebAppUrl) -or ($null -eq $CurrentValues.ServiceAppProxyGroup))
    {
        return $false
    }

    if ($CurrentValues.ServiceAppProxyGroup -eq $ServiceAppProxyGroup)
    {
        return $true
    }
    else
    {
        return $false
    }
}

Export-ModuleMember -Function *-TargetResource
