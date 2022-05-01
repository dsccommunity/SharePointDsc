function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServiceAppName,

        [Parameter()]
        [System.String]
        $DatabaseServer,

        [Parameter()]
        [System.Boolean]
        $UseSQLAuthentication,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Getting Search Crawl Database '$DatabaseName'"

    $result = Invoke-SPDscCommand -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        Write-Verbose -Message "Getting Search Service Application $($params.ServiceAppName)"
        $ssa = Get-SPEnterpriseSearchServiceApplication -Identity $params.ServiceAppName `
            -Verbose:$false `
            -ErrorAction SilentlyContinue

        if ($null -eq $ssa)
        {
            return @{
                DatabaseName   = $params.DatabaseName
                ServiceAppName = $null
                DatabaseServer = $null
                Ensure         = 'Absent'
            }
        }

        Write-Verbose -Message 'Looking for Crawl Databases'
        $crawldb = Get-SPEnterpriseSearchCrawlDatabase -SearchApplication $ssa `
            -Verbose:$false | Where-Object -FilterScript {
            $_.Name -eq $params.DatabaseName
        }

        if ($null -eq $crawldb)
        {
            Write-Verbose -Message 'Crawl database not found'
            return @{
                DatabaseName   = $params.DatabaseName
                ServiceAppName = $params.ServiceAppName
                DatabaseServer = $null
                Ensure         = 'Absent'
            }
        }

        Write-Verbose -Message 'Crawl database found, returning details'
        return @{
            DatabaseName   = $params.DatabaseName
            ServiceAppName = $params.ServiceAppName
            DatabaseServer = $crawldb.Database.NormalizedDataSource
            Ensure         = 'Present'
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
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServiceAppName,

        [Parameter()]
        [System.String]
        $DatabaseServer,

        [Parameter()]
        [System.Boolean]
        $UseSQLAuthentication,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Setting Search Crawl Database '$DatabaseName'"

    $PSBoundParameters.Ensure = $Ensure

    $result = Get-TargetResource @PSBoundParameters

    if ($result.Ensure -eq "Absent" -and $Ensure -eq "Present")
    {
        Write-Verbose -Message 'Creating Crawl Database since it does not exist'

        Invoke-SPDscCommand -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
            -ScriptBlock {
            $params = $args[0]
            $eventSource = $args[1]

            Write-Verbose -Message "Getting Search Service Application $($params.ServiceAppName)"
            $ssa = Get-SPEnterpriseSearchServiceApplication -Identity $params.ServiceAppName `
                -Verbose:$false `
                -ErrorAction SilentlyContinue

            if ($null -eq $ssa)
            {
                $message = 'Specified Search service application could not be found!'
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
                throw $message
            }

            $newParams = @{
                SearchApplication = $ssa
                DatabaseName      = $params.DatabaseName
            }

            if ($params.ContainsKey('DatabaseServer'))
            {
                Write-Verbose -Message "DatabaseServer parameter specified. Creating database on server $($params.DatabaseServer)."
                $newParams.Add("DatabaseServer", $params.DatabaseServer)
            }

            if ($params.useSQLAuthentication -eq $true)
            {
                Write-Verbose -Message "Using SQL authentication to create service application as `$useSQLAuthentication is set to $($params.useSQLAuthentication)."
                $newParams.Add("DatabaseUsername", $params.DatabaseCredentials.Username)
                $newParams.Add("DatabasePassword", $params.DatabaseCredentials.Password)
            }
            else
            {
                Write-Verbose -Message "`$useSQLAuthentication is false or not specified; using default Windows authentication."
            }

            $null = New-SPEnterpriseSearchCrawlDatabase @newParams -Verbose:$false
            Write-Verbose "Crawl database $($params.DatabaseName) created!"
        }
    }

    if ($Ensure -eq "Absent")
    {
        # The service app should not exit
        Write-Verbose -Message "Removing Search Crawl Database '$DatabaseName'"
        Invoke-SPDscCommand -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
            -ScriptBlock {
            $params = $args[0]
            $eventSource = $args[1]

            Write-Verbose -Message "Getting Search Service Application $($params.ServiceAppName)"
            $ssa = Get-SPEnterpriseSearchServiceApplication -Identity $params.ServiceAppName `
                -Verbose:$false `
                -ErrorAction SilentlyContinue

            if ($null -eq $ssa)
            {
                $message = 'Specified Search service application could not be found!'
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
                throw $message
            }

            Write-Verbose "Removing crawl database '$($params.DatabaseName)'"
            Remove-SPEnterpriseSearchCrawlDatabase -SearchApplication $ssa `
                -Identity $params.DatabaseName `
                -Confirm:$false `
                -Verbose:$false
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
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServiceAppName,

        [Parameter()]
        [System.String]
        $DatabaseServer,

        [Parameter()]
        [System.Boolean]
        $UseSQLAuthentication,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Testing Search Crawl Database '$DatabaseName'"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("Ensure")

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [System.String]
        $SearchSAName,

        [Parameter()]
        [System.String[]]
        $DependsOn
    )

    $VerbosePreference = "SilentlyContinue"

    $content = ''
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath "\DSCResources\MSFT_SPSearchCrawlDatabase\MSFT_SPSearchCrawlDatabase.psm1" -Resolve

    $crawlDBs = Get-SPEnterpriseSearchCrawlDatabase -SearchApplication $SearchSAName `
        -Verbose:$false

    $j = 1
    $totalDBs = $crawlDBs.Count

    foreach ($crawlDB in $crawlDBs)
    {
        $dbName = $crawlDB.Name
        Write-Host "    -> Scanning Search Crawl Databases [$j/$totalDBs] {$dbName}"
        try
        {
            $params = Get-DSCFakeParameters -ModulePath $module

            $partialContent = "        SPSearchCrawlDatabase " + $dbName.Replace(" ", "") + "`r`n"
            $partialContent += "        {`r`n"
            $params.DatabaseName = $dbName
            $params.ServiceAppName = $SearchSAName
            $results = Get-TargetResource @params

            $results = Repair-Credentials -results $results

            Add-ConfigurationDataEntry -Node "NonNodeData" -Key "DatabaseServer" -Value $results.DatabaseServer -Description "Name of the Database Server associated with the destination SharePoint Farm;"
            $results.DatabaseServer = "`$ConfigurationData.NonNodeData.DatabaseServer"

            if ($dependsOn)
            {
                $results.add("DependsOn", $dependsOn)
            }

            $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
            $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "DatabaseServer"
            $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
            $partialContent += $currentBlock
            $partialContent += "        }`r`n"

            $j++
            $content += $partialContent
        }
        catch
        {
            $_
            $Global:ErrorLog += "[Search Crawl Database]" + $crawlDB.Name + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
    }

    return $content
}

Export-ModuleMember -Function *-TargetResource
