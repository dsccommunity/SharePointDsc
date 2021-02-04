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
        $WebAppUrl,

        [Parameter()]
        [System.Boolean]
        $SendUnusedSiteCollectionNotifications,

        [Parameter()]
        [System.UInt32]
        $UnusedSiteNotificationPeriod,

        [Parameter()]
        [System.Boolean]
        $AutomaticallyDeleteUnusedSiteCollections,

        [Parameter()]
        [ValidateRange(2, 168)]
        [System.UInt32]
        $UnusedSiteNotificationsBeforeDeletion,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting web application '$WebAppUrl' site use and deletion settings"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $nullReturn = @{
            # Set the Site Use and Deletion settings
            WebAppUrl                                = $params.WebAppUrl
            SendUnusedSiteCollectionNotifications    = $null
            UnusedSiteNotificationPeriod             = $null
            AutomaticallyDeleteUnusedSiteCollections = $null
            UnusedSiteNotificationsBeforeDeletion    = $null
        }

        try
        {
            $null = Get-SPFarm
        }
        catch
        {
            Write-Verbose -Message ("No local SharePoint farm was detected. Site Use and " + `
                    "Deletion settings will not be applied")
            return $nullReturn
        }

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl `
            -ErrorAction SilentlyContinue
        if ($null -eq $wa)
        {
            return $nullReturn
        }

        return @{
            # Set the Site Use and Deletion settings
            WebAppUrl                                = $params.WebAppUrl
            SendUnusedSiteCollectionNotifications    = $wa.SendUnusedSiteCollectionNotifications
            UnusedSiteNotificationPeriod             = $wa.UnusedSiteNotificationPeriod.TotalDays
            AutomaticallyDeleteUnusedSiteCollections = $wa.AutomaticallyDeleteUnusedSiteCollections
            UnusedSiteNotificationsBeforeDeletion    = $wa.UnusedSiteNotificationsBeforeDeletion
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
        $WebAppUrl,

        [Parameter()]
        [System.Boolean]
        $SendUnusedSiteCollectionNotifications,

        [Parameter()]
        [System.UInt32]
        $UnusedSiteNotificationPeriod,

        [Parameter()]
        [System.Boolean]
        $AutomaticallyDeleteUnusedSiteCollections,

        [Parameter()]
        [ValidateRange(2, 168)]
        [System.UInt32]
        $UnusedSiteNotificationsBeforeDeletion,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting web application '$WebAppUrl' Site Use and Deletion settings"

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
            $message = ("No local SharePoint farm was detected. Site Use and Deletion settings " + `
                    "will not be applied")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue
        if ($null -eq $wa)
        {
            $message = "Configured web application could not be found"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }

        # Check if the specified value is in the range for the configured schedule
        $job = Get-SPTimerJob -Identity job-dead-site-delete -WebApplication $params.WebAppUrl
        if ($null -eq $job)
        {
            $message = "Dead Site Delete timer job for web application $($params.WebAppUrl) could not be found"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }
        else
        {
            # Check schedule value
            switch ($job.Schedule.Description)
            {
                "Daily"
                {
                    if (($params.UnusedSiteNotificationsBeforeDeletion -lt 28) -or
                        ($params.UnusedSiteNotificationsBeforeDeletion -gt 168))
                    {
                        $message = ("Value of UnusedSiteNotificationsBeforeDeletion has to be >28 and " + `
                                "<168 when the schedule is set to daily")
                        Add-SPDscEvent -Message $message `
                            -EntryType 'Error' `
                            -EventID 100 `
                            -Source $eventSource
                        throw $message
                    }
                }
                "Weekly"
                {
                    if (($params.UnusedSiteNotificationsBeforeDeletion -lt 4) -or
                        ($params.UnusedSiteNotificationsBeforeDeletion -gt 24))
                    {
                        $message = ("Value of UnusedSiteNotificationsBeforeDeletion has to be >4 and " + `
                                "<24 when the schedule is set to weekly")
                        Add-SPDscEvent -Message $message `
                            -EntryType 'Error' `
                            -EventID 100 `
                            -Source $eventSource
                        throw $message
                    }
                }
                "Monthly"
                {
                    if (($params.UnusedSiteNotificationsBeforeDeletion -lt 2) -or
                        ($params.UnusedSiteNotificationsBeforeDeletion -gt 6))
                    {
                        $message = ("Value of UnusedSiteNotificationsBeforeDeletion has to be >2 and " + `
                                "<6 when the schedule is set to monthly")
                        Add-SPDscEvent -Message $message `
                            -EntryType 'Error' `
                            -EventID 100 `
                            -Source $eventSource
                        throw $message
                    }
                }
            }
        }

        Write-Verbose -Message "Start update"

        # Set the Site Use and Deletion settings
        if ($params.ContainsKey("SendUnusedSiteCollectionNotifications"))
        {
            $wa.SendUnusedSiteCollectionNotifications = `
                $params.SendUnusedSiteCollectionNotifications
        }
        if ($params.ContainsKey("UnusedSiteNotificationPeriod"))
        {
            $timespan = New-TimeSpan -Days $params.UnusedSiteNotificationPeriod
            $wa.UnusedSiteNotificationPeriod = $timespan
        }
        if ($params.ContainsKey("AutomaticallyDeleteUnusedSiteCollections"))
        {
            $wa.AutomaticallyDeleteUnusedSiteCollections = `
                $params.AutomaticallyDeleteUnusedSiteCollections
        }
        if ($params.ContainsKey("UnusedSiteNotificationsBeforeDeletion"))
        {
            $wa.UnusedSiteNotificationsBeforeDeletion = `
                $params.UnusedSiteNotificationsBeforeDeletion
        }
        $wa.Update()
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
        $WebAppUrl,

        [Parameter()]
        [System.Boolean]
        $SendUnusedSiteCollectionNotifications,

        [Parameter()]
        [System.UInt32]
        $UnusedSiteNotificationPeriod,

        [Parameter()]
        [System.Boolean]
        $AutomaticallyDeleteUnusedSiteCollections,

        [Parameter()]
        [ValidateRange(2, 168)]
        [System.UInt32]
        $UnusedSiteNotificationsBeforeDeletion,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing web application '$WebAppUrl' site use and deletion settings"

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
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPWebAppSiteUseAndDeletion\MSFT_SPWebAppSiteUseAndDeletion.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module

    $webApps = Get-SPWebApplication
    foreach ($wa in $webApps)
    {
        try
        {
            if ($null -ne $wa)
            {
                $params.WebAppUrl = $wa.Url
                $PartialContent = "        SPWebAppSiteUseAndDeletion " + [System.Guid]::NewGuid().toString() + "`r`n"
                $PartialContent += "        {`r`n"
                $results = Get-TargetResource @params

                if ($results.Contains("InstallAccount"))
                {
                    $results.Remove("InstallAccount")
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
            $Global:ErrorLog += "[Web Application Site Use and Deletion]" + $wa.Url + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
