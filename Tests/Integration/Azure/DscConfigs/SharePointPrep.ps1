Configuration SharePointPrep
{
    param(
        [Parameter(Mandatory=$true)] 
		[ValidateNotNullorEmpty()] 
		[PSCredential] 
		$DomainAdminCredential,

        [Parameter(Mandatory=$true)] 
		[ValidateNotNullorEmpty()] 
		[PSCredential] 
		$SPSetupCredential,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SPProductKey,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SoftwareStorageAccount,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SoftwareStorageKey,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SoftwareStorageContainer
    )

    Import-DscResource -ModuleName xCredSSP -ModuleVersion 1.0.1
    Import-DscResource -ModuleName xComputerManagement -ModuleVersion 1.9.0.0
    Import-DscResource -ModuleName xWebAdministration
    Import-DscResource -ModuleName SharePointDsc

    node localhost
    {
        Registry DisableIPv6 
        {
            Key       = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters"
            ValueName = "DisabledComponents"
            ValueData = "ff"
            ValueType = "Dword"
            Hex       = $true
            Ensure    = 'Present'
        }

        xComputer DomainJoin
        {
            Name       = $env:COMPUTERNAME
            DomainName = "demo.lab"
            Credential = $DomainAdminCredential
            DependsOn  = "[Registry]DisableIPv6"
        }

        Group LocalAdministrators
        {
            GroupName        = "Administrators"
            Ensure           = "Present"
            MembersToInclude = $SPSetupCredential.UserName
            Credential       = $DomainAdminCredential
        }

        Script DownloadBinaries
        {
            GetScript = { return $null }
            TestScript = {
                Test-Path -Path C:\Binaries
            }
            SetScript = {
                if ($null -eq (Get-Module -Name Azure.Storage -ListAvailable))
                {
                    if ($PSVersionTable.PSVersion.Major -ge 5)
                    {
                        Install-Module -Name Azure.Storage
                    }
                }
                Import-Module -Name Azure.Storage
                $context = New-AzureStorageContext -StorageAccountName $using:SoftwareStorageAccount `
                                                   -StorageAccountKey $using:SoftwareStorageKey

                $blobs = Get-AzureStorageBlob -Container $using:SoftwareStorageContainer `
                                              -Context $context

                New-Item -Path C:\Binaries\SharePoint -ItemType Directory
                
                $blobs | ForEach-Object -Process {
                    Get-AzureStorageBlobContent -Blob $_.Name `
                                                -Container $using:SoftwareStorageContainer `
                                                -Destination C:\Binaries\SharePoint `
                                                -Context $context | Out-Null
                }
            }
        }

        SPInstallPrereqs InstallPrereqs {
            Ensure        = "Present"
            OnlineMode    = $true
            InstallerPath = "C:\Binaries\SharePoint\prerequisiteinstaller.exe"
            DependsOn     = @("[Script]DownloadBinaries", "[Group]LocalAdministrators") 
        }

        xWebAppPool RemoveDotNet2Pool         { Name      = ".NET v2.0"            
                                                Ensure    = "Absent" 
                                                DependsOn = "[SPInstallPrereqs]InstallPrereqs" }
        xWebAppPool RemoveDotNet2ClassicPool  { Name      = ".NET v2.0 Classic"
                                                Ensure    = "Absent"
                                                DependsOn = "[SPInstallPrereqs]InstallPrereqs" }
        xWebAppPool RemoveDotNet45Pool        { Name      = ".NET v4.5"
                                                Ensure    = "Absent"
                                                DependsOn = "[SPInstallPrereqs]InstallPrereqs" }
        xWebAppPool RemoveDotNet45ClassicPool { Name      = ".NET v4.5 Classic"
                                                Ensure    = "Absent"
                                                DependsOn = "[SPInstallPrereqs]InstallPrereqs" }
        xWebAppPool RemoveClassicDotNetPool   { Name      = "Classic .NET AppPool"
                                                Ensure = "Absent"
                                                DependsOn = "[SPInstallPrereqs]InstallPrereqs" }
        xWebAppPool RemoveDefaultAppPool      { Name      = "DefaultAppPool"
                                                Ensure    = "Absent"
                                                DependsOn = "[SPInstallPrereqs]InstallPrereqs" }
        xWebSite    RemoveDefaultWebSite      { Name         = "Default Web Site"
                                                Ensure       = "Absent"
                                                PhysicalPath = "C:\inetpub\wwwroot"
                                                DependsOn    = "[SPInstallPrereqs]InstallPrereqs" }

        SPInstall InstallSharePoint 
        {
            Ensure      = "Present"
            BinaryDir   = "C:\Binaries\SharePoint"
            ProductKey  = $SPProductKey
            DependsOn   = "[SPInstallPrereqs]InstallPrereqs"
        }

        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
            ActionAfterReboot = "ContinueConfiguration"
        }
    }
}
