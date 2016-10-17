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

        [parameter(Mandatory = $true)]  
        [System.Boolean] 
        $AuditingEnabled,

        [parameter(Mandatory = $false)] 
        [System.UInt32]  
        $AuditlogMaxSize,

        [parameter(Mandatory = $false)] 
        [System.String]  
        $DatabaseName,

        [parameter(Mandatory = $false)] 
        [System.String]  
        $DatabaseServer,

        [parameter(Mandatory = $false)] 
        [System.String]  
        $FailoverDatabaseServer,

        [parameter(Mandatory = $false)] 
        [System.Boolean] 
        $PartitionMode,

        [parameter(Mandatory = $false)] 
        [System.Boolean] 
        $Sharing,

        [parameter(Mandatory = $false)] 
        [ValidateSet("Windows", "SQL")]   
        [System.String] 
        $DatabaseAuthenticationType,

        [parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present",

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $DatabaseCredentials,

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Getting secure store service application '$Name'"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]
        
        $nullReturn = @{
            Name = $params.Name
            ApplicationPool = $params.ApplicationPool
            AuditingEnabled = $false
            Ensure = "Absent"
        }

        $serviceApps = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue 
        if ($null -eq $serviceApps) 
        { 
            return $nullReturn 
        }
        $serviceApp = $serviceApps | Where-Object -FilterScript { 
            $_.GetType().FullName -eq "Microsoft.Office.SecureStoreService.Server.SecureStoreServiceApplication" 
        }

        if ($null -eq $serviceApp) 
        { 
            return $nullReturn 
        } 
        else 
        {
            $serviceAppProxies = Get-SPServiceApplicationProxy -ErrorAction SilentlyContinue
            if ($null -ne $serviceAppProxies)
            {
                $serviceAppProxy = $serviceAppProxies | Where-Object -FilterScript { 
                    $serviceApp.IsConnected($_)
                }
                if ($null -ne $serviceAppProxy) 
                { 
                    $proxyName = $serviceAppProxy.Name
                }
            }
            return  @{
                Name = $serviceApp.DisplayName
                ProxyName       = $proxyName
                ApplicationPool = $serviceApp.ApplicationPool.Name
                DatabaseName = $serviceApp.Database.Name
                DatabaseServer = $serviceApp.Database.Server.Name
                InstallAccount = $params.InstallAccount
                Ensure = "Present"
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

        [parameter(Mandatory = $true)]  
        [System.Boolean] 
        $AuditingEnabled,

        [parameter(Mandatory = $false)] 
        [System.UInt32]  
        $AuditlogMaxSize,

        [parameter(Mandatory = $false)] 
        [System.String]  
        $DatabaseName,

        [parameter(Mandatory = $false)] 
        [System.String]  
        $DatabaseServer,

        [parameter(Mandatory = $false)] 
        [System.String]  
        $FailoverDatabaseServer,

        [parameter(Mandatory = $false)] 
        [System.Boolean] 
        $PartitionMode,

        [parameter(Mandatory = $false)] 
        [System.Boolean] 
        $Sharing,

        [parameter(Mandatory = $false)] 
        [ValidateSet("Windows", "SQL")]   
        [System.String] 
        $DatabaseAuthenticationType,

        [parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present",

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $DatabaseCredentials,

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Setting secure store service application '$Name'"

    $result = Get-TargetResource @PSBoundParameters
    $params = $PSBoundParameters

    if((($params.ContainsKey("DatabaseAuthenticationType") -eq $true) -and `
        ($params.ContainsKey("DatabaseCredentials") -eq $false)) -or `
        (($params.ContainsKey("DatabaseCredentials") -eq $true) -and `
        ($params.ContainsKey("DatabaseAuthenticationType") -eq $false))) 
        {
        throw ("Where DatabaseCredentials are specified you must also specify " + `
               "DatabaseAuthenticationType to identify the type of credentials being passed")
        return
    }

    if ($result.Ensure -eq "Absent" -and $Ensure -eq "Present") 
    { 
        Write-Verbose -Message "Creating Secure Store Service Application $Name"
        Invoke-SPDSCCommand -Credential $InstallAccount `
                            -Arguments $params `
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

            if($params.ContainsKey("DatabaseAuthenticationType")) 
            {
                if ($params.DatabaseAuthenticationType -eq "SQL") 
                {
                    $params.Add("DatabaseUsername", $params.DatabaseCredentials.Username)
                    $params.Add("DatabasePassword", $params.DatabaseCredentials.Password)
                }
                $params.Remove("DatabaseAuthenticationType")
            }

            if ($params.ContainsKey("ProxyName")) 
            { 
                $pName = $params.ProxyName
                $params.Remove("ProxyName") | Out-Null 
            }
            if ($null -eq $pName) 
            {
                $pName = "$($params.Name) Proxy"
            }
            New-SPSecureStoreServiceApplication @params | New-SPSecureStoreServiceApplicationProxy -Name $pName
        }
    } 
    
    if ($result.Ensure -eq "Present" -and $Ensure -eq "Present") 
    {
        if ([string]::IsNullOrEmpty($ApplicationPool) -eq $false `
            -and $ApplicationPool -ne $result.ApplicationPool) 
        {
            Write-Verbose -Message "Updating Secure Store Service Application $Name"
            Invoke-SPDSCCommand -Credential $InstallAccount `
                                -Arguments $PSBoundParameters `
                                -ScriptBlock {
                $params = $args[0]

                $serviceApp = Get-SPServiceApplication -Name $params.Name | Where-Object -FilterScript { 
                    $_.GetType().FullName -eq "Microsoft.Office.SecureStoreService.Server.SecureStoreServiceApplication" 
                }
                $appPool = Get-SPServiceApplicationPool -Identity $params.ApplicationPool 
                Set-SPSecureStoreServiceApplication -Identity $serviceApp -ApplicationPool $appPool
            }
        }
    }
    
    if ($Ensure -eq "Absent") 
    {
        # The service app should not exit
        Write-Verbose -Message "Removing Secure Store Service Application $Name"
        Invoke-SPDSCCommand -Credential $InstallAccount `
                            -Arguments $PSBoundParameters `
                            -ScriptBlock {
            $params = $args[0]
            
            $serviceApp =  Get-SPServiceApplication -Name $params.Name | Where-Object -FilterScript { 
                $_.GetType().FullName -eq "Microsoft.Office.SecureStoreService.Server.SecureStoreServiceApplication" 
            }

            # Remove the connected proxy(ies)
            $proxies = Get-SPServiceApplicationProxy
            foreach($proxyInstance in $proxies)
            {
                if($serviceApp.IsConnected($proxyInstance))
                {
                    $proxyInstance.Delete()
                }
            }

            Remove-SPServiceApplication $serviceApp -Confirm:$false
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

        [parameter(Mandatory = $true)]  
        [System.Boolean] 
        $AuditingEnabled,

        [parameter(Mandatory = $false)] 
        [System.UInt32]  
        $AuditlogMaxSize,

        [parameter(Mandatory = $false)] 
        [System.String]  
        $DatabaseName,

        [parameter(Mandatory = $false)] 
        [System.String]  
        $DatabaseServer,

        [parameter(Mandatory = $false)] 
        [System.String]  
        $FailoverDatabaseServer,

        [parameter(Mandatory = $false)] 
        [System.Boolean] 
        $PartitionMode,

        [parameter(Mandatory = $false)] 
        [System.Boolean] 
        $Sharing,

        [parameter(Mandatory = $false)] 
        [ValidateSet("Windows", "SQL")]   
        [System.String] 
        $DatabaseAuthenticationType,

        [parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present",

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $DatabaseCredentials,

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Testing secure store service application $Name"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @("ApplicationPool", "Ensure")
}

Export-ModuleMember -Function *-TargetResource
