function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $URL,
        [parameter(Mandatory = $true)]  [System.String] $ServiceAppProxyGroup,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )
    
    Write-Verbose -Message "Getting $URL Service Proxy Group Association"
    
    $result = Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
            
        $WebApp = get-spwebapplication $params.url
        if (!$WebApp) { return $null }
         
         if ($WebApp.ServiceApplicationProxyGroup.friendlyname -eq "[default]") {
             $ServiceAppProxyGroup = "Default"
         } else {
             $ServiceAppProxyGroup = $WebApp.ServiceApplicationProxyGroup.name
         }
         
         return @{
             Url = $params.url
             ServiceAppProxyGroup = $ServiceAppProxyGroup
         }
    }
    
    return $result 
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $URL,
        [parameter(Mandatory = $true)]  [System.String] $ServiceAppProxyGroup,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )
    
    Write-Verbose -Message "Setting $URL Service Proxy Group Association"
    
    Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
     
        if ($params.ServiceAppProxyGroup -eq "Default") {
                $params.ServiceAppProxyGroup = "[default]"
        }
        
        Set-SPWebApplication $params.url -ServiceApplicationProxyGroup $params.ServiceAppProxyGroup
        
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $URL,
        [parameter(Mandatory = $true)]  [System.String] $ServiceAppProxyGroup,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )
    
    Write-Verbose -Message "Testing $URL Service Proxy Group Association"
    
    $CurrentValues = Get-TargetResource @PSBoundParameters
    
    if ($null -eq $CurrentValues) { return $false }
    
    if ($CurrentValues.ServiceAppProxyGroup -eq $ServiceAppProxyGroup) {
        return $true 
    } else {
        return $false 
    }
}
