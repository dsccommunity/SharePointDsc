function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $true)]  [System.String] $ApplicationPool,
        [parameter(Mandatory = $false)] [System.String] $DatabaseServer,
        [parameter(Mandatory = $false)] [System.String] $DatabaseName,
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] [System.String] $Ensure = "Present",
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $DefaultContentAccessAccount,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Getting Search service application '$Name'"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
        [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")
        [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Administration")
        [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Office.Server.Search.Administration")
        [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Office.Server.Search")
        [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Office.Server") 

        $serviceApps = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue
        
        $nullReturn = @{
            Name = $params.Name
            ApplicationPool = $params.ApplicationPool
            Ensure = "Absent"
        }
         
        if ($null -eq $serviceApps) { 
            return $nullReturn 
        }
        $serviceApp = $serviceApps | Where-Object { $_.TypeName -eq "Search Service Application" }

        If ($null -eq $serviceApp) { 
            return $nullReturn
        } else {
            $caWebApp = Get-SPWebApplication -IncludeCentralAdministration | where {$_.IsAdministrationWebApplication} 
            $s = Get-SPSite $caWebApp.Url
            $c = [Microsoft.Office.Server.Search.Administration.SearchContext]::GetContext($s);
            $sc = New-Object -TypeName Microsoft.Office.Server.Search.Administration.Content -ArgumentList $c;
            $defaultAccount = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @($sc.DefaultGatheringAccount, (ConvertTo-SecureString "-" -AsPlainText -Force))
            
            $returnVal =  @{
                Name = $serviceApp.DisplayName
                ApplicationPool = $serviceApp.ApplicationPool.Name
                DatabaseName = $serviceApp.Database.Name
                DatabaseServer = $serviceApp.Database.Server.Name
                Ensure = "Present"
                DefaultContentAccessAccount = $defaultAccount
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
        [parameter(Mandatory = $false)] [System.String] $DatabaseServer,
        [parameter(Mandatory = $false)] [System.String] $DatabaseName,
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] [System.String] $Ensure = "Present",
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $DefaultContentAccessAccount,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )
    $result = Get-TargetResource @PSBoundParameters

    if ($result.Ensure -eq "Absent" -and $Ensure -eq "Present") {
        # Create the service app as it doesn't exist
         
        Write-Verbose -Message "Creating Search Service Application $Name"
        Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            
            $serviceInstance = Get-SPEnterpriseSearchServiceInstance -Local 
            Start-SPEnterpriseSearchServiceInstance -Identity $serviceInstance -ErrorAction SilentlyContinue            
            $newParams = @{
                Name = $params.Name
                ApplicationPool = $params.ApplicationPool
            }
            if ($params.ContainsKey("DatabaseServer") -eq $true) { $newParams.Add("DatabaseServer", $params.DatabaseServer) }
            if ($params.ContainsKey("DatabaseName") -eq $true) { $newParams.Add("DatabaseName", $params.DatabaseName) }
            $app = New-SPEnterpriseSearchServiceApplication @newParams 
            if ($app) {
                New-SPEnterpriseSearchServiceApplicationProxy -Name "$($params.Name) Proxy" -SearchApplication $app
                if ($params.ContainsKey("DefaultContentAccessAccount") -eq $true) {
                    $appPool = Get-SPServiceApplicationPool -Identity $params.ApplicationPool
                    $setParams = @{
                        ApplicationPool = $appPool
                        Identity = $app
                        DefaultContentAccessAccountName = $params.DefaultContentAccessAccount.UserName
                        DefaultContentAccessAccountPassword = (ConvertTo-SecureString -String $params.DefaultContentAccessAccount.GetNetworkCredential().Password -AsPlainText -Force)
                    }
                    Set-SPEnterpriseSearchServiceApplication @setParams
                } 
            }
        }
    }
    if ($result.Ensure -eq "Present" -and $Ensure -eq "Present") {
        # Update the service app that already exists
        
        Write-Verbose -Message "Updating Search Service Application $Name"
        Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            
            $serviceApp = Get-SPServiceApplication -Name $params.Name | Where-Object { $_.TypeName -eq "Search Service Application" }
            $appPool = Get-SPServiceApplicationPool -Identity $params.ApplicationPool
            $setParams = @{
                ApplicationPool = $appPool
                Identity = $serviceApp
            }
            if ($params.ContainsKey("DefaultContentAccessAccount") -eq $true) {
                $setParams.Add("DefaultContentAccessAccountName", $params.DefaultContentAccessAccount.UserName)
                $password = ConvertTo-SecureString -String $params.DefaultContentAccessAccount.GetNetworkCredential().Password -AsPlainText -Force
                $setParams.Add("DefaultContentAccessAccountPassword", $password)
            } 
            Set-SPEnterpriseSearchServiceApplication @setParams
        }
    }
    
    if ($Ensure -eq "Absent") {
        # The service app should not exit
        Write-Verbose -Message "Removing Search Service Application $Name"
        Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            
            $serviceApp =  Get-SPServiceApplication -Name $params.Name | Where-Object { $_.TypeName -eq "Search Service Application"  }
            Remove-SPServiceApplication $serviceApp -Confirm:$false
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
        [parameter(Mandatory = $false)] [System.String] $DatabaseServer,
        [parameter(Mandatory = $false)] [System.String] $DatabaseName,
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] [System.String] $Ensure = "Present",
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $DefaultContentAccessAccount,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing Search service application '$Name'"

    if ($PSBoundParameters.ContainsKey("DefaultContentAccessAccount") -and $Ensure -eq "Present") {
        if ($DefaultContentAccessAccount.UserName -ne $CurrentValues.DefaultContentAccessAccount.UserName) {
            return $false
        }
    }
    $PSBoundParameters.Ensure = $Ensure

    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("Ensure", "ApplicationPool")
}

Export-ModuleMember -Function *-TargetResource
