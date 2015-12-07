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

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        $ConfirmPreference = 'None'

        $ssa = Get-SPEnterpriseSearchServiceApplication -Identity $params.ServiceAppName      
        $currentTopology = $ssa.ActiveTopology
        
        $AdminComponents = (Get-SPEnterpriseSearchComponent -SearchTopology $currentTopology | Where-Object { ($_.GetType().Name -eq "AdminComponent") }).ServerName
        $CrawlComponents = (Get-SPEnterpriseSearchComponent -SearchTopology $currentTopology | Where-Object { ($_.GetType().Name -eq "CrawlComponent") }).ServerName
        $ContentProcessingComponents = (Get-SPEnterpriseSearchComponent -SearchTopology $currentTopology | Where-Object { ($_.GetType().Name -eq "ContentProcessingComponent") }).ServerName
        $AnalyticsProcessingComponents = (Get-SPEnterpriseSearchComponent -SearchTopology $currentTopology | Where-Object { ($_.GetType().Name -eq "AnalyticsProcessingComponent") }).ServerName
        $QueryProcessingComponents = (Get-SPEnterpriseSearchComponent -SearchTopology $currentTopology | Where-Object { ($_.GetType().Name -eq "QueryProcessingComponent") }).ServerName
        $IndexComponents = (Get-SPEnterpriseSearchComponent -SearchTopology $currentTopology | Where-Object { ($_.GetType().Name -eq "IndexComponent") -and ($_.IndexPartitionOrdinal -eq 0) }).ServerName
        
        return @{
            ServiceAppName = $params.ServiceAppName
            Admin = $AdminComponents
            Crawler = $CrawlComponents
            ContentProcessing = $ContentProcessingComponents
            AnalyticsProcessing = $AnalyticsProcessingComponents
            QueryProcessing = $QueryProcessingComponents
            InstallAccount = $params.InstallAccount
            FirstPartitionDirectory = $params.FirstPartitionDirectory
            IndexPartition = $IndexComponents
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

    Invoke-xSharePointCommand -Credential $InstallAccount -Arguments @($PSBoundParameters, $CurrentValues, $PSScriptRoot) -ScriptBlock {
        $params = $args[0]
        $CurrentValues = $args[1]
        $ScriptRoot = $args[2]
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
            $searchService = Get-SPEnterpriseSearchServiceInstance -Identity $searchServer
            if($searchService.Status -eq "Offline") {
                Write-Verbose "Start Search Service Instance"
                Start-SPEnterpriseSearchServiceInstance -Identity $searchServer
            }

            #Wait for Search Service Instance to come online
            $loopCount = 0
            $online = Get-SPEnterpriseSearchServiceInstance -Identity $searchServer 
            do {
                $online = Get-SPEnterpriseSearchServiceInstance -Identity $searchServer 
                Write-Verbose "Waiting for service: $($online.TypeName)"
                $loopCount++
                Start-Sleep -Seconds 30
            } 
            until ($online.Status -eq "Online" -or $loopCount -eq 20)
        }

        # Create the index partition directory on each remote server
        foreach($IndexPartitionServer in $params.IndexPartition) {
            $networkPath = "\\$IndexPartitionServer\" + $params.FirstPartitionDirectory.Replace(":\", "$\")
            New-Item $networkPath -ItemType Directory -Force
        }
        
        # Get all service service instances to assign topology components to
        $AllSearchServiceInstances = @{}
        foreach ($server in $AllSearchServers) {
            $AllSearchServiceInstances.Add($server, (Get-SPEnterpriseSearchServiceInstance -Identity $server))
        }

        # Get current topology and prepare a new one
        $ssa = Get-SPEnterpriseSearchServiceApplication -Identity $params.ServiceAppName
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
            Write-Verbose "Setting components for '$_' property"

            if ($null -eq $CurrentValues.$_) {
                $ComponentsToAdd = $params.$_
            } else {
                $ComponentsToAdd = @()
                $ComponentsToRemove = @()
                foreach($Component in ($params.$_ | Where-Object { $CurrentValues.$_.Contains($_) -eq $false })) {
                    $ComponentsToAdd += $Component
                }
                foreach($Component in ($CurrentValues.$_ | Where-Object { $params.$_.Contains($_) -eq $false })) {
                    $ComponentsToRemove += $Component
                }
            }
            foreach($ComponentToAdd in $ComponentsToAdd) {
                $NewComponentParams = @{
                    SearchTopology = $newTopology
                    SearchServiceInstance = $AllSearchServiceInstances.$ComponentToAdd
                }
                switch($componentTypes.$_) {
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
                if ($componentTypes.$_ -eq "IndexComponent") {
                    $component = Get-SPEnterpriseSearchComponent -SearchTopology $newTopology | Where-Object {($_.GetType().Name -eq $componentTypes.$_) -and ($_.ServerName -eq $ComponentToRemove) -and ($_.IndexPartitionOrdinal -eq 0)}
                } else {
                    $component = Get-SPEnterpriseSearchComponent -SearchTopology $newTopology | Where-Object {($_.GetType().Name -eq $componentTypes.$_) -and ($_.ServerName -eq $ComponentToRemove)}
                }
                if ($null -ne $component) {
                    Remove-SPEnterpriseSearchComponent -Identity $component.ComponentId -SearchTopology $newTopology -confirm:$false
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
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues `
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
