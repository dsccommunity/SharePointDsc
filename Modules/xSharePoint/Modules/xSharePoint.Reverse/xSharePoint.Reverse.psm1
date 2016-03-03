<##############################################################
 # This script is used to analyze an existing SharePoint (2010, 2013, 2016 or greater), and to produce the resulting PowerShell DSC Configuration Script representing it. Its purpose is to help SharePoint Admins and Devs replicate an existing SharePoint farm in an isolated area in order to troubleshoot an issue. This script needs to be executed directly on one of the SharePoint server in the far we wish to replicate. Upon finishing its execution, this Powershell script will prompt the user to specify a path to a FOLDER where the resulting PowerShell DSC Configuraton (.ps1) script will be generated. The resulting script will be named "SP-Farm.DSC.ps1" and will contain an exact description, in DSC notation, of the various components and configuration settings of the current SharePoint Farm. This script can then be used in an isolated environment to replicate the SharePoint server farm. The script could also be used as a simple textual (while in a DSC notation format) description of what the configuraton of the SharePoint farm looks like. This script is meant to be community driven, and everyone is encourage to participate and help improve and mature it. It is not officially endorsed by Microsoft, and support is 'offered' on a best effort basis by its contributors. Bugs suggestions should be reported through the issue system on GitHub. They will be looked at as time permits.
 # v0.1 - Nik Charlebois
 ##############################################################>
<## Check to see if the SharePoint PowerShell snapin is already loaded, if not, load it in the current PowerShell session. #>
if ((Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null )
{
    Add-PsSnapin Microsoft.SharePoint.PowerShell
}

<## Scripts Variables #>
$Script:dscConfigContent = ""
$Script:spCentralAdmin = Get-SPWebApplication -IncludeCentralAdministration | Where{$_.DisplayName -like '*Central Administration*'}

<## This is the main function for this script. It acts as a call dispatcher, calling th various functions required in the proper order to get the full farm picture. #>
function Orchestrator{    
    $spFarm = Get-SPFarm
    $spServers = $spFarm.Servers    
    Read-OperatingSystemVersion
    Read-SQLVersion
    Read-SPProductVersions
    $Script:dscConfigContent += "Configuration SharePointFarm`r`n"
    $Script:dscConfigContent += "{`r`n"
    Set-ObtainRequiredCredentials
    Set-Imports
    foreach($spServer in $spServers)
    {
        <## SQL servers are returned by Get-SPServer but they have a Role of 'Invalid'. Therefore we need to ignore these. The resulting PowerShell DSC Configuration script does not take into account the configuration of the SQL server for the SharePoint Farm at this point in time. We are activaly working on giving our users an experience that is as painless as possible, and are planning on integrating the SQL DSC Configuration as part of our feature set. #>
        if($spServer.Role -ne "Invalid")
        {
            $Script:dscConfigContent += "`r`n    node " + $spServer.Name + "{`r`n"    
            Set-ConfigurationSettings    
            Read-SPFarm
            Read-SPWebApplications
            Read-SPManagedPaths
            Read-SPManagedAccounts
            Read-SPServiceApplicationPools
            Read-SPSites
            Read-SPServiceInstance -Server $spServer.Name
            Read-DiagnosticLoggingSettings
            Read-UsageServiceApplication
            Read-StateServiceApplication
            Read-UserProfileServiceapplication
            Read-CacheAccounts
            Read-SecureStoreServiceApplication
            Read-BCSServiceApplication
            Read-SearchServiceApplication
            Read-ManagedMetadataServiceApplication
            Set-LCM
            $Script:dscConfigContent += "    }`r`n"
        }
    }    
    $Script:dscConfigContent += "}"
}

function Read-OperatingSystemVersion
{
    $servers = Get-SPServer
    $Script:dscConfigContent += "<#`r`n    Operating Systems in this Farm`r`n-------------------------------------------`r`n"
    $Script:dscConfigContent += "    Products and Language Packs`r`n"
    $Script:dscConfigContent += "-------------------------------------------`r`n"
    foreach($spServer in $servers)
    {
        $serverName = $spServer.Name
        $osInfo = Get-WmiObject Win32_OperatingSystem  -ComputerName $serverName| Select-Object @{Label="OSName"; Expression={$_.Name.Substring($_.Name.indexof("W"),$_.Name.indexof("|")-$_.Name.indexof("W"))}} , Version ,OSArchitecture
        $Script:dscConfigContent += "    [" + $serverName + "]: " + $osInfo.OSName + "(" + $osInfo.OSArchitecture + ")    ----    " + $osInfo.Version + "`r`n"
    }    
    $Script:dscConfigContent += "#>`r`n`r`n"
}

function Read-SQLVersion
{
    $uniqueServers = @()
    $sqlServers = Get-SPDatabase | select Server -Unique
    foreach($sqlServer in $sqlServers)
    {
        $serverName = $sqlServer.Server.Name

        if($serverName -eq $null)
        {
            $serverName = $sqlServer.Server
        }
        
        if(!($uniqueServers -contains $serverName))
        {
            $sqlVersionInfo = Invoke-SQL -Server $serverName -dbName "Master" -sqlQuery "SELECT @@VERSION AS 'SQLVersion'"
            $uniqueServers += $serverName.ToString()
            $Script:dscConfigContent += "<#`r`n    SQL Server Product Versions Installed on this Farm`r`n-------------------------------------------`r`n"
            $Script:dscConfigContent += "    Products and Language Packs`r`n"
            $Script:dscConfigContent += "-------------------------------------------`r`n"
            $Script:dscConfigContent += "    [" + $serverName + "]: " + $sqlVersionInfo.SQLversion + "`r`n#>`r`n`r`n"
        }
    }
}

<## This function ensure all required Windows Features are properly installed on the server. #>
<# TODO: Replace this by a logic that reads the feature from te actual server and writes them down instead of simply assuming they are required. #>
function Set-ConfigurationSettings
{
    $Script:dscConfigContent += "        xCredSSP CredSSPServer { Ensure = `"Present`"; Role = `"Server`"; } `r`n"
    $Script:dscConfigContent += "        xCredSSP CredSSPClient { Ensure = `"Present`"; Role = `"Client`"; DelegateComputers = `"*." + (Get-WmiObject Win32_ComputerSystem).Domain + "`" }`r`n`r`n"

    $Script:dscConfigContent += "        xWebAppPool RemoveDotNet2Pool         { Name = `".NET v2.0`";            Ensure = `"Absent`" }`r`n"
    $Script:dscConfigContent += "        xWebAppPool RemoveDotNet2ClassicPool  { Name = `".NET v2.0 Classic`";    Ensure = `"Absent`" }`r`n"
    $Script:dscConfigContent += "        xWebAppPool RemoveDotNet45Pool        { Name = `".NET v4.5`";            Ensure = `"Absent`"; }`r`n"
    $Script:dscConfigContent += "        xWebAppPool RemoveDotNet45ClassicPool { Name = `".NET v4.5 Classic`";    Ensure = `"Absent`"; }`r`n"
    $Script:dscConfigContent += "        xWebAppPool RemoveClassicDotNetPool   { Name = `"Classic .NET AppPool`"; Ensure = `"Absent`" }`r`n"
    $Script:dscConfigContent += "        xWebAppPool RemoveDefaultAppPool      { Name = `"DefaultAppPool`";       Ensure = `"Absent`" }`r`n"
    $Script:dscConfigContent += "        xWebSite    RemoveDefaultWebSite      { Name = `"Default Web Site`";     Ensure = `"Absent`"; PhysicalPath = `"C:\inetpub\wwwroot`" }`r`n"
}

