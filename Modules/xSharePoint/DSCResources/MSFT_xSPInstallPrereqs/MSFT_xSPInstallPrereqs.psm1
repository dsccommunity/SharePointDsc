function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $InstallerPath
    )
    
    $returnValue = @{}

    Write-Verbose "Getting installed windows features"
    $WindowsFeatures = Get-WindowsFeature Net-Framework-Features,Web-Server,Web-WebServer,Web-Common-Http,Web-Static-Content,Web-Default-Doc,Web-Dir-Browsing,Web-Http-Errors,Web-App-Dev,Web-Asp-Net,Web-Net-Ext,Web-ISAPI-Ext,Web-ISAPI-Filter,Web-Health,Web-Http-Logging,Web-Log-Libraries,Web-Request-Monitor,Web-Http-Tracing,Web-Security,Web-Basic-Auth,Web-Windows-Auth,Web-Filtering,Web-Digest-Auth,Web-Performance,Web-Stat-Compression,Web-Dyn-Compression,Web-Mgmt-Tools,Web-Mgmt-Console,Web-Mgmt-Compat,Web-Metabase,Application-Server,AS-Web-Support,AS-TCP-Port-Sharing,AS-WAS-Support, AS-HTTP-Activation,AS-TCP-Activation,AS-Named-Pipes,AS-Net-Framework,WAS,WAS-Process-Model,WAS-NET-Environment,WAS-Config-APIs,Web-Lgcy-Scripting,Windows-Identity-Foundation,Server-Media-Foundation,Xps-Viewer
    foreach ($feature in $WindowsFeatures) {
        $returnValue.Add($feature.Name, $feature.Installed)
    }

    Write-Verbose "Checking windows packages"
    $installedItems = Get-WmiObject -Class Win32_Product
    #TODO: Ensure this checks for all prereqs, believe this list is missing a couple
    #TODO: Check the list on other operating systems, this was tested on 2012 R2
    $returnValue.Add("Microsoft SQL Server 2008 R2 Native Client", (($installedItems | ? {$_.Name -eq "Microsoft SQL Server 2008 R2 Native Client"}) -ne $null))
    $returnValue.Add("Microsoft Sync Framework Runtime v1.0 SP1 (x64)", (($installedItems | ? {$_.Name -eq "Microsoft Sync Framework Runtime v1.0 SP1 (x64)"}) -ne $null))
    $returnValue.Add("AppFabric 1.1 for Windows Server", (($installedItems | ? {$_.Name -eq "AppFabric 1.1 for Windows Server"}) -ne $null))

    # Detect Identity extensions from the registry as depending on the user that installed it may not appear in the WmiObject call
    $returnValue.Add("Microsoft Identity Extensions", (@(Get-ChildItem HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\ -Recurse | ? {$_.GetValue("DisplayName") -eq "Microsoft Identity Extensions" }).Count -gt 0))
    $returnValue.Add("Active Directory Rights Management Services Client 2.0", (($installedItems | ? {$_.Name -eq "Active Directory Rights Management Services Client 2.0"}) -ne $null))
    $returnValue.Add("WCF Data Services 5.0 (for OData v3) Primary Components", (($installedItems | ? {$_.Name -eq "WCF Data Services 5.0 (for OData v3) Primary Components"}) -ne $null))
    $returnValue.Add("WCF Data Services 5.6.0 Runtime", (($installedItems | ? {$_.Name -eq "WCF Data Services 5.6.0 Runtime"}) -ne $null))
    $returnValue.Add("Microsoft CCR and DSS Runtime 2008 R3", (($installedItems | ? {$_.Name -eq "Microsoft CCR and DSS Runtime 2008 R3"}) -ne $null))

    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $InstallerPath,
        [System.Boolean]
        $OnlineMode,
        [System.String]
        $SQLNCli,
        [System.String]
        $PowerShell,
        [System.String]
        $NETFX,
        [System.String]
        $IDFX,
        [System.String]
        $Sync,
        [System.String]
        $AppFabric,
        [System.String]
        $IDFX11,
        [System.String]
        $MSIPCClient,
        [System.String]
        $WCFDataServices,
        [System.String]
        $KB2671763,
        [System.String]
        $WCFDataServices56
    )

    if ($OnlineMode -eq $false) {
        if ([string]::IsNullOrEmpty($SQLNCli)) { throw "In offline mode parameter SQLNCli is required" }
        if ([string]::IsNullOrEmpty($PowerShell)) { throw "In offline mode parameter PowerShell is required" }
        if ([string]::IsNullOrEmpty($NETFX)) { throw "In offline mode parameter NETFX is required" }
        if ([string]::IsNullOrEmpty($IDFX)) { throw "In offline mode parameter IDFX is required" }
        if ([string]::IsNullOrEmpty($Sync)) { throw "In offline mode Sync SQLNCli is required" }
        if ([string]::IsNullOrEmpty($AppFabric)) { throw "In offline mode parameter AppFabric is required" }
        if ([string]::IsNullOrEmpty($IDFX11)) { throw "In offline mode parameter IDFX11 is required" }
        if ([string]::IsNullOrEmpty($MSIPCClient)) { throw "In offline mode parameter MSIPCClient is required" }
        if ([string]::IsNullOrEmpty($WCFDataServices)) { throw "In offline mode parameter WCFDataServices is required" }
        if ([string]::IsNullOrEmpty($KB2671763)) { throw "In offline mode parameter KB2671763 is required" }
        if ([string]::IsNullOrEmpty($WCFDataServices56)) { throw "In offline mode parameter WCFDataServices56 is required" }
    }
    
    Write-Verbose "Calling the SharePoint Pre-req installer"

    if ($OnlineMode) {
        $args = "/unattended"
    } else {
        $args = "/unattended /SQLNCli:`"$SQLNCli`" /PowerShell:`"$PowerShell`" /NETFX:`"$NETFX`" /IDFX:`"$IDFX`" /Sync:`"$Sync`" /AppFabric:`"$AppFabric`" /IDFX11:`"$IDFX11`" /MSIPCClient:`"$MSIPCClient`" /WCFDataServices:`"$WCFDataServices`" /KB2671763:`"$KB2671763`" /WCFDataServices56:`"$WCFDataServices56`""
    }
    Write-Verbose "Args for prereq installer are: $args"
    $process = Start-Process -FilePath $InstallerPath -ArgumentList $args -Wait

    switch ($process.ExitCode) {
        0 {
            Write-Verbose "Installer completed successfully"
        }
        default {
            $code = $process.ExitCode
            Write-Verbose "Machine needs reboot, exit code was $code"
            $global:DSCMachineStatus = 1
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
        $InstallerPath,
        [System.Boolean]
        $OnlineMode,
        [System.String]
        $SQLNCli,
        [System.String]
        $PowerShell,
        [System.String]
        $NETFX,
        [System.String]
        $IDFX,
        [System.String]
        $Sync,
        [System.String]
        $AppFabric,
        [System.String]
        $IDFX11,
        [System.String]
        $MSIPCClient,
        [System.String]
        $WCFDataServices,
        [System.String]
        $KB2671763,
        [System.String]
        $WCFDataServices56
    )


    $result = Get-TargetResource -InstallerPath $InstallerPath
    Write-Verbose "Checking installation of SharePoint prerequisites"
    if (($result.Values | Where-Object { $_ -eq $false }).Count -gt 0) {
        Write-Verbose "Prerequisites were detected as missing."
        return $false
    }
    
    return $true
}

Export-ModuleMember -Function *-TargetResource

