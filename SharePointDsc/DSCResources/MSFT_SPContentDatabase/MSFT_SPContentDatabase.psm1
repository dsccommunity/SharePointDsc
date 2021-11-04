function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $DatabaseServer,

        [Parameter()]
        [System.Boolean]
        $UseSQLAuthentication,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter()]
        [System.Boolean]
        $Enabled,

        [Parameter()]
        [System.UInt16]
        $WarningSiteCount,

        [Parameter()]
        [System.UInt16]
        $MaximumSiteCount,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting content database configuration settings"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $cdb = Get-SPDatabase | Where-Object -FilterScript {
            $_.GetType().FullName -eq "Microsoft.SharePoint.Administration.SPContentDatabase" -and `
                $_.Name -eq $params.Name
        }

        if ($null -eq $cdb)
        {
            # Database does not exist
            return @{
                Name             = $params.Name
                DatabaseServer   = $params.DatabaseServer
                WebAppUrl        = $params.WebAppUrl
                Enabled          = $params.Enabled
                WarningSiteCount = $params.WarningSiteCount
                MaximumSiteCount = $params.MaximumSiteCount
                Ensure           = "Absent"
            }
        }
        else
        {
            # Database exists
            if ($cdb.Status -eq "Online")
            {
                $cdbenabled = $true
            }
            else
            {
                $cdbenabled = $false
            }

            $returnVal = @{
                Name             = $params.Name
                DatabaseServer   = $cdb.Server
                WebAppUrl        = $cdb.WebApplication.Url.Trim("/")
                Enabled          = $cdbenabled
                WarningSiteCount = $cdb.WarningSiteCount
                MaximumSiteCount = $cdb.MaximumSiteCount
                Ensure           = "Present"
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
        $Name,

        [Parameter()]
        [System.String]
        $DatabaseServer,

        [Parameter()]
        [System.Boolean]
        $UseSQLAuthentication,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter()]
        [System.Boolean]
        $Enabled,

        [Parameter()]
        [System.UInt16]
        $WarningSiteCount,

        [Parameter()]
        [System.UInt16]
        $MaximumSiteCount,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting content database configuration settings"

    $PSBoundParameters.Ensure = $Ensure

    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]

        # Use Get-SPDatabase instead of Get-SPContentDatabase because the Get-SPContentDatabase
        # does not return disabled databases.
        $cdb = Get-SPDatabase | Where-Object -FilterScript {
            $_.Type -eq "Content Database" -and $_.Name -eq $params.Name
        }

        if ($params.Ensure -eq "Present")
        {
            # Check if specified web application exists and throw exception when
            # this is not the case
            $webapp = Get-SPWebApplication | Where-Object -FilterScript {
                $_.Url.Trim("/") -eq $params.WebAppUrl.Trim("/")
            }

            if ($null -eq $webapp)
            {
                $message = "Specified web application does not exist."
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
                throw $message
            }

            # Check if database exists
            if ($null -ne $cdb)
            {
                if ($params.ContainsKey('DatabaseServer') -and $params.DatabaseServer -ne $null -and $cdb.Server -ne $params.DatabaseServer)
                {
                    $message = ("Specified database server does not match the actual database " + `
                            "server. This resource cannot move the database to a different " + `
                            "SQL instance.")
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $eventSource
                    throw $message
                }

                # Check and change attached web application.
                # Dismount and mount to correct web application
                if ($params.WebAppUrl.Trim("/") -ne $cdb.WebApplication.Url.Trim("/"))
                {
                    Dismount-SPContentDatabase $params.Name -Confirm:$false

                    $newParams = @{ }
                    foreach ($param in $params.GetEnumerator())
                    {
                        $skipParams = @("Enabled", "Ensure", "InstallAccount", "MaximumSiteCount", "WebAppUrl")

                        if ($skipParams -notcontains $param.Key)
                        {
                            $newParams.$($param.Key) = $param.Value
                        }

                        if ($param.Key -eq "MaximumSiteCount")
                        {
                            $newParams.MaxSiteCount = $param.Value
                        }

                        if ($param.Key -eq "WebAppUrl")
                        {
                            $newParams.WebApplication = $param.Value
                        }
                    }

                    try
                    {
                        $cdb = Mount-SPContentDatabase @newParams -ErrorAction Stop
                    }
                    catch
                    {
                        $message = ("Error occurred while mounting content database. " + `
                                "Content database is not mounted. " + `
                                "Error details: $($_.Exception.Message)")
                        Add-SPDscEvent -Message $message `
                            -EntryType 'Error' `
                            -EventID 100 `
                            -Source $eventSource
                        throw $message
                    }

                    if ($cdb.Status -eq "Online")
                    {
                        $cdbenabled = $true
                    }
                    else
                    {
                        $cdbenabled = $false
                    }

                    if ($params.Enabled -ne $cdbenabled)
                    {
                        switch ($params.Enabled)
                        {
                            $true
                            {
                                $cdb.Status = [Microsoft.SharePoint.Administration.SPObjectStatus]::Online
                            }
                            $false
                            {
                                $cdb.Status = [Microsoft.SharePoint.Administration.SPObjectStatus]::Disabled
                            }
                        }
                    }
                }

                # Check and change database status
                if ($cdb.Status -eq "Online")
                {
                    $cdbenabled = $true
                }
                else
                {
                    $cdbenabled = $false
                }

                if ($params.ContainsKey("Enabled") -and $params.Enabled -ne $cdbenabled)
                {
                    switch ($params.Enabled)
                    {
                        $true
                        {
                            $cdb.Status = [Microsoft.SharePoint.Administration.SPObjectStatus]::Online
                        }
                        $false
                        {
                            $cdb.Status = [Microsoft.SharePoint.Administration.SPObjectStatus]::Disabled
                        }
                    }
                }

                # Check and change site count settings
                if ($null -ne $params.WarningSiteCount -and $params.WarningSiteCount -ne $cdb.WarningSiteCount)
                {
                    $cdb.WarningSiteCount = $params.WarningSiteCount
                }

                if ($params.MaximumSiteCount -and $params.MaximumSiteCount -ne $cdb.MaximumSiteCount)
                {
                    $cdb.MaximumSiteCount = $params.MaximumSiteCount
                }
            }
            else
            {
                # Database does not exist, but should. Create/mount database
                $newParams = @{ }
                foreach ($param in $params.GetEnumerator())
                {
                    $skipParams = @("Enabled", "Ensure", "InstallAccount", "MaximumSiteCount", "WebAppUrl")

                    if ($skipParams -notcontains $param.Key)
                    {
                        $newParams.$($param.Key) = $param.Value
                    }

                    if ($param.Key -eq "MaximumSiteCount")
                    {
                        $newParams.MaxSiteCount = $param.Value
                    }

                    if ($param.Key -eq "WebAppUrl")
                    {
                        $newParams.WebApplication = $param.Value
                    }
                }

                try
                {
                    $cdb = Mount-SPContentDatabase @newParams -ErrorAction Stop
                }
                catch
                {
                    $message = ("Error occurred while mounting content database. " + `
                            "Content database is not mounted. " + `
                            "Error details: $($_.Exception.Message)")
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $eventSource
                    throw $message
                }

                if ($cdb.Status -eq "Online")
                {
                    $cdbenabled = $true
                }
                else
                {
                    $cdbenabled = $false
                }

                if ($params.ContainsKey("Enabled") -eq $true -and `
                        $params.Enabled -ne $cdbenabled)
                {
                    switch ($params.Enabled)
                    {
                        $true
                        {
                            $cdb.Status = [Microsoft.SharePoint.Administration.SPObjectStatus]::Online
                        }
                        $false
                        {
                            $cdb.Status = [Microsoft.SharePoint.Administration.SPObjectStatus]::Disabled
                        }
                    }
                }
            }
            $cdb.Update()
        }
        else
        {
            if ($null -ne $cdb)
            {
                # Database exists, but shouldn't. Dismount database
                Dismount-SPContentDatabase $params.Name -Confirm:$false
            }
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
        $Name,

        [Parameter()]
        [System.String]
        $DatabaseServer,

        [Parameter()]
        [System.Boolean]
        $UseSQLAuthentication,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter()]
        [System.Boolean]
        $Enabled,

        [Parameter()]
        [System.UInt16]
        $WarningSiteCount,

        [Parameter()]
        [System.UInt16]
        $MaximumSiteCount,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing content database configuration settings"

    $PSBoundParameters.Ensure = $Ensure
    $PSBoundParameters.WebAppUrl = $WebAppUrl.TrimEnd("/")

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($PSBoundParameters.ContainsKey('DatabaseServer') -and $PSBoundParameters.DatabaseServer -ne $null -and $CurrentValues.DatabaseServer -ne $PSBoundParameters.DatabaseServer)
    {
        $message = ("Specified database server $DatabaseServer does not match the actual " + `
                "database server $($CurrentValues.DatabaseServer). This resource cannot move " + `
                "the database to a different SQL instance.")
        Write-Verbose -Message $message
        Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

        Write-Verbose -Message "Test-TargetResource returned false"
        return $false
    }

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath "\DSCResources\MSFT_SPContentDatabase\MSFT_SPContentDatabase.psm1" -Resolve

    $params = Get-DSCFakeParameters -ModulePath $module
    $spContentDBs = Get-SPContentDatabase

    $Content = ''
    $i = 1
    $total = $spContentDBs.Length
    foreach ($spContentDB in $spContentDBs)
    {
        try
        {
            $dbName = $spContentDB.Name
            Write-Host "Scanning Content Database [$i/$total] {$dbName}"
            $PartialContent = "        SPContentDatabase " + $spContentDB.Name.Replace(" ", "") + "`r`n"
            $PartialContent += "        {`r`n"
            $params.Name = $dbName
            $params.WebAppUrl = $spContentDB.WebApplication.Url
            $results = Get-TargetResource @params
            $results = Repair-Credentials -results $results

            Add-ConfigurationDataEntry -Node "NonNodeData" -Key "DatabaseServer" -Value $results.DatabaseServer -Description "Name of the Database Server associated with the destination SharePoint Farm;"
            $results.DatabaseServer = "`$ConfigurationData.NonNodeData.DatabaseServer"

            $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
            $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "DatabaseServer"
            $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
            $PartialContent += $currentBlock
            $PartialContent += "        }`r`n"
            $i++
        }
        catch
        {
            $Global:ErrorLog += "[Content Database]" + $spContentDB.Name + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
        $Content += $PartialContent
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