<## This function ensures all required DSC Modules are properly loaded into the current PowerShell session. #>
function Set-Imports
{
    $Script:dscConfigContent += "    Import-DscResource -ModuleName PSDesiredStateConfiguration`r`n"
    $Script:dscConfigContent += "    Import-DscResource -ModuleName xSharePoint`r`n"
    $Script:dscConfigContent += "    Import-DscResource -ModuleName xWebAdministration`r`n"
    $Script:dscConfigContent += "    Import-DscResource -ModuleName xCredSSP`r`n"
}

<## This function receives a user name and returns the "Display Name" for that user. This function is primarly used to identify the Farm (System) account. #>
function Check-Credentials([string] $userName)
{
    if($userName -eq $Script:spCentralAdmin.ApplicationPool.ProcessAccount.Name)
    {
        return "`$FarmAccount"
    }
    else
    {
        $userNameParts = $userName.Split('\')
        if($userNameParts.Length -gt 1)
        {
            return "`$Creds" + $userNameParts[1]
        }
        return "`$Creds" + $userName
    }
    return $userName
}

<## This function defines variables of type Credential for the resulting DSC Configuraton Script. Each variable declared in this method will result in the user being prompted to manually input credentials when executing the resulting script. #>
function Set-ObtainRequiredCredentials
{
    # Farm Account
    $spFarmAccount = $Script:spCentralAdmin.ApplicationPool.ProcessAccount.Name
    $requiredCredentials = @($spFarmAccount)
    $managedAccounts = Get-SPManagedAccount
    foreach($managedAccount in $managedAccounts)
    {
        $requiredCredentials += $managedAccounts.UserName
    }

    $spServiceAppPools = Get-SPServiceApplicationPool
    foreach($spServiceAppPool in $spServiceAppPools)
    {
        $requiredCredentials += $spServiceAppPools.ProcessAccount.Name
    }

    $requiredCredentials = $requiredCredentials | Select -Unique

    foreach($account in $requiredCredentials)
    {
        $accountName = $account
        if($account -eq $spFarmAccount)
        {
            $accountName = "FarmAccount"
        }
        else
        {
            $accountParts = $accountName.Split('\')
            if($accountParts.Length -gt 1)
            {
                $accountName = $accountParts[1]
            }
        }
        $Script:dscConfigContent += "    `$Creds" + $accountName + "= Get-Credential -UserName `"" + $account + "`" -Message `"Credentials for " + $account + "`"`r`n"
    }

    $Script:dscConfigContent += "`r`n"
}

<## This function really is optional, but helps provide valuable information about the various software components installed in the current SharePoint farm (i.e. Cummulative Updates, Language Packs, etc.). #>
function Read-SPProductVersions
{    
    $Script:dscConfigContent += "<#`r`n    SharePoint Product Versions Installed on this Farm`r`n-------------------------------------------`r`n"
    $Script:dscConfigContent += "    Products and Language Packs`r`n"
    $Script:dscConfigContent += "-------------------------------------------`r`n"

    $regLoc = Get-ChildItem HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall
    $programs = $regLoc | where-object { $_.PsPath -like "*\Office*" } | foreach {Get-ItemProperty $_.PsPath} 
    $components = $regLoc | where-object { $_.PsPath -like "*1000-0000000FF1CE}" } | foreach {Get-ItemProperty $_.PsPath} 

    foreach($program in $programs)
    { 
        $productCodes = $_.ProductCodes
        $component = @() + ($components |     where-object { $_.PSChildName -like $productCodes } | foreach {Get-ItemProperty $_.PsPath})
        foreach($component in $components)
        {
            $Script:dscConfigContent += "    " + $component.DisplayName + " -- " + $component.DisplayVersion + "`r`n"
        }        
    }
    $Script:dscConfigContent += "#>`r`n"
}

<## This function declares the xSPCreateFarm object required to create the config and admin database for the resulting SharePoint Farm. #>
function Read-SPFarm{
    $spFarm = Get-SPFarm
    $Script:dscConfigContent += "        xSPCreateFarm CreateSPFarm{`r`n"
    $configDB = Get-SPDatabase | Where{$_.TypeName -eq "Configuration Database"}
    $Script:dscConfigContent += "            DatabaseServer=`"" + $configDB.Server.Name + "`"`r`n"
    $Script:dscConfigContent += "            AdminContentDatabaseName=`"" + $Script:spCentralAdmin.ContentDatabases.Name + "`"`r`n"
    $Script:dscConfigContent += "            FarmConfigDatabaseName=`"" + $configDB.Name + "`"`r`n"
    $Script:dscConfigContent += "            Passphrase=`"pass@word1`"`r`n"
    $Script:dscConfigContent += "            FarmAccount=`$FarmAccount`r`n"
    $Script:dscConfigContent += "            PsDscRunAsCredential=`$FarmAccount`r`n"
    $Script:dscConfigContent += "        }`r`n"        
}

<## This function obtains a reference to every Web Application in the farm and declares their properties (i.e. Port, Associated IIS Application Pool, etc.). #>
function Read-SPWebApplications
{
    $spWebApplications = Get-SPWebApplication | Sort-Object -Property Name
    $Script:spCentralAdmin = Get-SPWebapplication -IncludeCentralAdministration | Where{$_.DisplayName -like '*Central Administration*'}

    foreach($spWebApp in $spWebApplications)
    {
        $Script:dscConfigContent += "        xSPWebApplication " + $spWebApp.Name.Replace(" ", "") + "{`r`n"
        $Script:dscConfigContent += "            Name=`"" + $spWebApp.Name + "`"`r`n"
        $Script:dscConfigContent += "            ApplicationPool=`"" + $spWebApp.ApplicationPool.Name + "`"`r`n"
        
        $Script:dscConfigContent += "            ApplicationPoolAccount=" + (Check-Credentials $spWebApplications.ApplicationPool.ProcessAccount.Name) + "`r`n"

        $spAuthProvider = Get-SPAuthenticationProvider -WebApplication $spWebApp.Url -Zone "Default"
        $Script:dscConfigContent += "            AllowAnonymous=`$" + $spAuthProvider.AllowAnonymous + "`r`n"

        if ($spAuthProvider.DisableKerberos -eq $true) { $localAuthMode = "NTLM" } else { $localAuthMode = "Kerberos" }
        $Script:dscConfigContent += "            AuthenticationMethod=`"" + $localAuthMode + "`"`r`n"

        $Script:dscConfigContent += "            DatabaseName=`"" + $spWebApp.ContentDatabases[0].Name + "`"`r`n"
        $Script:dscConfigContent += "            DatabaseServer=`"" + $spWebApp.ContentDatabases[0].Server + "`"`r`n"
        $Script:dscConfigContent += "            Url=`"" + $spWebApp.Url + "`"`r`n"
        $Script:dscConfigContent += "            Port=`"" + (New-Object System.Uri $spWebApp.Url).Port + "`"`r`n"
        $Script:dscConfigContent += "            PsDscRunAsCredential=`$FarmAccount`r`n"
        $Script:dscConfigContent += "        }`r`n"
    }
}

<## This function loops through every IIS Application Pool that are associated with the various existing Service Applications in the SharePoint farm. ##>
function Read-SPServiceApplicationPools
{
    $spServiceAppPools = Get-SPServiceApplicationPool | Sort-Object -Property Name

    foreach($spServiceAppPool in $spServiceAppPools)
    {
        $Script:dscConfigContent += "        xSPServiceAppPool " + $spServiceAppPool.Name.Replace(" ", "") + "`r`n"
        $Script:dscConfigContent += "        {`r`n"
        $Script:dscConfigContent += "            Name=`"" + $spServiceAppPool.Name + "`"`r`n"
        $Script:dscConfigContent += "            ServiceAccount=" + (Check-Credentials $spServiceAppPool.ProcessAccount.Name) + "`r`n"
        $Script:dscConfigContent += "            PsDscRunAsCredential=`$FarmAccount`r`n"
        $Script:dscConfigContent += "            DependsOn=`"[xSPCreateFarm]CreateSPFarm`"`r`n"
        $Script:dscConfigContent += "        }`r`n"
    }
}

<## This function retrieves a list of all site collections, no matter what Web Application they belong to. The Url attribute helps the xSharePoint DSC Resource determine what Web Application they belong to. #>
function Read-SPSites
{
    $spSites = Get-SPSite -Limit All 
    foreach($spsite in $spSites)
    {
        $Script:dscConfigContent += "        xSPSite " + $spSite.RootWeb.Title.Replace(" ", "") + "`r`n"
        $Script:dscConfigContent += "        {`r`n"
        $Script:dscConfigContent += "            Name=`"" + $spSite.RootWeb.Title + "`"`r`n"
        $Script:dscConfigContent += "            OwnerAlias=`"" + $spSite.Owner.DisplayName + "`"`r`n"

        $webTemplate = $spSite.RootWeb.WebTemplate
        $webTemplateId = $spSite.RootWeb.WebTemplateId
        $webTemplateName = Get-SPWebTemplate | where { $_.Name -Like ($webTemplate + '*') -and $_.ID -eq $webTemplateId }
        if($webTemplateName.Length -gt 1)
        {
            $webTemplateName = $webTemplateName[0]
        }

        $Script:dscConfigContent += "            Template=`"" + $webTemplateName.Name + "`"`r`n"
        $Script:dscConfigContent += "            Url=`"" + $spSite.Url + "`"`r`n"
        $Script:dscConfigContent += "            PsDscRunAsCredential=`$FarmAccount`r`n"
        $Script:dscConfigContent += "            DependsOn=`"[xSPWebApplication]" + $spSite.WebApplication.Name.Replace(" ", "") + "`"`r`n"
        $Script:dscConfigContent += "        }`r`n"
    }
}

<## This function generates a list of all Managed Paths, no matter what their associated Web Application is. The xSharePoint DSC Resource uses the WebAppUrl attribute to identify what Web Applicaton they belong to. #>
function Read-SPManagedPaths
{
    $spWebApps = Get-SPWebApplication
    foreach($spWebApp in $spWebApps)
    {
        $spManagedPaths = Get-SPManagedPath -WebApplication $spWebApp.Url | Sort-Object -Property Name
        foreach($spManagedPath in $spManagedPaths)
        {
            if($spManagedPath.Name.Length -gt 0 -and $spManagedPath.Name -ne "sites")
            {
                $Script:dscConfigContent += "        xSPManagedPath " + $spWebApp.Name.Replace(" ", "") + "Path" + $spManagedPath.Name + "`r`n"
                $Script:dscConfigContent += "        {`r`n"
                $Script:dscConfigContent += "            WebAppUrl=`"" + $spWebApp.Url + "`"`r`n"
                $Script:dscConfigContent += "            RelativeUrl=`"" + $spManagedPath.Name + "`"`r`n"
                
                $isExplicit = $false
                if($spManagedPath.PrefixType -eq "ExplicitInclusion")
                {
                    $isExplicit = $true
                }
                $Script:dscConfigContent += "            Explicit=" + $isExplicit + "`r`n"
                
                $Script:dscConfigContent += "            HostHeader=`$false`r`n"
                $Script:dscConfigContent += "            PsDscRunAsCredential=`$FarmAccount`r`n"
                $Script:dscConfigContent += "            DependsOn=`"[xSPWebApplication]" + $spWebApp.Name.Replace(" ", "") + "`"`r`n"
                $Script:dscConfigContent += "        }`r`n"
            }            
        }

        $spManagedPaths = Get-SPManagedPath -HostHeader | Sort-Object -Property Name
        foreach($spManagedPath in $spManagedPaths)
        {
            if($spManagedPath.Name.Length -gt 0 -and $spManagedPath.Name -ne "sites")
            {
                $Script:dscConfigContent += "        xSPManagedPath " + $spWebApp.Name.Replace(" ", "") + "Path" + $spManagedPath.Name + "`r`n"
                $Script:dscConfigContent += "        {`r`n"
                $Script:dscConfigContent += "            WebAppUrl=`"" + $spWebApp.Url + "`"`r`n"
                $Script:dscConfigContent += "            RelativeUrl=`"" + $spManagedPath.Name + "`"`r`n"
                
                $isExplicit = $false
                if($spManagedPath.PrefixType -eq "ExplicitInclusion")
                {
                    $isExplicit = $true
                }
                $Script:dscConfigContent += "            Explicit=" + $isExplicit + "`r`n"
                
                $Script:dscConfigContent += "            HostHeader=`$true`r`n"
                $Script:dscConfigContent += "            PsDscRunAsCredential=`$FarmAccount`r`n"
                $Script:dscConfigContent += "            DependsOn=`"[xSPWebApplication]" + $spWebApp.Name.Replace(" ", "") + "`"`r`n"
                $Script:dscConfigContent += "        }`r`n"
            }            
        }
    }
}

<## This function retrieves all Managed Accounts in the SharePoint Farm. The Account attribute sets the associated credential variable (each managed account is declared as a variable and the user is prompted to Manually enter the credentials when first executing the script. See function "Set-ObtainRequiredCredentials" for more details on how these variales are set. #>
function Read-SPManagedAccounts
{
    $managedAccounts = Get-SPManagedAccount
    foreach($managedAccount in $managedAccounts)
    {
        $Script:dscConfigContent += "        xSPManagedAccount " + (Check-Credentials $managedAccount.Username).Replace("$","") + "`r`n"
        $Script:dscConfigContent += "        {`r`n"
        $Script:dscConfigContent += "            AccountName=`"" + $managedAccount.Username + "`"`r`n"
        $Script:dscConfigContent += "            Account=" + (Check-Credentials $managedAccount.UserName) + "`r`n"
        $Script:dscConfigContent += "            PsDscRunAsCredential=`$FarmAccount`r`n"
        $Script:dscConfigContent += "            DependsOn=`"[xSPCreateFarm]CreateSPFarm`"`r`n"
        $Script:dscConfigContent += "        }`r`n"
    }
}

<## This function retrieves all Services in the SharePoint farm. It does not care if the service is enabled or not. It lists them all, and simply sets the "Ensure" attribute of those that are disabled to "Absent". #>
function Read-SPServiceInstance
{
    param(
       [Parameter(Mandatory=$true)]
        [string]$Server
    )
    $serviceInstances = Get-SPServiceInstance | Where{$_.Server.Name -eq $Server} | Sort-Object -Property TypeName
    foreach($serviceInstance in $serviceInstances)
    {
        if($serviceInstance.TypeName -eq "Distributed Cache")
        {
            $Script:dscConfigContent += "        xSPDistributedCacheService " + $serviceInstance.TypeName.Replace(" ", "") + "Instance`r`n"
            $Script:dscConfigContent += "        {`r`n"
            $Script:dscConfigContent += "            Name=`"" + $serviceInstance.TypeName + "`"`r`n"

            $status = "Present"
            if($serviceInstance.Status -eq "Disabled")
            {
                $status = "Absent"
            }
            $Script:dscConfigContent += "            Ensure=`"" + $status + "`"`r`n"

            Use-CacheCluster
            $cacheHost = Get-CacheHost -ErrorAction SilentlyContinue
            $computerName = ([System.Net.Dns]::GetHostByName($env:computerName)).HostName
            $cacheHostConfig = Get-AFCacheHostConfiguration -ComputerName $computerName -CachePort ($cacheHost | Where-Object { $_.HostName -eq $computerName }).PortNo -ErrorAction SilentlyContinue
            $windowsService = Get-WmiObject "win32_service" -Filter "Name='AppFabricCachingService'"
            $firewallRule = Get-NetFirewallRule -DisplayName "SharePoint Distributed Cache" -ErrorAction SilentlyContinue

            $Script:dscConfigContent += "            CacheSizeInMB=" + $cacheHostConfig.Size + "`r`n"
            $Script:dscConfigContent += "            ServiceAccount=" + (Check-Credentials $windowsService.StartName) + "`r`n"
            $Script:dscConfigContent += "            CreateFirewallRules=`$" + ($firewallRule -ne $null) + "`r`n"
            $Script:dscConfigContent += "            PsDscRunAsCredential=`$FarmAccount`r`n"
            $Script:dscConfigContent += "            DependsOn=@('[xSPCreateFarm]CreateSPFarm','[xSPManagedAccount]" + (Check-Credentials $windowsService.StartName).Replace("$", "") + "')`r`n"
            $Script:dscConfigContent += "        }`r`n"
        }
        elseif($serviceInstance.TypeName -eq "User Profile Synchronization Service")
        {
            $Script:dscConfigContent += "        xSPUserProfileSyncService " + $serviceInstance.TypeName.Replace(" ", "") + "Instance`r`n"
            $Script:dscConfigContent += "        {`r`n"
            $Script:dscConfigContent += "            Name=`"" + $serviceInstance.TypeName + "`"`r`n"

            $status = "Present"
            if($serviceInstance.Status -eq "Disabled")
            {
                $status = "Absent"
            }
            $Script:dscConfigContent += "            Ensure=`"" + $status + "`"`r`n"            
            $Script:dscConfigContent += "            FarmAccount=`$FarmAccount`r`n"
            $Script:dscConfigContent += "            PsDscRunAsCredential=`$FarmAccount`r`n"
            $Script:dscConfigContent += "            DependsOn=@('[xSPCreateFarm]CreateSPFarm','[xSPManagedAccount]" + (Check-Credentials $windowsService.StartName).Replace("$", "") + "')`r`n"
            $Script:dscConfigContent += "        }`r`n"
        }
        else
        {
            $Script:dscConfigContent += "        xSPServiceInstance " + $serviceInstance.TypeName.Replace(" ", "") + "Instance`r`n"
            $Script:dscConfigContent += "        {`r`n"
            $Script:dscConfigContent += "            Name=`"" + $serviceInstance.TypeName + "`"`r`n"

            $status = "Present"
            if($serviceInstance.Status -eq "Disabled")
            {
                $status = "Absent"
            }
            $Script:dscConfigContent += "            Ensure=`"" + $status + "`"`r`n"
            $Script:dscConfigContent += "            PsDscRunAsCredential=`$FarmAccount`r`n"
            $Script:dscConfigContent += "            DependsOn=`"[xSPCreateFarm]CreateSPFarm`"`r`n"
            $Script:dscConfigContent += "        }`r`n"
        }
    }
}

<## This function retrieves all settings related to Diagnostic Logging (ULS logs) on the SharePoint farm. #>
function Read-DiagnosticLoggingSettings
{
    $diagConfig = Get-SPDiagnosticConfig
    $Script:dscConfigContent += "        xSPDiagnosticLoggingSettings ApplyDiagnosticLogSettings`r`n"
    $Script:dscConfigContent += "        {`r`n"
    $Script:dscConfigContent += "            LogPath=`"" + $diagConfig.LogLocation + "`"`r`n"
    $Script:dscConfigContent += "            LogSpaceInGB=" + $diagConfig.LogDiskSpaceUsageGB + "`r`n"
    $Script:dscConfigContent += "            AppAnalyticsAutomaticUploadEnabled=`$" + $diagConfig.AppAnalyticsAutomaticUploadEnabled + "`r`n"
    $Script:dscConfigContent += "            CustomerExperienceImprovementProgramEnabled=`$" + $diagConfig.CustomerExperienceImprovementProgramEnabled + "`r`n"
    $Script:dscConfigContent += "            DaysToKeepLogs=" + $diagConfig.DaysToKeepLogs + "`r`n"
    $Script:dscConfigContent += "            DownloadErrorReportingUpdatesEnabled=`$" + $diagConfig.DownloadErrorReportingUpdatesEnabled + "`r`n"
    $Script:dscConfigContent += "            ErrorReportingAutomaticUploadEnabled=`$" + $diagConfig.ErrorReportingAutomaticUploadEnabled + "`r`n"
    $Script:dscConfigContent += "            ErrorReportingEnabled=`$" + $diagConfig.ErrorReportingEnabled + "`r`n"
    $Script:dscConfigContent += "            EventLogFloodProtectionEnabled=`$" + $diagConfig.EventLogFloodProtectionEnabled + "`r`n"
    $Script:dscConfigContent += "            EventLogFloodProtectionNotifyInterval=" + $diagConfig.EventLogFloodProtectionNotifyInterval + "`r`n"
    $Script:dscConfigContent += "            EventLogFloodProtectionQuietPeriod=" + $diagConfig.EventLogFloodProtectionQuietPeriod + "`r`n"
    $Script:dscConfigContent += "            EventLogFloodProtectionThreshold=" + $diagConfig.EventLogFloodProtectionThreshold + "`r`n"
    $Script:dscConfigContent += "            EventLogFloodProtectionTriggerPeriod=" + $diagConfig.EventLogFloodProtectionTriggerPeriod + "`r`n"
    $Script:dscConfigContent += "            LogCutInterval=" + $diagConfig.LogCutInterval + "`r`n"
    $Script:dscConfigContent += "            LogMaxDiskSpaceUsageEnabled=`$" + $diagConfig.LogMaxDiskSpaceUsageEnabled + "`r`n"
    $Script:dscConfigContent += "            ScriptErrorReportingDelay=" + $diagConfig.ScriptErrorReportingDelay + "`r`n"
    $Script:dscConfigContent += "            ScriptErrorReportingEnabled=`$" + $diagConfig.ScriptErrorReportingEnabled + "`r`n"
    $Script:dscConfigContent += "            ScriptErrorReportingRequireAuth=`$" + $diagConfig.ScriptErrorReportingEnabled + "`r`n"
    $Script:dscConfigContent += "            PsDscRunAsCredential=`$FarmAccount`r`n"
    $Script:dscConfigContent += "            DependsOn=@(`"[xSPCreateFarm]CreateSPFarm`", `"[xDisk]LogsDisk`")`r`n"
    $Script:dscConfigContent += "        }`r`n"
}

<## This function retrieves all settings related to the SharePoint Usage Service Application, assuming it exists. #>
function Read-UsageServiceApplication
{
        $usageApplication = Get-SPUsageApplication
        if($usageApplication.Length -gt 0)
        {
            $Script:dscConfigContent += "        xSPUsageApplication " + $usageApplication.TypeName.Replace(" ", "") + "`r`n"
            $Script:dscConfigContent += "        {`r`n"
            $Script:dscConfigContent += "            Name=`"" + $usageApplication.TypeName + "`"`r`n"
            $Script:dscConfigContent += "            DatabaseName=`"" + $usageApplication.UsageDatabase.Name + "`"`r`n"
            $Script:dscConfigContent += "            DatabaseServer=`"" + $usageApplication.UsageDatabase.Server.Address + "`"`r`n"
            $Script:dscConfigContent += "            UsageLogCutTime=`"" + $usageApplication.Service.UsageLogCutTime + "`"`r`n"
            $Script:dscConfigContent += "            UsageLogLocation=`""  + $usageApplication.Service.UsageLogDir + "`"`r`n"
            $Script:dscConfigContent += "            UsageLogMaxFileSizeKB=" + $usageApplication.Service.UsageLogMaxFileSize + "`r`n"
            $Script:dscConfigContent += "            PsDscRunAsCredential=`$FarmAccount`r`n"
            $Script:dscConfigContent += "        }`r`n"
        }
}

<## This function retrieves settings associated with the State Service Application, assuming it exists. #>
function Read-StateServiceApplication
{
    $stateApplications = Get-SPStateServiceApplication
    foreach($stateApp in $stateApplications)
    {
        if($stateApp -ne $null)
        {
            $Script:dscConfigContent += "        xSPStateServiceApp " + $stateApp.DisplayName.Replace(" ", "") + "`r`n"
            $Script:dscConfigContent += "        {`r`n"
            $Script:dscConfigContent += "            Name=`"" + $stateApp.DisplayName + "`"`r`n"

            $stateDBName = ""
            if($stateApp.Databases.Length -gt 0)
            {
                $stateDBName = $stateApp.Databases.Name
                $Script:dscConfigContent += "            DatabaseServer=`"" + $stateApp.Databases.Server.Address + "`"`r`n"
            }
            $Script:dscConfigContent += "            DatabaseName=`"" + $stateDBName + "`"`r`n"        
            $Script:dscConfigContent += "            PsDscRunAsCredential=`$FarmAccount`r`n"
            $Script:dscConfigContent += "        }`r`n"
        }
    }
}

<## This function retrieves information about all the "Super" accounts (Super Reader & Super User) used for caching. #>
function Read-CacheAccounts
{
    $webApps = Get-SPWebApplication
    foreach($webApp in $webApps)
    {
        $Script:dscConfigContent += "        xSPCacheAccounts " + $webApp.DisplayName.Replace(" ", "") + "CacheAccounts`r`n"
        $Script:dscConfigContent += "        {`r`n"
        $Script:dscConfigContent += "            WebAppUrl=`"" + $webApp.Url + "`"`r`n"
        $Script:dscConfigContent += "            SuperUserAlias=`"" + $webApp.Properties["portalsuperuseraccount"] + "`"`r`n"
        $Script:dscConfigContent += "            SuperReaderAlias=`"" + $webApp.Properties["portalsuperreaderaccount"]  + "`"`r`n"
        $Script:dscConfigContent += "            PsDscRunAsCredential=`$FarmAccount`r`n"
        $Script:dscConfigContent += "            DependsOn=`"[xSPWebApplication]" + $webApp.DisplayName.Replace(" ", "") + "`"`r`n"
        $Script:dscConfigContent += "        }`r`n"
    }
}

<## This function retrieves settings related to the User Profile Service Application. #>
function Read-UserProfileServiceapplication
{
    $ups = Get-SPServiceApplication | Where{$_.TypeName -eq "User Profile Service Application"}

    $sites = Get-SPSite
    if($sites.Length -gt 0)
    {
        $context = Get-SPServiceContext $sites[0]
        try
        {
            $pm = new-object Microsoft.Office.Server.UserProfiles.UserProfileManager($context)
        }
        catch{
            $Script:dscConfigContent += "<# WARNING: It appears the farm account doesn't have Full Control to the User Profile Service Aplication. This is currently preventing the script from determining the exact path for the MySite Host (if configured). Please ensure the Farm account is granted Full Control on the User Profile Service Application. #>"
            Write-Host "WARNING - Farm Account does not have Full Control on the User Profile Service Application." -BackgroundColor Yellow -ForegroundColor Black
        }

        if($ups -ne $null)
        {
            $Script:dscConfigContent += "        xSPUserProfileServiceApp UserProfileServiceApp`r`n"
            $Script:dscConfigContent += "        {`r`n"
            $Script:dscConfigContent += "            Name=`"" + $ups.Name + "`"`r`n"
            $Script:dscConfigContent += "            ApplicationPool=`"" + $ups.ApplicationPool.Name + "`"`r`n"
            $Script:dscConfigContent += "            MySiteHostLocation=`"" + $pm.MySiteHostUrl + "`"`r`n"

            $profileDB = Get-SPDatabase | Where{$_.Type -eq "Microsoft.Office.Server.Administration.ProfileDatabase"}
            $Script:dscConfigContent += "            ProfileDBName=`"" + $profileDB.Name + "`"`r`n"
            $Script:dscConfigContent += "            ProfileDBServer=`"" + $profileDB.Server.Name + "`"`r`n"

            $socialDB = Get-SPDatabase | Where{$_.Type -eq "Microsoft.Office.Server.Administration.SocialDatabase"}
            $Script:dscConfigContent += "            SocialDBName=`"" + $socialDB.Name + "`"`r`n"
            $Script:dscConfigContent += "            SocialDBServer=`"" + $socialDB.Server.Name + "`"`r`n"

            $syncDB = Get-SPDatabase | Where{$_.Type -eq "Microsoft.Office.Server.Administration.SynchronizationDatabase"}
            $Script:dscConfigContent += "            SyncDBName=`"" + $syncDB.Name + "`"`r`n"
            $Script:dscConfigContent += "            SyncDBServer=`"" + $syncDB.Server.Name + "`"`r`n"

            $Script:dscConfigContent += "            FarmAccount=`$FarmAccount`r`n"
            $Script:dscConfigContent += "            PsDscRunAsCredential=`$FarmAccount`r`n"
            $Script:dscConfigContent += "        }`r`n"
        }
    }
}

