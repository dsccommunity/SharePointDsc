function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $true)]  [System.String] $ApplicationPool,
        [parameter(Mandatory = $false)] [System.String] $DatabaseServer,
        [parameter(Mandatory = $false)] [System.String] $DatabaseName,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount      
    )

    Write-Verbose -Message "Getting managed metadata service application $Name"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
        $serviceApps = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue 
        if ($null -eq $serviceApps) { 
            return $null 
        }
        $serviceApp = $serviceApps | Where-Object { $_.TypeName -eq "Managed Metadata Service" }

        If ($null -eq $serviceApp)
        {
            return $null
        }
        else
        {
            return @{
                Name = $serviceApp.DisplayName
                ApplicationPool = $serviceApp.ApplicationPool.Name
                DatabaseName = $serviceApp.Database.Name
                DatabaseServer = $serviceApp.Database.Server.Name
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
        [parameter(Mandatory = $false)] [System.String] $DatabaseServer,
        [parameter(Mandatory = $false)] [System.String] $DatabaseName,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount      
    )

    $result = Get-TargetResource @PSBoundParameters

    if ($result.Count -eq 0) { 
        Write-Verbose -Message "Creating Managed Metadata Service Application $Name"
        Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            

            if ($params.ContainsKey("InstallAccount")) { $params.Remove("InstallAccount") | Out-Null }

            $app = New-SPMetadataServiceApplication @params 
            if ($null -ne $app)
            {
                New-SPMetadataServiceApplicationProxy -Name ($params.Name + " Proxy") `
                                                      -ServiceApplication $app `
                                                      -DefaultProxyGroup `
                                                      -ContentTypePushdownEnabled `
                                                      -DefaultKeywordTaxonomy `
                                                      -DefaultSiteCollectionTaxonomy
            }
        }
    }
    else {
        if ([string]::IsNullOrEmpty($ApplicationPool) -eq $false -and $ApplicationPool -ne $result.ApplicationPool) {
            Write-Verbose -Message "Updating Managed Metadata Service Application $Name"
            Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
                $params = $args[0]
                

                $serviceApp = Get-SPServiceApplication -Name $params.Name  | Where-Object { $_.TypeName -eq "Managed Metadata Service" }
                $appPool = Get-SPServiceApplicationPool -Identity $params.ApplicationPool
                Set-SPMetadataServiceApplication -Identity $serviceApp -ApplicationPool $appPool
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
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $true)]  [System.String] $ApplicationPool,
        [parameter(Mandatory = $false)] [System.String] $DatabaseServer,
        [parameter(Mandatory = $false)] [System.String] $DatabaseName,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount      
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing for Managed Metadata Service Application '$Name'"
    if ($null -eq $CurrentValues) { return $false }
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("ApplicationPool")
}


Export-ModuleMember -Function *-TargetResource

