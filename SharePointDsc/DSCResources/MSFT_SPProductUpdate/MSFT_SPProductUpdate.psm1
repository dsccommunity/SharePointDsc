$script:resourceModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:resourceModulePath -ChildPath 'Modules'
$script:resourceHelperModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'SharePointDsc.Util'
Import-Module -Name (Join-Path -Path $script:resourceHelperModulePath -ChildPath 'SharePointDsc.Util.psm1')

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $SetupFile,

        [Parameter()]
        [System.Boolean]
        $ShutdownServices,

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

    if ($Ensure -eq "Absent")
    {
        throw [Exception] "SharePoint does not support uninstalling updates."
        return
    }

    Write-Verbose -Message "Getting install status of SP binaries"

    $languagepack = $false
    $servicepack = $false
    $language = ""

    Write-Verbose -Message "Check if the setup file exists"
    if (-not(Test-Path -Path $SetupFile))
    {
        return @{
            SetupFile         = $SetupFile
            ShutdownServices  = $ShutdownServices
            BinaryInstallDays = $BinaryInstallDays
            BinaryInstallTime = $BinaryInstallTime
            Ensure            = "Absent"
        }
    }

    Write-Verbose -Message "Checking file status of $SetupFile"
    $checkBlockedFile = $true
    if (Split-Path -Path $SetupFile -IsAbsolute)
    {
        $driveLetter = (Split-Path -Path $SetupFile -Qualifier).TrimEnd(":")
        Write-Verbose -Message "SetupFile refers to drive $driveLetter"

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
            $zone = Get-Item -Path $SetupFile -Stream "Zone.Identifier" -EA SilentlyContinue
        }
        catch
        {
            Write-Verbose -Message 'Encountered error while reading file stream. Ignoring file stream.'
        }

        if ($null -ne $zone)
        {
            throw ("Setup file is blocked! Please use 'Unblock-File -Path $SetupFile' " + `
                    "to unblock the file before continuing.")
        }
        Write-Verbose -Message "File not blocked, continuing."
    }

    $nullVersion = New-Object -TypeName System.Version

    Write-Verbose -Message "Get file information from setup file"
    $setupFileInfo = Get-ItemProperty -Path $SetupFile
    $fileVersion = $setupFileInfo.VersionInfo.FileVersion
    Write-Verbose -Message "Update has version $fileVersion"

    $fileVersionInfo = New-Object -TypeName System.Version -ArgumentList $fileVersion
    if ($fileVersionInfo.Major -eq 15)
    {
        $sharePointVersion = 2013
    }
    else
    {
        if ($fileVersionInfo.Build.ToString().Length -eq 4)
        {
            $sharePointVersion = 2016
        }
        else
        {
            $sharePointVersion = 2019
        }
    }

    if ($setupFileInfo.VersionInfo.FileDescription -match "Service Pack.*Language Pack")
    {
        Write-Verbose -Message "Update is a Language Pack Service Pack."
        # Retrieve language from file and check version for that language pack.
        $languagepack = $true

        # Extract language from filename
        if ($setupFileInfo.Name -match "\w*-(\w{2}-\w{2}).exe")
        {
            $language = $matches[1]
        }
        else
        {
            throw "Update does not contain the language code in the correct format."
        }

        try
        {
            $cultureInfo = New-Object -TypeName System.Globalization.CultureInfo -ArgumentList $language
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
        if ($cultureInfo.EnglishName -match "(\w*,*\s*\w*) \([a-zA-Z_0-9 ]*\)")
        {
            $languageEnglish = $matches[1]
            if ($languageEnglish.contains(","))
            {
                $languages = $languageEnglish.Split(",")
                $languageEnglish = $languages[0]
            }
        }

        # Extract Native name of the language code
        if ($cultureInfo.NativeName -match "(\w*,*\s*\w*) \([a-zA-Z_0-9 ]*\)")
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
        Write-Verbose -Message "Update is for the $($languageString) language"

        $versionInfo = Get-SPDscLocalVersionInfo -ProductVersion $sharePointVersion -Lcid $($cultureInfo.LCID)

        if ($versionInfo -eq $nullVersion)
        {
            throw "Error: Product for language $language is not found."
        }
        else
        {
            Write-Verbose -Message "Product found; Version: $versionInfo"
        }
    }
    elseif ($setupFileInfo.VersionInfo.FileDescription -match "Service Pack")
    {
        Write-Verbose -Message "Update is a Service Pack for SharePoint."
        # Check SharePoint version information.
        $servicepack = $true
        $versionInfo = Get-SPDscLocalVersionInfo -ProductVersion $sharePointVersion
    }
    else
    {
        Write-Verbose -Message "Update is a Cumulative Update."
        # For SP 2016 + 2019 Patches
        $setupFileInformation = New-Object -TypeName System.IO.FileInfo -ArgumentList  $SetupFile
        if ($setupFileInformation.Name.StartsWith("wssloc"))
        {
            Write-Verbose -Message "Cumulative Update is multilingual"
            $versionInfo = Get-SPDscLocalVersionInfo -ProductVersion $sharePointVersion -IsWssPackage
        }
        else
        {
            Write-Verbose -Message "Cumulative Update is generic"
            $versionInfo = Get-SPDscLocalVersionInfo -ProductVersion $sharePointVersion
        }
    }

    Write-Verbose -Message "The lowest version of any SharePoint component is $($versionInfo)"
    if ($versionInfo -lt $fileVersionInfo)
    {
        # Version of SharePoint is lower than the patch version. Patch is not installed.
        return @{
            SetupFile         = $SetupFile
            ShutdownServices  = $ShutdownServices
            BinaryInstallDays = $BinaryInstallDays
            BinaryInstallTime = $BinaryInstallTime
            Ensure            = "Absent"
        }
    }
    else
    {
        # Version of SharePoint is equal or greater than the patch version. Patch is installed.
        return @{
            SetupFile         = $SetupFile
            ShutdownServices  = $ShutdownServices
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
        [Parameter(Mandatory = $true)]
        [System.String]
        $SetupFile,

        [Parameter()]
        [System.Boolean]
        $ShutdownServices,

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

    Write-Verbose -Message "Setting install status of SP Update binaries"

    if ($Ensure -eq "Absent")
    {
        throw [Exception] "SharePoint does not support uninstalling updates."
        return
    }

    Write-Verbose -Message "Check if the setup file exists"
    if (-not(Test-Path -Path $SetupFile))
    {
        throw "Setup file cannot be found: {$SetupFile}"
    }

    Write-Verbose -Message "Checking file status of $SetupFile"
    $checkBlockedFile = $true
    if (Split-Path -Path $SetupFile -IsAbsolute)
    {
        $driveLetter = (Split-Path -Path $SetupFile -Qualifier).TrimEnd(":")
        Write-Verbose -Message "SetupFile refers to drive $driveLetter"

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
            $zone = Get-Item -Path $SetupFile -Stream "Zone.Identifier" -EA SilentlyContinue
        }
        catch
        {
            Write-Verbose -Message 'Encountered error while reading file stream. Ignoring file stream.'
        }

        if ($null -ne $zone)
        {
            throw ("Setup file is blocked! Please use 'Unblock-File -Path $SetupFile' " + `
                    "to unblock the file before continuing.")
        }
        Write-Verbose -Message "File not blocked, continuing."
    }

    $now = Get-Date
    Write-Verbose -Message "Check if BinaryInstallDays is specified"
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

    Write-Verbose -Message "Check if BinaryInstallTime is specified"
    if ($BinaryInstallTime)
    {
        Write-Verbose -Message ("BinaryInstallTime parameter exists, check if current time is inside " + `
                "of time window")
        $upgradeTimes = $BinaryInstallTime.Split(" ")
        $starttime = 0
        $endtime = 0

        if ($upgradeTimes.Count -ne 3)
        {
            throw "Time window incorrectly formatted."
        }
        else
        {
            if ([datetime]::TryParse($upgradeTimes[0], [ref]$starttime) -ne $true)
            {
                throw "Error converting start time"
            }

            if ([datetime]::TryParse($upgradeTimes[2], [ref]$endtime) -ne $true)
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

    $installedVersion = Get-SPDscInstalledProductVersion

    Write-Verbose -Message "Try to load local Farm"

    $farmIsAvailable = Invoke-SPDscCommand -Credential $InstallAccount `
        -ScriptBlock {
        try
        {
            $null = Get-SPFarm
            return $true
        }
        catch
        {
            return $false
        }
    }

    if ($ShutdownServices -and $farmIsAvailable)
    {
        Write-Verbose -Message "Stopping services to speed up installation process"

        $searchPaused = $false
        $osearchStopped = $false
        $hostControllerStopped = $false

        if ($installedVersion.FileMajorPart -eq 15)
        {
            $searchServiceName = "OSearch15"
        }
        else
        {
            $searchServiceName = "OSearch16"
        }

        $osearchSvc = Get-Service -Name $searchServiceName
        $hostControllerSvc = Get-Service -Name "SPSearchHostController"

        Invoke-SPDscCommand -Credential $InstallAccount `
            -ScriptBlock {
            $searchSAs = Get-SPEnterpriseSearchServiceApplication
            foreach ($searchSA in $searchSAs)
            {
                if ($searchSA.isPaused() -eq 0)
                {
                    $searchSA.Pause()
                }
            }
        }
        $searchPaused = $true

        if ($osearchSvc.Status -eq "Running")
        {
            $osearchStopped = $true
            Set-Service -Name $searchServiceName -StartupType Disabled
            $osearchSvc.Stop()
        }

        if ($hostControllerSvc.Status -eq "Running")
        {
            $hostControllerStopped = $true
            Set-Service "SPSearchHostController" -StartupType Disabled
            $hostControllerSvc.Stop()
        }

        $hostControllerSvc.WaitForStatus('Stopped', '00:01:00')

        Write-Verbose -Message "Search Services are stopped"

        Write-Verbose -Message "Stopping other services"

        if ($installedVersion.FileMajorPart -eq 15 -or $installedVersion.ProductBuildPart.ToString().Length -eq 4)
        {
            Write-Verbose -Message "SharePoint 2013 or 2016 used, reconfiguring IISAdmin service to Disabled startup."
            Set-Service -Name "IISADMIN" -StartupType Disabled
        }
        Set-Service -Name "SPTimerV4" -StartupType Disabled

        $null = Start-Process -FilePath "iisreset.exe" `
            -ArgumentList "-stop -noforce" `
            -Wait `
            -PassThru

        $timerSvc = Get-Service -Name "SPTimerV4"
        if ($timerSvc.Status -eq "Running")
        {
            $timerSvc.Stop()
        }
    }

    Write-Verbose -Message "Beginning installation of the SharePoint update"

    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $SetupFile `
        -ScriptBlock {
        $setupFile = $args[0]

        Write-Verbose -Message "Checking if SetupFile is an UNC path"
        $uncInstall = $false
        if ($setupFile.StartsWith("\\"))
        {
            Write-Verbose -Message "Specified BinaryDir is an UNC path. Adding path to Local Intranet Zone"

            $uncInstall = $true

            if ($setupFile -match "\\\\(.*?)\\.*")
            {
                $serverName = $Matches[1]
            }
            else
            {
                throw "Cannot extract servername from UNC path. Check if it is in the correct format."
            }

            Set-SPDscZoneMap -Server $serverName
        }

        $setup = Start-Process -FilePath $setupFile `
            -ArgumentList "/quiet /passive" `
            -Wait `
            -PassThru

        if ($uncInstall -eq $true)
        {
            Write-Verbose -Message "Removing added path from the Local Intranet Zone"
            Remove-SPDscZoneMap -ServerName $serverName
        }

        # Error codes: https://aka.ms/installerrorcodes
        switch ($setup.ExitCode)
        {
            0
            {
                Write-Verbose -Message "SharePoint update binary installation complete."
            }
            17022
            {
                Write-Verbose -Message ("SharePoint update binary installation complete, " + `
                        "however a reboot is required.")
                $global:DSCMachineStatus = 1
            }
            17025
            {
                Write-Verbose -Message ("The SharePoint update was already installed on your system." + `
                        "Please report an issue about this behavior at https://github.com/dsccommunity/SharePointDsc")
            }
            Default
            {
                throw ("SharePoint update install failed, exit code was $($setup.ExitCode). " + `
                        "Error codes can be found at https://aka.ms/installerrorcodes")
            }
        }
    }

    if ($ShutdownServices -and $farmIsAvailable)
    {
        Write-Verbose -Message "Restart stopped services"
        Set-Service -Name "SPTimerV4" -StartupType Automatic

        if ($installedVersion.FileMajorPart -eq 15 -or $installedVersion.ProductBuildPart.ToString().Length -eq 4)
        {
            Write-Verbose -Message "SharePoint 2013 or 2016 used, reconfiguring IISAdmin service to Automatic startup."
            Set-Service -Name "IISADMIN" -StartupType Automatic
        }

        $timerSvc = Get-Service -Name "SPTimerV4"
        $timerSvc.Start()

        Start-Process -FilePath "iisreset.exe" `
            -ArgumentList "-start" `
            -Wait `
            -PassThru

        $osearchSvc = Get-Service -Name $searchServiceName
        $hostControllerSvc = Get-Service -Name "SPSearchHostController"

        # Ensuring Search Services were stopped by script before Starting"
        if ($osearchStopped -eq $true)
        {
            Set-Service -Name $searchServiceName -StartupType Manual
            $osearchSvc.Start()
        }

        if ($hostControllerStopped -eq $true)
        {
            Set-Service "SPSearchHostController" -StartupType Automatic
            $hostControllerSvc.Start()
        }

        if ($searchPaused -eq $true)
        {
            # Resuming Search Service Application if paused###
            Invoke-SPDscCommand -Credential $InstallAccount `
                -ScriptBlock {
                $searchSAs = Get-SPEnterpriseSearchServiceApplication
                foreach ($searchSA in $searchSAs)
                {
                    if (($searchSA.IsPaused() -band 0x80) -ne 0)
                    {
                        $searchSA.Resume()
                    }
                }
            }
        }

        Write-Verbose -Message "Services restarted."
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
        $SetupFile,

        [Parameter()]
        [System.Boolean]
        $ShutdownServices,

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

    Write-Verbose -Message "Testing install status of SP Update binaries"

    $PSBoundParameters.Ensure = $Ensure

    if ($Ensure -eq "Absent")
    {
        throw [Exception] "SharePoint does not support uninstalling updates."
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

function Get-SPDscLocalVersionInfo
{
    [OutputType([System.Version])]
    param
    (
        # Parameter help description
        [Parameter(Mandatory = $true)]
        [ValidateSet(2013, 2016, 2019)]
        [System.Int32]
        $ProductVersion,

        [Parameter()]
        [System.Int32]
        $Lcid,

        [Parameter()]
        [Switch]
        $IsWssPackage
    )

    $productNameRegEx = "Microsoft SharePoint (Foundation|Server) $($ProductVersion) Core"

    if (0 -ne $Lcid)
    {
        $productNameRegEx = "Microsoft SharePoint (Foundation|Server) $($ProductVersion) $($Lcid) (Lang|Language) Pack"
    }

    if ($IsWssPackage)
    {
        $productNameRegEx = "Microsoft SharePoint (Foundation|Server) $($ProductVersion) \d{4} (Lang|Language) Pack"
    }
    Write-Verbose "Product Name RegEx: $($productNameRegEx)"

    $installerRegistryPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products"

    $patchRegistryPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Patches"

    $installerEntries = Get-ChildItem -Path $installerRegistryPath -ErrorAction SilentlyContinue

    $nullVersion = New-Object -TypeName System.Version
    $versionInfoValue = New-Object -TypeName System.Version

    $officeProductKeys = $installerEntries | Where-Object -FilterScript { $_.PsPath -like "*00000000F01FEC" }

if ($null -eq $installerEntries -or $null -eq $officeProductKeys )
{
    return $nullVersion
}

# $null - one command returns an empty value
$null = $officeProductKeys | ForEach-Object -Process {
    $officeProductKey = $_

    $productInfo = Get-ItemProperty "Registry::$($officeProductKey)\InstallProperties" -ErrorAction SilentlyContinue

    if ($null -eq $productInfo)
    {
        break
    }

    $prodName = $productInfo.DisplayName

    if ($prodName -match $productNameRegEx)
    {
        Write-Verbose "Gathering Information for $($prodName)"
        $patchInformationFolder = Get-ItemProperty "Registry::$($officeProductKey)\Patches"
        # SharePoint 2013 with SP 1 has a minimum of two Items in this key
        if ($patchInformationFolder.AllPatches.GetType().Name -eq "String[]" -and $patchInformationFolder.AllPatches.Length -gt 0)
        {
            $patchGuid = $patchInformationFolder.AllPatches[$patchInformationFolder.AllPatches.Length - 1]
        }
        else
        {
            $patchGuid = $patchInformationFolder.AllPatches
        }

        if ($null -ne $patchGuid)
        {
            $detailedPatchInformation = Get-ItemProperty "$($patchRegistryPath)\$($patchGuid)"
            $localPackage = $detailedPatchInformation.LocalPackage

            if ($null -ne $localPackage)
            {
                $patchFileInformation = New-Object -TypeName System.IO.FileInfo -ArgumentList $localPackage
                if ($patchFileInformation.Extension -eq ".msp")
                {
                    try
                    {
                        $windowsInstaller = New-Object -ComObject WindowsInstaller.Installer
                        $installerDatabase = $windowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $null, $windowsInstaller, ($localPackage , 32))
                        $databaseQuery = "SELECT Value FROM MsiPatchMetadata WHERE Property = 'BuildNumber'"
                        $databaseView = $installerDatabase.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $installerDatabase, ($databaseQuery))
                        $databaseView.GetType().InvokeMember("Execute", "InvokeMethod", $null, $databaseView, $null)
                        $value = $databaseView.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $databaseView, $null)
                        $versionInfo = [System.Version]$value.GetType().InvokeMember("StringData", "GetProperty", $null, $value, 1)

                        # https://github.com/dsccommunity/DscResources/issues/383

                        Clear-ComObject -ComObject $databaseView
                        Clear-ComObject -ComObject $value
                        Clear-ComObject -ComObject $installerDatabase
                        Clear-ComObject -ComObject $windowsInstaller
                    }
                    catch [Exception]
                    {
                        throw [Exception] "An error occured during the collection of data about installed products in Get-SPDscLocalVersionInfo."
                    }
                }
            }
            else
            {
                $versionInfo = New-Object -TypeName System.Version -ArgumentList $productInfo.DisplayVersion
            }
        }

        # Collect Information about language packs
        if ($IsWssPackage `
                -and (  $versionInfoValue -eq $nullVersion `
                    -or $versionInfoValue -gt $versionInfo) `
        )
        {
            $versionInfoValue = $versionInfo
        }
        else
        {
            $versionInfoValue = $versionInfo
        }
        Write-Verbose "Version Information for $($prodName): $($versionInfoValue)"

    }
}

if ($nullVersion -ne $versionInfoValue)
{
    return $versionInfoValue
}

return $nullVersion
}

# Function required for Mocking the static .Net call
function Clear-ComObject
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $ComObject
    )

    $null = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($ComObject)
}

Export-ModuleMember -Function *-TargetResource
