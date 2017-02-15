function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  
        [System.String] 
        $BinaryDir,

        [parameter(Mandatory = $false)]
        [ValidateSet("mon","tue","wed","thu","fri","sat","sun")]
        [System.String[]]
        $BinaryInstallDays,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $BinaryInstallTime,
        
        [parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present",

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting install status of SharePoint Language Pack"

    # Check if Binary folder exists
    if (-not(Test-Path -Path $BinaryDir))
    {
        throw "Specified path cannot be found."
    }

    $osrvFolder = Get-ChildItem -Path (Join-Path -Path $BinaryDir `
                                                 -ChildPath "\osmui*.*")

    if ($osrvFolder.Count -ne 1)
    {
        throw "Unknown folder structure"
    }

    $products = Invoke-SPDSCCommand -Credential $InstallAccount `
                                    -ScriptBlock {
        return Get-SPDscRegProductsInfo 
    }

    # Extract language from filename
    if ($osrvFolder.Name -match "\w*.(\w{2}-\w{2})")
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
            
    # Extract English name of the language code
    if ($cultureInfo.EnglishName -match "(\w*,*\s*\w*) \(\w*\)")
    {
        $languageEnglish = $matches[1]
        if ($languageEnglish.contains(","))
        {
            $languages = $languageEnglish.Split(",")
            $languageEnglish = $languages[0]
        }
    }

    # Extract Native name of the language code
    if ($cultureInfo.NativeName -match "(\w*,*\s*\w*) \(\w*\)")
    {
        $languageNative = $matches[1]
        if ($languageNative.contains(","))
        {
            $languages = $languageNative.Split(",")
            $languageNative = $languages[0]
        }
    }

    # Build language string used in Language Pack names
    $languageString = "$languageEnglish/$languageNative"
    Write-Verbose -Message "Update is for the $languageEnglish language"

    # Find the product name for the specific language pack
    $productName = ""
    foreach ($product in $products)
    {
        if ($product -match $languageString)
        {
            $productName = $product
        }
    }

    if ($productName -eq "")
    {
        return @{
            BinaryDir         = $BinaryDir
            BinaryInstallDays = $BinaryInstallDays
            BinaryInstallTime = $BinaryInstallTime
            Ensure            = "Absent"
        }
    }
    else
    {
        return @{
            BinaryDir         = $BinaryDir
            BinaryInstallDays = $BinaryInstallDays
            BinaryInstallTime = $BinaryInstallTime
            Ensure            = "Present"
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
        [parameter(Mandatory = $true)]  
        [System.String] 
        $BinaryDir,

        [parameter(Mandatory = $false)]
        [ValidateSet("mon","tue","wed","thu","fri","sat","sun")]
        [System.String[]]
        $BinaryInstallDays,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $BinaryInstallTime,
        
        [parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present",

        [parameter(Mandatory = $false)]
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

    # Check if Binary folder exists
    if (-not(Test-Path -Path $BinaryDir))
    {
        throw "Specified path cannot be found."
    }

    $now = Get-Date
    if ($BinaryInstallDays)
    {
        # BinaryInstallDays parameter exists, check if current day is specified
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

    # Check if BinaryInstallTime parameter exists
    if ($BinaryInstallTime)
    {
        # Check if current time is inside of time window
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

    # To prevent an endless loop: Check if an upgrade is required.
    if ((Get-SPDSCInstalledProductVersion).FileMajorPart -eq 15)
    {
        $wssRegKey ="hklm:SOFTWARE\Microsoft\Shared Tools\Web Server Extensions\15.0\WSS"
    }
    else
    {
        $wssRegKey ="hklm:SOFTWARE\Microsoft\Shared Tools\Web Server Extensions\16.0\WSS"
    }

    # Read LanguagePackInstalled and SetupType registry keys
    $languagePackInstalled = Get-SPDSCRegistryKey -Key $wssRegKey -Value "LanguagePackInstalled"
    $setupType = Get-SPDSCRegistryKey -Key $wssRegKey -Value "SetupType"

    # Determine if LanguagePackInstalled=1 or SetupType=B2B_Upgrade.
    # If so, the Config Wizard is required, so the installation will be skipped.
    if (($languagePackInstalled -eq 1) -or ($setupType -eq "B2B_UPGRADE"))
    {
        Write-Verbose -Message ("An upgrade is pending. " + `
                                "To prevent a possible loop, the install will be skipped")
        return
    }    

    Write-Verbose -Message "Writing install config file"

    $configPath = "$env:temp\SPInstallLanguagePackConfig.xml" 

    $configData = "<Configuration>
    <Setting Id=`"OSERVERLPK`" Value=`"1`"/>
    <Setting Id=`"USINGUIINSTALLMODE`" Value=`"0`"/>
    <Logging Type=`"verbose`" Path=`"%temp%`" Template=`"SharePoint "

    if ((Get-SPDSCInstalledProductVersion).FileMajorPart -eq 15)
    {
        $configData += "2013"
    }
    else
    {
        $configData += "2016"
    }

    $configData += " Products Language Pack Setup(*).log`"/>
    <Display Level=`"none`" CompletionNotice=`"no`" />
</Configuration>"

    $configData | Out-File -FilePath $configPath

    Write-Verbose -Message "Beginning installation of the SharePoint Language Pack"

    $setupExe = Join-Path -Path $BinaryDir -ChildPath "setup.exe"
    
    $setup = Start-Process -FilePath $setupExe `
                           -ArgumentList "/config `"$configPath`"" `
                           -Wait `
                           -PassThru

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
        [parameter(Mandatory = $true)]  
        [System.String] 
        $BinaryDir,

        [parameter(Mandatory = $false)]
        [ValidateSet("mon","tue","wed","thu","fri","sat","sun")]
        [System.String[]]
        $BinaryInstallDays,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $BinaryInstallTime,
        
        [parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present",

        [parameter(Mandatory = $false)]
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
