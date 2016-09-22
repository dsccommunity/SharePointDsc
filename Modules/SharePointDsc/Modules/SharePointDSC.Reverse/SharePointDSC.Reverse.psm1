<##############################################################
 # This script is used to analyze an existing SharePoint (2010, 2013, 2016 or greater), and to produce the resulting PowerShell DSC Configuration Script representing it. Its purpose is to help SharePoint Admins and Devs replicate an existing SharePoint farm in an isolated area in order to troubleshoot an issue. This script needs to be executed directly on one of the SharePoint server in the far we wish to replicate. Upon finishing its execution, this Powershell script will prompt the user to specify a path to a FOLDER where the resulting PowerShell DSC Configuraton (.ps1) script will be generated. The resulting script will be named "SP-Farm.DSC.ps1" and will contain an exact description, in DSC notation, of the various components and configuration settings of the current SharePoint Farm. This script can then be used in an isolated environment to replicate the SharePoint server farm. The script could also be used as a simple textual (while in a DSC notation format) description of what the configuraton of the SharePoint farm looks like. This script is meant to be community driven, and everyone is encourage to participate and help improve and mature it. It is not officially endorsed by Microsoft, and support is 'offered' on a best effort basis by its contributors. Bugs suggestions should be reported through the issue system on GitHub. They will be looked at as time permits.
 # v0.1 - Nik Charlebois
 ##############################################################>
<## Script Settings #>
$VerbosePreference = "SilentlyContinue"

<## Scripts Variables #>
$Script:dscConfigContent = ""

<## This is the main function for this script. It acts as a call dispatcher, calling th various functions required in the proper order to get the full farm picture. #>
function Orchestrator{    
	$Script:spFarmAccount = Get-Credential -Message "Farm Account"
	$Script:spCentralAdmin = Get-SPWebApplication -IncludeCentralAdministration | Where{$_.DisplayName -like '*Central Administration*'}
    $spFarm = Get-SPFarm
    $spServers = $spFarm.Servers

    $totalSteps = 6 + ($spServers.Length * 18)
    $currentStep = 1

    Write-Progress -Activity "Scanning Operating System Version..." -PercentComplete ($currentStep/$totalSteps*100)
    Read-OperatingSystemVersion
    $currentStep++

    Write-Progress -Activity "Scanning SQL Server Version..." -PercentComplete ($currentStep/$totalSteps*100)
    Read-SQLVersion
    $currentStep++

    Write-Progress -Activity "Scanning Patch Levels..." -PercentComplete ($currentStep/$totalSteps*100)
    Read-SPProductVersions
    $currentStep++

    $Script:dscConfigContent += "Configuration SharePointFarm`r`n"
    $Script:dscConfigContent += "{`r`n"

    Write-Progress -Activity "Configuring Credentials..." -PercentComplete ($currentStep/$totalSteps*100)
    Set-ObtainRequiredCredentials
    $currentStep++

    Write-Progress -Activity "Configuring Dependencies..." -PercentComplete ($currentStep/$totalSteps*100)
    Set-Imports
    $currentStep++
    
    foreach($spServer in $spServers)
    {
        <## SQL servers are returned by Get-SPServer but they have a Role of 'Invalid'. Therefore we need to ignore these. The resulting PowerShell DSC Configuration script does not take into account the configuration of the SQL server for the SharePoint Farm at this point in time. We are activaly working on giving our users an experience that is as painless as possible, and are planning on integrating the SQL DSC Configuration as part of our feature set. #>
        if($spServer.Role -ne "Invalid")
        {
            $Script:dscConfigContent += "`r`n    node " + $spServer.Name + "{`r`n"

            Write-Progress -Activity ("[" + $spServer.Name + "] Setting Up Configuration Settings...") -PercentComplete ($currentStep/$totalSteps*100)
            Set-ConfigurationSettings
            $currentStep++

            Write-Progress -Activity ("[" + $spServer.Name + "] Scanning the SharePoint Farm...") -PercentComplete ($currentStep/$totalSteps*100)
            Read-SPFarm
            $currentStep++

            Write-Progress -Activity ("[" + $spServer.Name + "] Scanning Web Application(s)...") -PercentComplete ($currentStep/$totalSteps*100)
            Read-SPWebApplications
            $currentStep++

            Write-Progress -Activity ("[" + $spServer.Name + "] Scanning Managed Path(s)...") -PercentComplete ($currentStep/$totalSteps*100)
            Read-SPManagedPaths
            $currentStep++

            Write-Progress -Activity ("[" + $spServer.Name + "] Scanning Managed Account(s)...") -PercentComplete ($currentStep/$totalSteps*100)
            Read-SPManagedAccounts
            $currentStep++

            Write-Progress -Activity ("[" + $spServer.Name + "] Scanning Application Pool(s)...") -PercentComplete ($currentStep/$totalSteps*100)
            Read-SPServiceApplicationPools
            $currentStep++

            Write-Progress -Activity ("[" + $spServer.Name + "] Scanning Site Collection(s)...") -PercentComplete ($currentStep/$totalSteps*100)
            Read-SPSites
            $currentStep++

            Write-Progress -Activity ("[" + $spServer.Name + "] Scanning Service Instance(s)...") -PercentComplete ($currentStep/$totalSteps*100)
            Read-SPServiceInstance -Server $spServer.Name
            $currentStep++

            Write-Progress -Activity ("[" + $spServer.Name + "] Scanning Diagnostic Logging Settings...") -PercentComplete ($currentStep/$totalSteps*100)
            Read-DiagnosticLoggingSettings
            $currentStep++

            Write-Progress -Activity ("[" + $spServer.Name + "] Scanning Usage Service Application...") -PercentComplete ($currentStep/$totalSteps*100)
            Read-UsageServiceApplication
            $currentStep++

            Write-Progress -Activity ("[" + $spServer.Name + "] Scanning State Service Application...") -PercentComplete ($currentStep/$totalSteps*100)
            Read-StateServiceApplication
            $currentStep++

            Write-Progress -Activity ("[" + $spServer.Name + "] Scanning User Profile Service Application(s)...") -PercentComplete ($currentStep/$totalSteps*100)
            Read-UserProfileServiceapplication
            $currentStep++

            Write-Progress -Activity ("[" + $spServer.Name + "] Cache Account(s)...") -PercentComplete ($currentStep/$totalSteps*100)
            Read-CacheAccounts
            $currentStep++

            Write-Progress -Activity ("[" + $spServer.Name + "] Scanning Secure Store Service Application(s)...") -PercentComplete ($currentStep/$totalSteps*100)
            Read-SecureStoreServiceApplication
            $currentStep++

            Write-Progress -Activity ("[" + $spServer.Name + "] Scanning Business Connectivity Service Application(s)...") -PercentComplete ($currentStep/$totalSteps*100)
            Read-BCSServiceApplication
            $currentStep++

            Write-Progress -Activity ("[" + $spServer.Name + "] Scanning Search Service Application(s)...") -PercentComplete ($currentStep/$totalSteps*100)
            Read-SearchServiceApplication
            $currentStep++

            Write-Progress -Activity ("[" + $spServer.Name + "] Scanning Managed Metadata Service Application(s)...") -PercentComplete ($currentStep/$totalSteps*100)
            Read-ManagedMetadataServiceApplication
            $currentStep++

            Write-Progress -Activity ("[" + $spServer.Name + "] Configuring Local Configuration Manager (LCM)...") -PercentComplete ($currentStep/$totalSteps*100)
            Set-LCM
            $currentStep++

            $Script:dscConfigContent += "    }`r`n"
        }
    }    
    $Script:dscConfigContent += "}`r`n"
    Write-Progress -Activity "[$spServer.Name] Setting Configuration Data..." -PercentComplete ($currentStep/$totalSteps*100)
    Set-ConfigurationData
    $currentStep++
    $Script:dscConfigContent += "SharePointFarm -ConfigurationData `$ConfigData"
}

