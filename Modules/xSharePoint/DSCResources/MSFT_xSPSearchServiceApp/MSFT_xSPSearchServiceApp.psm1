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
        if ($null -eq $serviceApps) { 
            return $null 
        }
        $serviceApp = $serviceApps | Where-Object { $_.TypeName -eq "Search Service Application" }

        If ($null -eq $serviceApp) { 
            return $null 
        } else {
            $caWebApp = [Microsoft.SharePoint.Administration.SPAdministrationWebApplication]::Local
            $caWebApp.Sites[0].Url
            $s = new-Object Microsoft.SharePoint.SPSite($caWebApp.Sites[0].Url);
            $c = [Microsoft.Office.Server.Search.Administration.SearchContext]::GetContext($s);
            $sc = new-Object Microsoft.Office.Server.Search.Administration.Content($c);
            $defaultAccount = New-Object System.Management.Automation.PSCredential ($sc.DefaultGatheringAccount, (ConvertTo-SecureString "-" -AsPlainText -Force))
            
            $returnVal =  @{
                Name = $serviceApp.DisplayName
                ApplicationPool = $serviceApp.ApplicationPool.Name
                DatabaseName = $serviceApp.Database.Name
                DatabaseServer = $serviceApp.Database.Server.Name
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
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $DefaultContentAccessAccount,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )
    $result = Get-TargetResource @PSBoundParameters

    if ($result -eq $null) { 
        Write-Verbose -Message "Creating Search Service Application $Name"
        Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            

            if ($params.ContainsKey("InstallAccount")) { $params.Remove("InstallAccount") | Out-Null }

            $serviceInstance = Get-SPEnterpriseSearchServiceInstance -Local 
            Start-SPEnterpriseSearchServiceInstance -Identity $serviceInstance -ErrorAction SilentlyContinue
            $app = New-SPEnterpriseSearchServiceApplication @params
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
    } else {
        if ([string]::IsNullOrEmpty($ApplicationPool) -eq $false -and $ApplicationPool -ne $result.ApplicationPool) {
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
                    $setParams.Add("DefaultContentAccessAccountPassword ", (ConvertTo-SecureString -String $params.DefaultContentAccessAccount.GetNetworkCredential().Password -AsPlainText -Force))
                } 
                Set-SPEnterpriseSearchServiceApplication @setParams
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
        [parameter(Mandatory = $false)] [System.String] $DatabaseServer,
        [parameter(Mandatory = $false)] [System.String] $DatabaseName,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $DefaultContentAccessAccount,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing Search service application '$Name'"
    If ($null -eq $CurrentValues) { return $false }
    if ($PSBoundParameters.ContainsKey("DefaultContentAccessAccount")) {
        if ($DefaultContentAccessAccount.UserName -ne $CurrentValues.DefaultContentAccessAccount.UserName) {
            return $false
        }
    }
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("ApplicationPool")
}

Export-ModuleMember -Function *-TargetResource
