function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]   $Name,
        [parameter(Mandatory = $false)]  [System.String][ValidateSet("Present","Absent")] $Ensure = "Present",
        [parameter(Mandatory = $false)] [System.String[]] $ServiceAppProxies,
        [parameter(Mandatory = $false)] [System.String[]] $ServiceAppProxiesToInclude,
        [parameter(Mandatory = $false)] [System.String[]] $ServiceAppProxiesToExclude,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )
 
    if (($Ensure -eq "Present") -and $ServiceAppProxies -and (($ServiceAppProxiesToInclude) -or ($ServiceAppProxiesToExclude))) {
           Write-Verbose  "Cannot use the ServiceAppProxies parameter together with the ServiceAppProxiesToInclude or ServiceAppProxiesToExclude parameters"
           return $null
        }
    
    if (($Ensure -eq "Present") -and !$ServiceAppProxies -and !$ServiceAppProxiesToInclude -and !$ServiceAppProxiesToExclude) {
            Write-Verbose "At least one of the following parameters must be specified: ServiceAppProxies, ServiceAppProxiesToInclude,ServiceAppProxiesToExclude"
            return $null  
        }

        Write-Verbose -Message "Getting Service Application Proxy Group $Name"
        
    $result = Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
    
            #Try to get the proxy group
            if ($params.Name -eq "Default") {
                $ProxyGroup = Get-SPServiceApplicationProxyGroup -Default
            } else {
                $ProxyGroup = Get-SPServiceApplicationProxyGroup $params.name -ErrorAction SilentlyContinue 
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
                ServiceAppProxiesToExclude = $param.ServiceAppProxiesToExclude
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
        [parameter(Mandatory = $false)]  [System.String][ValidateSet("Present","Absent")] $Ensure = "Present",
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
                    if ($ProxyGroup.Proxies.name) {
                        $differences = Compare-Object -ReferenceObject $ProxyGroup.Proxies.Name -DifferenceObject $params.ServiceAppProxies
                    
                        if ($null -eq $Differences) { 
                            write-verbose "Service Proxy Group $($params.name) Membership matches desired state"
                        }
                        Else {
                            ForEach ($difference in $differences) {
                                if ($difference.SideIndicator -eq "=>") {
                                    # Add service proxy 
                                    $ServiceProxyName = $difference.InputObject
                                    $ServiceProxy = Get-SPServiceApplicationProxy | Where-Object {$_.DisplayName -eq $ServiceProxyName}
                                
                                    if (!$ServiceProxy) {
                                        throw "Invalid Service Application Proxy $ServiceProxyName"
                                    }
                                
                                    write-verbose "1 Adding $ServiceProxyName to $($params.name) Proxy Group"
                                    $ProxyGroup | Add-SPServiceApplicationProxyGroupMember -member $ServiceProxy
                                
                                } elseif ($difference.SideIndicator -eq "<=") {
                                    # Remove service proxy
                                    $ServiceProxyName = $difference.InputObject
                                    $ServiceProxy = Get-SPServiceApplicationProxy | Where-Object {$_.DisplayName -eq $ServiceProxyName}
                                
                                    if (!$ServiceProxy) {
                                        throw "Invalid Service Application Proxy $ServiceProxyName"
                                    }
                                
                                    write-verbose "Removing $ServiceProxyName from $($params.name) Proxy Group"
                                    $ProxyGroup | Remove-SPServiceApplicationProxyGroupMember -member $ServiceProxy
                                
                                }
                            }
                        
                        }
                   }
                   else {
                       Foreach ($ServiceProxyName in $params.ServiceAppProxies) {
                          $ServiceProxy = Get-SPServiceApplicationProxy | Where-Object {$_.DisplayName -eq $ServiceProxyName}
                                
                           if (!$ServiceProxy) {
                               throw "Invalid Service Application Proxy $ServiceProxyName"
                           }
                                
                           write-verbose "2 Adding $ServiceProxyName to $($params.name) Proxy Group"
                           $ProxyGroup | Add-SPServiceApplicationProxyGroupMember -member $ServiceProxy
                       }
                   }
                        
              }
                
                #Add Service Applications
                if ($params.ServiceAppProxiesToInclude) {
                    if ($ProxyGroup.Proxies.name) {
                        $differences = Compare-Object -ReferenceObject $ProxyGroup.Proxies.Name -DifferenceObject $params.ServiceAppProxiesToInclude 
                        
                        if ($null -eq $Differences) { 
                            write-verbose "Service Proxy Group $($params.name) Membership matches desired state"
                        }
                        Else {
                            ForEach ($difference in $differences) {
                                if ($difference.SideIndicator -eq "=>") {
                                    # Add service proxy 
                                    $ServiceProxyName = $difference.InputObject
                                    $ServiceProxy = Get-SPServiceApplicationProxy | Where-Object {$_.DisplayName -eq $ServiceProxyName}
                                    
                                    if (!$ServiceProxy) {
                                        throw "Invalid Service Application Proxy $ServiceProxyName"
                                    }
                                    
                                    write-verbose "3 Adding $ServiceProxyName to $($params.name) Proxy Group"
                                    $ProxyGroup | Add-SPServiceApplicationProxyGroupMember -member $ServiceProxy
                                    
                                }
                            }
                       }
                    }
                    else {
                        Foreach ($ServiceProxyName in $params.ServiceAppProxies) {
                           $ServiceProxy = Get-SPServiceApplicationProxy | Where-Object {$_.DisplayName -eq $ServiceProxyName}
                                
                           if (!$ServiceProxy) {
                               throw "Invalid Service Application Proxy $ServiceProxyName"
                           }
                                
                           write-verbose "4 Adding $ServiceProxyName to $($params.name) Proxy Group"
                           $ProxyGroup | Add-SPServiceApplicationProxyGroupMember -member $ServiceProxy
                       }
                    }
                }
                
                #Remove Service Applications
                if ($params.ServiceAppProxiesToExclude) {
                    if ($ProxyGroup.Proxies.name) {
                        $differences = Compare-Object -ReferenceObject $ProxyGroup.Proxies.Name -DifferenceObject $params.ServiceAppProxiesToExclude -IncludeEqual
                        
                        if ($null -eq $Differences) { 
                            throw "Error comparing ServiceAppProxiesToExclude for Service Proxy Group $($params.name)"
                        }
                        Else {
                            ForEach ($difference in $differences) {
                                if ($difference.SideIndicator -eq "==") {
                                    # Remove service proxy 
                                    $ServiceProxyName = $difference.InputObject
                                    $ServiceProxy = Get-SPServiceApplicationProxy | Where-Object {$_.DisplayName -eq $ServiceProxyName}
                                    
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
            }
            else {
            #Absent - Make sure Proxy Group does not exist
            write-verbose "Removing $($params.name) Proxy Group"
            $ProxyGroup | Remove-SPServiceApplicationProxyGroup -confirm:$false
            }
        
        }
    
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]   $Name,
        [parameter(Mandatory = $false)]  [System.String][ValidateSet("Present","Absent")] $Ensure = "Present",
        [parameter(Mandatory = $false)] [System.String[]] $ServiceAppProxies,
        [parameter(Mandatory = $false)] [System.String[]] $ServiceAppProxiesToInclude,
        [parameter(Mandatory = $false)] [System.String[]] $ServiceAppProxiesToExclude,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )
 
    write-verbose "Testing Service Application Proxy Group $Name"
    
    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($null -eq $CurrentValues) { return $false }
    
    if ($CurrentValues.Ensure -ne $Ensure) {
        return $false
    }
    
    if ($ServiceAppProxies){
        Write-Verbose "Testing ServiceAppProxies property for $Name Proxy Group"
        
        if (-not $CurrentValues.ServiceAppProxies) { return $false }
        
        $differences = Compare-Object -ReferenceObject $CurrentValues.ServiceAppProxies -DifferenceObject $ServiceAppProxies

        if ($null -eq $differences) {
            Write-Verbose "ServiceAppProxies match"
        } else {
            Write-Verbose "ServiceAppProxies do not match"
            return $false
        }   
    }
    
    if ($ServiceAppProxiesToInclude){
        Write-Verbose "Testing ServiceAppProxiesToInclude property for $Name Proxy Group"
        
        if (-not $CurrentValues.ServiceAppProxies) { return $false }
        
        $differences = Compare-Object -ReferenceObject $CurrentValues.ServiceAppProxies -DifferenceObject $ServiceAppProxiesToInclude

        if ($null -eq $differences) {
            Write-Verbose "ServiceAppProxiesToInclude matches"
        } elseif ($differences.sideindicator -contains "=>") {
            Write-Verbose "ServiceAppProxiesToInclude does not match"
            return $false
        }   
    }
    
    if ($ServiceAppProxiesToExclude){
        Write-Verbose "Testing ServiceAppProxiesToExclude property for $Name Proxy Group"
        
        if (-not $CurrentValues.ServiceAppProxies) { return $true }
        
        $differences = Compare-Object -ReferenceObject $CurrentValues.ServiceAppProxies -DifferenceObject $ServiceAppProxiesToExclude -IncludeEqual

        if ($null -eq $differences) {
           return $false
        } elseif  ($differences.sideindicator -contains "==") {
            Write-Verbose "ServiceAppProxiesToExclude does not match"
            return $false
        }   
    }
    
    return $true 
}
