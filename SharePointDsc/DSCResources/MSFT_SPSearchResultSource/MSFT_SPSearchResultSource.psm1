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
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet("SSA",
            "SPSite",
            "SPWeb")]
        [System.String]
        $ScopeName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ScopeUrl,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SearchServiceAppName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Query,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ProviderType,

        [Parameter()]
        [System.String]
        $ConnectionUrl,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting search result source '$Name'"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]
        [void] [Reflection.Assembly]::LoadWithPartialName("Microsoft.Office.Server.Search")

        $nullReturn = @{
            Name                 = $params.Name
            ScopeName            = $params.ScopeName
            SearchServiceAppName = $params.SearchServiceAppName
            Query                = $null
            ProviderType         = $null
            ConnectionUrl        = $null
            ScopeUrl             = $null
            Ensure               = "Absent"
        }
        $serviceApp = Get-SPEnterpriseSearchServiceApplication -Identity $params.SearchServiceAppName
        if ($null -eq $serviceApp)
        {
            Write-Verbose -Message ("Specified Search service application $($params.SearchServiceAppName)" + `
                    "does not exist.")
            return $nullReturn
        }

        $fedManager = New-Object Microsoft.Office.Server.Search.Administration.Query.FederationManager($serviceApp)
        $providers = $fedManager.ListProviders()
        if ($providers.Keys -notcontains $params.ProviderType)
        {
            Write-Verbose -Message ("Unknown ProviderType ($($params.ProviderType)) is used. Allowed " + `
                    "values are: '" + ($providers.Keys -join "', '") + "'")
            return $nullReturn
        }

        $searchOwner = $null
        if ("ssa" -eq $params.ScopeName.ToLower())
        {
            $searchOwner = Get-SPEnterpriseSearchOwner -Level SSA
        }
        else
        {
            $searchOwner = Get-SPEnterpriseSearchOwner -Level $params.ScopeName -SPWeb $params.ScopeUrl
        }
        $filter = New-Object Microsoft.Office.Server.Search.Administration.SearchObjectFilter($searchOwner)
        $filter.IncludeHigherLevel = $true

        $source = $fedManager.ListSources($filter, $true) | Where-Object -FilterScript {
            $_.Name -eq $params.Name
        }

        if ($null -ne $source)
        {
            $providers = $fedManager.ListProviders()
            $provider = $providers.Values | Where-Object -FilterScript {
                $_.Id -eq $source.ProviderId
            }
            return @{
                Name                 = $params.Name
                ScopeName            = $params.ScopeName
                SearchServiceAppName = $params.SearchServiceAppName
                Query                = $source.QueryTransform.QueryTemplate
                ProviderType         = $provider.DisplayName
                ConnectionUrl        = $source.ConnectionUrlTemplate
                ScopeUrl             = $params.ScopeUrl
                Ensure               = "Present"
            }
        }
        else
        {
            return $nullReturn
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
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet("SSA",
            "SPSite",
            "SPWeb")]
        [System.String]
        $ScopeName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ScopeUrl,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SearchServiceAppName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Query,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ProviderType,

        [Parameter()]
        [System.String]
        $ConnectionUrl,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting search result source '$Name'"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($CurrentValues.Ensure -eq "Absent" -and $Ensure -eq "Present")
    {
        Write-Verbose -Message "Creating search result source $Name"
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]
            [void] [Reflection.Assembly]::LoadWithPartialName("Microsoft.Office.Server.Search")

            $serviceApp = Get-SPEnterpriseSearchServiceApplication `
                -Identity $params.SearchServiceAppName
            if ($null -eq $serviceApp)
            {
                throw ("Specified Search service application $($params.SearchServiceAppName)" + `
                        "does not exist.")
            }

            $fedManager = New-Object Microsoft.Office.Server.Search.Administration.Query.FederationManager($serviceApp)
            $providers = $fedManager.ListProviders()
            if ($providers.Keys -notcontains $params.ProviderType)
            {
                throw ("Unknown ProviderType ($($params.ProviderType)) is used. Allowed " + `
                        "values are: '" + ($providers.Keys -join "', '") + "'")
            }

            $searchOwner = $null
            if ("ssa" -eq $params.ScopeName.ToLower())
            {
                $searchOwner = Get-SPEnterpriseSearchOwner -Level SSA
            }
            else
            {
                $searchOwner = Get-SPEnterpriseSearchOwner -Level $params.ScopeName -SPWeb $params.ScopeUrl
            }

            $transformType = "Microsoft.Office.Server.Search.Query.Rules.QueryTransformProperties"
            $queryProperties = New-Object -TypeName $transformType
            $resultSource = $fedManager.CreateSource($searchOwner)

            $resultSource.Name = $params.Name
            $providers = $fedManager.ListProviders()
            $provider = $providers.Values | Where-Object -FilterScript {
                $_.DisplayName -eq $params.ProviderType
            }
            $resultSource.ProviderId = $provider.Id
            $resultSource.CreateQueryTransform($queryProperties, $params.Query)
            if ($params.ContainsKey("ConnectionUrl") -eq $true)
            {
                $resultSource.ConnectionUrlTemplate = $params.ConnectionUrl
            }
            $resultSource.Commit()
        }
    }

    if ($Ensure -eq "Absent")
    {
        Write-Verbose -Message "Removing search result source $Name"
        Invoke-SPDscCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            [void] [Reflection.Assembly]::LoadWithPartialName("Microsoft.Office.Server.Search")

            $serviceApp = Get-SPEnterpriseSearchServiceApplication `
                -Identity $params.SearchServiceAppName

            $fedManager = New-Object Microsoft.Office.Server.Search.Administration.Query.FederationManager($serviceApp)
            $searchOwner = $null
            if ("ssa" -eq $params.ScopeName.ToLower())
            {
                $searchOwner = Get-SPEnterpriseSearchOwner -Level SSA
            }
            else
            {
                $searchOwner = Get-SPEnterpriseSearchOwner -Level $params.ScopeName -SPWeb $params.ScopeUrl
            }

            $source = $fedManager.GetSourceByName($params.Name, $searchOwner)
            if ($null -ne $source)
            {
                $fedManager.RemoveSource($source)
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
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet("SSA",
            "SPSite",
            "SPWeb")]
        [System.String]
        $ScopeName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ScopeUrl,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SearchServiceAppName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Query,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ProviderType,

        [Parameter()]
        [System.String]
        $ConnectionUrl,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing search result source '$Name'"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("Ensure")

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    $content = ''
    $ParentModuleBase = Get-Module "SharePointDSC" | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath "\DSCResources\MSFT_SPSearchResultSource\MSFT_SPSearchResultSource.psm1" -Resolve 
    $params = Get-DSCFakeParameters -ModulePath $module

    $ssas = Get-SPServiceApplication | Where-Object -FilterScript{$_.GetType().FullName -eq "Microsoft.Office.Server.Search.Administration.SearchServiceApplication"}

    $i = 1
    $total = $ssas.Length
    foreach($ssa in $ssas)
    {
        try
        {
            if($ssa)
            {
                $serviceName = $ssa.DisplayName
                Write-Host "Scanning Results Sources for Search Service Application [$i/$total] {$serviceName}"
                $fedman = New-Object Microsoft.Office.Server.Search.Administration.Query.FederationManager($ssa)
                $searchOwner = Get-SPEnterpriseSearchOwner -Level SSA
                $filter = New-Object Microsoft.Office.Server.Search.Administration.SearchObjectFilter($searchOwner)
                $resultSources = $fedman.ListSources($filter,$true)

                $j = 1
                $totalRS = $resultSources.Count
                foreach($resultSource in $resultSources)
                {
                    <# Filter out the hidden Local SharePoint Graph provider since it is not supported by SharePointDSC. #>
                    if($resultSource.Name -ne "Local SharePoint Graph")
                    {
                        try
                        {
                            $rsName = $resultSource.Name
                            Write-Host "    -> Scanning Results Source [$j/$totalRS] {$rsName}"
                            $partialContent = "        SPSearchResultSource " + [System.Guid]::NewGuid().ToString() + "`r`n"
                            $partialContent += "        {`r`n"
                            $params.SearchServiceAppName = $serviceName
                            $params.Name = $rsName
                            $params.ScopeUrl = "Global"
                            $results = Get-TargetResource @params

                            $providers = $fedman.ListProviders()
                            $provider = $providers.Values | Where-Object -FilterScript {
                                $_.Id -eq $resultSource.ProviderId 
                            }

                            if($null -eq $results.Get_Item("ConnectionUrl") -or $results.ConnectionUrl -eq "")
                            {
                                $results.Remove("ConnectionUrl")
                            }
                            $results.Query = $resultSource.QueryTransform.QueryTemplate.Replace("`"","'")
                            $results.ProviderType = $provider.Name
                            $results.Ensure = "Present"
                            $results.ScopeUrl = "Global"
                            if($resultSource.ConnectionUrlTemplate)
                            {
                                $results.ConnectionUrl = $resultSource.ConnectionUrlTemplate
                            }

                            $results = Repair-Credentials -results $results
                            $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
                            $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
                            $partialContent += $currentBlock
                            $partialContent += "        }`r`n"
                            $Content += $partialContent
                        }
                        catch
                        {
                            $_
                        }
                    }
                    $j++
                }

                <# Include Web Level Content Sources #>
                if (!$SkipSitesAndWebs)
                {
                    $webApplications = Get-SPWebApplication
                    foreach ($webApp in $webApplications)
                    {
                        foreach ($site in $webApp.Sites)
                        {
                            try
                            {
                                foreach ($web in $site.AllWebs)
                                {
                                    # If the site is a subsite, then the SPWeb option had to be selected for extraction
                                    if ($site.RootWeb.Url -eq $web.Url -or $chckSPWeb.Checked)
                                    {
                                        Write-Host "Scanning Results Sources for {$($web.Url)}"
                                        $fedman = New-Object Microsoft.Office.Server.Search.Administration.Query.FederationManager($ssa)
                                        $searchOwner = Get-SPEnterpriseSearchOwner -Level SPWeb -SPWeb $web
                                        $filter = New-Object Microsoft.Office.Server.Search.Administration.SearchObjectFilter($searchOwner)
                                        # Filtering Higher Sources from each Web as they will be exported with the Service App
                                        $filter.IncludeHigherLevel = $false
                                        $sources = $fedman.ListSources($filter,$true)

                                        foreach ($source in $sources)
                                        {
                                            try
                                            {
                                                if (!$source.BuiltIn)
                                                {
                                                    $partialContent = "        SPSearchResultSource " + [System.Guid]::NewGuid().ToString() + "`r`n"
                                                    $partialContent += "        {`r`n"
                                                    $params.SearchServiceAppName = $serviceName
                                                    $params.Name = $source.Name
                                                    $params.ScopeName = "SPWeb"
                                                    $params.ScopeUrl = $web.Url
                                                    $results = Get-TargetResource @params
                                                    $results.ScopeUrl = $web.Url

                                                    $providers = $fedman.ListProviders()
                                                    $provider = $providers.Values | Where-Object -FilterScript {
                                                        $_.Id -eq $source.ProviderId 
                                                    }

                                                    if ($null -eq $results.Get_Item("ConnectionUrl"))
                                                    {
                                                        $results.Remove("ConnectionUrl")
                                                    }
                                                    $results.Query = $source.QueryTransform.QueryTemplate.Replace("`"","'")
                                                    $results.ProviderType = $provider.Name
                                                    $results.Ensure = "Present"
                                                    if ($source.ConnectionUrlTemplate)
                                                    {
                                                        $results.ConnectionUrl = $source.ConnectionUrlTemplate
                                                    }

                                                    $results = Repair-Credentials -results $results
                                                    $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
                                                    $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
                                                    $partialContent += $currentBlock
                                                    $partialContent += "        }`r`n"
                                                    $Content += $partialContent
                                                }
                                            }
                                            catch
                                            {
                                                $_
                                            }
                                        }
                                    }
                                    $web.Dispose()
                                }
                            }
                            catch
                            {
                                $_
                            }
                            $site.Dispose()
                        }
                    }
                }
            }
        }
        catch
        {
            $_
            $Global:ErrorLog += "[Search Result Source]" + $ssa.DisplayName + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
        $Content += $partialContent
    }
    Return $content
}

Export-ModuleMember -Function *-TargetResource
