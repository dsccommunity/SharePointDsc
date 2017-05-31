function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  
        [System.String] 
        $Name,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $ProxyName,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $ApplicationPool,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $DatabaseServer,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $DatabaseName,

        [parameter(Mandatory = $false)]
        [System.String[]]
        $TermStoreAdministrators,

        [parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present",

        [parameter(Mandatory = $false)] 
        [System.String] 
        $ContentTypeHubUrl,

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Getting managed metadata service application $Name"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]
        
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

            # Get the ContentTypeHubUrl value
            $hubUrl = ""
            try 
            {
                $propertyFlags = [System.Reflection.BindingFlags]::Instance `
                                -bor [System.Reflection.BindingFlags]::NonPublic
                $defaultPartitionId = [Guid]::Parse("0C37852B-34D0-418e-91C6-2AC25AF4BE5B")

                $installedVersion = Get-SPDSCInstalledProductVersion
                switch ($installedVersion.FileMajorPart)
                {
                    15 {
                        $propData = $serviceApp.GetType().GetMethods($propertyFlags)
                        $method = $propData | Where-Object -FilterScript {
                            $_.Name -eq "GetContentTypeSyndicationHubLocal"
                        } 
                        $hubUrl = $method.Invoke($serviceApp, $defaultPartitionId).AbsoluteUri                    }
                    16 {
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
                    default {
                        throw ("Detected an unsupported major version of SharePoint. " + `
                               "SharePointDsc only supports SharePoint 2013 or 2016.")
                    }
                }

                if ($hubUrl)
                {
                    $hubUrl = $hubUrl.TrimEnd('/')
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
            
            $session.TermStores[0].TermStoreAdministrators | ForEach-Object -Process {
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

            return @{
                Name                    = $serviceApp.DisplayName
                ProxyName               = $proxyName
                Ensure                  = "Present"
                ApplicationPool         = $serviceApp.ApplicationPool.Name
                DatabaseName            = $serviceApp.Database.Name
                DatabaseServer          = $serviceApp.Database.Server.Name
                TermStoreAdministrators = $currentAdmins
                ContentTypeHubUrl       = $hubUrl
                InstallAccount          = $params.InstallAccount
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
        $Name,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $ProxyName,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $ApplicationPool,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $DatabaseServer,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $DatabaseName,

        [parameter(Mandatory = $false)]
        [System.String[]]
        $TermStoreAdministrators,

        [parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present",

        [parameter(Mandatory = $false)] 
        [System.String] 
        $ContentTypeHubUrl,

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount    
    )

    Write-Verbose -Message "Setting managed metadata service application $Name"

    $result = Get-TargetResource @PSBoundParameters

    if ($result.Ensure -eq "Absent" -and $Ensure -eq "Present") 
    { 
        Write-Verbose -Message "Creating Managed Metadata Service Application $Name"
        Invoke-SPDSCCommand -Credential $InstallAccount `
                            -Arguments $PSBoundParameters `
                            -ScriptBlock {
            $params = $args[0]
            
            if ($params.ContainsKey("Ensure")) 
            { 
                $params.Remove("Ensure") | Out-Null 
            }
            if ($params.ContainsKey("InstallAccount")) 
            { 
                $params.Remove("InstallAccount") | Out-Null 
            }
            if ($params.ContainsKey("TermStoreAdministrators")) 
            { 
                $params.Remove("TermStoreAdministrators") | Out-Null 
            }
            if ($params.ContainsKey("ContentTypeHubUrl")) 
            {
                $params.Add("HubUri", $params.ContentTypeHubUrl)
                $params.Remove("ContentTypeHubUrl")
            }
            if ($params.ContainsKey("ProxyName")) 
            { 
                $pName = $params.ProxyName
                $params.Remove("ProxyName") | Out-Null 
            }
            if ($null -eq $pName) {
                $pName = "$($params.Name) Proxy"
            }

            $app = New-SPMetadataServiceApplication @params 
            if ($null -ne $app)
            {
                New-SPMetadataServiceApplicationProxy -Name $pName `
                                                      -ServiceApplication $app `
                                                      -DefaultProxyGroup `
                                                      -ContentTypePushdownEnabled `
                                                      -DefaultKeywordTaxonomy `
                                                      -DefaultSiteCollectionTaxonomy
            }
        }
    }
    
    if ($result.Ensure -eq "Present" -and $Ensure -eq "Present") 
    {
        if ([string]::IsNullOrEmpty($ApplicationPool) -eq $false `
            -and $ApplicationPool -ne $result.ApplicationPool) 
        {
            Write-Verbose -Message "Updating Managed Metadata Service Application $Name"
            Invoke-SPDSCCommand -Credential $InstallAccount `
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

        if (($PSBoundParameters.ContainsKey("ContentTypeHubUrl") -eq $true) `
            -and ($ContentTypeHubUrl.TrimEnd('/') -ne $result.ContentTypeHubUrl.TrimEnd('/')))
        {
            Write-Verbose -Message "Updating Content type hub for Managed Metadata Service Application $Name"
            Invoke-SPDSCCommand -Credential $InstallAccount `
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
    }

    if ($Ensure -eq "Present" -and $PSBoundParameters.ContainsKey("TermStoreAdministrators") -eq $true)
    {
        # Update the term store administrators
        Invoke-SPDSCCommand -Credential $InstallAccount `
                            -Arguments @($PSBoundParameters, $result) `
                            -ScriptBlock {

            Write-Verbose -Message "Setting term store administrators"
            $params = $args[0]
            $currentValues = $args[1]

            $centralAdminSite = Get-SPWebApplication -IncludeCentralAdministration `
                                | Where-Object -FilterScript { 
                $_.IsAdministrationWebApplication -eq $true 
            }
            $session = Get-SPTaxonomySession -Site $centralAdminSite.Url
            $termStore = $session.TermStores[0]

            $changesToMake = Compare-Object -ReferenceObject $currentValues.TermStoreAdministrators `
                                            -DifferenceObject $params.TermStoreAdministrators
            
            $changesToMake | ForEach-Object -Process {
                $change = $_
                switch($change.SideIndicator)
                {
                    "<=" {
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
                    "=>" {
                        # add a new user
                        $termStore.AddTermStoreAdministrator($change.InputObject)
                    }
                    default {
                        throw "An unknown side indicator was found."
                    }
                }
            }

            $termStore.CommitAll();
        }
    }
    
    if ($Ensure -eq "Absent") 
    {
        # The service app should not exit
        Write-Verbose -Message "Removing Managed Metadata Service Application $Name"
        Invoke-SPDSCCommand -Credential $InstallAccount `
                            -Arguments $PSBoundParameters `
                            -ScriptBlock {
            $params = $args[0] 

            $serviceApp = Get-SPServiceApplication -Name $params.Name | Where-Object -FilterScript {
                $_.GetType().FullName -eq "Microsoft.SharePoint.Taxonomy.MetadataWebServiceApplication"  

            }

            $proxies = Get-SPServiceApplicationProxy
            foreach($proxyInstance in $proxies)
            {
                if($serviceApp.IsConnected($proxyInstance))
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
        [parameter(Mandatory = $true)]  
        [System.String] 
        $Name,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $ProxyName,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $ApplicationPool,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $DatabaseServer,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $DatabaseName,

        [parameter(Mandatory = $false)]
        [System.String[]]
        $TermStoreAdministrators,

        [parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present",

        [parameter(Mandatory = $false)] 
        [System.String] 
        $ContentTypeHubUrl,

        [parameter(Mandatory = $false)] 
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

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @("ApplicationPool", 
                                                     "ContentTypeHubUrl", 
                                                     "TermStoreAdministrators",
                                                     "Ensure")
}

Export-ModuleMember -Function *-TargetResource
