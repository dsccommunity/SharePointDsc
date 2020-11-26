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
        [System.String]
        $ActiveDirectoryCustomFilter,

        [Parameter()]
        [System.String]
        $ActiveDirectoryCustomQuery,

        [Parameter()]
        [System.UInt16]
        $ActiveDirectorySearchTimeout,

        [Parameter()]
        [System.Boolean]
        $OnlySearchWithinSiteCollection,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $SearchActiveDirectoryDomains,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting People Picker Settings for $WebAppUrl"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl `
            -ErrorAction SilentlyContinue

        if ($null -eq $wa)
        {
            return @{
                WebAppUrl                      = $params.WebAppUrl
                ActiveDirectoryCustomFilter    = $null
                ActiveDirectoryCustomQuery     = $null
                ActiveDirectorySearchTimeout   = $null
                OnlySearchWithinSiteCollection = $null
                SearchActiveDirectoryDomains   = $null
            }
        }

        $searchADDomains = @()
        foreach ($searchDomain in $wa.PeoplePickerSettings.SearchActiveDirectoryDomains)
        {
            $searchADDomain = @{ }
            $searchADDomain.FQDN = $searchDomain.DomainName
            $searchADDomain.IsForest = $searchDomain.IsForest
            $searchADDomain.AccessAccount = $searchDomain.LoginName
            $searchADDomains += $searchADDomain
        }

        return @{
            WebAppUrl                      = $params.WebAppUrl
            ActiveDirectoryCustomFilter    = $wa.PeoplePickerSettings.ActiveDirectoryCustomFilter
            ActiveDirectoryCustomQuery     = $wa.PeoplePickerSettings.ActiveDirectoryCustomQuery
            ActiveDirectorySearchTimeout   = $wa.PeoplePickerSettings.ActiveDirectorySearchTimeout.TotalSeconds
            OnlySearchWithinSiteCollection = $wa.PeoplePickerSettings.OnlySearchWithinSiteCollection
            SearchActiveDirectoryDomains   = $searchADDomains
        }
    }
    return $result
}

