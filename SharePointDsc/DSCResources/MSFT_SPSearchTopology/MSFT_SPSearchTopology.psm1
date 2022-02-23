function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServiceAppName,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Admin,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Crawler,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $ContentProcessing,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $AnalyticsProcessing,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $QueryProcessing,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $IndexPartition,

        [Parameter(Mandatory = $true)]
        [System.String]
        $FirstPartitionDirectory
    )

    Write-Verbose -Message "Getting Search Topology for '$ServiceAppName'"

    $result = Invoke-SPDscCommand -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]
        $ConfirmPreference = 'None'

        $ssa = Get-SPEnterpriseSearchServiceApplication -Identity $params.ServiceAppName `
            -ErrorAction SilentlyContinue

        if ($null -eq $ssa)
        {
            return @{
                ServiceAppName          = $params.ServiceAppName
                Admin                   = $null
                Crawler                 = $null
                ContentProcessing       = $null
                AnalyticsProcessing     = $null
                QueryProcessing         = $null
                FirstPartitionDirectory = $null
                IndexPartition          = $null
            }
        }

        $currentTopology = $ssa.ActiveTopology

        $allServers = Get-SPServer | ForEach-Object -Process {
            return New-Object -TypeName System.Object | `
                    Add-Member -MemberType NoteProperty `
                    -Name Name `
                    -Value $_.Name `
                    -PassThru | `
                        Add-Member -MemberType NoteProperty `
                        -Name Id `
                        -Value $_.Id `
                        -PassThru
                }

                $allComponents = Get-SPEnterpriseSearchComponent -SearchTopology $currentTopology `
                    -ErrorAction SilentlyContinue

                $AdminComponents = @()
                $AdminComponents += ($allComponents | Where-Object -FilterScript {
                        ($_.GetType().Name -eq "AdminComponent")
                    }).ServerId | ForEach-Object -Process {
                    $serverId = $_
                    $server = $allServers | Where-Object -FilterScript {
                        $_.Id -eq $serverId
                    } | Select-Object -First 1
                    return $server.Name
                }

        $CrawlComponents = @()
        $CrawlComponents += ($allComponents | Where-Object -FilterScript {
                ($_.GetType().Name -eq "CrawlComponent")
            }).ServerId | ForEach-Object -Process {
            $serverId = $_
            $server = $allServers | Where-Object -FilterScript {
                $_.Id -eq $serverId
            } | Select-Object -First 1
            return $server.Name
        }

        $ContentProcessingComponents = @()
        $ContentProcessingComponents += ($allComponents | Where-Object -FilterScript {
                ($_.GetType().Name -eq "ContentProcessingComponent")
            }).ServerId | ForEach-Object -Process {
            $serverId = $_
            $server = $allServers | Where-Object -FilterScript {
                $_.Id -eq $serverId
            } | Select-Object -First 1
            return $server.Name
        }

        $AnalyticsProcessingComponents = @()
        $AnalyticsProcessingComponents += ($allComponents | Where-Object -FilterScript {
                ($_.GetType().Name -eq "AnalyticsProcessingComponent")
            }).ServerId | ForEach-Object -Process {
            $serverId = $_
            $server = $allServers | Where-Object -FilterScript {
                $_.Id -eq $serverId
            } | Select-Object -First 1
            return $server.Name
        }

        $QueryProcessingComponents = @()
        $QueryProcessingComponents += ($allComponents | Where-Object -FilterScript {
                ($_.GetType().Name -eq "QueryProcessingComponent")
            }).ServerId | ForEach-Object -Process {
            $serverId = $_
            $server = $allServers | Where-Object -FilterScript {
                $_.Id -eq $serverId
            } | Select-Object -First 1
            return $server.Name
        }

        $IndexComponents = @()
        $IndexComponents += ($allComponents | Where-Object -FilterScript {
                ($_.GetType().Name -eq "IndexComponent") -and `
                    $_.IndexPartitionOrdinal -eq 0
            }).ServerId | ForEach-Object -Process {
            $serverId = $_
            $server = $allServers | Where-Object -FilterScript {
                $_.Id -eq $serverId
            } | Select-Object -First 1
            return $server.Name
        }

        $domain = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain

        $firstPartition = $null
        $enterpriseSearchServiceInstance = Get-SPEnterpriseSearchServiceInstance
        if ($null -ne $enterpriseSearchServiceInstance)
        {
            $ssiComponents = $enterpriseSearchServiceInstance.Components
            if ($null -ne $ssiComponents)
            {
                if ($ssiComponents.Length -gt 1)
                {
                    $ssiComponents = $ssiComponents[0]
                }

                if ($ssiComponents.IndexLocation.GetType().Name -eq "String")
                {
                    $firstPartition = $ssiComponents.IndexLocation
                }
                elseif ($ssiComponents.IndexLocation.GetType().Name -eq "Object[]")
                {
                    $firstPartition = $ssiComponents.IndexLocation[0]
                }
            }
        }

        return @{
            ServiceAppName          = $params.ServiceAppName
            Admin                   = $AdminComponents -replace ".$domain"
            Crawler                 = $CrawlComponents -replace ".$domain"
            ContentProcessing       = $ContentProcessingComponents -replace ".$domain"
            AnalyticsProcessing     = $AnalyticsProcessingComponents -replace ".$domain"
            QueryProcessing         = $QueryProcessingComponents -replace ".$domain"
            FirstPartitionDirectory = $firstPartition
            IndexPartition          = $IndexComponents -replace ".$domain"
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
        $ServiceAppName,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Admin,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Crawler,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $ContentProcessing,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $AnalyticsProcessing,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $QueryProcessing,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $IndexPartition,

        [Parameter(Mandatory = $true)]
        [System.String]
        $FirstPartitionDirectory
    )

    Write-Verbose -Message "Setting Search Topology for '$ServiceAppName'"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Invoke-SPDscCommand -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source, $CurrentValues) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]
        $CurrentValues = $args[2]

        $ConfirmPreference = 'None'

        $AllSearchServers = @()
        $AllSearchServers += ($params.Admin | Where-Object -FilterScript {
                ($AllSearchServers -contains $_) -eq $false
            })
        $AllSearchServers += ($params.Crawler | Where-Object -FilterScript {
                ($AllSearchServers -contains $_) -eq $false
            })
        $AllSearchServers += ($params.ContentProcessing | Where-Object -FilterScript {
                ($AllSearchServers -contains $_) -eq $false
            })
        $AllSearchServers += ($params.AnalyticsProcessing | Where-Object -FilterScript {
                ($AllSearchServers -contains $_) -eq $false
            })
        $AllSearchServers += ($params.QueryProcessing | Where-Object -FilterScript {
                ($AllSearchServers -contains $_) -eq $false
            })
        $AllSearchServers += ($params.IndexPartition | Where-Object -FilterScript {
                ($AllSearchServers -contains $_) -eq $false
            })

        # Ensure the search service instance is running on all servers
        foreach ($searchServer in $AllSearchServers)
        {
            if ($searchServer -like '*.*')
            {
                Write-Verbose -Message "Server name specified in FQDN, extracting just server name."
                $searchServer = $searchServer.Split('.')[0]
            }

            $searchService = Get-SPEnterpriseSearchServiceInstance -Identity $searchServer `
                -ErrorAction SilentlyContinue
            if ($null -eq $searchService)
            {
                $domain = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain
                $searchServer = "$searchServer.$domain"
                $searchService = Get-SPEnterpriseSearchServiceInstance -Identity $searchServer
            }

            if (($searchService.Status -eq "Offline") -or ($searchService.Status -eq "Disabled"))
            {
                Write-Verbose -Message "Start Search Service Instance"
                Start-SPEnterpriseSearchServiceInstance -Identity $searchServer
            }

            # Wait for Search Service Instance to come online
            $loopCount = 0
            $online = Get-SPEnterpriseSearchServiceInstance -Identity $searchServer
            while ($online.Status -ne "Online" -and $loopCount -lt 15)
            {
                $online = Get-SPEnterpriseSearchServiceInstance -Identity $searchServer
                Write-Verbose -Message ("$([DateTime]::Now.ToShortTimeString()) - Waiting for " + `
                        "search service instance to start on $searchServer " + `
                        "(waited $loopCount of 15 minutes)")
                $loopCount++
                Start-Sleep -Seconds 60
            }
        }

        # Create the index partition directory on each remote server
        foreach ($IndexPartitionServer in $params.IndexPartition)
        {
            $networkPath = "\\$IndexPartitionServer\" + `
                $params.FirstPartitionDirectory.Replace(":\", "$\")
            try
            {
                $null = New-Item -Path $networkPath `
                    -ItemType Directory `
                    -Force `
                    -ErrorAction Stop
            }
            catch
            {
                Write-Verbose -Message ("Unable to create folder {$($params.FirstPartitionDirectory)} " + `
                        "on {$IndexPartitionServer}.")
                Write-Verbose -Message "  Error: $($_.Exception.Message)"
            }
        }

        # Get all service service instances to assign topology components to
        $AllSearchServiceInstances = @{ }
        foreach ($server in $AllSearchServers)
        {
            if ($server -like '*.*')
            {
                Write-Verbose -Message "Server name specified in FQDN, extracting just server name."
                $server = $server.Split('.')[0]
            }

            $serverName = $server
            $serviceToAdd = Get-SPEnterpriseSearchServiceInstance -Identity $server `
                -ErrorAction SilentlyContinue
            if ($null -eq $serviceToAdd)
            {
                $domain = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain
                $server = "$server.$domain"
                $serviceToAdd = Get-SPEnterpriseSearchServiceInstance -Identity $server
            }
            if ($null -eq $serviceToAdd)
            {
                $message = "Unable to locate a search service instance on $serverName"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
                throw $message
            }
            $AllSearchServiceInstances.Add($server, $serviceToAdd)
        }

        # Get current topology and prepare a new one
        $ssa = Get-SPEnterpriseSearchServiceApplication -Identity $params.ServiceAppName
        if ($null -eq $ssa)
        {
            $message = "Search service applications '$($params.ServiceAppName)' was not found"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }
        $currentTopology = $ssa.ActiveTopology
        $newTopology = New-SPEnterpriseSearchTopology -SearchApplication $ssa `
            -Clone `
            -SearchTopology $currentTopology

        $componentTypes = @{
            Admin               = "AdminComponent"
            Crawler             = "CrawlComponent"
            ContentProcessing   = "ContentProcessingComponent"
            AnalyticsProcessing = "AnalyticsProcessingComponent"
            QueryProcessing     = "QueryProcessingComponent"
            IndexPartition      = "IndexComponent"
        }

        $domain = "." + (Get-CimInstance -ClassName Win32_ComputerSystem).Domain

        # Build up the topology changes for each object type
        @("Admin",
            "Crawler",
            "ContentProcessing",
            "AnalyticsProcessing",
            "QueryProcessing",
            "IndexPartition") | ForEach-Object -Process {

            $CurrentSearchProperty = $_
            Write-Verbose "Setting components for '$CurrentSearchProperty' property"

            if ($null -eq $CurrentValues.$CurrentSearchProperty)
            {
                $ComponentsToAdd = $params.$CurrentSearchProperty
            }
            else
            {
                $ComponentsToAdd = $params.$CurrentSearchProperty | Where-Object -FilterScript {
                    ($CurrentValues.$CurrentSearchProperty -contains $_ -eq $false) -and `
                    ($CurrentValues.$CurrentSearchProperty -contains ($_ -replace $domain) -eq $false)
                }

                $ComponentsToRemove = $CurrentValues.$CurrentSearchProperty | Where-Object -FilterScript {
                    ($params.$CurrentSearchProperty -contains $_ -eq $false) -and `
                    ($params.$CurrentSearchProperty -contains ($_ + $domain) -eq $false)
                }
            }

            foreach ($ComponentToAdd in $ComponentsToAdd)
            {
                Write-Verbose -Message "Processing Search Topology roles for '$ComponentToAdd'"

                # FIND SERVICE INSTANCE
                if ($AllSearchServiceInstances.ContainsKey($ComponentToAdd))
                {
                    $serviceInstance = $AllSearchServiceInstances.$ComponentToAdd
                }
                elseif ($AllSearchServiceInstances.ContainsKey($ComponentToAdd + $domain))
                {
                    $serviceInstance = $AllSearchServiceInstances.($ComponentToAdd + $domain)
                }
                else
                {
                    $message = ("Search service instance for component '$ComponentToAdd' was not " + `
                            "found. Only found components on '$($ComponentsToAdd.Keys -join ", ")'")
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $eventSource
                    throw $message
                }

                $NewComponentParams = @{
                    SearchTopology        = $newTopology
                    SearchServiceInstance = $serviceInstance
                }
                switch ($componentTypes.$CurrentSearchProperty)
                {
                    "AdminComponent"
                    {
                        Write-Verbose -Message "Adding $ComponentToAdd to run an AdminComponent"
                        $null = New-SPEnterpriseSearchAdminComponent @NewComponentParams
                    }
                    "CrawlComponent"
                    {
                        Write-Verbose -Message "Adding $ComponentToAdd to run a CrawlComponent"
                        $null = New-SPEnterpriseSearchCrawlComponent @NewComponentParams
                    }
                    "ContentProcessingComponent"
                    {
                        Write-Verbose -Message "Adding $ComponentToAdd to run a ContentProcessingComponent"
                        $null = New-SPEnterpriseSearchContentProcessingComponent @NewComponentParams
                    }
                    "AnalyticsProcessingComponent"
                    {
                        Write-Verbose -Message "Adding $ComponentToAdd to run an AnalyticsProcessingComponent"
                        $null = New-SPEnterpriseSearchAnalyticsProcessingComponent @NewComponentParams
                    }
                    "QueryProcessingComponent"
                    {
                        Write-Verbose -Message "Adding $ComponentToAdd to run a QueryComponent"
                        $null = New-SPEnterpriseSearchQueryProcessingComponent @NewComponentParams
                    }
                    "IndexComponent"
                    {
                        Write-Verbose -Message "Adding $ComponentToAdd to run an IndexComponent"
                        $indexServer = (Get-SPServer $ComponentToAdd).Name
                        $indexComponent = (New-Object Microsoft.Office.Server.Search.Administration.Topology.IndexComponent $indexServer, 0);
                        $indexComponent.RootDirectory = $params.FirstPartitionDirectory
                        $newTopology.AddComponent($indexComponent)
                    }
                }
            }
            foreach ($ComponentToRemove in $ComponentsToRemove)
            {
                Write-Verbose -Message "Removing $($componentTypes.$CurrentSearchProperty) from $ComponentToRemove"
                if ($componentTypes.$CurrentSearchProperty -eq "IndexComponent")
                {
                    $component = Get-SPEnterpriseSearchComponent -SearchTopology $newTopology | `
                            Where-Object -FilterScript {
                            ($_.GetType().Name -eq $componentTypes.$CurrentSearchProperty) `
                                -and (($_.ServerName -eq $ComponentToRemove) `
                                    -or ($_.ServerName -eq ($ComponentToRemove -replace $domain))) `
                                -and ($_.IndexPartitionOrdinal -eq 0)
                        }
                }
                else
                {
                    $component = Get-SPEnterpriseSearchComponent -SearchTopology $newTopology | `
                            Where-Object -FilterScript {
                            ($_.GetType().Name -eq $componentTypes.$CurrentSearchProperty) `
                                -and (($_.ServerName -eq $ComponentToRemove) `
                                    -or ($_.ServerName -eq ($ComponentToRemove -replace $domain)))
                        }
                }

                if ($null -ne $component)
                {
                    $component | Remove-SPEnterpriseSearchComponent -SearchTopology $newTopology `
                        -Confirm:$false
                }
            }
        }

        # Look for components that have no server name and remove them
        $idsWithNoName = (Get-SPEnterpriseSearchComponent -SearchTopology $newTopology | `
                    Where-Object -FilterScript {
                    $null -eq $_.ServerName
                }).ComponentId
        $idsWithNoName | ForEach-Object -Process {
            $id = $_
            Get-SPEnterpriseSearchComponent -SearchTopology $newTopology | `
                    Where-Object -FilterScript {
                    $_.ComponentId -eq $id
                } | Remove-SPEnterpriseSearchComponent -SearchTopology $newTopology `
                        -Confirm:$false
        }

        # Apply the new topology to the farm
        Write-Verbose -Message "Applying new Search topology"
        Set-SPEnterpriseSearchTopology -Identity $newTopology
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
        $ServiceAppName,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Admin,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Crawler,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $ContentProcessing,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $AnalyticsProcessing,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $QueryProcessing,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $IndexPartition,

        [Parameter(Mandatory = $true)]
        [System.String]
        $FirstPartitionDirectory
    )

    Write-Verbose -Message "Testing Search Topology for '$ServiceAppName'"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    $domain = "." + (Get-CimInstance -ClassName Win32_ComputerSystem).Domain
    $PSBoundParameters.Admin = $PSBoundParameters.Admin -replace $domain
    $PSBoundParameters.Crawler = $PSBoundParameters.Crawler -replace $domain
    $PSBoundParameters.ContentProcessing = $PSBoundParameters.ContentProcessing -replace $domain
    $PSBoundParameters.AnalyticsProcessing = $PSBoundParameters.AnalyticsProcessing -replace $domain
    $PSBoundParameters.QueryProcessing = $PSBoundParameters.QueryProcessing -replace $domain
    $PSBoundParameters.IndexPartition = $PSBoundParameters.IndexPartition -replace $domain

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @(
        "Admin",
        "Crawler",
        "ContentProcessing",
        "AnalyticsProcessing",
        "QueryProcessing",
        "IndexPartition"
    )

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPSearchTopology\MSFT_SPSearchTopology.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module

    $ssas = Get-SPServiceApplication | Where-Object -FilterScript { $_.GetType().FullName -eq "Microsoft.Office.Server.Search.Administration.SearchServiceApplication" }

    $i = 1
    $total = $ssas.Length
    foreach ($ssa in $ssas)
    {
        try
        {
            if ($null -ne $ssa)
            {
                $serviceName = $ssa.DisplayName
                Write-Host "Scanning Search Topology for Service Application [$i/$total] {$serviceName}"
                $PartialContent = "        SPSearchTopology " + [System.Guid]::NewGuid().ToString() + "`r`n"
                $PartialContent += "        {`r`n"
                $params.ServiceAppName = $serviceName
                $results = Get-TargetResource @params

                Add-ConfigurationDataEntry -Node "NonNodeData" -Key "SearchContentProcessingServers" -Value $results.ContentProcessing -Description "List of servers that will act as Search Content Processors;"
                $results.ContentProcessing = "`$ConfigurationData.NonNodeData.SearchContentProcessingServers"

                Add-ConfigurationDataEntry -Node "NonNodeData" -Key "SearchAnalyticsProcessingServers" -Value $results.AnalyticsProcessing -Description "List of servers that will act as Search Analytics Processors;"
                $results.AnalyticsProcessing = "`$ConfigurationData.NonNodeData.SearchAnalyticsProcessingServers"

                Add-ConfigurationDataEntry -Node "NonNodeData" -Key "SearchIndexPartitionServers" -Value $results.IndexPartition -Description "List of servers that will host the Search Index Partitions;"
                $results.IndexPartition = "`$ConfigurationData.NonNodeData.SearchIndexPartitionServers"

                Add-ConfigurationDataEntry -Node "NonNodeData" -Key "SearchCrawlerServers" -Value $results.Crawler -Description "List of servers that will act as Search Crawlers;"
                $results.Crawler = "`$ConfigurationData.NonNodeData.SearchCrawlerServers"

                Add-ConfigurationDataEntry -Node "NonNodeData" -Key "SearchAdminServers" -Value $results.Admin -Description "List of servers that will host the Search Admin Components;"
                $results.Admin = "`$ConfigurationData.NonNodeData.SearchAdminServers"

                Add-ConfigurationDataEntry -Node "NonNodeData" -Key "QueryProcessingServers" -Value $results.QueryProcessing -Description "List of servers that will host the Search Query Components;"
                $results.QueryProcessing = "`$ConfigurationData.NonNodeData.QueryProcessingServers"

                if ($results.FirstPartitionDirectory.Length -gt 1)
                {
                    $results.FirstPartitionDirectory = $results.FirstPartitionDirectory
                }

                $results = Repair-Credentials -results $results

                $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
                $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
                $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "Admin"
                $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "AnalyticsProcessing"
                $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "ContentProcessing"
                $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "Crawler"
                $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "IndexPartition"
                $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "QueryProcessing"
                $PartialContent += $currentBlock
                $PartialContent += "        }`r`n"
                $Content += $PartialContent
                $i++
            }
        }
        catch
        {
            $_
            $Global:ErrorLog += "[Search Topology]" + $ssa.DisplayName + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
