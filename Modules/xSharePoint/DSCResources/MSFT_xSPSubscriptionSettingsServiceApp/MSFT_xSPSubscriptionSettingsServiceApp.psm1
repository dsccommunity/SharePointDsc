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
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )
    Write-Verbose -Message "Getting Subscription Settings Service '$Name'"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
        $serviceApps = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue 
        if ($null -eq $serviceApps) { 
            return $null 
        }
        $serviceApp = $serviceApps | Where-Object { $_.TypeName -eq "Microsoft SharePoint Foundation Subscription Settings Service Application" }

        If ($null -eq $serviceApp) { 
            return $null 
        } else {
            $returnVal =  @{
                Name = $serviceApp.DisplayName
                ApplicationPool = $serviceApp.ApplicationPool.Name
                DatabaseName = $serviceApp.Database.Name
                DatabaseServer = $serviceApp.Database.Server.Name
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
        [parameter(Mandatory = $false)] [System.String] $DatabaseName,
        [parameter(Mandatory = $false)] [System.String] $DatabaseServer,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $result = Get-TargetResource @PSBoundParameters

    if ($result -eq $null) { 
        Write-Verbose -Message "Creating Subscription Settings Service Application $Name"
        Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            
            $newParams = @{
                Name = $params.Name 
                ApplicationPool = $params.ApplicationPool
            }
            if ($params.ContainsKey("DatabaseName") -eq $true) { $newParams.Add("DatabaseName", $params.DatabaseName) }
            if ($params.ContainsKey("DatabaseServer") -eq $true) { $newParams.Add("DatabaseServer", $params.DatabaseServer) }
            $serviceApp = New-SPSubscriptionSettingsServiceApplication @newParams
            $proxy = New-SPSubscriptionSettingsServiceApplicationProxy -ServiceApplication $serviceApp 
        }
    }
    else {
        if ($ApplicationPool -ne $result.ApplicationPool) {
            Write-Verbose -Message "Updating Subscription Settings Service Application $Name"
            Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
                $params = $args[0]
                

                $appPool = Get-SPServiceApplicationPool -Identity $params.ApplicationPool

                $service = Get-SPServiceApplication -Name $params.Name `
                    | Where-Object { $_.TypeName -eq "Microsoft SharePoint Foundation Subscription Settings Service Application" } 

                $service.ApplicationPool = $appPool
                $service.Update()
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
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $true)]  [System.String] $ApplicationPool,
        [parameter(Mandatory = $false)] [System.String] $DatabaseName,
        [parameter(Mandatory = $false)] [System.String] $DatabaseServer,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )
    
    Write-Verbose -Message "Testing for Subscription Settings Service Application '$Name'"
    $CurrentValues = Get-TargetResource @PSBoundParameters
    
    if ($null -eq $CurrentValues) { return $false }
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("ApplicationPool")
}

Export-ModuleMember -Function *-TargetResource
