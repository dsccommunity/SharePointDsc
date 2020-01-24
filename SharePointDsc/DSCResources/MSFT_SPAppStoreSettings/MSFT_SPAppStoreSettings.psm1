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

        [Parameter()]
        [System.Boolean]
        $AllowAppPurchases,

        [Parameter()]
        [System.Boolean]
        $AllowAppsForOffice,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting app store settings of $WebAppUrl"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $nullreturn = @{
            WebAppUrl      = $null
            InstallAccount = $params.InstallAccount
        }

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue
        if ($null -eq $wa)
        {
            return $nullreturn
        }

        $currentAAP = (Get-SPAppAcquisitionConfiguration -WebApplication $params.WebAppUrl).Enabled
        $AllowAppPurchases = [System.Convert]::ToBoolean($currentAAP)
        $currentAAFO = (Get-SPOfficeStoreAppsDefaultActivation -WebApplication $params.WebAppUrl).Enable
        $AllowAppsForOffice = [System.Convert]::ToBoolean($currentAAFO)

        return @{
            WebAppUrl          = $params.WebAppUrl
            AllowAppPurchases  = $AllowAppPurchases
            AllowAppsForOffice = $AllowAppsForOffice
            InstallAccount     = $params.InstallAccount
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

        [Parameter()]
        [System.Boolean]
        $AllowAppPurchases,

        [Parameter()]
        [System.Boolean]
        $AllowAppsForOffice,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting app store settings of $WebAppUrl"

    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue
        if ($null -eq $wa)
        {
            throw ("Specified web application does not exist.")
        }

        if ($params.ContainsKey("AllowAppPurchases"))
        {
            $current = (Get-SPAppAcquisitionConfiguration -WebApplication $params.WebAppUrl).Enabled
            $AllowAppPurchases = [System.Convert]::ToBoolean($current)
            if ($AllowAppPurchases -ne $params.AllowAppPurchases)
            {
                Set-SPAppAcquisitionConfiguration -WebApplication $params.WebAppUrl `
                    -Enable $params.AllowAppPurchases
            }
        }

        if ($params.ContainsKey("AllowAppsForOffice"))
        {
            $current = (Get-SPOfficeStoreAppsDefaultActivation -WebApplication $params.WebAppUrl).Enable
            $AllowAppsForOffice = [System.Convert]::ToBoolean($current)
            if ($AllowAppsForOffice -ne $params.AllowAppsForOffice)
            {
                Set-SPOfficeStoreAppsDefaultActivation -WebApplication $params.WebAppUrl `
                    -Enable $params.AllowAppsForOffice
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
        $WebAppUrl,

        [Parameter()]
        [System.Boolean]
        $AllowAppPurchases,

        [Parameter()]
        [System.Boolean]
        $AllowAppsForOffice,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing app store settings of $WebAppUrl"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($null -eq $currentValues.WebAppUrl)
    {
        Write-Verbose -Message "Specified web application does not exist."
        return $false
    }

    if ($PSBoundParameters.ContainsKey("AllowAppPurchases"))
    {
        if ($AllowAppPurchases -ne $CurrentValues.AllowAppPurchases)
        {
            return $false
        }
    }

    if ($PSBoundParameters.ContainsKey("AllowAppsForOffice"))
    {
        if ($AllowAppsForOffice -ne $CurrentValues.AllowAppsForOffice)
        {
            return $false
        }
    }

    return $true
}

Export-ModuleMember -Function *-TargetResource
