function Set-xSharePointSearchTopologyComponents {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)]  [string]    $ComponentType,
        [parameter(Mandatory = $false)] [object[]]  $CurrentServers,
        [parameter(Mandatory = $true)]  [object[]]  $DesiredServers,
        [parameter(Mandatory = $true)]  [object]    $NewTopology,
        [parameter(Mandatory = $true)]  [Hashtable] $ServiceInstances,
        [parameter(Mandatory = $false)] [string]    $PartitionDirectory,
        [parameter(Mandatory = $false)] [Int]       $PartitionId = 0
    )

    if ($null -eq $CurrentServers) {
        $ComponentsToAdd = $DesiredServers
    } else {
        $ComponentsToAdd = @()
        $ComponentsToRemove = @()
        foreach($Component in ($DesiredServers | Where-Object { $CurrentServers.Contains($_) -eq $false })) {
            $ComponentsToAdd += $Component
        }
        foreach($Component in ($CurrentServers | Where-Object { $DesiredServers.Contains($_) -eq $false })) {
            $ComponentsToRemove += $Component
        }
    }
    foreach($ComponentToAdd in $ComponentsToAdd) {
        $NewComponentParams = @{
            SearchTopology = $NewTopology
            SearchServiceInstance = $ServiceInstances.$ComponentToAdd
        }
        switch($ComponentType) {
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
                $NewComponentParams.Add("IndexPartition", $PartitionId)
                if ($PSBoundParameters.ContainsKey("PartitionDirectory") -eq $true) {
                    if ([string]::IsNullOrEmpty($PSBoundParameters.PartitionDirectory) -eq $false) {
                        $NewComponentParams.Add("RootDirectory", $PartitionDirectory)
                    }
                }
                New-SPEnterpriseSearchIndexComponent @NewComponentParams
            }
        }
    }
    foreach($ComponentToRemove in $ComponentsToRemove) {
        if ($ComponentType -eq "IndexComponent") {
            $component = Get-SPEnterpriseSearchComponent -SearchTopology $NewTopology | Where-Object {($_.GetType().Name -eq $ComponentType) -and ($_.ServerName -eq $ComponentToRemove) -and ($_.IndexPartitionOrdinal -eq $PartitionId)}
        } else {
            $component = Get-SPEnterpriseSearchComponent -SearchTopology $NewTopology | Where-Object {($_.GetType().Name -eq $ComponentType) -and ($_.ServerName -eq $ComponentToRemove)}
        }
        if ($null -ne $component) {
            Remove-SPEnterpriseSearchComponent -Identity $component.ComponentId -SearchTopology $newTopology -confirm:$false
        }
        
    }
}