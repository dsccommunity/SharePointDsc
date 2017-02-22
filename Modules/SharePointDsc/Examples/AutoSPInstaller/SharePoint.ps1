[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null

function Get-Passphrase {
    param([xml]$autoInstallerXML)

    $passphraseXML = $autoInstallerXML.Configuration.Farm.Passphrase

    if($passphraseXML -eq "") {
        $passphrase = Get-Credential -UserName "PassPhrase" -Message "Enter Farm Passphrase"
        return $passsphrase    
    }
    else {
        $secpasswd = ConvertTo-SecureString -String "$($passphraseXML)" -AsPlainText -Force
        $passphrase = New-Object System.Management.Automation.PSCredential ("PassPhrase", $secpasswd)
        return $passsphrase
    }
}

function Get-FarmAccount {
    param([xml]$autoInstallerXML)

    [PSCredential]$farmAccount;
    $farmAccountUserName = $autoInstallerXML.Configuration.Farm.Account.UserName
    $farmAccountPassword = $autoInstallerXML.Configuration.Farm.Account.Password

    if($farmAccountPassword -eq "") {
        $farmAccount = Get-Credential -UserName "$($farmAccountUserName)" -Message "Provide Farm Account Password"
    }
    else {
        $secpasswd = ConvertTo-SecureString -String "$($farmAccountPassword)" -AsPlainText -Force
        $farmAccount = New-Object System.Management.Automation.PSCredential ("$($farmAccountUserName)", $secpasswd)
       
    }
}

function Get-Version {
     param([xml]$autoInstallerXML)

     return $($autoInstallerXML.Configuration.Install.SPVersion)
}

function Get-CentralAdminServer {
    param([xml]$autoInstallerXML)
    return $autoInstallerXML.Configuration.Farm.CentralAdmin.Provision
}

function Get-DatabaseServerName {
    param([xml]$autoInstallerXML)

    if($autoInstallerXML.Configuration.Farm.Database.DBServer -eq "") {
        return "localhost"
    }
    else {
        return "$($autoInstallerXML.Configuration.Farm.Database.DBServer)"
    }
}

function Get-DatabaseAlias {
    param([xml]$autoInstallerXML)

    if($autoInstallerXML.Configuration.Farm.Database.DBAlias.Create -eq "true") {
        $dbServer = $"($autoInstallerXML.Configuration.Farm.Database.DBAlias.DBInstance)"
        $dbPort = "$($autoInstallerXML.Configuration.Farm.Database.DBAlias.DBPort)"
        
            $dbInstance = "DBMSSOCN,$($dbServer),$($dbPort)"
        if($dbPort -eq "") {
            $dbInstance = "DBMSSOCN,$($dbServer)"
        }
        return @{ 
            ValueName = Get-DatabaseServerName -autoInstallerXML $autoInstallerXML
            ValueData = "$($dbInstance)"
        }
    }
    else {
        return $null;
    }
}

function Get-ProductKey {
     param([xml]$autoInstallerXML)
     $productKey = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"

     $configFile = $autoInstallerXML.Configuration.Install.ConfigFile
     
     if($configFile -ne "") {
         [xml]$configFile = Get-Content $configFile
         $productKey = $configFile.Configuration.PIDKey
     }
     else {
        $productKey = $autoInstallerXML.Configuration.Install.PIDKey
        if($productKey -eq "") {
            $productKey = [Microsoft.VisualBasic.Interaction]::InputBox("Enter a product key", "SharePoint Product Key", "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX")
        }
     }
     return $productKey
}

function Get-OnlineInstallMode {
    param([xml]$autoInstallerXML)
    return ($autoInstallerXML.Configuration.Install.OfflineInstall -eq "false")
    
}
function Get-DBPrefixDatabaseName {
    param([string]$dbName)

    $dbPrefix = "($autoInstallerXML.Configuration.Farm.Database.DBPrefix)"
    if($dbPrefix -eq "") {
        return "$($dbName)"
    }
    else {
        return "$($dbPrefix)_$($dbName)"
    }

}
function Get-AdminContentDatabaseName {
    param([xml]$autoInstallerXML)
    $adminContentDb = "$($autoInstallerXML.Configuration.Farm.CentralAdmin.Database)"

    return (Get-DBPrefixDatabaseName -dbName $adminContentDb)
}

function Get-ConfigDatabaseName {
    param([xml]$autoInstallerXML)
    $configDb = "$($autoInstallerXML.Configuration.Farm.Database.ConfigDB)"

    return (Get-DBPrefixDatabaseName -dbName $configDb)
   
}

Configuration AutoInstallerExample
{
    param (
        [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [xml]$autoInstallerXML
    )



    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName SharePointDsc
    
    $passphrase = Get-Passphrase -autoInstallerXML $autoInstallerXML
    $farmAccount = Get-FarmAccount -autoInstallerXML $autoInstallerXML
    $version = Get-Version -autoInstallerXML $autoInstallerXML
    
    $centalAdminNode = Get-CentralAdminServer -autoInstallerXML $autoInstallerXML
    $databaseServer = Get-DatabaseServerName -autoInstallerXML $autoInstallerXML
    
    $configDatabaseName = Get-ConfigDatabaseName -autoInstallerXML $autoInstallerXML
    $adminContentDatabaseName = Get-AdminContentDatabaseName -autoInstallerXML $autoInstallerXML

    $createAlias = Get-DatabaseAlias -autoInstallerXML $autoInstallerXML
    $productKey = Get-ProductKey -autoInstallerXML $autoInstallerXML
    $onlineMode = Get-OnlineInstallMode -autoInstallerXML $autoInstallerXML
   
    node "localhost"
    {       

        #**********************************************************
        # Registry for SQL Alias
        #
        #
        #
        #**********************************************************
        if($createAlias -ne $null) {
            Registry SQLAlias {
                Key = "HKLM\Software\Microsoft\MSSQLServer\Client\ConnectTo"
                ValueType = "String"
                ValueName = "$($createAlias.ValueName)"
                ValueData = "$($createAlias.ValueData)"
            }
        }

        #**********************************************************
        # Install Binaries
        #
        # This section installs SharePoint and its Prerequisites
        # Not sure where the AutoSPInstaller stores this info for a local install modle
        #**********************************************************
        
        
        SPInstallPrereqs InstallPrereqs {
            Ensure            = "Present"
            InstallerPath     = "C:\binaries\prerequisiteinstaller.exe"
            OnlineMode        = $onlineMode
        }

        SPInstall InstallSharePoint {
            Ensure = "Present"
            BinaryDir = "C:\binaries\"
            ProductKey = "$($productKey)"
            DependsOn = "[SPInstallPrereqs]InstallPrereqs"
        }

        #**********************************************************
        # Basic farm configuration
        #
        # This section creates the new SharePoint farm object, and
        # provisions generic services and components used by the
        # whole farm
        #**********************************************************
       
      
            SPCreateFarm CreateSPFarm
            {
                DatabaseServer           = "$($databaseServer)"
                FarmConfigDatabaseName   = "$($configDatabaseName)"
                Passphrase               = $passphrase
                FarmAccount              = $farmAccount
                PsDscRunAsCredential     = $SPSetupAccount
                AdminContentDatabaseName = "$($adminContentDatabaseName)"
                DependsOn                = "[SPInstall]InstallSharePoint"
            }
       
        SPManagedAccount ServicePoolManagedAccount
        {
            AccountName          = $ServicePoolManagedAccount.UserName
            Account              = $ServicePoolManagedAccount
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn            = "[SPCreateFarm]CreateSPFarm"
        }
        SPManagedAccount WebPoolManagedAccount
        {
            AccountName          = $WebPoolManagedAccount.UserName
            Account              = $WebPoolManagedAccount
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn            = "[SPCreateFarm]CreateSPFarm"
        }
        SPDiagnosticLoggingSettings ApplyDiagnosticLogSettings
        {
            PsDscRunAsCredential                        = $SPSetupAccount
            LogPath                                     = "C:\ULS"
            LogSpaceInGB                                = 5
            AppAnalyticsAutomaticUploadEnabled          = $false
            CustomerExperienceImprovementProgramEnabled = $true
            DaysToKeepLogs                              = 7
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
            DependsOn                                   = "[SPCreateFarm]CreateSPFarm"
        }
        SPUsageApplication UsageApplication 
        {
            Name                  = "Usage Service Application"
            DatabaseName          = "SP_Usage"
            UsageLogCutTime       = 5
            UsageLogLocation      = "C:\UsageLogs"
            UsageLogMaxFileSizeKB = 1024
            PsDscRunAsCredential  = $SPSetupAccount
            DependsOn             = "[SPCreateFarm]CreateSPFarm"
        }
        SPStateServiceApp StateServiceApp
        {
            Name                 = "State Service Application"
            DatabaseName         = "SP_State"
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn            = "[SPCreateFarm]CreateSPFarm"
        }
        SPDistributedCacheService EnableDistributedCache
        {
            Name                 = "AppFabricCachingService"
            Ensure               = "Present"
            CacheSizeInMB        = 1024
            ServiceAccount       = $ServicePoolManagedAccount.UserName
            PsDscRunAsCredential = $SPSetupAccount
            CreateFirewallRules  = $true
            DependsOn            = @('[SPCreateFarm]CreateSPFarm','[SPManagedAccount]ServicePoolManagedAccount')
        }

        #**********************************************************
        # Web applications
        #
        # This section creates the web applications in the 
        # SharePoint farm, as well as managed paths and other web
        # application settings
        #**********************************************************

        SPWebApplication SharePointSites
        {
            Name                   = "SharePoint Sites"
            ApplicationPool        = "SharePoint Sites"
            ApplicationPoolAccount = $WebPoolManagedAccount.UserName
            AllowAnonymous         = $false
            AuthenticationMethod   = "NTLM"
            AuthenticationProvider = "Windows Authentication"
            DatabaseName           = "SP_Content"
            Url                    = "http://sites.contoso.com"
            HostHeader             = "sites.contoso.com"
            Port                   = 80
            PsDscRunAsCredential   = $SPSetupAccount
            DependsOn              = "[SPManagedAccount]WebPoolManagedAccount"
        }
        
        SPCacheAccounts WebAppCacheAccounts
        {
            WebAppUrl              = "http://sites.contoso.com"
            SuperUserAlias         = "CONTOSO\SP_SuperUser"
            SuperReaderAlias       = "CONTOSO\SP_SuperReader"
            PsDscRunAsCredential   = $SPSetupAccount
            DependsOn              = "[SPWebApplication]SharePointSites"
        }

        SPSite TeamSite
        {
            Url                      = "http://sites.contoso.com"
            OwnerAlias               = "CONTOSO\SP_Admin"
            Name                     = "DSC Demo Site"
            Template                 = "STS#0"
            PsDscRunAsCredential     = $SPSetupAccount
            DependsOn                = "[SPWebApplication]SharePointSites"
        }


        #**********************************************************
        # Service instances
        #
        # This section describes which services should be running
        # and not running on the server
        #**********************************************************

        SPServiceInstance ClaimsToWindowsTokenServiceInstance
        {  
            Name                 = "Claims to Windows Token Service"
            Ensure               = "Present"
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn            = "[SPCreateFarm]CreateSPFarm"
        }   

        SPServiceInstance SecureStoreServiceInstance
        {  
            Name                 = "Secure Store Service"
            Ensure               = "Present"
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn            = "[SPCreateFarm]CreateSPFarm"
        }
        
        SPServiceInstance ManagedMetadataServiceInstance
        {  
            Name                 = "Managed Metadata Web Service"
            Ensure               = "Present"
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn            = "[SPCreateFarm]CreateSPFarm"
        }

        SPServiceInstance BCSServiceInstance
        {  
            Name                 = "Business Data Connectivity Service"
            Ensure               = "Present"
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn            = "[SPCreateFarm]CreateSPFarm"
        }
        
        SPServiceInstance SearchServiceInstance
        {  
            Name                 = "SharePoint Server Search"
            Ensure               = "Present"
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn            = "[SPCreateFarm]CreateSPFarm"
        }
        
        #**********************************************************
        # Service applications
        #
        # This section creates service applications and required
        # dependencies
        #**********************************************************

        $serviceAppPoolName = "SharePoint Service Applications"
        SPServiceAppPool MainServiceAppPool
        {
            Name                 = $serviceAppPoolName
            ServiceAccount       = $ServicePoolManagedAccount.UserName
            PsDscRunAsCredential = $SPSetupAccount
            DependsOn            = "[SPCreateFarm]CreateSPFarm"
        }

        SPSecureStoreServiceApp SecureStoreServiceApp
        {
            Name                  = "Secure Store Service Application"
            ApplicationPool       = $serviceAppPoolName
            AuditingEnabled       = $true
            AuditlogMaxSize       = 30
            DatabaseName          = "SP_SecureStore"
            PsDscRunAsCredential  = $SPSetupAccount
            DependsOn             = "[SPServiceAppPool]MainServiceAppPool"
        }
        
        SPManagedMetaDataServiceApp ManagedMetadataServiceApp
        {  
            Name                 = "Managed Metadata Service Application"
            PsDscRunAsCredential = $SPSetupAccount
            ApplicationPool      = $serviceAppPoolName
            DatabaseName         = "SP_MMS"
            DependsOn            = "[SPServiceAppPool]MainServiceAppPool"
        }

        SPBCSServiceApp BCSServiceApp
        {
            Name                  = "BCS Service Application"
            ApplicationPool       = $serviceAppPoolName
            DatabaseName          = "SP_BCS"
            PsDscRunAsCredential  = $SPSetupAccount
            DependsOn             = @('[SPServiceAppPool]MainServiceAppPool', '[SPSecureStoreServiceApp]SecureStoreServiceApp')
        }

        SPSearchServiceApp SearchServiceApp
        {  
            Name                  = "Search Service Application"
            DatabaseName          = "SP_Search"
            ApplicationPool       = $serviceAppPoolName
            PsDscRunAsCredential  = $SPSetupAccount
            DependsOn             = "[SPServiceAppPool]MainServiceAppPool"
        }
        
        #**********************************************************
        # Local configuration manager settings
        #
        # This section contains settings for the LCM of the host
        # that this configuraiton is applied to
        #**********************************************************
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }
    }
}


[xml]$autoInstallerXML = Get-Content AutoInstallerInput.xml

