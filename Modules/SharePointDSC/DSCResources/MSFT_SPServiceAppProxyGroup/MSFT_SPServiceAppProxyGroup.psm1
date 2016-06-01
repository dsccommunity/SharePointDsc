function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]   $Name,
        [parameter(Mandatory = $true)]  [System.String][ValidateSet("Present","Absent")] $Ensure,
        [parameter(Mandatory = $false)] [System.String[]] $ServiceAppProxies,
        [parameter(Mandatory = $false)] [System.String[]] $ServiceAppProxiesToInclude,
        [parameter(Mandatory = $false)] [System.String[]] $ServiceAppProxiesToExclude,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )
 
    if ($ServiceAppProxies -and (($ServiceAppProxiesToInclude) -or ($ServiceAppProxiesToExclude))) {
           Write-Verbose  "Cannot use the ServiceAppProxies parameter together with the ServiceAppProxiesToInclude or ServiceAppProxiesToExclude parameters"
           return $null
        }
    
    if (!$ServiceAppProxies -and !$ServiceAppProxiesToInclude -and !$ServiceAppProxiesToExclude) {
            Write-Verbose "At least one of the following parameters must be specified: ServiceAppProxies, ServiceAppProxiesToInclude,ServiceAppProxiesToExclude"
            return $null  
        }
        
    $result = Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
    
            #Try to get the proxy group
            if ($params.Name -eq "Default") {
                $ProxyGroup = Get-SPServiceApplicationProxyGroup -Default
            } else {
                $ProxyGroup = Get-SPServiceApplicationProxyGroup $params.name -EA 0 
            }
            
            if ($ProxyGroup){ 
                $Ensure = "Present"
            }
            else {
                $Ensure = "Absent"    
            }
            
            $ServiceAppProxies = $ProxyGroup.Proxies.Name
            
            return @{
                Name = $params.name
                Ensure = $Ensure
                ServiceAppProxies = $ServiceAppProxies 
                ServiceAppProxiesToInclude = $param.ServiceAppProxiesToInclude
                ServiceAppProxiesToExluce = $param.ServiceAppProxiesToExclude
                InstallAccount = $params.InstallAccount
            }
                
    }
    
    return $result
    
}



function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]   $Name,
        [parameter(Mandatory = $true)]  [System.String][ValidateSet("Present","Absent")] $Ensure,
        [parameter(Mandatory = $false)] [System.String[]] $ServiceAppProxies,
        [parameter(Mandatory = $false)] [System.String[]] $ServiceAppProxiesToInclude,
        [parameter(Mandatory = $false)] [System.String[]] $ServiceAppProxiesToExclude,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )
 
        Write-Verbose -Message "Setting Service Application Proxy Group $Name"
        
        if ($ServiceAppProxies -and (($ServiceAppProxiesToInclude) -or ($ServiceAppProxiesToExclude))) {
           Throw "Cannot use the ServiceAppProxies parameter together with the ServiceAppProxiesToInclude or ServiceAppProxiesToExclude parameters"
        }
        if (!$ServiceAppProxies -and !$ServiceAppProxiesToInclude -and !$ServiceAppProxiesToExclude) {
            throw "At least one of the following parameters must be specified: ServiceAppProxies, ServiceAppProxiesToInclude,ServiceAppProxiesToExclude"
        }
    
        Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            
            #Ensure - Make sure Proxy Group exists
            if ($params.Ensure -eq "Present"){
                #Try to get the proxy group
                if ($params.Name -eq "Default") {
                    $ProxyGroup = Get-SPServiceApplicationProxyGroup -Default
                } else {
                    $ProxyGroup = Get-SPServiceApplicationProxyGroup $params.name -EA 0 
                }   
                
                #if it does not already exist, we will create it
                if (!($ProxyGroup)) {
                    Write-Verbose "Creating new Service Application Proxy Group $($params.Name)"
                    $ProxyGroup = New-SPServiceApplicationProxyGroup $params.name
                }
                    
                #Explicit Service Applications
                if ($params.ServiceAppProxies) {
                    $differences = Compare-Object -ReferenceObject $ProxyGroup.Proxies.Name -DifferenceObject $params.ServiceAppProxies
                    
                    if ($Differences -eq $null) { 
                        write-verbose "Service Proxy Group $($params.name) Membership matches desired state"
                    }
                    Else {
                        ForEach ($difference in $differences) {
                            if ($difference.SideIndicator -eq "=>") {
                                # Add service proxy 
                                $ServiceProxyName = $difference.InputObject
                                $ServiceProxy = Get-SPServiceApplicationProxy | ? {$_.DisplayName -eq $ServiceProxyName}
                                
                                if (!$ServiceProxy) {
                                    throw "Invalid Service Application Proxy $ServiceProxyName"
                                }
                                
                                write-verbose "Adding $ServiceProxyName to $($params.name) Proxy Group"
                                $ProxyGroup | Add-SPServiceApplicationProxyGroupMember -member $ServiceProxy
                                
                            } elseif ($difference.SideIndicator -eq "<=") {
                                # Remove service proxy
                                $ServiceProxyName = $difference.InputObject
                                $ServiceProxy = Get-SPServiceApplicationProxy | ? {$_.DisplayName -eq $ServiceProxyName}
                                
                                if (!$ServiceProxy) {
                                    throw "Invalid Service Application Proxy $ServiceProxyName"
                                }
                                
                                write-verbose "Removing $ServiceProxyName from $($params.name) Proxy Group"
                                $ProxyGroup | Remove-SPServiceApplicationProxyGroupMember -member $ServiceProxy
                                
                            }
                        }
                        
                    }
                    
                }
                
                #Add Service Applications
                if ($params.ServiceAppProxiesToInclude) {
                    $differences = Compare-Object -ReferenceObject $ProxyGroup.Proxies.Name -DifferenceObject $params.ServiceAppProxiesToInclude 
                    
                    if ($Differences -eq $null) { 
                        write-verbose "Service Proxy Group $($params.name) Membership matches desired state"
                    }
                    Else {
                        ForEach ($difference in $differences) {
                            if ($difference.SideIndicator -eq "=>") {
                                # Add service proxy 
                                $ServiceProxyName = $difference.InputObject
                                $ServiceProxy = Get-SPServiceApplicationProxy | ? {$_.DisplayName -eq $ServiceProxyName}
                                
                                if (!$ServiceProxy) {
                                    throw "Invalid Service Application Proxy $ServiceProxyName"
                                }
                                
                                write-verbose "Adding $ServiceProxyName to $($params.name) Proxy Group"
                                $ProxyGroup | Add-SPServiceApplicationProxyGroupMember -member $ServiceProxy
                                
                            }
                        }
                    } 
                }
                
                #Remove Service Applications
                if ($params.ServiceAppProxiesToExclude) {
                    $differences = Compare-Object -ReferenceObject $ProxyGroup.Proxies.Name -DifferenceObject $params.ServiceAppProxiesToExclude 
                    
                    if ($Differences -eq $null) { 
                        write-verbose "Service Proxy Group $($params.name) Membership matches desired state"
                    }
                    Else {
                        ForEach ($difference in $differences) {
                            if ($difference.SideIndicator -eq "<=") {
                                # Remove service proxy 
                                $ServiceProxyName = $difference.InputObject
                                $ServiceProxy = Get-SPServiceApplicationProxy | ? {$_.DisplayName -eq $ServiceProxyName}
                                
                                if (!$ServiceProxy) {
                                    throw "Invalid Service Application Proxy $ServiceProxyName"
                                }
                                
                                write-verbose "Removing $ServiceProxyName to $($params.name) Proxy Group"
                                $ProxyGroup | Remove-SPServiceApplicationProxyGroupMember -member $ServiceProxy
                                
                            }
                        }
                    } 
                }
            }
            else {
            #Absent - Make sure Proxy Group does not exist
            write-verbose "Removing $($params.name) Proxy Group"
            $ProxyGroup | Remove-SPServiceApplicationProxyGroup -confirm:$false
            }
        
        }
    
}


