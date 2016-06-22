function Get-TargetResource
{
    # Ignoring this because we need to generate a stub credential to return up the current crawl account as a PSCredential
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])] 
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $true)]  [System.String] $ApplicationPool,
        [parameter(Mandatory = $false)] [System.String] $DatabaseServer,
        [parameter(Mandatory = $false)] [System.String] $DatabaseName,
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] [System.String] $Ensure = "Present",
        [parameter(Mandatory = $false)] [System.String] $SearchCenterUrl,
        [parameter(Mandatory = $false)] [System.Boolean] $CloudIndex,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $DefaultContentAccessAccount,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Getting Search service application '$Name'"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount -Arguments @($PSBoundParameters, $PSScriptRoot) -ScriptBlock {
        $params = $args[0]
        $scriptRoot = $args[1]
        
        Import-Module -Name (Join-Path $scriptRoot "MSFT_SPSearchServiceApp.psm1")
        
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

        if ($null -eq $serviceApp) { 
            return $nullReturn
        } else {
            $caWebApp = Get-SPWebApplication -IncludeCentralAdministration | Where-Object -FilterScript { $_.IsAdministrationWebApplication } 
            $s = Get-SPSite $caWebApp.Url
            $c = [Microsoft.Office.Server.Search.Administration.SearchContext]::GetContext($s);
            $sc = New-Object -TypeName Microsoft.Office.Server.Search.Administration.Content -ArgumentList $c;
            $dummyPassword = ConvertTo-SecureString "-" -AsPlainText -Force
            $defaultAccount = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @($sc.DefaultGatheringAccount, $dummyPassword)

            $cloudIndex = $false
            $version = Get-SPDSCInstalledProductVersion
            if(($version.FileMajorPart -gt 15) -or ($version.FileMajorPart -eq 15 -and $version.FileBuildPart -ge 4745)) {
                $cloudIndex = $serviceApp.CloudIndex
            }
            $returnVal =  @{
                Name = $serviceApp.DisplayName
                ApplicationPool = $serviceApp.ApplicationPool.Name
                DatabaseName = $serviceApp.Database.Name
                DatabaseServer = $serviceApp.Database.Server.Name
                Ensure = "Present"
                SearchCenterUrl = $serviceApp.SearchCenterUrl
                DefaultContentAccessAccount = $defaultAccount
                CloudIndex = $cloudIndex
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
        [parameter(Mandatory = $false)] [System.String] $SearchCenterUrl,
        [parameter(Mandatory = $false)] [System.Boolean] $CloudIndex,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $DefaultContentAccessAccount,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )
    $result = Get-TargetResource @PSBoundParameters

    if ($result.Ensure -eq "Absent" -and $Ensure -eq "Present") {
        # Create the service app as it doesn't exist
         
        Write-Verbose -Message "Creating Search Service Application $Name"
        Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            
            $serviceInstance = Get-SPEnterpriseSearchServiceInstance -Local 
            Start-SPEnterpriseSearchServiceInstance -Identity $serviceInstance -ErrorAction SilentlyContinue            
            $newParams = @{
                Name = $params.Name
                ApplicationPool = $params.ApplicationPool
            }
            if ($params.ContainsKey("DatabaseServer") -eq $true) { $newParams.Add("DatabaseServer", $params.DatabaseServer) }
            if ($params.ContainsKey("DatabaseName") -eq $true) { $newParams.Add("DatabaseName", $params.DatabaseName) }
            
            if ($params.ContainsKey("CloudIndex") -eq $true) {
                $version = Get-SPDSCInstalledProductVersion
                if (($version.FileMajorPart -gt 15) -or ($version.FileMajorPart -eq 15 -and $version.FileBuildPart -ge 4745)) {
                    $newParams.Add("CloudIndex", $params.CloudIndex)    
                } else {
                    throw "Please install SharePoint 2016 or SharePoint 2013 with August 2015 CU or higher before attempting to create a cloud enabled search service application"
                }
                
            }
            
            $app = New-SPEnterpriseSearchServiceApplication @newParams 
            if ($app) {
                New-SPEnterpriseSearchServiceApplicationProxy -Name "$($params.Name) Proxy" -SearchApplication $app
                if ($params.ContainsKey("DefaultContentAccessAccount") -eq $true) {
                    $appPool = Get-SPServiceApplicationPool -Identity $params.ApplicationPool
                    $setParams = @{
                        ApplicationPool = $appPool
                        Identity = $app
                        DefaultContentAccessAccountName = $params.DefaultContentAccessAccount.UserName
                        DefaultContentAccessAccountPassword = $params.DefaultContentAccessAccount.Password
                    }
                    Set-SPEnterpriseSearchServiceApplication @setParams
                } 
                
                if ($params.ContainsKey("SearchCenterUrl") -eq $true) {
                    $serviceApp = Get-SPServiceApplication -Name $params.Name | Where-Object { $_.TypeName -eq "Search Service Application" }
                    $serviceApp.SearchCenterUrl = $params.SearchCenterUrl
                    $serviceApp.Update()
                }
            }
        }
    }
    if ($result.Ensure -eq "Present" -and $Ensure -eq "Present") {
        # Update the service app that already exists
        
        Write-Verbose -Message "Updating Search Service Application $Name"
        Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            
            $serviceApp = Get-SPServiceApplication -Name $params.Name | Where-Object { $_.TypeName -eq "Search Service Application" }
            $appPool = Get-SPServiceApplicationPool -Identity $params.ApplicationPool
            $setParams = @{
                ApplicationPool = $appPool
                Identity = $serviceApp
            }
            if ($params.ContainsKey("DefaultContentAccessAccount") -eq $true) {
                $setParams.Add("DefaultContentAccessAccountName", $params.DefaultContentAccessAccount.UserName)
                $setParams.Add("DefaultContentAccessAccountPassword", $params.DefaultContentAccessAccount.Password)
            } 
            Set-SPEnterpriseSearchServiceApplication @setParams
            
            if ($params.ContainsKey("SearchCenterUrl") -eq $true) {
                $serviceApp = Get-SPServiceApplication -Name $params.Name | Where-Object { $_.TypeName -eq "Search Service Application" }
                $serviceApp.SearchCenterUrl = $params.SearchCenterUrl
                $serviceApp.Update()
            }
        }
    }
    
    if ($Ensure -eq "Absent") {
        # The service app should not exit
        Write-Verbose -Message "Removing Search Service Application $Name"
        Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
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
        [parameter(Mandatory = $false)] [System.String] $SearchCenterUrl,
        [parameter(Mandatory = $false)] [System.Boolean] $CloudIndex,
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
    if ($Ensure -eq "Present") {
        return Test-SPDSCSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("Ensure", "ApplicationPool", "SearchCenterUrl")    
    } else {
        return Test-SPDSCSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("Ensure")
    }    
}

function Get-SPDSCContentAccessAccount() {
    # Ignoring this because we need to generate a stub credential to return up the current crawl account as a PSCredential
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
    param()
    $caWebApp = Get-SPWebApplication -IncludeCentralAdministration | Where-Object -FilterScript { $_.IsAdministrationWebApplication } 
    $s = Get-SPSite $caWebApp.Url
    $c = [Microsoft.Office.Server.Search.Administration.SearchContext]::GetContext($s);
    $sc = New-Object -TypeName Microsoft.Office.Server.Search.Administration.Content -ArgumentList $c;

    $dummyPassword = ConvertTo-SecureString "-" -AsPlainText -Force
    $defaultAccount = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @($sc.DefaultGatheringAccount, $dummyPassword)
    return $defaultAccount    
}

Export-ModuleMember -Function *-TargetResource, Get-SPDSCContentAccessAccount
