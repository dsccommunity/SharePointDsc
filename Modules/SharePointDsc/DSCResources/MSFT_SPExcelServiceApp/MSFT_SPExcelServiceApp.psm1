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
        [parameter(Mandatory = $true)]  
        [System.String] 
        $Name,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $ApplicationPool,

        [parameter(Mandatory = $false)] 
        [Microsoft.Management.Infrastructure.CimInstance[]] 
        $TrustedFileLocations,

        [parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present",

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )
    
    Write-Verbose -Message "Getting Excel Services Application '$Name'"

    if ((Get-SPDSCInstalledProductVersion).FileMajorPart -ne 15) 
    {
        throw [Exception] "Only SharePoint 2013 is supported to deploy Excel Services " + `
                          "service applicaions via DSC, as SharePoint 2016 deprecated " + `
                          "this service. See " + `
                          "https://technet.microsoft.com/en-us/library/mt346112(v=office.16).aspx " + `
                          "for more info."
    }

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments @($PSBoundParameters, $Script:ServiceAppObjectType) `
                                  -ScriptBlock {
        $params = $args[0]
        $serviceAppObjectType = $args[1]
        
        $serviceApps = Get-SPServiceApplication -Name $params.Name `
                                                -ErrorAction SilentlyContinue
        $nullReturn = @{
            Name = $params.Name
            ApplicationPool = $params.ApplicationPool
            Ensure = "Absent"
            InstallAccount = $params.InstallAccount
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
                    Address = $_.Address
                    LocationType = $_.LocationType
                    IncludeChildren = $_.IncludeChildren
                    SessionTimeout = $_.SessionTimeout
                    ShortSessionTimeout = $_.ShortSessionTimeout
                    NewWorkbookSessionTimeout = $_.NewWorkbookSessionTimeout
                    RequestDurationMax = $_.RequestDurationMax
                    ChartRenderDurationMax = $_.ChartRenderDurationMax
                    WorkbookSizeMax = $_.WorkbookSizeMax
                    ChartAndImageSizeMax = $_.ChartAndImageSizeMax
                    AutomaticVolatileFunctionCacheLifetime = $_.AutomaticVolatileFunctionCacheLifetime
                    DefaultWorkbookCalcMode = $_.DefaultWorkbookCalcMode
                    ExternalDataAllowed = $_.ExternalDataAllowed
                    WarnOnDataRefresh = $_.WarnOnDataRefresh
                    DisplayGranularExtDataErrors = $_.DisplayGranularExtDataErrors
                    AbortOnRefreshOnOpenFail = $_.AbortOnRefreshOnOpenFail
                    PeriodicExtDataCacheLifetime = $_.PeriodicExtDataCacheLifetime
                    ManualExtDataCacheLifetime = $_.ManualExtDataCacheLifetime
                    ConcurrentDataRequestsPerSessionMax = $_.ConcurrentDataRequestsPerSessionMax
                    UdfsAllowed = $_.UdfsAllowed
                    Description = $_.Description
                    RESTExternalDataAllowed = $_.RESTExternalDataAllowed
                }
            }

            $returnVal =  @{
                Name = $serviceApp.DisplayName
                ApplicationPool = $serviceApp.ApplicationPool.Name
                Ensure = "Present"
                TrustedFileLocations = $fileLocationsToReturn
                InstallAccount = $params.InstallAccount
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
        [parameter(Mandatory = $true)]  
        [System.String] 
        $Name,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $ApplicationPool,

        [parameter(Mandatory = $false)] 
        [Microsoft.Management.Infrastructure.CimInstance[]] 
        $TrustedFileLocations,

        [parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present",

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Setting Excel Services Application '$Name'"

    if ((Get-SPDSCInstalledProductVersion).FileMajorPart -ne 15) 
    {
        throw [Exception] "Only SharePoint 2013 is supported to deploy Excel Services " + `
                          "service applicaions via DSC, as SharePoint 2016 deprecated " + `
                          "this service. See " + `
                          "https://technet.microsoft.com/en-us/library/mt346112(v=office.16).aspx " + `
                          "for more info."
    }
    $result = Get-TargetResource @PSBoundParameters

    if ($result.Ensure -eq "Absent" -and $Ensure -eq "Present") 
    { 
        Write-Verbose -Message "Creating Excel Services Application $Name"
        Invoke-SPDSCCommand -Credential $InstallAccount `
                            -Arguments $PSBoundParameters `
                            -ScriptBlock {
            $params = $args[0]

            New-SPExcelServiceApplication -Name $params.Name `
                                          -ApplicationPool $params.ApplicationPool
        }
    }

    if ($Ensure -eq "Present")
    {
        # Update trusted locations
        $TrustedFileLocations | ForEach-Object -Process {
            $desiredLocation = $_
            $matchingCurrentValue = $result.TrustedFileLocations | Where-Object -FilterScript {
                $_.Address -eq $desiredLocation.Address 
            }
            if ($null -eq $matchingCurrentValue)
            {
                Write-Verbose -Message "Adding trusted location '$($desiredLocation.Address)' to service app"
                Invoke-SPDSCCommand -Credential $InstallAccount `
                                    -Arguments $($PSBoundParameters, $desiredLocation, $Script:TrustLocationProperties, $Script:ServiceAppObjectType) `
                                    -ScriptBlock {
                    $params = $args[0]
                    $desiredLocation = $args[1]
                    $trustLocationProperties = $args[2]
                    $serviceAppObjectType  = $args[3]

                    $newArgs = @{}
                    $trustLocationProperties | ForEach-Object -Process {
                        if ($null -ne $desiredLocation.$_)
                        {
                            $newArgs.Add($_, $desiredLocation.$_)
                        }
                    }
                    $serviceApp = Get-SPServiceApplication -Name $params.Name | Where-Object -FilterScript {
                        $_.GetType().FullName -eq $serviceAppObjectType
                    }
                    $newArgs.Add("ExcelServiceApplication", $serviceApp)

                    New-SPExcelFileLocation @newArgs
                }
            }
            else
            {
                Write-Verbose -Message "Updating trusted location '$($desiredLocation.Address)' in service app"
                Invoke-SPDSCCommand -Credential $InstallAccount `
                                    -Arguments $($PSBoundParameters, $desiredLocation, $Script:TrustLocationProperties, $Script:ServiceAppObjectType) `
                                    -ScriptBlock {
                    $params = $args[0]
                    $desiredLocation = $args[1]
                    $trustLocationProperties = $args[2]
                    $serviceAppObjectType  = $args[3]

                    $updateArgs = @{}
                    $trustLocationProperties | ForEach-Object -Process {
                        if ($null -ne $desiredLocation.$_)
                        {
                            $updateArgs.Add($_, $desiredLocation.$_)
                        }
                    }
                    $serviceApp = Get-SPServiceApplication -Name $params.Name | Where-Object -FilterScript {
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
                Invoke-SPDSCCommand -Credential $InstallAccount `
                                    -Arguments @($PSBoundParameters, $currentLocation) `
                                    -ScriptBlock {
                    $params = $args[0]
                    $currentLocation = $args[1]

                    Remove-SPExcelFileLocation -ExcelServiceApplication $params.Name -Identity $currentLocation.Address -Confirm:$false
                }
            }
        }
    }

    if ($Ensure -eq "Absent") 
    {
        Write-Verbose -Message "Removing Excel Service Application $Name"
        Invoke-SPDSCCommand -Credential $InstallAccount `
                            -Arguments @($PSBoundParameters, $Script:ServiceAppObjectType) `
                            -ScriptBlock {
            $params = $args[0]
            $serviceAppObjectType = $args[1]

            $appService =  Get-SPServiceApplication -Name $params.Name | Where-Object -FilterScript {
                $_.GetType().FullName -eq $serviceAppObjectType  
            }
            Remove-SPServiceApplication $appService -Confirm:$false
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
        $ApplicationPool,

        [parameter(Mandatory = $false)] 
        [Microsoft.Management.Infrastructure.CimInstance[]] 
        $TrustedFileLocations,

        [parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present",

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )
    
    Write-Verbose -Message "Testing Excel Services Application '$Name'"

    $PSBoundParameters.Ensure = $Ensure

    if ((Get-SPDSCInstalledProductVersion).FileMajorPart -ne 15) 
    {
        throw [Exception] "Only SharePoint 2013 is supported to deploy Excel Services " + `
                          "service applicaions via DSC, as SharePoint 2016 deprecated " + `
                          "this service. See " + `
                          "https://technet.microsoft.com/en-us/library/mt346112(v=office.16).aspx " + `
                          "for more info."
    }
    
    $CurrentValues = Get-TargetResource @PSBoundParameters

    $existsCheck = Test-SPDscParameterState -CurrentValues $CurrentValues `
                                            -DesiredValues $PSBoundParameters `
                                            -ValuesToCheck @("Ensure")
    
    if ($Ensure -eq "Present" -and $existsCheck -eq $true -and $null -ne $TrustedFileLocations) 
    {
        # Check that all the desired types are in the current values and match
        $locationCheck = $TrustedFileLocations | ForEach-Object -Process {
            $desiredLocation = $_
            $matchingCurrentValue = $CurrentValues.TrustedFileLocations | Where-Object -FilterScript {
                $_.Address -eq $desiredLocation.Address 
            }
            if ($null -eq $matchingCurrentValue)
            {
                Write-Verbose -Message ("Trusted file location '$($_.Address)' was not found " + `
                                        "in the Excel service app. Desired state is false.")
                return $false
            }
            else
            {
                $Script:TrustLocationProperties | ForEach-Object -Process {
                    if ($desiredLocation.CimInstanceProperties.Name -contains $_)
                    {
                        if ($desiredLocation.$_ -ne $matchingCurrentValue.$_)
                        {
                            Write-Verbose -Message ("Trusted file location '$($desiredLocation.Address)' did not match " + `
                                                    "desired property '$_'. Desired value is " + `
                                                    "'$($desiredLocation.$_)' but the current value is " + `
                                                    "'$($matchingCurrentValue.$_)'")
                            return $false
                        }
                    }
                }
            }
            return $true
        }
        if ($locationCheck -contains $false)
        {
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
                Write-Verbose -Message ("Existing trusted file location '$($_.Address)' was not " + `
                                        "found in the desired state for this service " + `
                                        "application. Desired state is false.")
                return $false
            }
            return $true
        }
        if ($locationCheck -contains $false)
        {
            return $false
        }
        
        # at this point if no other value has been returned, all desired entires exist and are 
        # correct, and no existing entries exist that are not in desired state, so return true
        return $true
    }
    else
    {
        return $existsCheck
    }
}

Export-ModuleMember -Function *-TargetResource
