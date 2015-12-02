function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.UInt32]    $Index,
        [parameter(Mandatory = $true)]  [System.String[]]  $Servers,
        [parameter(Mandatory = $false)] [System.String]    $RootDirectory,
        [parameter(Mandatory = $true)]  [System.String]    $ServiceAppName,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        $ConfirmPreference = 'None'

        $ssa = Get-SPEnterpriseSearchServiceApplication -Identity $params.ServiceAppName      
        $currentTopology = $ssa.ActiveTopology
        
        $IndexComponents = (Get-SPEnterpriseSearchComponent -SearchTopology $currentTopology | Where-Object { ($_.GetType().Name -eq "IndexComponent") -and ($_.IndexPartitionOrdinal -eq $params.Index) }).ServerName
        
        return @{
            Index = $params.Index
            Servers = $IndexComponents
            RootDirectory = $params.RootDirectory
            ServiceAPpName = $params.ServiceAppName
            InstallAccount = $params.InstallAccount
        }
    }
    return $result
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  [System.UInt32]    $Index,
        [parameter(Mandatory = $true)]  [System.String[]]  $Servers,
        [parameter(Mandatory = $false)] [System.String]    $RootDirectory,
        [parameter(Mandatory = $true)]  [System.String]    $ServiceAppName,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Invoke-xSharePointCommand -Credential $InstallAccount -Arguments @($PSBoundParameters, $CurrentValues, $PSScriptRoot) -ScriptBlock {
        $params = $args[0]
        $CurrentValues = $args[1]
        $ScriptRoot = $args[2]
        $ConfirmPreference = 'None'

        $AllSearchServers = $params.Servers

        # Ensure the search service instance is running on all servers
        foreach($searchServer in $AllSearchServers) {
            $searchService = Get-SPEnterpriseSearchServiceInstance -Identity $searchServer
            if($searchService.Status -eq "Offline") {
                Write-Verbose "Start Search Service Instance"
                Start-SPEnterpriseSearchServiceInstance -Identity $searchService
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
        foreach($IndexPartitionServer in $params.Servers) {
            $networkPath = "\\$IndexPartitionServer\" + $params.RootDirectory.Replace(":\", "$\")
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

        # Index components
        $IndexParams = @{ PartitionId = $params.Index }
        if ($params.ContainsKey("RootDirectory") -eq $true) { 
            $IndexParams.Add("PartitionDirectory", $params.RootDirectory)
        } 
        Set-xSharePointSearchTopologyComponents -ComponentType "IndexComponent" `
                                                -CurrentServers $CurrentValues.Servers `
                                                -DesiredServers $params.Servers `
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
        [parameter(Mandatory = $true)]  [System.UInt32]    $Index,
        [parameter(Mandatory = $true)]  [System.String[]]  $Servers,
        [parameter(Mandatory = $false)] [System.String]    $RootDirectory,
        [parameter(Mandatory = $true)]  [System.String]    $ServiceAppName,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )
    $CurrentValues = Get-TargetResource @PSBoundParameters
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues `
                                              -DesiredValues $PSBoundParameters `
                                              -ValuesToCheck @("Servers")
}

Export-ModuleMember -Function *-TargetResource
