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

    Write-Verbose "Getting secure store service application '$Name'"
    
    $session = Get-xSharePointAuthenticatedPSSession $InstallAccount

    $result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        $serviceApp = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue |
                        Where-Object { $_.TypeName -eq "Secure Store Service Application" }
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
        [System.Boolean]
        $AuditingEnabled,

        [System.UInt32]
        $AuditlogMaxSize,

        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [System.String]
        $DatabaseName,

        [System.String]
        $DatabasePassword,

        [System.String]
        $DatabaseServer,

        [System.String]
        $DatabaseUsername,

        [System.String]
        $FailoverDatabaseServer,

        [System.Boolean]
        $PartitionMode,

        [System.Boolean]
        $Sharing,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    $result = Get-TargetResource -Name $Name -ApplicationPool $ApplicationPool -AuditingEnabled $AuditingEnabled -InstallAccount $InstallAccount
    $session = Get-xSharePointAuthenticatedPSSession $InstallAccount
    if ($result.Count -eq 0) { 
        Write-Verbose "Creating Secure Store Service Application $Name"
        Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            $params.Remove("InstallAccount") | Out-Null

            $app = New-SPSecureStoreServiceApplication @params
            if ($app -ne $null) {
                New-SPSecureStoreServiceApplicationProxy -Name ($params.Name + " Proxy") -ServiceApplication $app
            }
        }
    }
    else {
        if ([string]::IsNullOrEmpty($ApplicationPool) -eq $false -and $ApplicationPool -ne $result.ApplicationPool) {
            Write-Verbose "Updating Secure Store Service Application $Name"
            Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
                $params = $args[0]

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
        $AuditlogMaxSize,

        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [System.String]
        $DatabaseName,

        [System.String]
        $DatabasePassword,

        [System.String]
        $DatabaseServer,

        [System.String]
        $DatabaseUsername,

        [System.String]
        $FailoverDatabaseServer,

        [System.Boolean]
        $PartitionMode,

        [System.Boolean]
        $Sharing,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    $result = Get-TargetResource -Name $Name -ApplicationPool $ApplicationPool -AuditingEnabled $AuditingEnabled -InstallAccount $InstallAccount
    Write-Verbose "Testing secure store service application $Name"
    if ($result.Count -eq 0) { return $false }
    else {
        if ($ApplicationPool -ne $result.ApplicationPool) { return $false }
    }
    return $true
}


Export-ModuleMember -Function *-TargetResource

