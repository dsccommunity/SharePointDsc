function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]   $ServiceAppName,
        [parameter(Mandatory = $true)]  [System.String[]] $Admin,
        [parameter(Mandatory = $true)]  [System.String[]] $Crawler,
        [parameter(Mandatory = $true)]  [System.String[]] $ContentProcessing,
        [parameter(Mandatory = $true)]  [System.String[]] $AnalyticsProcessing,
        [parameter(Mandatory = $true)]  [System.String[]] $QueryProcessing,
        [parameter(Mandatory = $true)]  [System.String[]] $IndexPartition,
        [parameter(Mandatory = $true)]  [System.String]   $FirstPartitionDirectory,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $result = Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        $ConfirmPreference = 'None'

        $ssa = Get-SPEnterpriseSearchServiceApplication -Identity $params.ServiceAppName  
        
        IF ($null -eq $ssa) {
            return $null
        }    
        $currentTopology = $ssa.ActiveTopology
        
        $AdminComponents = (Get-SPEnterpriseSearchComponent -SearchTopology $currentTopology | Where-Object { ($_.GetType().Name -eq "AdminComponent") }).ServerName
        $CrawlComponents = (Get-SPEnterpriseSearchComponent -SearchTopology $currentTopology | Where-Object { ($_.GetType().Name -eq "CrawlComponent") }).ServerName
        $ContentProcessingComponents = (Get-SPEnterpriseSearchComponent -SearchTopology $currentTopology | Where-Object { ($_.GetType().Name -eq "ContentProcessingComponent") }).ServerName
        $AnalyticsProcessingComponents = (Get-SPEnterpriseSearchComponent -SearchTopology $currentTopology | Where-Object { ($_.GetType().Name -eq "AnalyticsProcessingComponent") }).ServerName
        $QueryProcessingComponents = (Get-SPEnterpriseSearchComponent -SearchTopology $currentTopology | Where-Object { ($_.GetType().Name -eq "QueryProcessingComponent") }).ServerName
        $IndexComponents = (Get-SPEnterpriseSearchComponent -SearchTopology $currentTopology | Where-Object { ($_.GetType().Name -eq "IndexComponent") -and ($_.IndexPartitionOrdinal -eq 0) }).ServerName
        
        $domain = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain
        
        return @{
            ServiceAppName = $params.ServiceAppName
            Admin = $AdminComponents -replace ".$domain"
            Crawler = $CrawlComponents -replace ".$domain"
            ContentProcessing = $ContentProcessingComponents -replace ".$domain"
            AnalyticsProcessing = $AnalyticsProcessingComponents -replace ".$domain"
            QueryProcessing = $QueryProcessingComponents -replace ".$domain"
            InstallAccount = $params.InstallAccount
            FirstPartitionDirectory = $params.FirstPartitionDirectory
            IndexPartition = $IndexComponents -replace ".$domain"
        }
    }
    return $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]   $ServiceAppName,
        [parameter(Mandatory = $true)]  [System.String[]] $Admin,
        [parameter(Mandatory = $true)]  [System.String[]] $Crawler,
        [parameter(Mandatory = $true)]  [System.String[]] $ContentProcessing,
        [parameter(Mandatory = $true)]  [System.String[]] $AnalyticsProcessing,
        [parameter(Mandatory = $true)]  [System.String[]] $QueryProcessing,
        [parameter(Mandatory = $true)]  [System.String[]] $IndexPartition,
        [parameter(Mandatory = $true)]  [System.String]   $FirstPartitionDirectory,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Invoke-SPDSCCommand -Credential $InstallAccount -Arguments @($PSBoundParameters, $CurrentValues) -ScriptBlock {
        $params = $args[0]
        $CurrentValues = $args[1]
        $ConfirmPreference = 'None'

        $AllSearchServers = @()
        $AllSearchServers += ($params.Admin               | Where-Object { $AllSearchServers.Contains($_) -eq $false })
        $AllSearchServers += ($params.Crawler             | Where-Object { $AllSearchServers.Contains($_) -eq $false })
        $AllSearchServers += ($params.ContentProcessing   | Where-Object { $AllSearchServers.Contains($_) -eq $false })
        $AllSearchServers += ($params.AnalyticsProcessing | Where-Object { $AllSearchServers.Contains($_) -eq $false })
        $AllSearchServers += ($params.QueryProcessing     | Where-Object { $AllSearchServers.Contains($_) -eq $false })
        $AllSearchServers += ($params.IndexPartition      | Where-Object { $AllSearchServers.Contains($_) -eq $false })

        # Ensure the search service instance is running on all servers
        foreach($searchServer in $AllSearchServers) {
            
            $searchService = Get-SPEnterpriseSearchServiceInstance -Identity $searchServer -ErrorAction SilentlyContinue
            if ($null -eq $searchService) {
                $domain = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain
                $searchServer = "$searchServer.$domain"
                $searchService = Get-SPEnterpriseSearchServiceInstance -Identity $searchServer    
            }
            
            if($searchService.Status -eq "Offline") {
                Write-Verbose "Start Search Service Instance"
                Start-SPEnterpriseSearchServiceInstance -Identity $searchServer
            }

            #Wait for Search Service Instance to come online
            $loopCount = 0
            $online = Get-SPEnterpriseSearchServiceInstance -Identity $searchServer 
            do {
                $online = Get-SPEnterpriseSearchServiceInstance -Identity $searchServer
                Write-Verbose "$([DateTime]::Now.ToShortTimeString()) - Waiting for search service instance to start on $searchServer (waited $loopCount of 15 minutes)"
                $loopCount++
                Start-Sleep -Seconds 60
            } 
            until ($online.Status -eq "Online" -or $loopCount -eq 15)
        }

        # Create the index partition directory on each remote server
        foreach($IndexPartitionServer in $params.IndexPartition) {
            $networkPath = "\\$IndexPartitionServer\" + $params.FirstPartitionDirectory.Replace(":\", "$\")
            New-Item $networkPath -ItemType Directory -Force
        }

        # Create the directory on the local server as it will not apply the topology without it
        if ((Test-Path -Path $params.FirstPartitionDirectory) -eq $false) {
            New-Item $params.FirstPartitionDirectory -ItemType Directory -Force
        }
        
        # Get all service service instances to assign topology components to
        $AllSearchServiceInstances = @{}
        foreach ($server in $AllSearchServers) {
            $serverName = $server
            $serviceToAdd = Get-SPEnterpriseSearchServiceInstance -Identity $server -ErrorAction SilentlyContinue
            if ($null -eq $serviceToAdd) {
                $domain = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain
                $server = "$server.$domain"
                $serviceToAdd = Get-SPEnterpriseSearchServiceInstance -Identity $server    
            }
            if ($null -eq $serviceToAdd) {
                throw "Unable to locate a search service instance on $serverName"
            }
            $AllSearchServiceInstances.Add($serverName, $serviceToAdd)
        }

        # Get current topology and prepare a new one
        $ssa = Get-SPEnterpriseSearchServiceApplication -Identity $params.ServiceAppName
        if ($null -eq $ssa) {
            throw "Search service applications '$($params.ServiceAppName)' was not found"
            return
        }
        $currentTopology = $ssa.ActiveTopology
        $newTopology = New-SPEnterpriseSearchTopology -SearchApplication $ssa -Clone -SearchTopology $currentTopology

        $componentTypes = @{
            Admin = "AdminComponent"
            Crawler = "CrawlComponent"
            ContentProcessing = "ContentProcessingComponent"
            AnalyticsProcessing = "AnalyticsProcessingComponent"
            QueryProcessing = "QueryProcessingComponent"
            IndexPartition = "IndexComponent"
        }

        # Build up the topology changes for each object type
        @("Admin", "Crawler", "ContentProcessing", "AnalyticsProcessing", "QueryProcessing", "IndexPartition")  | ForEach-Object { 
            $CurrentSearchProperty = $_
            Write-Verbose "Setting components for '$CurrentSearchProperty' property"

            if ($null -eq $CurrentValues.$CurrentSearchProperty) {
                $ComponentsToAdd = $params.$CurrentSearchProperty
            } else {
                $ComponentsToAdd = @()
                $ComponentsToRemove = @()
                foreach($Component in ($params.$CurrentSearchProperty | Where-Object { $CurrentValues.$CurrentSearchProperty -contains $_ -eq $false })) {
                    $ComponentsToAdd += $Component
                }
                foreach($Component in ($CurrentValues.$CurrentSearchProperty | Where-Object { $params.$CurrentSearchProperty -contains $_ -eq $false })) {
                    $ComponentsToRemove += $Component
                }
            }
            foreach($ComponentToAdd in $ComponentsToAdd) {
                $NewComponentParams = @{
                    SearchTopology = $newTopology
                    SearchServiceInstance = $AllSearchServiceInstances.$ComponentToAdd
                }
                switch($componentTypes.$CurrentSearchProperty) {
                    "AdminComponent" {
                        New-SPEnterpriseSearchAdminComponent @NewComponentParams
                    }
                    "CrawlComponent" {
                        New-SPEnterpriseSearchCrawlComponent @NewComponentParams
                    }
                    "ContentProcessingComponent" {
                        New-SPEnterpriseSearchContentProcessingComponent @NewComponentParams
                    }
                    "AnalyticsProcessingComponent" {
                        New-SPEnterpriseSearchAnalyticsProcessingComponent @NewComponentParams
                    }
                    "QueryProcessingComponent" {
                        New-SPEnterpriseSearchQueryProcessingComponent @NewComponentParams
                    }
                    "IndexComponent" {
                        $NewComponentParams.Add("IndexPartition", 0)
                        if ($params.ContainsKey("FirstPartitionDirectory") -eq $true) {
                            if ([string]::IsNullOrEmpty($params.FirstPartitionDirectory) -eq $false) {
                                $NewComponentParams.Add("RootDirectory", $params.FirstPartitionDirectory)
                            }
                        }
                        New-SPEnterpriseSearchIndexComponent @NewComponentParams
                    }
                }
            }
            foreach($ComponentToRemove in $ComponentsToRemove) {
                if ($componentTypes.$CurrentSearchProperty -eq "IndexComponent") {
                    $component = Get-SPEnterpriseSearchComponent -SearchTopology $newTopology | Where-Object {($_.GetType().Name -eq $componentTypes.$CurrentSearchProperty) -and ($_.ServerName -eq $ComponentToRemove) -and ($_.IndexPartitionOrdinal -eq 0)}
                } else {
                    $component = Get-SPEnterpriseSearchComponent -SearchTopology $newTopology | Where-Object {($_.GetType().Name -eq $componentTypes.$CurrentSearchProperty) -and ($_.ServerName -eq $ComponentToRemove)}
                }
                if ($null -ne $component) {
                    $component | Remove-SPEnterpriseSearchComponent -SearchTopology $newTopology -confirm:$false
                }
        
            }
        }

        # Apply the new topology to the farm
        Set-SPEnterpriseSearchTopology -Identity $newTopology
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]   $ServiceAppName,
        [parameter(Mandatory = $true)]  [System.String[]] $Admin,
        [parameter(Mandatory = $true)]  [System.String[]] $Crawler,
        [parameter(Mandatory = $true)]  [System.String[]] $ContentProcessing,
        [parameter(Mandatory = $true)]  [System.String[]] $AnalyticsProcessing,
        [parameter(Mandatory = $true)]  [System.String[]] $QueryProcessing,
        [parameter(Mandatory = $true)]  [System.String[]] $IndexPartition,
        [parameter(Mandatory = $true)]  [System.String]   $FirstPartitionDirectory,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    if ($null -eq $CurrentValues) { return $false }
    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                        -DesiredValues $PSBoundParameters `
                                        -ValuesToCheck @(
                                                  "Admin", 
                                                  "Crawler", 
                                                  "ContentProcessing", 
                                                  "AnalyticsProcessing", 
                                                  "QueryProcessing",
                                                  "IndexPartition"
                                              )
}

Export-ModuleMember -Function *-TargetResource
