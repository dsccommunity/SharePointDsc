function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $true)]  [System.String] $ApplicationPool,
        [parameter(Mandatory = $true)]  [System.Management.Automation.PSCredential] $FarmAccount,
        [parameter(Mandatory = $false)] [System.String] $MySiteHostLocation,
        [parameter(Mandatory = $false)] [System.String] $ProfileDBName,
        [parameter(Mandatory = $false)] [System.String] $ProfileDBServer,
        [parameter(Mandatory = $false)] [System.String] $SocialDBName,
        [parameter(Mandatory = $false)] [System.String] $SocialDBServer,
        [parameter(Mandatory = $false)] [System.String] $SyncDBName,
        [parameter(Mandatory = $false)] [System.String] $SyncDBServer,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
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
            $propData = $serviceApp.GetType().GetProperties([System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)

            $socialProp = $propData | Where-Object {$_.Name -eq "SocialDatabase"}
            $socialDB = $socialProp.GetValue($serviceApp)

            $profileProp = $propData | Where-Object {$_.Name -eq "ProfileDatabase"}
            $profileDB = $profileProp.GetValue($serviceApp)

            $syncProp = $propData | Where-Object {$_.Name -eq "SynchronizationDatabase"}
            $syncDB = $syncProp.GetValue($serviceApp)

            $spFarm = Invoke-xSharePointSPCmdlet -CmdletName "Get-SPFarm"

            if ($params.FarmAccount.UserName -eq $spFarm.DefaultServiceAccount.Name) {
                $farmAccount = $params.FarmAccount
            } else {
                $farmAccount = $spFarm.DefaultServiceAccount.Name
            }

            return @{
                Name = $serviceApp.DisplayName
                ApplicationPool = $serviceApp.ApplicationPool.Name
                FarmAccount = $farmAccount
                MySiteHostLocation = $params.MySiteHostLocation
                ProfileDBName = $profileProp.Name
                ProfileDBServer = $profileProp.Server.Name
                SocialDBName = $socialDB.Name
                SocialDBServer = $socialDB.Server.Name
                SyncDBName = $syncDB.Name
                SyncDBServer = $syncDB.Server.Name
                InstallAccount = $params.InstallAccount
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
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $true)]  [System.String] $ApplicationPool,
        [parameter(Mandatory = $true)]  [System.Management.Automation.PSCredential] $FarmAccount,
        [parameter(Mandatory = $false)] [System.String] $MySiteHostLocation,
        [parameter(Mandatory = $false)] [System.String] $ProfileDBName,
        [parameter(Mandatory = $false)] [System.String] $ProfileDBServer,
        [parameter(Mandatory = $false)] [System.String] $SocialDBName,
        [parameter(Mandatory = $false)] [System.String] $SocialDBServer,
        [parameter(Mandatory = $false)] [System.String] $SyncDBName,
        [parameter(Mandatory = $false)] [System.String] $SyncDBServer,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
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
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $true)]  [System.String] $ApplicationPool,
        [parameter(Mandatory = $true)]  [System.Management.Automation.PSCredential] $FarmAccount,
        [parameter(Mandatory = $false)] [System.String] $MySiteHostLocation,
        [parameter(Mandatory = $false)] [System.String] $ProfileDBName,
        [parameter(Mandatory = $false)] [System.String] $ProfileDBServer,
        [parameter(Mandatory = $false)] [System.String] $SocialDBName,
        [parameter(Mandatory = $false)] [System.String] $SocialDBServer,
        [parameter(Mandatory = $false)] [System.String] $SyncDBName,
        [parameter(Mandatory = $false)] [System.String] $SyncDBServer,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing for user profile service application $Name"
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("ApplicationPool")
}

Export-ModuleMember -Function *-TargetResource

