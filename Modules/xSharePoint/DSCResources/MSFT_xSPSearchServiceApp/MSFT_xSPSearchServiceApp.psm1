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

    Write-Verbose -Message "Getting Search service application '$Name'"

    $session = Get-xSharePointAuthenticatedPSSession -Credential $InstallAccount

    $result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        $serviceApp = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue |
                        Where-Object { $_.TypeName -eq "Search Service Application" }
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

        [System.String]
        $DatabaseServer = $null,

        [System.String]
        $DatabaseName = $null,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    $result = Get-TargetResource -Name $Name -ApplicationPool $ApplicationPool -InstallAccount $InstallAccount
    $session = Get-xSharePointAuthenticatedPSSession -Credential $InstallAccount
    if ($result.Count -eq 0) { 
        Write-Verbose -Message "Creating Search Service Application $Name"
        Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            $params = Remove-xSharePointNullParamValues -Params $params
            $params.Remove("InstallAccount") | Out-Null

            Get-SPEnterpriseSearchServiceInstance -Local | Start-SPEnterpriseSearchServiceInstance -ErrorAction SilentlyContinue
            $app = New-SPEnterpriseSearchServiceApplication @params
            if ($app) {
                New-SPEnterpriseSearchServiceApplicationProxy -Name ($params.Name + " Proxy") -SearchApplication $app
            }
        }
    }
    else {
        if ([string]::IsNullOrEmpty($ApplicationPool) -eq $false -and $ApplicationPool -ne $result.ApplicationPool) {
            Write-Verbose -Message "Updating Search Service Application $Name"
            Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
                $params = $args[0]
                $params = Remove-xSharePointNullParamValues -Params $params
                $serviceApp = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue |
                        Where-Object { $_.TypeName -eq "Search Service Application" }
                $serviceApp | Set-SPEnterpriseSearchServiceApplication -ApplicationPool (Get-SPServiceApplicationPool $params.ApplicationPool)
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

        [System.String]
        $DatabaseServer = $null,

        [System.String]
        $DatabaseName = $null,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    $result = Get-TargetResource -Name $Name -ApplicationPool $ApplicationPool -InstallAccount $InstallAccount
    Write-Verbose -Message "Testing Search service application '$Name'"
    
    if ($result.Count -eq 0) { return $false }
    else {
        if ($ApplicationPool -ne $result.ApplicationPool) { return $false }
    }
    return $true
}

Export-ModuleMember -Function *-TargetResource
