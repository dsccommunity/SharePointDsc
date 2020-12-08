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
        [System.UInt32]
        $StorageMaxInMB,

        [Parameter()]
        [System.UInt32]
        $StorageWarningInMB,

        [Parameter()]
        [System.UInt32]
        $MaximumUsagePointsSolutions,

        [Parameter()]
        [System.UInt32]
        $WarningUsagePointsSolutions,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting Quota Template settings for quota $Name"

    if ($StorageMaxInMB -lt $StorageWarningInMB)
    {
        $message = "StorageMaxInMB must be equal to or larger than StorageWarningInMB."
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if ($MaximumUsagePointsSolutions -lt $WarningUsagePointsSolutions)
    {
        $message = ("MaximumUsagePointsSolutions must be equal to or larger than " + `
                "WarningUsagePointsSolutions.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        try
        {
            $null = Get-SPFarm
        }
        catch
        {
            Write-Verbose -Message ("No local SharePoint farm was detected. Quota " + `
                    "template settings will not be applied")
            return @{
                Name                        = $params.Name
                StorageMaxInMB              = 0
                StorageWarningInMB          = 0
                MaximumUsagePointsSolutions = 0
                WarningUsagePointsSolutions = 0
                Ensure                      = "Absent"
            }
        }

        # Get a reference to the Administration WebService
        $admService = Get-SPDscContentService

        $template = $admService.QuotaTemplates[$params.Name]
        if ($null -eq $template)
        {
            return @{
                Name   = $params.Name
                Ensure = "Absent"
            }
        }
        else
        {
            return @{
                Name                        = $params.Name
                # Convert from bytes to megabytes
                StorageMaxInMB              = ($template.StorageMaximumLevel / 1MB)
                # Convert from bytes to megabytes
                StorageWarningInMB          = ($template.StorageWarningLevel / 1MB)
                MaximumUsagePointsSolutions = $template.UserCodeMaximumLevel
                WarningUsagePointsSolutions = $template.UserCodeWarningLevel
                Ensure                      = "Present"
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
        [System.UInt32]
        $StorageMaxInMB,

        [Parameter()]
        [System.UInt32]
        $StorageWarningInMB,

        [Parameter()]
        [System.UInt32]
        $MaximumUsagePointsSolutions,

        [Parameter()]
        [System.UInt32]
        $WarningUsagePointsSolutions,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting Quota Template settings for quota $Name"

    if ($PSBoundParameters.ContainsKey("StorageMaxInMB") -eq $true -and `
            $PSBoundParameters.ContainsKey("StorageWarningInMB") -eq $true -and `
            $StorageMaxInMB -lt $StorageWarningInMB)
    {
        $message = "StorageMaxInMB must be equal to or larger than StorageWarningInMB."
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if ($PSBoundParameters.ContainsKey("MaximumUsagePointsSolutions") -eq $true -and `
            $PSBoundParameters.ContainsKey("WarningUsagePointsSolutions") -eq $true -and `
            $MaximumUsagePointsSolutions -lt $WarningUsagePointsSolutions)
    {
        $message = ("MaximumUsagePointsSolutions must be equal to or larger than " + `
                "WarningUsagePointsSolutions.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    switch ($Ensure)
    {
        "Present"
        {
            Write-Verbose "Ensure is set to Present - Add or update template"
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
                    $message = ("No local SharePoint farm was detected. Quota " + `
                            "template settings will not be applied")
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $eventSource
                    throw $message
                }

                Write-Verbose -Message "Start update"
                # Get a reference to the Administration WebService
                $admService = Get-SPDscContentService

                $template = $admService.QuotaTemplates[$params.Name]

                if ($null -eq $template)
                {
                    #Template does not exist, create new template
                    $newTemplate = New-Object Microsoft.SharePoint.Administration.SPQuotaTemplate
                    $newTemplate.Name = $params.Name
                    if ($params.ContainsKey("StorageMaxInMB"))
                    {
                        $newTemplate.StorageMaximumLevel = ($params.StorageMaxInMB * 1MB)
                    }
                    if ($params.ContainsKey("StorageWarningInMB"))
                    {
                        $newTemplate.StorageWarningLevel = ($params.StorageWarningInMB * 1MB)
                    }
                    if ($params.ContainsKey("MaximumUsagePointsSolutions"))
                    {
                        $newTemplate.UserCodeMaximumLevel = $params.MaximumUsagePointsSolutions
                    }
                    if ($params.ContainsKey("WarningUsagePointsSolutions"))
                    {
                        $newTemplate.UserCodeWarningLevel = $params.WarningUsagePointsSolutions
                    }
                    $admService.QuotaTemplates.Add($newTemplate)
                    $admService.Update()
                }
                else
                {
                    #Template exists, update settings
                    $updatedTemplate = [Microsoft.SharePoint.Administration.SPQuotaTemplate]::new()
                    $updatedTemplate.Name = $params.Name

                    if ($params.ContainsKey("StorageMaxInMB"))
                    {
                        Write-Verbose "StorageMaxInMB specified. Setting value to $($params.StorageMaxInMB)MB"
                        $updatedTemplate.StorageMaximumLevel = $params.StorageMaxInMB * 1MB
                    }
                    else
                    {
                        Write-Verbose "StorageMaxInMB not specified. Reusing level from existing template ($($template.StorageMaximumLevel / 1MB)MB)"
                        $updatedTemplate.StorageMaximumLevel = $template.StorageMaximumLevel
                    }

                    if ($params.ContainsKey("StorageWarningInMB"))
                    {
                        Write-Verbose -Message "StorageWarningInMB specified. Setting value to $($params.StorageWarningInMB)MB"
                        $newWarningLevel = $params.StorageWarningInMB * 1MB

                        if ($newWarningLevel -gt $updatedTemplate.StorageMaximumLevel)
                        {
                            # Since the StorageMaxInMB and StorageWarningInMB parameter were checked at
                            # the beginning of this function, hitting this code means the StorageMaxInMB was not
                            # specfied. Therefore it not checked again here, but exception is immediately thrown.
                            $message = ("To be configured StorageWarningInMB ($($params.StorageWarningInMB)MB) is " + `
                                    "higher than the existing StorageMaxInMB ($($updatedTemplate.StorageMaximumLevel / 1MB)MB). " + `
                                    "Make sure you add the StorageMaxInMB parameter!")
                            Add-SPDscEvent -Message $message `
                                -EntryType 'Error' `
                                -EventID 100 `
                                -Source $eventSource
                            throw $message
                        }
                        else
                        {
                            Write-Verbose -Message "Setting StorageWarningInMB to $($params.StorageWarningInMB)MB"
                            $updatedTemplate.StorageWarningLevel = $newWarningLevel
                        }

                    }
                    else
                    {
                        $newWarningLevel = $template.StorageWarningLevel
                        Write-Verbose -Message "Reusing StorageWarningLevel from existing template: $($newWarningLevel / 1MB)MB"

                        if ($newWarningLevel -gt $updatedTemplate.StorageMaximumLevel)
                        {
                            # Since the StorageMaxInMB and StorageWarningInMB parameter were checked at
                            # the beginning of this function, hitting this code means the StorageWarningInMB was not
                            # specfied. Therefore it not checked again here, but exception is immediately thrown.
                            $message = ("To be configured StorageWarningInMB ($($newWarningLevel / 1MB)MB) is " + `
                                    "higher than the existing StorageMaxInMB ($($updatedTemplate.StorageMaximumLevel / 1MB)MB). " + `
                                    "Make sure you add the StorageWarningInMB parameter!")
                            Add-SPDscEvent -Message $message `
                                -EntryType 'Error' `
                                -EventID 100 `
                                -Source $eventSource
                            throw $message
                        }
                        else
                        {
                            Write-Verbose -Message "Setting StorageWarningLevel to $($newWarningLevel / 1MB)MB"
                            $updatedTemplate.StorageWarningLevel = $newWarningLevel
                        }
                    }

                    if ($params.ContainsKey("MaximumUsagePointsSolutions"))
                    {
                        Write-Verbose "MaximumUsagePointsSolutions specified. Setting value to $($params.MaximumUsagePointsSolutions)"
                        $updatedTemplate.UserCodeMaximumLevel = $params.MaximumUsagePointsSolutions
                    }
                    else
                    {
                        Write-Verbose "MaximumUsagePointsSolutions not specified. Reusing level from existing template ($($template.UserCodeMaximumLevel))"
                        $updatedTemplate.UserCodeMaximumLevel = $template.UserCodeMaximumLevel
                    }

                    if ($params.ContainsKey("WarningUsagePointsSolutions"))
                    {
                        Write-Verbose -Message "WarningUsagePointsSolutions specified. Setting value to $($params.WarningUsagePointsSolutions)"
                        $newWarningLevel = $params.WarningUsagePointsSolutions

                        if ($newWarningLevel -gt $updatedTemplate.UserCodeMaximumLevel)
                        {
                            # Since the MaximumUsagePointsSolutions and WarningUsagePointsSolutions parameter were checked at
                            # the beginning of this function, hitting this code means the MaximumUsagePointsSolutions was not
                            # specfied. Therefore it not checked again here, but exception is immediately thrown.
                            $message = ("To be configured WarningUsagePointsSolutions ($($params.WarningUsagePointsSolutions)) is " + `
                                    "higher than the existing MaximumUsagePointsSolutions ($($updatedTemplate.UserCodeMaximumLevel)). " + `
                                    "Make sure you add the MaximumUsagePointsSolutions parameter!")
                            Add-SPDscEvent -Message $message `
                                -EntryType 'Error' `
                                -EventID 100 `
                                -Source $eventSource
                            throw $message
                        }
                        else
                        {
                            Write-Verbose -Message "Setting WarningUsagePointsSolutions to $($params.WarningUsagePointsSolutions)"
                            $updatedTemplate.UserCodeWarningLevel = $newWarningLevel
                        }

                    }
                    else
                    {
                        $newWarningLevel = $template.UserCodeWarningLevel
                        Write-Verbose -Message "Reusing UserCodeWarningLevel from existing template: $($newWarningLevel)"

                        if ($newWarningLevel -gt $updatedTemplate.UserCodeMaximumLevel)
                        {
                            # Since the MaximumUsagePointsSolutions and WarningUsagePointsSolutions parameter were checked at
                            # the beginning of this function, hitting this code means the WarningUsagePointsSolutions was not
                            # specfied. Therefore it not checked again here, but exception is immediately thrown.
                            $message = ("To be configured WarningUsagePointsSolutions ($($newWarningLevel)) is " + `
                                    "higher than the existing MaximumUsagePointsSolutions ($($updatedTemplate.UserCodeMaximumLevel)). " + `
                                    "Make sure you add the WarningUsagePointsSolutions parameter!")
                            Add-SPDscEvent -Message $message `
                                -EntryType 'Error' `
                                -EventID 100 `
                                -Source $eventSource
                            throw $message
                        }
                        else
                        {
                            Write-Verbose -Message "Setting WarningUsagePointsSolutions to $($newWarningLevel)"
                            $updatedTemplate.UserCodeWarningLevel = $newWarningLevel
                        }
                    }

                    $admService.QuotaTemplates[$params.Name] = $updatedTemplate
                    $admService.Update()
                }
            }
        }
        "Absent"
        {
            Write-Verbose "Ensure is set to Absent - Removing template"

            if ($StorageMaxInMB `
                    -or $StorageWarningInMB `
                    -or $MaximumUsagePointsSolutions `
                    -or $WarningUsagePointsSolutions)
            {
                $message = ("Do not use StorageMaxInMB, StorageWarningInMB, " + `
                        "MaximumUsagePointsSolutions or WarningUsagePointsSolutions " + `
                        "when Ensure is specified as Absent")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }

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
                    $message = ("No local SharePoint farm was detected. Quota " + `
                            "template settings will not be applied")
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $eventSource
                    throw $message
                }

                Write-Verbose -Message "Start update"
                # Get a reference to the Administration WebService
                $admService = Get-SPDscContentService

                # Delete template, function does not throw an error when the template does not
                # exist. So safe to call without error handling.
                $admService.QuotaTemplates.Delete($params.Name)
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
        [System.UInt32]
        $StorageMaxInMB,

        [Parameter()]
        [System.UInt32]
        $StorageWarningInMB,

        [Parameter()]
        [System.UInt32]
        $MaximumUsagePointsSolutions,

        [Parameter()]
        [System.UInt32]
        $WarningUsagePointsSolutions,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing Quota Template settings for quota $Name"

    if ($StorageMaxInMB -lt $StorageWarningInMB)
    {
        $message = "StorageMaxInMB must be equal to or larger than StorageWarningInMB."
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if ($MaximumUsagePointsSolutions -lt $WarningUsagePointsSolutions)
    {
        $message = ("MaximumUsagePointsSolutions must be equal to or larger than " + `
                "WarningUsagePointsSolutions.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    switch ($Ensure)
    {
        "Present"
        {
            if ($CurrentValues.Ensure -eq "Absent")
            {
                $message = "Ensure {$($CurrentValues.Ensure)} does not match the desired state {$Ensure}"
                Write-Verbose -Message $message
                Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

                $result = $false
            }
            else
            {
                $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
                    -Source $($MyInvocation.MyCommand.Source) `
                    -DesiredValues $PSBoundParameters
            }
        }
        "Absent"
        {
            if ($StorageMaxInMB -or `
                    $StorageWarningInMB -or `
                    $MaximumUsagePointsSolutions -or `
                    $WarningUsagePointsSolutions)
            {
                $message = ("Do not use StorageMaxInMB, StorageWarningInMB, " + `
                        "MaximumUsagePointsSolutions or WarningUsagePointsSolutions " + `
                        "when Ensure is specified as Absent")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }

            if ($CurrentValues.Ensure -eq "Present")
            {
                # Error occured in Get method or template exists, which is not supposed to be. Return false
                $message = "Ensure {$($CurrentValues.Ensure)} does not match the desired state {$Ensure}"
                Write-Verbose -Message $message
                Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

                $result = $false
            }
            else
            {
                # Template does not exists, which is supposed to be. Return true
                $result = $true
            }
        }
    }

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

Export-ModuleMember -Function *-TargetResource
