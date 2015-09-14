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
        [System.Boolean]
        $AuditingEnabled,

        [parameter(Mandatory = $false)]
        [System.UInt32]
        $AuditlogMaxSize,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabaseName,

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabasePassword,

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabaseServer,

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabaseUsername,

        [parameter(Mandatory = $false)]
        [System.String]
        $FailoverDatabaseServer,

        [parameter(Mandatory = $false)]
        [System.Boolean]
        $PartitionMode,

        [parameter(Mandatory = $false)]
        [System.Boolean]
        $Sharing,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting secure store service application '$Name'"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $serviceApp = Get-xSharePointServiceApplication -Name $params.Name -TypeName SecureStore

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
        [System.Boolean]
        $AuditingEnabled,

        [parameter(Mandatory = $false)]
        [System.UInt32]
        $AuditlogMaxSize,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabaseName,

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabasePassword,

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabaseServer,

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabaseUsername,

        [parameter(Mandatory = $false)]
        [System.String]
        $FailoverDatabaseServer,

        [parameter(Mandatory = $false)]
        [System.Boolean]
        $PartitionMode,

        [parameter(Mandatory = $false)]
        [System.Boolean]
        $Sharing,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    $result = Get-TargetResource @PSBoundParameters

    if ($result.Count -eq 0) { 
        Write-Verbose -Message "Creating Secure Store Service Application $Name"
        Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            if ($params.ContainsKey("InstallAccount")) { $params.Remove("InstallAccount") | Out-Null }

            $app = Invoke-xSharePointSPCmdlet -CmdletName "New-SPSecureStoreServiceApplication" -Arguments $params
            if ($app) {
                Invoke-xSharePointSPCmdlet -CmdletName "New-SPSecureStoreServiceApplicationProxy" -Arguments @{ 
                    Name = "$($params.Name) Proxy"
                    ServiceApplication = $app
                }
            }
        }
    } else {
        if ([string]::IsNullOrEmpty($ApplicationPool) -eq $false -and $ApplicationPool -ne $result.ApplicationPool) {
            Write-Verbose -Message "Updating Secure Store Service Application $Name"
            Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
                $params = $args[0]

                $serviceApp = Get-xSharePointServiceApplication -Name $params.Name -TypeName SecureStore
                Invoke-xSharePointSPCmdlet -CmdletName "Set-SPSecureStoreServiceApplication" -Arguments @{
                    Identity = $serviceApp
                    ApplicationPool = (Invoke-xSharePointSPCmdlet -CmdletName "Get-SPServiceApplicationPool" -Arguments @{ Identity = $params.ApplicationPool } )
                }
            }
        }
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
        [System.Boolean]
        $AuditingEnabled,

        [parameter(Mandatory = $false)]
        [System.UInt32]
        $AuditlogMaxSize,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabaseName,

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabasePassword,

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabaseServer,

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabaseUsername,

        [parameter(Mandatory = $false)]
        [System.String]
        $FailoverDatabaseServer,

        [parameter(Mandatory = $false)]
        [System.Boolean]
        $PartitionMode,

        [parameter(Mandatory = $false)]
        [System.Boolean]
        $Sharing,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    $result = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing secure store service application $Name"
    if ($result.Count -eq 0) { return $false }
    else {
        if ($ApplicationPool -ne $result.ApplicationPool) { return $false }
    }
    return $true
}


Export-ModuleMember -Function *-TargetResource

