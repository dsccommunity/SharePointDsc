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
        [System.String]
        $DatabaseName,

        [parameter(Mandatory = $true)]
        [System.String]
        $DatabaseServer,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting BCS service app '$Name'"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        try 
        {
            $serviceApp = Get-xSharePointServiceApplication -Name $params.Name -TypeName BCS

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
        catch
        {
            return @{ } 
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
        [System.String]
        $DatabaseName,

        [parameter(Mandatory = $true)]
        [System.String]
        $DatabaseServer,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    $result = Get-TargetResource @PSBoundParameters

    if ($result.Count -eq 0) { 
        Write-Verbose -Message "Creating BCS Service Application $Name"
        Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            Invoke-xSharePointSPCmdlet -CmdletName "New-SPBusinessDataCatalogServiceApplication" -Arguments @{
                Name = $params.Name
                ApplicationPool = $params.ApplicationPool
                DatabaseName = $params.DatabaseName
                DatabaseServer = $params.DatabaseServer
            }
        }
    }
    else {
        if ($ApplicationPool -ne $result.ApplicationPool) {
            Write-Verbose -Message "Updating BCS Service Application $Name"
            Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
                $params = $args[0]
                $serviceApp = Get-xSharePointServiceApplication -Name $params.Name -TypeName "BCS"
                $appPool = Invoke-xSharePointSPCmdlet -CmdletName "Get-SPServiceApplicationPool" @{ 
                    Identity = $params.ApplicationPool 
                }
                Invoke-xSharePointSPCmdlet -CmdletName "Set-SPBusinessDataCatalogServiceApplication" -Arguments @{ 
                    Identity = $serviceApp
                    ApplicationPool = $appPool 
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
        [System.String]
        $DatabaseName,

        [parameter(Mandatory = $true)]
        [System.String]
        $DatabaseServer,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )
    $result = Get-TargetResource @PSBoundParameters
    
    Write-Verbose -Message "Testing for BCS Service Application '$Name'"
    if ($result.Count -eq 0) { return $false }
    else {
        if ($ApplicationPool -ne $result.ApplicationPool) { return $false }
    }
    return $true
}

Export-ModuleMember -Function *-TargetResource
