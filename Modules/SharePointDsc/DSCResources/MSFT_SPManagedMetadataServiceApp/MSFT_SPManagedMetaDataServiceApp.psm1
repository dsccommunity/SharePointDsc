function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $ProxyName,
        
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
        [System.String]
        $ContentTypeHubUrl,

        [parameter(Mandatory = $false)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",
        
        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount      
    )

    Write-Verbose -Message "Getting managed metadata service application $Name"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]
        
        $serviceApps = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue
        $nullReturn = @{
            Name            = $params.Name
            Ensure          = "Absent"
            ApplicationPool = $params.ApplicationPool
        } 

        if ($null -eq $serviceApps)
        { 
            return $nullReturn 
        }
        
        $serviceApp = $serviceApps | Where-Object { $_.TypeName -eq "Managed Metadata Service" }
        if ($null -eq $serviceApp)
        {
            return $nullReturn
        }
        else
        {
            $serviceAppProxies = Get-SPServiceApplicationProxy -ErrorAction SilentlyContinue
            if ($null -ne $serviceAppProxies)
            {
                $serviceAppProxy = $serviceAppProxies | Where-Object { $serviceApp.IsConnected($_)}
                if ($null -ne $serviceAppProxy)
                {
                    $proxyName = $serviceAppProxy.Name
                }
            }

            return @{
                Name            = $serviceApp.DisplayName
                ProxyName       = $proxyName
                Ensure          = "Present"
                ApplicationPool = $serviceApp.ApplicationPool.Name
                DatabaseName    = $serviceApp.Database.Name
                DatabaseServer  = $serviceApp.Database.Server.Name
                InstallAccount  = $params.InstallAccount
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
        
        [parameter(Mandatory = $false)]
        [System.String]
        $ProxyName,
        
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
        [System.String]
        $ContentTypeHubUrl,

        [parameter(Mandatory = $false)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",
        
        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount      
    )

    $result = Get-TargetResource @PSBoundParameters

    if ($result.Ensure -eq "Absent" -and $Ensure -eq "Present")
    { 
        Write-Verbose -Message "Creating Managed Metadata Service Application $Name"
        Invoke-SPDSCCommand -Credential $InstallAccount `
                            -Arguments $PSBoundParameters `
                            -ScriptBlock {
            $params = $args[0]
            
            if ($params.ContainsKey("Ensure"))
            {
                $params.Remove("Ensure") | Out-Null
            }
            
            if ($params.ContainsKey("InstallAccount"))
            {
                $params.Remove("InstallAccount") | Out-Null
            }
            
            if ($params.ContainsKey("ContentTypeHubUrl"))
            {
                $params.Add("HubUri", $params.ContentTypeHubUrl)
                $params.Remove("ContentTypeHubUrl")
            }
            
            if ($params.ContainsKey("ProxyName"))
            {
                $pName = $params.ProxyName ; $params.Remove("ProxyName") | Out-Null
            }
            
            if ($null -eq $pName)
            {
                $pName = "$($params.Name) Proxy"
            }

            $app = New-SPMetadataServiceApplication @params 

            if ($null -ne $app)
            {
                New-SPMetadataServiceApplicationProxy -Name $pName `
                                                      -ServiceApplication $app `
                                                      -DefaultProxyGroup `
                                                      -ContentTypePushdownEnabled `
                                                      -DefaultKeywordTaxonomy `
                                                      -DefaultSiteCollectionTaxonomy
            }
        }
    }
    
    if ($result.Ensure -eq "Present" -and $Ensure -eq "Present")
    {
        if ([string]::IsNullOrEmpty($ApplicationPool) -eq $false `
            -and $ApplicationPool -ne $result.ApplicationPool)
        {
            Write-Verbose -Message "Updating Managed Metadata Service Application $Name"
            Invoke-SPDSCCommand -Credential $InstallAccount `
                                -Arguments $PSBoundParameters `
                                -ScriptBlock {
                $params = $args[0]

                $serviceApp = Get-SPServiceApplication -Name $params.Name  `
                              | Where-Object { $_.TypeName -eq "Managed Metadata Service" }
                $appPool = Get-SPServiceApplicationPool -Identity $params.ApplicationPool
                Set-SPMetadataServiceApplication -Identity $serviceApp -ApplicationPool $appPool
            }
        }
    }
    
    if ($Ensure -eq "Absent")
    {
        # The service app should not exit
        Write-Verbose -Message "Removing Managed Metadata Service Application $Name"
        Invoke-SPDSCCommand -Credential $InstallAccount `
                            -Arguments $PSBoundParameters `
                            -ScriptBlock {
            $params = $args[0]
            
            $serviceApp =  Get-SPServiceApplication -Name $params.Name `
                           | Where-Object { $_.TypeName -eq "Managed Metadata Service" }
            Remove-SPServiceApplication -Identity $serviceApp -Confirm:$false
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
        [System.String]
        $ProxyName,
        
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
        [System.String]
        $ContentTypeHubUrl,

        [parameter(Mandatory = $false)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",
        
        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount      
    )

    Write-Verbose -Message "Testing for Managed Metadata Service Application '$Name'"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters
    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @("ApplicationPool", "Ensure")
}

Export-ModuleMember -Function *-TargetResource
