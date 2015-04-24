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

    Write-Verbose "Getting user profile service application $Name"
    $session = Get-xSharePointAuthenticatedPSSession $InstallAccount
    $result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        $serviceApp = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue |
                        Where-Object { $_.TypeName -eq "User Profile Service Application" }
        If ($serviceApp -eq $null)
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
        $MySiteHostLocation,

        [System.String]
        $ProfileDBName,

        [System.String]
        $ProfileDBServer,

        [System.String]
        $SocialDBName,

        [System.String]
        $SocialDBServer,

        [System.String]
        $SyncDBName,

        [System.String]
        $SyncDBServer,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose "Creating user profile service application $Name"
    $domainName = $FarmAccount.UserName.Split('\')[0]
    $userName = $FarmAccount.UserName.Split('\')[1]
    $computerName = "$env:computername"

    # Add the FarmAccount to the local Administrators group, if it's not already there
    $isLocalAdmin = ([ADSI]"WinNT://$computerName/Administrators,group").PSBase.Invoke("Members") | 
        %{$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)} | 
        ? { $_ -eq $userName }

    if (!$isLocalAdmin)
    {
        Write-Verbose "Adding $domainName\$userName to local admin group"
        ([ADSI]"WinNT://$computerName/Administrators,group").Add("WinNT://$domainName/$userName") | Out-Null
    }

    $session = Get-xSharePointAuthenticatedPSSession $FarmAccount -ForceNewSession $true
    $result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        $params.Remove("InstallAccount") | Out-Null
        $params.Remove("FarmAccount") | Out-Null

        $params = Rename-xSharePointParamValue $params "SyncDBName" "ProfileSyncDBName"
        $params = Rename-xSharePointParamValue $params "SyncDBServer" "ProfileSyncDBServer"

        $app = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue
        if ($app -eq $null) { 
            $app = New-SPProfileServiceApplication @params
            if ($app -ne $null) {
                New-SPProfileServiceApplicationProxy -Name ($params.Name + " Proxy") -ServiceApplication $app -DefaultProxyGroup
            }
        }
    }

    # Remove the FarmAccount from the local Administrators group, if it was added above
    if (!$isLocalAdmin)
    {
        Write-Verbose "Removing $domainName\$userName from local admin group"
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
        $MySiteHostLocation,

        [System.String]
        $ProfileDBName,

        [System.String]
        $ProfileDBServer,

        [System.String]
        $SocialDBName,

        [System.String]
        $SocialDBServer,

        [System.String]
        $SyncDBName,

        [System.String]
        $SyncDBServer,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    $result = Get-TargetResource -Name $Name -ApplicationPool $ApplicationPool -FarmAccount $FarmAccount -InstallAccount $InstallAccount
    Write-Verbose "Testing for user profile service application $Name"

    if ($result.Count -eq 0) { return $false }
    else {
        if ($ApplicationPool -ne $result.ApplicationPool) { return $false }
    }
    return $true
}

Export-ModuleMember -Function *-TargetResource

