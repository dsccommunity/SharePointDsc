if ( (Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null )
{
    Add-PsSnapin Microsoft.SharePoint.PowerShell
}

$Script:dscConfigContent = ""
$Script:spCentralAdmin = Get-SPWebapplication -IncludeCentralAdministration | Where{$_.DisplayName -like '*Central Administration*'}

function Orchestrator{	
	$spFarm = Get-SPFarm
	$spServers = $spFarm.Servers	
	Read-SPProductVersions
	$Script:dscConfigContent += "Configuration SharePointFarm`r`n"
	$Script:dscConfigContent += "{`r`n"
	Set-ObtainRequiredCredentials
	Set-Imports
	foreach($spServer in $spServers)
	{
		$Script:dscConfigContent += "`r`n    node " + $spServer.Name + "{`r`n"	
		Set-ConfigurationSettings	
		Read-SPFarm
		Read-SPWebApplications
		Read-SPManagedPaths
		Read-SPManagedAccounts
		Read-SPServiceApplicationPools
		Read-SPSites
		Read-SPServiceInstance
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
	$Script:dscConfigContent += "}"
}

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

function Set-Imports
{
	$Script:dscConfigContent += "    Import-DscResource -ModuleName PSDesiredStateConfiguration`r`n"
    $Script:dscConfigContent += "    Import-DscResource -ModuleName xSharePoint`r`n"
    $Script:dscConfigContent += "    Import-DscResource -ModuleName xWebAdministration`r`n"
    $Script:dscConfigContent += "    Import-DscResource -ModuleName xCredSSP`r`n"
}

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
		$component = @() + ($components | 	where-object { $_.PSChildName -in $productCodes } | foreach {Get-ItemProperty $_.PsPath})
		foreach($component in $components)
		{
	        $Script:dscConfigContent += "    " + $component.DisplayName + " -- " + $component.DisplayVersion + "`r`n"
		}		
	}
	$Script:dscConfigContent += "#>`r`n"
}

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

function Read-SPServiceInstance
{
	$serviceInstances = Get-SPServiceInstance | Sort-Object -Property TypeName
	foreach($serviceInstance in $serviceInstances)
	{
		if($serviceInstance.TypeName -eq "Distributed Cache")
		{
			$Script:dscConfigContent += "        xSPDistributedCacheService " + $serviceInstance.TypeName.Replace(" ", "") + "`r`n"
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
			$Script:dscConfigContent += "        xSPUserProfileSyncService " + $serviceInstance.TypeName.Replace(" ", "") + "`r`n"
			$Script:dscConfigContent += "        {`r`n"
			$Script:dscConfigContent += "            Name=`"" + $serviceInstance.TypeName + "`"`r`n"

			$status = "Present"
			if($serviceInstance.Status -eq "Disabled")
			{
				$status = "Absent"
			}
			$Script:dscConfigContent += "            Ensure=`"" + $status + "`"`r`n"			
			$Script:dscConfigContent += "            FramAccount=`$FarmAccount`r`n"
			$Script:dscConfigContent += "            PsDscRunAsCredential=`$FarmAccount`r`n"
			$Script:dscConfigContent += "            DependsOn=@('[xSPCreateFarm]CreateSPFarm','[xSPManagedAccount]" + (Check-Credentials $windowsService.StartName).Replace("$", "") + "')`r`n"
			$Script:dscConfigContent += "        }`r`n"
		}
		else
		{
			$Script:dscConfigContent += "        xSPServiceInstance " + $serviceInstance.TypeName.Replace(" ", "") + "`r`n"
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

function Read-StateServiceApplication
{
	$stateApplications = Get-SPStateServiceApplication
	foreach($stateApp in $stateApplications)
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

function Read-UserProfileServiceapplication
{
	$ups = Get-SPServiceApplication | Where{$_.TypeName -eq "User Profile Service Application"}

	$sites = Get-SPSite
	if($sites.Length -gt 0)
	{
		$context = Get-SPServiceContext $sites[0]
		$pm = new-object Microsoft.Office.Server.UserProfiles.UserProfileManager($context)

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

		Push-Location
		$queryResults = Invoke-SqlCmd -Query "SELECT * FROM SSSConfig" -ServerInstance $ssDBServer -Database $ssDBName
		Pop-Location

		$logTime = $queryResults.PurgeAuditDays		
		$Script:dscConfigContent += "            AuditingEnabled=`$" + $queryResults.EnableAudit + "`r`n"
		$Script:dscConfigContent += "            AuditlogMaxSize=" + $logTime + "`r`n"
		$Script:dscConfigContent += "            DatabaseName=`"" + $ssDBName + "`"`r`n"
		$Script:dscConfigContent += "            PsDscRunAsCredential=`$FarmAccount`r`n"
		$Script:dscConfigContent += "        }`r`n"		
	}
}

function Read-ManagedMetadataServiceApplication
{
	$mms = Get-SPServiceApplication | Where{$_.TypeName -eq "Managed Metadata Service"}
	if (Get-Command "Get-SPMetadataServiceApplication" -errorAction SilentlyContinue)
    {
		foreach($mmsInstance in $mms)
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

function Read-BCSServiceApplication
{
    $bcsa = Get-SPServiceApplication | Where{$_.TypeName -eq "Business Data Connectivity Service Application"}
	
	foreach($bcsaInstance in $bcsa)
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

function Read-SearchServiceApplication
{
    $searchSA = Get-SPServiceApplication | Where{$_.TypeName -eq "Search Service Application"}
	
	foreach($searchSAInstance in $searchSA)
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

function Set-LCM
{
	$Script:dscConfigContent += "        LocalConfigurationManager"  + "`r`n"
	$Script:dscConfigContent += "        {`r`n"
	$Script:dscConfigContent += "            RebootNodeIfNeeded = `$True`r`n"
	$Script:dscConfigContent += "        }`r`n"
}

Orchestrator
$OutputDSCPath = Read-Host "Output Folder for DSC Configuration: "
if(!$OutputDSCPath.EndsWith("\") -and !$OutputDSCPath.EndsWith("/"))
{
	$OutputDSCPath += "\"
}
$OutputDSCPath += "SP-Farm.DSC.ps1"
$Script:dscConfigContent | Out-File $OutputDSCPath
