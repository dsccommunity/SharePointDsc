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
        [System.Boolean]
        $Enabled,

        [Parameter()]
        [ValidateSet("All Servers", "Any Server")]
        [System.String]
        $RuleScope,

        [Parameter()]
        [ValidateSet("Hourly", "Daily", "Weekly", "Monthly", "OnDemandOnly")]
        [System.String]
        $Schedule,

        [Parameter()]
        [System.Boolean]
        $FixAutomatically,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting Health Rule configuration settings"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $nullReturn = @{
            # Set the Health Analyzer Rule settings
            Name             = $null
            Enabled          = $null
            RuleScope        = $null
            Schedule         = $null
            FixAutomatically = $null
        }

        try
        {
            $null = Get-SPFarm
        }
        catch
        {
            Write-Verbose -Message ("No local SharePoint farm was detected. Health " + `
                    "Analyzer Rule settings will not be applied")
            return $nullReturn
        }

        $caWebapp = Get-SPwebapplication -IncludeCentralAdministration `
        | Where-Object -FilterScript {
            $_.IsAdministrationWebApplication
        }

        if ($null -eq $caWebapp)
        {
            Write-Verbose -Message "Unable to locate central administration website"
            return $nullReturn
        }

        # Get CA SPWeb
        $caWeb = Get-SPWeb($caWebapp.Url)
        $healthRulesList = $caWeb.Lists | Where-Object -FilterScript {
            $_.BaseTemplate -eq "HealthRules"
        }

        if ($null -ne $healthRulesList)
        {
            $spQuery = New-Object Microsoft.SharePoint.SPQuery
            $querytext = "<Where><Eq><FieldRef Name='Title'/><Value Type='Text'>" + `
                "$($params.Name)</Value></Eq></Where>"
            $spQuery.Query = $querytext
            $results = $healthRulesList.GetItems($spQuery)
            if ($results.Count -eq 1)
            {
                $item = $results[0]

                # Additional check for incorrect default value of the schedule for rule
                # "One or more app domains for web applications aren't configured correctly."
                $ruleschedule = $item["HealthRuleSchedule"]
                if ($ruleschedule -eq "On Demand")
                {
                    $ruleschedule = "OnDemandOnly"
                }

                return @{
                    # Set the Health Analyzer Rule settings
                    Name             = $params.Name
                    Enabled          = $item["HealthRuleCheckEnabled"]
                    RuleScope        = $item["HealthRuleScope"]
                    Schedule         = $ruleschedule
                    FixAutomatically = $item["HealthRuleAutoRepairEnabled"]
                }
            }
            else
            {
                Write-Verbose -Message ("Unable to find specified Health Analyzer Rule. Make " + `
                        "sure any related service applications exists.")
                return $nullReturn
            }
        }
        else
        {
            Write-Verbose -Message "Unable to locate Health Analyzer Rules list"
            return $nullReturn
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
        [System.Boolean]
        $Enabled,

        [Parameter()]
        [ValidateSet("All Servers", "Any Server")]
        [System.String]
        $RuleScope,

        [Parameter()]
        [ValidateSet("Hourly", "Daily", "Weekly", "Monthly", "OnDemandOnly")]
        [System.String]
        $Schedule,

        [Parameter()]
        [System.Boolean]
        $FixAutomatically,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting Health Analyzer Rule configuration settings"

    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]

        try
        {
            $null = Get-SPFarm
        }
        catch
        {
            $message = ("No local SharePoint farm was detected. Health Analyzer Rule " + `
                    "settings will not be applied")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }

        $caWebapp = Get-SPwebapplication -IncludeCentralAdministration `
        | Where-Object -FilterScript {
            $_.IsAdministrationWebApplication
        }

        if ($null -eq $caWebapp)
        {
            $message = ("No Central Admin web application was found. Health Analyzer Rule " + `
                    "settings will not be applied")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }

        # Get Central Admin SPWeb
        $caWeb = Get-SPWeb($caWebapp.Url)
        $healthRulesList = $caWeb.Lists | Where-Object -FilterScript {
            $_.BaseTemplate -eq "HealthRules"
        }

        if ($null -ne $healthRulesList)
        {
            $spQuery = New-Object Microsoft.SharePoint.SPQuery
            $querytext = "<Where><Eq><FieldRef Name='Title'/><Value Type='Text'>" + `
                "$($params.Name)</Value></Eq></Where>"
            $spQuery.Query = $querytext
            $results = $healthRulesList.GetItems($spQuery)
            if ($results.Count -eq 1)
            {
                $item = $results[0]

                $item["HealthRuleCheckEnabled"] = $params.Enabled
                if ($params.ContainsKey("RuleScope"))
                {
                    $item["HealthRuleScope"] = $params.RuleScope
                }
                if ($params.ContainsKey("Schedule"))
                {
                    $item["HealthRuleSchedule"] = $params.Schedule
                }
                if ($params.ContainsKey("FixAutomatically"))
                {
                    $item["HealthRuleAutoRepairEnabled"] = $params.FixAutomatically
                }

                $item.Update()
            }
            else
            {
                $message = ("Could not find specified Health Analyzer Rule. Health Analyzer Rule " + `
                        "settings will not be applied. Make sure any related service " + `
                        "applications exists")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
                throw $message
            }
        }
        else
        {
            $message = ("Could not find Health Analyzer Rules list. Health Analyzer Rule settings " + `
                    "will not be applied")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
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
        [System.Boolean]
        $Enabled,

        [Parameter()]
        [ValidateSet("All Servers", "Any Server")]
        [System.String]
        $RuleScope,

        [Parameter()]
        [ValidateSet("Hourly", "Daily", "Weekly", "Monthly", "OnDemandOnly")]
        [System.String]
        $Schedule,

        [Parameter()]
        [System.Boolean]
        $FixAutomatically,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing Health Analyzer rule configuration settings"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDSC" | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPHealthAnalyzerRuleState\MSFT_SPHealthAnalyzerRuleState.psm1" -Resolve
    $caWebapp = Get-SPWebApplication -IncludeCentralAdministration `
    | Where-Object -FilterScript { $_.IsAdministrationWebApplication }
    $caWeb = Get-SPWeb($caWebapp.Url)
    $healthRulesList = $caWeb.Lists | Where-Object -FilterScript { $_.BaseTemplate -eq "HealthRules" }

    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module

    foreach ($healthRule in $healthRulesList.Items)
    {
        try
        {
            $params.Name = $healthRule.Title
            $results = Get-TargetResource @params

            if ($null -ne $results.Schedule)
            {
                $PartialContent = "        SPHealthAnalyzerRuleState " + [System.Guid]::NewGuid().ToString() + "`r`n"
                $PartialContent += "        {`r`n"

                if ($results.Get_Item("Schedule") -eq "On Demand")
                {
                    $results.Schedule = "OnDemandOnly"
                }

                $results = Repair-Credentials -results $results
                $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
                $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
                $PartialContent += $currentBlock
                $PartialContent += "        }`r`n"
                $Content += $PartialContent
            }
            else
            {
                $ruleName = $healthRule.Title
                Write-Warning "Could not extract information for rule {$ruleName}. There may be some missing service applications."
            }
        }
        catch
        {
            $Global:ErrorLog += "[Health Analyzer Rule]" + $healthRule.Title + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