function Read-OperatingSystemVersion
{
    $servers = Get-SPServer
    $Script:dscConfigContent += "<#`r`n    Operating Systems in this Farm`r`n-------------------------------------------`r`n"
    $Script:dscConfigContent += "    Products and Language Packs`r`n"
    $Script:dscConfigContent += "-------------------------------------------`r`n"
    foreach($spServer in $servers)
    {
        $serverName = $spServer.Name
        $osInfo = Get-WmiObject Win32_OperatingSystem  -ComputerName $serverName| Select-Object @{Label="OSName"; Expression={$_.Name.Substring($_.Name.indexof("W"),$_.Name.indexof("|")-$_.Name.indexof("W"))}} , Version ,OSArchitecture -ErrorAction SilentlyContinue
        $Script:dscConfigContent += "    [" + $serverName + "]: " + $osInfo.OSName + "(" + $osInfo.OSArchitecture + ")    ----    " + $osInfo.Version + "`r`n"
    }    
    $Script:dscConfigContent += "#>`r`n`r`n"
}

function Read-SQLVersion
{
    $uniqueServers = @()
    $sqlServers = Get-SPDatabase | select Server -Unique
    foreach($sqlServer in $sqlServers)
    {
        $serverName = $sqlServer.Server.Name

        if($serverName -eq $null)
        {
            $serverName = $sqlServer.Server
        }
        
        if(!($uniqueServers -contains $serverName))
        {
            $sqlVersionInfo = Invoke-SQL -Server $serverName -dbName "Master" -sqlQuery "SELECT @@VERSION AS 'SQLVersion'"
            $uniqueServers += $serverName.ToString()
            $Script:dscConfigContent += "<#`r`n    SQL Server Product Versions Installed on this Farm`r`n-------------------------------------------`r`n"
            $Script:dscConfigContent += "    Products and Language Packs`r`n"
            $Script:dscConfigContent += "-------------------------------------------`r`n"
            $Script:dscConfigContent += "    [" + $serverName + "]: " + $sqlVersionInfo.SQLversion + "`r`n#>`r`n`r`n"
        }
    }
}

