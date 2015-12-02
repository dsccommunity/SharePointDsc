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

    Invoke-xSharePointCommand -Credential $InstallAccount -Arguments @($PSBoundParameters, $CurrentValues) -ScriptBlock {
        $params = $args[0]
        $CurrentValues = $args[1]
        $ConfirmPreference = 'None'


        $AllSearchServers = @()
        $AllSearchServers += ($params.Admin | Where-Object { $AllSearchServers.Contains($_) -eq $false })
        $AllSearchServers += ($params.Crawler | Where-Object { $AllSearchServers.Contains($_) -eq $false })
        $AllSearchServers += ($params.ContentProcessing | Where-Object { $AllSearchServers.Contains($_) -eq $false })
        $AllSearchServers += ($params.AnalyticsProcessing | Where-Object { $AllSearchServers.Contains($_) -eq $false })
        $AllSearchServers += ($params.QueryProcessing | Where-Object { $AllSearchServers.Contains($_) -eq $false })
        $AllSearchServers += ($params.IndexPartition | Where-Object { $AllSearchServers.Contains($_) -eq $false })

        # Ensure the search service instance is running on all servers
        foreach($searchServer in $AllSearchServers) {
            $searchService = Get-SPEnterpriseSearchServiceInstance -Identity $searchServer
            if($searchService.Status -eq "Offline") {
                Write-Verbose "Start Search Service Instance"
                Start-SPEnterpriseSearchServiceInstance -Identity $indexSsi
            }

            #Wait for Search Service Instance to come online
            $loopCount = 0
            $online = Get-SPEnterpriseSearchServiceInstance -Identity $searchService; 
            do {
                $online = Get-SPEnterpriseSearchServiceInstance -Identity $searchService; 
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


        Import-Module (Join-Path $ScriptRoot "..\..\Modules\xSharePoint.SearchTopology\xSharePoint.SearchTopology.psm1" -Resolve)

        # Admin components
        Set-xSharePointSearchTopologyComponents -ComponentType "AdminComponent" `
                                                -CurrentServers $CurrentValues.Admin `
                                                -DesiredServers $params.Admin `
                                                -NewTopology $newTopology `
                                                -ServiceInstances $AllSearchServiceInstances
        # Crawler components
        Set-xSharePointSearchTopologyComponents -ComponentType "CrawlComponent" `
                                                -CurrentServers $CurrentValues.Crawler `
                                                -DesiredServers $params.Crawler `
                                                -NewTopology $newTopology `
                                                -ServiceInstances $AllSearchServiceInstances
        # Content Processing components
        Set-xSharePointSearchTopologyComponents -ComponentType "ContentProcessingComponent" `
                                                -CurrentServers $CurrentValues.ContentProcessing `
                                                -DesiredServers $params.ContentProcessing `
                                                -NewTopology $newTopology `
                                                -ServiceInstances $AllSearchServiceInstances
        # Analytics components
        Set-xSharePointSearchTopologyComponents -ComponentType "AnalyticsProcessingComponent" `
                                                -CurrentServers $CurrentValues.AnalyticsProcessing `
                                                -DesiredServers $params.AnalyticsProcessing `
                                                -NewTopology $newTopology `
                                                -ServiceInstances $AllSearchServiceInstances
        # Query components
        Set-xSharePointSearchTopologyComponents -ComponentType "QueryProcessingComponent" `
                                                -CurrentServers $CurrentValues.QueryProcessing `
                                                -DesiredServers $params.QueryProcessing `
                                                -NewTopology $newTopology `
                                                -ServiceInstances $AllSearchServiceInstances
        # Index components
        $IndexParams = @{ PartitionId = 0 }
        if ($params.ContainsKey("FirstPartitionDirectory") -eq $true) { 
            $IndexParams.Add("PartitionDirectory", $params.FirstPartitionDirectory)
        } 
        Set-xSharePointSearchTopologyComponents -ComponentType "IndexComponent" `
                                                -CurrentServers $CurrentValues.IndexPartition `
                                                -DesiredServers $params.IndexPartition `
                                                -NewTopology $newTopology `
                                                -ServiceInstances $AllSearchServiceInstances `
                                                @IndexParams

        # Apply the new topology
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
