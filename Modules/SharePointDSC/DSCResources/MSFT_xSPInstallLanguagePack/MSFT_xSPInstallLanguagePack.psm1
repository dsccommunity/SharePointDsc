function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $Culture,
        [parameter(Mandatory = $true)]  [System.String] $BinaryDir,
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] [System.String] $Ensure = "Present"
    )

    Write-Verbose -Message 'Getting install status of SP language pack'

    $spInstall = Get-CimInstance -ClassName Win32_Product -Filter "Name like 'Microsoft SharePoint Server%'"
    if ($spInstall) 
    {
        $Ensure = 'Absent'
        $MajorVersion = $spInstall.version.substring(0,2)
        $installedOfficeServerLanguages = (Get-Item "HKLM:\Software\Microsoft\Office Server\$MajorVersion.0\InstalledLanguages").GetValueNames() | ? {$_ -ne ""}
        foreach ($installedOfficeServerLanguage in $installedOfficeServerLanguages)
        {
            if ($installedOfficeServerLanguage.tolower() -eq $Culture) {$Ensure = 'Present'}
        }
    } 
    else
    {
        Write-Verbose -Message 'Sharepoint not installed'
        $Ensure = 'Absent'
    }
    
    return @{
        BinaryDir = $BinaryDir
        Culture = $Culture
        Ensure = $Ensure
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $Culture,
        [parameter(Mandatory = $true)]  [System.String] $BinaryDir,
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] [System.String] $Ensure = "Present"
    )

    Write-Verbose -Message "Testing for installation of SharePoint language pack"
    $CurrentValues = Get-TargetResource @PSBoundParameters
    
    if ($CurrentValues.Ensure -eq $Ensure) {return $true} else {return $false}
}

function Set-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $Culture,
        [parameter(Mandatory = $true)]  [System.String] $BinaryDir,
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] [System.String] $Ensure = "Present"
    )

    if ($Ensure -eq 'Absent') {
        throw [Exception] 'xSharePoint does not support uninstalling SharePoint or its prerequisites. Please remove this manually.'
        return $false
    }

    Write-Verbose -Message 'Install language pack start'

    $InstallerPath = Join-Path $BinaryDir 'setup.exe'
    if (!(Test-Path $InstallerPath)) 
    {
        throw [Exception] 'setup.exe not found in the provided BinaryDir'
        return $false
    }

    $configPath = Join-Path $BinaryDir 'Files\SetupSilent\config.xml'
    if (!(Test-Path $ConfigPath)) 
    {
        throw [Exception] 'Files\SetupSilent\config.xml not found in the provided BinaryDir'
        return $false
    }

    $setup = Start-Process -WorkingDirectory $BinaryDir -FilePath $InstallerPath -ArgumentList "/config `"$configPath`"" -Wait -PassThru
 
    if ($setup.ExitCode -eq 0) {
        Write-Verbose -Message "SharePoint language pack installation complete"
        #Return true if a reboot is pending to force a reboot from dsc
        return (((Get-Item 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending' -ErrorAction SilentlyContinue) -ne $null) -or ((Get-Item 'HKLM:\Software\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired' -ErrorAction SilentlyContinue) -ne $null) -or ((Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' | Get-ItemProperty).PendingFileRenameOperations.count -gt 0))
    }
    else
    {
        throw "SharePoint language pack install failed, exit code was $($setup.ExitCode)"
        return $false
    }
}


Export-ModuleMember -Function *-TargetResource