function Set-TargetResource
{
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification = "Ignoring this because the used AccessAccount does not use SecureString to handle the password")]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter()]
        [System.String]
        $ActiveDirectoryCustomFilter,

        [Parameter()]
        [System.String]
        $ActiveDirectoryCustomQuery,

        [Parameter()]
        [System.UInt16]
        $ActiveDirectorySearchTimeout,

        [Parameter()]
        [System.Boolean]
        $OnlySearchWithinSiteCollection,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $SearchActiveDirectoryDomains,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting People Picker Settings for $WebAppUrl"

    ## Perform changes
    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue

        if ($null -eq $wa)
        {
            $message = "Specified web application could not be found."
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }

        if ($params.ContainsKey("ActiveDirectoryCustomFilter"))
        {
            if ($params.ActiveDirectoryCustomFilter -ne $wa.PeoplePickerSettings.ActiveDirectoryCustomFilter)
            {
                $wa.PeoplePickerSettings.ActiveDirectoryCustomFilter = $params.ActiveDirectoryCustomFilter
            }
        }

        if ($params.ContainsKey("ActiveDirectoryCustomQuery"))
        {
            if ($params.ActiveDirectoryCustomQuery -ne $wa.PeoplePickerSettings.ActiveDirectoryCustomQuery)
            {
                $wa.PeoplePickerSettings.ActiveDirectoryCustomQuery = $params.ActiveDirectoryCustomQuery
            }
        }

        if ($params.ContainsKey("ActiveDirectorySearchTimeout"))
        {
            if ($params.ActiveDirectorySearchTimeout -ne $wa.PeoplePickerSettings.ActiveDirectorySearchTimeout.TotalSeconds)
            {
                $wa.PeoplePickerSettings.ActiveDirectorySearchTimeout = New-TimeSpan -Seconds $params.ActiveDirectorySearchTimeout
            }
        }

        if ($params.ContainsKey("OnlySearchWithinSiteCollection"))
        {
            if ($params.OnlySearchWithinSiteCollection -ne $wa.PeoplePickerSettings.OnlySearchWithinSiteCollection)
            {
                $wa.PeoplePickerSettings.OnlySearchWithinSiteCollection = $params.OnlySearchWithinSiteCollection
            }
        }

        if ($params.ContainsKey("SearchActiveDirectoryDomains"))
        {
            foreach ($searchADDomain in $params.SearchActiveDirectoryDomains)
            {
                $configuredDomain = $wa.PeoplePickerSettings.SearchActiveDirectoryDomains | `
                    Where-Object -FilterScript {
                    $_.DomainName -eq $searchADDomain.FQDN -and `
                        $_.IsForest -eq $searchADDomain.IsForest
                }
                if ($null -eq $configuredDomain)
                {
                    # Add domain
                    $adsearchobj = New-Object -TypeName Microsoft.SharePoint.Administration.SPPeoplePickerSearchActiveDirectoryDomain
                    $adsearchobj.DomainName = $searchADDomain.FQDN

                    $prop = $searchADDomain.CimInstanceProperties | Where-Object -FilterScript {
                        $_.Name -eq "NetBIOSName"
                    }
                    if ($null -ne $prop)
                    {
                        $adsearchobj.ShortDomainName = $searchADDomain.NetBIOSName
                    }

                    $adsearchobj.IsForest = $searchADDomain.IsForest

                    if ($null -ne $searchADDomain.AccessAccount)
                    {
                        $adsearchobj.LoginName = $searchADDomain.AccessAccount.UserName

                        if ([string]::IsNullOrEmpty($searchADDomain.AccessAccount.Password))
                        {
                            $adsearchobj.SetPassword($null)
                        }
                        else
                        {
                            $accessAccountPassword = ConvertTo-SecureString $searchADDomain.AccessAccount.Password -AsPlainText -Force
                            $adsearchobj.SetPassword($accessAccountPassword)
                        }
                    }

                    $wa.PeoplePickerSettings.SearchActiveDirectoryDomains.Add($adsearchobj)
                }
            }

            # Reverse Check: Configured domains do not exist in config
            $removeDomains = @()
            foreach ($waSearchADDomain in $wa.PeoplePickerSettings.SearchActiveDirectoryDomains)
            {
                $specifiedDomain = $params.SearchActiveDirectoryDomains | Where-Object -FilterScript {
                    $_.FQDN -eq $waSearchADDomain.DomainName -and `
                        $_.IsForest -eq $waSearchADDomain.IsForest
                }

                if ($null -eq $specifiedDomain)
                {
                    # Configured domain not found in DSC configuration, removing domain
                    $removeDomains += $waSearchADDomain
                }
            }

            foreach ($domain in $removeDomains)
            {
                $wa.PeoplePickerSettings.SearchActiveDirectoryDomains.Remove($domain) | Out-Null
            }
        }
        $wa.Update()
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
        [System.String]
        $ActiveDirectoryCustomFilter,

        [Parameter()]
        [System.String]
        $ActiveDirectoryCustomQuery,

        [Parameter()]
        [System.UInt16]
        $ActiveDirectorySearchTimeout,

        [Parameter()]
        [System.Boolean]
        $OnlySearchWithinSiteCollection,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $SearchActiveDirectoryDomains,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing People Picker Settings for $WebAppUrl"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    # Testing SearchActiveDirectoryDomains against configured values
    foreach ($searchADDomain in $SearchActiveDirectoryDomains)
    {
        $configuredDomain = $CurrentValues.SearchActiveDirectoryDomains | `
            Where-Object -FilterScript {
            $_.FQDN -eq $searchADDomain.FQDN -and `
                $_.IsForest -eq $searchADDomain.IsForest
        }
        if ($null -eq $configuredDomain)
        {
            $message = "Current SearchActiveDirectoryDomains does not match the desired state."
            Write-Verbose -Message $message
            Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

            Write-Verbose -Message "Test-TargetResource returned false"
            return $false
        }
    }

    # Reverse: Testing configured values against SearchActiveDirectoryDomains
    foreach ($searchADDomain in $CurrentValues.SearchActiveDirectoryDomains)
    {
        $specifiedDomain = $SearchActiveDirectoryDomains | Where-Object -FilterScript {
            $_.FQDN -eq $searchADDomain.FQDN -and `
                $_.IsForest -eq $searchADDomain.IsForest
        }

        if ($null -eq $specifiedDomain)
        {
            $message = "Current SearchActiveDirectoryDomains does not match the desired state."
            Write-Verbose -Message $message
            Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

            Write-Verbose -Message "Test-TargetResource returned false"
            return $false
        }
    }

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("ActiveDirectoryCustomFilter", `
            "ActiveDirectoryCustomQuery", `
            "ActiveDirectorySearchTimeout", `
            "OnlySearchWithinSiteCollection")

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

Export-ModuleMember -Function *-TargetResource
