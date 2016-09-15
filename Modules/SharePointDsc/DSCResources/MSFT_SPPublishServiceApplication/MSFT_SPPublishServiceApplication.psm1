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
        [System.Management.Automation.PSCredential] 
        $InstallAccount,
        
        [parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present"
    )

    Write-Verbose -Message "Getting service application '$Name'"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
        $serviceApp = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue
        
        if ($null -eq $serviceApp) 
        { 
            Write-Verbose -Message "The service application $Name does not exist"
            $sharedEnsure = "Absent"
        }

        if ($null -eq $serviceApp.Uri)
        {
            Write-Verbose -Message "Only Business Data Connectivity, Machine Translation, Managed Metadata, `
                                    User Profile, Search, Secure Store are supported to be published via DSC."
            $sharedEnsure = "Absent"
        }
        else
        {
            if ($serviceApp.Shared -eq $true)
            {
                $sharedEnsure = "Present"
            }
            elseif ($serviceApp.Shared -eq $false)
            {
                $sharedEnsure = "Absent"    
            }
        }  
               
        return @{
            Name = $params.Name
            Ensure = $sharedEnsure.ToString()
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
        [parameter(Mandatory = $true)]  
        [System.String] 
        $Name,

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount,
        
        [parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present"
    )

    if ($Ensure -eq "Present") 
    {        
        Write-Verbose -Message "Publishing Service Application $Name"
        Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            
            $serviceApp = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue    
            if ($null -eq $serviceApp) 
            { 
                throw [Exception] ("The service application $Name does not exist")
            }
            
            Publish-SPServiceApplication $serviceApp            
        }
    }
    if ($Ensure -eq "Absent") {
        Write-Verbose -Message "Unpublishing Service Application $Name"
        Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            
            $serviceApp = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue    
            if ($null -eq $serviceApp) 
            { 
                throw [Exception] ("The service application $Name does not exist")
            }
            
            Unpublish-SPServiceApplication $serviceApp            
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
        
        [parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present"
    )

    Write-Verbose -Message "Testing service application '$Name'"
    $PSBoundParameters.Ensure = $Ensure

    $testArgs = @{
        CurrentValues = (Get-TargetResource @PSBoundParameters)
        DesiredValues = $PSBoundParameters
        ValuesToCheck = @("Name", "Ensure")
    }
    return Test-SPDscParameterState @testArgs
}

Export-ModuleMember -Function *-TargetResource
