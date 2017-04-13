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
        $DatabaseName,

        [parameter(Mandatory = $true)]
        [System.String]
        $DatabaseServer,

        [parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [System.Management.Automation.PSCredential]
        $InstallAccount
    )
    Write-Verbose -Message "Getting Machine Translation Service Application '$Name'"
   
    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]
        
        $serviceApps = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue
        
        $nullReturn = @{
            Name = $params.Name
            DatabaseName = $params.DatabaseName
            DatabaseServer = $params.DatabaseServer
            ApplicationPool = $params.ApplicationPool
            Ensure = "Absent"
        }
        
        if($null -eq $serviceApps) 
        {
            return $nullReturn
        }
    
        $serviceApp = $serviceApps | Where-Object -FilterScript {
            $_.GetType().FullName -eq "Microsoft.Office.TranslationServices.TranslationServiceApplication"
        }
    
        if($null -eq $serviceApp)
        {
            return $nullReturn
        }      
        else {
            return @{
                Name = $params.Name
                DatabaseName = $($serviceApp.Database.Name)
                DatabaseServer = $($serviceApp.Database.Server.Name)
                ApplicationPool = $($serviceApp.ApplicationPool.Name)
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

        [parameter(Mandatory = $true)]
        [System.String]
        $DatabaseName,

        [parameter(Mandatory = $true)]
        [System.String]
        $DatabaseServer,

        [parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose "Setting Machine Translation Service Application."
    $CurrentValues = Get-TargetResource @PSBoundParameters

    if($CurrentValues.Ensure -eq "Present" -and $Ensure -eq "Present")
    {
        Write-Verbose "Resetting Machine Translation Service Application."
    
        $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
            $params = $args[0]
            $serviceApps = Get-SPServiceApplication -Identity $params.Name
            
            $serviceApp = $serviceApps | Where-Object -FilterScript { 
                $_.GetType().FullName -eq "Microsoft.Office.TranslationServices.TranslationServiceApplication"
            }
           
            $serviceApp | Set-SPTranslationServiceApplication -ApplicationPool $params.ApplicationPool `
                                                              -DatabaseName $params.DatabaseName `
                                                              -DatabaseServer $params.DatabaseServer
        }
    }
    if($CurrentValues.Ensure -eq "Absent" -and $Ensure -eq "Present")
    {
        Write-Verbose "Creating Machine Translation Service Application."
    
        $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
            $params = $args[0]
            
            New-SPTranslationServiceApplication -Name $params.Name `
                                                -DatabaseName $params.DatabaseName `
                                                -DatabaseServer $params.DatabaseServer `
                                                -ApplicationPool $params.ApplicationPool
        }
    }
    if($Ensure -eq "Absent")
    {
        Write-Verbose "Removing Machine Translation Service Application."
    
        $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                      -Arguments $PSBoundParameters `
                                      -ScriptBlock {
            $params = $args[0]
            
            $serviceApps = Get-SPServiceApplication -Identity $params.Name
            $serviceApp = $serviceApps | Where-Object -FilterScript { 
                $_.GetType().FullName -eq "Microsoft.Office.TranslationServices.TranslationServiceApplication"
            }
            $serviceApp | Remove-SPServiceApplication  

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

        [parameter(Mandatory = $true)]
        [System.String]
        $DatabaseName,

        [parameter(Mandatory = $true)]
        [System.String]
        $DatabaseServer,

        [parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose "Test Machine Translation Service Application."

    $PSBoundParameters.Ensure = $Ensure
    
    $CurrentValues = Get-TargetResource @PSBoundParameters

    $params = $PSBoundParameters

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @("Name","ApplicationPool", 
                                                     "DatabaseName","DatabaseServer", 
                                                     "Ensure")

}


Export-ModuleMember -Function *-TargetResource
