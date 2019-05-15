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
        [ValidateSet("mon","tue","wed","thu","fri","sat","sun")]
        [System.String[]]
        $BinaryInstallDays,

        [Parameter()]
        [System.String]
        $BinaryInstallTime,

        [Parameter()]
        [ValidateSet("Present","Absent")]
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
        throw "Specified path cannot be found: {$BinaryDir}"
    }

    Write-Verbose -Message "Checking file status of setup.exe"
    $setupExe = Join-Path -Path $BinaryDir -ChildPath "setup.exe"
    if (-not(Test-Path -Path $setupExe))
    {
        throw "Setup.exe cannot be found in {$BinaryDir}"
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
        $zone = Get-Item -Path $setupExe -Stream "Zone.Identifier" -EA SilentlyContinue
        if ($null -ne $zone)
        {
            throw ("Setup file is blocked! Please use 'Unblock-File -Path $setupExe' " + `
                   "to unblock the file before continuing.")
        }
        Write-Verbose -Message "File not blocked, continuing."
    }

    $osrvFolder = Get-ChildItem -Path (Join-Path -Path $BinaryDir `
                                                 -ChildPath "\osmui*.*")

    if ($osrvFolder.Count -ne 1)
    {
        throw "Unknown folder structure"
    }

    $products = Get-SPDscRegProductsInfo

    $englishProducts = @()
    foreach ($product in $products)
    {
        $parsedProduct = $product -split " - "
        switch -Regex ($parsedProduct)
        {
            "Dari"    { $languageEN = "Dari"}
            "Serbian" {
                if ($parsedProduct[1] -match "srpski")
                {
                    $languageEN = "Serbian (Latin)"
                }
                else
                {
                    $languageEN = "Serbian (Cyrillic)"
                }
            }
            "Chinese" {
                $parsedENProduct = $parsedProduct[1] -split "/"
                $languageEN = $parsedENProduct[0]
            }
            "Portuguese" {
                if ($parsedProduct[1] -match "\(Brasil\)")
                {
                    $languageEN = "Portuguese (Brasil)"
                }
                else
                {
                    $languageEN = "Portuguese (Portugal)"
                }
            }
            Default {
                $parsedENProduct = $parsedProduct[1] -split "/"
                $parsedENProduct = $parsedENProduct[0] -split " "
                $languageEN = $parsedENProduct[0]
            }
        }
        $englishProducts += $languageEN
    }

    Write-Verbose -Message "Extract language from filename"
    if ($osrvFolder.Name -match "\w*.(\w{2,3}-\w*-?\w*)")
    {
        $language = $matches[1]
    }
    else
    {
        throw "Update does not contain the language code in the correct format."
    }

    try
    {
        $cultureInfo = New-Object -TypeName System.Globalization.CultureInfo `
                                  -ArgumentList $language
    }
    catch
    {
        throw "Error while converting language information: $language"
    }

    # try/catch is required for some versions of Windows, other version use the LCID value of 4096
    if ($cultureInfo.LCID -eq 4096)
    {
        throw "Error while converting language information: $language"
    }

    Write-Verbose -Message "Extract English name of the language code"
    $updateLanguage = $cultureInfo.EnglishName
    switch ($cultureInfo.EnglishName)
    {
        "Dari (Afghanistan)" { $languageEnglish = "Dari" }
        "Chinese (Simplified, China)" { $languageEnglish = "Chinese (PRC)" }
        "Chinese (Traditional, Taiwan)" { $languageEnglish = "Chinese (Taiwan)" }
        "Portuguese (Brazil)" { $languageEnglish = "Portuguese (Brasil)" }
        "Portuguese (Portugal)" { $languageEnglish = "Portuguese (Portugal)" }
        "Serbian (Cyrillic, Serbia)" { $languageEnglish = "Serbian (Cyrillic)" }
        "Serbian (Latin, Serbia)" { $languageEnglish = "Serbian (Latin)" }
        "Norwegian Bokmål (Norway)" { $languageEnglish = "Norwegian" }
        Default {
            if ($cultureInfo.EnglishName -match "(\w*,*\s*\w*) \([^)]*\)")
            {
                $languageEnglish = $matches[1]
                $updateLanguage  = $matches[0]
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
        [ValidateSet("mon","tue","wed","thu","fri","sat","sun")]
        [System.String[]]
        $BinaryInstallDays,

        [Parameter()]
        [System.String]
        $BinaryInstallTime,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting install status of SharePoint Language Pack"

    if ($Ensure -eq "Absent")
    {
        throw [Exception] ("SharePointDsc does not support uninstalling SharePoint " + `
                           "Language Packs. Please remove this manually.")
        return
    }

    Write-Verbose -Message "Check if Binary folder exists"
    if (-not(Test-Path -Path $BinaryDir))
    {
        throw "Specified path cannot be found: {$BinaryDir}"
    }

    Write-Verbose -Message "Checking file status of setup.exe"
    $setupExe = Join-Path -Path $BinaryDir -ChildPath "setup.exe"
    if (-not(Test-Path -Path $setupExe))
    {
        throw "Setup.exe cannot be found in {$BinaryDir}"
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
        $zone = Get-Item -Path $setupExe -Stream "Zone.Identifier" -EA SilentlyContinue
        if ($null -ne $zone)
        {
            throw ("Setup file is blocked! Please use 'Unblock-File -Path $setupExe' " + `
                   "to unblock the file before continuing.")
        }
        Write-Verbose -Message "File not blocked, continuing."
    }

    $now = Get-Date
    Write-Verbose -Message "Check if BinaryInstallDays parameter exists"
    if ($BinaryInstallDays)
    {
        Write-Verbose -Message "BinaryInstallDays parameter exists, check if current day is specified"
        $currentDayOfWeek = $now.DayOfWeek.ToString().ToLower().Substring(0,3)

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
            throw "Time window incorrectly formatted."
        }
        else
        {
            if ([datetime]::TryParse($upgradeTimes[0],[ref]$starttime) -ne $true)
            {
                throw "Error converting start time"
            }

            if ([datetime]::TryParse($upgradeTimes[2],[ref]$endtime) -ne $true)
            {
                throw "Error converting end time"
            }

            if ($starttime -gt $endtime)
            {
                throw "Error: Start time cannot be larger than end time"
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

    Write-Verbose -Message "To prevent an endless loop: Check if an upgrade is required."
    if ((Get-SPDSCInstalledProductVersion).FileMajorPart -eq 15)
    {
        $wssRegKey ="hklm:SOFTWARE\Microsoft\Shared Tools\Web Server Extensions\15.0\WSS"
    }
    else
    {
        $wssRegKey ="hklm:SOFTWARE\Microsoft\Shared Tools\Web Server Extensions\16.0\WSS"
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
            throw "Cannot extract servername from UNC path. Check if it is in the correct format."
        }

        Set-SPDscZoneMap -Server $serverName
    }

    Write-Verbose -Message "Writing install config file"

    $configPath = "$env:temp\SPInstallLanguagePackConfig.xml"

    $configData = "<Configuration>
    <Setting Id=`"OSERVERLPK`" Value=`"1`"/>
    <Setting Id=`"USINGUIINSTALLMODE`" Value=`"0`"/>
    <Logging Type=`"verbose`" Path=`"%temp%`" Template=`"SharePoint "

    $InstalledVersion = Get-SPDSCInstalledProductVersion
    if ($InstalledVersion.FileMajorPart -eq 15)
    {
        $configData += "2013"
    }
    else
    {
        if($InstalledVersion.ProductBuildPart.ToString().Length -eq 4)
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
        0 {
            Write-Verbose -Message "SharePoint Language Pack binary installation complete"
        }
        17022 {
            Write-Verbose -Message "SharePoint Language Pack binary installation complete. Reboot required."
            $global:DSCMachineStatus = 1
        }
        Default {
            throw "SharePoint Language Pack install failed, exit code was $($setup.ExitCode)"
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
        [ValidateSet("mon","tue","wed","thu","fri","sat","sun")]
        [System.String[]]
        $BinaryInstallDays,

        [Parameter()]
        [System.String]
        $BinaryInstallTime,

        [Parameter()]
        [ValidateSet("Present","Absent")]
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
        throw [Exception] ("SharePointDsc does not support uninstalling SharePoint " + `
                           "Language Packs. Please remove this manually.")
        return
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @("Ensure")
}

Export-ModuleMember -Function *-TargetResource
