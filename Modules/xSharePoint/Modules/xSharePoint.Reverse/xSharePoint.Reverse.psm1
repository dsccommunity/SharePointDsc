#
# xSharePoint.psm1
#
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
		Read-SPServiceApplicationPools
		Read-SPSites
		Read-SPServiceInstance
		Read-DiagnosticLoggingSettings
		Set-LCM
		$Script:dscConfigContent += "    }`r`n"
	}	
	$Script:dscConfigContent += "}"
}

function Set-ConfigurationSettings
{
	$Script:dscConfigContent += "    xCredSSP CredSSPServer { Ensure = `"Present`"; Role = `"Server`"; } `r`n"
    $Script:dscConfigContent += "    xCredSSP CredSSPClient { Ensure = `"Present`"; Role = `"Client`"; DelegateComputers = `"*." + (Get-WmiObject Win32_ComputerSystem).Domain + "`" }`r`n`r`n"

	$Script:dscConfigContent += "    xWebAppPool RemoveDotNet2Pool         { Name = `".NET v2.0`";            Ensure = `"Absent`" }`r`n"
    $Script:dscConfigContent += "    xWebAppPool RemoveDotNet2ClassicPool  { Name = `".NET v2.0 Classic`";    Ensure = `"Absent`" }`r`n"
    $Script:dscConfigContent += "    xWebAppPool RemoveDotNet45Pool        { Name = `".NET v4.5`";            Ensure = `"Absent`"; }`r`n"
    $Script:dscConfigContent += "    xWebAppPool RemoveDotNet45ClassicPool { Name = `".NET v4.5 Classic`";    Ensure = `"Absent`"; }`r`n"
    $Script:dscConfigContent += "    xWebAppPool RemoveClassicDotNetPool   { Name = `"Classic .NET AppPool`"; Ensure = `"Absent`" }`r`n"
    $Script:dscConfigContent += "    xWebAppPool RemoveDefaultAppPool      { Name = `"DefaultAppPool`";       Ensure = `"Absent`" }`r`n"
    $Script:dscConfigContent += "    xWebSite    RemoveDefaultWebSite      { Name = `"Default Web Site`";     Ensure = `"Absent`"; PhysicalPath = `"C:\inetpub\wwwroot`" }`r`n"
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
	if($userName -and $Script:spCentralAdmin.ApplicationPool.ProcessAccount.Name)
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
	$Script:dscConfigContent += "        xSPCreateFarm " + $spFarm.Name.Replace(" ", "") + "{`r`n"
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
		$Script:dscConfigContent += "        xSPServiceAppPool " + $spServiceAppPool.Name.Replace(" ", "") + "{`r`n"
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
		$Script:dscConfigContent += "        xSPSite " + $spSite.RootWeb.Title.Replace(" ", "") + "{`r`n"
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
	$managedAccounts = Get-SPManagedAccout
	foreach($managedAccount in $managedAccounts)
	{
		$Script:dscConfigContent += "        xSPManagedAccount " + $managedAccount.Name + "`r`n"
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
		$Script:dscConfigContent += "        xSPServiceInstance " + $serviceInstance.TypeName.Replace(" ", "") + "`r`n"
		$Script:dscConfigContent += "        {`r`n"
		$Script:dscConfigContent += "            Name=`"" + $serviceInstance.TypeName + "`"`r`n"

		$status = "Present"
		if($serviceInstances.Status -eq "Disabled")
		{
			$status = "Absent"
		}
		$Script:dscConfigContent += "            Ensure=`"" + $status + "`"`r`n"
		$Script:dscConfigContent += "            PsDscRunAsCredential=`$FarmAccount`r`n"
		$Script:dscConfigContent += "            DependsOn=`"[xSPCreateFarm]CreateSPFarm`"`r`n"
		$Script:dscConfigContent += "        }`r`n"
	}
}

function Read-DiagnosticLoggingSettings
{
	$diagConfig = Get-SPDiagnosticConfig
	$Script:dscConfigContent += "        xSPDiagnosticLoggingSettings ApplyDiagnosticLogSettings`r`n"
	$Script:dscConfigContent += "        {`r`n"
    $Script:dscConfigContent += "            LogPath=`"" + $diagConfig.LogPath + "`"`r`n"
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

function Set-LCM
{
	$Script:dscConfigContent += "        LocalConfigurationManager"  + "`r`n"
	$Script:dscConfigContent += "        {`r`n"
	$Script:dscConfigContent += "            RebootNodeIfNeeded = `$true`r`n"
	$Script:dscConfigContent += "        }`r`n"
}

Orchestrator
$Script:dscConfigContent | Out-File "SP-Farm.DSC.ps1"