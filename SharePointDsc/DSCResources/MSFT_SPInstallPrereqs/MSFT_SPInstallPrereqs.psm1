$Script:SP2013Features = @("Application-Server", "AS-NET-Framework",
    "AS-TCP-Port-Sharing", "AS-Web-Support", "AS-WAS-Support",
    "AS-HTTP-Activation", "AS-Named-Pipes", "AS-TCP-Activation", "Web-Server",
    "Web-WebServer", "Web-Common-Http", "Web-Default-Doc", "Web-Dir-Browsing",
    "Web-Http-Errors", "Web-Static-Content", "Web-Http-Redirect", "Web-Health",
    "Web-Http-Logging", "Web-Log-Libraries", "Web-Request-Monitor",
    "Web-Http-Tracing", "Web-Performance", "Web-Stat-Compression",
    "Web-Dyn-Compression", "Web-Security", "Web-Filtering", "Web-Basic-Auth",
    "Web-Client-Auth", "Web-Digest-Auth", "Web-Cert-Auth", "Web-IP-Security",
    "Web-Url-Auth", "Web-Windows-Auth", "Web-App-Dev", "Web-Net-Ext",
    "Web-Net-Ext45", "Web-Asp-Net", "Web-Asp-Net45", "Web-ISAPI-Ext",
    "Web-ISAPI-Filter", "Web-Mgmt-Tools", "Web-Mgmt-Console", "Web-Mgmt-Compat",
    "Web-Metabase", "Web-Lgcy-Scripting", "Web-WMI", "Web-Scripting-Tools",
    "NET-Framework-Features", "NET-Framework-Core", "NET-Framework-45-ASPNET",
    "NET-WCF-HTTP-Activation45", "NET-WCF-Pipe-Activation45",
    "NET-WCF-TCP-Activation45", "Server-Media-Foundation",
    "Windows-Identity-Foundation", "PowerShell-V2", "WAS", "WAS-Process-Model",
    "WAS-NET-Environment", "WAS-Config-APIs", "XPS-Viewer")

$Script:SP2016Win19Features = @("Web-Server", "Web-WebServer",
    "Web-Common-Http", "Web-Default-Doc", "Web-Dir-Browsing",
    "Web-Http-Errors", "Web-Static-Content", "Web-Health",
    "Web-Http-Logging", "Web-Log-Libraries", "Web-Request-Monitor",
    "Web-Http-Tracing", "Web-Performance", "Web-Stat-Compression",
    "Web-Dyn-Compression", "Web-Security", "Web-Filtering", "Web-Basic-Auth",
    "Web-Digest-Auth", "Web-Windows-Auth", "Web-App-Dev", "Web-Net-Ext",
    "Web-Net-Ext45", "Web-Asp-Net", "Web-Asp-Net45", "Web-ISAPI-Ext",
    "Web-ISAPI-Filter", "Web-Mgmt-Tools", "Web-Mgmt-Console",
    "Web-Mgmt-Compat", "Web-Metabase", "Web-Lgcy-Scripting", "Web-WMI",
    "NET-Framework-Features", "NET-HTTP-Activation", "NET-Non-HTTP-Activ",
    "NET-Framework-45-ASPNET", "NET-WCF-Pipe-Activation45",
    "Windows-Identity-Foundation", "WAS", "WAS-Process-Model",
    "WAS-NET-Environment", "WAS-Config-APIs", "XPS-Viewer")

$Script:SP2016Win16Features = @("Web-Server", "Web-WebServer",
    "Web-Common-Http", "Web-Default-Doc", "Web-Dir-Browsing",
    "Web-Http-Errors", "Web-Static-Content", "Web-Health",
    "Web-Http-Logging", "Web-Log-Libraries", "Web-Request-Monitor",
    "Web-Http-Tracing", "Web-Performance", "Web-Stat-Compression",
    "Web-Dyn-Compression", "Web-Security", "Web-Filtering", "Web-Basic-Auth",
    "Web-Digest-Auth", "Web-Windows-Auth", "Web-App-Dev", "Web-Net-Ext",
    "Web-Net-Ext45", "Web-Asp-Net", "Web-Asp-Net45", "Web-ISAPI-Ext",
    "Web-ISAPI-Filter", "Web-Mgmt-Tools", "Web-Mgmt-Console",
    "Web-Mgmt-Compat", "Web-Metabase", "Web-Lgcy-Scripting", "Web-WMI",
    "NET-Framework-Features", "NET-HTTP-Activation", "NET-Non-HTTP-Activ",
    "NET-Framework-45-ASPNET", "NET-WCF-Pipe-Activation45",
    "Windows-Identity-Foundation", "WAS", "WAS-Process-Model",
    "WAS-NET-Environment", "WAS-Config-APIs", "XPS-Viewer")

$Script:SP2016Win12r2Features = @("Application-Server", "AS-NET-Framework",
    "AS-Web-Support", "Web-Server", "Web-WebServer", "Web-Common-Http",
    "Web-Default-Doc", "Web-Dir-Browsing", "Web-Http-Errors",
    "Web-Static-Content", "Web-Http-Redirect", "Web-Health",
    "Web-Http-Logging", "Web-Log-Libraries", "Web-Request-Monitor",
    "Web-Performance", "Web-Stat-Compression", "Web-Dyn-Compression",
    "Web-Security", "Web-Filtering", "Web-Basic-Auth", "Web-Client-Auth",
    "Web-Digest-Auth", "Web-Cert-Auth", "Web-IP-Security", "Web-Url-Auth",
    "Web-Windows-Auth", "Web-App-Dev", "Web-Net-Ext", "Web-Net-Ext45",
    "Web-Asp-Net45", "Web-ISAPI-Ext", "Web-ISAPI-Filter", "Web-Mgmt-Tools",
    "Web-Mgmt-Console", "Web-Mgmt-Compat", "Web-Metabase",
    "Web-Lgcy-Mgmt-Console", "Web-Lgcy-Scripting", "Web-WMI",
    "Web-Scripting-Tools", "NET-Framework-Features", "NET-Framework-Core",
    "NET-HTTP-Activation", "NET-Non-HTTP-Activ", "NET-Framework-45-ASPNET",
    "NET-WCF-HTTP-Activation45", "Windows-Identity-Foundation",
    "PowerShell-V2", "WAS", "WAS-Process-Model", "WAS-NET-Environment",
    "WAS-Config-APIs")

