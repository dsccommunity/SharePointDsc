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
        $FirstPartitionDirectory,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting Search Topology for '$ServiceAppName'"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
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
        $FirstPartitionDirectory,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting Search Topology for '$ServiceAppName'"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters, $CurrentValues) `
        -ScriptBlock {

        $params = $args[0]
        $CurrentValues = $args[1]
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

            if ($searchService.Status -eq "Offline")
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
                throw "Unable to locate a search service instance on $serverName"
            }
            $AllSearchServiceInstances.Add($server, $serviceToAdd)
        }

        # Get current topology and prepare a new one
        $ssa = Get-SPEnterpriseSearchServiceApplication -Identity $params.ServiceAppName
        if ($null -eq $ssa)
        {
            throw "Search service applications '$($params.ServiceAppName)' was not found"
            return
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
                    $CurrentValues.$CurrentSearchProperty -contains $_ -eq $false
                }

                $ComponentsToRemove = $CurrentValues.$CurrentSearchProperty | Where-Object -FilterScript {
                    $params.$CurrentSearchProperty -contains $_ -eq $false
                }
            }
            foreach ($ComponentToAdd in $ComponentsToAdd)
            {
                $NewComponentParams = @{
                    SearchTopology        = $newTopology
                    SearchServiceInstance = $AllSearchServiceInstances.$ComponentToAdd
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
                        $installedVersion = Get-SPDscInstalledProductVersion
                        if ($installedVersion.FileMajorPart -eq 15)
                        {
                            Write-Verbose -Message "Using SharePoint 2013"
                            $indexServer = (Get-SPServer $ComponentToAdd).Name
                            $indexComponent = (New-Object Microsoft.Office.Server.Search.Administration.Topology.IndexComponent $indexServer, 0);
                            $indexComponent.RootDirectory = $params.FirstPartitionDirectory
                            $newTopology.AddComponent($indexComponent)
                        }
                        else
                        {
                            Write-Verbose -Message "Using SharePoint 2016 or later"
                            $NewComponentParams.Add("IndexPartition", 0)
                            if ($params.ContainsKey("FirstPartitionDirectory") -eq $true)
                            {
                                if ([string]::IsNullOrEmpty($params.FirstPartitionDirectory) -eq $false)
                                {
                                    $dir = $params.FirstPartitionDirectory
                                    $NewComponentParams.Add("RootDirectory", $dir)
                                }
                            }
                            $null = New-SPEnterpriseSearchIndexComponent @NewComponentParams
                        }
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
                            -and ($_.ServerName -eq $ComponentToRemove) `
                            -and ($_.IndexPartitionOrdinal -eq 0)
                    }
                }
                else
                {
                    $component = Get-SPEnterpriseSearchComponent -SearchTopology $newTopology | `
                        Where-Object -FilterScript {
                        ($_.GetType().Name -eq $componentTypes.$CurrentSearchProperty) `
                            -and ($_.ServerName -eq $ComponentToRemove)
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
            } | `
                Remove-SPEnterpriseSearchComponent -SearchTopology $newTopology `
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
        $FirstPartitionDirectory,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing Search Topology for '$ServiceAppName'"

    $CurrentValues = Get-TargetResource @PSBoundParameters

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

Export-ModuleMember -Function *-TargetResource
