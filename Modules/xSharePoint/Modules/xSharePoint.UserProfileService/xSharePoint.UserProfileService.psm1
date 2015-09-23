function Test-xSharePointUserIsLocalAdmin() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1)]
        [string]
        $UserName
    )

    $domainName = $UserName.Split('\')[0]
    $accountName = $UserName.Split('\')[1]

    return ([ADSI]"WinNT://$($env:computername)/Administrators,group").PSBase.Invoke("Members") | 
        ForEach-Object {$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)} | 
        Where-Object { $_ -eq $accountName }
}

function Add-xSharePointUserToLocalAdmin() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1)]
        [string]
        $UserName
    )

    $domainName = $UserName.Split('\')[0]
    $accountName = $UserName.Split('\')[1]

    Write-Verbose -Message "Adding $domainName\$userName to local admin group"
    ([ADSI]"WinNT://$($env:computername)/Administrators,group").Add("WinNT://$domainName/$accountName") | Out-Null
}

function Remove-xSharePointUserToLocalAdmin() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1)]
        [string]
        $UserName
    )

    $domainName = $UserName.Split('\')[0]
    $accountName = $UserName.Split('\')[1]

    Write-Verbose -Message "Removing $domainName\$userName from local admin group"
    ([ADSI]"WinNT://$($env:computername)/Administrators,group").Remove("WinNT://$domainName/$accountName") | Out-Null
}

function Set-xSharePointUserProfileSyncMachine() {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true,Position=1)]
        [string]
        $UserProfileServiceAppName,

        [parameter(Mandatory = $true,Position=2)]
        [Guid]
        $SyncServiceId,

        [parameter(Mandatory = $true,Position=3)]
        [PSCredential]
        $FarmAccount
    )
    $serviceApps = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue 
    if ($null -eq $serviceApps) { 
        return $null 
    }
    $ups = $serviceApps | Where-Object { $_.TypeName -eq "User Profile Service Application" }
    $ups.SetSynchronizationMachine($env:COMPUTERNAME, $SyncServiceId, $FarmAccount.UserName, $FarmAccount.GetNetworkCredential().Password)
}

Export-ModuleMember -Function *
