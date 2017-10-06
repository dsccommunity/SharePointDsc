function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  
        [System.String]
        $Name,

        [parameter()]
        [System.Management.Automation.PSCredential] 
        $InstallAccount,

        [parameter(Mandatory = $true)] 
        [System.String] 
        $ManagedAccount
    )

    Write-Verbose -Message "Getting identity for service instance '$Name'"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        

        $serviceInstance = Get-SPServiceInstance -Server $env:computername | Where-Object { $_.TypeName -eq $params.Name }
        
        if ($null -eq $serviceInstance.service.processidentity) 
        {
            Write-Verbose "WARNING: Service $($params.name) does not support setting the process identity"
        }
        
        $ManagedAccount = $serviceInstance.service.processidentity.username
        
        return @{
            Name = $params.Name
            ManagedAccount = $ManagedAccount
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

        [parameter()] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount,

        [parameter(Mandatory = $true)] 
        [System.String] 
        $ManagedAccount
    )

    Write-Verbose -Message "Setting service instance '$Name' to '$ManagedAccount'"

    Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        

        $serviceInstance = Get-SPServiceInstance -Server $env:COMPUTERNAME| Where-Object { $_.TypeName -eq $params.Name }
        $managedAccount = Get-SPManagedAccount $params.ManagedAccount
        if ($null -eq $serviceInstance) 
        {
            throw [System.Exception] "Unable to locate service $($params.Name)"
        }
        if ($null -eq $managedAccount) 
        {
            throw [System.Exception] "Unable to locate Managed Account $($params.ManagedAccount)"
        }
        
       if ($null -eq $serviceInstance.service.processidentity) 
       {
           throw [System.Exception] "Service $($params.name) does not support setting the process identity"
       }
       
       $serviceInstance.service.processIdentity.CurrentIdentityType = [Microsoft.SharePoint.Administration.IdentityType]::SpecificUser 
       $serviceInstance.service.processIdentity.ManagedAccount = $managedAccount
       $serviceInstance.service.processIdentity.update()
       $serviceInstance.service.processIdentity.deploy() 
        
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

        [parameter()] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount,

        [parameter(Mandatory = $true)] 
        [System.String] 
        $ManagedAccount
    )

  $CurrentValues = Get-TargetResource @PSBoundParameters
  Write-Verbose -Message "Testing service instance '$Name' Process Identity"
  
  return ($CurrentValues.ManagedAccount -eq $ManagedAccount)
  
    
}
