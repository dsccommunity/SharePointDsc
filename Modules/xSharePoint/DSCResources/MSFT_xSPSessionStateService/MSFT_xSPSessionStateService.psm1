function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $DatabaseName,
        [parameter(Mandatory = $true)]  [System.String] $DatabaseServer,
        [parameter(Mandatory = $true)]  [System.Boolean] $Enabled,
        [parameter(Mandatory = $false)]  [System.UInt32] $SessionTimeout,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Getting SPSessionStateService info"
    
    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
        $svc = Get-SPSessionStateService
        
        return @{
            DatabaseName = $svc.DatabaseId
            DatabaseServer = $svc.DatabaseServer
            Enabled = $svc.SessionStateEnabled
            SessionTimeout = $svc.Timeout.TotalMinutes
        }
    }
    return $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $DatabaseName,
        [parameter(Mandatory = $true)]  [System.String] $DatabaseServer,
        [parameter(Mandatory = $true)]  [System.Boolean] $Enabled,
        [parameter(Mandatory = $false)]  [System.UInt32] $SessionTimeout,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    if($SessionTimeout -eq 0) 
    {
        $SessionTimeout = 60    
    }
    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
        $svc = Get-SPSessionStateService
        if($params.Enabled) 
        {
            if($svc.SessionStateEnabled)
            {
                if($svc.Timeout.TotalMinutes -ne $params.SessionTimeout){
                    Write-Verbose -Message "Configuring SPSessionState timeout"
                    Set-SPSessionStateService -SessionTimeout $params.SessionTimeout
                }
            }
            else 
            {
                Write-Verbose -Message "Enabling SPSessionState"
                Enable-SPSessionStateService -DatabaseName $params.DatabaseName `
                    -DatabaseServer $params.DatabaseServer `
                    -SessionTimeout $params.SessionTimeout
            }
        }
        else 
        {
            if($svc.SessionStateEnabled)
            {
                Write-Verbose -Message "Disabling SPSessionState"
                Disable-SPSessionStateService 
            }  
            else 
            {
                Write-Verbose -Message "Keeping SPSessionState disabled"    
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
        [parameter(Mandatory = $true)]  [System.String] $DatabaseName,
        [parameter(Mandatory = $true)]  [System.String] $DatabaseServer,
        [parameter(Mandatory = $true)]  [System.Boolean] $Enabled,
        [parameter(Mandatory = $false)]  [System.UInt32] $SessionTimeout,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("Enabled","SessionTimeout")
}

Export-ModuleMember -Function *-TargetResource
