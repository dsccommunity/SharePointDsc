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

	# Remove existing sessions to keep things clean
	Get-PSSession | Where-Object { $_.ComputerName -eq "localhost" -and $_.Runspace.OriginalConnectionInfo.Credential.UserName -eq $Credential.UserName } | Remove-PSSession
	[GC]::Collect()
    
        Write-Verbose -Message "Creating new PowerShell session"
        $session = New-PSSession -ComputerName $env:COMPUTERNAME -Credential $Credential -Authentication CredSSP
        Invoke-Command -Session $session -ScriptBlock {
            if ($null -eq (Get-PSSnapin -Name "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue)) 
            {
                Add-PSSnapin -Name "Microsoft.SharePoint.PowerShell"
            }
        }
        return $session    
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
