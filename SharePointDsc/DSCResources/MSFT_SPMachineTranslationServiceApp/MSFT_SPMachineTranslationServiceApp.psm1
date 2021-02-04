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
        [System.String]
        $ProxyName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
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
        $ApplicationPool,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )
    Write-Verbose -Message "Getting Machine Translation Service Application '$Name'"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $serviceApps = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue

        $nullReturn = @{
            Name            = $params.Name
            DatabaseName    = $params.DatabaseName
            DatabaseServer  = $params.DatabaseServer
            ApplicationPool = $params.ApplicationPool
            Ensure          = "Absent"
        }

        if ($null -eq $serviceApps)
        {
            return $nullReturn
        }

        $serviceApp = $serviceApps | Where-Object -FilterScript {
            $_.GetType().FullName -eq "Microsoft.Office.TranslationServices.TranslationServiceApplication"
        }

        if ($null -eq $serviceApp)
        {
            return $nullReturn
        }
        else
        {
            $serviceAppProxies = Get-SPServiceApplicationProxy -ErrorAction SilentlyContinue
            if ($null -ne $serviceAppProxies)
            {
                $serviceAppProxy = $serviceAppProxies | Where-Object -FilterScript {
                    $serviceApp.IsConnected($_)
                }
                if ($null -ne $serviceAppProxy)
                {
                    $proxyName = $serviceAppProxy.Name
                }
            }

            return @{
                Name            = $params.Name
                ProxyName       = $proxyName
                DatabaseName    = $($serviceApp.Database.Name)
                DatabaseServer  = $($serviceApp.Database.NormalizedDataSource)
                ApplicationPool = $($serviceApp.ApplicationPool.Name)
                Ensure          = "Present"
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
        [System.String]
        $ProxyName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
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
        $ApplicationPool,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose "Setting Machine Translation Service Application."
    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($CurrentValues.Ensure -eq "Present" -and $Ensure -eq "Present")
    {
        Write-Verbose "Resetting Machine Translation Service Application."

        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]
            if ($params.UseSQLAuthentication -eq $true)
            {
                Write-Verbose -Message "Using SQL authentication to configure service application as `$useSQLAuthentication is set to $($params.useSQLAuthentication)."
                $databaseCredentialsParam = @{
                    DatabaseCredentials = $params.DatabaseCredentials
                }
            }
            else
            {
                $databaseCredentialsParam = ""
            }

            $serviceApps = Get-SPServiceApplication -Identity $params.Name

            $serviceApp = $serviceApps | Where-Object -FilterScript {
                $_.GetType().FullName -eq "Microsoft.Office.TranslationServices.TranslationServiceApplication"
            }

            $serviceApp | Set-SPTranslationServiceApplication -ApplicationPool $params.ApplicationPool `
                -DatabaseName $params.DatabaseName `
                -DatabaseServer $params.DatabaseServer `
                @databaseCredentialsParam
        }
    }
    if ($CurrentValues.Ensure -eq "Absent" -and $Ensure -eq "Present")
    {
        Write-Verbose "Creating Machine Translation Service Application."

        $result = Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            if ($params.UseSQLAuthentication -eq $true)
            {
                Write-Verbose -Message "Using SQL authentication to create service application as `$useSQLAuthentication is set to $($params.useSQLAuthentication)."
                $databaseCredentialsParam = @{
                    DatabaseCredentials = $params.DatabaseCredentials
                }
            }
            else
            {
                $databaseCredentialsParam = ""
            }

            $tsServiceApp = New-SPTranslationServiceApplication -Name $params.Name `
                -DatabaseName $params.DatabaseName `
                -DatabaseServer $params.DatabaseServer `
                -ApplicationPool $params.ApplicationPool `
                @databaseCredentialsParam

            if ($params.ContainsKey("ProxyName"))
            {
                # The New-SPTranslationServiceApplication cmdlet creates a proxy by default
                # If a name is specified, we first need to delete the created one
                $proxies = Get-SPServiceApplicationProxy
                foreach ($proxyInstance in $proxies)
                {
                    if ($tsServiceApp.IsConnected($proxyInstance))
                    {
                        $proxyInstance.Delete()
                    }
                }

                New-SPTranslationServiceApplicationProxy -Name $params.ProxyName `
                    -ServiceApplication $tsServiceApp | Out-Null
            }

        }
    }
    if ($Ensure -eq "Absent")
    {
        Write-Verbose "Removing Machine Translation Service Application."

        $result = Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            $serviceApps = Get-SPServiceApplication -Identity $params.Name
            $serviceApp = $serviceApps | Where-Object -FilterScript {
                $_.GetType().FullName -eq "Microsoft.Office.TranslationServices.TranslationServiceApplication"
            }
            $serviceApp | Remove-SPServiceApplication

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
        $ProxyName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
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
        $ApplicationPool,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose "Test Machine Translation Service Application."

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("Name",
        "ApplicationPool",
        "DatabaseName",
        "DatabaseServer",
        "Ensure")

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPMachineTranslationServiceApp\MSFT_SPMachineTranslationServiceApp.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module

    $machineTranslationServiceApps = Get-SPServiceApplication | Where-Object { $_.GetType().Name -eq "TranslationServiceApplication" }
    $i = 1
    $total = $machineTranslationServiceApps.Length
    foreach ($machineTranslation in $machineTranslationServiceApps)
    {
        try
        {
            $serviceName = $machineTranslation.Name
            Write-Host "Scanning Machine Translation Service [$i/$total] {$serviceName}"

            $PartialContent = "        SPMachineTranslationServiceApp " + [System.Guid]::NewGuid().toString() + "`r`n"
            $PartialContent += "        {`r`n"
            $params.Name = $serviceName
            $results = Get-TargetResource @params
            $results = Repair-Credentials -results $results

            Add-ConfigurationDataEntry -Node "NonNodeData" -Key "DatabaseServer" -Value $results.DatabaseServer -Description "Name of the Database Server associated with the destination SharePoint Farm;"
            $results.DatabaseServer = "`$ConfigurationData.NonNodeData.DatabaseServer"

            $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
            $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "DatabaseServer"
            $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
            $PartialContent += $currentBlock
            $PartialContent += "        }`r`n"
            $Content += $PartialContent
            $i++
        }
        catch
        {
            $Global:ErrorLog += "[Machine Translation Service Application]" + $machineTranslation.Name + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
