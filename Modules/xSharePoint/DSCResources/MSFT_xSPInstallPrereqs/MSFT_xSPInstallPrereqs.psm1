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
    Write-Verbose -Message "Detecting SharePoint version from binaries"
    $majorVersion = (Get-xSharePointAssemblyVerion -PathToAssembly $InstallerPath).Major
    if ($majorVersion -eq 15) {
        Write-Verbose -Message "Version: SharePoint 2013"
    }
    if ($majorVersion -eq 16) {
        Write-Verbose -Message "Version: SharePoint 2016"
    }

    Write-Verbose -Message "Getting installed windows features"
        
    if ($majorVersion -eq 15) {
        $WindowsFeatures = Get-WindowsFeature -Name Net-Framework-Features,Web-Server,Web-WebServer,Web-Common-Http,Web-Static-Content,Web-Default-Doc,Web-Dir-Browsing,Web-Http-Errors,Web-App-Dev,Web-Asp-Net,Web-Net-Ext,Web-ISAPI-Ext,Web-ISAPI-Filter,Web-Health,Web-Http-Logging,Web-Log-Libraries,Web-Request-Monitor,Web-Http-Tracing,Web-Security,Web-Basic-Auth,Web-Windows-Auth,Web-Filtering,Web-Digest-Auth,Web-Performance,Web-Stat-Compression,Web-Dyn-Compression,Web-Mgmt-Tools,Web-Mgmt-Console,Web-Mgmt-Compat,Web-Metabase,Application-Server,AS-Web-Support,AS-TCP-Port-Sharing,AS-WAS-Support, AS-HTTP-Activation,AS-TCP-Activation,AS-Named-Pipes,AS-Net-Framework,WAS,WAS-Process-Model,WAS-NET-Environment,WAS-Config-APIs,Web-Lgcy-Scripting,Windows-Identity-Foundation,Server-Media-Foundation,Xps-Viewer
    }
    if ($majorVersion -eq 16) {
        $WindowsFeatures = Get-WindowsFeature -Name Application-Server,AS-NET-Framework,AS-Web-Support,Web-Server,Web-WebServer,Web-Common-Http,Web-Default-Doc,Web-Dir-Browsing,Web-Http-Errors,Web-Static-Content,Web-Http-Redirect,Web-Health,Web-Http-Logging,Web-Log-Libraries,Web-Request-Monitor,Web-Performance,Web-Stat-Compression,Web-Dyn-Compression,Web-Security,Web-Filtering,Web-Basic-Auth,Web-Client-Auth,Web-Digest-Auth,Web-Cert-Auth,Web-IP-Security,Web-Url-Auth,Web-Windows-Auth,Web-App-Dev,Web-Net-Ext,Web-Net-Ext45,Web-Asp-Net45,Web-ISAPI-Ext,Web-ISAPI-Filter,Web-Mgmt-Tools,Web-Mgmt-Console,Web-Mgmt-Compat,Web-Metabase,Web-Lgcy-Mgmt-Console,Web-Lgcy-Scripting,Web-WMI,Web-Scripting-Tools,NET-Framework-Features,NET-Framework-Core,NET-HTTP-Activation,NET-Non-HTTP-Activ,NET-Framework-45-ASPNET,NET-WCF-HTTP-Activation45,Windows-Identity-Foundation,PowerShell-V2,WAS,WAS-Process-Model,WAS-NET-Environment,WAS-Config-APIs
    }    
    foreach ($feature in $WindowsFeatures) {
        $returnValue.Add($feature.Name, $feature.Installed)
    }

    Write-Verbose -Message "Checking windows packages"
    $installedItems = Get-CimInstance -ClassName Win32_Product
    
    #Common prereqs
    $returnValue.Add("Microsoft Identity Extensions", (@(Get-ChildItem HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\ -Recurse | ? {$_.GetValue("DisplayName") -eq "Microsoft Identity Extensions" }).Count -gt 0))
    $returnValue.Add("Microsoft CCR and DSS Runtime 2008 R3", (($installedItems | ? {$_.Name -eq "Microsoft CCR and DSS Runtime 2008 R3"}) -ne $null))
    $returnValue.Add("Microsoft Sync Framework Runtime v1.0 SP1 (x64)", (($installedItems | ? {$_.Name -eq "Microsoft Sync Framework Runtime v1.0 SP1 (x64)"}) -ne $null))
    $returnValue.Add("Active Directory Rights Management Services Client 2.0", (($installedItems | ? {$_.Name -eq "Active Directory Rights Management Services Client 2.0"}) -ne $null))
    $returnValue.Add("AppFabric 1.1 for Windows Server", (($installedItems | ? {$_.Name -eq "AppFabric 1.1 for Windows Server"}) -ne $null))
    $returnValue.Add("WCF Data Services 5.0 (for OData v3) Primary Components", (($installedItems | ? {$_.Name -eq "WCF Data Services 5.0 (for OData v3) Primary Components"}) -ne $null))
    $returnValue.Add("WCF Data Services 5.6.0 Runtime", (($installedItems | ? {$_.Name -eq "WCF Data Services 5.6.0 Runtime"}) -ne $null))

    #SP2013 prereqs
    if ($majorVersion -eq 15) {
        $returnValue.Add("Microsoft SQL Server 2008 R2 Native Client", (($installedItems | ? {$_.Name -eq "Microsoft SQL Server 2008 R2 Native Client"}) -ne $null))
    }

    #SP2016 prereqs
    if ($majorVersion -eq 16) {
        $returnValue.Add("Microsoft ODBC Driver 11 for SQL Server", (($installedItems | ? {$_.Name -eq "Microsoft ODBC Driver 11 for SQL Server"}) -ne $null))    
        $returnValue.Add("Microsoft Visual C++ 2013 x64 Minimum Runtime - 12.0.21005", (($installedItems | ? {$_.Name -eq "Microsoft Visual C++ 2013 x64 Minimum Runtime - 12.0.21005"}) -ne $null))    
        $returnValue.Add("Microsoft Visual C++ 2013 x64 Additional Runtime - 12.0.21005", (($installedItems | ? {$_.Name -eq "Microsoft Visual C++ 2013 x64 Additional Runtime - 12.0.21005"}) -ne $null))    
        $returnValue.Add("Microsoft SQL Server 2012 Native Client", (($installedItems | ? {$_.Name.Trim() -eq "Microsoft SQL Server 2012 Native Client"}) -ne $null))    
    }
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
        $OnlineMode = $true,
        [System.String]
        $SQLNCli = [System.String]::Empty,
        [System.String]
        $PowerShell = [System.String]::Empty,
        [System.String]
        $NETFX = [System.String]::Empty,
        [System.String]
        $IDFX = [System.String]::Empty,
        [System.String]
        $Sync = [System.String]::Empty,
        [System.String]
        $AppFabric = [System.String]::Empty,
        [System.String]
        $IDFX11 = [System.String]::Empty,
        [System.String]
        $MSIPCClient = [System.String]::Empty,
        [System.String]
        $WCFDataServices = [System.String]::Empty,
        [System.String]
        $KB2671763 = [System.String]::Empty,
        [System.String]
        $WCFDataServices56 = [System.String]::Empty,
        [System.String]
        $KB2898850 = [System.String]::Empty,
        [System.String]
        $MSVCRT12 = [System.String]::Empty
    )

    Write-Verbose -Message "Detecting SharePoint version from binaries"
    $majorVersion = (Get-xSharePointAssemblyVerion -PathToAssembly $InstallerPath).Major
    if ($majorVersion -eq 15) {
        Write-Verbose -Message "Version: SharePoint 2013"
        $requiredParams = @("SQLNCli","PowerShell","NETFX","IDFX","Sync","AppFabric","IDFX11","MSIPCClient","WCFDataServices","KB2671763","WCFDataServices56")
    }
    if ($majorVersion -eq 16) {
        Write-Verbose -Message "Version: SharePoint 2016"
        $requiredParams = @("SQLNCli","Sync","AppFabric","IDFX11","MSIPCClient","WCFDataServices","KB2671763","WCFDataServices56","KB2898850","MSVCRT12")
    }
    
    $args = "/unattended"
    if ($OnlineMode -eq $false) {
        $requiredParams | ForEach-Object {
            if($PSBoundParameters.ContainsKey($_) -and [string]::IsNullOrEmpty($PSBoundParameters.$_)) {
                throw "In offline mode for version $majorVersion parameter $_ is required"
            }
        }
        $requiredParams | ForEach-Object {
            $args += " /$_ `"$($PSBoundParameters.$_)`""
        }
    }

    Write-Verbose -Message "Calling the SharePoint Pre-req installer"
    Write-Verbose -Message "Args for prereq installer are: $args"
    $process = Start-Process -FilePath $InstallerPath -ArgumentList $args -Wait -PassThru

    switch ($process.ExitCode) {
        0 {
            Write-Verbose -Message "Prerequisite installer completed successfully"
        }
        1 {
            throw "Another instance of the prerequisite installer is already running"
        }
        2 {
            throw "Invalid command line parameters passed to the prerequisite installer"
        }
        1001 {
            Write-Verbose -Message "A pending restart is blocking the prerequisite installer from running. Scheduling a reboot."
            $global:DSCMachineStatus = 1
        }
        3010 {
            Write-Verbose -Message "The prerequisite installer has run correctly and needs to reboot the machine."
            $global:DSCMachineStatus = 1
        }
        default {
            throw "The prerequisite installer ran with the following unknown exit code $($process.ExitCode)"
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
        $OnlineMode = $true,
        [System.String]
        $SQLNCli = [System.String]::Empty,
        [System.String]
        $PowerShell = [System.String]::Empty,
        [System.String]
        $NETFX = [System.String]::Empty,
        [System.String]
        $IDFX = [System.String]::Empty,
        [System.String]
        $Sync = [System.String]::Empty,
        [System.String]
        $AppFabric = [System.String]::Empty,
        [System.String]
        $IDFX11 = [System.String]::Empty,
        [System.String]
        $MSIPCClient = [System.String]::Empty,
        [System.String]
        $WCFDataServices = [System.String]::Empty,
        [System.String]
        $KB2671763 = [System.String]::Empty,
        [System.String]
        $WCFDataServices56 = [System.String]::Empty,
        [System.String]
        $KB2898850 = [System.String]::Empty,
        [System.String]
        $MSVCRT12 = [System.String]::Empty
    )


    $result = Get-TargetResource -InstallerPath $InstallerPath
    Write-Verbose -Message "Checking installation of SharePoint prerequisites"
    if (($result.Values | Where-Object { $_ -eq $false }).Count -gt 0) {
        Write-Verbose -Message "Prerequisites were detected as missing."
        return $false
    }
    
    return $true
}

Export-ModuleMember -Function *-TargetResource

