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
        [String]
        $ServiceAppProxyGroup,

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

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {

        $params = $args[0]

        if ($params.ServiceAppProxyGroup -eq 'default')
        {
            $serviceAppProxyGroup = Get-SPServiceApplicationProxyGroup -Default -ErrorAction SilentlyContinue
        }
        else
        {
            $serviceAppProxyGroup = Get-SPServiceApplicationProxyGroup -Identity $params.ServiceAppProxyGroup `
                -ErrorAction SilentlyContinue
        }

        if ($null -eq $serviceAppProxyGroup)
        {
            throw "Specified ServiceAppProxyGroup $($params.ServiceAppProxyGroup) does not exist."
        }

        $serviceAppProxies = $serviceAppProxyGroup.Proxies

        if ($null -eq $serviceAppProxies)
        {
            throw "There are no Service Application Proxies available in the proxy group"
        }

        $serviceAppProxies = $serviceAppProxies | Where-Object -FilterScript {
            $_.GetType().FullName -eq "Microsoft.SharePoint.Taxonomy.MetadataWebServiceApplicationProxy"
        }

        if ($null -eq $serviceAppProxies)
        {
            throw "There are no Managed Metadata Service Application Proxies available in the proxy group"
        }

        $defaultSiteCollectionProxyIsSet = $false
        $defaultKeywordProxyIsSet = $false

        $defaultSiteCollectionProxy = $null
        $defaultKeywordProxy = $null

        foreach ($serviceAppProxy in $serviceAppProxies)
        {
            if ($serviceAppProxy.Properties["IsDefaultSiteCollectionTaxonomy"] -eq $true)
            {
                if ($defaultSiteCollectionProxyIsSet -eq $false)
                {
                    $defaultSiteCollectionProxy = $serviceAppProxy.Name
                    $defaultSiteCollectionProxyIsSet = $true
                }
                else
                {
                    $defaultSiteCollectionProxy = $null
                }
            }
            if ($serviceAppProxy.Properties["IsDefaultKeywordTaxonomy"] -eq $true)
            {
                if ($defaultKeywordProxyIsSet -eq $false)
                {
                    $defaultKeywordProxy = $serviceAppProxy.Name
                    $defaultKeywordProxyIsSet = $true
                }
                else
                {
                    $defaultKeywordProxy = $null
                }
            }
        }

        return @{
            ServiceAppProxyGroup           = $params.ServiceAppProxyGroup
            DefaultSiteCollectionProxyName = $defaultSiteCollectionProxy
            DefaultKeywordProxyName        = $defaultKeywordProxy
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
        [String]
        $ServiceAppProxyGroup,

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

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {

        $params = $args[0]

        if ($params.ServiceAppProxyGroup -eq 'default')
        {
            $serviceAppProxyGroup = Get-SPServiceApplicationProxyGroup -Default -ErrorAction SilentlyContinue
        }
        else
        {
            $serviceAppProxyGroup = Get-SPServiceApplicationProxyGroup -Identity $params.ServiceAppProxyGroup `
                -ErrorAction SilentlyContinue
        }

        $serviceAppProxies = $serviceAppProxyGroup.Proxies

        $serviceAppProxies = $serviceAppProxies | Where-Object -FilterScript {
            $_.GetType().FullName -eq "Microsoft.SharePoint.Taxonomy.MetadataWebServiceApplicationProxy"
        }

        foreach ($serviceAppProxy in $serviceAppProxies)
        {
            $proxyName = $serviceAppProxy.Name

            $serviceAppProxy.Properties["IsDefaultKeywordTaxonomy"] = $false
            $serviceAppProxy.Properties["IsDefaultSiteCollectionTaxonomy"] = $false

            if ($proxyName -eq $params.DefaultKeywordProxyName)
            {
                $serviceAppProxy.Properties["IsDefaultKeywordTaxonomy"] = $true
            }

            if ($proxyName -eq $params.DefaultSiteCollectionProxyName)
            {
                $serviceAppProxy.Properties["IsDefaultSiteCollectionTaxonomy"] = $true
            }

            $serviceAppProxy.Update()
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
        [String]
        $ServiceAppProxyGroup,

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

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck $valuesToCheck
}

Export-ModuleMember -Function *-TargetResource
