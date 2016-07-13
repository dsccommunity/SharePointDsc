function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  
        [System.String] 
        $Name,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $SearchServiceAppName,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $Query,

        [parameter(Mandatory = $true)]  
        [ValidateSet("Best Bet Provider", 
                     "Exchange Search Provider", 
                     "Local People Provider", 
                     "Local", 
                     "SharePoint Provider", 
                     "OpenSearch Provider", 
                     "Personal Favorites Provider", 
                     "Remote People Provider", 
                     "Remote SharePoint Provider")] 
        [System.String] 
        $ProviderType,

        [parameter(Mandatory = $false)] 
        [Microsoft.Management.Infrastructure.CimInstance[]] 
        $SortOptions,

        [parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present",

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Getting search result source '$Name'"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $serviceApp = Get-SPEnterpriseSearchServiceApplication -Identity $params.SearchServiceAppName
        $fedManager = New-Object -TypeName Microsoft.Office.Server.Search.Administration.Query.FederationManager `
                                 -ArgumentList $serviceApp

        try 
        {
            $source = $fedManager.GetSourceByName($params.Name)

            #TODO: Get the properties off the $source object and build up a return value
        }
        catch [System.Exception] {
            return @{
                Name = $params.Name
                SearchServiceAppName = $params.SearchServiceAppName
                Query = $null
                ProviderType = $null
                SortOptions = $null
                Ensure = "Absent"
                InstallAccount = $params.InstallAccount
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

        [parameter(Mandatory = $true)]  
        [System.String] 
        $SearchServiceAppName,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $Query,

        [parameter(Mandatory = $true)]  
        [ValidateSet("Best Bet Provider", 
                     "Exchange Search Provider", 
                     "Local People Provider", 
                     "Local", 
                     "SharePoint Provider", 
                     "OpenSearch Provider", 
                     "Personal Favorites Provider", 
                     "Remote People Provider", 
                     "Remote SharePoint Provider")] 
        [System.String] 
        $ProviderType,

        [parameter(Mandatory = $false)] 
        [Microsoft.Management.Infrastructure.CimInstance[]] 
        $SortOptions,

        [parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present",

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    
    Write-Verbose -Message "Creating search result source '$Name'"

    if ($CurrentValues.Ensure -eq "Absent" -and $Ensure -eq "Present") {
        Write-Verbose -Message "Creating search result source $Name"
        Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            [void] [Reflection.Assembly]::LoadWithPartialName("Microsoft.Office.Server.Search")
            
            $serviceApp = Get-SPEnterpriseSearchServiceApplication -Identity $params.SearchServiceAppName
            $searchSite = Get-SPWeb -Identity $serviceApp.SearchCenterUrl

            $fedManager = New-Object -TypeName Microsoft.Office.Server.Search.Administration.Query.FederationManager `
                                     -ArgumentList $serviceApp
            $searchOwner = New-Object -TypeName Microsoft.Office.Server.Search.Administration.SearchObjectOwner `
                                      -ArgumentList @(
                                          [Microsoft.Office.Server.Search.Administration.SearchObjectLevel]::Ssa, 
                                          $searchSite
                                        )
            $queryProperties = New-Object -TypeName Microsoft.Office.Server.Search.Query.Rules.QueryTransformProperties
            $sortCollection = New-Object - TypeName Microsoft.Office.Server.Search.Query.SortCollection

            if ($params.ContainsKey("SortOptions"))
            {
                foreach($sortObject in $params.SortOptions)
                {
                    $sortDir = [Microsoft.Office.Server.Search.Query.SortDirection]::($sortObject.SortDirection)
                    $sortCollection.Add($sortObject.PropertyName, $sortDir)
                }
            }
            $queryProperties["SortList"] = [Microsoft.Office.Server.Search.Query.SortCollection]$sortCollection

            $resultSource = $fedManager.CreateSource($searchOwner)
            $resultSource.Name = $params.Name

            $providers = $fedManager.ListProviders()
            $resultSource.ProviderId = $providers[$params.ProviderType].Id
            $resultSource.CreateQueryTransform($queryProperties, $params.Query)
            $resultSource.Commit()
        }
    }
    if ($Ensure -eq "Absent") {
        Write-Verbose -Message "Removing search result source $Name"
        Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            
            $serviceApp = Get-SPEnterpriseSearchServiceApplication -Identity $params.SearchServiceAppName
            $fedManager = New-Object -TypeName Microsoft.Office.Server.Search.Administration.Query.FederationManager `
                                     -ArgumentList $serviceApp

            $source = $fedManager.GetSourceByName($params.Name)
            $fedManager.RemoveSource($source)                 
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

        [parameter(Mandatory = $true)]  
        [System.String] 
        $SearchServiceAppName,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $Query,

        [parameter(Mandatory = $true)]  
        [ValidateSet("Best Bet Provider", 
                     "Exchange Search Provider", 
                     "Local People Provider", 
                     "Local", 
                     "SharePoint Provider", 
                     "OpenSearch Provider", 
                     "Personal Favorites Provider", 
                     "Remote People Provider", 
                     "Remote SharePoint Provider")] 
        [System.String] 
        $ProviderType,

        [parameter(Mandatory = $false)] 
        [Microsoft.Management.Infrastructure.CimInstance[]] 
        $SortOptions,

        [parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present",

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing search result source '$Name'"
    $PSBoundParameters.Ensure = $Ensure
    
    return Test-SPDscParameterState -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("Ensure") 
}

Export-ModuleMember -Function *-TargetResource