<## This function ensure all required Windows Features are properly installed on the server. #>
<# TODO: Replace this by a logic that reads the feature from te actual server and writes them down instead of simply assuming they are required. #>
function Set-ConfigurationSettings
{
    $Script:dscConfigContent += "        xCredSSP CredSSPServer { Ensure = `"Present`"; Role = `"Server`"; } `r`n"
    $Script:dscConfigContent += "        xCredSSP CredSSPClient { Ensure = `"Present`"; Role = `"Client`"; DelegateComputers = `"*." + (Get-WmiObject Win32_ComputerSystem).Domain + "`" }`r`n`r`n"

    $Script:dscConfigContent += "        xWebAppPool RemoveDotNet2Pool         { Name = `".NET v2.0`";            Ensure = `"Absent`" }`r`n"
    $Script:dscConfigContent += "        xWebAppPool RemoveDotNet2ClassicPool  { Name = `".NET v2.0 Classic`";    Ensure = `"Absent`" }`r`n"
    $Script:dscConfigContent += "        xWebAppPool RemoveDotNet45Pool        { Name = `".NET v4.5`";            Ensure = `"Absent`"; }`r`n"
    $Script:dscConfigContent += "        xWebAppPool RemoveDotNet45ClassicPool { Name = `".NET v4.5 Classic`";    Ensure = `"Absent`"; }`r`n"
    $Script:dscConfigContent += "        xWebAppPool RemoveClassicDotNetPool   { Name = `"Classic .NET AppPool`"; Ensure = `"Absent`" }`r`n"
    $Script:dscConfigContent += "        xWebAppPool RemoveDefaultAppPool      { Name = `"DefaultAppPool`";       Ensure = `"Absent`" }`r`n"
    $Script:dscConfigContent += "        xWebSite    RemoveDefaultWebSite      { Name = `"Default Web Site`";     Ensure = `"Absent`"; PhysicalPath = `"C:\inetpub\wwwroot`" }`r`n"
}

function Set-ConfigurationData
{
    $Script:dscConfigContent += "`$ConfigData = @{`r`n"
    $Script:dscConfigContent += "    AllNodes = @(`r`n"

    $spFarm = Get-SPFarm
    $spServers = $spFarm.Servers

    $tempConfigDataContent = ""
    foreach($spServer in $spServers)
    {
        $tempConfigDataContent += "    @{`r`n"
        $tempConfigDataContent += "        NodeName = `"" + $spServer.Name + "`"`r`n"
        $tempConfigDataContent += "        PSDscAllowPlainTextPassword = `$true`r`n"
        $tempConfigDataContent += "    },`r`n"
    }

    # Remove the last ',' in the array
    $tempConfigDataContent = $tempConfigDataContent.Remove($tempConfigDataContent.LastIndexOf(","), 1)
    $Script:dscConfigContent += $tempConfigDataContent
    $Script:dscConfigContent += ")}`r`n"
}

<## This function ensures all required DSC Modules are properly loaded into the current PowerShell session. #>
function Set-Imports
{
    $Script:dscConfigContent += "    Import-DscResource -ModuleName PSDesiredStateConfiguration`r`n"
    $Script:dscConfigContent += "    Import-DscResource -ModuleName SharePointDSC`r`n"
    $Script:dscConfigContent += "    Import-DscResource -ModuleName xWebAdministration`r`n"
    $Script:dscConfigContent += "    Import-DscResource -ModuleName xCredSSP`r`n"
}

<## This function receives a user name and returns the "Display Name" for that user. This function is primarly used to identify the Farm (System) account. #>
function Check-Credentials([string] $userName)
{
    if($userName -eq $Script:spCentralAdmin.ApplicationPool.ProcessAccount.Name)
    {
        return "`$CredsFarmAccount"
    }
    else
    {
        $userNameParts = $userName.Split('\')
        if($userNameParts.Length -gt 1)
        {
            return "`$Creds" + $userNameParts[1]
        }
        return "`$Creds" + $userName
    }
    return $userName
}

<## This function defines variables of type Credential for the resulting DSC Configuraton Script. Each variable declared in this method will result in the user being prompted to manually input credentials when executing the resulting script. #>
function Set-ObtainRequiredCredentials
{
    # Farm Account
    $spFarmAccount = $Script:spCentralAdmin.ApplicationPool.ProcessAccount.Name
    $requiredCredentials = @($spFarmAccount)
    $managedAccounts = Get-SPManagedAccount
    foreach($managedAccount in $managedAccounts)
    {
        $requiredCredentials += $managedAccounts.UserName
    }

    $spServiceAppPools = Get-SPServiceApplicationPool
    foreach($spServiceAppPool in $spServiceAppPools)
    {
        $requiredCredentials += $spServiceAppPools.ProcessAccount.Name
    }

    $requiredCredentials = $requiredCredentials | Select -Unique

    foreach($account in $requiredCredentials)
    {
        $accountName = $account
        if($account -eq $spFarmAccount)
        {
            $accountName = "FarmAccount"
        }
        else
        {
            $accountParts = $accountName.Split('\')
            if($accountParts.Length -gt 1)
            {
                $accountName = $accountParts[1]
            }
        }
        $Script:dscConfigContent += "    `$Creds" + $accountName + "= Get-Credential -UserName `"" + $account + "`" -Message `"Credentials for " + $account + "`"`r`n"
    }

    $Script:dscConfigContent += "`r`n"
}

<## This function really is optional, but helps provide valuable information about the various software components installed in the current SharePoint farm (i.e. Cummulative Updates, Language Packs, etc.). #>
function Read-SPProductVersions
{    
    $Script:dscConfigContent += "<#`r`n    SharePoint Product Versions Installed on this Farm`r`n-------------------------------------------`r`n"
    $Script:dscConfigContent += "    Products and Language Packs`r`n"
    $Script:dscConfigContent += "-------------------------------------------`r`n"

    if($PSVersionTable.PSVersion -like "2.*")
    {
        $RegLoc = Get-ChildItem HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall
        $Programs = $RegLoc | where-object { $_.PsPath -like "*\Office*" } | foreach {Get-ItemProperty $_.PsPath}        

        foreach($program in $Programs)
        {
            $Script:dscConfigContent += "    " +  $program.DisplayName + " -- " + $program.DisplayVersion + "`r`n"
        }
    }
    else
    {
        $regLoc = Get-ChildItem HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall
        $programs = $regLoc | where-object { $_.PsPath -like "*\Office*" } | foreach {Get-ItemProperty $_.PsPath} 
        $components = $regLoc | where-object { $_.PsPath -like "*1000-0000000FF1CE}" } | foreach {Get-ItemProperty $_.PsPath} 

        foreach($program in $programs)
        { 
            $productCodes = $_.ProductCodes
            $component = @() + ($components |     where-object { $_.PSChildName -in $productCodes } | foreach {Get-ItemProperty $_.PsPath})
            foreach($component in $components)
            {
                $Script:dscConfigContent += "    " + $component.DisplayName + " -- " + $component.DisplayVersion + "`r`n"
            }        
        }
    }
    $Script:dscConfigContent += "#>`r`n"
}

<## This function receives the path to a DSC module, and a parameter name. It then returns the type associated with the parameter (int, string, etc.). #>
function Get-DSCParamType
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)] [System.String] $FilePath,
        [parameter(Mandatory = $true)] [System.String] $ParamName
    )

    $tokens = $null 
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref] $tokens, [ref] $errors)
    $functions = $ast.FindAll( {$args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]}, $true)
    
    $functions | ForEach-Object {

        if ($_.Name -eq "Get-TargetResource") 
        {
            $function = $_
            $functionAst = [System.Management.Automation.Language.Parser]::ParseInput($_.Body, [ref] $tokens, [ref] $errors)

            $parameters = $functionAst.FindAll( {$args[0] -is [System.Management.Automation.Language.ParameterAst]}, $true)
            $parameters | ForEach-Object {
                if($_.Name.Extent.Text -eq $ParamName)
                {
                    $attributes = $_.Attributes
                    $attributes | ForEach-Object{
                        if($_.TypeName.FullName -like "System.*")
                        {
                            return $_.TypeName.FullName
                        }
                    }                    
                }
            }
        }
     }
     return $null
 }

