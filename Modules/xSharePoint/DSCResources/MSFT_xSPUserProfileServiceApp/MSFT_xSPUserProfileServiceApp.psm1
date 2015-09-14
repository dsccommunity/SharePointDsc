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

        [parameter(Mandatory = $false)]
        [System.String]
        $MySiteHostLocation,

        [parameter(Mandatory = $false)]
        [System.String]
        $ProfileDBName,

        [parameter(Mandatory = $false)]
        [System.String]
        $ProfileDBServer,

        [parameter(Mandatory = $false)]
        [System.String]
        $SocialDBName,

        [parameter(Mandatory = $false)]
        [System.String]
        $SocialDBServer,

        [parameter(Mandatory = $false)]
        [System.String]
        $SyncDBName,

        [parameter(Mandatory = $false)]
        [System.String]
        $SyncDBServer,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting user profile service application $Name"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $serviceApp = Get-xSharePointServiceApplication -Name $params.Name -TypeName UserProfile

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
    return $result
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

        [parameter(Mandatory = $false)]
        [System.String]
        $MySiteHostLocation,

        [parameter(Mandatory = $false)]
        [System.String]
        $ProfileDBName,

        [parameter(Mandatory = $false)]
        [System.String]
        $ProfileDBServer,

        [parameter(Mandatory = $false)]
        [System.String]
        $SocialDBName,

        [parameter(Mandatory = $false)]
        [System.String]
        $SocialDBServer,

        [parameter(Mandatory = $false)]
        [System.String]
        $SyncDBName,

        [parameter(Mandatory = $false)]
        [System.String]
        $SyncDBServer,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Creating user profile service application $Name"

    # Add the FarmAccount to the local Administrators group, if it's not already there
    $isLocalAdmin = Test-xSharePointUserIsLocalAdmin -UserName $FarmAccount.UserName

    if (!$isLocalAdmin)
    {
        Add-xSharePointUserToLocalAdmin -UserName $FarmAccount.UserName
    }

    $result = Invoke-xSharePointCommand -Credential $FarmAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        if ($params.ContainsKey("InstallAccount")) { $params.Remove("InstallAccount") | Out-Null }
        $params.Remove("FarmAccount") | Out-Null

        $params = Rename-xSharePointParamValue -params $params -oldName "SyncDBName" -newName "ProfileSyncDBName"
        $params = Rename-xSharePointParamValue -params $params -oldName "SyncDBServer" -newName "ProfileSyncDBServer"

        $serviceApp = Get-xSharePointServiceApplication -Name $params.Name -TypeName UserProfile
        if ($null -eq $serviceApp) { 
            $app = Invoke-xSharePointSPCmdlet -CmdletName "New-SPProfileServiceApplication" -Arguments $params
            if ($null -ne $app) {
                Invoke-xSharePointSPCmdlet -CmdletName "New-SPProfileServiceApplicationProxy" -Arguments @{
                    Name = "$($params.Name) Proxy"
                    ServiceApplication = $app 
                    DefaultProxyGroup = $true
                }
            }
        }
    }

    # Remove the FarmAccount from the local Administrators group, if it was added above
    if (!$isLocalAdmin)
    {
        Remove-xSharePointUserToLocalAdmin -UserName $FarmAccount.UserName
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

        [parameter(Mandatory = $false)]
        [System.String]
        $MySiteHostLocation,

        [parameter(Mandatory = $false)]
        [System.String]
        $ProfileDBName,

        [parameter(Mandatory = $false)]
        [System.String]
        $ProfileDBServer,

        [parameter(Mandatory = $false)]
        [System.String]
        $SocialDBName,

        [parameter(Mandatory = $false)]
        [System.String]
        $SocialDBServer,

        [parameter(Mandatory = $false)]
        [System.String]
        $SyncDBName,

        [parameter(Mandatory = $false)]
        [System.String]
        $SyncDBServer,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    $result = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing for user profile service application $Name"

    if ($result.Count -eq 0) { return $false }
    else {
        if ($ApplicationPool -ne $result.ApplicationPool) { return $false }
    }
    return $true
}

Export-ModuleMember -Function *-TargetResource

