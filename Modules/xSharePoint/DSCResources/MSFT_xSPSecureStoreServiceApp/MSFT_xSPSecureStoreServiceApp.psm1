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

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting secure store service application '$Name'"
    
    $session = Get-xSharePointAuthenticatedPSSession -Credential $InstallAccount

    $result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        $serviceApp = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue |
                        Where-Object { $_.TypeName -eq "Secure Store Service Application" }
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
        [System.Boolean]
        $AuditingEnabled,

        [System.UInt32]
        $AuditlogMaxSize = 30,

        [System.Management.Automation.PSCredential]
        $DatabaseCredentials = $null,

        [System.String]
        $DatabaseName = $null,

        [System.String]
        $DatabasePassword = $null,

        [System.String]
        $DatabaseServer = $null,

        [System.String]
        $DatabaseUsername = $null,

        [System.String]
        $FailoverDatabaseServer = $null,

        [System.Boolean]
        $PartitionMode = $false,

        [System.Boolean]
        $Sharing = $true,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    $result = Get-TargetResource -Name $Name -ApplicationPool $ApplicationPool -AuditingEnabled $AuditingEnabled -InstallAccount $InstallAccount
    $session = Get-xSharePointAuthenticatedPSSession -Credential $InstallAccount
    if ($result.Count -eq 0) { 
        Write-Verbose -Message "Creating Secure Store Service Application $Name"
        Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            $params = Remove-xSharePointNullParamValues -Params $params
            $params.Remove("InstallAccount") | Out-Null

            $app = New-SPSecureStoreServiceApplication @params
            if ($null -ne $app) {
                New-SPSecureStoreServiceApplicationProxy -Name ($params.Name + " Proxy") -ServiceApplication $app
            }
        }
    }
    else {
        if ([string]::IsNullOrEmpty($ApplicationPool) -eq $false -and $ApplicationPool -ne $result.ApplicationPool) {
            Write-Verbose -Message "Updating Secure Store Service Application $Name"
            Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
                $params = $args[0]
                $params = Remove-xSharePointNullParamValues -Params $params
                $params.Remove("Name") | Out-Null
                if ($params.ContainsKey("PartitionMode")) { $params.Remove("PartitionMode") | Out-Null }

                $serviceApp = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue |
                        Where-Object { $_.TypeName -eq "Secure Store Service Application" }
                $serviceApp | Set-SPSecureStoreServiceApplication @params
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

        [System.UInt32]
        $AuditlogMaxSize = 30,

        [System.Management.Automation.PSCredential]
        $DatabaseCredentials = $null,

        [System.String]
        $DatabaseName = $null,

        [System.String]
        $DatabasePassword = $null,

        [System.String]
        $DatabaseServer = $null,

        [System.String]
        $DatabaseUsername = $null,

        [System.String]
        $FailoverDatabaseServer = $null,

        [System.Boolean]
        $PartitionMode = $false,

        [System.Boolean]
        $Sharing = $true,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    $result = Get-TargetResource -Name $Name -ApplicationPool $ApplicationPool -AuditingEnabled $AuditingEnabled -InstallAccount $InstallAccount
    Write-Verbose -Message "Testing secure store service application $Name"
    if ($result.Count -eq 0) { return $false }
    else {
        if ($ApplicationPool -ne $result.ApplicationPool) { return $false }
    }
    return $true
}


Export-ModuleMember -Function *-TargetResource

