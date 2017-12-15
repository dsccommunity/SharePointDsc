function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DefaultSiteCollectionProxyName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DefaultKeywordProxyName,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting the default site collection and keyword term store settings"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {

        $params = $args[0]

        $serviceAppProxies = Get-SPServiceApplicationProxy -ErrorAction SilentlyContinue

        if ($null -eq $serviceAppProxies)
        {
            return @{
                IsSingleInstance               = $params.IsSingleInstance
                DefaultSiteCollectionProxyName = ""
                DefaultKeywordProxyName        = ""
                InstallAccount                 = $params.InstallAccount
            }
        }
        else
        {
            $serviceAppProxies | Where-Object -FilterScript {
                $_.GetType().FullName -eq "Managed Metadata Service Connection"
            }

            $defaultSiteCollectionProxy = ""
            foreach($serviceAppProxy in $serviceAppProxies)
            {
                if($serviceAppProxy.Properties["IsDefaultKeywordTaxonomy"] -eq $true)
                {
                    if($defaultSiteCollectionProxy -eq "")
                    {
                        $defaultSiteCollectionProxy = $serviceAppProxy.Name
                    }
                    else
                    {
                        $defaultSiteCollectionProxy = $null
                    }
                }

                $defaultKeywordProxy = ""
                if($serviceAppProxy.Properties["IsDefaultSiteCollectionTaxonomy"] -eq $true)
                {
                    if($defaultKeywordProxy -eq "")
                    {
                        $defaultKeywordProxy = $serviceAppProxy.Name
                    }
                    else
                    {
                        $defaultKeywordProxy = $null
                    }
                }
            }
        }

        return @{
            IsSingleInstance               = $params.IsSingleInstance
            DefaultSiteCollectionProxyName = ""
            DefaultKeywordProxyName        = ""
            InstallAccount                 = $params.InstallAccount
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
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DefaultSiteCollectionProxyName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DefaultKeywordProxyName,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting the default site collection and keyword term store settings"

    $result = Get-TargetResource @PSBoundParameters

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
    -Arguments $PSBoundParameters `
    -ScriptBlock {

    $params = $args[0]

    $serviceAppProxies | Where-Object -FilterScript {
        $_.GetType().FullName -eq "Managed Metadata Service Connection"
    }

    foreach($serviceAppProxy in $serviceAppProxies)
    {
        $proxyName = $serviceAppProxy.Name

        $serviceAppProxy.Properties["IsDefaultKeywordTaxonomy"] = $false
        $serviceAppProxy.Properties["IsDefaultSiteCollectionTaxonomy"] = $false

        if($proxyName -eq $params.DefaultKeywordProxyName)
        {
            $serviceAppProxy.Properties["IsDefaultKeywordTaxonomy"] = $true
        }

        if($proxyName -eq $params.DefaultSiteCollectionProxyName)
        {
            $serviceAppProxy.Properties["IsDefaultSiteCollectionTaxonomy"] = $true
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
        [parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DefaultSiteCollectionProxyName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DefaultKeywordProxyName,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing the default site collection and keyword term store settings"

    $valuesToCheck = @(
        "DefaultSiteCollectionProxyName",
        "DefaultKeywordProxyName"
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck $valuesToCheck
}

Export-ModuleMember -Function *-TargetResource
