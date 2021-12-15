function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServiceAppName,

        [Parameter()]
        [System.Boolean]
        $AutoCreateNewManagedProperties,

        [Parameter()]
        [System.Boolean]
        $DiscoverNewProperties,

        [Parameter()]
        [System.Boolean]
        $MapToContents,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Getting Metadata Category Setting for '$Name'"

    $result = Invoke-SPDscCommand -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]

        $ssa = Get-SPEnterpriseSearchServiceApplication -Identity $params.ServiceAppName
        if ($null -eq $ssa)
        {
            $message = ("The specified Search Service Application $($params.ServiceAppName) is  `
                    invalid. Please make sure you specify the name of an existing service application.")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }
        $category = Get-SPEnterpriseSearchMetadataCategory -SearchApplication $ssa | `
                Where-Object { $_.Name -eq $params.Name }
        if ($null -eq $category)
        {
            return @{
                Name                           = $params.Name
                ServiceAppName                 = $params.ServiceAppName
                AutoCreateNewManagedProperties = $null
                DiscoverNewProperties          = $null
                MapToContents                  = $null
                Ensure                         = "Absent"
            }
        }
        else
        {
            $results = @{
                Name                           = $params.Name
                ServiceAppName                 = $params.ServiceAppName
                AutoCreateNewManagedProperties = $category.AutoCreateNewManagedProperties
                DiscoverNewProperties          = $category.DiscoverNewProperties
                MapToContents                  = $category.MapToContents
                Ensure                         = "Present"
            }
            return $results
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
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServiceAppName,

        [Parameter()]
        [System.Boolean]
        $AutoCreateNewManagedProperties,

        [Parameter()]
        [System.Boolean]
        $DiscoverNewProperties,

        [Parameter()]
        [System.Boolean]
        $MapToContents,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Setting Metadata Category Setting for '$Name'"

    # Validate that the specified crawled properties are all valid and existing
    Invoke-SPDscCommand -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]

        $ssa = Get-SPEnterpriseSearchServiceApplication -Identity $params.ServiceAppName
        if ($null -eq $ssa)
        {
            $message = ("The specified Search Service Application $($params.ServiceAppName) is  `
                    invalid. Please make sure you specify the name of an existing service application.")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }

        # Set the specified properties on the Managed Property
        $category = Get-SPEnterpriseSearchMetadataCategory -Identity $params.Name `
            -SearchApplication $params.ServiceAppName

        # The category exists and it shouldn't, delete it;
        if ($params.Ensure -eq "Absent" -and $null -ne $category)
        {
            # If the category we are trying to remove is not empty, throw an error
            if ($category.CrawledPropertyCount -gt 0)
            {
                $message = ("Cannot delete Metadata Category $($param.Name) because it contains " + `
                        "Crawled Properties. Please remove all associated Crawled Properties " + `
                        "before attempting to delete this category.")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
                throw $message
            }
            Remove-SPEnterpriseSearchMetadataCategory -Identity $params.Name `
                -SearchApplication $params.ServiceAppName `
                -Confirm:$false
        }

        # The category doesn't exist, but should
        if ($params.Ensure -eq "Present" -and $null -eq $category)
        {
            $category = New-SPEnterpriseSearchMetadataCategory -Name $params.Name `
                -SearchApplication $params.ServiceAppName
        }
        Set-SPEnterpriseSearchMetadataCategory -Identity $params.Name `
            -SearchApplication $params.ServiceAppName `
            -AutoCreateNewManagedProperties $params.AutoCreateNewManagedProperties `
            -DiscoverNewProperties $params.DiscoverNewProperties `
            -MapToContents $params.MapToContents
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
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServiceAppName,

        [Parameter()]
        [System.Boolean]
        $AutoCreateNewManagedProperties,

        [Parameter()]
        [System.Boolean]
        $DiscoverNewProperties,

        [Parameter()]
        [System.Boolean]
        $MapToContents,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Testing Metadata Category Setting for '$Name'"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("Name",
        "PropertyType",
        "Ensure",
        "AutoCreateNewManagedProperties",
        "DiscoverNewProperties",
        "MapToContents")

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

Export-ModuleMember -Function *-TargetResource
