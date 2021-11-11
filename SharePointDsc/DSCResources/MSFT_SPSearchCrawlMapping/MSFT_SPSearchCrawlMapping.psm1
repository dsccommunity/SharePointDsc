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
        [System.String]
        $Url,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Target,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Getting Search Crawl Mapping for '$Url'"

    $result = Invoke-SPDscCommand -Arguments $PSBoundParameters `
        -ScriptBlock {

        $params = $args[0]
        $searchApp = Get-SPEnterpriseSearchServiceApplication -Identity $params.ServiceAppName
        if ($null -eq $searchApp)
        {
            Write-Verbose -Message "Search Service Application $($params.ServiceAppName) not found"
            $returnVal = @{
                ServiceAppName = ""
                Url            = $params.Url
                Target         = ""
                Ensure         = "Absent"
            }
            return $returnVal
        }

        $mappings = $searchApp | Get-SPEnterpriseSearchCrawlMapping

        if ($null -eq $mappings)
        {
            Write-Verbose -Message "Search Service Application $($params.ServiceAppName) has no mappings"
            $returnVal = @{
                ServiceAppName = $params.ServiceAppName
                Url            = $params.Url
                Target         = ""
                Ensure         = "Absent"
            }
            return $returnVal
        }

        $mapping = $mappings | Where-Object -FilterScript { $_.Source -eq "$($params.Url)" } | Select-Object -First 1

        if ($null -eq $mapping)
        {
            Write-Verbose "Search Service Application $($params.ServiceAppName) has no matching mapping"
            $returnVal = @{
                ServiceAppName = $params.ServiceAppName
                Url            = $params.Url
                Target         = ""
                Ensure         = "Absent"
            }
            return $returnVal
        }
        else
        {
            Write-Verbose "Search Service Application $($params.ServiceAppName) has a matching mapping"
            $returnVal = @{
                ServiceAppName = $params.ServiceAppName
                Url            = $mapping.Source
                Target         = $mapping.Target
                Ensure         = "Present"
            }
            return $returnVal
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
        [System.String]
        $Url,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Target,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )
    Write-Verbose -Message "Setting Search Crawl Mapping Rule '$Url'"
    $result = Get-TargetResource @PSBoundParameters

    if ($result.Ensure -eq "Absent" -and $Ensure -eq "Present")
    {
        Write-Verbose "Adding the Crawl Mapping '$Url'"

        Invoke-SPDscCommand -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
            -ScriptBlock {
            $params = $args[0]
            $eventSource = $args[1]

            $searchApp = Get-SPEnterpriseSearchServiceApplication -Identity $params.ServiceAppName
            if ($null -eq $searchApp)
            {
                $message = "The Search Service Application does not exist"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
                throw $message
            }
            else
            {
                New-SPEnterpriseSearchCrawlMapping -SearchApplication $searchApp -Url $params.Url -Target $params.Target
            }
        }
    }
    if ($result.Ensure -eq "Present" -and $Ensure -eq "Present")
    {
        Write-Verbose "Updating the Crawl Mapping '$Url'"
        Invoke-SPDscCommand -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            $searchApp = Get-SPEnterpriseSearchServiceApplication -Identity $params.ServiceAppName
            $mappings = $searchApp | Get-SPEnterpriseSearchCrawlMapping
            $mapping = $mappings | Where-Object -FilterScript { $_.Source -eq $params.Url } | Select-Object -First 1
            $mapping | Remove-SPEnterpriseSearchCrawlMapping

            New-SPEnterpriseSearchCrawlMapping -SearchApplication $searchApp -Url $params.Url -Target $params.Target
        }
    }
    if ($result.Ensure -eq "Present" -and $Ensure -eq "Absent")
    {
        Write-Verbose "Removing the Crawl Mapping '$Url'"
        Invoke-SPDscCommand -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            $searchapp = Get-SPEnterpriseSearchServiceApplication -Identity $params.ServiceAppName
            $mappings = $searchApp | Get-SPEnterpriseSearchCrawlMapping
            $mapping = $mappings | Where-Object -FilterScript { $_.Source -eq $params.Url } | Select-Object -First 1
            $mapping | Remove-SPEnterpriseSearchCrawlMapping
        }
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
        [System.String]
        $Url,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Target,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )
    Write-Verbose -Message "Testing Search Crawl Mapping for '$Url'"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($Ensure -eq "Present")
    {
        $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("ServiceAppName", "Url", "Target", "Ensure")
    }
    else
    {
        $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("Ensure")
    }

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

Export-ModuleMember -Function *-TargetResource