<## This function loops through a HashTable and returns a string that combines all the Key/Value pairs into a DSC param block. #>
function Get-DSCBlock
{
    [CmdletBinding()]
    param(
        [System.Collections.Hashtable] $Params,
        [System.String] $ModulePath
    )

    $dscBlock = ""
    $foundInstallAccount = $false
    $Params.Keys | % { 
        $paramType = Get-DSCParamType -FilePath $ModulePath -ParamName "`$$_"

        $value = $null
        if($paramType -eq "System.String")
        {
            $value = "`"" + $Params.Item($_) + "`""
        }
        elseif($paramType -eq "System.Boolean")
        {
            $value = "`$" + $Params.Item($_)
        }
        elseif($paramType -eq "System.Management.Automation.PSCredential" -and $_ -ne "InstallAccount")
        {
            $value = "`$CredsFarmAccount #`"" + ($Params.Item($_)).Username + "`""
        }
        else
        {
            if($_ -eq "InstallAccount")
            {
                $value = "`$CredsFarmAccount"
                $foundInstallAccount = $true
            }
            else
            {
                $value = $Params.Item($_)
            }
        }
        $dscBlock += "            " + $_  + " = " + $value + " `r`n"
    }

    if(!$foundInstallAccount)
    {
        $dscBlock += "            PsDscRunAsCredential=`$CredsFarmAccount`r`n"
    }
    
    return $dscBlock
}

