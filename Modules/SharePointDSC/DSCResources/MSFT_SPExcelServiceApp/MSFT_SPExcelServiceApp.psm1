function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $true)]  [System.String] $ApplicationPool,
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] [System.String] $Ensure = "Present",
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )
    
    if ((Get-SPDSCInstalledProductVersion).FileMajorPart -ne 15) {
        throw [Exception] "Only SharePoint 2013 is supported to deploy Excel Services " + `
                          "service applicaions via DSC, as SharePoint 2016 deprecated " + `
                          "this service. See " + `
                          "https://technet.microsoft.com/en-us/library/mt346112(v=office.16).aspx " + `
                          "for more info."
    }

    Write-Verbose -Message "Getting Excel Services service app '$Name'"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
        $serviceApps = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue
        $nullReturn = @{
            Name = $params.Name
            ApplicationPool = $params.ApplicationPool
            Ensure = "Absent"
            InstallAccount = $params.InstallAccount
        }  
        if ($null -eq $serviceApps) { 
            return $nullReturn 
        }
        $serviceApp = $serviceApps | Where-Object { $_.TypeName -eq "Excel Services Application Web Service Application" }

        If ($null -eq $serviceApp) { 
            return $nullReturn
        } else {
            $returnVal =  @{
                Name = $serviceApp.DisplayName
                ApplicationPool = $serviceApp.ApplicationPool.Name
                Ensure = "Present"
                InstallAccount = $params.InstallAccount
            }
            return $returnVal
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
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] [System.String] $Ensure = "Present",
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    if ((Get-SPDSCInstalledProductVersion).FileMajorPart -ne 15) {
        throw [Exception] "Only SharePoint 2013 is supported to deploy Excel Services " + `
                          "service applicaions via DSC, as SharePoint 2016 deprecated " + `
                          "this service. See " + `
                          "https://technet.microsoft.com/en-us/library/mt346112(v=office.16).aspx " + `
                          "for more info."
    }
    $result = Get-TargetResource @PSBoundParameters

    if ($result.Ensure -eq "Absent" -and $Ensure -eq "Present") { 
        Write-Verbose -Message "Creating Excel Services Application $Name"
        Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]

            New-SPExcelServiceApplication -Name $params.Name `
                                          -ApplicationPool $params.ApplicationPool                                                    
        }
    }
    if ($Ensure -eq "Absent") {
        Write-Verbose -Message "Removing Excel Service Application $Name"
        Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
                $params = $args[0]
                
                $appService =  Get-SPServiceApplication -Name $params.Name | Where-Object { $_.TypeName -eq "Excel Services Application Web Service Application"  }
                Remove-SPServiceApplication $appService -Confirm:$false
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
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] [System.String] $Ensure = "Present",
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )
    
    if ((Get-SPDSCInstalledProductVersion).FileMajorPart -ne 15) {
        throw [Exception] "Only SharePoint 2013 is supported to deploy Excel Services " + `
                          "service applicaions via DSC, as SharePoint 2016 deprecated " + `
                          "this service. See " + `
                          "https://technet.microsoft.com/en-us/library/mt346112(v=office.16).aspx " + `
                          "for more info."
    }
    
    $PSBoundParameters.Ensure = $Ensure
    Write-Verbose -Message "Testing for Excel Services Application '$Name'"
    $CurrentValues = Get-TargetResource @PSBoundParameters
    return Test-SPDSCSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("Ensure")
}

Export-ModuleMember -Function *-TargetResource
