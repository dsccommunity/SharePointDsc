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
        $InstallAccount
    )

    Write-Verbose -Message "Getting BCS service app '$Name'"

    $session = Get-xSharePointAuthenticatedPSSession -Credential $InstallAccount

    $result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        $serviceApp = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue |
                        Where-Object { $_.TypeName -eq "Business Data Connectivity Service Application" }
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
        [System.String]
        $DatabaseName,

        [parameter(Mandatory = $true)]
        [System.String]
        $DatabaseServer,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    $result = Get-TargetResource -Name $Name -ApplicationPool $ApplicationPool -InstallAccount $InstallAccount
    $session = Get-xSharePointAuthenticatedPSSession -Credential $InstallAccount
    if ($result.Count -eq 0) { 
        Write-Verbose -Message "Creating BCS Service Application $Name"
        Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            $params.Remove("InstallAccount") | Out-Null
            New-SPBusinessDataCatalogServiceApplication @params | Out-Null
        }
    }
    else {
        if ($ApplicationPool -ne $result.ApplicationPool) {
            Write-Verbose -Message "Updating BCS Service Application $Name"
            Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
                $params = $args[0]
                $serviceApp = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue |
                        Where-Object { $_.TypeName -eq "Business Data Connectivity Service Application" }
                $serviceApp | Set-SPBusinessDataCatalogServiceApplication -ApplicationPool (Get-SPServiceApplicationPool $params.ApplicationPool)
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
        [System.String]
        $DatabaseName,

        [parameter(Mandatory = $true)]
        [System.String]
        $DatabaseServer,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )
    $result = Get-TargetResource -Name $Name -ApplicationPool $ApplicationPool -InstallAccount $InstallAccount
    
    Write-Verbose -Message "Testing for BCS Service Application '$Name'"
    if ($result.Count -eq 0) { return $false }
    else {
        if ($ApplicationPool -ne $result.ApplicationPool) { return $false }
    }
    return $true
}

Export-ModuleMember -Function *-TargetResource
