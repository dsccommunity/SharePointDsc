#
# xSharePoint.psm1
#
$dscConfigcontent = ""
function Read-SPFarm{
	$spFarm = Get-SPFarm
	$spServers = $spFarm.Servers	
	foreach($spServer in $spServers)
	{
		$dscConfigcontent += "node " + $spServer.Name + "{`n"
		Read-SPWebApplications
		$dscConfigContent += "}`n"
	}
}

function Read-SPWebApplications
{
	$spWebApplications = Get-SPWebApplication
	$spCentralAdmin = Get-SPWebapplication -IncludeCentralAdministration | Where{$_.DisplayName -like '*Central Administration*'}

	foreach($spWebApp in $spWebApplications)
	{
		$dscConfigcontent += "xSPWebApplication " + $spWebApp.Name.Replace(" ", "") + "{`n"
		$dscConfigcontent += "    Name=" + $spWebApp.Name + "`n"
		$dscConfigcontent += "    ApplicationPool=" + $spWebApp.ApplicationPool.Name + "`n"
		$dscConfigContent += "    ApplicationPoolAccount=" + $spWebApplications.ApplicationPool.ProcessAccount + "`n"

		$spAuthProvider = Get-SPAuthenticationProvider -WebApplication $spWebApp.Url -Zone "Default"
		$dscConfigContent += "    AllowAnonymous=" + $spAuthProvider.AllowAnonymous + "`n"

		if ($spAuthProvider.DisableKerberos -eq $true) { $localAuthMode = "NTLM" } else { $localAuthMode = "Kerberos" }
		$dscconfigContent += "    AuthenticationMethod=" + $localAuthMode + "`n"

		$dscConfigcontent += "    DatabaseName=" + $spWebApp.ContentDatabases[0].Name + "`n"
		$dscConfigContent += "    DatabaseServer=" + $spWebApp.ContentDatabases[0].Server + "`n"
		$dscConfigContent += "    Url=" + $spWebApp.Url + "`n"
		$dscConfigContent += "    Port=" + (New-Object System.Uri $wa.Url).Port + "`n"
		$dscConfigcontent += "    PsDscRunAsCredential=" + $spCentralAdmin.ApplicationPool.ProcessAccount + "`n"
        $dscConfigContent += "    DependsOn=[xSPManagedAccount]WebPoolManagedAccount`n"
		$dscConfigcontent += "}`n"
	}
}
