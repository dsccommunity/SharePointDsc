$script:SPDscUtilModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SharePointDsc.Util'
Import-Module -Name $script:SPDscUtilModulePath

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
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [Parameter()]
        [System.String]
        $DatabaseName,

        [Parameter()]
        [System.String]
        $DatabaseServer,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [Parameter()]
        [System.String]
        $FailoverDatabaseServer,

        [Parameter()]
        [System.UInt32]
        $UsageLogCutTime,

        [Parameter()]
        [System.String]
        $UsageLogLocation,

        [Parameter()]
        [System.UInt32]
        $UsageLogMaxFileSizeKB,

        [Parameter()]
        [System.UInt32]
        $UsageLogMaxSpaceGB
    )

    Write-Verbose -Message "Getting usage application '$Name'"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $serviceApps = Get-SPServiceApplication | Where-Object -FilterScript {
            $_.Name -eq $params.Name
        }

        $nullReturn = @{
            Name   = $params.Name
            Ensure = "Absent"
        }

        if ($null -eq $serviceApps)
        {
            return $nullReturn
        }
        $serviceApp = $serviceApps | Where-Object -FilterScript {
            $_.GetType().FullName -eq "Microsoft.SharePoint.Administration.SPUsageApplication"
        }

        if ($null -eq $serviceApp)
        {
            return $nullReturn
        }
        else
        {
            $spUsageApplicationProxy = Get-SPServiceApplicationProxy | Where-Object -FilterScript {
                $_.GetType().FullName -eq "Microsoft.SharePoint.Administration.SPUsageApplicationProxy"
            }

            $ensure = "Present"
            if ($spUsageApplicationProxy.Status -eq "Disabled")
            {
                $ensure = "Absent"
            }

            $service = Get-SPUsageService
            return @{
                Name                   = $serviceApp.DisplayName
                DatabaseName           = $serviceApp.UsageDatabase.Name
                DatabaseServer         = $serviceApp.UsageDatabase.NormalizedDataSource
                DatabaseCredentials    = $params.DatabaseCredentials
                FailoverDatabaseServer = $serviceApp.UsageDatabase.FailoverServer
                UsageLogCutTime        = $service.UsageLogCutTime
                UsageLogLocation       = $service.UsageLogDir
                UsageLogMaxFileSizeKB  = $service.UsageLogMaxFileSize / 1024
                UsageLogMaxSpaceGB     = $service.UsageLogMaxSpaceGB
                Ensure                 = $ensure
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
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [Parameter()]
        [System.String]
        $DatabaseName,

        [Parameter()]
        [System.String]
        $DatabaseServer,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [Parameter()]
        [System.String]
        $FailoverDatabaseServer,

        [Parameter()]
        [System.UInt32]
        $UsageLogCutTime,

        [Parameter()]
        [System.String]
        $UsageLogLocation,

        [Parameter()]
        [System.UInt32]
        $UsageLogMaxFileSizeKB,

        [Parameter()]
        [System.UInt32]
        $UsageLogMaxSpaceGB
    )

    Write-Verbose -Message "Setting usage application $Name"

    $CurrentState = Get-TargetResource @PSBoundParameters

    if ($CurrentState.Ensure -eq "Absent" -and $Ensure -eq "Present")
    {
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            $newParams = @{ }
            $newParams.Add("Name", $params.Name)
            if ($params.ContainsKey("DatabaseName"))
            {
                $newParams.Add("DatabaseName", $params.DatabaseName)
            }
            if ($params.ContainsKey("DatabaseCredentials"))
            {
                Write-Verbose -Message "Using DatabaseUsername and DatabasePassword parameters since we specified DatabaseCredentials."
                $newparams.Add("DatabaseUsername", $params.DatabaseCredentials.Username)
                $newparams.Add("DatabasePassword", $params.DatabaseCredentials.Password)
            }
            else
            {
                Write-Verbose -Message "Using default Windows auth as no DatabaseCredentials were provided."
            }
            if ($params.ContainsKey("DatabaseServer"))
            {
                $newParams.Add("DatabaseServer", $params.DatabaseServer)
            }
            if ($params.ContainsKey("FailoverDatabaseServer"))
            {
                $newParams.Add("FailoverDatabaseServer", $params.FailoverDatabaseServer)
            }

            New-SPUsageApplication @newParams
        }
    }

    if ($Ensure -eq "Present")
    {
        Write-Verbose -Message "Configuring usage application $Name"
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            $spUsageApplicationProxy = Get-SPServiceApplicationProxy | Where-Object -FilterScript {
                $_.GetType().FullName -eq "Microsoft.SharePoint.Administration.SPUsageApplicationProxy"
            }

            if ($spUsageApplicationProxy.Status -eq "Disabled")
            {
                $spUsageApplicationProxy.Provision()
            }

            $setParams = @{ }
            $setParams.Add("LoggingEnabled", $true)
            if ($params.ContainsKey("UsageLogCutTime"))
            {
                $setParams.Add("UsageLogCutTime", $params.UsageLogCutTime)
            }
            if ($params.ContainsKey("UsageLogLocation"))
            {
                $setParams.Add("UsageLogLocation", $params.UsageLogLocation)
            }
            if ($params.ContainsKey("UsageLogMaxFileSizeKB"))
            {
                $setParams.Add("UsageLogMaxFileSizeKB", $params.UsageLogMaxFileSizeKB)
            }
            if ($params.ContainsKey("UsageLogMaxSpaceGB"))
            {
                $setParams.Add("UsageLogMaxSpaceGB", $params.UsageLogMaxSpaceGB)
            }
            Set-SPUsageService @setParams
        }
    }

    if ($Ensure -eq "Absent")
    {
        Write-Verbose -Message "Removing usage application $Name"
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            $service = Get-SPServiceApplication | Where-Object -FilterScript {
                $_.Name -eq $params.Name -and `
                $_.GetType().FullName -eq "Microsoft.SharePoint.Administration.SPUsageApplication"
            }
            Remove-SPServiceApplication $service -Confirm:$false
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
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [Parameter()]
        [System.String]
        $DatabaseName,

        [Parameter()]
        [System.String]
        $DatabaseServer,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [Parameter()]
        [System.String]
        $FailoverDatabaseServer,

        [Parameter()]
        [System.UInt32]
        $UsageLogCutTime,

        [Parameter()]
        [System.String]
        $UsageLogLocation,

        [Parameter()]
        [System.UInt32]
        $UsageLogMaxFileSizeKB,

        [Parameter()]
        [System.UInt32]
        $UsageLogMaxSpaceGB
    )

    Write-Verbose -Message "Testing for usage application '$Name'"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($Ensure -eq "Present")
    {
        $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("UsageLogCutTime",
            "UsageLogLocation",
            "UsageLogMaxFileSizeKB",
            "UsageLogMaxSpaceGB",
            "Ensure")
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

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPUsageApplication\MSFT_SPUsageApplication.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module

    $usageApplication = Get-SPUsageApplication
    if ($usageApplication.Length -gt 0)
    {
        $PartialContent = "        SPUsageApplication " + $usageApplication.TypeName.Replace(" ", "") + "`r`n"
        $PartialContent += "        {`r`n"
        $params.Name = $usageApplication.Name
        $params.Ensure = "Present"
        $results = Get-TargetResource @params

        $results.Remove("DatabaseCredentials")

        $failOverFound = $false

        $results = Repair-Credentials -results $results

        if ($null -eq $results.FailOverDatabaseServer)
        {
            $results.Remove("FailOverDatabaseServer")
        }
        else
        {
            $failOverFound = $true
            Add-ConfigurationDataEntry -Node $env:COMPUTERNAME -Key "UsageAppFailOverDatabaseServer" -Value $results.FailOverDatabaseServer -Description "Name of the Usage Service Application Failover Database;"
            $results.FailOverDatabaseServer = "`$ConfigurationData.NonNodeData.UsageAppFailOverDatabaseServer"
        }
        $results.DatabaseServer = "`$ConfigurationData.NonNodeData.DatabaseServer"
        Add-ConfigurationDataEntry -Node "NonNodeData" -Key "UsageLogLocation" -Value $results.UsageLogLocation -Description "Path where the Usage Logs will be stored;"
        $results.UsageLogLocation = "`$ConfigurationData.NonNodeData.UsageLogLocation"

        $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
        $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
        $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "UsageLogLocation"
        $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "DatabaseServer"

        if ($failOverFound)
        {
            $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "FailOverDatabaseServer"
        }

        $PartialContent += $currentBlock
        $PartialContent += "        }`r`n"
        $Content += $PartialContent
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
