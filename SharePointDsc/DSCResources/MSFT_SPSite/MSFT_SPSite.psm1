function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Url,

        [Parameter(Mandatory = $true)]
        [System.String]
        $OwnerAlias,

        [Parameter()]
        [System.UInt32]
        $CompatibilityLevel,

        [Parameter()]
        [System.String]
        $ContentDatabase,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.String]
        $HostHeaderWebApplication,

        [Parameter()]
        [System.UInt32]
        $Language,

        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $OwnerEmail,

        [Parameter()]
        [System.String]
        $QuotaTemplate,

        [Parameter()]
        [System.String]
        $SecondaryEmail,

        [Parameter()]
        [System.String]
        $SecondaryOwnerAlias,

        [Parameter()]
        [System.String]
        $Template,

        [Parameter()]
        [System.Boolean]
        $CreateDefaultGroups = $true,

        [Parameter()]
        [ValidateSet("TenantAdministration", "None")]
        [System.String]
        $AdministrationSiteType,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting site collection $Url"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]
        $site = $null

        try
        {
            $centralAdminWebApp = [Microsoft.SharePoint.Administration.SPAdministrationWebApplication]::Local
            $centralAdminSite = Get-SPSite -Identity $centralAdminWebApp.Url

            $site = New-Object "Microsoft.SharePoint.SPSite" -ArgumentList @($params.Url, $centralAdminSite.SystemAccount.UserToken)
        }
        catch [System.Exception]
        {
        }

        if ($null -eq $site)
        {
            Write-Verbose "Site Collection not found"

            return @{
                Url                      = $params.Url
                OwnerAlias               = $null
                CompatibilityLevel       = $null
                ContentDatabase          = $null
                Description              = $null
                HostHeaderWebApplication = $null
                Language                 = $null
                Name                     = $null
                OwnerEmail               = $null
                QuotaTemplate            = $null
                SecondaryEmail           = $null
                SecondaryOwnerAlias      = $null
                Template                 = $null
                CreateDefaultGroups      = $null
            }
        }
        else
        {
            if ($site.HostHeaderIsSiteName)
            {
                $HostHeaderWebApplication = $site.WebApplication.Url
            }

            if ($null -eq $site.Owner)
            {
                $owner = $null
            }
            else
            {
                if ($site.WebApplication.UseClaimsAuthentication)
                {
                    $principal = New-SPClaimsPrincipal -Identity $site.Owner.UserLogin `
                        -IdentityType "EncodedClaim" `
                        -ErrorAction SilentlyContinue

                    if ($null -ne $principal)
                    {
                        $owner = $principal.Value
                    }
                    else
                    {
                        $owner = $site.Owner.UserLogin
                    }
                }
                else
                {
                    $owner = $site.Owner.UserLogin
                }
            }

            if ($null -eq $site.SecondaryContact)
            {
                $secondaryOwner = $null
            }
            else
            {
                if ($site.WebApplication.UseClaimsAuthentication)
                {
                    $secondaryOwner = (New-SPClaimsPrincipal -Identity $site.SecondaryContact.UserLogin `
                            -IdentityType "EncodedClaim").Value
                }
                else
                {
                    $secondaryOwner = $site.SecondaryContact.UserLogin
                }
            }

            $admService = Get-SPDscContentService
            $quota = ($admService.QuotaTemplates | `
                        Where-Object -FilterScript {
                        $_.QuotaID -eq $site.Quota.QuotaID
                    }).Name

            $CreateDefaultGroups = $true
            if ($null -eq $site.RootWeb.AssociatedVisitorGroup -and
                $null -eq $site.RootWeb.AssociatedMemberGroup -and
                $null -eq $site.RootWeb.AssociatedOwnerGroup)
            {
                $CreateDefaultGroups = $false
            }

            return @{
                Url                      = $site.Url
                OwnerAlias               = $owner
                CompatibilityLevel       = $site.CompatibilityLevel
                ContentDatabase          = $site.ContentDatabase.Name
                Description              = $site.RootWeb.Description
                HostHeaderWebApplication = $HostHeaderWebApplication
                Language                 = $site.RootWeb.Language
                Name                     = $site.RootWeb.Name
                OwnerEmail               = $site.Owner.Email
                QuotaTemplate            = $quota
                SecondaryEmail           = $site.SecondaryContact.Email
                SecondaryOwnerAlias      = $secondaryOwner
                Template                 = "$($site.RootWeb.WebTemplate)#$($site.RootWeb.Configuration)"
                CreateDefaultGroups      = $CreateDefaultGroups
                AdministrationSiteType   = $site.AdministrationSiteType
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
        $Url,

        [Parameter(Mandatory = $true)]
        [System.String]
        $OwnerAlias,

        [Parameter()]
        [System.UInt32]
        $CompatibilityLevel,

        [Parameter()]
        [System.String]
        $ContentDatabase,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.String]
        $HostHeaderWebApplication,

        [Parameter()]
        [System.UInt32]
        $Language,

        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $OwnerEmail,

        [Parameter()]
        [System.String]
        $QuotaTemplate,

        [Parameter()]
        [System.String]
        $SecondaryEmail,

        [Parameter()]
        [System.String]
        $SecondaryOwnerAlias,

        [Parameter()]
        [System.String]
        $Template,

        [Parameter()]
        [System.Boolean]
        $CreateDefaultGroups = $true,

        [Parameter()]
        [ValidateSet("TenantAdministration", "None")]
        [System.String]
        $AdministrationSiteType,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting site collection $Url"

    if ($PSBoundParameters.ContainsKey("CreateDefaultGroups") -eq $false)
    {
        $PSBoundParameters.CreateDefaultGroups = $true
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters

    $null = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters, $CurrentValues) `
        -ScriptBlock {
        $params = $args[0]
        $CurrentValues = $args[1]
        $doCreateDefaultGroups = $false

        $params.Remove("InstallAccount") | Out-Null

        $CreateDefaultGroups = $params.CreateDefaultGroups
        $params.Remove("CreateDefaultGroups") | Out-Null

        $site = Get-SPSite -Identity $params.Url -ErrorAction SilentlyContinue

        if ($null -eq $site)
        {
            Write-Verbose -Message ("Starting New-SPSite with the following parameters: " + `
                    "$(Convert-SPDscHashtableToString $params)")
            $site = New-SPSite @params
            if ($CreateDefaultGroups -eq $true)
            {
                $doCreateDefaultGroups = $true

            }
            else
            {
                Write-Verbose -Message ("CreateDefaultGroups set to false. The default " + `
                        "SharePoint groups will not be created")
            }
        }
        else
        {
            $newParams = @{
                Identity = $params.Url
            }

            if ($params.ContainsKey("QuotaTemplate") -eq $true)
            {
                if ($params.QuotaTemplate -ne $CurrentValues.QuotaTemplate)
                {
                    $newParams.QuotaTemplate = $params.QuotaTemplate
                }
            }

            $centralAdminWebApp = [Microsoft.SharePoint.Administration.SPAdministrationWebApplication]::Local
            $centralAdminSite = Get-SPSite -Identity $centralAdminWebApp.Url
            $systemAccountSite = New-Object "Microsoft.SharePoint.SPSite" -ArgumentList @($site.Id, $centralAdminSite.SystemAccount.UserToken)

            if ($params.OwnerAlias -ne $CurrentValues.OwnerAlias)
            {
                Write-Verbose -Message "Updating owner to $($params.OwnerAlias)"
                try
                {
                    $confirmedUsername = $systemAccountSite.RootWeb.EnsureUser($params.OwnerAlias)
                    $systemAccountSite.Owner = $confirmedUsername
                }
                catch
                {
                    Write-Output "Cannot resolve user $($params.OwnerAlias) as OwnerAlias"
                }
            }

            if ($params.ContainsKey("SecondaryOwnerAlias") -eq $true -and `
                    $params.SecondaryOwnerAlias -ne $CurrentValues.SecondaryOwnerAlias)
            {
                Write-Verbose -Message "Updating secondary owner to $($params.SecondaryOwnerAlias)"
                try
                {
                    $confirmedUsername = $systemAccountSite.RootWeb.EnsureUser($params.SecondaryOwnerAlias)
                    $systemAccountSite.SecondaryContact = $confirmedUsername
                }
                catch
                {
                    Write-Verbose -Message ("Cannot resolve user $($params.SecondaryOwnerAlias) " + `
                            "as SecondaryOwnerAlias")
                }
            }

            if ($params.ContainsKey("AdministrationSiteType") -eq $true)
            {
                if ($params.AdministrationSiteType -ne $CurrentValues.AdministrationSiteType)
                {
                    $newParams.AdministrationSiteType = $params.AdministrationSiteType
                }
            }

            if ($newParams.Count -gt 1)
            {
                Write-Verbose -Message "Updating existing site collection"
                Write-Verbose -Message ("Starting Set-SPSite with the following parameters: " + `
                        "$(Convert-SPDscHashtableToString $newParams)")
                Set-SPSite @newParams
            }

            if ($CurrentValues.CreateDefaultGroups -eq $false)
            {
                if ($CreateDefaultGroups -eq $true)
                {
                    $doCreateDefaultGroups = $true
                }
                else
                {
                    Write-Verbose -Message ("CreateDefaultGroups set to false. The default " + `
                            "SharePoint groups will not be created")
                }
            }
        }

        if ($doCreateDefaultGroups -eq $true)
        {
            Write-Verbose -Message ("Creating default groups")

            $centralAdminWebApp = [Microsoft.SharePoint.Administration.SPAdministrationWebApplication]::Local
            $centralAdminSite = Get-SPSite -Identity $centralAdminWebApp.Url
            $systemAccountSite = New-Object "Microsoft.SharePoint.SPSite" -ArgumentList @($site.Id, $centralAdminSite.SystemAccount.UserToken)

            if ($null -eq $systemAccountSite.SecondaryContact)
            {
                $secondaryOwnerLogin = $null
            }
            else
            {
                $secondaryOwnerLogin = $systemAccountSite.SecondaryContact.UserLogin;
            }

            $systemAccountSite.RootWeb.CreateDefaultAssociatedGroups($systemAccountSite.Owner.UserLogin,
                $secondaryOwnerLogin,
                $null)
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
        $Url,

        [Parameter(Mandatory = $true)]
        [System.String]
        $OwnerAlias,

        [Parameter()]
        [System.UInt32]
        $CompatibilityLevel,

        [Parameter()]
        [System.String]
        $ContentDatabase,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.String]
        $HostHeaderWebApplication,

        [Parameter()]
        [System.UInt32]
        $Language,

        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $OwnerEmail,

        [Parameter()]
        [System.String]
        $QuotaTemplate,

        [Parameter()]
        [System.String]
        $SecondaryEmail,

        [Parameter()]
        [System.String]
        $SecondaryOwnerAlias,

        [Parameter()]
        [System.String]
        $Template,

        [Parameter()]
        [System.Boolean]
        $CreateDefaultGroups = $true,

        [Parameter()]
        [ValidateSet("TenantAdministration", "None")]
        [System.String]
        $AdministrationSiteType,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing site collection $Url"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($PSBoundParameters.ContainsKey("CreateDefaultGroups") -eq $true -and `
            $CreateDefaultGroups -eq $true)
    {
        if ($CurrentValues.CreateDefaultGroups -ne $true)
        {
            $message = "The default site groups are not configured as desired."
            Write-Verbose -Message $message
            Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

            Write-Verbose -Message "Test-TargetResource returned false"
            return $false
        }
    }

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("Url",
        "QuotaTemplate",
        "OwnerAlias",
        "SecondaryOwnerAlias",
        "AdministrationSiteType")

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $spSites = Get-SPSite -Limit All
    $siteGuid = $null
    $siteTitle = $null
    $dependsOnItems = @()
    $sc = Get-SPDscContentService
    $Content = ''

    $i = 1
    $total = $spSites.Length

    $ParentModueBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModueBase -ChildPath "\DSCResources\MSFT_SPSite\MSFT_SPSite.psm1" -Resolve

    foreach ($spSite in $spSites)
    {
        try
        {
            if (!$spSite.IsSiteMaster)
            {
                $siteTitle = $spSite.RootWeb.Title
                $siteUrl = $spSite.Url
                Write-Host "Scanning SPSite [$i/$total] {$siteUrl}"

                $dependsOnItems = @("[SPWebApplication]$($spSite.WebApplication.Name.Replace(' ', ''))")
                $params = Get-DSCFakeParameters -ModulePath $module
                $siteGuid = [System.Guid]::NewGuid().toString()
                $siteTitle = $spSite.RootWeb.Title
                if (!$siteTitle)
                {
                    $siteTitle = "SiteCollection"
                }
                $partialContent = "        SPSite " + $siteGuid + "`r`n"
                $partialContent += "        {`r`n"
                $params.Url = $spSite.Url
                $results = Get-TargetResource @params

                <# WA - Somehow the WebTemplateID returned for App Catalog is 18, but the template is APPCATALOG#0 #>
                if ($results.Template -eq "APPCATALOG#18")
                {
                    $results.Template = "APPCATALOG#0"
                }
                <# If the current Quota ID is 0, it means no quota templates were used. Remove param in that case. #>
                if ($spSite.Quota.QuotaID -eq 0)
                {
                    $results.Remove("QuotaTemplate")
                }
                else
                {
                    $quotaTemplateName = $sc.QuotaTemplates | Where-Object { $_.QuotaId -eq $spsite.Quota.QuotaID }
                    if ($null -ne $quotaTemplateName -and $null -ne $quotaTemplateName.Name)
                    {
                        if ($Global:DH_SPQUOTATEMPLATE.ContainsKey($quotaTemplateName.Name))
                        {
                            $dependsOnItems += "[SPQuotaTemplate]$($Global:DH_SPQUOTATEMPLATE.Item($quotaTemplateName.Name))"
                        }
                    }
                    else
                    {
                        $results.Remove("QuotaTemplate")
                    }
                }
                if (!$results.Get_Item("SecondaryOwnerAlias"))
                {
                    $results.Remove("SecondaryOwnerAlias")
                }
                if (!$results.Get_Item("SecondaryEmail"))
                {
                    $results.Remove("SecondaryEmail")
                }
                if (!$results.Get_Item("OwnerEmail"))
                {
                    $results.Remove("OwnerEmail")
                }
                if (!$results.Get_Item("HostHeaderWebApplication"))
                {
                    $results.Remove("HostHeaderWebApplication")
                }
                if (!$results.Get_Item("Name"))
                {
                    $results.Remove("Name")
                }
                if (!$results.Get_Item("Description"))
                {
                    $results.Remove("Description")
                }
                else
                {
                    $results.Description = $results.Description.Replace("`"", "'").Replace("`r`n", ' `
                    ')
                }
                $dependsOnClause = Get-DSCDependsOnBlock($dependsOnItems)
                $results = Repair-Credentials -results $results

                $ownerAlias = Get-Credentials -UserName $results.OwnerAlias
                $plainTextUser = $false;
                if (!$ownerAlias)
                {
                    if (!$Global:AllUsers.Contains($results.OwnerAlias) -and $results.OwnerAlias -ne "")
                    {
                        $Global:AllUsers += $results.OwnerAlias
                    }
                    $plainTextUser = $true
                    $ownerAlias = $results.OwnerAlias
                }
                $currentBlock = ""
                if ($null -ne $ownerAlias -and !$plainTextUser)
                {
                    $results.OwnerAlias = (Resolve-Credentials -UserName $results.OwnerAlias) + ".UserName"
                }

                if ($results.ContainsKey("SecondaryOwnerAlias"))
                {
                    $secondaryOwner = Get-Credentials -UserName $results.SecondaryOwnerAlias
                    if ($null -ne $secondaryOwner)
                    {
                        $results.SecondaryOwnerAlias = (Resolve-Credentials -UserName $results.SecondaryOwnerAlias) + ".UserName"
                    }
                    else
                    {
                        if (!$Global:AllUsers.Contains($results.SecondaryOwnerAlias) -and $results.SecondaryOwnerAlias -ne "")
                        {
                            $Global:AllUsers += $results.SecondaryOwnerAlias
                        }
                        $secondaryOwner = $results.SecondaryOwnerAlias
                    }
                }
                $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
                $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"

                if ($null -ne $results.SecondaryOwnerAlias -and $results.SecondaryOwnerAlias.StartsWith("`$"))
                {
                    $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "SecondaryOwnerAlias"
                }
                if ($null -ne $results.OwnerAlias -and $results.OwnerAlias.StartsWith("`$"))
                {
                    $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "OwnerAlias"
                }
                $partialContent += $currentBlock
                $partialContent += "            DependsOn =  " + $dependsOnClause + "`r`n"
                $partialContent += "        }`r`n"

                $properties = @{
                    URL = $SPSite.URL
                }
                $partialContent += Read-TargetResource -ResourceName 'SPSiteUrl' `
                    -ExportParams $properties

                <# Nik20170112 - There are restrictions preventing this setting from being applied if the PsDscRunAsCredential parameter is not used.
                            Since this is only available in WMF 5, we check to see if the node farm we are extracting the configuration from is
                            running at least PowerShell v5 before reading the Site Collection level SPDesigner settings. #>
                if ($PSVersionTable.PSVersion.Major -ge 5 -and $Global:ExtractionModeValue -ge 2)
                {
                    $properties = @{
                        URL   = $SPSite.URL
                        Scope = "SiteCollection"
                    }
                    $partialContent += Read-TargetResource -Resource 'SPDesignerSettings' `
                        -ExportParams $properties
                }

                <# SPSite Feature Section #>
                if (($Global:ExtractionModeValue -eq 3 -and $Quiet) -or $Global:ComponentsToExtract.Contains("SPFeature"))
                {
                    $properties = @{
                        Scope     = "Site"
                        Url       = $SpSite.Url
                        DependsOn = "[SPSite]$($siteGuid)"
                    }
                    $partialContent += Read-TargetResource -ResourceName 'SPFeature' `
                        -ExportParams $properties
                }

                if (($Global:ExtractionModeValue -eq 3 -and $Quiet) -or $Global:ComponentsToExtract.Contains("SPWeb"))
                {
                    $properties = @{
                        Url       = $spSite.Url
                        DependsOn = "[SPSite]$($siteGuid)"
                    }
                    $partialContent += Read-TargetResource -ResourceName 'SPWeb' `
                        -ExportParams $properties
                }
            }
            $i++
        }
        catch
        {
            $_
            $Global:ErrorLog += "[Site Collection]" + $spSite.Url + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
        $i++
        $Content += $partialContent
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