function test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]   $Name,
        [parameter(Mandatory = $true)]  [System.String][ValidateSet("Present","Absent")] $Ensure,
        [parameter(Mandatory = $false)] [System.String[]] $ServiceAppProxies,
        [parameter(Mandatory = $false)] [System.String[]] $ServiceAppProxiesToInclude,
        [parameter(Mandatory = $false)] [System.String[]] $ServiceAppProxiesToExclude,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )
 
    write-verbose "Testing Service Application Proxy Group $Name"
    
    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($null -eq $CurrentValues) { return $false }
    
    if ($ServiceAppProxies){
        Write-Verbose "Testing ServiceAppProxies property for $Name Proxy Group"
        
        if (-not $CurrentValues.ServiceAppProxies) { return $false }
        
        $differences = Compare-Object -ReferenceObject $CurrentValues.ServiceAppProxies -DifferenceObject $ServiceAppProxies

        if ($differences -eq $null) {
            Write-Verbose "ServiceAppProxies match"
        } else {
            Write-Verbose "ServiceAppProxies do not match"
            return $false
        }   
    }
    
    if ($ServiceAppProxiesToInclude){
        Write-Verbose "Testing ServiceAppProxiesToInclude property for $Name Proxy Group"
        
        if (-not $CurrentValues.ServiceAppProxiesToInclude) { return $false }
        
        $differences = Compare-Object -ReferenceObject $CurrentValues.ServiceAppProxiesToInclude -DifferenceObject $ServiceAppProxiesToInclude

        if ($differences -eq $null) {
            Write-Verbose "ServiceAppProxiesToInclude matches"
        } else {
            Write-Verbose "ServiceAppProxiesToInclude does not match"
            return $false
        }   
    }
    
    if ($ServiceAppProxiesToExclude){
        Write-Verbose "Testing ServiceAppProxiesToExclude property for $Name Proxy Group"
        
        if (-not $CurrentValues.ServiceAppProxiesToExclude) { return $false }
        
        $differences = Compare-Object -ReferenceObject $CurrentValues.ServiceAppProxiesToExclude -DifferenceObject $ServiceAppProxiesToExclude

        if ($differences -eq $null) {
            Write-Verbose "ServiceAppProxiesToExclude matches"
        } else {
            Write-Verbose "ServiceAppProxiesToExclude does not match"
            return $false
        }   
    }
}