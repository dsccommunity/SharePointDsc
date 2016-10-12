function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  
        [System.String] 
        $WebAppUrl,

        [parameter(Mandatory = $false)]  
        [System.Boolean] 
        $AllowAppPurchases,

        [parameter(Mandatory = $false)]  
        [System.Boolean] 
        $AllowAppsForOffice,

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Getting app catalog status of $SiteUrl"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]

        $nullreturn = @{
            WebAppUrl = $null
            InstallAccount = $params.InstallAccount
        }

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue
        if ($null -eq $wa) 
        {
            return $nullreturn
        }

        $AllowAppPurchases = (Get-SPAppAcquisitionConfiguration -WebApplication $params.WebAppUrl).Enabled
        $AllowAppsForOffice = (Get-SPOfficeStoreAppsDefaultActivation -WebApplication $params.WebAppUrl).Enabled

        return @{
            WebAppUrl = $params.WebAppUrl
            AllowAppPurchases = $AllowAppPurchases
            AllowAppsForOffice = $AllowAppsForOffice
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
        [parameter(Mandatory = $true)]  
        [System.String] 
        $WebAppUrl,

        [parameter(Mandatory = $false)]  
        [System.Boolean] 
        $AllowAppPurchases,

        [parameter(Mandatory = $false)]  
        [System.Boolean] 
        $AllowAppsForOffice,

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Setting app catalog status of $SiteUrl"

    Invoke-SPDSCCommand -Credential $InstallAccount `
                        -Arguments $PSBoundParameters `
                        -ScriptBlock {
        $params = $args[0]

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue
        if ($null -eq $wa) 
        {
            throw ("Specified web application does not exist.")
        }

        $AllowAppPurchases = (Get-SPAppAcquisitionConfiguration -WebApplication $params.WebAppUrl).Enabled
        if ($AllowAppPurchases -ne $params.AllowAppPurchases)
        {
            Set-SPAppAcquisitionConfiguration -WebApplication $params.WebAppUrl -Enable $params.AllowAppPurchases
        }

        $AllowAppsForOffice = (Get-SPOfficeStoreAppsDefaultActivation -WebApplication $params.WebAppUrl).Enabled
        if ($AllowAppsForOffice -ne $params.AllowAppsForOffice)
        {
            Set-SPOfficeStoreAppsDefaultActivation -WebApplication $params.WebAppUrl -Enable $params.AllowAppsForOffice
        }
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
        $WebAppUrl,

        [parameter(Mandatory = $false)]  
        [System.Boolean] 
        $AllowAppPurchases,

        [parameter(Mandatory = $false)]  
        [System.Boolean] 
        $AllowAppsForOffice,

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Testing app catalog status of $SiteUrl"

    $currentValues = Get-TargetResource @PSBoundParameters

    return Test-SPDscParameterState -CurrentValues $currentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @("WebAppUrl", `
                                                     "AllowAppPurchases", `
                                                     "AllowAppsForOffice") 
}

Export-ModuleMember -Function *-TargetResource