<## This function retrieves all settings related to the Secure Store Service Application. Currently this function makes a direct call to the Secure Store database on the farm's SQL server to retrieve information about the logging details. There are currently no publicly available hooks in the SharePoint/Office Server Object Model that allow us to do it. This forces the user executing this reverse DSC script to have to install the SQL Server Client components on the server on which they execute the script, which is not a "best practice". #>
<# TODO: Change the logic to extract information about the logging from being a direct SQL call to something that uses the Object Model. #>
function Read-SecureStoreServiceApplication
{
    $ssa = Get-SPServiceApplication | Where{$_.TypeName -eq "Secure Store Service Application"}
    for($i = 0; $i -lt $ssa.Length; $i++)
    {
        $Script:dscConfigContent += "        xSPSecureStoreServiceApp " + $ssa[$i].Name.Replace(" ", "") + "`r`n"
        $Script:dscConfigContent += "        {`r`n"
        $Script:dscConfigContent += "            Name=`"" + "`"`r`n"
        $Script:dscConfigContent += "            ApplicationPool=`"" + $ssa[$i].ApplicationPool.Name + "`"`r`n"
    
        <## This is a little dirty, the only way I have found to retrieve the Audit information is by accessing the database directly; #>
        $ssDB = get-spdatabase | where{$_.Type -eq "Microsoft.Office.SecureStoreService.Server.SecureStoreServiceDatabase"}
        $ssDBServer = $ssDB[$i].Server.Name
        $ssDBName = $ssDB[$i].DisplayName
        $query = "SELECT * FROM SSSConfig"
            
        $queryResults = Invoke-SQL -Server $ssDBServer -dbName $ssDBName -sqlQuery $query
        
        $logTime = $queryResults.PurgeAuditDays        
        $Script:dscConfigContent += "            AuditingEnabled=`$" + $queryResults.EnableAudit + "`r`n"
        $Script:dscConfigContent += "            AuditlogMaxSize=" + $logTime + "`r`n"
        $Script:dscConfigContent += "            DatabaseName=`"" + $ssDBName + "`"`r`n"
        $Script:dscConfigContent += "            PsDscRunAsCredential=`$FarmAccount`r`n"
        $Script:dscConfigContent += "        }`r`n"        
    }
}

