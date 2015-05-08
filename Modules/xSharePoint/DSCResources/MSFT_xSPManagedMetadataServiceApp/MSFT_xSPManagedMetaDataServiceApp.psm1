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
        $InstallAccount,
        
        [parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool        
    )

    Write-Verbose -Message "Getting managed metadata service application $Name"

    $session = Get-xSharePointAuthenticatedPSSession -Credential $InstallAccount

    $result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        $serviceApp = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue |
                        Where-Object { $_.TypeName -eq "Managed Metadata Service" }
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
        Write-Verbose -Message "Creating Managed Metadata Service Application $Name"
        Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            $params = Remove-xSharePointNullParamValues -Params $params
            $params.Remove("InstallAccount") | Out-Null
            $app = New-SPMetadataServiceApplication @params 
            if ($null -ne $app)
            {
                New-SPMetadataServiceApplicationProxy -Name ($params.Name + " Proxy") -ServiceApplication $app -DefaultProxyGroup -ContentTypePushdownEnabled -DefaultKeywordTaxonomy -DefaultSiteCollectionTaxonomy
            }
        }
    }
    else {
        if ([string]::IsNullOrEmpty($ApplicationPool) -eq $false -and $ApplicationPool -ne $result.ApplicationPool) {
            Write-Verbose -Message "Updating Managed Metadata Service Application $Name"
            Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
                $params = $args[0]
                $params = Remove-xSharePointNullParamValues -Params $params
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
        
        [parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

        [System.String]
        $DatabaseServer = $null,
        
        [System.String]
        $DatabaseName = $null
    )

    $result = Get-TargetResource -Name $Name -InstallAccount $InstallAccount -ApplicationPool $ApplicationPool
    
    Write-Verbose -Message "Testing for Managed Metadata Service Application '$Name'"
    if ($result.Count -eq 0) { return $false }
    else {
        if ([string]::IsNullOrEmpty($ApplicationPool) -eq $false -and $ApplicationPool -ne $result.ApplicationPool) { return $false }
    }
    return $true
    
}


Export-ModuleMember -Function *-TargetResource

