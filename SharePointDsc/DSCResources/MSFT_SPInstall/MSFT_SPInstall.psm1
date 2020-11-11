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
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [System.String]
        $BinaryDir,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ProductKey,

        [Parameter()]
        [System.String]
        $InstallPath,

        [Parameter()]
        [System.String]
        $DataPath,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Getting install status of SharePoint"

    Write-Verbose -Message "Check if Binary folder exists"
    if (-not(Test-Path -Path $BinaryDir))
    {
        throw "Specified path cannot be found: {$BinaryDir}"
    }

    $InstallerPath = Join-Path -Path $BinaryDir -ChildPath "setup.exe"
    if (-not(Test-Path -Path $InstallerPath))
    {
        throw "Setup.exe cannot be found in {$BinaryDir}"
    }

    Write-Verbose -Message "Checking file status of $InstallerPath"
    $checkBlockedFile = $true
    if (Split-Path -Path $InstallerPath -IsAbsolute)
    {
        $driveLetter = (Split-Path -Path $InstallerPath -Qualifier).TrimEnd(":")
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
            $zone = Get-Item -Path $InstallerPath -Stream "Zone.Identifier" -EA SilentlyContinue
        }
        catch
        {
            Write-Verbose -Message 'Encountered error while reading file stream. Ignoring file stream.'
        }
        if ($null -ne $zone)
        {
            throw ("Setup file is blocked! Please use 'Unblock-File -Path $InstallerPath' " + `
                    "to unblock the file before continuing.")
        }
        Write-Verbose -Message "File not blocked, continuing."
    }

    $x86Path = "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    $installedItemsX86 = Get-ItemProperty -Path $x86Path | Select-Object -Property DisplayName

    $x64Path = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    $installedItemsX64 = Get-ItemProperty -Path $x64Path | Select-Object -Property DisplayName

    $installedItems = $installedItemsX86 + $installedItemsX64
    $installedItems = $installedItems.DisplayName | Select-Object -Unique
    $spInstall = $installedItems | Where-Object -FilterScript {
        $_ -match "^Microsoft SharePoint Server (2013|2016|2019)$"
    }

    if ($spInstall)
    {
        return @{
            IsSingleInstance = "Yes"
            BinaryDir        = $BinaryDir
            ProductKey       = $ProductKey
            InstallPath      = $InstallPath
            DataPath         = $DataPath
            Ensure           = "Present"
        }
    }
    else
    {
        return @{
            IsSingleInstance = "Yes"
            BinaryDir        = $BinaryDir
            ProductKey       = $ProductKey
            InstallPath      = $InstallPath
            DataPath         = $DataPath
            Ensure           = "Absent"
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
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [System.String]
        $BinaryDir,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ProductKey,

        [Parameter()]
        [System.String]
        $InstallPath,

        [Parameter()]
        [System.String]
        $DataPath,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Setting install status of SharePoint"

    if ($Ensure -eq "Absent")
    {
        throw [Exception] ("SharePointDsc does not support uninstalling SharePoint or " + `
                "its prerequisites. Please remove this manually.")
    }

    Write-Verbose -Message "Check if Binary folder exists"
    if (-not(Test-Path -Path $BinaryDir))
    {
        throw "Specified path cannot be found: {$BinaryDir}"
    }

    $InstallerPath = Join-Path -Path $BinaryDir -ChildPath "setup.exe"
    if (-not(Test-Path -Path $InstallerPath))
    {
        throw "Setup.exe cannot be found in {$BinaryDir}"
    }

    $majorVersion = (Get-SPDscAssemblyVersion -PathToAssembly $InstallerPath)
    if ($majorVersion -eq 15)
    {
        $svrsetupDll = Join-Path -Path $BinaryDir -ChildPath "updates\svrsetup.dll"
        $checkDotNet = $true
        if (Test-Path -Path $svrsetupDll)
        {
            $svrsetupDllFileInfo = Get-ItemProperty -Path $svrsetupDll
            $fileVersion = $svrsetupDllFileInfo.VersionInfo.FileVersion
            if ($fileVersion -ge "15.0.4709.1000")
            {
                $checkDotNet = $false
            }
        }

        if ($checkDotNet -eq $true)
        {
            $ndpKey = "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4"
            $dotNet46Installed = $false
            if (Test-Path -Path $ndpKey)
            {
                $dotNetv4Keys = Get-ChildItem -Path $ndpKey
                foreach ($dotnetInstance in $dotNetv4Keys)
                {
                    if ($dotnetInstance.GetValue("Release") -ge 390000)
                    {
                        $dotNet46Installed = $true
                        break
                    }
                }
            }

            if ($dotNet46Installed -eq $true)
            {
                throw [Exception] ("A known issue prevents installation of SharePoint 2013 on " + `
                        "servers that have .NET 4.6 already installed. See details " + `
                        "at https://support.microsoft.com/en-us/kb/3087184")
                return
            }
        }
    }

    Write-Verbose -Message "Checking file status of $InstallerPath"
    $checkBlockedFile = $true
    if (Split-Path -Path $InstallerPath -IsAbsolute)
    {
        $driveLetter = (Split-Path -Path $InstallerPath -Qualifier).TrimEnd(":")
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
            $zone = Get-Item -Path $InstallerPath -Stream "Zone.Identifier" -EA SilentlyContinue
        }
        catch
        {
            Write-Verbose -Message 'Encountered error while reading file stream. Ignoring file stream.'
        }
        if ($null -ne $zone)
        {
            throw ("Setup file is blocked! Please use 'Unblock-File -Path $InstallerPath' " + `
                    "to unblock the file before continuing.")
        }
        Write-Verbose -Message "File not blocked, continuing."
    }

    Write-Verbose -Message "Checking if Path is an UNC path"
    $uncInstall = $false
    if ($BinaryDir.StartsWith("\\"))
    {
        Write-Verbose -Message ("Specified BinaryDir is an UNC path. Adding servername to Local " +
            "Intranet Zone")

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

    $configPath = Join-Path -Path $env:temp -ChildPath "SPInstallConfig.xml"

    $configData = "<Configuration>
    <Package Id=`"sts`">
        <Setting Id=`"LAUNCHEDFROMSETUPSTS`" Value=`"Yes`"/>
    </Package>

    <Package Id=`"spswfe`">
        <Setting Id=`"SETUPCALLED`" Value=`"1`"/>
    </Package>

    <Logging Type=`"verbose`" Path=`"%temp%`" Template=`"SharePoint Server Setup(*).log`"/>
    <PIDKEY Value=`"$ProductKey`" />
    <Display Level=`"none`" CompletionNotice=`"no`" />
"

    if ($PSBoundParameters.ContainsKey("InstallPath") -eq $true)
    {
        $configData += "    <INSTALLLOCATION Value=`"$InstallPath`" />
"
    }
    if ($PSBoundParameters.ContainsKey("DataPath") -eq $true)
    {
        $configData += "    <DATADIR Value=`"$DataPath`"/>
"
    }
    $configData += "    <Setting Id=`"SERVERROLE`" Value=`"APPLICATION`"/>
    <Setting Id=`"USINGUIINSTALLMODE`" Value=`"0`"/>
    <Setting Id=`"SETUP_REBOOT`" Value=`"Never`" />
    <Setting Id=`"SETUPTYPE`" Value=`"CLEAN_INSTALL`"/>
</Configuration>"

    $configData | Out-File -FilePath $configPath

    Write-Verbose -Message "Beginning installation of SharePoint"

    $setupExe = Join-Path -Path $BinaryDir -ChildPath "setup.exe"

    $setup = Start-Process -FilePath $setupExe `
        -ArgumentList "/config `"$configPath`"" `
        -Wait `
        -PassThru

    if ($uncInstall -eq $true)
    {
        Write-Verbose -Message "Removing added path from the Local Intranet Zone"
        Remove-SPDscZoneMap -ServerName $serverName
    }

    # Exit codes: https://docs.microsoft.com/en-us/windows/desktop/msi/error-codes
    switch ($setup.ExitCode)
    {
        0
        {
            Write-Verbose -Message "SharePoint binary installation complete"
            $global:DSCMachineStatus = 1
        }
        3010
        {
            Write-Verbose -Message "SharePoint binary installation complete, but reboot is required"
            $global:DSCMachineStatus = 1
        }
        30066
        {
            $pr1 = ("HKLM:\Software\Microsoft\Windows\CurrentVersion\" + `
                    "Component Based Servicing\RebootPending")
            $pr2 = ("HKLM:\Software\Microsoft\Windows\CurrentVersion\" + `
                    "WindowsUpdate\Auto Update\RebootRequired")
            $pr3 = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
            if (    ($null -ne (Get-Item -Path $pr1 -ErrorAction SilentlyContinue)) `
                    -or ($null -ne (Get-Item -Path $pr2 -ErrorAction SilentlyContinue)) `
                    -or ((Get-Item -Path $pr3 | Get-ItemProperty).PendingFileRenameOperations.count -gt 0) `
            )
            {

                Write-Verbose -Message ("SPInstall has detected the server has pending " + `
                        "a reboot. Flagging to the DSC engine that the " + `
                        "server should reboot before continuing.")
                $global:DSCMachineStatus = 1
            }
            else
            {
                throw ("SharePoint installation has failed due to an issue with prerequisites " + `
                        "not being installed correctly. Please review the setup logs.")
            }
        }
        Default
        {
            throw "SharePoint install failed, exit code was $($setup.ExitCode)"
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
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [System.String]
        $BinaryDir,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ProductKey,

        [Parameter()]
        [System.String]
        $InstallPath,

        [Parameter()]
        [System.String]
        $DataPath,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Testing install status of SharePoint"

    $PSBoundParameters.Ensure = $Ensure

    if ($Ensure -eq "Absent")
    {
        throw [Exception] ("SharePointDsc does not support uninstalling SharePoint or " + `
                "its prerequisites. Please remove this manually.")
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

function Export-TargetResource
{
    param(
        [Parameter()]
        [System.String]
        $ProductKey = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX",

        [Parameter()]
        [System.String]
        $BinaryLocation = "\\<location>"
    )
    Add-ConfigurationDataEntry -Node "NonNodeData" -Key "FullInstallation" -Value "`$False" -Description "Specifies whether or not the DSC configuration script will install the SharePoint Prerequisites and Binaries;"
    $Content = "        if(`$ConfigurationData.NonNodeData.FullInstallation)`r`n"
    $Content += "        {`r`n"
    $Content += "            SPInstall BinaryInstallation" + "`r`n            {`r`n"

    if ([System.String]::IsNullOrEmpty($BinaryLocation))
    {
        $BinaryLocation = "\\<location>"
    }
    Add-ConfigurationDataEntry -Node "NonNodeData" -Key "SPInstallationBinaryPath" -Value $BinaryLocation -Description "Location of the SharePoint Binaries (local path or network share);"
    $Content += "                BinaryDir = `$ConfigurationData.NonNodeData.SPInstallationBinaryPath;`r`n"
    if ([System.String]::IsNullOrEmpty($ProductKey))
    {
        $ProductKey = "xxxxx-xxxxx-xxxxx-xxxxx"
    }
    Add-ConfigurationDataEntry -Node "NonNodeData" -Key "SPProductKey" -Value $ProductKey -Description "SharePoint Product Key"
    $Content += "                ProductKey = `$ConfigurationData.NonNodeData.SPProductKey;`r`n"
    $Content += "                Ensure = `"Present`";`r`n"
    $Content += "                IsSingleInstance = `"Yes`";`r`n"
    $Content += "                PSDscRunAsCredential = `$Creds" + ($Global:spFarmAccount.Username.Split('\'))[1].Replace("-","_").Replace(".", "_") + ";`r`n"
    $Content += "            }`r`n"
    $Content += "        }`r`n"
    
    Return $Content
}

Export-ModuleMember -Function *-TargetResource