$Script:SP2019Win16Features = @("Web-Server", "Web-WebServer",
    "Web-Common-Http", "Web-Default-Doc", "Web-Dir-Browsing",
    "Web-Http-Errors", "Web-Static-Content", "Web-Health",
    "Web-Http-Logging", "Web-Log-Libraries", "Web-Request-Monitor",
    "Web-Http-Tracing", "Web-Performance", "Web-Stat-Compression",
    "Web-Dyn-Compression", "Web-Security", "Web-Filtering", "Web-Basic-Auth",
    "Web-Windows-Auth", "Web-App-Dev", "Web-Net-Ext",
    "Web-Net-Ext45", "Web-Asp-Net", "Web-Asp-Net45", "Web-ISAPI-Ext",
    "Web-ISAPI-Filter", "Web-Mgmt-Tools", "Web-Mgmt-Console",
    "NET-Framework-Features", "NET-HTTP-Activation", "NET-Non-HTTP-Activ",
    "NET-Framework-45-ASPNET", "NET-WCF-Pipe-Activation45",
    "Windows-Identity-Foundation", "WAS", "WAS-Process-Model",
    "WAS-NET-Environment", "WAS-Config-APIs", "XPS-Viewer")

$Script:SP2019Win19Features = @("Web-Server", "Web-WebServer",
    "Web-Common-Http", "Web-Default-Doc", "Web-Dir-Browsing",
    "Web-Http-Errors", "Web-Static-Content", "Web-Health",
    "Web-Http-Logging", "Web-Log-Libraries", "Web-Request-Monitor",
    "Web-Http-Tracing", "Web-Performance", "Web-Stat-Compression",
    "Web-Dyn-Compression", "Web-Security", "Web-Filtering", "Web-Basic-Auth",
    "Web-Windows-Auth", "Web-App-Dev", "Web-Net-Ext",
    "Web-Net-Ext45", "Web-Asp-Net", "Web-Asp-Net45", "Web-ISAPI-Ext",
    "Web-ISAPI-Filter", "Web-Mgmt-Tools", "Web-Mgmt-Console",
    "NET-Framework-Features", "NET-HTTP-Activation", "NET-Non-HTTP-Activ",
    "NET-Framework-45-ASPNET", "NET-WCF-Pipe-Activation45",
    "Windows-Identity-Foundation", "WAS", "WAS-Process-Model",
    "WAS-NET-Environment", "WAS-Config-APIs", "XPS-Viewer")

$Script:SPSEFeatures = @("NET-WCF-Pipe-Activation45",
    "NET-WCF-HTTP-Activation45", "NET-WCF-TCP-Activation45",
    "Web-Server", "Web-WebServer", "Web-Common-Http",
    "Web-Static-Content", "Web-Default-Doc", "Web-Dir-Browsing",
    "Web-Http-Errors", "Web-App-Dev", "Web-Asp-Net45", "Web-Net-Ext45",
    "Web-ISAPI-Ext", "Web-ISAPI-Filter", "Web-Health", "Web-Http-Logging",
    "Web-Log-Libraries", "Web-Request-Monitor", "Web-Http-Tracing",
    "Web-Security", "Web-Basic-Auth", "Web-Windows-Auth", "Web-Filtering",
    "Web-Performance", "Web-Stat-Compression", "Web-Dyn-Compression",
    "WAS", "WAS-Process-Model", "WAS-Config-APIs", "Web-Mgmt-Console",
    "Web-Mgmt-Tools")

