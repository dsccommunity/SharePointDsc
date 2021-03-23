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
        $BinaryDir,

        [Parameter()]
        [ValidateSet("mon", "tue", "wed", "thu", "fri", "sat", "sun")]
        [System.String[]]
        $BinaryInstallDays,

        [Parameter()]
        [System.String]
        $BinaryInstallTime,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting install status of SharePoint Language Pack"

    Write-Verbose -Message "Check if Binary folder exists"
    if (-not(Test-Path -Path $BinaryDir))
    {
        $message = "Specified path cannot be found: {$BinaryDir}"
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    Write-Verbose -Message "Checking file status of setup.exe"
    $setupExe = Join-Path -Path $BinaryDir -ChildPath "setup.exe"
    if (-not(Test-Path -Path $setupExe))
    {
        $message = "Setup.exe cannot be found in {$BinaryDir}"
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    Write-Verbose -Message "Checking file status of $setupExe"
    $checkBlockedFile = $true
    if (Split-Path -Path $setupExe -IsAbsolute)
    {
        $driveLetter = (Split-Path -Path $setupExe -Qualifier).TrimEnd(":")
        Write-Verbose -Message "BinaryDir refers to drive $driveLetter"

        $volume = Get-Volume -DriveLetter $driveLetter -ErrorAction SilentlyContinue
        if ($null -ne $volume)
        {
            if ($volume.DriveType -ne "CD-ROM")
            {
                Write-Verbose -Message "Volume is a fixed drive: Perform Blocked File test"
            }
            else
            {
                Write-Verbose -Message "Volume is a CD-ROM drive: Skipping Blocked File test"
                $checkBlockedFile = $false
            }
        }
        else
        {
            Write-Verbose -Message "Volume not found. Unable to determine the type. Continuing."
        }
    }

    if ($checkBlockedFile -eq $true)
    {
        Write-Verbose -Message "Checking status now"
        try
        {
            $zone = Get-Item -Path $setupExe -Stream "Zone.Identifier" -EA SilentlyContinue
        }
        catch
        {
            Write-Verbose -Message 'Encountered error while reading file stream. Ignoring file stream.'
        }
        if ($null -ne $zone)
        {
            $message = ("Setup file is blocked! Please use 'Unblock-File -Path $setupExe' " + `
                    "to unblock the file before continuing.")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }
        Write-Verbose -Message "File not blocked, continuing."
    }

    $osrvFolder = Get-ChildItem -Path (Join-Path -Path $BinaryDir `
            -ChildPath "\osmui*.*")

    if ($osrvFolder.Count -ne 1)
    {
        $message = "Unknown folder structure"
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $products = Get-SPDscRegProductsInfo

    $englishProducts = @()
    foreach ($product in $products)
    {
        $parsedProduct = $product -split " - "
        switch -Regex ($parsedProduct)
        {
            "Dari"
            {
                $languageEN = "Dari"
            }
            "Serbian"
            {
                if ($parsedProduct[1] -match "srpski")
                {
                    $languageEN = "Serbian (Latin)"
                }
                else
                {
                    $languageEN = "Serbian (Cyrillic)"
                }
            }
            "Chinese"
            {
                $parsedENProduct = $parsedProduct[1] -split "/"
                $languageEN = $parsedENProduct[0]

                if ($languageEN -eq "Chinese (Simplified)")
                {
                    $languageEN = "Chinese (PRC)"
                }

                if ($languageEN -eq "Chinese (Traditional)")
                {
                    $languageEN = "Chinese (Taiwan)"
                }
            }
            "Portuguese"
            {
                if ($parsedProduct[1] -match "\(Brasil\)")
                {
                    $languageEN = "Portuguese (Brasil)"
                }
                else
                {
                    $languageEN = "Portuguese (Portugal)"
                }
            }
            Default
            {
                $parsedENProduct = $parsedProduct[1] -split "/"
                $parsedENProduct = $parsedENProduct[0] -split " "
                $languageEN = $parsedENProduct[0]
            }
        }
        Write-Verbose "Installed Language Pack: $languageEN"
        $englishProducts += $languageEN
    }

    Write-Verbose -Message "Extract language from filename"
    if ($osrvFolder.Name -match "\w*.(\w{2,3}-\w*-?\w*)")
    {
        $language = $matches[1]
    }
    else
    {
        $message = "Update does not contain the language code in the correct format."
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    try
    {
        $cultureInfo = New-Object -TypeName System.Globalization.CultureInfo `
            -ArgumentList $language
    }
    catch
    {
        $message = "Error while converting language information: $language"
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    # try/catch is required for some versions of Windows, other version use the LCID value of 4096
    if ($cultureInfo.LCID -eq 4096)
    {
        $message = "Error while converting language information: $language"
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    Write-Verbose -Message "Extract English name of the language code: $($cultureInfo.EnglishName)"
    switch ($cultureInfo.EnglishName)
    {
        "Dari (Afghanistan)"
        {
            $languageEnglish = "Dari"
        }
        "Chinese (Simplified, China)"
        {
            $languageEnglish = "Chinese (PRC)"
        }
        "Chinese (Traditional, Taiwan)"
        {
            $languageEnglish = "Chinese (Taiwan)"
        }
        "Portuguese (Brazil)"
        {
            $languageEnglish = "Portuguese (Brasil)"
        }
        "Portuguese (Portugal)"
        {
            $languageEnglish = "Portuguese (Portugal)"
        }
        "Serbian (Cyrillic, Serbia)"
        {
            $languageEnglish = "Serbian (Cyrillic)"
        }
        "Serbian (Latin, Serbia)"
        {
            $languageEnglish = "Serbian (Latin)"
        }
        # If VS Code shows a strange character in Bokmål, this is correct.
        # PowerShell encodes files in Windows-1252 and VSCode uses UTF8.
        # This characters is therefore stored in Windows-1252.
        "Norwegian Bokm�l (Norway)"
        {
            $languageEnglish = "Norwegian"
        }
        Default
        {
            if ($cultureInfo.EnglishName -match "(\w*,*\s*\w*) \([^)]*\)")
            {
                $languageEnglish = $matches[1]
                if ($languageEnglish.contains(","))
                {
                    $languages = $languageEnglish.Split(",")
                    $languageEnglish = $languages[0]
                }
            }
        }
    }

    Write-Verbose -Message "Update is for the $languageEnglish language"

    if ($englishProducts -contains $languageEnglish -eq $true)
    {
        Write-Verbose -Message "Language Pack $languageEnglish is found"
        return @{
            BinaryDir         = $BinaryDir
            BinaryInstallDays = $BinaryInstallDays
            BinaryInstallTime = $BinaryInstallTime
            Ensure            = "Present"
        }
    }
    else
    {
        Write-Verbose -Message "Language Pack $languageEnglish is NOT found"
        return @{
            BinaryDir         = $BinaryDir
            BinaryInstallDays = $BinaryInstallDays
            BinaryInstallTime = $BinaryInstallTime
            Ensure            = "Absent"
        }
    }
}


function Set-TargetResource
{
    # Supressing the global variable use to allow passing DSC the reboot message
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "")]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $BinaryDir,

        [Parameter()]
        [ValidateSet("mon", "tue", "wed", "thu", "fri", "sat", "sun")]
        [System.String[]]
        $BinaryInstallDays,

        [Parameter()]
        [System.String]
        $BinaryInstallTime,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting install status of SharePoint Language Pack"

    if ($Ensure -eq "Absent")
    {
        $message = ("SharePointDsc does not support uninstalling SharePoint " + `
                "Language Packs. Please remove this manually.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    Write-Verbose -Message "Check if Binary folder exists"
    if (-not(Test-Path -Path $BinaryDir))
    {
        $message = "Specified path cannot be found: {$BinaryDir}"
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    Write-Verbose -Message "Checking file status of setup.exe"
    $setupExe = Join-Path -Path $BinaryDir -ChildPath "setup.exe"
    if (-not(Test-Path -Path $setupExe))
    {
        $message = "Setup.exe cannot be found in {$BinaryDir}"
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    Write-Verbose -Message "Checking file status of $setupExe"
    $checkBlockedFile = $true
    if (Split-Path -Path $setupExe -IsAbsolute)
    {
        $driveLetter = (Split-Path -Path $setupExe -Qualifier).TrimEnd(":")
        Write-Verbose -Message "BinaryDir refers to drive $driveLetter"

        $volume = Get-Volume -DriveLetter $driveLetter -ErrorAction SilentlyContinue
        if ($null -ne $volume)
        {
            if ($volume.DriveType -ne "CD-ROM")
            {
                Write-Verbose -Message "Volume is a fixed drive: Perform Blocked File test"
            }
            else
            {
                Write-Verbose -Message "Volume is a CD-ROM drive: Skipping Blocked File test"
                $checkBlockedFile = $false
            }
        }
        else
        {
            Write-Verbose -Message "Volume not found. Unable to determine the type. Continuing."
        }
    }

    if ($checkBlockedFile -eq $true)
    {
        Write-Verbose -Message "Checking status now"
        try
        {
            $zone = Get-Item -Path $setupExe -Stream "Zone.Identifier" -EA SilentlyContinue
        }
        catch
        {
            Write-Verbose -Message 'Encountered error while reading file stream. Ignoring file stream.'
        }
        if ($null -ne $zone)
        {
            $message = ("Setup file is blocked! Please use 'Unblock-File -Path $setupExe' " + `
                    "to unblock the file before continuing.")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }
        Write-Verbose -Message "File not blocked, continuing."
    }

    $now = Get-Date
    Write-Verbose -Message "Check if BinaryInstallDays parameter exists"
    if ($BinaryInstallDays)
    {
        Write-Verbose -Message "BinaryInstallDays parameter exists, check if current day is specified"
        $currentDayOfWeek = $now.DayOfWeek.ToString().ToLower().Substring(0, 3)

        if ($BinaryInstallDays -contains $currentDayOfWeek)
        {
            Write-Verbose -Message ("Current day is present in the parameter BinaryInstallDays. " + `
                    "Update can be run today.")
        }
        else
        {
            Write-Verbose -Message ("Current day is not present in the parameter BinaryInstallDays, " + `
                    "skipping the update")
            return
        }
    }
    else
    {
        Write-Verbose -Message "No BinaryInstallDays specified, Update can be ran on any day."
    }

    Write-Verbose -Message "Check if BinaryInstallTime parameter exists"
    if ($BinaryInstallTime)
    {
        Write-Verbose -Message "BinaryInstallTime parameter exists, check if current time is inside of time window"
        $upgradeTimes = $BinaryInstallTime.Split(" ")
        $starttime = 0
        $endtime = 0

        if ($upgradeTimes.Count -ne 3)
        {
            $message = "Time window incorrectly formatted."
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }
        else
        {
            if ([datetime]::TryParse($upgradeTimes[0], [ref]$starttime) -ne $true)
            {
                $message = "Error converting start time"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }

            if ([datetime]::TryParse($upgradeTimes[2], [ref]$endtime) -ne $true)
            {
                $message = "Error converting end time"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }

            if ($starttime -gt $endtime)
            {
                $message = "Error: Start time cannot be larger than end time"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
        }

        if (($starttime -lt $now) -and ($endtime -gt $now))
        {
            Write-Verbose -Message ("Current time is inside of the window specified in " + `
                    "BinaryInstallTime. Starting update")
        }
        else
        {
            Write-Verbose -Message ("Current time is outside of the window specified in " + `
                    "BinaryInstallTime, skipping the update")
            return
        }
    }
    else
    {
        Write-Verbose -Message ("No BinaryInstallTime specified, Update can be ran at " + `
                "any time. Starting update.")
    }

    Write-Verbose -Message "Checking if BinaryDir is an UNC path"
    $uncInstall = $false
    if ($BinaryDir.StartsWith("\\"))
    {
        Write-Verbose -Message "Specified BinaryDir is an UNC path. Adding path to Local Intranet Zone"

        $uncInstall = $true

        if ($BinaryDir -match "\\\\(.*?)\\.*")
        {
            $serverName = $Matches[1]
        }
        else
        {
            $message = "Cannot extract servername from UNC path. Check if it is in the correct format."
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }

        Set-SPDscZoneMap -Server $serverName
    }

    Write-Verbose -Message "Writing install config file"

    $configPath = "$env:temp\SPInstallLanguagePackConfig.xml"

    $configData = "<Configuration>
    <Setting Id=`"OSERVERLPK`" Value=`"1`"/>
    <Setting Id=`"USINGUIINSTALLMODE`" Value=`"0`"/>
    <Logging Type=`"verbose`" Path=`"%temp%`" Template=`"SharePoint "

    $InstalledVersion = Get-SPDscInstalledProductVersion
    if ($InstalledVersion.FileMajorPart -eq 15)
    {
        $configData += "2013"
    }
    else
    {
        if ($InstalledVersion.ProductBuildPart.ToString().Length -eq 4)
        {
            $configData += "2016"
        }
        else
        {
            $configData += "2019"
        }
    }

    $configData += " Products Language Pack Setup(*).log`"/>
    <Display Level=`"none`" CompletionNotice=`"no`" />
</Configuration>"

    $configData | Out-File -FilePath $configPath

    Write-Verbose -Message "Beginning installation of the SharePoint Language Pack"

    $setup = Start-Process -FilePath $setupExe `
        -ArgumentList "/config `"$configPath`"" `
        -Wait `
        -PassThru

    if ($uncInstall -eq $true)
    {
        Write-Verbose -Message "Removing added path from the Local Intranet Zone"
        Remove-SPDscZoneMap -ServerName $serverName
    }

    switch ($setup.ExitCode)
    {
        0
        {
            Write-Verbose -Message "SharePoint Language Pack binary installation complete"
        }
        17022
        {
            Write-Verbose -Message "SharePoint Language Pack binary installation complete. Reboot required."
            $global:DSCMachineStatus = 1
        }
        Default
        {
            $message = "SharePoint Language Pack install failed, exit code was $($setup.ExitCode)"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
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
        $BinaryDir,

        [Parameter()]
        [ValidateSet("mon", "tue", "wed", "thu", "fri", "sat", "sun")]
        [System.String[]]
        $BinaryInstallDays,

        [Parameter()]
        [System.String]
        $BinaryInstallTime,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing install status of SharePoint Language Pack"

    $PSBoundParameters.Ensure = $Ensure

    if ($Ensure -eq "Absent")
    {
        $message = ("SharePointDsc does not support uninstalling SharePoint " + `
                "Language Packs. Please remove this manually.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

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

Export-ModuleMember -Function *-TargetResource
