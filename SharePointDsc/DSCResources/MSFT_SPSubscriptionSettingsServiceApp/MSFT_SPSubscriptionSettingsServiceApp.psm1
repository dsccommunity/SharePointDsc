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
        $ApplicationPool,

        [Parameter()]
        [System.String]
        $DatabaseName,

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
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting Subscription Settings Service '$Name'"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $serviceApps = Get-SPServiceApplication -Name $params.Name `
            -ErrorAction SilentlyContinue
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
            $_.GetType().FullName -eq "Microsoft.SharePoint.SPSubscriptionSettingsServiceApplication"
        }

        if ($null -eq $serviceApp)
        {
            return $nullReturn
        }
        else
        {
            $propertyFlags = [System.Reflection.BindingFlags]::Instance `
                -bor [System.Reflection.BindingFlags]::NonPublic

            $propData = $serviceApp.GetType().GetProperties($propertyFlags)

            $dbProp = $propData | Where-Object -FilterScript {
                $_.Name -eq "Database"
            }

            $db = $dbProp.GetValue($serviceApp)

            return  @{
                Name            = $serviceApp.DisplayName
                ApplicationPool = $serviceApp.ApplicationPool.Name
                DatabaseName    = $db.Name
                DatabaseServer  = $db.NormalizedDataSource
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

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

        [Parameter()]
        [System.String]
        $DatabaseName,

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
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting Subscription Settings Service '$Name'"

    $result = Get-TargetResource @PSBoundParameters

    if ($result.Ensure -eq "Absent" -and $Ensure -eq "Present")
    {
        Write-Verbose -Message "Creating Subscription Settings Service Application $Name"
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            $newParams = @{
                Name            = $params.Name
                ApplicationPool = $params.ApplicationPool
            }
            if ($params.ContainsKey("DatabaseName") -eq $true)
            {
                $newParams.Add("DatabaseName", $params.DatabaseName)
            }
            if ($params.ContainsKey("DatabaseServer") -eq $true)
            {
                $newParams.Add("DatabaseServer", $params.DatabaseServer)
            }
            if ($params.useSQLAuthentication -eq $true)
            {
                Write-Verbose -Message "Using SQL authentication to create service application as `$useSQLAuthentication is set to $($params.useSQLAuthentication)."
                $newParams.Add("DatabaseCredentials", $params.DatabaseCredentials)
            }
            else
            {
                Write-Verbose -Message "`$useSQLAuthentication is false or not specified; using default Windows authentication."
            }
            $serviceApp = New-SPSubscriptionSettingsServiceApplication @newParams
            New-SPSubscriptionSettingsServiceApplicationProxy -ServiceApplication $serviceApp | Out-Null
        }
    }
    if ($result.Ensure -eq "Present" -and $Ensure -eq "Present")
    {
        Write-Verbose -Message "Checking proxy for Subscription Settings Service Application $Name"
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            $serviceApp = Get-SPServiceApplication -Name $params.Name `
                -ErrorAction SilentlyContinue

            $serviceAppProxies = Get-SPServiceApplicationProxy -ErrorAction SilentlyContinue

            if ($null -ne $serviceAppProxies)
            {
                # Checking if one of the proxies is connected to the service app
                $serviceAppProxy = $serviceAppProxies | Where-Object -FilterScript {
                    $serviceApp.IsConnected($_)
                }
                if ($null -eq $serviceAppProxy)
                {
                    # No proxy connected, create new proxy
                    New-SPSubscriptionSettingsServiceApplicationProxy -ServiceApplication $serviceApp | Out-Null
                }
            }
            else
            {
                # No proxies exist in the environment, create new proxy
                New-SPSubscriptionSettingsServiceApplicationProxy -ServiceApplication $serviceApp | Out-Null
            }
        }

        if ($ApplicationPool -ne $result.ApplicationPool)
        {
            Write-Verbose -Message "Updating Subscription Settings Service Application $Name"
            Invoke-SPDscCommand -Credential $InstallAccount `
                -Arguments $PSBoundParameters `
                -ScriptBlock {

                $params = $args[0]
                $appPool = Get-SPServiceApplicationPool -Identity $params.ApplicationPool
                $service = Get-SPServiceApplication -Name $params.Name `
                | Where-Object -FilterScript {
                    $_.GetType().FullName -eq "Microsoft.SharePoint.SPSubscriptionSettingsServiceApplication"
                }
                $service.ApplicationPool = $appPool
                $service.Update()
            }
        }
    }
    if ($Ensure -eq "Absent")
    {
        Write-Verbose -Message "Removing Subscription Settings Service Application $Name"
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            $service = Get-SPServiceApplication -Name $params.Name `
            | Where-Object -FilterScript {
                $_.GetType().FullName -eq "Microsoft.SharePoint.SPSubscriptionSettingsServiceApplication"
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

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

        [Parameter()]
        [System.String]
        $DatabaseName,

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
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing Subscription Settings Service '$Name'"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($Ensure -eq "Present")
    {
        if ($CurrentValues.Ensure -eq "Present")
        {
            $result = Invoke-SPDscCommand -Credential $InstallAccount `
                -Arguments $PSBoundParameters `
                -ScriptBlock {
                $params = $args[0]

                $serviceApp = Get-SPServiceApplication -Name $params.Name `
                    -ErrorAction SilentlyContinue

                $serviceAppProxies = Get-SPServiceApplicationProxy -ErrorAction SilentlyContinue

                if ($null -ne $serviceAppProxies)
                {
                    $serviceAppProxy = $serviceAppProxies | Where-Object -FilterScript {
                        $serviceApp.IsConnected($_)
                    }
                    if ($null -eq $serviceAppProxy)
                    {
                        return $false
                    }
                }
            }

            if ($result -eq $false)
            {
                $message = "The service application is not configured to a proxy"
                Write-Verbose -Message $message
                Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

                Write-Verbose -Message "Test-TargetResource returned false"
                return $false
            }
        }

        $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("ApplicationPool", "Ensure")
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
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPSubscriptionSettingsServiceApp\MSFT_SPSubscriptionSettingsServiceApp.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module
    $serviceApps = Get-SPServiceApplication | Where-Object { $_.GetType().Name -eq "SPSubscriptionSettingsServiceApplication" }

    foreach ($subSetting in $serviceApps)
    {
        $PartialContent = "        SPSubscriptionSettingsServiceApp " + $subSetting.Name.Replace(" ", "") + [System.Guid]::NewGuid().ToString() + "`r`n"
        $PartialContent += "        {`r`n"
        $params.Name = $subSetting.Name

        $results = Get-TargetResource @params

        if ($null -eq $results.DatabaseName)
        {
            $results.Remove("DatabaseName")
        }

        if ($null -eq $results.DatabaseServer)
        {
            $results.Remove("DatabaseServer")
        }

        $results = Repair-Credentials -results $results
        $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
        $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
        $PartialContent += $currentBlock
        $PartialContent += "        }`r`n"
        $Content += $PartialContent
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
