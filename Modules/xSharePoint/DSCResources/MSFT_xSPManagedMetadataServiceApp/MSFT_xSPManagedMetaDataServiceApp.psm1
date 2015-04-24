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
        [System.Management.Automation.PSCredential]
        $InstallAccount
        
    )

    Write-Verbose "Getting managed metadata service application $Name"

    $session = Get-xSharePointAuthenticatedPSSession $InstallAccount

    $result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        $serviceApp = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue |
                        Where-Object { $_.TypeName -eq "Managed Metadata Service" }
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
        [System.String]
        $DatabaseServer,

        [parameter(Mandatory = $true)]
        [System.String]
        $DatabaseName,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    $result = Get-TargetResource -Name $Name -ApplicationPool $ApplicationPool -InstallAccount $InstallAccount
    $session = Get-xSharePointAuthenticatedPSSession $InstallAccount
    if ($result.Count -eq 0) { 
        Write-Verbose "Creating Managed Metadata Service Application $Name"
        Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            $params.Remove("InstallAccount") | Out-Null
            New-SPMetadataServiceApplication @params | Out-Null
            New-SPMetadataServiceApplicationProxy -Name ($params.Name + " Proxy") -ServiceApplication $params.Name -DefaultProxyGroup -ContentTypePushdownEnabled -DefaultKeywordTaxonomy -DefaultSiteCollectionTaxonomy
        }
    }
    else {
        if ([string]::IsNullOrEmpty($ApplicationPool) -eq $false -and $ApplicationPool -ne $result.ApplicationPool) {
            Write-Verbose "Updating Managed Metadata Service Application $Name"
            Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
                $params = $args[0]
                $serviceApp = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue |
                        Where-Object { $_.TypeName -eq "Managed Metadata Service" }
                $serviceApp | Set-SPMetadataServiceApplication -ApplicationPool (Get-SPServiceApplicationPool $params.ApplicationPool)
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
        [System.Management.Automation.PSCredential]
        $InstallAccount,
        
        [System.String]
        $ApplicationPool,

        [System.String]
        $DatabaseServer,
        
        [System.String]
        $DatabaseName
    )

    $result = Get-TargetResource -Name $Name -InstallAccount $InstallAccount
    
    Write-Verbose "Testing for Managed Metadata Service Application '$Name'"
    if ($result.Count -eq 0) { return $false }
    else {
        if ([string]::IsNullOrEmpty($ApplicationPool) -eq $false -and $ApplicationPool -ne $result.ApplicationPool) { return $false }
    }
    return $true
    
}


Export-ModuleMember -Function *-TargetResource