<## This function retrieves settings related to the Managed Metadata Service Application. #>
function Read-ManagedMetadataServiceApplication
{
    $mms = Get-SPServiceApplication | Where{$_.TypeName -eq "Managed Metadata Service"}
    if (Get-Command "Get-SPMetadataServiceApplication" -errorAction SilentlyContinue)
    {
        foreach($mmsInstance in $mms)
        {
            if($mmsInstance -ne $null)
            {
                $mmsa = Get-SPMetadataServiceApplication $mmsInstance
                $Script:dscConfigContent += "        xSPManagedMetaDataServiceApp " + $mmsInstance.Name.Replace(" ", "") + "`r`n"
                $Script:dscConfigContent += "        {`r`n"
                $Script:dscConfigContent += "            Name=`"" + $mmsInstance.Name + "`"`r`n"
                $Script:dscConfigContent += "            ApplicationPool=`"" + $mmsInstance.ApplicationPool.Name + "`"`r`n"
                $Script:dscConfigContent += "            DatabaseName=`"" + $mmsa.Database.Name + "`"`r`n"
                $Script:dscConfigContent += "            DatabaseServer=`"" + $mmsa.Database.Server.Name + "`"`r`n"
                $Script:dscConfigContent += "            PsDscRunAsCredential=`$FarmAccount`r`n"
                $Script:dscConfigContent += "        }`r`n"
            }
        }
    }
}

