function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $ServiceAppName,
        [parameter(Mandatory = $true)]  [System.Boolean] $Admin,
        [parameter(Mandatory = $true)]  [System.Boolean] $Crawler,
        [parameter(Mandatory = $true)]  [System.Boolean] $ContentProcessing,
        [parameter(Mandatory = $true)]  [System.Boolean] $AnalyticsProcessing,
        [parameter(Mandatory = $true)]  [System.Boolean] $QueryProcessing,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")] [System.String] $Ensure,
        [parameter(Mandatory = $false)] [System.UInt32]  $FirstPartitionIndex,
        [parameter(Mandatory = $true)]  [System.String]  $FirstPartitionDirectory,
        [parameter(Mandatory = $true)]  [System.String]  $FirstPartitionServers
    )

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        $ConfirmPreference = 'None'

        $AdminExists = $false;
        $CrawlerExists = $false;
        $ContentProcessingExists = $false;
        $AnalyticsProcessingExists = $false;
        $QueryProcessingExists = $false;

        $ssi = Get-SPEnterpriseSearchServiceInstance -Identity $env:COMPUTERNAME 
        $ssa = Get-SPEnterpriseSearchServiceApplication        
        if($ssi.Status -eq "Offline") {
            Write-Verbose "Search is offline"
            return @{
                ServiceAppName = $params.ServiceAppName
                Admin = $false
                Crawler = $false
                ContentProcessing = $false
                AnalyticsProcessing = $false
                QueryProcessing = $false
                InstallAccount = $params.InstallAccount
                FirstPartitionIndex = $params.FirstPartitionIndex
                FirstPartitionDirectory = $params.FirstPartitionDirectory
                FirstPartitionServers = $params.FirstPartitionServers
                Ensure = $params.Ensure
            }
        }
        $currentTopology = $ssa.ActiveTopology
        
        #Make sure what we expect to be there is
        $AdminComponent1 = Get-SPEnterpriseSearchComponent -SearchTopology $currentTopology | Where-Object {($_.GetType().Name -eq "AdminComponent") -and ($_.ServerName -eq $($ssi.Server.Address))}
        if($AdminComponent1) {
            $AdminExists = $true
        }
        $CrawlComponent1 = Get-SPEnterpriseSearchComponent -SearchTopology $currentTopology | Where-Object {($_.GetType().Name -eq "CrawlComponent") -and ($_.ServerName -eq $($ssi.Server.Address))}
        if($CrawlComponent1) {
            $CrawlerExists = $true
        }
        $ContentProcessingComponent1 = Get-SPEnterpriseSearchComponent -SearchTopology $currentTopology | Where-Object {($_.GetType().Name -eq "ContentProcessingComponent") -and ($_.ServerName -eq $($ssi.Server.Address))}
        if($ContentProcessingComponent1) {
            $ContentProcessingExists = $true
        }
        $AnalyticsProcessingComponent1 = Get-SPEnterpriseSearchComponent -SearchTopology $currentTopology | Where-Object {($_.GetType().Name -eq "AnalyticsProcessingComponent") -and ($_.ServerName -eq $($ssi.Server.Address))}
        if($AnalyticsProcessingComponent1) {
            $AnalyticsProcessingExists = $true
        }
        $QueryProcessingComponent1 = Get-SPEnterpriseSearchComponent -SearchTopology $currentTopology | Where-Object {($_.GetType().Name -eq "QueryProcessingComponent") -and ($_.ServerName -eq $($ssi.Server.Address))}
        if($QueryProcessingComponent1) {
            $QueryProcessingExists = $true
        }

        $indexComps = Get-SPEnterpriseSearchComponent -SearchTopology $currentTopology `
            | Where-Object {($_.GetType().Name -eq "IndexComponent") `
                -and ($_.IndexPartitionOrdinal -eq $params.Index)}

        $servers = ""
        foreach ($indexComp in $indexComps) {
            $servers += $indexComp.ServerName + ","
        }

        return @{
            ServiceAppName = $params.ServiceAppName
            Admin = $AdminExists
            Crawler = $CrawlerExists
            ContentProcessing = $ContentProcessingExists
            AnalyticsProcessing = $AnalyticsProcessingExists
            QueryProcessing = $QueryProcessingExists
            InstallAccount = $params.InstallAccount
            FirstPartitionIndex = $params.FirstPartitionIndex
            FirstPartitionDirectory = $params.FirstPartitionDirectory
            FirstPartitionServers = $servers.TrimEnd(",")
            Ensure = $params.Ensure
        }
    }
    return $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $ServiceAppName,
        [parameter(Mandatory = $true)]  [System.Boolean] $Admin,
        [parameter(Mandatory = $true)]  [System.Boolean] $Crawler,
        [parameter(Mandatory = $true)]  [System.Boolean] $ContentProcessing,
        [parameter(Mandatory = $true)]  [System.Boolean] $AnalyticsProcessing,
        [parameter(Mandatory = $true)]  [System.Boolean] $QueryProcessing,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")] [System.String] $Ensure,
        [parameter(Mandatory = $false)] [System.UInt32]  $FirstPartitionIndex,
        [parameter(Mandatory = $true)]  [System.String]  $FirstPartitionDirectory,
        [parameter(Mandatory = $true)]  [System.String]  $FirstPartitionServers
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Invoke-xSharePointCommand -Credential $InstallAccount -Arguments @($PSBoundParameters, $CurrentValues) -ScriptBlock {
        $params = $args[0]
        $CurrentValues = $args[1]
        $ConfirmPreference = 'None'

        $ssi = Get-SPEnterpriseSearchServiceInstance -Local
        $ssa = Get-SPEnterpriseSearchServiceApplication

        if($ssi.Status -eq "Offline") {
            Write-Verbose "Start Search Service Instance"
            Start-SPEnterpriseSearchServiceInstance -Identity $ssi
        }

        #Wait for Search Service Instance to come online
        $online = Get-SPEnterpriseSearchServiceInstance -Identity $ssi; 
        do {
            $online = Get-SPEnterpriseSearchServiceInstance -Identity $ssi; 
            Write-Verbose "Waiting for service: $($online.TypeName)"
        } 
        until ($online.Status -eq "Online")

        $currentTopology = $ssa.ActiveTopology
        $newTopology = New-SPEnterpriseSearchTopology -SearchApplication $ssa -Clone -SearchTopology $currentTopology


        if ($params.Ensure -eq "Present") {
            if($CurrentValues.Admin -eq $false -and $params.Admin -eq $true) {
                New-SPEnterpriseSearchAdminComponent -SearchTopology $newTopology `
                                                     -SearchServiceInstance $ssi
            }
            if($CurrentValues.Crawler -eq $false -and $params.Crawler -eq $true) {
                New-SPEnterpriseSearchCrawlComponent -SearchTopology $newTopology `
                                                     -SearchServiceInstance $ssi
            }
            if($CurrentValues.ContentProcessing -eq $false -and $params.ContentProcessing -eq $true) {
                New-SPEnterpriseSearchContentProcessingComponent -SearchTopology $newTopology `
                                                                 -SearchServiceInstance $ssi
            }
            if($CurrentValues.AnalyticsProcessing -eq $false -and $params.AnalyticsProcessing -eq $true) {
                New-SPEnterpriseSearchAnalyticsProcessingComponent -SearchTopology $newTopology `
                                                                   -SearchServiceInstance $ssi
            }
            if($CurrentValues.QueryProcessing -eq $false -and $params.QueryProcessing -eq $true) {
                New-SPEnterpriseSearchQueryProcessingComponent -SearchTopology $newTopology `
                                                               -SearchServiceInstance $ssi
            }

            $IndexComponent1 = Get-SPEnterpriseSearchComponent -SearchTopology $newTopology | Where-Object {
                ($_.GetType().Name -ccontains "IndexComponent")
            }
            
            #Add the First search index if no other indexes already exist required
            if($null -eq $IndexComponent1) {
                Write-Verbose "Adding First search indedx at partition $($params.FirstPartitionIndex)"

                $servers = $params.FirstPartitionServers.Replace(" ", "").Split(',', [StringSplitOptions]::RemoveEmptyEntries)
                foreach($server in $servers) {
                    $networkPath = "\\$server\" + $params.FirstPartitionDirectory.Replace(":\", "$\")
                    New-Item $networkPath -ItemType Directory -Force

                    $indexSsi = Get-SPEnterpriseSearchServiceInstance -Identity $server
                    if($indexSsi.Status -eq "Offline") {
                        Write-Verbose "Start Search Service Instance"
                        Start-SPEnterpriseSearchServiceInstance -Identity $indexSsi
                    }
                    $online = Get-SPEnterpriseSearchServiceInstance -Identity $indexSsi 
                    do {
                        $online = Get-SPEnterpriseSearchServiceInstance -Identity $indexSsi 
                        Write-Verbose "Waiting for service: $($online.TypeName)"
                    } 
                    until ($online.Status -eq "Online")
                    New-SPEnterpriseSearchIndexComponent -SearchTopology $newTopology -SearchServiceInstance $indexSsi -IndexPartition $params.FirstPartitionIndex -RootDirectory $params.FirstPartitionDirectory
                }
            }
            Set-SPEnterpriseSearchTopology -Identity $newTopology
        } else {
            $AdminComponent1 = Get-SPEnterpriseSearchComponent -SearchTopology $newTopology | Where-Object {($_.GetType().Name -eq "AdminComponent") -and ($_.ServerName -eq $($ssi.Server.Address))}
             if (($params.Admin -eq $false) -and ($null -ne $AdminComponent1)) {
                Remove-SPEnterpriseSearchComponent -Identity $AdminComponent1.ComponentId -SearchTopology $newTopology -confirm:$false
            }
            $CrawlComponent1 = Get-SPEnterpriseSearchComponent -SearchTopology $newTopology | Where-Object {($_.GetType().Name -eq "CrawlComponent") -and ($_.ServerName -eq $($ssi.Server.Address))}
            if (($params.Crawler -eq $false) -and ($null -ne $CrawlComponent1)) {
                Remove-SPEnterpriseSearchComponent -Identity $CrawlComponent1.ComponentId -SearchTopology $newTopology -confirm:$false
            }
            $ContentProcessingComponent1 = Get-SPEnterpriseSearchComponent -SearchTopology $newTopology | Where-Object {($_.GetType().Name -eq "ContentProcessingComponent") -and ($_.ServerName -eq $($ssi.Server.Address))}
            if (($params.ContentProcessing -eq $false) -and ($null -ne $ContentProcessingComponent1)) {
                Remove-SPEnterpriseSearchComponent -Identity $ContentProcessingComponent1.ComponentId -SearchTopology $newTopology -confirm:$false
            }
            $AnalyticsProcessingComponent1 = Get-SPEnterpriseSearchComponent -SearchTopology $newTopology | Where-Object {($_.GetType().Name -eq "AnalyticsProcessingComponent") -and ($_.ServerName -eq $($ssi.Server.Address))}
            if (($params.AnalyticsProcessing -eq $false) -and ($null -ne $AnalyticsProcessingComponent1)) {
                Remove-SPEnterpriseSearchComponent -Identity $AnalyticsProcessingComponent1.ComponentId -SearchTopology $newTopology -confirm:$false
            }
            $QueryProcessingComponent1 = Get-SPEnterpriseSearchComponent -SearchTopology $newTopology | Where-Object {($_.GetType().Name -eq "QueryProcessingComponent") -and ($_.ServerName -eq $($ssi.Server.Address))}
            if (($params.QueryProcessing -eq $false) -and ($null -ne $QueryProcessingComponent1)) {
                Remove-SPEnterpriseSearchComponent -Identity $QueryProcessingComponent1.ComponentId -SearchTopology $newTopology -confirm:$false
            }
            
            Set-SPEnterpriseSearchTopology -Identity $newTopology
        }
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $ServiceAppName,
        [parameter(Mandatory = $true)]  [System.Boolean] $Admin,
        [parameter(Mandatory = $true)]  [System.Boolean] $Crawler,
        [parameter(Mandatory = $true)]  [System.Boolean] $ContentProcessing,
        [parameter(Mandatory = $true)]  [System.Boolean] $AnalyticsProcessing,
        [parameter(Mandatory = $true)]  [System.Boolean] $QueryProcessing,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")] [System.String] $Ensure,
        [parameter(Mandatory = $false)] [System.UInt32]  $FirstPartitionIndex,
        [parameter(Mandatory = $true)]  [System.String]  $FirstPartitionDirectory,
        [parameter(Mandatory = $true)]  [System.String]  $FirstPartitionServers
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("Ensure", "Admin", "Crawler", "ContentProcessing", "AnalyticsProcessing", "QueryProcessing")
}

Export-ModuleMember -Function *-TargetResource

