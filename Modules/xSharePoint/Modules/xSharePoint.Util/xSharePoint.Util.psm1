function Get-xSharePointAuthenticatedPSSession() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1)]
        [System.Management.Automation.PSCredential]
        $Credential,

        [parameter(Mandatory = $false,Position=2)]
        [System.Boolean]
        $ForceNewSession = $false
    )

	[GC]::Collect()

    # Remove existing sessions to keep things clean
    $session = Get-PSSession -ComputerName localhost -Name "Microsoft.SharePoint.DSC"
	if ($ForceNewSession -or $session -eq $null) {
        Write-Verbose -Message "Creating new PowerShell session"
        $session = New-PSSession -ComputerName $env:COMPUTERNAME -Credential $Credential -Authentication CredSSP -Name "Microsoft.SharePoint.DSC" -SessionOption (New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck -OperationTimeout 0 -IdleTimeout 60000)
        Invoke-Command -Session $session -ScriptBlock {
            if ($null -eq (Get-PSSnapin -Name "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue)) 
            {
                Add-PSSnapin -Name "Microsoft.SharePoint.PowerShell"
            }
        }
        return $session    
	} else {
		Write-Verbose -Message "Using existing new PowerShell session"
		return $session[0]
	}
}

function Rename-xSharePointParamValue() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1)]
        $params,

        [parameter(Mandatory = $true,Position=2)]
        $oldName,

        [parameter(Mandatory = $true,Position=3)]
        $newName
    )

    if ($params.ContainsKey($oldName)) {
        $params.Add($newName, $params.$oldName)
        $params.Remove($oldName) | Out-Null
    }
    return $params
}

function Remove-xSharePointNullParamValues() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1)]
        $Params
    )
    $keys = $Params.Keys
    ForEach ($key in $keys) {
        if ($null -eq $Params.$key) {
            $Params.Remove($key) | Out-Null
        }
    }
    return $Params
}

function Get-xSharePointAssemblyVerion() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1)]
        $PathToAssembly
    )
    return (Get-Command $PathToAssembly).Version
}

Export-ModuleMember -Function *
