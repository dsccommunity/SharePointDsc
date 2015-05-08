function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $FarmAccount,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting user profile service application $Name"
    $session = Get-xSharePointAuthenticatedPSSession -Credential $InstallAccount
    $result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        $serviceApp = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue |
                        Where-Object { $_.TypeName -eq "User Profile Service Application" }
        If ($null -eq $serviceApp)
        {
            return @{}
        }
        else
        {
            return @{
                Name = $serviceApp.DisplayName
                ApplicationPool = $serviceApp.ApplicationPool.Name
            }
        }
    }
    $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $FarmAccount,

        [System.String]
        $MySiteHostLocation = $null,

        [System.String]
        $ProfileDBName = $null,

        [System.String]
        $ProfileDBServer = $null,

        [System.String]
        $SocialDBName = $null,

        [System.String]
        $SocialDBServer = $null,

        [System.String]
        $SyncDBName = $null,

        [System.String]
        $SyncDBServer = $null,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Creating user profile service application $Name"
    $domainName = $FarmAccount.UserName.Split('\')[0]
    $userName = $FarmAccount.UserName.Split('\')[1]
    $computerName = "$env:computername"

    # Add the FarmAccount to the local Administrators group, if it's not already there
    $isLocalAdmin = ([ADSI]"WinNT://$computerName/Administrators,group").PSBase.Invoke("Members") | 
        ForEach-Object {$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)} | 
        Where-Object { $_ -eq $userName }

    if (!$isLocalAdmin)
    {
        Write-Verbose -Message "Adding $domainName\$userName to local admin group"
        ([ADSI]"WinNT://$computerName/Administrators,group").Add("WinNT://$domainName/$userName") | Out-Null
    }

    $session = Get-xSharePointAuthenticatedPSSession -Credential $FarmAccount -ForceNewSession $true
    $result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        $params = Remove-xSharePointNullParamValues -Params $params
        $params.Remove("InstallAccount") | Out-Null
        $params.Remove("FarmAccount") | Out-Null

        $params = Rename-xSharePointParamValue -params $params -oldName "SyncDBName" -newName "ProfileSyncDBName"
        $params = Rename-xSharePointParamValue -params $params -oldName "SyncDBServer" -newName "ProfileSyncDBServer"

        $app = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue
        if ($null -eq $app) { 
            $app = New-SPProfileServiceApplication @params
            if ($null -ne $app) {
                New-SPProfileServiceApplicationProxy -Name ($params.Name + " Proxy") -ServiceApplication $app -DefaultProxyGroup
            }
        }
    }

    # Remove the FarmAccount from the local Administrators group, if it was added above
    if (!$isLocalAdmin)
    {
        Write-Verbose -Message "Removing $domainName\$userName from local admin group"
        ([ADSI]"WinNT://$computerName/Administrators,group").Remove("WinNT://$domainName/$userName") | Out-Null
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $FarmAccount,

        [System.String]
        $MySiteHostLocation = $null,

        [System.String]
        $ProfileDBName = $null,

        [System.String]
        $ProfileDBServer = $null,

        [System.String]
        $SocialDBName = $null,

        [System.String]
        $SocialDBServer = $null,

        [System.String]
        $SyncDBName = $null,

        [System.String]
        $SyncDBServer = $null,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    $result = Get-TargetResource -Name $Name -ApplicationPool $ApplicationPool -FarmAccount $FarmAccount -InstallAccount $InstallAccount
    Write-Verbose -Message "Testing for user profile service application $Name"

    if ($result.Count -eq 0) { return $false }
    else {
        if ($ApplicationPool -ne $result.ApplicationPool) { return $false }
    }
    return $true
}

Export-ModuleMember -Function *-TargetResource