<## This function retrieves settings related to the Business Connectivity Service Application. #>
function Read-BCSServiceApplication
{
    $bcsa = Get-SPServiceApplication | Where{$_.TypeName -eq "Business Data Connectivity Service Application"}
    
    foreach($bcsaInstance in $bcsa)
    {
        if($bcsaInstance -ne $null)
        {
            $Script:dscConfigContent += "        xSPBCSServiceApp " + $bcsaInstance.Name.Replace(" ", "") + "`r`n"
            $Script:dscConfigContent += "        {`r`n"
            $Script:dscConfigContent += "            Name=`"" + $bcsaInstance.Name + "`"`r`n"
            $Script:dscConfigContent += "            ApplicationPool=`"" + $bcsaInstance.ApplicationPool.Name + "`"`r`n"
            $Script:dscConfigContent += "            DatabaseName=`"" + $bcsaInstance.Database.Name + "`"`r`n"
            $Script:dscConfigContent += "            DatabaseServer=`"" + $bcsaInstance.Database.Server.Name + "`"`r`n"
            $Script:dscConfigContent += "            PsDscRunAsCredential=`$FarmAccount`r`n"
            $Script:dscConfigContent += "        }`r`n"        
        }
    }
}

<## This function retrieves settings related to the Search Service Application. #>
function Read-SearchServiceApplication
{
    $searchSA = Get-SPServiceApplication | Where{$_.TypeName -eq "Search Service Application"}
    
    foreach($searchSAInstance in $searchSA)
    {
        if($searchSA -ne $null)
        {
            $Script:dscConfigContent += "        xSPSearchServiceApp " + $searchSAInstance.Name.Replace(" ", "") + "`r`n"
            $Script:dscConfigContent += "        {`r`n"
            $Script:dscConfigContent += "            Name=`"" + $searchSAInstance.Name + "`"`r`n"
            $Script:dscConfigContent += "            ApplicationPool=`"" + $searchSAInstance.ApplicationPool.Name + "`"`r`n"
            $Script:dscConfigContent += "            DatabaseName=`"" + $searchSAInstance.Database.Name + "`"`r`n"
            $Script:dscConfigContent += "            DatabaseServer=`"" + $searchSAInstance.Database.Server.Name + "`"`r`n"
            $Script:dscConfigContent += "            PsDscRunAsCredential=`$FarmAccount`r`n"
            $Script:dscConfigContent += "        }`r`n"  
        }
    }
}

