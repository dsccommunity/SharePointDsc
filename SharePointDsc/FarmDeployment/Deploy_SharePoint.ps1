### NOTE: This script hasn't been fully tested yet. We are in the process of doing that.
###       But wanted to share it anyways, so it can be used as an example by others.

##### GENERIC VARIABLES #####
$buildingBlockVersion = [System.Version]'1.0.0'

##### DSC CONFIGURATION #####
Configuration Deploy_SP
{
    param
    (
        [Parameter(Mandatory = $true)] [ValidateNotNullorEmpty()] [PSCredential[]] $Credentials,
        [Parameter(Mandatory = $true)] [ValidateNotNullorEmpty()] [PSCredential] $InstallAccount,
        [Parameter(Mandatory = $true)] [ValidateNotNullorEmpty()] [PSCredential] $PassPhrase,
        [Parameter(Mandatory = $true)] [ValidateNotNullorEmpty()] [PSCredential] $CertificatePassword
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName SharePointDsc
    Import-DscResource -ModuleName CertificateDsc
    Import-DscResource -ModuleName xWebAdministration
    Import-DscResource -ModuleName xCredSSP
    Import-DscResource -ModuleName ComputerManagementDsc

    # Determine SharePoint Frontend and Backend servers based on Subrole property
    $spServers = ($AllNodes | Where-Object { $_.Role -eq "SharePoint" }).NodeName
    $feServers = ($AllNodes | Where-Object { $_.Role -eq "SharePoint" -and $_.Subrole -contains "SPFE" } ).NodeName
    $beServers = ($AllNodes | Where-Object { $_.Role -eq "SharePoint" -and $_.Subrole -contains "SPBE" }).NodeName
    $firstBEServer = $beServers | Select-Object -First 1

    # Determine SharePoint Search servers based on Subrole property
    $searchServers = ($AllNodes | Where-Object { $_.Role -eq "SharePoint" -and ($_.Subrole -contains "SearchBE" -or $_.Subrole -contains "SearchFE") } ).NodeName
    $searchFEServers = ($AllNodes | Where-Object { $_.Role -eq "SharePoint" -and $_.Subrole -contains "SearchFE" } ).NodeName
    $searchBEServers = ($AllNodes | Where-Object { $_.Role -eq "SharePoint" -and $_.Subrole -contains "SearchBE" } ).NodeName
    $firstSearchBEServer = $searchBEServers | Select-Object -First 1

    # Define install folders
    $installFolder = $ConfigurationData.NonNodeData.InstallPaths.InstallFolder
    $installSPFolder = Join-Path -Path $installFolder -ChildPath "SharePoint"
    $installSPBinFolder = Join-Path -Path $installSPFolder -ChildPath "Install"
    $installSPPrereqFolder = Join-Path -Path $installSPBinFolder -ChildPath "prerequisiteinstallerfiles"
    $installSPLPFolder = Join-Path -Path $installSPFolder -ChildPath "LanguagePackNL"
    $installSPCUFolder = Join-Path -Path $installSPFolder -ChildPath "CU"

    node $AllNodes.NodeName
    {
        #region SharePoint servers
        if ($spServers -contains $Node.NodeName)
        {
            Group 'FarmAccountPerformanceMonitorUsersGroup'
            {
                GroupName        = 'Performance Monitor Users'
                MembersToInclude = @($ConfigurationData.NonNodeData.ManagedAccounts.Farm, `
                        $ConfigurationData.NonNodeData.ManagedAccounts.AppPool, `
                        $ConfigurationData.NonNodeData.ManagedAccounts.Services)
                Ensure           = 'Present'
            }

            # Disable SSL 2.0, SSL 3.0, TLS 1.0 en TLS 1.1: Only TLS 1.2 is allowed. More info:
            # - https://docs.microsoft.com/en-us/windows/desktop/secauthn/protocols-in-tls-ssl--schannel-ssp-
            # - https://docs.microsoft.com/en-us/sharepoint/security-for-sharepoint-server/enable-tls-1-1-and-tls-1-2-support-in-sharepoint-server-2019
            Registry 'SSL2_Client_ConfigureEnabled'
            {
                Ensure    = 'Present'
                Key       = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\Schannel\Protocols\SSL 2.0\Client'
                ValueName = 'Enabled'
                ValueData = '0'
                ValueType = 'Dword'
            }


            Registry 'SSL2_Client_ConfigureDisabledByDefault'
            {
                Ensure    = 'Present'
                Key       = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\Schannel\Protocols\SSL 2.0\Client'
                ValueName = 'DisabledByDefault'
                ValueData = '1'
                ValueType = 'Dword'
            }

            Registry 'SSL3_Client_ConfigureEnabled'
            {
                Ensure    = 'Present'
                Key       = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\Schannel\Protocols\SSL 3.0\Client'
                ValueName = 'Enabled'
                ValueData = '0'
                ValueType = 'Dword'
            }

            Registry 'SSL3_Client_ConfigureDisabledByDefault'
            {
                Ensure    = 'Present'
                Key       = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\Schannel\Protocols\SSL 3.0\Client'
                ValueName = 'DisabledByDefault'
                ValueData = '1'
                ValueType = 'Dword'
            }

            Registry 'TLS1.0_Client_ConfigureEnabled'
            {
                Ensure    = 'Present'
                Key       = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\Schannel\Protocols\TLS 1.0\Client'
                ValueName = 'Enabled'
                ValueData = '0'
                ValueType = 'Dword'
            }

            Registry 'TLS1.0_Client_ConfigureDisabledByDefault'
            {
                Ensure    = 'Present'
                Key       = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\Schannel\Protocols\TLS 1.0\Client'
                ValueName = 'DisabledByDefault'
                ValueData = '1'
                ValueType = 'Dword'
            }

            Registry 'TLS1.1_Client_ConfigureEnabled'
            {
                Ensure    = 'Present'
                Key       = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\Schannel\Protocols\TLS 1.1\Client'
                ValueName = 'Enabled'
                ValueData = '0'
                ValueType = 'Dword'
            }

            Registry 'TLS1.1_Client_ConfigureDisabledByDefault'
            {
                Ensure    = 'Present'
                Key       = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\Schannel\Protocols\TLS 1.1\Client'
                ValueName = 'DisabledByDefault'
                ValueData = '1'
                ValueType = 'Dword'
            }

            Registry 'TLS1.2_Client_ConfigureEnabled'
            {
                Ensure    = 'Present'
                Key       = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\Schannel\Protocols\TLS 1.2\Client'
                ValueName = 'Enabled'
                ValueData = '1'
                ValueType = 'Dword'
            }

            Registry 'TLS1.2_Client_ConfigureDisabledByDefault'
            {
                Ensure    = 'Present'
                Key       = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\Schannel\Protocols\TLS 1.2\Client'
                ValueName = 'DisabledByDefault'
                ValueData = '0'
                ValueType = 'Dword'
            }

            Registry 'SSL2_Server_ConfigureEnabled'
            {
                Ensure    = 'Present'
                Key       = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\Schannel\Protocols\SSL 2.0\Server'
                ValueName = 'Enabled'
                ValueData = '0'
                ValueType = 'Dword'
            }

            Registry 'SSL2_Server_ConfigureDisabledByDefault'
            {
                Ensure    = 'Present'
                Key       = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\Schannel\Protocols\SSL 2.0\Server'
                ValueName = 'DisabledByDefault'
                ValueData = '1'
                ValueType = 'Dword'
            }

            Registry 'SSL3_Server_ConfigureEnabled'
            {
                Ensure    = 'Present'
                Key       = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\Schannel\Protocols\SSL 3.0\Server'
                ValueName = 'Enabled'
                ValueData = '0'
                ValueType = 'Dword'
            }

            Registry 'SSL3_Server_ConfigureDisabledByDefault'
            {
                Ensure    = 'Present'
                Key       = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\Schannel\Protocols\SSL 3.0\Server'
                ValueName = 'DisabledByDefault'
                ValueData = '1'
                ValueType = 'Dword'
            }

            Registry 'TLS1.0_Server_ConfigureEnabled'
            {
                Ensure    = 'Present'
                Key       = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\Schannel\Protocols\TLS 1.0\Server'
                ValueName = 'Enabled'
                ValueData = '0'
                ValueType = 'Dword'
            }

            Registry 'TLS1.0_Server_ConfigureDisabledByDefault'
            {
                Ensure    = 'Present'
                Key       = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\Schannel\Protocols\TLS 1.0\Server'
                ValueName = 'DisabledByDefault'
                ValueData = '1'
                ValueType = 'Dword'
            }

            Registry 'TLS1.1_Server_ConfigureEnabled'
            {
                Ensure    = 'Present'
                Key       = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\Schannel\Protocols\TLS 1.1\Server'
                ValueName = 'Enabled'
                ValueData = '0'
                ValueType = 'Dword'
            }

            Registry 'TLS1.1_Server_ConfigureDisabledByDefault'
            {
                Ensure    = 'Present'
                Key       = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\Schannel\Protocols\TLS 1.1\Server'
                ValueName = 'DisabledByDefault'
                ValueData = '1'
                ValueType = 'Dword'
            }

            Registry 'TLS1.2_Server_ConfigureEnabled'
            {
                Ensure    = 'Present'
                Key       = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\Schannel\Protocols\TLS 1.2\Server'
                ValueName = 'Enabled'
                ValueData = '1'
                ValueType = 'Dword'
            }

            Registry 'TLS1.2_Server_ConfigureDisabledByDefault'
            {
                Ensure    = 'Present'
                Key       = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\Schannel\Protocols\TLS 1.2\Server'
                ValueName = 'DisabledByDefault'
                ValueData = '0'
                ValueType = 'Dword'
            }

            # https://docs.microsoft.com/en-us/officeonlineserver/enable-tls-1-1-and-tls-1-2-support-in-office-online-server
            Registry 'Enable_Strong_Crypto_NET_64'
            {
                Ensure    = 'Present'
                Key       = 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319'
                ValueName = 'SchUseStrongCrypto'
                ValueData = '1'
                ValueType = 'Dword'
            }

            Registry 'Enable_Strong_Crypto_NET_32'
            {
                Ensure    = 'Present'
                Key       = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319'
                ValueName = 'SchUseStrongCrypto'
                ValueData = '1'
                ValueType = 'Dword'
            }

            # Gebaseerd op https://docs.microsoft.com/en-us/windows/desktop/secauthn/tls-cipher-suites-in-windows-10-v1607
            Registry 'ConfigureAllowedCipherSuites'
            {
                Ensure    = 'Present'
                Key       = 'HKLM:\SOFTWARE\Policies\Microsoft\Cryptography\Configuration\SSL\00010002'
                ValueName = 'Functions'
                ValueData = 'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_DHE_RSA_WITH_AES_256_GCM_SHA384,TLS_DHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384,TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256,TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA,TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA,TLS_DHE_RSA_WITH_AES_256_CBC_SHA,TLS_DHE_RSA_WITH_AES_128_CBC_SHA,TLS_RSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_128_GCM_SHA256,TLS_RSA_WITH_AES_256_CBC_SHA256,TLS_RSA_WITH_AES_128_CBC_SHA256,TLS_RSA_WITH_AES_256_CBC_SHA,TLS_RSA_WITH_AES_128_CBC_SHA,TLS_RSA_WITH_3DES_EDE_CBC_SHA,TLS_DHE_DSS_WITH_AES_256_CBC_SHA256,TLS_DHE_DSS_WITH_AES_128_CBC_SHA256,TLS_DHE_DSS_WITH_AES_256_CBC_SHA,TLS_DHE_DSS_WITH_AES_128_CBC_SHA,TLS_DHE_DSS_WITH_3DES_EDE_CBC_SHA,TLS_PSK_WITH_AES_256_GCM_SHA384,TLS_PSK_WITH_AES_128_GCM_SHA256,TLS_PSK_WITH_AES_256_CBC_SHA384,TLS_PSK_WITH_AES_128_CBC_SHA256'
                ValueType = 'String'
            }

            # Moet uit staan: https://docs.microsoft.com/en-us/sharepoint/security-for-sharepoint-server/federal-information-processing-standard-security-standards
            Registry 'DisableFIPSAlgorithmPolicy'
            {
                Ensure    = 'Present'
                Key       = 'HKLM:\System\CurrentControlSet\Control\Lsa\FIPSAlgorithmPolicy'
                ValueName = 'Enabled'
                ValueData = '0'
                ValueType = 'Dword'
            }

            Registry 'DisableLoopBackCheck'
            {
                Ensure    = 'Present'
                Key       = 'HKLM:\System\CurrentControlSet\Control\Lsa'
                ValueName = 'DisableLoopbackCheck'
                ValueData = '1'
                ValueType = 'Dword'
            }

            xCredSSP 'Server'
            {
                Ensure = 'Present'
                Role   = 'Server'
            }

            xCredSSP 'Client'
            {
                Ensure            = 'Present'
                Role              = 'Client'
                DelegateComputers = @("$($Node.NodeName)", "$($Node.NodeName).$($ConfigurationData.NonNodeData.DomainDetails.DomainName)")
            }


            File 'IISLogFolder'
            {
                DestinationPath = $ConfigurationData.NonNodeData.Logging.IISLogPath
                Type            = 'Directory'
                Ensure          = 'Present'

            }

            File 'UsageLogFolder'
            {
                DestinationPath = $ConfigurationData.NonNodeData.Logging.UsageLogPath
                Type            = 'Directory'
                Ensure          = 'Present'

            }

            if ($feServers -contains $Node.NodeName -or $beServers -contains $Node.NodeName)
            {
                PfxImport 'SSL_Portal_Contoso_local'
                {
                    Thumbprint = $ConfigurationData.NonNodeData.Certificates.Portal.Thumbprint.ToUpper()
                    Path       = (Join-Path -Path $ConfigurationData.NonNodeData.InstallPaths.CertificatesFolder -ChildPath $ConfigurationData.NonNodeData.Certificates.Portal.File)
                    Location   = 'LocalMachine'
                    Store      = 'My'
                    Credential = $CertificatePassword
                }
            }

            if ($feServers -contains $Node.NodeName -and
                $ConfigurationData.NonNodeData.SharePoint.ProvisionApps -eq $true)
            {
                PfxImport 'SSL_Portal_ContosoApps_local'
                {
                    Thumbprint = $ConfigurationData.NonNodeData.Certificates.PortalApps.Thumbprint.ToUpper()
                    Path       = (Join-Path -Path $ConfigurationData.NonNodeData.InstallPaths.CertificatesFolder -ChildPath $ConfigurationData.NonNodeData.Certificates.PortalApps.File)
                    Location   = 'LocalMachine'
                    Store      = 'My'
                    Credential = $CertificatePassword
                }
            }

            # Required to resolve a bug in the Prereqs installer, which does accepts an incorrect version
            # of the Visual C++ 2017 library: https://support.microsoft.com/en-us/help/2977003/the-latest-supported-visual-c-downloads
            # More info: https://docs.microsoft.com/en-us/sharepoint/troubleshoot/installation-and-setup/sharepoint-server-setup-fails
            Package 'Install_VC2017ReDistx64'
            {
                Name       = 'Microsoft Visual C++ 2015-2019 Redistributable (x64) - 14.24.28127'
                Path       = (Join-Path -Path $installSPPrereqFolder -ChildPath 'vc_redist.x64.exe')
                Arguments  = '/quiet /norestart'
                ProductId  = '282975d8-55fe-4991-bbbb-06a72581ce58'
                Ensure     = 'Present'
                Credential = $InstallAccount
            }

            SPInstallPrereqs 'Install_SP_Prereqs'
            {
                IsSingleInstance     = 'Yes'
                InstallerPath        = (Join-Path -Path $installSPBinFolder -ChildPath 'prerequisiteinstaller.exe')
                OnlineMode           = $false
                AppFabric            = (Join-Path -Path $installSPPrereqFolder -ChildPath 'WindowsServerAppFabricSetup_x64.exe')
                DotNetFX             = (Join-Path -Path $installSPPrereqFolder -ChildPath 'dotNetFx45_Full_setup.exe')
                DotNet472            = (Join-Path -Path $installSPPrereqFolder -ChildPath 'NDP472-KB4054530-x86-x64-AllOS-ENU.exe')
                KB3092423            = (Join-Path -Path $installSPPrereqFolder -ChildPath 'AppFabric-KB3092423-x64-ENU.exe')
                IDFX11               = (Join-Path -Path $installSPPrereqFolder -ChildPath 'MicrosoftIdentityExtensions-64.msi')
                MSIPCClient          = (Join-Path -Path $installSPPrereqFolder -ChildPath 'setup_msipc_x64.exe')
                MSVCRT11             = (Join-Path -Path $installSPPrereqFolder -ChildPath 'vcredist_x64.exe')
                MSVCRT141            = (Join-Path -Path $installSPPrereqFolder -ChildPath 'vc_redist.x64.exe')
                SQLNCli              = (Join-Path -Path $installSPPrereqFolder -ChildPath 'sqlncli.msi')
                Sync                 = (Join-Path -Path $installSPPrereqFolder -ChildPath 'Synchronization.msi')
                WCFDataServices56    = (Join-Path -Path $installSPPrereqFolder -ChildPath 'WcfDataServices.exe')
                Ensure               = 'Present'
                PSDscRunAsCredential = $InstallAccount
                DependsOn            = '[Package]Install_VC2017ReDistx64'
            }

            SPInstall 'Install_SharePoint'
            {
                IsSingleInstance     = 'Yes'
                BinaryDir            = $installSPBinFolder
                ProductKey           = $ConfigurationData.NonNodeData.SharePoint.ProductKey
                InstallPath          = $ConfigurationData.NonNodeData.SharePoint.InstallPath
                DataPath             = $ConfigurationData.NonNodeData.SharePoint.DataPath
                PSDscRunAsCredential = $InstallAccount
                DependsOn            = '[SPInstallPrereqs]Install_SP_Prereqs'
            }

<# Commented out to prevent LP to be installed. Update if you need to install LP.
            SPInstallLanguagePack 'Install_NL_LP_Binaries'
            {
                BinaryDir            = $installSPLPFolder
                Ensure               = 'Present'
                PSDscRunAsCredential = $InstallAccount
                DependsOn            = '[SPInstall]Install_SharePoint'
            }
#>

            SPProductUpdate 'LanguageDependant_CU'
            {
                SetupFile            = (Join-Path -Path $installSPCUFolder -ChildPath $ConfigurationData.NonNodeData.SharePoint.CULangFileName)
                ShutdownServices     = $false
                Ensure               = 'Present'
                PSDscRunAsCredential = $InstallAccount
                DependsOn            = '[SPInstall]Install_SharePoint'
            }

            SPProductUpdate 'Language_Independant_CU'
            {
                SetupFile            = (Join-Path -Path $installSPCUFolder -ChildPath $ConfigurationData.NonNodeData.SharePoint.CUFileName)
                ShutdownServices     = $false
                Ensure               = 'Present'
                PSDscRunAsCredential = $InstallAccount
                DependsOn            = '[SPProductUpdate]LanguageDependant_CU'
            }

            # Determine MinRole based on Subrole property
            $wfe = $false
            $be = $false
            $search = $false
            switch ($Node.Subrole)
            {
                'SPFE' { $wfe = $true }
                'SPBE' { $be = $true }
                { $_ -in ('SearchFE', 'SearchBE') } { $search = $true }
            }

            if ($wfe -eq $true -and $be -eq $false -and $search -eq $false)
            {
                $minRole = 'WebFrontEndWithDistributedCache'
            }
            elseif ($wfe -eq $false -and $be -eq $true -and $search -eq $false)
            {
                $minRole = 'Application'
            }
            elseif ($wfe -eq $false -and $be -eq $false -and $search -eq $true)
            {
                $minRole = 'Search'
            }
            elseif ($wfe -eq $false -and $be -eq $true -and $search -eq $true)
            {
                $minRole = 'ApplicationWithSearch'
            }
            elseif ($wfe -eq $true -and $be -eq $true -and $search -eq $true)
            {
                $minRole = 'SingleServerFarm'
            }

            $farmAccount = $Credentials | Where-Object { $_.UserName -eq $ConfigurationData.NonNodeData.ManagedAccounts.Farm }
            if ($beServers -contains $Node.NodeName)
            {
                # All Back-end servers have to run the Central Admin
                $runCentralAdmin = $true

            }
            else
            {
                # All other servers won't run the Central Admin
                $runCentralAdmin = $false
            }

            if ($Node.NodeName -eq $firstBEServer)
            {
                $depends = '[SPProductUpdate]Language_Independant_CU'
            }
            else
            {
                WaitForAll 'WaitForFirstBEServerToComplete'
                {
                    ResourceName     = '[SPFeature]DisableMySite'
                    NodeName         = $firstBEServer
                    RetryIntervalSec = 60
                    RetryCount       = 120
                    DependsOn        = '[SPProductUpdate]Language_Independant_CU'
                }
                $depends = '[WaitForAll]WaitForFirstBEServerToComplete'
            }

            SPFarm 'SharePointFarmConfig'
            {
                IsSingleInstance          = 'Yes'
                DatabaseServer            = $ConfigurationData.NonNodeData.DomainDetails.DBServerInfr
                FarmConfigDatabaseName    = $ConfigurationData.NonNodeData.FarmConfig.ConfigDBName
                AdminContentDatabaseName  = $ConfigurationData.NonNodeData.FarmConfig.AdminContentDBName
                Passphrase                = $Passphrase
                FarmAccount               = $farmAccount
                RunCentralAdmin           = $runCentralAdmin
                CentralAdministrationPort = 443
                PsDscRunAsCredential      = $InstallAccount
                DependsOn                 = '[SPProductUpdate]Language_Independant_CU'
                ServerRole                = $minRole
            }

            SPConfigWizard "RunConfigWizard"
            {
                IsSingleInstance     = 'Yes'
                PsDscRunAsCredential = $InstallAccount
                DependsOn            = '[SPFarm]SharePointFarmConfig'
            }

            $SharePointAdminsADGroup = $ConfigurationData.NonNodeData.DomainDetails.NetBIOSName + "\" + $ConfigurationData.NonNodeData.ActiveDirectory.SPAdmins.Name

            # Configure Farm on the first Back-End server
            if ($Node.NodeName -eq $firstBEServer)
            {
                SPAlternateUrl "CentralAdminAAM"
                {
                    WebAppName           = $ConfigurationData.NonNodeData.CentralAdminSite.WebAppName
                    Zone                 = "Default"
                    Url                  = ("https://" + $ConfigurationData.NonNodeData.CentralAdminSite.SiteURL)
                    Ensure               = "Present"
                    Internal             = $false
                    PsDscRunAsCredential = $InstallAccount
                    DependsOn            = '[SPFarm]SharePointFarmConfig'
                }

                xWebsite "Website"
                {
                    Name            = $ConfigurationData.NonNodeData.CentralAdminSite.WebAppName
                    ApplicationPool = $ConfigurationData.NonNodeData.CentralAdminSite.AppPool
                    BindingInfo     = @(
                        MSFT_xWebBindingInformation
                        {
                            Protocol              = 'HTTPS'
                            Port                  = '443'
                            CertificateThumbprint = $ConfigurationData.NonNodeData.Certificates.$($ConfigurationData.NonNodeData.CentralAdminSite.Certificate).Thumbprint.ToUpper()
                            CertificateStoreName  = 'My'
                            IPAddress             = '*'
                            Hostname              = $ConfigurationData.NonNodeData.CentralAdminSite.SiteURL
                        }
                    )
                    DependsOn       = '[SPFarm]SharePointFarmConfig'
                }

                $farmAdmins = @()
                $farmAdmins += $SharePointAdminsADGroup                                # SharePoint Admins AD Group
                $farmAdmins += $ConfigurationData.NonNodeData.ManagedAccounts.Farm     # SharePoint Farm account

                SPFarmAdministrators 'FarmAdmins'
                {
                    IsSingleInstance     = 'Yes'
                    Members              = $farmAdmins
                    PsDscRunAsCredential = $InstallAccount
                    DependsOn            = '[SPFarm]SharePointFarmConfig'
                }

                SPShellAdmins 'ShellAdmins'
                {
                    IsSingleInstance     = 'Yes'
                    Members              = $SharePointAdminsADGroup
                    AllDatabases         = $true
                    PsDscRunAsCredential = $InstallAccount
                    DependsOn            = '[SPFarm]SharePointFarmConfig'
                }

                SPDiagnosticLoggingSettings 'ApplyDiagnosticLogSettings'
                {
                    IsSingleInstance                            = 'Yes'
                    LogPath                                     = $ConfigurationData.NonNodeData.Logging.ULSLogPath
                    LogSpaceInGB                                = $ConfigurationData.NonNodeData.Logging.ULSMaxSizeInGB
                    AppAnalyticsAutomaticUploadEnabled          = $false
                    CustomerExperienceImprovementProgramEnabled = $false
                    DaysToKeepLogs                              = $ConfigurationData.NonNodeData.Logging.ULSDaysToKeep
                    DownloadErrorReportingUpdatesEnabled        = $false
                    ErrorReportingAutomaticUploadEnabled        = $false
                    ErrorReportingEnabled                       = $false
                    EventLogFloodProtectionEnabled              = $true
                    EventLogFloodProtectionNotifyInterval       = 5
                    EventLogFloodProtectionQuietPeriod          = 2
                    EventLogFloodProtectionThreshold            = 5
                    EventLogFloodProtectionTriggerPeriod        = 2
                    LogCutInterval                              = 15
                    LogMaxDiskSpaceUsageEnabled                 = $true
                    ScriptErrorReportingDelay                   = 30
                    ScriptErrorReportingEnabled                 = $true
                    ScriptErrorReportingRequireAuth             = $true
                    PsDscRunAsCredential                        = $InstallAccount
                    DependsOn                                   = '[SPFarm]SharePointFarmConfig'
                }

                SPOutgoingEmailSettings FarmWideEmailSettings
                {
                    WebAppUrl            = ("https://" + $ConfigurationData.NonNodeData.CentralAdminSite.SiteURL)
                    SMTPServer           = $ConfigurationData.NonNodeData.FarmConfig.OutgoingEmail.SMTPServer
                    FromAddress          = $ConfigurationData.NonNodeData.FarmConfig.OutgoingEmail.From
                    ReplyToAddress       = $ConfigurationData.NonNodeData.FarmConfig.OutgoingEmail.ReplyTo
                    UseTLS               = $ConfigurationData.NonNodeData.FarmConfig.OutgoingEmail.UseTLS
                    SMTPPort             = $ConfigurationData.NonNodeData.FarmConfig.OutgoingEmail.Port
                    CharacterSet         = "65001"
                    PsDscRunAsCredential = $InstallAccount
                    DependsOn            = '[SPFarm]SharePointFarmConfig'
                }

                SPQuotaTemplate "Default_500MB_Quota"
                {
                    Name                 = "500MB"
                    StorageMaxInMB       = 500
                    StorageWarningInMB   = 450
                    Ensure               = "Present"
                    PsDscRunAsCredential = $InstallAccount
                    DependsOn            = '[SPFarm]SharePointFarmConfig'
                }

                $processedAccounts = @()
                $day = $ConfigurationData.NonNodeData.FarmConfig.PasswordChangeSchedule.Day
                $hour = $ConfigurationData.NonNodeData.FarmConfig.PasswordChangeSchedule.Hour.ToString("00")
                $pwChangeSchedule = "monthly at first $day $($hour):00:00"
                foreach ($managedaccount in $ConfigurationData.NonNodeData.ManagedAccounts.GetEnumerator())
                {
                    if (-not $processedAccounts.Contains($managedaccount.Value))
                    {
                        $credential = $Credentials | Where-Object { $_.UserName -eq $managedaccount.Value }
                        SPManagedAccount $credential.UserName
                        {
                            AccountName          = $credential.UserName
                            Account              = $credential
                            PreExpireDays        = 2
                            Schedule             = $pwChangeSchedule
                            PsDscRunAsCredential = $InstallAccount
                            DependsOn            = '[SPFarm]SharePointFarmConfig'
                        }
                        $processedAccounts += $managedaccount.Value
                    }
                }

                SPServiceAppPool "ServiceAppPool_Services"
                {
                    Name                 = $ConfigurationData.NonNodeData.ApplicationPools.ServiceApplicationPools.Name
                    ServiceAccount       = $ConfigurationData.NonNodeData.ManagedAccounts.Services
                    Ensure               = "Present"
                    PsDscRunAsCredential = $InstallAccount
                    DependsOn            = "[SPManagedAccount]$($ConfigurationData.NonNodeData.ManagedAccounts.Services)"
                }

                #region AppMgmtServiceApp
                SPAppManagementServiceApp AppManagementServiceApp
                {
                    Name                 = $ConfigurationData.NonNodeData.ServiceApplications.AppManagement.Name
                    ApplicationPool      = $ConfigurationData.NonNodeData.ApplicationPools.ServiceApplicationPools.Name
                    DatabaseServer       = $ConfigurationData.NonNodeData.DomainDetails.DBServerInfr
                    DatabaseName         = $ConfigurationData.NonNodeData.ServiceApplications.AppManagement.DBName
                    Ensure               = "Present"
                    PsDscRunAsCredential = $InstallAccount
                    DependsOn            = "[SPServiceAppPool]ServiceAppPool_Services"
                }
                #endregion AppMgmtServiceApp

                #region BCSServiceApp
                SPBCSServiceApp BCSServiceApp
                {
                    Name                 = $ConfigurationData.NonNodeData.ServiceApplications.BCSService.Name
                    DatabaseServer       = $ConfigurationData.NonNodeData.DomainDetails.DBServerInfr
                    DatabaseName         = $ConfigurationData.NonNodeData.ServiceApplications.BCSService.DBName
                    ApplicationPool      = $ConfigurationData.NonNodeData.ApplicationPools.ServiceApplicationPools.Name
                    Ensure               = "Present"
                    PsDscRunAsCredential = $InstallAccount
                    DependsOn            = "[SPServiceAppPool]ServiceAppPool_Services"
                }
                #endregion BCSServiceApp

                #region MMSServiceApp
                SPManagedMetaDataServiceApp "ManagedMetadataServiceApp"
                {
                    Name                 = $ConfigurationData.NonNodeData.ServiceApplications.ManagedMetaDataService.Name
                    ApplicationPool      = $ConfigurationData.NonNodeData.ApplicationPools.ServiceApplicationPools.Name
                    DatabaseServer       = $ConfigurationData.NonNodeData.DomainDetails.DBServerInfr
                    DatabaseName         = $ConfigurationData.NonNodeData.ServiceApplications.ManagedMetaDataService.DBName
                    Ensure               = "Present"
                    PsDscRunAsCredential = $InstallAccount
                    DependsOn            = "[SPServiceAppPool]ServiceAppPool_Services"
                }
                #endregion MMSServiceApp

                #region SecureStoreServiceApp
                SPSecureStoreServiceApp "SecureStoreServiceApp"
                {
                    Name                 = $ConfigurationData.NonNodeData.ServiceApplications.SecureStore.Name
                    ApplicationPool      = $ConfigurationData.NonNodeData.ApplicationPools.ServiceApplicationPools.Name
                    AuditingEnabled      = $true
                    AuditlogMaxSize      = 30
                    DatabaseName         = $ConfigurationData.NonNodeData.ServiceApplications.SecureStore.DBName
                    Ensure               = "Present"
                    PsDscRunAsCredential = $InstallAccount
                    DependsOn            = "[SPServiceAppPool]ServiceAppPool_Services"
                }
                #endregion SecureStoreServiceApp

                #region StateServiceApp
                SPStateServiceApp "StateServiceApp"
                {
                    Name                 = $ConfigurationData.NonNodeData.ServiceApplications.StateService.Name
                    DatabaseServer       = $ConfigurationData.NonNodeData.DomainDetails.DBServerInfr
                    DatabaseName         = $ConfigurationData.NonNodeData.ServiceApplications.StateService.DBName
                    Ensure               = "Present"
                    PsDscRunAsCredential = $InstallAccount
                    DependsOn            = "[SPManagedAccount]$($ConfigurationData.NonNodeData.ManagedAccounts.Services)"
                }
                #endregion StateServiceApp

                #region SubscriptionSettingsServiceApp
                SPSubscriptionSettingsServiceApp "SubscriptionSettingsServiceApp"
                {
                    Name                 = $ConfigurationData.NonNodeData.ServiceApplications.SubscriptionSettings.Name
                    ApplicationPool      = $ConfigurationData.NonNodeData.ApplicationPools.ServiceApplicationPools.Name
                    DatabaseServer       = $ConfigurationData.NonNodeData.DomainDetails.DBServerInfr
                    DatabaseName         = $ConfigurationData.NonNodeData.ServiceApplications.SubscriptionSettings.DBName
                    Ensure               = "Present"
                    PsDscRunAsCredential = $InstallAccount
                    DependsOn            = "[SPManagedAccount]$($ConfigurationData.NonNodeData.ManagedAccounts.Services)"
                }
                #endregion SubscriptionSettingsServiceApp

                #region UsageServiceApp
                SPUsageApplication "UsageApplication"
                {
                    Name                  = $ConfigurationData.NonNodeData.ServiceApplications.UsageAndHealth.Name
                    DatabaseServer        = $ConfigurationData.NonNodeData.DomainDetails.DBServerInfr
                    DatabaseName          = $ConfigurationData.NonNodeData.ServiceApplications.UsageAndHealth.DBName
                    UsageLogCutTime       = $ConfigurationData.NonNodeData.Logging.UsagePerLogInMinutes
                    UsageLogLocation      = $ConfigurationData.NonNodeData.Logging.UsageLogPath
                    UsageLogMaxFileSizeKB = $ConfigurationData.NonNodeData.Logging.UsageMaxLogSizeInMB * 1024
                    PsDscRunAsCredential  = $InstallAccount
                    DependsOn             = '[SPFarm]SharePointFarmConfig'
                }
                #endregion UsageServiceApp

                $hostName = $ConfigurationData.NonNodeData.ServiceApplications.UserProfileService.MySiteHostLocation.Replace("http://", "").Replace("https://", "").Replace("/", "")
                $site = "Site_$($hostName)"
                SPUserProfileServiceApp "UserProfileServiceApp"
                {
                    Name                 = $ConfigurationData.NonNodeData.ServiceApplications.UserProfileService.Name
                    ApplicationPool      = $ConfigurationData.NonNodeData.ApplicationPools.ServiceApplicationPools.Name
                    MySiteHostLocation   = $ConfigurationData.NonNodeData.ServiceApplications.UserProfileService.MySiteHostLocation
                    ProfileDBName        = $ConfigurationData.NonNodeData.ServiceApplications.UserProfileService.ProfileDBName
                    ProfileDBServer      = $ConfigurationData.NonNodeData.DomainDetails.DBServerInfr
                    SocialDBName         = $ConfigurationData.NonNodeData.ServiceApplications.UserProfileService.SocialDBName
                    SocialDBServer       = $ConfigurationData.NonNodeData.DomainDetails.DBServerInfr
                    SyncDBName           = $ConfigurationData.NonNodeData.ServiceApplications.UserProfileService.SyncDBName
                    SyncDBServer         = $ConfigurationData.NonNodeData.DomainDetails.DBServerInfr
                    EnableNetBIOS        = $false
                    PsDscRunAsCredential = $InstallAccount
                    DependsOn            = @("[SPServiceAppPool]ServiceAppPool_Services", "[SPSite]$site")
                }

                $UpsSyncAccount = $Credentials | Where-Object { $_.UserName -eq $ConfigurationData.NonNodeData.ManagedAccounts.UpsSync }
                SPUserProfileSyncConnection "UserProfileSyncConnection"
                {
                    Name                  = $ConfigurationData.NonNodeData.ServiceApplications.UserProfileService.UserProfileSyncConnection.Name
                    UserProfileService    = $ConfigurationData.NonNodeData.ServiceApplications.UserProfileService.Name
                    Forest                = $ConfigurationData.NonNodeData.ServiceApplications.UserProfileService.UserProfileSyncConnection.Forest
                    ConnectionCredentials = $UpsSyncAccount
                    UseSSL                = $ConfigurationData.NonNodeData.ServiceApplications.UserProfileService.UserProfileSyncConnection.UseSSL
                    Port                  = $ConfigurationData.NonNodeData.ServiceApplications.UserProfileService.UserProfileSyncConnection.Port
                    IncludedOUs           = $ConfigurationData.NonNodeData.ServiceApplications.UserProfileService.UserProfileSyncConnection.IncludedOUs
                    ExcludedOUs           = $ConfigurationData.NonNodeData.ServiceApplications.UserProfileService.UserProfileSyncConnection.ExcludedOUs
                    Force                 = $ConfigurationData.NonNodeData.ServiceApplications.UserProfileService.UserProfileSyncConnection.Force
                    ConnectionType        = $ConfigurationData.NonNodeData.ServiceApplications.UserProfileService.UserProfileSyncConnection.ConnectionType
                    PsDscRunAsCredential  = $InstallAccount
                    DependsOn             = "[SPUserProfileServiceApp]UserProfileServiceApp"
                }

                $contentDBs = @()
                $spns = @()
                foreach ($webAppEnum in $ConfigurationData.NonNodeData.WebApplications.GetEnumerator())
                {
                    # Skip to next web application if ProvisionApps=False and the current web app is Apps
                    if ($ConfigurationData.NonNodeData.SharePoint.ProvisionApps -eq $false -and
                        $webAppEnum.Key -eq 'Apps')
                    {
                        continue
                    }

                    $webApplication = $webAppEnum.Value

                    $contentDB = "ContentDB_$($webApplication.DatabaseName)"
                    if ($contentDBs.Contains($contentDB) -eq $true)
                    {
                        throw "Specified database is already configured!"
                    }

                    $contentDBs += $contentDB

                    $hostheader = $webApplication.Url.Replace("https://", "")
                    SPWebApplication $webApplication.Name
                    {
                        Name                   = $webApplication.Name
                        ApplicationPool        = $webApplication.ApplicationPool
                        ApplicationPoolAccount = $webApplication.ApplicationPoolAccount
                        AllowAnonymous         = $false
                        DatabaseName           = $webApplication.DatabaseName
                        DatabaseServer         = $ConfigurationData.NonNodeData.DomainDetails.DBServerCont
                        WebAppUrl              = $webApplication.Url
                        HostHeader             = $hostheader
                        Port                   = $webApplication.Port
                        Ensure                 = "Present"
                        PsDscRunAsCredential   = $InstallAccount
                        DependsOn              = '[SPFarm]SharePointFarmConfig'
                    }

                    SPCacheAccounts $webApplication.Name
                    {
                        WebAppUrl            = $webApplication.Url
                        SuperUserAlias       = $ConfigurationData.NonNodeData.FarmConfig.SuperUser
                        SuperReaderAlias     = $ConfigurationData.NonNodeData.FarmConfig.SuperReader
                        SetWebAppPolicy      = $true
                        PsDscRunAsCredential = $InstallAccount
                        DependsOn            = "[SPWebApplication]$($webApplication.Name)"
                    }

                    SPDesignerSettings $webApplication.Name
                    {
                        WebAppUrl                              = $webApplication.Url
                        SettingsScope                          = "WebApplication"
                        AllowSharePointDesigner                = $true
                        AllowDetachPagesFromDefinition         = $false
                        AllowCustomiseMasterPage               = $false
                        AllowManageSiteURLStructure            = $false
                        AllowCreateDeclarativeWorkflow         = $false
                        AllowSavePublishDeclarativeWorkflow    = $false
                        AllowSaveDeclarativeWorkflowAsTemplate = $false
                        PsDscRunAsCredential                   = $InstallAccount
                        DependsOn                              = "[SPWebApplication]$($webApplication.Name)"
                    }

                    # Create root Path based site collection
                    $pathBasedRootSC = $webApplication.PathBasedRootSiteCollection
                    $contentDB = "ContentDB_$($pathBasedRootSC.ContentDatabase)"
                    $depends = "[SPWebApplication]$($webApplication.Name)"

                    if ($contentDBs.Contains($contentDB) -eq $false)
                    {
                        SPContentDatabase $contentDB
                        {
                            Name                 = $pathBasedRootSC.ContentDatabase
                            DatabaseServer       = $ConfigurationData.NonNodeData.DomainDetails.DBServerCont
                            WebAppUrl            = $webApplication.Url
                            Enabled              = $true
                            WarningSiteCount     = 2000
                            MaximumSiteCount     = 5000
                            Ensure               = "Present"
                            PsDscRunAsCredential = $InstallAccount
                            DependsOn            = "[SPWebApplication]$($webApplication.Name)"
                        }

                        $contentDBs += $contentDB
                        $depends = "[SPContentDatabase]$($contentDB)"
                    }

                    # Determine hostname, used for configuring SPN
                    $hostName = $pathBasedRootSC.Url.Replace("http://", "").Replace("https://", "").Replace("/", "")

                    $webAppAccount = Split-Path -Path $webApplication.ApplicationPoolAccount -Leaf

                    $spn = "HTTP/$hostName"
                    if ($spns -notcontains $spn)
                    {
                        $spns += $spn
                        ADServicePrincipalName "SPN_$spn"
                        {
                            ServicePrincipalName = $spn
                            Account              = $webAppAccount
                            Ensure               = 'Present'
                            PsDscRunAsCredential = $InstallAccount
                            DependsOn            = '[WindowsFeature]ADPowerShell'
                        }
                    }

                    SPSite $pathBasedRootSC.Url
                    {
                        Url                  = $pathBasedRootSC.Url
                        OwnerAlias           = $webApplication.OwnerAlias
                        ContentDatabase      = $pathBasedRootSC.ContentDatabase
                        Name                 = $pathBasedRootSC.Name
                        Template             = $pathBasedRootSC.Template
                        Language             = $pathBasedRootSC.Language
                        PsDscRunAsCredential = $InstallAccount
                        DependsOn            = $depends
                    }

                    # Create Host Header site collections
                    foreach ($hostNamedSiteCollection in $webApplication.HostNamedSiteCollections)
                    {
                        # Determine hostname, used for configuring SPN
                        $hostName = $hostNamedSiteCollection.Url.Replace("http://", "").Replace("https://", "").Replace("/", "")

                        $spn = "HTTP/$hostName"
                        if ($spns -notcontains $spn)
                        {
                            ADServicePrincipalName "SPN_$spn"
                            {
                                ServicePrincipalName = $spn
                                Account              = $webAppAccount
                                Ensure               = 'Present'
                                PsDscRunAsCredential = $InstallAccount
                                DependsOn            = '[WindowsFeature]ADPowerShell'
                            }
                        }

                        $site = "Site_$($hostName)"

                        $contentDB = "ContentDB_$($hostNamedSiteCollection.ContentDatabase)"
                        $depends = "[SPWebApplication]$($webApplication.Name)"

                        if ($contentDBs.Contains($contentDB) -eq $false)
                        {
                            SPContentDatabase $contentDB
                            {
                                Name                 = $hostNamedSiteCollection.ContentDatabase
                                DatabaseServer       = $ConfigurationData.NonNodeData.DomainDetails.DBServerCont
                                WebAppUrl            = $webApplication.Url
                                Enabled              = $true
                                WarningSiteCount     = 2000
                                MaximumSiteCount     = 5000
                                Ensure               = "Present"
                                PsDscRunAsCredential = $InstallAccount
                                DependsOn            = "[SPWebApplication]$($webApplication.Name)"
                            }

                            $contentDBs += $contentDB
                            $depends = "[SPContentDatabase]$contentDB"
                        }

                        SPSite $site
                        {
                            Url                      = $hostNamedSiteCollection.Url
                            OwnerAlias               = $webApplication.OwnerAlias
                            ContentDatabase          = $hostNamedSiteCollection.ContentDatabase
                            HostHeaderWebApplication = $webApplication.Url
                            Name                     = $hostNamedSiteCollection.Name
                            Template                 = $hostNamedSiteCollection.Template
                            Language                 = $hostNamedSiteCollection.Language
                            PsDscRunAsCredential     = $InstallAccount
                            DependsOn                = $depends
                        }
                    }

                    SPWebAppAuthentication "WebAppAuthentication_$($webApplication.Name)"
                    {
                        WebAppUrl            = $webApplication.Url
                        Default              = @(
                            MSFT_SPWebAppAuthenticationMode
                            {
                                AuthenticationMethod = "WindowsAuthentication"
                                WindowsAuthMethod    = "Kerberos"
                            }
                        )
                        PsDscRunAsCredential = $InstallAccount
                        DependsOn            = @("[SPWebApplication]$($webApplication.Name)")
                    }

                    SPWebAppGeneralSettings "GeneralSettings_$($webApplication.Name)"
                    {
                        WebAppUrl                      = $webApplication.Url
                        TimeZone                       = 4    # (GMT+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna
                        SelfServiceSiteCreationEnabled = $false
                        MaximumUploadSize              = 250
                        RecycleBinEnabled              = $true
                        DefaultQuotaTemplate           = "500MB"
                        PsDscRunAsCredential           = $InstallAccount
                        DependsOn                      = @("[SPWebApplication]$($webApplication.Name)")
                    }

                    SPWebAppThrottlingSettings "Throttling_$($webApplication.Name)"
                    {
                        WebAppUrl               = $webApplication.Url
                        ListViewLookupThreshold = 8
                        HappyHourEnabled        = $true
                        HappyHour               = MSFT_SPWebApplicationHappyHour
                        {
                            Hour     = 6
                            Minute   = 0
                            Duration = 2
                        }
                        ChangeLogEnabled        = $true
                        ChangeLogExpiryDays     = 60
                        PsDscRunAsCredential    = $InstallAccount
                        DependsOn               = @("[SPWebApplication]$($webApplication.Name)")
                    }

                    SPBlobCacheSettings "BlobCacheSettings_$($webApplication.Name)"
                    {
                        WebAppUrl            = $webApplication.Url
                        Zone                 = 'Default'
                        EnableCache          = $true
                        Location             = $webApplication.BlobCacheFolder
                        MaxSizeInGB          = $webApplication.BlobCacheSize
                        FileTypes            = $webApplication.BlobCacheFileTypes
                        PsDscRunAsCredential = $InstallAccount
                        DependsOn            = @("[SPWebApplication]$($webApplication.Name)")
                    }

                    SPWebAppPermissions "WebAppPermissions_$($webApplication.Name)"
                    {
                        WebAppUrl            = $webApplication.Url
                        AllPermissions       = $true
                        PsDscRunAsCredential = $InstallAccount
                        DependsOn            = @("[SPWebApplication]$($webApplication.Name)")
                    }

                    if ($webApplication.Name -eq $ConfigurationData.NonNodeData.WebApplications.Content.Name)
                    {
                        SPFeature "EnableFeature_DocumentManagement_$($webApplication.Name)"
                        {
                            Url                  = $webApplication.Url
                            Name                 = 'DocumentManagement'
                            FeatureScope         = 'WebApplication'
                            Ensure               = 'Present'
                            PsDscRunAsCredential = $InstallAccount
                            DependsOn            = @("[SPWebApplication]$($webApplication.Name)")
                        }

                        SPFeature "EnableFeature_SPSearch_Enterprise_$($webApplication.Name)"
                        {
                            Url                  = $webApplication.Url
                            Name                 = 'OSearchEnhancedFeature'
                            FeatureScope         = 'WebApplication'
                            Ensure               = 'Present'
                            PsDscRunAsCredential = $InstallAccount
                            DependsOn            = @("[SPWebApplication]$($webApplication.Name)")
                        }

                        SPFeature "EnableFeature_SPSearch_Standard_$($webApplication.Name)"
                        {
                            Url                  = $webApplication.Url
                            Name                 = 'OSearchBasicFeature'
                            FeatureScope         = 'WebApplication'
                            Ensure               = 'Present'
                            PsDscRunAsCredential = $InstallAccount
                            DependsOn            = @("[SPWebApplication]$($webApplication.Name)")
                        }

                        SPFeature "EnableFeature_SP_Standard_$($webApplication.Name)"
                        {
                            Url                  = $webApplication.Url
                            Name                 = 'BaseWebApplication'
                            FeatureScope         = 'WebApplication'
                            Ensure               = 'Present'
                            PsDscRunAsCredential = $InstallAccount
                            DependsOn            = @("[SPWebApplication]$($webApplication.Name)")
                        }

                        SPFeature "DisableFeature_InternetFacingApps_$($webApplication.Name)"
                        {
                            Url                  = $webApplication.Url
                            Name                 = 'IfeDependentApps'
                            FeatureScope         = 'WebApplication'
                            Ensure               = 'Absent'
                            PsDscRunAsCredential = $InstallAccount
                            DependsOn            = @("[SPWebApplication]$($webApplication.Name)")
                        }

                        SPFeature "DisableFeature_SP_Enterprise_$($webApplication.Name)"
                        {
                            Url                  = $webApplication.Url
                            Name                 = 'PremiumWebApplication'
                            FeatureScope         = 'WebApplication'
                            Ensure               = 'Absent'
                            PsDscRunAsCredential = $InstallAccount
                            DependsOn            = @("[SPWebApplication]$($webApplication.Name)")
                        }

                        SPFeature "DisableFeature_VideoProcessin_$($webApplication.Name)"
                        {
                            Url                  = $webApplication.Url
                            Name                 = 'VideoProcessing'
                            FeatureScope         = 'WebApplication'
                            Ensure               = 'Absent'
                            PsDscRunAsCredential = $InstallAccount
                            DependsOn            = @("[SPWebApplication]$($webApplication.Name)")
                        }

                        if ($ConfigurationData.NonNodeData.SharePoint.ProvisionApps -eq $true)
                        {
                            SPAppStoreSettings "AppStoreSettings_$($webApplication.Name)"
                            {
                                WebAppUrl            = $webApplication.Url
                                AllowAppPurchases    = $ConfigurationData.NonNodeData.FarmConfig.AppsSettings.AllowAppPurchases
                                AllowAppsForOffice   = $ConfigurationData.NonNodeData.FarmConfig.AppsSettings.AllowAppPurchases
                                PsDscRunAsCredential = $InstallAccount
                                DependsOn            = @("[SPWebApplication]$($webApplication.Name)", "[SPAppCatalog]Configure_AppCatalog")
                            }
                        }
                    }
                }

                SPFeature "DisableMySite"
                {
                    Name                 = "MySite"
                    Url                  = "N/A"
                    FeatureScope         = "Farm"
                    Ensure               = "Absent"
                    PsDscRunAsCredential = $InstallAccount
                    DependsOn            = '[SPFarm]SharePointFarmConfig'
                }

                if ($ConfigurationData.NonNodeData.SharePoint.ProvisionApps -eq $true)
                {
                    $appCatalogUrl = ($ConfigurationData.NonNodeData.WebApplications.Content.HostNamedSiteCollections | Where-Object { $_.Template -eq "APPCATALOG#0" }).Url
                    $appCatalogHostName = $appCatalogUrl.Replace("http://", "").Replace("https://", "").Replace("/", "")
                    SPAppCatalog "Configure_AppCatalog"
                    {
                        SiteUrl              = $appCatalogUrl
                        PsDscRunAsCredential = $InstallAccount
                        DependsOn            = @("[SPSite]Site_$($appCatalogHostName)")
                    }

                    SPAppDomain "ConfigureAppDomain"
                    {
                        AppDomain            = $ConfigurationData.NonNodeData.FarmConfig.AppsSettings.AppDomain
                        Prefix               = $ConfigurationData.NonNodeData.FarmConfig.AppsSettings.Prefix
                        PsDscRunAsCredential = $InstallAccount
                        DependsOn            = @("[SPAppCatalog]Configure_AppCatalog")
                    }
                }
            }

            # Configure all Back-End servers
            if ($beServers -contains $Node.NodeName)
            {
                $blobCacheFolders = $ConfigurationData.NonNodeData.WebApplications.GetEnumerator() | ForEach-Object {
                    $_.Value.BlobCacheFolder
                } | Sort-Object -Unique

                foreach ($folder in $blobCacheFolders)
                {
                    $name = $folder -replace ":", "" -replace "\\", "_"
                    File "BlobCacheFolder_$name"
                    {
                        Type            = "Directory"
                        DestinationPath = $folder
                        Ensure          = "Present"
                        Credential      = $InstallAccount
                    }
                }

                SPServiceInstance 'BusinessConnectivityServiceInstance'
                {
                    Name                 = "Business Data Connectivity Service"
                    Ensure               = "Present"
                    PsDscRunAsCredential = $InstallAccount
                    DependsOn            = '[SPFarm]SharePointFarmConfig'
                }

                SPServiceInstance 'CentralAdministrationServiceInstance'
                {
                    Name                 = "Central Administration"
                    Ensure               = "Present"
                    PsDscRunAsCredential = $InstallAccount
                    DependsOn            = '[SPFarm]SharePointFarmConfig'
                }

                SPServiceInstance 'ManagedMetadataServiceInstance'
                {
                    Name                 = "Managed Metadata Web Service"
                    Ensure               = "Present"
                    PsDscRunAsCredential = $InstallAccount
                    DependsOn            = '[SPFarm]SharePointFarmConfig'
                }

                SPServiceInstance 'IncomingEmailServiceInstance'
                {
                    Name                 = "Microsoft SharePoint Foundation Incoming E-Mail"
                    Ensure               = "Present"
                    PsDscRunAsCredential = $InstallAccount
                    DependsOn            = '[SPFarm]SharePointFarmConfig'
                }

                SPServiceInstance 'SubscriptionSettingsServiceInstance'
                {
                    Name                 = "Microsoft SharePoint Foundation Subscription Settings Service"
                    Ensure               = "Present"
                    PsDscRunAsCredential = $InstallAccount
                    DependsOn            = '[SPFarm]SharePointFarmConfig'
                }

                SPServiceInstance 'WebApplicationServiceInstance'
                {
                    Name                 = "Microsoft SharePoint Foundation Web Application"
                    Ensure               = "Present"
                    PsDscRunAsCredential = $InstallAccount
                    DependsOn            = '[SPFarm]SharePointFarmConfig'
                }

                SPServiceInstance 'WebAppTimerServiceInstance'
                {
                    Name                 = "Microsoft SharePoint Foundation Workflow Timer Service"
                    Ensure               = "Present"
                    PsDscRunAsCredential = $InstallAccount
                    DependsOn            = '[SPFarm]SharePointFarmConfig'
                }

                SPServiceInstance 'SecureStoreServiceInstance'
                {
                    Name                 = "Secure Store Service"
                    Ensure               = "Present"
                    PsDscRunAsCredential = $InstallAccount
                    DependsOn            = '[SPFarm]SharePointFarmConfig'
                }

                SPServiceInstance 'UserProfileServiceInstance'
                {
                    Name                 = "User Profile Service"
                    Ensure               = "Present"
                    PsDscRunAsCredential = $InstallAccount
                    DependsOn            = '[SPFarm]SharePointFarmConfig'
                }
            }

            # Configure all Search servers
            if ($searchServers -contains $Node.NodeName)
            {
                File "IndexPartitionRootDir_$($Node.NodeName)"
                {
                    Type            = "Directory"
                    DestinationPath = $ConfigurationData.NonNodeData.ServiceApplications.SearchService.IndexPartitionRootDirectory
                    Ensure          = "Present"
                    Credential      = $InstallAccount
                    DependsOn       = '[SPFarm]SharePointFarmConfig'
                }

                $path = $ConfigurationData.NonNodeData.ServiceApplications.SearchService.IndexPartitionRootDirectory
                $account = $ConfigurationData.NonNodeData.ManagedAccounts.Search
                Script 'Set_Folder_Permissions_IndexPartitionRootDir'
                {
                    GetScript  = {
                        $permissions = @{
                            Account           = $using:account
                            FileSystemRights  = $null
                            AccessControlType = $null
                            InheritanceFlags  = $null
                            PropagationFlags  = $null
                        }

                        $acl = Get-Acl -Path $using:path
                        $userAcl = $acl.Access | Where-Object { $_.IdentityReference -eq $using:account }
                        if ($null -eq $userAcl)
                        {
                            return @{ Result = ($permissions | format-list * -force | out-string) }
                        }
                        elseif ($userAcl.Count -gt 1)
                        {
                            return @{ Result = ($permissions | format-list * -force | out-string) }
                        }
                        else
                        {
                            $permissions.FileSystemRights = $userAcl.FileSystemRights.ToString()
                            $permissions.AccessControlType = $userAcl.AccessControlType.ToString()
                            $permissions.InheritanceFlags = $userAcl.InheritanceFlags.ToString()
                            $permissions.PropagationFlags = $userAcl.PropagationFlags.ToString()
                            return @{ Result = ($permissions | format-list * -force | out-string) }
                        }
                    }
                    SetScript  = {
                        $acl = Get-Acl $using:path

                        $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($using:account, 'Modify', 'ContainerInherit, ObjectInherit', 'None', 'Allow')

                        $acl.SetAccessRule($AccessRule)

                        Set-Acl -Path $using:path -AclObject $acl
                    }
                    TestScript = {
                        $acl = Get-Acl -Path $using:path
                        $userAcl = $acl.Access | Where-Object { $_.IdentityReference -eq $using:account }
                        if ($null -eq $userAcl)
                        {
                            return $false
                        }
                        elseif ($userAcl.Count -gt 1)
                        {
                            return $false
                        }
                        else
                        {
                            if ($userAcl.FileSystemRights -eq 'Modify, Synchronize' -and
                                $userAcl.AccessControlType -eq 'Allow' -and
                                $userAcl.InheritanceFlags -eq 'ContainerInherit, ObjectInherit' -and
                                $userAcl.PropagationFlags -eq 'None')
                            {
                                return $true
                            }
                        }
                        return $false
                    }
                    DependsOn  = "[File]IndexPartitionRootDir_$($Node.NodeName)"
                }
            }

            # Configure Search on the first Backend Search server
            if ($Node.NodeName -eq $firstSearchBEServer)
            {
                WaitForAll 'WaitForServiceAppPool_Services'
                {
                    NodeName         = $firstBEServer
                    ResourceName     = '[SPServiceAppPool]ServiceAppPool_Services'
                    RetryIntervalSec = 60
                    RetryCount       = 60
                }

                $servicesAccount = $Credentials | Where-Object { $_.UserName -eq $ConfigurationData.NonNodeData.ManagedAccounts.Search }
                $crawlAccount = $Credentials | Where-Object { $_.UserName -eq $ConfigurationData.NonNodeData.ServiceApplications.SearchService.DefaultContentAccessAccount }

                SPSearchServiceApp 'SearchServiceApp'
                {
                    Name                        = $ConfigurationData.NonNodeData.ServiceApplications.SearchService.Name
                    DatabaseServer              = $ConfigurationData.NonNodeData.DomainDetails.DBServerSear
                    DatabaseName                = $ConfigurationData.NonNodeData.ServiceApplications.SearchService.DBName
                    ApplicationPool             = $ConfigurationData.NonNodeData.ApplicationPools.ServiceApplicationPools.Name
                    DefaultContentAccessAccount = $crawlAccount
                    SearchCenterUrl             = $ConfigurationData.NonNodeData.ServiceApplications.SearchService.SearchCenterUrl
                    Ensure                      = 'Present'
                    PsDscRunAsCredential        = $InstallAccount
                    DependsOn                   = '[WaitForAll]WaitForServiceAppPool_Services'
                }

                SPSearchTopology 'LocalSearchTopology'
                {
                    ServiceAppName          = $ConfigurationData.NonNodeData.ServiceApplications.SearchService.Name
                    Admin                   = $searchBEServers
                    Crawler                 = $searchBEServers
                    ContentProcessing       = $searchBEServers
                    AnalyticsProcessing     = $searchBEServers
                    QueryProcessing         = $searchFEServers
                    IndexPartition          = $searchFEServers
                    FirstPartitionDirectory = "$($ConfigurationData.NonNodeData.ServiceApplications.SearchService.IndexPartitionRootDirectory)\0"
                    PsDscRunAsCredential    = $InstallAccount
                    DependsOn               = '[SPSearchServiceApp]SearchServiceApp'
                }

                SPSearchServiceSettings 'SearchServiceSettings'
                {
                    IsSingleInstance      = 'Yes'
                    PerformanceLevel      = $ConfigurationData.NonNodeData.FarmConfig.SearchSettings.PerformanceLevel
                    ContactEmail          = $ConfigurationData.NonNodeData.FarmConfig.SearchSettings.ContactEmail
                    WindowsServiceAccount = $servicesAccount
                    PsDscRunAsCredential  = $InstallAccount
                    DependsOn             = '[SPSearchTopology]LocalSearchTopology'
                }
            }

            # Configure all Front-End servers
            if ($feServers -contains $Node.NodeName)
            {
                # If server also is specified as BE server, skip this section. Services are already started.
                if ($beServers -notcontains $Node.NodeName)
                {
                    $blobCacheFolders = $ConfigurationData.NonNodeData.WebApplications.GetEnumerator() | ForEach-Object {
                        $_.Value.BlobCacheFolder
                    } | Sort-Object -Unique

                    foreach ($folder in $blobCacheFolders)
                    {
                        $name = $folder -replace ":", "" -replace "\\", "_"
                        File "BlobCacheFolder_$name"
                        {
                            Type            = "Directory"
                            DestinationPath = $folder
                            Ensure          = "Present"
                            Credential      = $InstallAccount
                        }
                    }

                    SPServiceInstance 'BusinessConnectivityServiceInstance'
                    {
                        Name                 = 'Business Data Connectivity Service'
                        Ensure               = 'Present'
                        PsDscRunAsCredential = $InstallAccount
                        DependsOn            = '[SPFarm]SharePointFarmConfig'
                    }

                    SPServiceInstance 'ManagedMetadataServiceInstance'
                    {
                        Name                 = 'Managed Metadata Web Service'
                        Ensure               = 'Present'
                        PsDscRunAsCredential = $InstallAccount
                        DependsOn            = '[SPFarm]SharePointFarmConfig'
                    }

                    SPServiceInstance 'SubscriptionSettingsServiceInstance'
                    {
                        Name                 = 'Microsoft SharePoint Foundation Subscription Settings Service'
                        Ensure               = 'Present'
                        PsDscRunAsCredential = $InstallAccount
                        DependsOn            = '[SPFarm]SharePointFarmConfig'
                    }

                    SPServiceInstance 'WebApplicationServiceInstance'
                    {
                        Name                 = 'Microsoft SharePoint Foundation Web Application'
                        Ensure               = 'Present'
                        PsDscRunAsCredential = $InstallAccount
                        DependsOn            = '[SPFarm]SharePointFarmConfig'
                    }

                    SPServiceInstance 'SecureStoreServiceInstance'
                    {
                        Name                 = 'Secure Store Service'
                        Ensure               = 'Present'
                        PsDscRunAsCredential = $InstallAccount
                        DependsOn            = '[SPFarm]SharePointFarmConfig'
                    }

                    SPServiceInstance 'UserProfileServiceInstance'
                    {
                        Name                 = 'User Profile Service'
                        Ensure               = 'Present'
                        PsDscRunAsCredential = $InstallAccount
                        DependsOn            = '[SPFarm]SharePointFarmConfig'
                    }
                }

                $processedAppPools = @()
                foreach ($webAppEnum in $ConfigurationData.NonNodeData.WebApplications.GetEnumerator())
                {
                    $internalName = $webAppEnum.Name
                    $webApplication = $webAppEnum.Value

                    WaitForAny "WaitForWebApplication_$($webApplication.Name)"
                    {
                        NodeName         = $firstBEServer
                        ResourceName     = "[SPWebApplication]$($webApplication.Name)"
                        RetryIntervalSec = 60
                        RetryCount       = 60
                        DependsOn        = '[SPFarm]SharePointFarmConfig'
                    }

                    $xWebsite = "xWebsite_$($webApplication.Name)"

                    xWebsite $xWebsite
                    {
                        Name        = $webApplication.Name
                        BindingInfo = @(
                            $hostName = $webApplication.URL.Replace('http://', '').Replace('https://', '').Replace('/', '').Replace('root', '*')
                            MSFT_xWebBindingInformation
                            {
                                Port                  = 443
                                Protocol              = 'HTTPS'
                                IPAddress             = $node.IPAddress.$($internalName)
                                CertificateThumbprint = $ConfigurationData.NonNodeData.Certificates.$($webApplication.Certificate).Thumbprint.ToUpper()
                                CertificateStoreName  = $webApplication.CertificateStoreName
                            }
                        )
                        DependsOn   = "[WaitForAny]WaitForWebApplication_$($webApplication.Name)"
                    }

                    if ($processedAppPools -notcontains $webApplication.ApplicationPool)
                    {
                        xWebAppPool "AppPoolSettings_$($webApplication.ApplicationPool)"
                        {
                            Name            = $webApplication.ApplicationPool
                            Ensure          = 'Present'
                            State           = 'Started'
                            autoStart       = $true
                            restartSchedule = @("02:$(Get-Random -Maximum 59):00")
                            DependsOn       = "[WaitForAny]WaitForWebApplication_$($webApplication.Name)"
                        }
                        $processedAppPools += $webApplication.ApplicationPool
                    }
                }

                WaitForAll 'WaitForServicesManagedAccount'
                {
                    NodeName         = $firstBEServer
                    ResourceName     = "[SPManagedAccount]$($ConfigurationData.NonNodeData.ManagedAccounts.Services)"
                    RetryIntervalSec = 60
                    RetryCount       = 60
                    DependsOn        = '[SPFarm]SharePointFarmConfig'
                }

                $servicesAccount = $Credentials | Where-Object { $_.UserName -eq $ConfigurationData.NonNodeData.ManagedAccounts.Services }

                SPDistributedCacheService "DistributedCacheService_$($Node.NodeName)"
                {
                    Name                 = 'Distributed Cache Service'
                    Ensure               = 'Present'
                    CacheSizeInMB        = 1024
                    ServiceAccount       = $servicesAccount.UserName
                    CreateFirewallRules  = $true
                    ServerProvisionOrder = $distributedCacheServers
                    PsDscRunAsCredential = $InstallAccount
                    DependsOn            = '[WaitForAll]WaitForServicesManagedAccount'
                }
            }

            #**********************************************************
            # IIS clean up
            #
            # This section stop all default sites and application
            # pools from IIS as they are not required
            #**********************************************************

            xWebAppPool 'DisableDotNet2Pool'
            {
                Name = '.NET v2.0'; State = 'Stopped'; DependsOn = '[SPInstallPrereqs]Install_SP_Prereqs'
            }
            xWebAppPool 'DisableDotNet2ClassicPool'
            {
                Name = '.NET v2.0 Classic'; State = 'Stopped'; DependsOn = '[SPInstallPrereqs]Install_SP_Prereqs'
            }
            xWebAppPool 'DisableDotNet45Pool'
            {
                Name = '.NET v4.5'; State = 'Stopped'; DependsOn = '[SPInstallPrereqs]Install_SP_Prereqs'
            }
            xWebAppPool 'DisableDotNet45ClassicPool'
            {
                Name = '.NET v4.5 Classic'; State = 'Stopped'; DependsOn = '[SPInstallPrereqs]Install_SP_Prereqs'
            }
            xWebAppPool 'DisableClassicDotNetPool'
            {
                Name = 'Classic .NET AppPool'; State = 'Stopped'; DependsOn = '[SPInstallPrereqs]Install_SP_Prereqs'
            }
            xWebAppPool 'DisableDefaultAppPool'
            {
                Name = 'DefaultAppPool'; State = 'Stopped'; DependsOn = '[SPInstallPrereqs]Install_SP_Prereqs'
            }
            xWebSite    'DisableDefaultWebSite'
            {
                Name = 'Default Web Site'; State = 'Stopped'; DependsOn = '[SPInstallPrereqs]Install_SP_Prereqs'
            }

            xIisLogging 'ConfigureIISLogging'
            {
                LogPath              = $ConfigurationData.NonNodeData.Logging.IISLogPath
                Logflags             = @('Date', 'Time', 'ServerIP', 'Method', 'UriStem', 'UriQuery', 'ServerPort', 'UserName', 'ClientIP', 'UserAgent', 'Referer', 'HttpStatus', 'HttpSubStatus', 'Win32Status', 'TimeTaken')
                LoglocalTimeRollover = $true
                LogPeriod            = 'Daily'
                LogFormat            = 'W3C'
                DependsOn            = '[SPInstallPrereqs]Install_SP_Prereqs'
            }
        }
        #endregion
    }
}

##### DSC COMPILATION #####
Write-Host 'Compiling DSC Configuration for SharePoint Servers' -ForegroundColor Green
if ($null -eq $Datafile)
{
    Write-Host '[ERROR] Datafile variable not specified. Have you ran the PrepVariables script?' -ForegroundColor Red
    Exit
}

Write-Host 'Checking Building Block versions:' -ForegroundColor DarkGray
$dataFileVersion = [System.Version]$DataFile.NonNodeData.BuildingBlock.Version
Write-Host "  - Data file version : $($dataFileVersion.ToString())" -ForegroundColor DarkGray
Write-Host "  - Script version    : $($buildingBlockVersion.ToString())" -ForegroundColor DarkGray
if ($dataFileVersion -eq $buildingBlockVersion)
{
    Write-Host 'Versions equal, proceeding...' -ForegroundColor DarkGray

    foreach ($node in $DataFile.AllNodes)
    {
        if ($node.CertificateFile -eq '<CERTFILE>')
        {
            Write-Host "Node $($node.NodeName) does not have a valid Certificate File populated, cancelling compilation!" -ForegroundColor Red
            exit
        }

        if ($node.Thumbprint -eq '<THUMBPRINT>')
        {
            Write-Host "Node $($node.NodeName) does not have a valid Thumbprint populated, cancelling compilation!" -ForegroundColor Red
            exit
        }
    }

    if ($ConfigPathFull -and (Test-Path $ConfigPathFull))
    {
        $outputPath = Join-Path $ConfigPathFolder '\Deploy_SP'
        Deploy_SP -ConfigurationData $ConfigPathFull `
            -InstallAccount $InstallAccount `
            -PassPhrase $PassPhrase `
            -CertificatePassword $CertPassword `
            -Credentials $credentials `
            -OutputPath $outputPath
    }
    else
    {
        Write-Host 'Configuration Data file unknown, did you run PrepVariables.ps1?' -ForegroundColor Red
    }
}
else
{
    Write-Host 'Versions do not match, please check the building block versions. Quiting!' -ForegroundColor Red
    break
}

<#
# Deploy MOF files
Start-DscConfiguration -Path '.\Deploy_SP' -Verbose -Wait -force

$SPSrv1 = Test-DscConfiguration -Computername SPSrv1 -Verbose -Detailed
$SPSrv2 = Test-DscConfiguration -Computername SPSrv2 -Verbose -Detailed
$SPSrv3 = Test-DscConfiguration -Computername SPSrv3 -Verbose -Detailed
$SPSrv4 = Test-DscConfiguration -Computername SPSrv4 -Verbose -Detailed

#>
