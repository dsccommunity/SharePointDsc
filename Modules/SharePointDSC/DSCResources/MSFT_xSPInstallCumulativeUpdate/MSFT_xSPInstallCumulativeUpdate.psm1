function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $Build,
        [parameter(Mandatory = $true)]  [System.String] $BinaryDir,
        [parameter(Mandatory = $true)]  [System.String] $CuExeName,
        [parameter(Mandatory = $false)]  [System.String] $CuInstallLogPath
    )

    Write-Verbose -Message 'Getting Sharepoint buildnumber'

    try
    {
        $spInstall = Get-xSharePointInstalledProductVersion
        $Build = $spInstall.ProductVersion
    }
    catch
    {
        Write-Verbose -Message 'Sharepoint not installed'
        $Build = $null        
    }
    
    return @{
        Build = $Build
        BinaryDir = $BinaryDir
        CuExeName = $CuExeName
        CuInstallLogPath = $CuInstallLogPath
    }
}
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $Build,
        [parameter(Mandatory = $true)]  [System.String] $BinaryDir,
        [parameter(Mandatory = $true)]  [System.String] $CuExeName,
        [parameter(Mandatory = $false)]  [System.String] $CuInstallLogPath
    )

    Write-Verbose -Message "Testing desired minium build number"
    $CurrentValues = Get-TargetResource @PSBoundParameters

    [Version]$DesiredBuild = $Build
    [Version]$ActualBuild = $CurrentValues.Build
    
    if ($ActualBuild -ge $DesiredBuild) {return $true} else {return $false}
}

function Set-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $Build,
        [parameter(Mandatory = $true)]  [System.String] $BinaryDir,
        [parameter(Mandatory = $true)]  [System.String] $CuExeName,
        [parameter(Mandatory = $false)]  [System.String] $CuInstallLogPath
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if (($CurrentValues.Build) -eq $null) {
        throw [Exception] 'xSharePoint must be installed before applying Cumulative Updates'
        return $false
    }

    Write-Verbose -Message 'Install CU start'

    $InstallerPath = Join-Path $BinaryDir $CuExeName
    if (!(Test-Path $InstallerPath)) 
    {
        throw [Exception] 'Cumultive update not found with provided path'
        return $false
    }
    
    $setup = Start-Process -WorkingDirectory $BinaryDir -FilePath $InstallerPath -ArgumentList "/log:`"$CuInstallLogPath`" /quiet /passive /norestart" -Wait -PassThru
 
    if ($setup.ExitCode -eq 0) {
        Write-Verbose -Message "SharePoint cumulative update $Build installation complete"
        #Return true if a reboot is pending to force a reboot from dsc
        return (((Get-Item 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending' -ErrorAction SilentlyContinue) -ne $null) -or ((Get-Item 'HKLM:\Software\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired' -ErrorAction SilentlyContinue) -ne $null) -or ((Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' | Get-ItemProperty).PendingFileRenameOperations.count -gt 0))
    }
    else
    {
        throw "SharePoint cumulative update install failed, exit code was $($setup.ExitCode)"
        return $false
    }
}


Export-ModuleMember -Function *-TargetResource
