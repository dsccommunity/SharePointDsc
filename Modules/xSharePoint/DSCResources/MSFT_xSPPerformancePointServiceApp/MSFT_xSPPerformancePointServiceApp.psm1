function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $true)]  [System.String] $ApplicationPool,
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] [System.String] $Ensure = "Present",
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

        Write-Verbose -Message "Getting Performance Point service app '$Name'"

        $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
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
        $serviceApp = $serviceApps | Where-Object { $_.TypeName -eq "Performance Point Service Application" }

        if ($null -eq $serviceApp) { 
            return $nullReturn 
        } else {
            return @{
                Name = $serviceApp.DisplayName
                ApplicationPool = $serviceApp.ApplicationPool.Name
                Ensure = "Present"
            }
        }
    }
    return $result
}

function Set-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $true)]  [System.String] $ApplicationPool,
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] [System.String] $Ensure = "Present",
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $result = Get-TargetResource @PSBoundParameters

    if ($result.Ensure -eq "Absent" -and $Ensure -eq "Present") { 
        Write-Verbose -Message "Creating Performance Point Service Application $Name"
        Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
        
            New-SPPerformancePointServiceApplication -Name $params.Name `
                                                     -ApplicationPool $params.ApplicationPool

            New-SPPerformancePointServiceApplicationProxy -Name $params.Name `
                                                          -ServiceApplication $params.Name 
        }
    }
    if ($result.Ensure -eq "Present" -and $Ensure -eq "Present") {
        if ($ApplicationPool -ne $result.ApplicationPool) {
            Write-Verbose -Message "Updating Performance Point Service Application $Name"
            Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
                $params = $args[0]               

                $appPool = Get-SPServiceApplicationPool -Identity $params.ApplicationPool

                Get-SPServiceApplication -Name $params.Name `
                    | Where-Object { $_.TypeName -eq "Performance Point Service Application" } `
                    | Set-SPPerformancePointServiceApplication -ApplicationPool $appPool
            }
        }
    }
    if ($Ensure -eq "Absent") {
        Write-Verbose -Message "Removing PerformancePoint Service Application $Name"
        Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
                $params = $args[0]
                
                $appService =  Get-SPServiceApplication -Name $params.Name | Where-Object { $_.TypeName -eq "Performance Point Service Application"  }
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
    
    Write-Verbose -Message "Testing for Performance Point Service Application '$Name'"
    $CurrentValues = Get-TargetResource @PSBoundParameters
    $PSBoundParameters.Ensure = $Ensure
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("ApplicationPool", "Ensure")
}

Export-ModuleMember -Function *-TargetResource
