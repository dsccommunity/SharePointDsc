function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Build,
        
        [parameter(Mandatory = $true)]
        [System.String]
        $BinaryDir,
        
        [parameter(Mandatory = $true)]
        [System.String]
        $CuExeName
    )

    Write-Verbose -Message 'Getting AppFabric ProductVersion from Microsoft.ApplicationServer.Caching.Configuration.dll'
    $afConfDLL = "$env:ProgramFiles\AppFabric 1.1 for Windows Server\PowershellModules\DistributedCacheConfiguration\Microsoft.ApplicationServer.Caching.Configuration.dll"
    if(Test-Path $afConfDLL)
    {
        $afInstall = (Get-ItemProperty $afConfDLL -Name VersionInfo)
        $Build = $afInstall.VersionInfo.ProductVersion
    }
    else
    {
        Write-Verbose -Message 'AppFabric not installed'
        [Version]$Build = '0.0.0.0'
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
        [parameter(Mandatory = $true)]
        [System.String]
        $Build,
        
        [parameter(Mandatory = $true)]
        [System.String]
        $BinaryDir,
        
        [parameter(Mandatory = $true)]
        [System.String]
        $CuExeName
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
        [parameter(Mandatory = $true)]
        [System.String]
        $Build,
        
        [parameter(Mandatory = $true)]
        [System.String]
        $BinaryDir,
        
        [parameter(Mandatory = $true)]
        [System.String]
        $CuExeName
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if (($CurrentValues.Build) -eq $null) {
        throw [Exception] 'AppFabric must be installed before applying Cumulative Updates'
        return $false
    }

    Write-Verbose -Message 'Install AppFabric Cumultive update start'

    $InstallerPath = Join-Path $BinaryDir $CuExeName
    if (!(Test-Path $InstallerPath)) 
    {
        throw [Exception] 'AppFabric Cumultive update not found with provided path'
        return $false
    }
    
    $setup = Start-Process -WorkingDirectory $BinaryDir -FilePath $InstallerPath -ArgumentList "/quiet /passive /norestart" -Wait -PassThru
 
    if ($setup.ExitCode -eq 0) {
        Write-Verbose -Message "AppFabric cumulative update $Build installation complete"
        #Return true if a reboot is pending to force a reboot from dsc
        return (((Get-Item 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending' -ErrorAction SilentlyContinue) -ne $null) -or ((Get-Item 'HKLM:\Software\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired' -ErrorAction SilentlyContinue) -ne $null) -or ((Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' | Get-ItemProperty).PendingFileRenameOperations.count -gt 0))
    }
    else
    {
        throw "AppFabric cumulative update install failed, exit code was $($setup.ExitCode)"
        return $false
    }
}


Export-ModuleMember -Function *-TargetResource
