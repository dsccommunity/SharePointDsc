function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $true)]  [System.String] $ApplicationPool,
        [parameter(Mandatory = $false)] [System.String] $DatabaseName,
        [parameter(Mandatory = $false)] [System.String] $DatabaseServer,
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")] [System.String] $Ensure,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )
    Write-Verbose -Message "Getting App management service app '$Name'"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
        $serviceApps = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue
        $nullReturn = @{
            Name = $params.Name
            ApplicationPool = $params.ApplicationPool
            DatabaseName = $null
            DatabaseServer = $null
            Ensure = "Absent"
            InstallAccount = $params.InstallAccount
        } 
        if ($null -eq $serviceApps) { 
            return $nullReturn
        }
        $serviceApp = $serviceApps | Where-Object { $_.TypeName -eq "App Management Service Application" }

        If ($null -eq $serviceApp) { 
            return  $nullReturn
        } else {
            return  @{
                Name = $serviceApp.DisplayName
                ApplicationPool = $serviceApp.ApplicationPool.Name
                DatabaseName = $serviceApp.Database.Name
                DatabaseServer = $serviceApp.Database.Server.Name
                Ensure = "Present"
                InstallAccount = $params.InstallAccount
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
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $true)]  [System.String] $ApplicationPool,
        [parameter(Mandatory = $false)] [System.String] $DatabaseName,
        [parameter(Mandatory = $false)] [System.String] $DatabaseServer,
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")] [System.String] $Ensure,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $result = Get-TargetResource @PSBoundParameters

    if ($result.Ensure -eq "Absent" -and $Ensure -eq "Present") { 
        # The service app doesn't exist but should
        
        Write-Verbose -Message "Creating App management Service Application $Name"
        Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            
            $newParams = @{
                Name = $params.Name 
                ApplicationPool = $params.ApplicationPool
            }
            if ($params.ContainsKey("DatabaseName") -eq $true) { $newParams.Add("DatabaseName", $params.DatabaseName) }
            if ($params.ContainsKey("DatabaseServer") -eq $true) { $newParams.Add("DatabaseServer", $params.DatabaseServer) }

            $appService = New-SPAppManagementServiceApplication @newParams
            New-SPAppManagementServiceApplicationProxy -Name "$($params.Name) Proxy" -UseDefaultProxyGroup -ServiceApplication $appService -ea Stop | Out-Null
        }
    }
    if ($result.Ensure -eq "Present" -and $Ensure -eq "Present") {
        # The service app exists but has the wrong application pool
         
        if ($ApplicationPool -ne $result.ApplicationPool) {
            Write-Verbose -Message "Updating App management Service Application $Name"
            Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
                $params = $args[0]
                $appPool = Get-SPServiceApplicationPool -Identity $params.ApplicationPool
                
                $appService =  Get-SPServiceApplication -Name $params.Name | Where-Object { $_.TypeName -eq "App Management Service Application"  }
                $appService.ApplicationPool = $appPool
                $appService.Update()
            }
        }
    }
    if ($Ensure -eq "Absent") {
        # The service app should not exit
        Write-Verbose -Message "Removing App management Service Application $Name"
        Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
                $params = $args[0]
                
                $appService =  Get-SPServiceApplication -Name $params.Name | Where-Object { $_.TypeName -eq "App Management Service Application"  }
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
        [parameter(Mandatory = $false)] [System.String] $DatabaseName,
        [parameter(Mandatory = $false)] [System.String] $DatabaseServer,
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")] [System.String] $Ensure,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )
    
    Write-Verbose -Message "Testing for App management Service Application '$Name'"
    $CurrentValues = Get-TargetResource @PSBoundParameters
    
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("ApplicationPool", "Ensure")
}

Export-ModuleMember -Function *-TargetResource

