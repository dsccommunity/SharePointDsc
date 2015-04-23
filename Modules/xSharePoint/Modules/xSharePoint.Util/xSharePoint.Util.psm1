function Get-xSharePointAuthenticatedPSSession() {
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true,Position=1)]
		[System.Management.Automation.PSCredential]
		$Credential,

		[parameter(Mandatory = $false,Position=2)]
		[System.Boolean]
		$ForceNewSession
	)

	$session = Get-PSSession | ? { $_.ComputerName -eq "localhost" -and $_.Runspace.OriginalConnectionInfo.Credential.UserName -eq $Credential.UserName}

	if ($session -ne $null -and $ForceNewSession -ne $true) { return $session }
	else
	{
		$session = New-PSSession -ComputerName "localhost" -Credential $Credential -Authentication CredSSP
		Invoke-Command -Session $session -ScriptBlock {
			if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) 
			{
				Add-PSSnapin "Microsoft.SharePoint.PowerShell"
			}
		}
		return $session
	}
}

Export-ModuleMember -Function *