<## This function generates an empty hash containing fakes values for all input parameters of a Get-TargetResource function. #>
function Get-DSCFakeParameters{
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)] [System.String] $FilePath
    )

    $params = @{}

    $tokens = $null 
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref] $tokens, [ref] $errors)
    $functions = $ast.FindAll( {$args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]}, $true)
    
    $functions | ForEach-Object {

        if ($_.Name -eq "Get-TargetResource") 
        {
            $function = $_
            $functionAst = [System.Management.Automation.Language.Parser]::ParseInput($_.Body, [ref] $tokens, [ref] $errors)

            $parameters = $functionAst.FindAll( {$args[0] -is [System.Management.Automation.Language.ParameterAst]}, $true)
            $parameters | ForEach-Object {   
                $paramName = $_.Name.Extent.Text             
                $attributes = $_.Attributes
                $found = $false

                <# Loop once to figure out if there is a validate Set to use. #>
                $attributes | ForEach-Object{
                    if($_.TypeName.FullName -eq"ValidateSet")
                    {
                        $params.Add($paramName.Replace("`$", ""), $_.PositionalArguments[0].ToString().Replace("`"", ""))
                        $found = $true
                    }
                }
                $attributes | ForEach-Object{
                    if(!$found)
                    {
                        if($_.TypeName.FullName -eq "System.String")
                        {
                            $params.Add($paramName.Replace("`$", ""), "*")
                            $found = $true
                        }
                        elseif($_.TypeName.FullName -eq "System.UInt32")
                        {
                            $params.Add($paramName.Replace("`$", ""), 0)
                            $found = $true
                        }
                        elseif($_.TypeName.FullName -eq "System.Management.Automation.PSCredential")
                        {
                            $params.Add($paramName.Replace("`$", ""), $Script:spFarmAccount)
                            $found = $true
                        }
                        elseif($_.TypeName.FullName -eq "System.Management.Automation.Boolean" -or $_.TypeName.FullName -eq "System.Boolean")
                        {
                            $params.Add($paramName.Replace("`$", ""), $true)
                            $found = $true
                        }
                    }
                }
            }
        }
     }
     return $params
}

<## This function declares the xSPCreateFarm object required to create the config and admin database for the resulting SharePoint Farm. #>
function Read-SPFarm{
    $path = Get-Location
    Write-Host $Path.Path -BackgroundColor DarkMagenta
    $module = Resolve-Path "..\..\DSCResources\MSFT_SPCreateFarm\MSFT_SPCreateFarm.psm1"
    Import-Module $module
    $Script:dscConfigContent += "        SPCreateFarm CreateSPFarm{`r`n"
    $params = Get-DSCFakeParameters -FilePath $module

    <# If not SP2016, remove the server role param. #>
    if ($null -ne $ServerRole -or (Get-SPDSCInstalledProductVersion).FileMajorPart -ne 16) {
        $params.Remove("ServerRole")
    }

    $results = Get-TargetResource @params
    $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
    $Script:dscConfigContent += "        }`r`n"
}

<## This function obtains a reference to every Web Application in the farm and declares their properties (i.e. Port, Associated IIS Application Pool, etc.). #>
function Read-SPWebApplications
{
    $module = Resolve-Path "..\..\DSCResources\MSFT_SPWebApplication\MSFT_SPWebApplication.psm1"
    Import-Module $module

    $spWebApplications = Get-SPWebApplication | Sort-Object -Property Name
    $params = Get-DSCFakeParameters -FilePath $module
    
    foreach($spWebApp in $spWebApplications)
    {
        $Script:dscConfigContent += "        SPWebApplication " + $spWebApp.Name.Replace(" ", "") + "{`r`n"      

        $params.Name = $spWebApp.Name
        $results = Get-TargetResource @params

    
        $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
        $Script:dscConfigContent += "        }`r`n"
    }
}

<## This function loops through every IIS Application Pool that are associated with the various existing Service Applications in the SharePoint farm. ##>
function Read-SPServiceApplicationPools
{
    $module = Resolve-Path "..\..\DSCResources\MSFT_SPServiceAppPool\MSFT_SPServiceAppPool.psm1"
    Import-Module $module
    $spServiceAppPools = Get-SPServiceApplicationPool | Sort-Object -Property Name
    $params = Get-DSCFakeParameters -FilePath $module

    foreach($spServiceAppPool in $spServiceAppPools)
    {
        $Script:dscConfigContent += "        SPServiceAppPool " + $spServiceAppPool.Name.Replace(" ", "") + "`r`n"
        $Script:dscConfigContent += "        {`r`n"
        $params.Name = $spServiceAppPool.Name
        $results = Get-TargetResource @params    
        $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
        $Script:dscConfigContent += "        }`r`n"
    }
}

<## This function retrieves a list of all site collections, no matter what Web Application they belong to. The Url attribute helps the xSharePoint DSC Resource determine what Web Application they belong to. #>
function Read-SPSites
{
    $module = Resolve-Path "..\..\DSCResources\MSFT_SPSite\MSFT_SPSite.psm1"
    Import-Module $module
    $spSites = Get-SPSite -Limit All

    $params = Get-DSCFakeParameters -FilePath $module
    $siteGuid = $null
    $siteTitle = $null
    foreach($spsite in $spSites)
    {
        $siteGuid = [System.Guid]::NewGuid().toString()
        $siteTitle = $spSite.RootWeb.Title
        if($siteTitle -eq $null)
        {
            $siteTitle = "SiteCollection"
        }
        $Script:dscConfigContent += "        SPSite " + $siteTitle.Replace(" ", "") + "-" + $siteGuid + "`r`n"
        $Script:dscConfigContent += "        {`r`n"
        $params.Url = $spsite.Url
        $results = Get-TargetResource @params    
        $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
        $Script:dscConfigContent += "        }`r`n"
    }
}

<## This function generates a list of all Managed Paths, no matter what their associated Web Application is. The xSharePoint DSC Resource uses the WebAppUrl attribute to identify what Web Applicaton they belong to. #>
function Read-SPManagedPaths
{
    $module = Resolve-Path "..\..\DSCResources\MSFT_SPManagedPath\MSFT_SPManagedPath.psm1"
    Import-Module $module

    $spWebApps = Get-SPWebApplication

    $params = Get-DSCFakeParameters -FilePath $module
    foreach($spWebApp in $spWebApps)
    {
        $spManagedPaths = Get-SPManagedPath -WebApplication $spWebApp.Url | Sort-Object -Property Name

        foreach($spManagedPath in $spManagedPaths)
        {
            if($spManagedPath.Name.Length -gt 0 -and $spManagedPath.Name -ne "sites")
            {
                $Script:dscConfigContent += "        SPManagedPath " + $spWebApp.Name.Replace(" ", "") + "Path" + $spManagedPath.Name + "`r`n"
                $Script:dscConfigContent += "        {`r`n"
                if($spManagedPath.Name -ne $null)
                {
                    $params.RelativeUrl = $spManagedPath.Name
                }                
                $params.WebAppUrl = $spWebApp.Url
                $params.HostHeader = $false;
                $results = Get-TargetResource @params    
                $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
                $Script:dscConfigContent += "        }`r`n"
            }            
        }

        $spManagedPaths = Get-SPManagedPath -HostHeader | Sort-Object -Property Name
        foreach($spManagedPath in $spManagedPaths)
        {
            if($spManagedPath.Name.Length -gt 0 -and $spManagedPath.Name -ne "sites")
            {
                $Script:dscConfigContent += "        SPManagedPath " + $spWebApp.Name.Replace(" ", "") + "Path" + $spManagedPath.Name + "`r`n"
                $Script:dscConfigContent += "        {`r`n"
                
                if($spManagedPath.Name -ne $null)
                {
                    $params.RelativeUrl = $spManagedPath.Name
                } 
                if($params.ContainsKey("Explicit"))
                {
                    $params.Explicit = ($spManagedPath.Type -eq "ExplicitInclusion")
                }
                else
                {
                    $params.Add("Explicit", ($spManagedPath.Type -eq "ExplicitInclusion"))
                }
                $params.HostHeader = $true;
                $params.WebAppUrl = $spWebApp.Url
                $results = Get-TargetResource @params
                $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
                $Script:dscConfigContent += "        }`r`n"
            }            
        }
    }
}

<## This function retrieves all Managed Accounts in the SharePoint Farm. The Account attribute sets the associated credential variable (each managed account is declared as a variable and the user is prompted to Manually enter the credentials when first executing the script. See function "Set-ObtainRequiredCredentials" for more details on how these variales are set. #>
function Read-SPManagedAccounts
{
    $module = Resolve-Path "..\..\DSCResources\MSFT_SPManagedAccount\MSFT_SPManagedAccount.psm1"
    Import-Module $module

    $managedAccounts = Get-SPManagedAccount
    $params = Get-DSCFakeParameters -FilePath $module
    foreach($managedAccount in $managedAccounts)
    {
        $Script:dscConfigContent += "        SPManagedAccount " + (Check-Credentials $managedAccount.Username).Replace("$","") + "`r`n"
        $Script:dscConfigContent += "        {`r`n"
        $results = Get-TargetResource @params
        $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
        $Script:dscConfigContent += "        }`r`n"
    }
}

<## This function retrieves all Services in the SharePoint farm. It does not care if the service is enabled or not. It lists them all, and simply sets the "Ensure" attribute of those that are disabled to "Absent". #>
function Read-SPServiceInstance
{
    $module = Resolve-Path "..\..\DSCResources\MSFT_SPServiceInstance\MSFT_SPServiceInstance.psm1"
    Import-Module $module

    $serviceInstances = Get-SPServiceInstance | Where{$_.Server.Name -eq $Server} | Sort-Object -Property TypeName
    $params = Get-DSCFakeParameters -FilePath $module

    foreach($serviceInstance in $serviceInstances)
    {
        $params.Name = $serviceInstance.Name
        if($serviceInstance.TypeName -eq "Distributed Cache")
        {
            $Script:dscConfigContent += "        SPDistributedCacheService " + $serviceInstance.TypeName.Replace(" ", "") + "Instance`r`n"
            $Script:dscConfigContent += "        {`r`n"
            $results = Get-TargetResource @params
            $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
            $Script:dscConfigContent += "        }`r`n"
        }
        elseif($serviceInstance.TypeName -eq "User Profile Synchronization Service")
        {
            $Script:dscConfigContent += "        SPUserProfileSyncService " + $serviceInstance.TypeName.Replace(" ", "") + "Instance`r`n"
            $Script:dscConfigContent += "        {`r`n"
            $results = Get-TargetResource @params
            $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
            $Script:dscConfigContent += "        }`r`n"
        }
        else
        {
            $Script:dscConfigContent += "        SPServiceInstance " + $serviceInstance.TypeName.Replace(" ", "") + "Instance`r`n"
            $Script:dscConfigContent += "        {`r`n"
            $results = Get-TargetResource @params
            $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
            $Script:dscConfigContent += "        }`r`n"
        }
    }
}

<## This function retrieves all settings related to Diagnostic Logging (ULS logs) on the SharePoint farm. #>
function Read-DiagnosticLoggingSettings
{
    $module = Resolve-Path "..\..\DSCResources\MSFT_SPDiagnosticLoggingSettings\MSFT_SPDiagnosticLoggingSettings.psm1"
    Import-Module $module
    $params = Get-DSCFakeParameters -FilePath $module
    $diagConfig = Get-SPDiagnosticConfig    

    $Script:dscConfigContent += "        SPDiagnosticLoggingSettings ApplyDiagnosticLogSettings`r`n"
    $Script:dscConfigContent += "        {`r`n"
    $results = Get-TargetResource @params
    $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
    $Script:dscConfigContent += "        }`r`n"
}

<## This function retrieves all settings related to the SharePoint Usage Service Application, assuming it exists. #>
function Read-UsageServiceApplication
{
    $module = Resolve-Path "..\..\DSCResources\MSFT_SPUsageApplication\MSFT_SPUsageApplication.psm1"
    Import-Module $module
    $params = Get-DSCFakeParameters -FilePath $module

    $usageApplication = Get-SPUsageApplication
    if($usageApplication.Length -gt 0)
    {
        $Script:dscConfigContent += "        SPUsageApplication " + $usageApplication.TypeName.Replace(" ", "") + "`r`n"
        $Script:dscConfigContent += "        {`r`n"
        $results = Get-TargetResource @params
        $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
        $Script:dscConfigContent += "        }`r`n"
    }
}

<## This function retrieves settings associated with the State Service Application, assuming it exists. #>
function Read-StateServiceApplication
{
    $module = Resolve-Path "..\..\DSCResources\MSFT_SPStateServiceApp\MSFT_SPStateServiceApp.psm1"
    Import-Module $module
    $params = Get-DSCFakeParameters -FilePath $module

    $stateApplications = Get-SPStateServiceApplication
    foreach($stateApp in $stateApplications)
    {
        if($stateApp -ne $null)
        {
            $params.Name = $stateApp.DisplayName
            $Script:dscConfigContent += "        SPStateServiceApp " + $stateApp.DisplayName.Replace(" ", "") + "`r`n"
            $Script:dscConfigContent += "        {`r`n"
            $results = Get-TargetResource @params
            $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
            $Script:dscConfigContent += "        }`r`n"
        }
    }
}

<## This function retrieves information about all the "Super" accounts (Super Reader & Super User) used for caching. #>
function Read-CacheAccounts
{
    $module = Resolve-Path "..\..\DSCResources\MSFT_SPCacheAccounts\MSFT_SPCacheAccounts.psm1"
    Import-Module $module
    $params = Get-DSCFakeParameters -FilePath $module

    $webApps = Get-SPWebApplication

    foreach($webApp in $webApps)
    {
        $params.WebAppUrl = $webApp.Url
        $results = Get-TargetResource @params

        $accountsMissing = 0
        if($params.SuperReaderAlias -ne "" -and $params.SuperUserAlias -ne "")
        {
            $Script:dscConfigContent += "        SPCacheAccounts " + $webApp.DisplayName.Replace(" ", "") + "CacheAccounts`r`n"
            $Script:dscConfigContent += "        {`r`n"        
            $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
            $Script:dscConfigContent += "        }`r`n"
        }
    }
}

<## This function retrieves settings related to the User Profile Service Application. #>
function Read-UserProfileServiceapplication
{
    $module = Resolve-Path "..\..\DSCResources\MSFT_SPUserProfileServiceApp\MSFT_SPUserProfileServiceApp.psm1"
    Import-Module $module
    $params = Get-DSCFakeParameters -FilePath $module

    $ups = Get-SPServiceApplication | Where{$_.TypeName -eq "User Profile Service Application"}

    $sites = Get-SPSite
    if($sites.Length -gt 0)
    {
        $context = Get-SPServiceContext $sites[0]
        try
        {
            $pm = new-object Microsoft.Office.Server.UserProfiles.UserProfileManager($context)
        }
        catch{
            $Script:dscConfigContent += "        <# WARNING: It appears the farm account doesn't have Full Control to the User Profile Service Aplication. This is currently preventing the script from determining the exact path for the MySite Host (if configured). Please ensure the Farm account is granted Full Control on the User Profile Service Application. #>`r`n"
            Write-Host "WARNING - Farm Account does not have Full Control on the User Profile Service Application." -BackgroundColor Yellow -ForegroundColor Black
        }

        if($ups -ne $null)
        {
            $params.Name = $ups.DisplayName
            $Script:dscConfigContent += "        SPUserProfileServiceApp UserProfileServiceApp`r`n"
            $Script:dscConfigContent += "        {`r`n"
            $results = Get-TargetResource @params
            $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
            $Script:dscConfigContent += "        }`r`n"
        }
    }
}

<## This function retrieves all settings related to the Secure Store Service Application. Currently this function makes a direct call to the Secure Store database on the farm's SQL server to retrieve information about the logging details. There are currently no publicly available hooks in the SharePoint/Office Server Object Model that allow us to do it. This forces the user executing this reverse DSC script to have to install the SQL Server Client components on the server on which they execute the script, which is not a "best practice". #>
<# TODO: Change the logic to extract information about the logging from being a direct SQL call to something that uses the Object Model. #>
function Read-SecureStoreServiceApplication
{
    $module = Resolve-Path "..\..\DSCResources\MSFT_SPSecureStoreServiceApp\MSFT_SPSecureStoreServiceApp.psm1"
    Import-Module $module
    $params = Get-DSCFakeParameters -FilePath $module

    $ssa = Get-SPServiceApplication | Where{$_.TypeName -eq "Secure Store Service Application"}
    for($i = 0; $i -lt $ssa.Length; $i++)
    {
        $params.Name = $ssa.DisplayName
        $Script:dscConfigContent += "        SPSecureStoreServiceApp " + $ssa[$i].Name.Replace(" ", "") + "`r`n"
        $Script:dscConfigContent += "        {`r`n"
        $results = Get-TargetResource @params

        # HACK: Can't dynamically retrieve value from the Secure Store at the moment #>
        $results.Add("AuditingEnabled", $true)

        $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
        $Script:dscConfigContent += "        }`r`n"        
    }
}

<## This function retrieves settings related to the Managed Metadata Service Application. #>
function Read-ManagedMetadataServiceApplication
{
    $module = Resolve-Path "..\..\DSCResources\MSFT_SPManagedMetadataServiceApp\MSFT_SPManagedMetadataServiceApp.psm1"
    Import-Module $module
    $params = Get-DSCFakeParameters -FilePath $module

    $mms = Get-SPServiceApplication | Where{$_.TypeName -eq "Managed Metadata Service"}
    if (Get-Command "Get-SPMetadataServiceApplication" -errorAction SilentlyContinue)
    {
        foreach($mmsInstance in $mms)
        {
            if($mmsInstance -ne $null)
            {
                $params.Name = $mmsInstance.Name
                $Script:dscConfigContent += "        SPManagedMetaDataServiceApp " + $mmsInstance.Name.Replace(" ", "") + "`r`n"
                $Script:dscConfigContent += "        {`r`n"
                $results = Get-TargetResource @params
                $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
                $Script:dscConfigContent += "        }`r`n"
            }
        }
    }
}

<## This function retrieves settings related to the Business Connectivity Service Application. #>
function Read-BCSServiceApplication
{
    $module = Resolve-Path "..\..\DSCResources\MSFT_SPBCSServiceApp\MSFT_SPBCSServiceApp.psm1"
    Import-Module $module
    $params = Get-DSCFakeParameters -FilePath $module

    $bcsa = Get-SPServiceApplication | Where{$_.TypeName -eq "Business Data Connectivity Service Application"}
    
    foreach($bcsaInstance in $bcsa)
    {
        if($bcsaInstance -ne $null)
        {
            $Script:dscConfigContent += "        SPBCSServiceApp " + $bcsaInstance.Name.Replace(" ", "") + "`r`n"
            $Script:dscConfigContent += "        {`r`n"
            $params.Name = $bcsa.DisplayName
            $results = Get-TargetResource @params
            $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
            $Script:dscConfigContent += "        }`r`n"        
        }
    }
}

<## This function retrieves settings related to the Search Service Application. #>
function Read-SearchServiceApplication
{
    $module = Resolve-Path "..\..\DSCResources\MSFT_SPSearchServiceApp\MSFT_SPSearchServiceApp.psm1"
    Import-Module $module
    $params = Get-DSCFakeParameters -FilePath $module

    $searchSA = Get-SPServiceApplication | Where{$_.TypeName -eq "Search Service Application"}
    
    foreach($searchSAInstance in $searchSA)
    {
        if($searchSAInstance -ne $null)
        {
            $Script:dscConfigContent += "        SPSearchServiceApp " + $searchSAInstance.Name.Replace(" ", "") + "`r`n"
            $Script:dscConfigContent += "        {`r`n"
            $params.Name = $searchSAInstance.Name
            $results = Get-TargetResource @params
            $Script:dscConfigContent += Get-DSCBlock -Params $results -ModulePath $module
            $Script:dscConfigContent += "        }`r`n"  
        }
    }
}

<## This function sets the settings for the Local Configuration Manager (LCM) component on the server we will be configuring using our resulting DSC Configuration script. The LCM component is the one responsible for orchestrating all DSC configuration related activities and processes on a server. This method specifies settings telling the LCM to not hesitate rebooting the server we are configurating automatically if it requires a reboot (i.e. During the SharePoint Prerequisites installation). Setting this value helps reduce the amount of manual interaction that is required to automate the configuration of our SharePoint farm using our resulting DSC Configuration script. #>
function Set-LCM
{
    $Script:dscConfigContent += "        LocalConfigurationManager"  + "`r`n"
    $Script:dscConfigContent += "        {`r`n"
    $Script:dscConfigContent += "            RebootNodeIfNeeded = `$True`r`n"
    $Script:dscConfigContent += "        }`r`n"
}

function Invoke-SQL {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Server,
        [Parameter(Mandatory=$true)]
        [string]$dbName,
        [Parameter(Mandatory=$true)]
        [string]$sqlQuery
    )
 
    $ConnectString="Data Source=${Server}; Integrated Security=SSPI; Initial Catalog=${dbName}"
 
    $Conn= New-Object System.Data.SqlClient.SQLConnection($ConnectString)
    $Command = New-Object System.Data.SqlClient.SqlCommand($sqlQuery,$Conn)
    $Conn.Open()
 
    $Adapter = New-Object System.Data.SqlClient.SqlDataAdapter $Command
    $DataSet = New-Object System.Data.DataSet
    $Adapter.Fill($DataSet) | Out-Null
 
    $Conn.Close()
    $DataSet.Tables
}


