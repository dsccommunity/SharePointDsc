#
# xSharePoint.psm1
#
$Script:dscConfigContent = ""
$Script:spCentralAdmin = Get-SPWebapplication -IncludeCentralAdministration | Where{$_.DisplayName -like '*Central Administration*'}

function Read-SPFarm{
	$spFarm = Get-SPFarm
	$spServers = $spFarm.Servers	
	foreach($spServer in $spServers)
	{
		$Script:dscConfigContent += "node " + $spServer.Name + "{`r`n"
		Read-SPWebApplications
		Read-SPManagedPaths
		Read-SPServiceApplicationPools
		Read-SPSites
		$Script:dscConfigContent += "}"
	}
}

function Read-SPWebApplications
{
	$spWebApplications = Get-SPWebApplication
	$Script:spCentralAdmin = Get-SPWebapplication -IncludeCentralAdministration | Where{$_.DisplayName -like '*Central Administration*'}

	foreach($spWebApp in $spWebApplications)
	{
		$Script:dscConfigContent += "    xSPWebApplication " + $spWebApp.Name.Replace(" ", "") + "{`r`n"
		$Script:dscConfigContent += "        Name=`"" + $spWebApp.Name + "`"`r`n"
		$Script:dscConfigContent += "        ApplicationPool=`"" + $spWebApp.ApplicationPool.Name + "`"`r`n"
		$Script:dscConfigContent += "        ApplicationPoolAccount=`"" + $spWebApplications.ApplicationPool.ProcessAccount + "`"`r`n"

		$spAuthProvider = Get-SPAuthenticationProvider -WebApplication $spWebApp.Url -Zone "Default"
		$Script:dscConfigContent += "        AllowAnonymous=`"" + $spAuthProvider.AllowAnonymous + "`"`r`n"

		if ($spAuthProvider.DisableKerberos -eq $true) { $localAuthMode = "NTLM" } else { $localAuthMode = "Kerberos" }
		$Script:dscConfigContent += "        AuthenticationMethod=`"" + $localAuthMode + "`"`r`n"

		$Script:dscConfigContent += "        DatabaseName=`"" + $spWebApp.ContentDatabases[0].Name + "`"`r`n"
		$Script:dscConfigContent += "        DatabaseServer=`"" + $spWebApp.ContentDatabases[0].Server + "`"`r`n"
		$Script:dscConfigContent += "        Url=`"" + $spWebApp.Url + "`"`r`n"
		$Script:dscConfigContent += "        Port=`"" + (New-Object System.Uri $spWebApp.Url).Port + "`"`r`n"
		$Script:dscConfigContent += "        PsDscRunAsCredential=`"" + $Script:spCentralAdmin.ApplicationPool.ProcessAccount.Name + "`"`r`n"
        $Script:dscConfigContent += "        DependsOn=`"[xSPManagedAccount]WebPoolManagedAccount`"`r`n"
		$Script:dscConfigContent += "    }`r`n"
	}
}

function Read-SPServiceApplicationPools
{
	$spServiceAppPools = Get-SPServiceApplicationPool

	foreach($spServiceAppPool in $spServiceAppPools)
	{
		$Script:dscConfigContent += "    xSPServiceAppPool " + $spServiceAppPool.Name.Replace(" ", "") + "{`r`n"
		$Script:dscConfigContent += "        Name=`"" + $spServiceAppPool.Name + "`"`r`n"
		$Script:dscConfigContent += "        ServiceAccount=`"" + $spServiceAppPool.ProcessAccount.Name + "`"`r`n"
		$Script:dscConfigContent += "        PsDscRunAsCredential=`"" + $Script:spCentralAdmin.ApplicationPool.ProcessAccount.Name + "`"`r`n"
		$Script:dscConfigContent += "        DependsOn=`"[xSPCreateFarm]CreateSPFarm`"`r`n"
		$Script:dscConfigContent += "    }`r`n"
	}
}

function Read-SPSites
{
	$spSites = Get-SPSite -Limit All
	foreach($spsite in $spSites)
	{
		$Script:dscConfigContent += "    xSPSite " + $spSite.RootWeb.Title.Replace(" ", "") + "{`r`n"
		$Script:dscConfigContent += "        Name=`"" + $spSite.RootWeb.Title + "`"`r`n"
		$Script:dscConfigContent += "        OwnerAlias=`"" + $spSite.Owner.DisplayName + "`"`r`n"

		$webTemplate = $spSite.RootWeb.WebTemplate
		$webTemplateId = $spSite.RootWeb.WebTemplateId
		$webTemplateName = Get-SPWebTemplate | where { $_.Name -Like ($webTemplate + '*') -and $_.ID -eq $webTemplateId }
		if($webTemplateName.Length -gt 1)
		{
			$webTemplateName = $webTemplateName[0]
		}

		$Script:dscConfigContent += "        Template=`"" + $webTemplateName.Name + "`"`r`n"
		$Script:dscConfigContent += "        Url=`"" + $spSite.Url + "`"`r`n"
		$Script:dscConfigContent += "        PsDscRunAsCredential=`"" + $Script:spCentralAdmin.ApplicationPool.ProcessAccount.Name + "`"`r`n"
		$Script:dscConfigContent += "        DependsOn=`"[xSPWebApplication]" + $spSite.WebApplication.Name.Replace(" ", "") + "`"`r`n"
		$Script:dscConfigContent += "    }`r`n"
	}
}

function Read-SPManagedPaths
{
	$spWebApps = Get-SPWebApplication
	foreach($spWebApp in $spWebApps)
	{
		$spManagedPaths = Get-SPManagedPath -WebApplication $spWebApp.Url
		foreach($spManagedPath in $spManagedPaths)
		{
			if($spManagedPath.Name.Length -gt 0)
			{
				$Script:dscConfigContent += "    xSPManagedPath " + $spWebApp.Name.Replace(" ", "") + "Path" + $spManagedPath.Name + "`r`n"
				$Script:dscConfigContent += "    {`r`n"
				$Script:dscConfigContent += "        WebAppUrl=`"" + $spWebApp.Url + "`"`r`n"
				$Script:dscConfigContent += "        RelativeUrl=`"" + $spManagedPath.Name + "`"`r`n"
				
				$isExplicit = $false
				if($spManagedPath.PrefixType -eq "ExplicitInclusion")
				{
					$isExplicit = $true
				}
				$Script:dscConfigContent += "        Explicit=" + $isExplicit + "`r`n"
				
				$Script:dscConfigContent += "        HostHeader=`$false`r`n"
				$Script:dscConfigContent += "        PsDscRunAsCredential=`"" + $Script:spCentralAdmin.ApplicationPool.ProcessAccount.Name + "`"`r`n"
				$Script:dscConfigContent += "        DependsOn=`"[xSPWebApplication]" + $spWebApp.Name.Replace(" ", "") + "`"`r`n"
				$Script:dscConfigContent += "    }`r`n"
			}			
		}

		$spManagedPaths = Get-SPManagedPath -HostHeader
		foreach($spManagedPath in $spManagedPaths)
		{
			if($spManagedPath.Name.Length -gt 0)
			{
				$Script:dscConfigContent += "    xSPManagedPath " + $spWebApp.Name.Replace(" ", "") + "Path" + $spManagedPath.Name + "`r`n"
				$Script:dscConfigContent += "    {`r`n"
				$Script:dscConfigContent += "        WebAppUrl=`"" + $spWebApp.Url + "`"`r`n"
				$Script:dscConfigContent += "        RelativeUrl=`"" + $spManagedPath.Name + "`"`r`n"
				
				$isExplicit = $false
				if($spManagedPath.PrefixType -eq "ExplicitInclusion")
				{
					$isExplicit = $true
				}
				$Script:dscConfigContent += "        Explicit=" + $isExplicit + "`r`n"
				
				$Script:dscConfigContent += "        HostHeader=`$true`r`n"
				$Script:dscConfigContent += "        PsDscRunAsCredential=`"" + $Script:spCentralAdmin.ApplicationPool.ProcessAccount.Name + "`"`r`n"
				$Script:dscConfigContent += "        DependsOn=`"[xSPWebApplication]" + $spWebApp.Name.Replace(" ", "") + "`"`r`n"
				$Script:dscConfigContent += "    }`r`n"
			}			
		}
	}
}

Read-SPFarm
$Script:dscConfigContent | Out-File "dscresult.txt"