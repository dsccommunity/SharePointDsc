$Script:TrustLocationProperties = @(
    "Address",
    "LocationType",
    "IncludeChildren",
    "SessionTimeout",
    "ShortSessionTimeout",
    "NewWorkbookSessionTimeout",
    "RequestDurationMax",
    "ChartRenderDurationMax",
    "WorkbookSizeMax",
    "ChartAndImageSizeMax",
    "AutomaticVolatileFunctionCacheLifetime",
    "DefaultWorkbookCalcMode",
    "ExternalDataAllowed",
    "WarnOnDataRefresh",
    "DisplayGranularExtDataErrors",
    "AbortOnRefreshOnOpenFail",
    "PeriodicExtDataCacheLifetime",
    "ManualExtDataCacheLifetime",
    "ConcurrentDataRequestsPerSessionMax",
    "UdfsAllowed",
    "Description",
    "RESTExternalDataAllowed"
)
$Script:ServiceAppObjectType = "Microsoft.Office.Excel.Server.MossHost.ExcelServerWebServiceApplication"

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $TrustedFileLocations,

        [Parameter()]
        [System.Boolean]
        $CachingOfUnusedFilesEnable,

        [Parameter()]
        [System.Boolean]
        $CrossDomainAccessAllowed,

        [Parameter()]
        [ValidateSet("None", "Connection")]
        [System.String]
        $EncryptedUserConnectionRequired,

        [Parameter()]
        [System.UInt32]
        $ExternalDataConnectionLifetime,

        [Parameter()]
        [ValidateSet("UseImpersonation", "UseFileAccessAccount")]
        [System.String]
        $FileAccessMethod,

        [Parameter()]
        [ValidateSet("RoundRobin", "Local", "WorkbookURL")]
        [System.String]
        $LoadBalancingScheme,

        [Parameter()]
        [System.UInt32]
        $MemoryCacheThreshold,

        [Parameter()]
        [System.Int32]
        $PrivateBytesMax,

        [Parameter()]
        [System.UInt32]
        $SessionsPerUserMax,

        [Parameter()]
        [System.UInt32]
        $SiteCollectionAnonymousSessionsMax,

        [Parameter()]
        [System.Boolean]
        $TerminateProcessOnAccessViolation,

        [Parameter()]
        [System.UInt32]
        $ThrottleAccessViolationsPerSiteCollection,

        [Parameter()]
        [System.String]
        $UnattendedAccountApplicationId,

        [Parameter()]
        [System.Int32]
        $UnusedObjectAgeMax,

        [Parameter()]
        [System.String]
        $WorkbookCache,

        [Parameter()]
        [System.UInt32]
        $WorkbookCacheSizeMax,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Getting Excel Services Application '$Name'"

    if ((Get-SPDscInstalledProductVersion).FileMajorPart -ne 15)
    {
        $message = ("Only SharePoint 2013 is supported to deploy Excel Services " + `
                "service applications via DSC, as SharePoint 2016 and SharePoint 2019 deprecated " + `
                "this service. See " + `
                "https://docs.microsoft.com/en-us/SharePoint/what-s-new/what-s-deprecated-or-removed-from-sharepoint-server-2016 " + `
                "for more info.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $result = Invoke-SPDscCommand -Arguments @($PSBoundParameters, $Script:ServiceAppObjectType) `
        -ScriptBlock {
        $params = $args[0]
        $serviceAppObjectType = $args[1]

        $serviceApps = Get-SPServiceApplication | Where-Object -FilterScript {
            $_.Name -eq $params.Name
        }

        $nullReturn = @{
            Name            = $params.Name
            ApplicationPool = $params.ApplicationPool
            Ensure          = "Absent"
        }
        if ($null -eq $serviceApps)
        {
            return $nullReturn
        }
        $serviceApp = $serviceApps | Where-Object -FilterScript {
            $_.GetType().FullName -eq $serviceAppObjectType
        }

        if ($null -eq $serviceApp)
        {
            return $nullReturn
        }
        else
        {
            $fileLocations = Get-SPExcelFileLocation -ExcelServiceApplication $serviceApp
            $fileLocationsToReturn = @()
            $fileLocations | ForEach-Object -Process {
                $fileLocationsToReturn += @{
                    Address                                = $_.Address
                    LocationType                           = $_.LocationType
                    IncludeChildren                        = [Convert]::ToBoolean($_.IncludeChildren)
                    SessionTimeout                         = $_.SessionTimeout
                    ShortSessionTimeout                    = $_.ShortSessionTimeout
                    NewWorkbookSessionTimeout              = $_.NewWorkbookSessionTimeout
                    RequestDurationMax                     = $_.RequestDurationMax
                    ChartRenderDurationMax                 = $_.ChartRenderDurationMax
                    WorkbookSizeMax                        = $_.WorkbookSizeMax
                    ChartAndImageSizeMax                   = $_.ChartAndImageSizeMax
                    AutomaticVolatileFunctionCacheLifetime = $_.AutomaticVolatileFunctionCacheLifetime
                    DefaultWorkbookCalcMode                = $_.DefaultWorkbookCalcMode
                    ExternalDataAllowed                    = $_.ExternalDataAllowed
                    WarnOnDataRefresh                      = [Convert]::ToBoolean($_.WarnOnDataRefresh)
                    DisplayGranularExtDataErrors           = [Convert]::ToBoolean($_.DisplayGranularExtDataErrors)
                    AbortOnRefreshOnOpenFail               = [Convert]::ToBoolean($_.AbortOnRefreshOnOpenFail)
                    PeriodicExtDataCacheLifetime           = $_.PeriodicExtDataCacheLifetime
                    ManualExtDataCacheLifetime             = $_.ManualExtDataCacheLifetime
                    ConcurrentDataRequestsPerSessionMax    = $_.ConcurrentDataRequestsPerSessionMax
                    UdfsAllowed                            = [Convert]::ToBoolean($_.UdfsAllowed)
                    Description                            = $_.Description
                    RESTExternalDataAllowed                = [Convert]::ToBoolean($_.RESTExternalDataAllowed)
                }
            }

            $returnVal = @{
                Name                                      = $serviceApp.DisplayName
                ApplicationPool                           = $serviceApp.ApplicationPool.Name
                Ensure                                    = "Present"
                TrustedFileLocations                      = $fileLocationsToReturn
                CachingOfUnusedFilesEnable                = $serviceApp.CachingOfUnusedFilesEnable
                CrossDomainAccessAllowed                  = $serviceApp.CrossDomainAccessAllowed
                EncryptedUserConnectionRequired           = $serviceApp.EncryptedUserConnectionRequired
                ExternalDataConnectionLifetime            = $serviceApp.ExternalDataConnectionLifetime
                FileAccessMethod                          = $serviceApp.FileAccessMethod
                LoadBalancingScheme                       = $serviceApp.LoadBalancingScheme
                MemoryCacheThreshold                      = $serviceApp.MemoryCacheThreshold
                PrivateBytesMax                           = $serviceApp.PrivateBytesMax
                SessionsPerUserMax                        = $serviceApp.SessionsPerUserMax
                SiteCollectionAnonymousSessionsMax        = $serviceApp.SiteCollectionAnonymousSessionsMax
                TerminateProcessOnAccessViolation         = $serviceApp.TerminateProcessOnAccessViolation
                ThrottleAccessViolationsPerSiteCollection = $serviceApp.ThrottleAccessViolationsPerSiteCollection
                UnattendedAccountApplicationId            = $serviceApp.UnattendedAccountApplicationId
                UnusedObjectAgeMax                        = $serviceApp.UnusedObjectAgeMax
                WorkbookCache                             = $serviceApp.WorkbookCache
                WorkbookCacheSizeMax                      = $serviceApp.WorkbookCacheSizeMax
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

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $TrustedFileLocations,

        [Parameter()]
        [System.Boolean]
        $CachingOfUnusedFilesEnable,

        [Parameter()]
        [System.Boolean]
        $CrossDomainAccessAllowed,

        [Parameter()]
        [ValidateSet("None", "Connection")]
        [System.String]
        $EncryptedUserConnectionRequired,

        [Parameter()]
        [System.UInt32]
        $ExternalDataConnectionLifetime,

        [Parameter()]
        [ValidateSet("UseImpersonation", "UseFileAccessAccount")]
        [System.String]
        $FileAccessMethod,

        [Parameter()]
        [ValidateSet("RoundRobin", "Local", "WorkbookURL")]
        [System.String]
        $LoadBalancingScheme,

        [Parameter()]
        [System.UInt32]
        $MemoryCacheThreshold,

        [Parameter()]
        [System.Int32]
        $PrivateBytesMax,

        [Parameter()]
        [System.UInt32]
        $SessionsPerUserMax,

        [Parameter()]
        [System.UInt32]
        $SiteCollectionAnonymousSessionsMax,

        [Parameter()]
        [System.Boolean]
        $TerminateProcessOnAccessViolation,

        [Parameter()]
        [System.UInt32]
        $ThrottleAccessViolationsPerSiteCollection,

        [Parameter()]
        [System.String]
        $UnattendedAccountApplicationId,

        [Parameter()]
        [System.Int32]
        $UnusedObjectAgeMax,

        [Parameter()]
        [System.String]
        $WorkbookCache,

        [Parameter()]
        [System.UInt32]
        $WorkbookCacheSizeMax,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Setting Excel Services Application '$Name'"

    if ((Get-SPDscInstalledProductVersion).FileMajorPart -ne 15)
    {
        $message = ("Only SharePoint 2013 is supported to deploy Excel Services " + `
                "service applications via DSC, as SharePoint 2016 and SharePoint 2019 deprecated " + `
                "this service. See " + `
                "https://docs.microsoft.com/en-us/SharePoint/what-s-new/what-s-deprecated-or-removed-from-sharepoint-server-2016 " + `
                "for more info.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }
    $result = Get-TargetResource @PSBoundParameters

    if ($result.Ensure -eq "Absent" -and $Ensure -eq "Present")
    {
        Write-Verbose -Message "Creating Excel Services Application $Name"
        Invoke-SPDscCommand -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            New-SPExcelServiceApplication -Name $params.Name `
                -ApplicationPool $params.ApplicationPool `
                -Default
        }
    }

    if ($Ensure -eq "Present")
    {
        Write-Verbose -Message "Updating settings for Excel Services Application $Name"
        Invoke-SPDscCommand -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            $newParams = @{
                Identity = $params.Name
            }

            foreach ($key in $params.Keys)
            {
                if ($key -notin @("Ensure", "TrustedFileLocations", "Name", "ApplicationPool"))
                {
                    $newParams.Add($key, $params.$key)
                }
            }

            Set-SPExcelServiceApplication @newParams
        }


        # Update trusted locations
        if ($null -ne $TrustedFileLocations)
        {
            $TrustedFileLocations | ForEach-Object -Process {
                $desiredLocation = $_
                $matchingCurrentValue = $result.TrustedFileLocations | Where-Object -FilterScript {
                    $_.Address -eq $desiredLocation.Address
                }
                if ($null -eq $matchingCurrentValue)
                {
                    Write-Verbose -Message "Adding trusted location '$($desiredLocation.Address)' to service app"
                    Invoke-SPDscCommand -Arguments @($PSBoundParameters, $desiredLocation, $Script:TrustLocationProperties, $Script:ServiceAppObjectType) `
                        -ScriptBlock {
                        $params = $args[0]
                        $desiredLocation = $args[1]
                        $trustLocationProperties = $args[2]
                        $serviceAppObjectType = $args[3]

                        $newArgs = @{ }
                        $trustLocationProperties | ForEach-Object -Process {
                            if ($null -ne $desiredLocation.$_)
                            {
                                $newArgs.Add($_, $desiredLocation.$_)
                            }
                        }
                        $serviceApp = Get-SPServiceApplication | Where-Object -FilterScript {
                            $_.Name -eq $params.Name -and `
                                $_.GetType().FullName -eq $serviceAppObjectType
                        }
                        $newArgs.Add("ExcelServiceApplication", $serviceApp)

                        New-SPExcelFileLocation @newArgs
                    }
                }
                else
                {
                    Write-Verbose -Message "Updating trusted location '$($desiredLocation.Address)' in service app"
                    Invoke-SPDscCommand -Arguments @($PSBoundParameters, $desiredLocation, $Script:TrustLocationProperties, $Script:ServiceAppObjectType) `
                        -ScriptBlock {
                        $params = $args[0]
                        $desiredLocation = $args[1]
                        $trustLocationProperties = $args[2]
                        $serviceAppObjectType = $args[3]

                        $updateArgs = @{ }
                        $trustLocationProperties | ForEach-Object -Process {
                            if ($null -ne $desiredLocation.$_)
                            {
                                $updateArgs.Add($_, $desiredLocation.$_)
                            }
                        }
                        $serviceApp = Get-SPServiceApplication | Where-Object -FilterScript {
                            $_.Name -eq $params.Name -and `
                                $_.GetType().FullName -eq $serviceAppObjectType
                        }
                        $updateArgs.Add("Identity", $desiredLocation.Address)
                        $updateArgs.Add("ExcelServiceApplication", $serviceApp)

                        Set-SPExcelFileLocation @updateArgs
                    }
                }
            }

            # Remove unlisted trusted locations
            $result.TrustedFileLocations | ForEach-Object -Process {
                $currentLocation = $_
                $matchingDesiredValue = $TrustedFileLocations | Where-Object -FilterScript {
                    $_.Address -eq $currentLocation.Address
                }
                if ($null -eq $matchingDesiredValue)
                {
                    Write-Verbose -Message "Removing trusted location '$($currentLocation.Address)' from service app"
                    Invoke-SPDscCommand -Arguments @($Name, $currentLocation) `
                        -ScriptBlock {
                        $name = $args[0]
                        $currentLocation = $args[1]

                        Remove-SPExcelFileLocation -ExcelServiceApplication $name -Identity $currentLocation.Address -Confirm:$false
                    }
                }
            }
        }
    }

    if ($Ensure -eq "Absent")
    {
        Write-Verbose -Message "Removing Excel Service Application $Name"
        Invoke-SPDscCommand -Arguments @($PSBoundParameters, $Script:ServiceAppObjectType) `
            -ScriptBlock {
            $params = $args[0]
            $serviceAppObjectType = $args[1]

            $serviceApp = Get-SPServiceApplication | Where-Object -FilterScript {
                $_.Name -eq $params.Name -and `
                    $_.GetType().FullName -eq $serviceAppObjectType
            }

            $proxies = Get-SPServiceApplicationProxy
            foreach ($proxyInstance in $proxies)
            {
                if ($serviceApp.IsConnected($proxyInstance))
                {
                    $proxyInstance.Delete()
                }
            }

            Remove-SPServiceApplication -Identity $serviceApp -Confirm:$false
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

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $TrustedFileLocations,

        [Parameter()]
        [System.Boolean]
        $CachingOfUnusedFilesEnable,

        [Parameter()]
        [System.Boolean]
        $CrossDomainAccessAllowed,

        [Parameter()]
        [ValidateSet("None", "Connection")]
        [System.String]
        $EncryptedUserConnectionRequired,

        [Parameter()]
        [System.UInt32]
        $ExternalDataConnectionLifetime,

        [Parameter()]
        [ValidateSet("UseImpersonation", "UseFileAccessAccount")]
        [System.String]
        $FileAccessMethod,

        [Parameter()]
        [ValidateSet("RoundRobin", "Local", "WorkbookURL")]
        [System.String]
        $LoadBalancingScheme,

        [Parameter()]
        [System.UInt32]
        $MemoryCacheThreshold,

        [Parameter()]
        [System.Int32]
        $PrivateBytesMax,

        [Parameter()]
        [System.UInt32]
        $SessionsPerUserMax,

        [Parameter()]
        [System.UInt32]
        $SiteCollectionAnonymousSessionsMax,

        [Parameter()]
        [System.Boolean]
        $TerminateProcessOnAccessViolation,

        [Parameter()]
        [System.UInt32]
        $ThrottleAccessViolationsPerSiteCollection,

        [Parameter()]
        [System.String]
        $UnattendedAccountApplicationId,

        [Parameter()]
        [System.Int32]
        $UnusedObjectAgeMax,

        [Parameter()]
        [System.String]
        $WorkbookCache,

        [Parameter()]
        [System.UInt32]
        $WorkbookCacheSizeMax,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Testing Excel Services Application '$Name'"

    $PSBoundParameters.Ensure = $Ensure

    if ((Get-SPDscInstalledProductVersion).FileMajorPart -ne 15)
    {
        $message = ("Only SharePoint 2013 is supported to deploy Excel Services " + `
                "service applications via DSC, as SharePoint 2016 and SharePoint 2019 deprecated " + `
                "this service. See " + `
                "https://docs.microsoft.com/en-us/SharePoint/what-s-new/what-s-deprecated-or-removed-from-sharepoint-server-2016 " + `
                "for more info.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $mainCheck = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @(
        "Ensure",
        "CachingOfUnusedFilesEnable",
        "CrossDomainAccessAllowed",
        "EncryptedUserConnectionRequired",
        "ExternalDataConnectionLifetime",
        "FileAccessMethod",
        "LoadBalancingScheme",
        "MemoryCacheThreshold",
        "PrivateBytesMax",
        "SessionsPerUserMax",
        "SiteCollectionAnonymousSessionsMax",
        "TerminateProcessOnAccessViolation",
        "ThrottleAccessViolationsPerSiteCollection",
        "UnattendedAccountApplicationId",
        "UnusedObjectAgeMax",
        "WorkbookCache",
        "WorkbookCacheSizeMax"
    )


    if ($Ensure -eq "Present" -and $mainCheck -eq $true -and $null -ne $TrustedFileLocations)
    {
        # Check that all the desired types are in the current values and match
        $locationCheck = $TrustedFileLocations | ForEach-Object -Process {
            $desiredLocation = $_
            $matchingCurrentValue = $CurrentValues.TrustedFileLocations | Where-Object -FilterScript {
                $_.Address -eq $desiredLocation.Address
            }
            if ($null -eq $matchingCurrentValue)
            {
                $message = ("Trusted file location '$($_.Address)' was not found " + `
                        "in the Excel service app. Desired state is false.")
                Write-Verbose -Message $message
                Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

                return $false
            }
            else
            {
                $Script:TrustLocationProperties | ForEach-Object -Process {
                    if ($desiredLocation.CimInstanceProperties.Name -contains $_)
                    {
                        if ($desiredLocation.$_ -ne $matchingCurrentValue.$_)
                        {
                            $message = ("Trusted file location '$($desiredLocation.Address)' did not match " + `
                                    "desired property '$_'. Desired value is " + `
                                    "'$($desiredLocation.$_)' but the current value is " + `
                                    "'$($matchingCurrentValue.$_)'")
                            Write-Verbose -Message $message
                            Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

                            return $false
                        }
                    }
                }
            }
            return $true
        }
        if ($locationCheck -contains $false)
        {
            Write-Verbose -Message "Test-TargetResource returned false"

            return $false
        }

        # Check that any other existing trusted locations are in the desired state
        $locationCheck = $CurrentValues.TrustedFileLocations | ForEach-Object -Process {
            $currentLocation = $_
            $matchingDesiredValue = $TrustedFileLocations | Where-Object -FilterScript {
                $_.Address -eq $currentLocation.Address
            }
            if ($null -eq $matchingDesiredValue)
            {
                $message = ("Existing trusted file location '$($_.Address)' was not " + `
                        "found in the desired state for this service " + `
                        "application. Desired state is false.")
                Write-Verbose -Message $message
                Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

                return $false
            }
            return $true
        }
        if ($locationCheck -contains $false)
        {
            Write-Verbose -Message "Test-TargetResource returned false"

            return $false
        }

        # at this point if no other value has been returned, all desired entires exist and are
        # correct, and no existing entries exist that are not in desired state, so return true
        Write-Verbose -Message "Test-TargetResource returned true"

        return $true
    }
    else
    {
        Write-Verbose -Message "Test-TargetResource returned $mainCheck"
        return $mainCheck
    }
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPExcelServiceApp\MSFT_SPExcelServiceApp.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module

    $excelSSAs = Get-SPServiceApplication | Where-Object { $_.TypeName -eq "Excel Services Application Web Service Application" }

    foreach ($excelSSA in $excelSSAs)
    {
        try
        {
            if ($null -ne $excelSSA)
            {
                $PartialContent = "        SPExcelServiceApp " + [System.Guid]::NewGuid().ToString() + "`r`n"
                $PartialContent += "        {`r`n"
                $params.Name = $excelSSA.DisplayName
                $results = Get-TargetResource @params
                $privateK = $results.Get_Item("PrivateBytesMax")
                $unusedMax = $results.Get_Item("UnusedObjectAgeMax")

                <# Nik20170106 - Temporary fix while waiting to hear back from Brian F. on how to properly pass these params. #>
                if ($results.ContainsKey("TrustedFileLocations"))
                {
                    $results.Remove("TrustedFileLocations")
                }

                if ($results.ContainsKey("PrivateBytesMax") -and $privateK -eq "-1")
                {
                    $results.Remove("PrivateBytesMax")
                }

                if ($results.ContainsKey("UnusedObjectAgeMax") -and $unusedMax -eq "-1")
                {
                    $results.Remove("UnusedObjectAgeMax")
                }
                $results = Repair-Credentials -results $results
                $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
                $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
                $PartialContent += $currentBlock
                $PartialContent += "        }`r`n"
                $Content += $PartialContent
            }
        }
        catch
        {
            $Global:ErrorLog += "[Excel Service Application]" + $excelSSA.DisplayName + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