$Script:SPSEWinCoreFeatures = @("NET-WCF-Pipe-Activation45",
    "NET-WCF-HTTP-Activation45", "NET-WCF-TCP-Activation45",
    "Web-Server", "Web-WebServer", "Web-Common-Http",
    "Web-Static-Content", "Web-Default-Doc", "Web-Dir-Browsing",
    "Web-Http-Errors", "Web-App-Dev", "Web-Asp-Net45", "Web-Net-Ext45",
    "Web-ISAPI-Ext", "Web-ISAPI-Filter", "Web-Health", "Web-Http-Logging",
    "Web-Log-Libraries", "Web-Request-Monitor", "Web-Http-Tracing",
    "Web-Security", "Web-Basic-Auth", "Web-Windows-Auth", "Web-Filtering",
    "Web-Performance", "Web-Stat-Compression", "Web-Dyn-Compression",
    "WAS", "WAS-Process-Model", "WAS-Config-APIs",
    "Web-Mgmt-Tools")

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
        $InstallerPath,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $OnlineMode,

        [Parameter()]
        [System.String]
        $SXSpath,

        [Parameter()]
        [System.String]
        $SQLNCli,

        [Parameter()]
        [System.String]
        $PowerShell,

        [Parameter()]
        [System.String]
        $NETFX,

        [Parameter()]
        [System.String]
        $IDFX,

        [Parameter()]
        [System.String]
        $Sync,

        [Parameter()]
        [System.String]
        $AppFabric,

        [Parameter()]
        [System.String]
        $IDFX11,

        [Parameter()]
        [System.String]
        $MSIPCClient,

        [Parameter()]
        [System.String]
        $WCFDataServices,

        [Parameter()]
        [System.String]
        $KB2671763,

        [Parameter()]
        [System.String]
        $WCFDataServices56,

        [Parameter()]
        [System.String]
        $MSVCRT11,

        [Parameter()]
        [System.String]
        $MSVCRT14,

        [Parameter()]
        [System.String]
        $MSVCRT141,

        [Parameter()]
        [System.String]
        $MSVCRT142,

        [Parameter()]
        [System.String]
        $KB3092423,

        [Parameter()]
        [System.String]
        $ODBC,

        [Parameter()]
        [System.String]
        $DotNetFx,

        [Parameter()]
        [System.String]
        $DotNet472,

        [Parameter()]
        [System.String]
        $DotNet48,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Getting installation status of SharePoint prerequisites"

    Write-Verbose -Message "Check if InstallerPath folder exists"
    if (-not(Test-Path -Path $InstallerPath))
    {
        $message = "PrerequisitesInstaller cannot be found: {$InstallerPath}"
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    Write-Verbose -Message "Checking file status of $InstallerPath"
    $checkBlockedFile = $true
    if (Split-Path -Path $InstallerPath -IsAbsolute)
    {
        $driveLetter = (Split-Path -Path $InstallerPath -Qualifier).TrimEnd(":")
        Write-Verbose -Message "InstallerPath refers to drive $driveLetter"

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
            $message = ("PrerequisitesInstaller is blocked! Please use 'Unblock-File -Path " + `
                    "$InstallerPath' to unblock the file before continuing.")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }
        Write-Verbose -Message "File not blocked, continuing."
    }

    $majorVersion = (Get-SPDscAssemblyVersion -PathToAssembly $InstallerPath)
    $buildVersion = (Get-SPDscBuildVersion -PathToAssembly $InstallerPath)
    if ($majorVersion -eq 15)
    {
        Write-Verbose -Message "Version: SharePoint 2013"
    }
    if ($majorVersion -eq 16)
    {
        if ($buildVersion -lt 10000)
        {
            Write-Verbose -Message "Version: SharePoint 2016"
        }
        elseif ($buildVersion -ge 10000 -and
            $buildVersion -le 12999)
        {
            Write-Verbose -Message "Version: SharePoint 2019"
        }
        elseif ($buildVersion -ge 13000)
        {
            Write-Verbose -Message "Version: SharePoint Server Subscription Edition"
        }
    }

    Write-Verbose -Message "Getting installed windows features"

    $osVersion = Get-SPDscOSVersion
    if ($majorVersion -eq 15)
    {
        if ($osVersion.Major -ne 6)
        {
            $message = "SharePoint 2013 only supports Windows Server 2012 R2 and below"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }

        $WindowsFeatures = Get-WindowsFeature -Name $Script:SP2013Features
    }
    elseif ($majorVersion -eq 16)
    {
        if ($buildVersion -lt 10000)
        {
            if ($osVersion.Major -eq 10)
            {
                if ($osVersion.Build -lt 17763)
                {
                    Write-Verbose -Message "OS Version: Windows Server 2016"
                    $WindowsFeatures = Get-WindowsFeature -Name $Script:SP2016Win16Features
                }
                else
                {
                    Write-Verbose -Message "OS Version: Windows Server 2019"
                    $WindowsFeatures = Get-WindowsFeature -Name $Script:SP2016Win19Features
                }
            }
            elseif ($osVersion.Major -eq 6 -and $osVersion.Minor -eq 3)
            {
                Write-Verbose -Message "OS Version: Windows Server 2012 R2"
                $WindowsFeatures = Get-WindowsFeature -Name $Script:SP2016Win12r2Features
            }
            else
            {
                $message = "SharePoint 2016 only supports Windows Server 2019, 2016 or 2012 R2"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
        }
        # SharePoint 2019
        elseif ($buildVersion -ge 10000 -and
            $buildVersion -le 12999)
        {
            if ($osVersion.Major -eq 10)
            {
                if ($osVersion.Build -lt 17763)
                {
                    Write-Verbose -Message "OS Version: Windows Server 2016"
                    $WindowsFeatures = Get-WindowsFeature -Name $Script:SP2019Win16Features
                }
                else
                {
                    Write-Verbose -Message "OS Version: Windows Server 2019"
                    $WindowsFeatures = Get-WindowsFeature -Name $Script:SP2019Win19Features
                }
            }
            else
            {
                $message = "SharePoint 2019 only supports Windows Server 2016 or Windows Server 2019"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
        }
        # SharePoint Server Subscription Edition
        elseif ($buildVersion -ge 13000)
        {
            if ($osVersion.Major -eq 10)
            {
                if ($osVersion.Build -eq 17763)
                {
                    Write-Verbose -Message "OS Version: Windows Server 2019"
                    $WindowsFeatures = Get-WindowsFeature -Name $Script:SPSEFeatures
                }
                elseif ($osVersion.Build -ge 20000)
                {
                    $OSServerLevel = Get-ComputerInfo | Select-Object $OSServerLevel
                    if ($OSServerLevel -eq "FullServer")
                    {
                        Write-Verbose -Message "OS Version: Windows Server 2022"
                        $WindowsFeatures = Get-WindowsFeature -Name $Script:SPSEFeatures
                    }
                    elseif ($OSServerLevel -eq "ServerCore")
                    {
                        Write-Verbose -Message "OS Version: Windows Server 2022 Core"
                        $WindowsFeatures = Get-WindowsFeature -Name $Script:SPSEWinCoreFeatures
                    }
                }
                else
                {
                    $message = "SharePoint Server Subscription Edition only supports Windows Server 2019 or Windows Server 2022"
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $MyInvocation.MyCommand.Source
                    throw $message
                }
            }
            else
            {
                $message = "SharePoint Server Subscription Edition only supports Windows Server 2019 or Windows Server 2022"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
        }
    }

    $windowsFeaturesInstalled = $true
    foreach ($feature in $WindowsFeatures)
    {
        if ($feature.Installed -eq $false)
        {
            $windowsFeaturesInstalled = $false
            Write-Verbose -Message "Windows feature $($feature.Name) is not installed"
        }
    }

    Write-Verbose -Message "Checking windows packages from the registry"

    $x86Path = "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    $installedItemsX86 = Get-ItemProperty -Path $x86Path | Select-Object -Property DisplayName, BundleUpgradeCode, DisplayVersion

    $x64Path = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    $installedItemsX64 = Get-ItemProperty -Path $x64Path | Select-Object -Property DisplayName, BundleUpgradeCode, DisplayVersion

    $installedItems = $installedItemsX86 + $installedItemsX64 | Select-Object -Property DisplayName, BundleUpgradeCode, DisplayVersion -Unique

    #SP2013 prereqs
    if ($majorVersion -eq 15)
    {
        $prereqsToTest = @(
            [PSObject]@{
                Name        = "Active Directory Rights Management Services Client 2.*"
                SearchType  = "Like"
                SearchValue = "Active Directory Rights Management Services Client 2.*"
            },
            [PSObject]@{
                Name        = "AppFabric 1.1 for Windows Server"
                SearchType  = "Equals"
                SearchValue = "AppFabric 1.1 for Windows Server"
            },
            [PSObject]@{
                Name        = "Microsoft CCR and DSS Runtime 2008 R3"
                SearchType  = "Equals"
                SearchValue = "Microsoft CCR and DSS Runtime 2008 R3"
            },
            [PSObject]@{
                Name        = "Microsoft Identity Extensions"
                SearchType  = "Equals"
                SearchValue = "Microsoft Identity Extensions"
            },
            [PSObject]@{
                Name        = "Microsoft SQL Server Native Client (2008 R2 or 2012)"
                SearchType  = "Match"
                SearchValue = "SQL Server (2008 R2|2012) Native Client"
            },
            [PSObject]@{
                Name        = "Microsoft Sync Framework Runtime v1.0 SP1 (x64)"
                SearchType  = "Equals"
                SearchValue = "Microsoft Sync Framework Runtime v1.0 SP1 (x64)"
            },
            [PSObject]@{
                Name        = "WCF Data Services 5.0 (for OData v3) Primary Components"
                SearchType  = "Equals"
                SearchValue = "WCF Data Services 5.0 (for OData v3) Primary Components"
            },
            [PSObject]@{
                Name        = "WCF Data Services 5.6.0 Runtime"
                SearchType  = "Equals"
                SearchValue = "WCF Data Services 5.6.0 Runtime"
            }
        )
    }

    #SP2016/SP2019/SE prereqs
    if ($majorVersion -eq 16)
    {
        if ($buildVersion -lt 10000)
        {
            #SP2016 prereqs
            $prereqsToTest = @(
                [PSObject]@{
                    Name        = "Active Directory Rights Management Services Client 2.1"
                    SearchType  = "Equals"
                    SearchValue = "Active Directory Rights Management Services Client 2.1"
                },
                [PSObject]@{
                    Name        = "AppFabric 1.1 for Windows Server"
                    SearchType  = "Equals"
                    SearchValue = "AppFabric 1.1 for Windows Server"
                },
                [PSObject]@{
                    Name        = "Microsoft CCR and DSS Runtime 2008 R3"
                    SearchType  = "Equals"
                    SearchValue = "Microsoft CCR and DSS Runtime 2008 R3"
                },
                [PSObject]@{
                    Name        = "Microsoft Identity Extensions"
                    SearchType  = "Equals"
                    SearchValue = "Microsoft Identity Extensions"
                },
                [PSObject]@{
                    Name        = "Microsoft SQL Server 2012 Native Client"
                    SearchType  = "Equals"
                    SearchValue = "Microsoft SQL Server 2012 Native Client"
                },
                [PSObject]@{
                    Name        = "Microsoft Sync Framework Runtime v1.0 SP1 (x64)"
                    SearchType  = "Equals"
                    SearchValue = "Microsoft Sync Framework Runtime v1.0 SP1 (x64)"
                },
                [PSObject]@{
                    Name        = "Microsoft ODBC Driver 11 for SQL Server"
                    SearchType  = "Equals"
                    SearchValue = "Microsoft ODBC Driver 11 for SQL Server"
                },
                [PSObject]@{
                    Name        = "Microsoft Visual C++ 2012 x64 Minimum Runtime - 11.0"
                    SearchType  = "Like"
                    SearchValue = "Microsoft Visual C++ 2012 x64 Minimum Runtime - 11.0.*"
                },
                [PSObject]@{
                    Name        = "Microsoft Visual C++ 2012 x64 Additional Runtime - 11.0"
                    SearchType  = "Like"
                    SearchValue = "Microsoft Visual C++ 2012 x64 Additional Runtime - 11.0.*"
                },
                [PSObject]@{
                    Name                   = "Microsoft Visual C++ 2015 Redistributable (x64)"
                    SearchType             = "BundleUpgradeCode"
                    SearchValue            = "{C146EF48-4D31-3C3D-A2C5-1E91AF8A0A9B}"
                    MinimumRequiredVersion = "14.0.23026.0"
                },
                [PSObject]@{
                    Name        = "WCF Data Services 5.6.0 Runtime"
                    SearchType  = "Equals"
                    SearchValue = "WCF Data Services 5.6.0 Runtime"
                }
            )
        }
        elseif ($buildVersion -ge 10000 -and
            $buildVersion -le 12999)
        {
            #SP2019 prereqs
            $prereqsToTest = @(
                [PSObject]@{
                    Name        = "Active Directory Rights Management Services Client 2.1"
                    SearchType  = "Equals"
                    SearchValue = "Active Directory Rights Management Services Client 2.1"
                },
                [PSObject]@{
                    Name        = "AppFabric 1.1 for Windows Server"
                    SearchType  = "Equals"
                    SearchValue = "AppFabric 1.1 for Windows Server"
                },
                [PSObject]@{
                    Name        = "Microsoft CCR and DSS Runtime 2008 R3"
                    SearchType  = "Equals"
                    SearchValue = "Microsoft CCR and DSS Runtime 2008 R3"
                },
                [PSObject]@{
                    Name        = "Microsoft Identity Extensions"
                    SearchType  = "Equals"
                    SearchValue = "Microsoft Identity Extensions"
                },
                [PSObject]@{
                    Name        = "Microsoft SQL Server 2012 Native Client"
                    SearchType  = "Equals"
                    SearchValue = "Microsoft SQL Server 2012 Native Client"
                },
                [PSObject]@{
                    Name        = "Microsoft Sync Framework Runtime v1.0 SP1 (x64)"
                    SearchType  = "Equals"
                    SearchValue = "Microsoft Sync Framework Runtime v1.0 SP1 (x64)"
                },
                [PSObject]@{
                    Name                   = "Microsoft Visual C++ 2017 Redistributable (x64)"
                    SearchType             = "BundleUpgradeCode"
                    SearchValue            = "{C146EF48-4D31-3C3D-A2C5-1E91AF8A0A9B}"
                    MinimumRequiredVersion = "14.13.26020.0"
                },
                [PSObject]@{
                    Name        = "WCF Data Services 5.6.0 Runtime"
                    SearchType  = "Equals"
                    SearchValue = "WCF Data Services 5.6.0 Runtime"
                }
            )
        }
        elseif ($buildVersion -ge 13000)
        {
            #SharePoint Server Subscription Edition prereqs
            $prereqsToTest = @(
                [PSObject]@{
                    Name                   = "Microsoft Visual C++ 2015-2019 Redistributable (x64)"
                    SearchType             = "BundleUpgradeCode"
                    SearchValue            = "{C146EF48-4D31-3C3D-A2C5-1E91AF8A0A9B}"
                    MinimumRequiredVersion = "14.29.30133.0"
                }
            )
        }
    }
    $prereqsInstalled = Test-SPDscPrereqInstallStatus -InstalledItems $installedItems `
        -PrereqsToCheck $prereqsToTest

    $results = @{
        IsSingleInstance  = "Yes"
        InstallerPath     = $InstallerPath
        OnlineMode        = $OnlineMode
        SXSpath           = $SXSpath
        SQLNCli           = $SQLNCli
        PowerShell        = $PowerShell
        NETFX             = $NETFX
        IDFX              = $IDFX
        Sync              = $Sync
        AppFabric         = $AppFabric
        IDFX11            = $IDFX11
        MSIPCClient       = $MSIPCClient
        WCFDataServices   = $WCFDataServices
        KB2671763         = $KB2671763
        WCFDataServices56 = $WCFDataServices56
        MSVCRT11          = $MSVCRT11
        MSVCRT14          = $MSVCRT14
        MSVCRT141         = $MSVCRT141
        MSVCRT142         = $MSVCRT142
        KB3092423         = $KB3092423
        ODBC              = $ODBC
        DotNetFx          = $DotNetFx
        DotNet472         = $DotNet472
        DotNet48          = $DotNet48
    }

    if ($prereqsInstalled -eq $true -and $windowsFeaturesInstalled -eq $true)
    {
        $results.Ensure = "Present"
    }
    else
    {
        $results.Ensure = "Absent"
    }

    return $results
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
        $InstallerPath,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $OnlineMode,

        [Parameter()]
        [System.String]
        $SXSpath,

        [Parameter()]
        [System.String]
        $SQLNCli,

        [Parameter()]
        [System.String]
        $PowerShell,

        [Parameter()]
        [System.String]
        $NETFX,

        [Parameter()]
        [System.String]
        $IDFX,

        [Parameter()]
        [System.String]
        $Sync,

        [Parameter()]
        [System.String]
        $AppFabric,

        [Parameter()]
        [System.String]
        $IDFX11,

        [Parameter()]
        [System.String]
        $MSIPCClient,

        [Parameter()]
        [System.String]
        $WCFDataServices,

        [Parameter()]
        [System.String]
        $KB2671763,

        [Parameter()]
        [System.String]
        $WCFDataServices56,

        [Parameter()]
        [System.String]
        $MSVCRT11,

        [Parameter()]
        [System.String]
        $MSVCRT14,

        [Parameter()]
        [System.String]
        $MSVCRT141,

        [Parameter()]
        [System.String]
        $MSVCRT142,

        [Parameter()]
        [System.String]
        $KB3092423,

        [Parameter()]
        [System.String]
        $ODBC,

        [Parameter()]
        [System.String]
        $DotNetFx,

        [Parameter()]
        [System.String]
        $DotNet472,

        [Parameter()]
        [System.String]
        $DotNet48,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Setting installation status of SharePoint prerequisites"

    if ($Ensure -eq "Absent")
    {
        $message = ("SharePointDsc does not support uninstalling SharePoint or its " + `
                "prerequisites. Please remove this manually.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    Write-Verbose -Message "Check if InstallerPath folder exists"
    if (-not(Test-Path -Path $InstallerPath))
    {
        $message = "PrerequisitesInstaller cannot be found: {$InstallerPath}"
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    Write-Verbose -Message "Checking file status of $InstallerPath"
    $checkBlockedFile = $true
    if (Split-Path -Path $InstallerPath -IsAbsolute)
    {
        $driveLetter = (Split-Path -Path $InstallerPath -Qualifier).TrimEnd(":")
        Write-Verbose -Message "InstallerPath refers to drive $driveLetter"

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
            $message = ("PrerequisitesInstaller is blocked! Please use 'Unblock-File -Path " + `
                    "$InstallerPath' to unblock the file before continuing.")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }
        Write-Verbose -Message "File not blocked, continuing."
    }

    Write-Verbose -Message "Detecting SharePoint version from binaries"
    $majorVersion = Get-SPDscAssemblyVersion -PathToAssembly $InstallerPath
    $buildVersion = Get-SPDscBuildVersion -PathToAssembly $InstallerPath
    $osVersion = Get-SPDscOSVersion
    switch ($osVersion.Major)
    {
        6
        {
            switch ($osVersion.Minor)
            {
                0
                {
                    Write-Verbose -Message "Operating System: Windows Server 2008"
                }
                1
                {
                    Write-Verbose -Message "Operating System: Windows Server 2008 R2"
                }
                2
                {
                    Write-Verbose -Message "Operating System: Windows Server 2012"
                }
                3
                {
                    Write-Verbose -Message "Operating System: Windows Server 2012 R2"
                }
            }
        }
        10
        {
            if ($osVersion.Build -lt 17763)
            {
                Write-Verbose -Message "Operating System: Windows Server 2016"
            }
            elseif ($osVersion.Build -eq 17763)
            {
                Write-Verbose -Message "Operating System: Windows Server 2019"
            }
            else
            {
                Write-Verbose -Message "Operating System: Windows Server 2022"
            }
        }
    }

    if ($majorVersion -eq 15)
    {
        if ($osVersion.Major -ne 6)
        {
            $message = "SharePoint 2013 only supports Windows Server 2012 R2 and below"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }

        $BinaryDir = Split-Path -Path $InstallerPath
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
                $message = ("A known issue prevents installation of SharePoint 2013 on " + `
                        "servers that have .NET 4.6 already installed. See details " + `
                        "at https://support.microsoft.com/en-us/kb/3087184")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
        }

        Write-Verbose -Message "Version: SharePoint 2013"
        $requiredParams = @("SQLNCli", "PowerShell", "NETFX", "IDFX", "Sync", "AppFabric", "IDFX11",
            "MSIPCClient", "WCFDataServices", "KB2671763", "WCFDataServices56")
        $WindowsFeatures = Get-WindowsFeature -Name $Script:SP2013Features
    }
    elseif ($majorVersion -eq 16)
    {
        if ($buildVersion -lt 10000)
        {
            Write-Verbose -Message "Version: SharePoint 2016"
            $requiredParams = @("SQLNCli", "Sync", "AppFabric", "IDFX11", "MSIPCClient", "KB3092423",
                "WCFDataServices56", "DotNetFx", "MSVCRT11", "MSVCRT14", "ODBC")
            if ($osVersion.Major -eq 10)
            {
                if ($osVersion.Build -lt 17763)
                {
                    # Server 2016
                    $WindowsFeatures = Get-WindowsFeature -Name $Script:SP2016Win16Features
                }
                else
                {
                    # Server 2019
                    $WindowsFeatures = Get-WindowsFeature -Name $Script:SP2016Win19Features
                }
            }
            elseif ($osVersion.Major -eq 6 -and $osVersion.Minor -eq 3)
            {
                # Server 2012 R2
                $WindowsFeatures = Get-WindowsFeature -Name $Script:SP2016Win12r2Features
            }
            else
            {
                $message = "SharePoint 2016 only supports Windows Server 2016 or 2012 R2"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
        }
        # SharePoint 2019
        elseif ($buildVersion -ge 10000 -and
            $buildVersion -le 12999)
        {
            Write-Verbose -Message "Version: SharePoint 2019"
            $requiredParams = @("SQLNCli", "Sync", "AppFabric", "IDFX11", "MSIPCClient", "KB3092423",
                "WCFDataServices56", "DotNet472", "MSVCRT11", "MSVCRT141")

            if ($osVersion.Major -eq 10)
            {
                if ($osVersion.Build -lt 17763)
                {
                    # Server 2016
                    $WindowsFeatures = Get-WindowsFeature -Name $Script:SP2019Win16Features
                }
                else
                {
                    # Server 2019
                    $WindowsFeatures = Get-WindowsFeature -Name $Script:SP2019Win19Features
                }
            }
            else
            {
                $message = "SharePoint 2019 only supports Windows Server 2016 or Windows Server 2019"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
        }
        # SharePoint Server Subscription Edition
        elseif ($buildVersion -ge 13000)
        {
            Write-Verbose -Message "Version: SharePoint Server Subscription Edition"
            $requiredParams = @("DotNet48", "MSVCRT142")

            if ($osVersion.Major -eq 10)
            {
                if ($osVersion.Build -eq 17763)
                {
                    # Server 2019
                    $WindowsFeatures = Get-WindowsFeature -Name $Script:SPSEFeatures
                }
                elseif ($osVersion.Build -ge 20000)
                {
                    # Server 2022
                    $WindowsFeatures = Get-WindowsFeature -Name $Script:SPSEFeatures
                }
                else
                {
                    $message = "SharePoint Server Subscription Edition only supports Windows Server 2019 or Windows Server 2022"
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $MyInvocation.MyCommand.Source
                    throw $message
                }
            }
            else
            {
                $message = "SharePoint Server Subscription Edition only supports Windows Server 2019 or Windows Server 2022"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
        }
    }

    # SXSstore for feature install specified, we will manually install features from the
    # store, rather then relying on the prereq installer to download them
    if ($SXSpath)
    {
        Write-Verbose -Message "Getting installed windows features"
        foreach ($feature in $WindowsFeatures)
        {
            if ($feature.Installed -ne $true)
            {
                Write-Verbose "Installing $($feature.name)"
                $installResult = Install-WindowsFeature -Name $feature.Name -Source $SXSpath
                if ($installResult.restartneeded -eq "yes")
                {
                    $global:DSCMachineStatus = 1
                }
                if ($installResult.Success -ne $true)
                {
                    $message = "Error installing $($feature.name)"
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $MyInvocation.MyCommand.Source
                    throw $message
                }
            }
        }

        # see if we need to reboot after feature install
        if ($global:DSCMachineStatus -eq 1)
        {
            return
        }
    }

    $prereqArgs = "/unattended"
    if ($OnlineMode -eq $false)
    {
        $requiredParams | ForEach-Object -Process {
            if (($PSBoundParameters.ContainsKey($_) -eq $true `
                        -and [string]::IsNullOrEmpty($PSBoundParameters.$_)) `
                    -or (-not $PSBoundParameters.ContainsKey($_)))
            {
                $message = "In offline mode for version $majorVersion parameter $_ is required"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
            if ((Test-Path -Path $PSBoundParameters.$_) -eq $false)
            {
                $message = ("The $_ parameter has been passed but the file cannot be found at the " + `
                        "path supplied: `"$($PSBoundParameters.$_)`"")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
        }
        $requiredParams | ForEach-Object -Process {
            $prereqArgs += " /$_`:`"$($PSBoundParameters.$_)`""
        }
    }

    Write-Verbose -Message "Checking if Path is an UNC path"
    $uncInstall = $false
    if ($InstallerPath.StartsWith("\\"))
    {
        Write-Verbose -Message ("Specified InstallerPath is an UNC path. Adding servername to Local " +
            "Intranet Zone")

        $uncInstall = $true

        if ($InstallerPath -match "\\\\(.*?)\\.*")
        {
            $serverName = $Matches[1]
        }
        else
        {
            $message = "Cannot extract servername from UNC path. Check if it is in the correct format."
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }

        Set-SPDscZoneMap -Server $serverName
    }


    Write-Verbose -Message "Calling the SharePoint Pre-req installer"
    Write-Verbose -Message "Args for prereq installer are: $prereqArgs"
    $process = Start-Process -FilePath $InstallerPath -ArgumentList $prereqArgs -Wait -PassThru

    if ($uncInstall -eq $true)
    {
        Write-Verbose -Message "Removing added path from the Local Intranet Zone"
        Remove-SPDscZoneMap -ServerName $serverName
    }

    switch ($process.ExitCode)
    {
        0
        {
            Write-Verbose -Message "Prerequisite installer completed successfully."
        }
        1
        {
            $message = "Another instance of the prerequisite installer is already running"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }
        2
        {
            $message = "Invalid command line parameters passed to the prerequisite installer"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }
        1001
        {
            Write-Verbose -Message ("A pending restart is blocking the prerequisite " + `
                    "installer from running. Scheduling a reboot.")
            $global:DSCMachineStatus = 1
        }
        3010
        {
            Write-Verbose -Message ("The prerequisite installer has run correctly and needs " + `
                    "to reboot the machine before continuing.")
            $global:DSCMachineStatus = 1
        }
        default
        {
            $message = ("The prerequisite installer ran with the following unknown " + `
                    "exit code $($process.ExitCode)")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }
    }

    $rebootKey1 = "HKLM:\Software\Microsoft\Windows\CurrentVersion\" + `
        "Component Based Servicing\RebootPending"
    $rebootTest1 = Get-Item -Path $rebootKey1 -ErrorAction SilentlyContinue

    $rebootKey2 = "HKLM:\Software\Microsoft\Windows\CurrentVersion\WindowsUpdate\" + `
        "Auto Update\RebootRequired"
    $rebootTest2 = Get-Item -Path $rebootKey2 -ErrorAction SilentlyContinue

    $sessionManagerKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
    $sessionManager = Get-Item -Path $sessionManagerKey | Get-ItemProperty
    $pendingFileRenames = $sessionManager.PendingFileRenameOperations.Count

    if (($null -ne $rebootTest1) -or ($null -ne $rebootTest2) -or ($pendingFileRenames -gt 0))
    {
        Write-Verbose -Message ("SPInstallPrereqs has detected the server has pending a " + `
                "reboot. Flagging to the DSC engine that the server should " + `
                "reboot before continuing.")
        $global:DSCMachineStatus = 1
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
        $InstallerPath,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $OnlineMode,

        [Parameter()]
        [System.String]
        $SXSpath,

        [Parameter()]
        [System.String]
        $SQLNCli,

        [Parameter()]
        [System.String]
        $PowerShell,

        [Parameter()]
        [System.String]
        $NETFX,

        [Parameter()]
        [System.String]
        $IDFX,

        [Parameter()]
        [System.String]
        $Sync,

        [Parameter()]
        [System.String]
        $AppFabric,

        [Parameter()]
        [System.String]
        $IDFX11,

        [Parameter()]
        [System.String]
        $MSIPCClient,

        [Parameter()]
        [System.String]
        $WCFDataServices,

        [Parameter()]
        [System.String]
        $KB2671763,

        [Parameter()]
        [System.String]
        $WCFDataServices56,

        [Parameter()]
        [System.String]
        $MSVCRT11,

        [Parameter()]
        [System.String]
        $MSVCRT14,

        [Parameter()]
        [System.String]
        $MSVCRT141,

        [Parameter()]
        [System.String]
        $MSVCRT142,

        [Parameter()]
        [System.String]
        $KB3092423,

        [Parameter()]
        [System.String]
        $ODBC,

        [Parameter()]
        [System.String]
        $DotNetFx,

        [Parameter()]
        [System.String]
        $DotNet472,

        [Parameter()]
        [System.String]
        $DotNet48,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Testing installation status of SharePoint prerequisites"

    $PSBoundParameters.Ensure = $Ensure

    if ($Ensure -eq "Absent")
    {
        $message = ("SharePointDsc does not support uninstalling SharePoint or its " + `
                "prerequisites. Please remove this manually.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
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

function Test-SPDscPrereqInstallStatus
{
    param
    (
        [Parameter()]
        [Object]
        $InstalledItems,

        [Parameter(Mandatory = $true)]
        [psobject[]]
        $PrereqsToCheck
    )

    if ($null -eq $InstalledItems)
    {
        return $false
    }

    $itemsInstalled = $true
    $PrereqsToCheck | ForEach-Object -Process {
        $itemToCheck = $_
        switch ($itemToCheck.SearchType)
        {
            "Equals"
            {
                $prereq = $InstalledItems | Where-Object -FilterScript {
                    $null -ne $_.DisplayName -and $_.DisplayName.Trim() -eq $itemToCheck.SearchValue
                }
                if ($null -eq $prereq)
                {
                    $itemsInstalled = $false
                    Write-Verbose -Message ("Prerequisite $($itemToCheck.Name) was not found " + `
                            "on this system")
                }
            }
            "Match"
            {
                $prereq = $InstalledItems | Where-Object -FilterScript {
                    $null -ne $_.DisplayName -and $_.DisplayName.Trim() -match $itemToCheck.SearchValue
                }
                if ($null -eq $prereq)
                {
                    $itemsInstalled = $false
                    Write-Verbose -Message ("Prerequisite $($itemToCheck.Name) was not found " + `
                            "on this system")
                }
            }
            "Like"
            {
                $prereq = $InstalledItems | Where-Object -FilterScript {
                    $null -ne $_.DisplayName -and $_.DisplayName.Trim() -like $itemToCheck.SearchValue
                }
                if ($null -eq $prereq)
                {
                    $itemsInstalled = $false
                    Write-Verbose -Message ("Prerequisite $($itemToCheck.Name) was not found " + `
                            "on this system")
                }
            }
            "BundleUpgradeCode"
            {
                $installedItem = $InstalledItems | Where-Object -FilterScript {
                    $null -ne $_.BundleUpgradeCode -and ($null -eq ($_.BundleUpgradeCode.Trim() | Compare-Object $itemToCheck.SearchValue))
                }
                if ($null -eq $installedItem)
                {
                    $itemsInstalled = $false
                    Write-Verbose -Message ("Prerequisite $($itemToCheck.Name) was not found " + `
                            "on this system")
                }
                else
                {
                    # Fix to prevent multiple items being returned when two items have the same BundleUpgradeCode
                    # This sometimes happens when the VC++ isn't upgraded properly.
                    if ($installedItem.Count -gt 1)
                    {
                        $installedItem = $installedItem | Sort-Object -Property DisplayVersion | Select-Object -Last 1
                    }

                    $isRequiredVersionInstalled = $true;

                    [System.Version]$minimumRequiredVersion = $itemToCheck.MinimumRequiredVersion
                    [System.Version]$installedVersion = $installedItem.DisplayVersion
                    if ($minimumRequiredVersion -gt $installedVersion)
                    {
                        $isRequiredVersionInstalled = $false;
                    }
                    if ($installedVersion.Length -eq 0 -or -not $isRequiredVersionInstalled)
                    {
                        $itemsInstalled = $false
                        Write-Verbose -Message ("Prerequisite $($itemToCheck.Name) was found but had " + `
                                "unexpected version. Expected minimum version $($itemToCheck.MinimumVersion) " + `
                                "but found version $($installedItem.DisplayVersion).")
                    }
                }
            }
            Default
            {
                $message = ("Unable to search for a prereq with mode '$($itemToCheck.SearchType)'. " + `
                        "please use either 'Equals', 'Like' or 'Match', or 'BundleUpgradeCode'")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
        }
    }
    return $itemsInstalled
}

function Export-TargetResource
{
    param
    (
        [Parameter()]
        [System.String]
        $BinaryLocation = "\\<location>"
    )

    $VerbosePreference = "SilentlyContinue"
    if ($DynamicCompilation)
    {
        Add-ConfigurationDataEntry -Node "NonNodeData" -Key "FullInstallation" -Value "`$True" -Description "Specifies whether or not the DSC configuration script will install the SharePoint Prerequisites and Binaries;"
    }
    else
    {
        Add-ConfigurationDataEntry -Node "NonNodeData" -Key "FullInstallation" -Value "`$False" -Description "Specifies whether or not the DSC configuration script will install the SharePoint Prerequisites and Binaries;"
    }
    $Content = "        if (`$ConfigurationData.NonNodeData.FullInstallation)`r`n"
    $Content += "        {`r`n"
    $Content += "            SPInstallPrereqs PrerequisitesInstallation" + "`r`n            {`r`n"
    if ([System.String]::IsNullOrEmpty($BinaryLocation))
    {
        $BinaryLocation = "\\<location>"
    }
    Add-ConfigurationDataEntry -Node "NonNodeData" -Key "SPPrereqsInstallerPath" -Value $BinaryLocation -Description "Location of the SharePoint Prerequisites Installer .exe (Local path or Network Share);"
    $Content += "                InstallerPath = `$ConfigurationData.NonNodeData.SPPrereqsInstallerPath;`r`n"
    $Content += "                OnlineMode = `$True;`r`n"
    $Content += "                Ensure = `"Present`";`r`n"
    $Content += "                IsSingleInstance = `"Yes`";`r`n"
    $Content += "                PSDscRunAsCredential = `$Creds" + ($Global:spFarmAccount.Username.Split('\'))[1].Replace("-", "_").Replace(".", "_") + ";`r`n"

    $Content += "            }`r`n"
    $Content += "        }`r`n"
    return $Content
}

Export-ModuleMember -Function *-TargetResource
