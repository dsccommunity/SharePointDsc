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

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabaseServer,

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabaseName,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount      
    )

    Write-Verbose -Message "Getting managed metadata service application $Name"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        try 
        {
            $serviceApp = Get-xSharePointServiceApplication -Name $params.Name -TypeName MMS

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

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabaseServer,

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabaseName,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    $result = Get-TargetResource @PSBoundParameters

    if ($result.Count -eq 0) { 
        Write-Verbose -Message "Creating Managed Metadata Service Application $Name"
        Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]

            if ($params.ContainsKey("InstallAccount")) { $params.Remove("InstallAccount") | Out-Null }

            $app = Invoke-xSharePointSPCmdlet -CmdletName "New-SPMetadataServiceApplication" -Arguments $params 
            if ($null -ne $app)
            {
                Invoke-xSharePointSPCmdlet -CmdletName "New-SPMetadataServiceApplicationProxy" -Arguments @{ 
                    Name = ($params.Name + " Proxy") 
                    ServiceApplication = $app 
                    DefaultProxyGroup = $true
                    ContentTypePushdownEnabled = $true
                    DefaultKeywordTaxonomy = $true
                    DefaultSiteCollectionTaxonomy = $true
                }
            }
        }
    }
    else {
        if ([string]::IsNullOrEmpty($ApplicationPool) -eq $false -and $ApplicationPool -ne $result.ApplicationPool) {
            Write-Verbose -Message "Updating Managed Metadata Service Application $Name"
            Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
                $params = $args[0]

                $serviceApp = Get-xSharePointServiceApplication -Name $params.Name -TypeName MMS
                Invoke-xSharePointSPCmdlet -CmdletName "Set-SPMetadataServiceApplication" -Arguments @{
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
        
        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount,
        
        [parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

        [parameter(Mandatory = $false)]
        [System.String]
        $DatabaseServer,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $DatabaseName
    )

    $result = Get-TargetResource @PSBoundParameters
    
    Write-Verbose -Message "Testing for Managed Metadata Service Application '$Name'"
    if ($result.Count -eq 0) { return $false }
    else {
        if ([string]::IsNullOrEmpty($ApplicationPool) -eq $false -and $ApplicationPool -ne $result.ApplicationPool) { return $false }
    }
    return $true
    
}


Export-ModuleMember -Function *-TargetResource

