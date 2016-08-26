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
        $SetupFile
    )

    Write-Verbose -Message 'Getting AppFabric ProductVersion from Microsoft.ApplicationServer.Caching.Configuration.dll'
    $afConfDLL = "$env:ProgramFiles\AppFabric 1.1 for Windows Server\PowershellModules\DistributedCacheConfiguration\Microsoft.ApplicationServer.Caching.Configuration.dll"
    if(Test-Path -Path $afConfDLL)
    {
        $afInstall = (Get-ItemProperty -Path $afConfDLL -Name VersionInfo)
        $Build = $afInstall.VersionInfo.ProductVersion
    }
    else
    {
        Write-Verbose -Message 'AppFabric not installed'
        [Version]$Build = '0.0.0.0'
    }
    
    return @{
        Build = $Build
        SetupFile = $SetupFile
    }
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Build,

        [parameter(Mandatory = $true)]
        [System.String]
        $SetupFile
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($null -eq $CurrentValues.Build)
    {
        throw [Exception] 'AppFabric must be installed before applying Cumulative Updates'
    }

    Write-Verbose -Message 'Beginning installation of AppFabric Cumulative Update'
    
    $setup = Start-Process -FilePath $SetupFile `
                           -ArgumentList "/quiet /passive /norestart" `
                           -Wait `
                           -PassThru

    if ($setup.ExitCode -eq 0) 
    {
        Write-Verbose -Message "AppFabric Cumulative Update installation complete"
            $pr1 = ("HKLM:\Software\Microsoft\Windows\CurrentVersion\" + `
                    "Component Based Servicing\RebootPending")
            $pr2 = ("HKLM:\Software\Microsoft\Windows\CurrentVersion\" + `
                    "WindowsUpdate\Auto Update\RebootRequired")
            $pr3 = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
            if (    ($null -ne (Get-Item $pr1 -ErrorAction SilentlyContinue)) `
                -or ($null -ne (Get-Item $pr2 -ErrorAction SilentlyContinue)) `
                -or ((Get-Item $pr3 | Get-ItemProperty).PendingFileRenameOperations.count -gt 0) `
                ) 
            {
                    
                Write-Verbose -Message ("SPInstallAppFabricUpdate has detected the server has pending " + `
                                        "a reboot. Flagging to the DSC engine that the " + `
                                        "server should reboot before continuing.")
                $global:DSCMachineStatus = 1
            }
    }
    else
    {
        throw "SharePoint cumulative update install failed, exit code was $($setup.ExitCode)"
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
        $SetupFile
    )

    Write-Verbose -Message "Testing desired minium build number"
    $CurrentValues = Get-TargetResource @PSBoundParameters

    [Version]$DesiredBuild = $Build
    [Version]$ActualBuild = $CurrentValues.Build
    
    if ($ActualBuild -ge $DesiredBuild)
    {
        return $true
    }
    else
    {
        return $false
    }
}


Export-ModuleMember -Function *-TargetResource

