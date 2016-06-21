function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.Boolean] $RunConfigWizard,
        [parameter(Mandatory = $true)]  [ValidateSet("mon","tue","wed","thu","fri","sat","sun")] [System.String[]] $DatabaseUpgradeDays,
        [parameter(Mandatory = $true)]  [System.String] $DatabaseUpgradeTime,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Getting status of Configuration Wizard"

    # Check which version of SharePoint is installed
    if ((Get-SPDSCInstalledProductVersion).FileMajorPart -eq 15) {
        $wssRegKey ="hklm:SOFTWARE\Microsoft\Shared Tools\Web Server Extensions\15.0\WSS"
    } else {
        $wssRegKey ="hklm:SOFTWARE\Microsoft\Shared Tools\Web Server Extensions\16.0\WSS"
    }

    # Read LanguagePackInstalled and SetupType registry keys
    $languagePackInstalled = Get-SPDSCRegistryKey $wssRegKey "LanguagePackInstalled"
    $setupType = Get-SPDSCRegistryKey $wssRegKey "SetupType"

    # Determine if LanguagePackInstalled=1 or SetupType=B2B_Upgrade. If so, the Config Wizard is required
    if (($languagePackInstalled -eq 1) -or ($setupType -eq "B2B_UPGRADE")) {
        return @{
            RunConfigWizard = $true
            DatabaseUpgradeDays = $DatabaseUpgradeDays
            DatabaseUpgradeTime = $DatabaseUpgradeTime
        }
    } else {
        return @{
            RunConfigWizard = $false
            DatabaseUpgradeDays = $DatabaseUpgradeDays
            DatabaseUpgradeTime = $DatabaseUpgradeTime
        }
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  [System.Boolean] $RunConfigWizard,
        [parameter(Mandatory = $true)]  [ValidateSet("mon","tue","wed","thu","fri","sat","sun")] [System.String[]] $DatabaseUpgradeDays,
        [parameter(Mandatory = $true)]  [System.String] $DatabaseUpgradeTime,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    if ($RunConfigWizard -eq $false) {
        Write-Verbose -Message "RunConfigWizard is set to False, so running the Configuration Wizard is not required"
        return
    }

    # Check which version of SharePoint is installed
    if ((Get-SPDSCInstalledProductVersion).FileMajorPart -eq 15) {
        $BinaryDir = Join-Path $env:CommonProgramFiles "Microsoft Shared\Web Server Extensions\15\BIN"
    } else {
        $BinaryDir = Join-Path $env:CommonProgramFiles "Microsoft Shared\Web Server Extensions\16\BIN"
    }

    # Start wizard
    Write-Verbose -Message "Starting Configuration Wizard"
    $psconfigExe = Join-Path -Path $BinaryDir -ChildPath "setup.exe"
    $psconfig = Start-Process -FilePath $psconfigExe -ArgumentList "-cmd upgrade -inplace b2b -wait -force" -Wait -PassThru

############# CHECK EXIT CODES
    switch ($psconfig.ExitCode) {
        0 {  
            Write-Verbose -Message "SharePoint binary installation complete"
            $global:DSCMachineStatus = 1
        }
        30066 {
            if (    ((Get-Item 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending' -ErrorAction SilentlyContinue) -ne $null) `
                -or ((Get-Item 'HKLM:\Software\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired' -ErrorAction SilentlyContinue) -ne $null) `
                -or ((Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' | Get-ItemProperty).PendingFileRenameOperations.count -gt 0) `
                ) {
                    
                Write-Verbose -Message "xSPInstall has detected the server has pending a reboot. Flagging to the DSC engine that the server should reboot before continuing."
                $global:DSCMachineStatus = 1
            } else {
                throw "SharePoint installation has failed due to an issue with prerequisites not being installed correctly. Please review the setup logs."
            }
        }
        Default {
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
        [parameter(Mandatory = $true)]  [System.Boolean] $RunConfigWizard,
        [parameter(Mandatory = $true)]  [ValidateSet("mon","tue","wed","thu","fri","sat","sun")] [System.String[]] $DatabaseUpgradeDays,
        [parameter(Mandatory = $true)]  [System.String] $DatabaseUpgradeTime,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    if ($RunConfigWizard -eq $false) {
        Write-Verbose -Message "RunConfigWizard is set to False, so running the Configuration Wizard is not required"
        return $true
    }

    Write-Verbose -Message "Testing status of Configuration Wizard"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    return -not($CurrentValues.RunConfigWizard)
}

Export-ModuleMember -Function *-TargetResource

Function Get-SPDSCRegistryKey() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $key,

        [parameter(Mandatory = $true)]
        [System.String]
        $value
    )

    if ((Test-Path $path) -eq $true) {
        $regkey = Get-ItemProperty -LiteralPath $path
        return $regkey.$value
    }
    return $null
}