<## This method is used to determine if a specific PowerShell cmdlet is available in the current Powershell Session. It is currently used to determine wheter or not the user has access to call the Invoke-SqlCmd cmdlet or if he needs to install the SQL Client coponent first. It simply returns $true if the cmdlet is available to the user, or $false if it is not. #>
function Test-CommandExists
{
    param ($command)

    $errorActionPreference = "stop"
    try {
        if(Get-Command $command)
        {
            return $true
        }
    }
    catch
    {
        return $false
    }
}

function Get-SPReverseDSC()
{
	<## Call into our main function that is responsible for extracting all the information about our SharePoint farm. #>
	Orchestrator

	<## Prompts the user to specify the FOLDER path where the resulting PowerShell DSC Configuration Script will be saved. #>
	$OutputDSCPath = Read-Host "Output Folder for DSC Configuration"

	<## Ensures the path we specify ends with a Slash, in order to make sure the resulting file path is properly structured. #>
	if(!$OutputDSCPath.EndsWith("\") -and !$OutputDSCPath.EndsWith("/"))
	{
		$OutputDSCPath += "\"
	}

	<## Save the content of the resulting DSC Configuration file into a file at the specified path. #>
	$OutputDSCPath += "SP-Farm.DSC.ps1"
	$Script:dscConfigContent | Out-File $OutputDSCPath
}
