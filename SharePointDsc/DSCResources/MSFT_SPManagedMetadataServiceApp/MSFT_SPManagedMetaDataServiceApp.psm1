function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $ProxyName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

        [Parameter()]
        [System.String]
        $DatabaseServer,

        [Parameter()]
        [System.String]
        $DatabaseName,

        [Parameter()]
        [System.Boolean]
        $UseSQLAuthentication,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [Parameter()]
        [System.String[]]
        $TermStoreAdministrators,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.String]
        $ContentTypeHubUrl,

        [Parameter()]
        [System.UInt32]
        $DefaultLanguage,

        [Parameter()]
        [System.UInt32[]]
        $Languages,

        [Parameter()]
        [System.Boolean]
        $ContentTypePushdownEnabled,

        [Parameter()]
        [System.Boolean]
        $ContentTypeSyndicationEnabled,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting managed metadata service application $Name"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]

        $serviceApps = Get-SPServiceApplication -Name $params.Name `
            -ErrorAction SilentlyContinue
        $nullReturn = @{
            Name                    = $params.Name
            Ensure                  = "Absent"
            ApplicationPool         = $params.ApplicationPool
            TermStoreAdministrators = @()
        }

        if ($null -eq $serviceApps)
        {
            return $nullReturn
        }

        $serviceApp = $serviceApps | Where-Object -FilterScript {
            $_.GetType().FullName -eq "Microsoft.SharePoint.Taxonomy.MetadataWebServiceApplication"
        }

        if ($null -eq $serviceApp)
        {
            return $nullReturn
        }
        else
        {
            $serviceAppProxies = Get-SPServiceApplicationProxy -ErrorAction SilentlyContinue

            if ($params.ContainsKey("ProxyName") -eq $true)
            {
                $proxyName = $params.ProxyName
            }
            else
            {
                $proxyName = ""
            }

            if ($null -ne $serviceAppProxies)
            {
                $serviceAppProxy = $serviceAppProxies | Where-Object -FilterScript {
                    $serviceApp.IsConnected($_)
                }
                if ($null -ne $serviceAppProxy)
                {
                    $proxyName = $serviceAppProxy.Name
                }
            }

            $proxy = Get-SPMetadataServiceApplicationProxy -Identity $proxyName `
                -ErrorAction SilentlyContinue
            if ($null -ne $proxy)
            {
                $contentTypePushDownEnabled = $proxy.Properties["IsContentTypePushdownEnabled"]
                $contentTypeSyndicationEnabled = $proxy.Properties["IsNPContentTypeSyndicationEnabled"]
            }
            else
            {
                Write-Verbose "No SPMetadataServiceApplicationProxy with the name '$($proxyName)' was found. Please verify your Managed Metadata Service Application."
            }

            # Get the ContentTypeHubUrl value
            $hubUrl = ""
            try
            {
                $propertyFlags = [System.Reflection.BindingFlags]::Instance `
                    -bor [System.Reflection.BindingFlags]::NonPublic
                $defaultPartitionId = [Guid]::Parse("0C37852B-34D0-418e-91C6-2AC25AF4BE5B")

                $installedVersion = Get-SPDscInstalledProductVersion
                switch ($installedVersion.FileMajorPart)
                {
                    15
                    {
                        $propData = $serviceApp.GetType().GetMethods($propertyFlags)
                        $method = $propData | Where-Object -FilterScript {
                            $_.Name -eq "GetContentTypeSyndicationHubLocal"
                        }
                        $hubUrl = $method.Invoke($serviceApp, $defaultPartitionId).AbsoluteUri
                    }
                    16
                    {
                        $propData = $serviceApp.GetType().GetProperties($propertyFlags)
                        $dbMapperProp = $propData | Where-Object -FilterScript {
                            $_.Name -eq "DatabaseMapper"
                        }

                        $dbMapper = $dbMapperProp.GetValue($serviceApp)

                        $propData2 = $dbMapper.GetType().GetMethods($propertyFlags)
                        $cthubMethod = $propData2 | Where-Object -FilterScript {
                            $_.Name -eq "GetContentTypeSyndicationHubLocal"
                        }

                        $hubUrl = $cthubMethod.Invoke($dbMapper, $defaultPartitionId).AbsoluteUri
                    }
                    default
                    {
                        $message = ("Detected an unsupported major version of SharePoint. " + `
                                "SharePointDsc only supports SharePoint 2013, 2016 or 2019.")
                        Add-SPDscEvent -Message $message `
                            -EntryType 'Error' `
                            -EventID 100 `
                            -Source $eventSource
                        throw $message
                    }
                }

                if ($hubUrl)
                {
                    $hubUrl = $hubUrl.TrimEnd('/')
                }
                else
                {
                    $hubUrl = ""
                }
            }
            catch [System.Exception]
            {
                $hubUrl = ""
            }

            $centralAdminSite = Get-SPWebApplication -IncludeCentralAdministration `
            | Where-Object -FilterScript {
                $_.IsAdministrationWebApplication -eq $true
            }
            $session = Get-SPTaxonomySession -Site $centralAdminSite.Url

            $currentAdmins = @()
            $termStoreDefaultLanguage = $null
            $termStoreLanguages = @()

            if ($null -ne $session)
            {
                if ($null -ne $proxyName)
                {
                    $termStore = $session.TermStores[$proxyName]

                    if ($null -ne $termstore)
                    {
                        $termStore.TermStoreAdministrators | ForEach-Object -Process {
                            $name = [string]::Empty
                            if ($_.IsWindowsAuthenticationMode -eq $true)
                            {
                                $name = $_.PrincipalName
                            }
                            else
                            {
                                $name = (New-SPClaimsPrincipal -Identity $_.PrincipalName -IdentityType EncodedClaim).Value
                                if ($name -match "^s-1-[0-59]-\d+-\d+-\d+-\d+-\d+")
                                {
                                    $name = Resolve-SPDscSecurityIdentifier -SID $name
                                }
                            }
                            $currentAdmins += $name
                        }
                        $termStoreDefaultLanguage = $termStore.DefaultLanguage
                        $termStoreLanguages = $termStore.Languages
                    }
                    else
                    {
                        Write-Verbose "No termstore matching to the proxy name '$proxyName' was found"
                    }
                }
                else
                {
                    Write-Verbose "No valid proxy for $($params.Name) was found"
                }
            }
            else
            {
                Write-Verbose "Could not get taxonomy session. Please check if the managed metadata service is started."
            }

            return @{
                Name                          = $serviceApp.DisplayName
                ProxyName                     = $proxyName
                Ensure                        = "Present"
                ApplicationPool               = $serviceApp.ApplicationPool.Name
                DatabaseName                  = $serviceApp.Database.Name
                DatabaseServer                = $serviceApp.Database.NormalizedDataSource
                TermStoreAdministrators       = $currentAdmins
                ContentTypeHubUrl             = $hubUrl
                DefaultLanguage               = $termStoreDefaultLanguage
                Languages                     = $termStoreLanguages
                ContentTypePushdownEnabled    = $contentTypePushDownEnabled
                ContentTypeSyndicationEnabled = $contentTypeSyndicationEnabled
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
        $Name,

        [Parameter()]
        [System.String]
        $ProxyName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

        [Parameter()]
        [System.String]
        $DatabaseServer,

        [Parameter()]
        [System.String]
        $DatabaseName,

        [Parameter()]
        [System.Boolean]
        $UseSQLAuthentication,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [Parameter()]
        [System.String[]]
        $TermStoreAdministrators,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.String]
        $ContentTypeHubUrl,

        [Parameter()]
        [System.UInt32]
        $DefaultLanguage,

        [Parameter()]
        [System.UInt32[]]
        $Languages,

        [Parameter()]
        [System.Boolean]
        $ContentTypePushdownEnabled,

        [Parameter()]
        [System.Boolean]
        $ContentTypeSyndicationEnabled,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting managed metadata service application $Name"

    $result = Get-TargetResource @PSBoundParameters

    $pName = "$Name Proxy"
    if ($null -ne $result.ProxyName)
    {
        $pName = $result.ProxyName
    }

    if ($PSBoundParameters.ContainsKey("ProxyName"))
    {
        $pName = $ProxyName
    }

    if ($result.Ensure -eq "Absent" -and $Ensure -eq "Present")
    {
        Write-Verbose -Message "Creating Managed Metadata Service Application $Name"
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments ($PSBoundParameters, $pName) `
            -ScriptBlock {
            $params = $args[0]
            $pName = $args[1]

            $newParams = @{
                Name            = $params.Name
                ApplicationPool = $params.ApplicationPool
                DatabaseServer  = $params.DatabaseServer
                DatabaseName    = $params.DatabaseName
            }

            if ($params.ContainsKey("ContentTypeHubUrl") -eq $true)
            {
                $newParams.Add("HubUri", $params.ContentTypeHubUrl)
            }

            if ($params.useSQLAuthentication -eq $true)
            {
                Write-Verbose -Message "Using SQL authentication to create service application as `$useSQLAuthentication is set to $($params.useSQLAuthentication)."
                $newParams.Add("DatabaseCredentials", $params.DatabaseCredentials)
            }
            else
            {
                Write-Verbose -Message "`$useSQLAuthentication is false or not specified; using default Windows authentication."
            }

            $app = New-SPMetadataServiceApplication @newParams
            if ($null -ne $app)
            {
                New-SPMetadataServiceApplicationProxy -Name $pName `
                    -ServiceApplication $app `
                    -DefaultProxyGroup `
                    -ContentTypePushdownEnabled
            }
        }
        $result = Get-TargetResource @PSBoundParameters
    }

    if ($result.Ensure -eq "Present" -and $Ensure -eq "Present")
    {
        if ([string]::IsNullOrEmpty($ApplicationPool) -eq $false -and `
                $ApplicationPool -ne $result.ApplicationPool)
        {
            Write-Verbose -Message "Updating application pool of Managed Metadata Service Application $Name"
            Invoke-SPDscCommand -Credential $InstallAccount `
                -Arguments $PSBoundParameters `
                -ScriptBlock {
                $params = $args[0]

                $serviceApp = Get-SPServiceApplication -Name $params.Name `
                | Where-Object -FilterScript {
                    $_.GetType().FullName -eq "Microsoft.SharePoint.Taxonomy.MetadataWebServiceApplication"
                }
                $appPool = Get-SPServiceApplicationPool -Identity $params.ApplicationPool
                Set-SPMetadataServiceApplication -Identity $serviceApp -ApplicationPool $appPool
            }
        }

        if ($pName -ne $result.ProxyName)
        {
            Write-Verbose -Message "Updating Managed Metadata Service Application Proxy"
            Invoke-SPDscCommand -Credential $InstallAccount `
                -Arguments @($PSBoundParameters, $pName) `
                -ScriptBlock {
                $params = $args[0]
                $pName = $args[1]

                $serviceApps = Get-SPServiceApplication -Name $params.Name `
                    -ErrorAction SilentlyContinue
                $serviceApp = $serviceApps | Where-Object -FilterScript {
                    $_.GetType().FullName -eq "Microsoft.SharePoint.Taxonomy.MetadataWebServiceApplication"
                }

                $serviceAppProxies = Get-SPServiceApplicationProxy -ErrorAction SilentlyContinue
                if ($null -ne $serviceAppProxies)
                {
                    $serviceAppProxy = $serviceAppProxies | Where-Object -FilterScript {
                        $serviceApp.IsConnected($_)
                    }

                    if ($null -ne $serviceAppProxy)
                    {
                        Write-Verbose -Message "Updating Proxy Name from '$($result.ProxyName)' to '$pName'"
                        $serviceAppProxy.Name = $pName
                        $serviceAppProxy.Update()
                    }
                    else
                    {
                        Write-Verbose -Message "Creating Service Application Proxy '$pName'"
                        New-SPMetadataServiceApplicationProxy -Name $pName `
                            -ServiceApplication $serviceApp `
                            -DefaultProxyGroup `
                            -ContentTypePushdownEnabled
                    }
                }
            }
        }

        if (($PSBoundParameters.ContainsKey("ContentTypeHubUrl") -eq $true) `
                -and ($ContentTypeHubUrl.TrimEnd('/') -ne $result.ContentTypeHubUrl.TrimEnd('/')))
        {
            Write-Verbose -Message "Updating Content type hub for Managed Metadata Service Application $Name"
            Invoke-SPDscCommand -Credential $InstallAccount `
                -Arguments $PSBoundParameters `
                -ScriptBlock {
                $params = $args[0]

                $serviceApp = Get-SPServiceApplication -Name $params.Name `
                | Where-Object -FilterScript {
                    $_.GetType().FullName -eq "Microsoft.SharePoint.Taxonomy.MetadataWebServiceApplication"
                }
                Set-SPMetadataServiceApplication -Identity $serviceApp -HubUri $params.ContentTypeHubUrl
            }
        }

        if (($PSBoundParameters.ContainsKey("TermStoreAdministrators") -eq $true) `
                -and ($null -ne (Compare-Object -ReferenceObject $result.TermStoreAdministrators `
                        -DifferenceObject $TermStoreAdministrators)))
        {
            Write-Verbose -Message "Updating the term store administrators"
            # Update the term store administrators
            Invoke-SPDscCommand -Credential $InstallAccount `
                -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source, $result, $pName) `
                -ScriptBlock {

                $params = $args[0]
                $eventSource = $args[1]
                $currentValues = $args[2]
                $pName = $args[3]

                $centralAdminSite = Get-SPWebApplication -IncludeCentralAdministration `
                | Where-Object -FilterScript {
                    $_.IsAdministrationWebApplication -eq $true
                }
                $session = Get-SPTaxonomySession -Site $centralAdminSite.Url
                $termStore = $session.TermStores[$pName]

                if ($null -eq $termStore)
                {
                    $message = "The name of the Managed Metadata Service Application Proxy '$pName' did not return any termstore."
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $eventSource
                    throw $message
                }

                $changesToMake = Compare-Object -ReferenceObject $currentValues.TermStoreAdministrators `
                    -DifferenceObject $params.TermStoreAdministrators

                $changesToMake | ForEach-Object -Process {
                    $change = $_
                    switch ($change.SideIndicator)
                    {
                        "<="
                        {
                            # remove an existing user
                            if ($termStore.TermStoreAdministrators.PrincipalName -contains $change.InputObject)
                            {
                                $termStore.DeleteTermStoreAdministrator($change.InputObject)
                            }
                            else
                            {
                                $claimsToken = New-SPClaimsPrincipal -Identity $change.InputObject `
                                    -IdentityType WindowsSamAccountName
                                $termStore.DeleteTermStoreAdministrator($claimsToken.ToEncodedString())
                            }
                        }
                        "=>"
                        {
                            # add a new user
                            $termStore.AddTermStoreAdministrator($change.InputObject)
                        }
                        default
                        {
                            $message = "An unknown side indicator was found."
                            Add-SPDscEvent -Message $message `
                                -EntryType 'Error' `
                                -EventID 100 `
                                -Source $eventSource
                            throw $message
                        }
                    }
                }

                $termStore.CommitAll();
            }
        }

        if (($PSBoundParameters.ContainsKey("DefaultLanguage") -eq $true) `
                -and ($DefaultLanguage -ne $result.DefaultLanguage))
        {
            # The lanauge settings should be set to default
            Write-Verbose -Message "Updating the default language for Managed Metadata Service Application Proxy '$pName'"
            Invoke-SPDscCommand -Credential $InstallAccount `
                -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source, $pName) `
                -ScriptBlock {

                $params = $args[0]
                $eventSource = $args[1]
                $pName = $args[2]

                $centralAdminSite = Get-SPWebApplication -IncludeCentralAdministration `
                | Where-Object -FilterScript {
                    $_.IsAdministrationWebApplication -eq $true
                }
                $session = Get-SPTaxonomySession -Site $centralAdminSite.Url
                $termStore = $session.TermStores[$pName]

                if ($null -eq $termStore)
                {
                    $message = "The name of the Managed Metadata Service Application Proxy '$pName' did not return any termstore."
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $eventSource
                    throw $message
                }

                $permissionResult = $termStore.TermStoreAdministrators.DoesUserHavePermissions([Microsoft.SharePoint.Taxonomy.TaxonomyRights]::ManageTermStore)

                if (-not($permissionResult))
                {
                    $termStore.AddTermStoreAdministrator([Security.Principal.WindowsIdentity]::GetCurrent().Name)
                    $termStore.CommitAll()
                }

                $termStore.DefaultLanguage = $params.DefaultLanguage
                $termStore.CommitAll()

                if (-not ($permissionResult))
                {
                    $termStore.DeleteTermStoreAdministrator([Security.Principal.WindowsIdentity]::GetCurrent().Name)
                    $termStore.CommitAll()
                }
            }
        }

        if (($PSBoundParameters.ContainsKey("Languages") -eq $true) `
                -and ($null -ne (Compare-Object -ReferenceObject $result.Languages `
                        -DifferenceObject $Languages)))
        {
            Write-Verbose -Message "Updating working languages for Managed Metadata Service Application Proxy '$pName'"
            # Update the term store working languages
            Invoke-SPDscCommand -Credential $InstallAccount `
                -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source, $result, $pName) `
                -ScriptBlock {

                $params = $args[0]
                $eventSource = $args[1]
                $currentValues = $args[2]
                $pName = $args[3]

                $centralAdminSite = Get-SPWebApplication -IncludeCentralAdministration `
                | Where-Object -FilterScript {
                    $_.IsAdministrationWebApplication -eq $true
                }
                $session = Get-SPTaxonomySession -Site $centralAdminSite.Url
                $termStore = $session.TermStores[$pName]

                if ($null -eq $termStore)
                {
                    $message = "The name of the Managed Metadata Service Application Proxy '$pName' did not return any termstore."
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $eventSource
                    throw $message
                }

                $permissionResult = $termStore.TermStoreAdministrators.DoesUserHavePermissions([Microsoft.SharePoint.Taxonomy.TaxonomyRights]::ManageTermStore)

                if (-not($permissionResult))
                {
                    $termStore.AddTermStoreAdministrator([Security.Principal.WindowsIdentity]::GetCurrent().Name)
                    $termStore.CommitAll()
                }

                $changesToMake = Compare-Object -ReferenceObject $currentValues.Languages `
                    -DifferenceObject $params.Languages

                $changesToMake | ForEach-Object -Process {
                    $change = $_
                    switch ($change.SideIndicator)
                    {
                        "<="
                        {
                            # delete a working language
                            $termStore.DeleteLanguage($change.InputObject)
                        }
                        "=>"
                        {
                            # add a working language
                            $termStore.AddLanguage($change.InputObject)
                        }
                        default
                        {
                            $message = "An unknown side indicator was found."
                            Add-SPDscEvent -Message $message `
                                -EntryType 'Error' `
                                -EventID 100 `
                                -Source $eventSource
                            throw $message
                        }
                    }
                }

                $termStore.CommitAll();

                if (-not ($permissionResult))
                {
                    $termStore.DeleteTermStoreAdministrator([Security.Principal.WindowsIdentity]::GetCurrent().Name)
                    $termStore.CommitAll()
                }
            }
        }

        if (($PSBoundParameters.ContainsKey("ContentTypePushdownEnabled") -eq $true) `
                -and ($ContentTypePushdownEnabled -ne $result.ContentTypePushdownEnabled)
        )
        {
            Invoke-SPDscCommand -Credential $InstallAccount `
                -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source, $pName) `
                -ScriptBlock {
                $params = $args[0]
                $eventSource = $args[1]
                $pName = $args[2]

                $proxy = Get-SPMetadataServiceApplicationProxy -Identity $pName
                if ($null -ne $proxy)
                {
                    $proxy.Properties["IsContentTypePushdownEnabled"] = $params.ContentTypePushdownEnabled
                    $proxy.Update()
                }
                else
                {
                    $message = "No SPMetadataServiceApplicationProxy with the name '$($proxyName)' was found. Please verify your Managed Metadata Service Application."
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $eventSource
                    throw $message
                }
            }
        }

        if (($PSBoundParameters.ContainsKey("ContentTypeSyndicationEnabled") -eq $true) `
                -and ($ContentTypeSyndicationEnabled -ne $result.ContentTypeSyndicationEnabled)
        )
        {
            Invoke-SPDscCommand -Credential $InstallAccount `
                -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source, $pName) `
                -ScriptBlock {
                $params = $args[0]
                $eventSource = $args[1]
                $pName = $args[2]

                $proxy = Get-SPMetadataServiceApplicationProxy -Identity $pName
                if ($null -ne $proxy)
                {
                    $proxy.Properties["IsNPContentTypeSyndicationEnabled"] = $params.ContentTypeSyndicationEnabled
                    $proxy.Update()
                }
                else
                {
                    $message = "No SPMetadataServiceApplicationProxy with the name '$($proxyName)' was found. Please verify your Managed Metadata Service Application."
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $eventSource
                    throw $message
                }
            }
        }
    }

    if ($Ensure -eq "Absent")
    {
        # The service app should not exit
        Write-Verbose -Message "Removing Managed Metadata Service Application $Name"
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            $serviceApp = Get-SPServiceApplication -Name $params.Name | Where-Object -FilterScript {
                $_.GetType().FullName -eq "Microsoft.SharePoint.Taxonomy.MetadataWebServiceApplication"
            }

            $proxies = Get-SPServiceApplicationProxy
            foreach ($proxyInstance in $proxies)
            {
                if ($serviceApp.IsConnected($proxyInstance))
                {
                    $proxyInstance.Delete()
                }
            }

            Remove-SPServiceApplication -Identity $serviceApp -Confirm:$false
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

        [Parameter()]
        [System.String]
        $ProxyName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

        [Parameter()]
        [System.String]
        $DatabaseServer,

        [Parameter()]
        [System.String]
        $DatabaseName,

        [Parameter()]
        [System.Boolean]
        $UseSQLAuthentication,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [Parameter()]
        [System.String[]]
        $TermStoreAdministrators,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.String]
        $ContentTypeHubUrl,

        [Parameter()]
        [System.UInt32]
        $DefaultLanguage,

        [Parameter()]
        [System.UInt32[]]
        $Languages,

        [Parameter()]
        [System.Boolean]
        $ContentTypePushdownEnabled,

        [Parameter()]
        [System.Boolean]
        $ContentTypeSyndicationEnabled,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing managed metadata service application $Name"

    $PSBoundParameters.Ensure = $Ensure
    if ($PSBoundParameters.ContainsKey("ContentTypeHubUrl") -eq $true)
    {
        $PSBoundParameters.ContentTypeHubUrl = $ContentTypeHubUrl.TrimEnd('/')
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $valuesToCheck = @("ApplicationPool",
        "ContentTypeHubUrl"
        "ContentTypePushdownEnabled"
        "ContentTypeSyndicationEnabled"
        "DefaultLanguage"
        "Ensure",
        "Languages"
        "TermStoreAdministrators"
        "ProxyName")

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck $valuesToCheck

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    if (!(Get-PSSnapin Microsoft.SharePoint.Powershell -ErrorAction SilentlyContinue))
    {
        Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction 0
    }
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDSC" | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPManagedMetadataServiceApp\MSFT_SPManagedMetadataServiceApp.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module

    $mms = Get-SPServiceApplication | Where-Object { $_.GetType().Name -eq "MetadataWebServiceApplication" }
    if (Get-Command "Get-SPMetadataServiceApplication" -ErrorAction SilentlyContinue)
    {
        $i = 1
        $total = $mms.Length
        foreach ($mmsInstance in $mms)
        {
            try
            {
                if ($null -ne $mmsInstance)
                {
                    $serviceName = $mmsInstance.Name
                    Write-Host "Scanning Managed Metadata Service [$i/$total] {$serviceName}"

                    $params.Name = $serviceName
                    $PartialContent = "        SPManagedMetaDataServiceApp " + $serviceName.Replace(" ", "") + "`r`n"
                    $PartialContent += "        {`r`n"
                    $results = Get-TargetResource @params

                    <# WA - Issue with 1.6.0.0 where DB Aliases not returned in Get-TargetResource #>
                    $results["DatabaseServer"] = Get-SpDscDBForAlias -DatabaseName $results["DatabaseName"]
                    $results = Repair-Credentials -results $results

                    if (!$results.Languages)
                    {
                        $results.Remove("Languages")
                    }

                    $results.TermStoreAdministrators = Set-SPDscTermStoreAdministratorsBlock $results.TermStoreAdministrators

                    Add-ConfigurationDataEntry -Node "NonNodeData" -Key "DatabaseServer" -Value $results.DatabaseServer -Description "Name of the Database Server associated with the destination SharePoint Farm;"
                    $results.DatabaseServer = "`$ConfigurationData.NonNodeData.DatabaseServer"

                    $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
                    $currentBlock = Set-SPDscTermStoreAdministrators $currentBlock
                    $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "DatabaseServer"
                    $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
                    $PartialContent += $currentBlock
                    $PartialContent += "        }`r`n"
                    $Content += $PartialContent
                }
                $i++
            }
            catch
            {
                $_
                $Global:ErrorLog += "[Managed Metadata Service Application]" + $mmsInstance.DisplayName + "`r`n"
                $Global:ErrorLog += "$_`r`n`r`n"
            }
        }
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