<## This function sets the settings for the Local Configuration Manager (LCM) component on the server we will be configuring using our resulting DSC Configuration script. The LCM component is the one responsible for orchestrating all DSC configuration related activities and processes on a server. This method specifies settings telling the LCM to not hesitate rebooting the server we are configurating automatically if it requires a reboot (i.e. During the SharePoint Prerequisites installation). Setting this value helps reduce the amount of manual interaction that is required to automate the configuration of our SharePoint farm using our resulting DSC Configuration script. #>
function Set-LCM
{
    $Script:dscConfigContent += "        LocalConfigurationManager"  + "`r`n"
    $Script:dscConfigContent += "        {`r`n"
    $Script:dscConfigContent += "            RebootNodeIfNeeded = `$True`r`n"
    $Script:dscConfigContent += "        }`r`n"
}

function Invoke-SQL {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Server,
        [Parameter(Mandatory=$true)]
        [string]$dbName,
        [Parameter(Mandatory=$true)]
        [string]$sqlQuery
    )
 
    $ConnectString="Data Source=${Server}; Integrated Security=SSPI; Initial Catalog=${dbName}"
 
    $Conn= New-Object System.Data.SqlClient.SQLConnection($ConnectString)
    $Command = New-Object System.Data.SqlClient.SqlCommand($sqlQuery,$Conn)
    $Conn.Open()
 
    $Adapter = New-Object System.Data.SqlClient.SqlDataAdapter $Command
    $DataSet = New-Object System.Data.DataSet
    $Adapter.Fill($DataSet) | Out-Null
 
    $Conn.Close()
    $DataSet.Tables
}


<## This method is used to determine if a specific PowerShell cmdlet is available in the current Powershell Session. It is currently used to determine wheter or not the user has access to call the Invoke-SqlCmd cmdlet or if he needs to install the SQL Client coponent first. It simply returns $true if the cmdlet is available to the user, or $false if it is not. #>
function Test-CommandExists
{
    param ($command)

    $errorActionPreference = "stop"
    try {
        if(Get-Command $command)
        {
            return $true
        }
    }
    catch
    {
        return $false
    }
}

<## Call into our main function that is responsible for extracting all the information about our SharePoint farm. #>
Orchestrator

<## Prompts the user to specify the FOLDER path where the resulting PowerShell DSC Configuration Script will be saved. #>
$OutputDSCPath = Read-Host "Output Folder for DSC Configuration"

<## Ensures the path we specify ends with a Slash, in order to make sure the resulting file pathis properly structured. #>
if(!$OutputDSCPath.EndsWith("\") -and !$OutputDSCPath.EndsWith("/"))
{
    $OutputDSCPath += "\"
}

<## Save the content of the resulting DSC Configuration file into a file at the specified path. #>
$OutputDSCPath += "SP-Farm.DSC.ps1"
$Script:dscConfigContent | Out-File $OutputDSCPath
