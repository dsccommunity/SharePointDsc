
<## Scripts Variables #>
$Script:DH_SPQUOTATEMPLATE = @{}
$Script:dscConfigContent = ""
$Global:AllUsers = @()
$Script:ErrorLog = ""
$Script:configName = ""
$Script:currentServerName = ""
$SPDSCSource = "$env:ProgramFiles\WindowsPowerShell\Modules\SharePointDSC\"
$SPDSCVersion = "4.4.0.0"
$Script:spCentralAdmin = ""
$Script:ExtractionModeValue = "2"
$script:SkipSitesAndWebs = $SkipSitesAndWebs
function Start-SharePointDSCExtract
{
    param
    (
        [Parameter()]
        [switch]
        $Quiet = $false,

        [Parameter()]
        [ValidateSet("Lite", "Default", "Full")]
        [System.String]
        $Mode = "Default",

        [Parameter()]
        [switch]
        $Standalone,

        [Parameter()]
        [Boolean]
        $Confirm = $true,

        [Parameter()]
        [String]
        $OutputFile = $null,

        [Parameter()]
        [String]
        $OutputPath = $null,

        [Parameter()]
        [switch]
        $SkipSitesAndWebs = $false,

        [Parameter()]
        [switch]
        $Azure = $false,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credentials,

        [Parameter()]
        [System.Object[]]
        $ComponentsToExtract,

        [Parameter()]
        [switch]
        $DynamicCompilation,

        [Parameter()]
        [String]
        $ProductKey,

        [Parameter()]
        [String]
        $BinaryLocation
    )

    <## Script Settings #>
    $VerbosePreference = "SilentlyContinue"

    if ($Quiet)
    {
        Write-Warning "-Quiet is deprecated. For unattended extraction, please use the -ComponentsToExtract parameter."
    }

    if ($Mode.ToLower() -eq "lite")
    {
        $Script:ExtractionModeValue = 1
    }
    elseif ($Mode.ToLower() -eq "full")
    {
        $Script:ExtractionModeValue = 3
    }

    try
    {
        $currentScript = Test-ScriptFileInfo $SCRIPT:MyInvocation.MyCommand.Path
        $Script:version = $currentScript.Version.ToString()
    }
    catch
    {
        $Script:version = $SPDSCVersion
    }
    $Script:SPDSCPath = $SPDSCSource + $SPDSCVersion
    $Global:spFarmAccount = ""

    Add-PSSnapin Microsoft.SharePoint.PowerShell -EA SilentlyContinue
    $sharePointSnapin = Get-PSSnapin | Where-Object { $_.Name -eq "Microsoft.SharePoint.PowerShell" }
    if ($null -ne $sharePointSnapin)
    {
        if ($Quiet -or $ComponentsToExtract.Count -gt 0)
        {
            if ($StandAlone)
            {
                if ($DynamicCompilation)
                {
                    Get-SPReverseDSC -ComponentsToExtract $ComponentsToExtract -Credentials $Credentials -OutputPath $OutputPath -StandAlone -DynamicCompilation -ProductKey $ProductKey -BinaryLocation $BinaryLocation
                }
                else
                {
                    Get-SPReverseDSC -ComponentsToExtract $ComponentsToExtract -Credentials $Credentials -OutputPath $OutputPath -StandAlone -ProductKey $ProductKey -BinaryLocation $BinaryLocation
                }
            }
            else
            {
                Get-SPReverseDSC -ComponentsToExtract $ComponentsToExtract -Credentials $Credentials -OutputPath $OutputPath -ProductKey $ProductKey -BinaryLocation $BinaryLocation
            }
        }
        else
        {
            [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
            [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
            DisplayGUI
        }
    }
    else
    {
        Write-Host "`r`nE102"  -BackgroundColor Red -ForegroundColor Black -NoNewline
        Write-Host "    - We couldn't detect a SharePoint installation on this machine. Please execute the SharePoint ReverseDSC script on an existing SharePoint server."
    }
}
function Get-SPReverseDSC
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object[]]
        $ComponentsToExtract,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credentials,

        [Parameter()]
        [System.String]
        $OutputPath,

        [Parameter()]
        [System.String]
        $OutputFile,

        [Parameter()]
        [Switch]
        $Standalone,

        [Parameter()]
        [Switch]
        $DynamicCompilation,

        [Parameter()]
        [System.String]
        $ProductKey,

        [Parameter()]
        [System.String]
        $BinaryLocation
    )

    if ($StandAlone)
    {
        if ($DynamicCompilation)
        {
            Orchestrator -ComponentsToExtract $ComponentsToExtract -Credentials $Credentials -StandAlone -DynamicCompilation -BinaryLocation $BinaryLocation -ProductKey $ProductKey
        }
        else
        {
            Orchestrator -ComponentsToExtract $ComponentsToExtract -Credentials $Credentials -StandAlone -BinaryLocation $BinaryLocation -ProductKey $ProductKey
        }
    }
    else
    {
        <## Call into our main function that is responsible for extracting all the information about our SharePoint farm. #>
        Orchestrator -ComponentsToExtract $ComponentsToExtract -Credentials $Credentials -BinaryLocation $BinaryLocation -ProductKey $ProductKey
    }

    <## Prompts the user to specify the FOLDER path where the resulting PowerShell DSC Configuration Script will be saved. #>
    $fileName = "SPFarmConfig"
    if ($chckStandalone.Checked)
    {
        $Standalone = $true
    }
    if ($Standalone)
    {
        $fileName = "SPStandalone"
    }
    elseif ($Global:ExtractionModeValue -eq 3)
    {
        $fileName += "-Full"
    }
    elseif ($Global:ExtractionModeValue -eq 1)
    {
        $fileName += "-Lite"
    }
    $fileName += ".ps1"
    if (!$outputfile)
    {
        if ($OutputPath)
        {
            $OutputDSCPath = $OutputPath
        }
        else
        {
            $OutputDSCPath = Read-Host "Please enter the full path of the output folder for DSC Configuration (will be created as necessary)"
        }
    }
    else
    {
        $OutputFile = $OutputFile.Replace("/", "\")
        $fileName = Split-Path $OutputFile -Leaf
        $OutputDSCPath = Split-Path $OutputFile -Parent
    }

    <## Ensures the specified output folder path actually exists; if not, tries to create it and throws an exception if we can't. ##>
    while (!(Test-Path -Path $OutputDSCPath -PathType Container -ErrorAction SilentlyContinue))
    {
        try
        {
            Write-Output "Directory `"$OutputDSCPath`" doesn't exist; creating..."
            New-Item -Path $OutputDSCPath -ItemType Directory | Out-Null
            if ($?)
            { break
            }
        }
        catch
        {
            Write-Warning "$($_.Exception.Message)"
            Write-Warning "Could not create folder $OutputDSCPath!"
        }
        $OutputDSCPath = Read-Host "Please Enter Output Folder for DSC Configuration (Will be Created as Necessary)"
    }
    <## Ensures the path we specify ends with a Slash, in order to make sure the resulting file path is properly structured. #>
    if (!$OutputDSCPath.EndsWith("\") -and !$OutputDSCPath.EndsWith("/"))
    {
        $OutputDSCPath += "\"
    }

    <# Now that we have acquired the output path, save all custom solutions (.wsp) in that directory; #>
    if ($chckFarmSolution.Checked)
    {
        Save-SPFarmsolution($OutputDSCPath)
    }

    <## Save the content of the resulting DSC Configuration file into a file at the specified path. #>
    $outputDSCFile = $OutputDSCPath + $fileName
    $Script:dscConfigContent | Out-File $outputDSCFile

    <# Add the list of all user accounts detected to the configurationdata #>
    if ($Global:AllUsers.Length -gt 0)
    {
        $missingUsers = ""
        foreach ($missingUser in $Global:AllUsers)
        {
            $missingUsers += "`"" + $missingUser + "`","
        }
        $missingUsers = "@(" + $missingUsers.Remove($missingUsers.Length - 1, 1) + ")"
        Add-ConfigurationDataEntry -Node "NonNodeData" -Key "RequiredUsers" -Value $missingUsers -Description "List of user accounts that were detected that you need to ensure exist in the destination environment;"
    }

    if ($chckAzure.Checked)
    {
        $Azure = $true
    }
    if (!$Azure)
    {
        $outputConfigurationData = $OutputDSCPath + "ConfigurationData.psd1"
        New-ConfigurationDataDocument -Path $outputConfigurationData
    }
    else
    {
        $resGroupName = Read-Host "Destination Resource Group Name"
        $automationAccountName = Read-Host "Destination Automation Account Name"

        $azureDeployScriptPath = $OutputDSCPath + "DeployToAzure.ps1"
        $configurationDataContent = Get-ConfigurationDataContent
        $deployScriptContent = "Login-AzureRMAccount`r`n`$configData = " + $configurationDataContent + "`r`n" + `
            "Import-AzureRmAutomationDscConfiguration -SourcePath (Get-Item '.\" + ($Script:configName + ".ps1") + "').FullName -ResourceGroupName `"" + $resGroupName + "`" -AutomationAccountName `"" + $automationAccountName + "`" -Verbose -Published -Force`r`n" + `
            "Start-AzureRmAutomationDscCompilationJob -ResourceGroupName `"" + $resGroupName + "`" -AutomationAccountName `"" + $automationAccountName + "`" -ConfigurationName `"" + $Script:configName + "`" -ConfigurationData `$configData"
        $deployScriptContent | Out-File $azureDeployScriptPath
    }

    # Generate the Required User Script if the checkbox is selected;
    if ($chckRequiredUsers.Checked)
    {
        New-RequiredUsersScript -Location ($OutputDSCPath + "GenerateRequiredUsers.ps1")
    }

    if ($Global:ErrorLog)
    {
        $errorLogPath = $OutputDSCPath + "SharePointDSC.Reverse-Errors.log"
        $Global:ErrorLog | Out-File $errorLogPath
    }

    <## Wait a second, then open our $outputDSCPath in Windows Explorer so we can review the glorious output. ##>
    Start-Sleep 1
    Invoke-Item -Path $OutputDSCPath
}

function Read-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $ResourceName,

        [Parameter()]
        [System.Collections.HashTable]
        $ExportParams
    )
    $ParentModueBase = Get-Module "SharePointDSC" | Select-Object -ExpandProperty Modulebase
    $ResourcesPath = Join-Path -Path $ParentModueBase -ChildPath "DSCResources" -Resolve
    $ResourceModule = Get-ChildItem $ResourcesPath -Recurse | Where-Object { $_.Name -like "MSFT_$($ResourceName).psm1" }

    try
    {
        $ModuleName = $ResourceModule.Name.Split('.')[0]
    }
    catch
    {
        Write-Host "$($ResourceName) not found" -ForegroundColor Magenta
    }

    try
    {
        $FriendlyName = $ModuleName.Replace("MSFT_", "")
        if ($Null -eq $Components -or $Components.Contains($FriendlyName))
        {
            Import-Module $ResourceModule.FullName -Scope Local | Out-Null
            $module = Get-Module ($ModuleName) | Where-Object -FilterScript { $_.ExportedCommands.Keys -contains 'Export-TargetResource' }
            if ($null -ne $module)
            {
                Write-Information "Exporting $($module.Name)"
                $exportString = Export-TargetResource @ExportParams
                return $exportString
                #[void]$sb.Append($exportString)
            }
        }
    }
    catch
    {
        $_
        $Global:ErrorLog += "Read-TargetResource $($ResourceName)`r`n"
        $Global:ErrorLog += "$_`r`n`r`n"
    }
}
function Orchestrator
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [switch]
        $Standalone,

        [Parameter()]
        [String]
        $OutputPath = $null,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credentials,

        [Parameter()]
        [System.Object[]]
        $ComponentsToExtract,

        [Parameter()]
        [switch]$DynamicCompilation,

        [Parameter()]
        [String]
        $ProductKey,

        [Parameter()]
        [String]
        $BinaryLocation
    )

    <#Skipped function for current time to disuss with Robert#>
    #Test-Prerequisites

    Import-Module -Name "ReverseDSC" -Force

    $Global:ComponentsToExtract = $ComponentsToExtract

    if ($Credentials)
    {
        $Global:spFarmAccount = $Credentials
    }
    else
    {
        $Global:spFarmAccount = Get-Credential -Message "Credentials with Farm Admin Rights" -UserName $env:USERDOMAIN\$env:USERNAME
    }
    Save-Credentials $Global:spFarmAccount.UserName

    <# Moved to Export-Target of MSFT_SPFarm.psm1
    #$Script:spCentralAdmin = Get-SPWebApplication -IncludeCentralAdministration | Where-Object{$_.DisplayName -like '*Central Administration*'}
     #>
    $spFarm = Get-SPFarm
    $spServers = $spFarm.Servers
    if ($Standalone)
    {
        $i = 0;
        foreach ($spServer in $spServers)
        {
            if ($i -eq 0)
            {
                $spServers = @($spServer)
            }
            $i++
        }
    }
    $Script:dscConfigContent += "<# Generated with SharePointDSC " + $script:version + " #>`r`n"

    Write-Host "Scanning Operating System Version..." -BackgroundColor DarkGreen -ForegroundColor White
    Read-OperatingSystemVersion

    Write-Host "Scanning SQL Server Version..." -BackgroundColor DarkGreen -ForegroundColor White
    Read-SQLVersion

    Write-Host "Scanning Patch Levels..." -BackgroundColor DarkGreen -ForegroundColor White
    Read-SPProductVersions

    $configName = "SharePointFarm"
    if ($Standalone)
    {
        $configName = "SharePointStandalone"
    }
    $Script:dscConfigContent += "Configuration $configName`r`n"
    $Script:dscConfigContent += "{`r`n"
    $Script:dscConfigContent += "    <# Credentials #>`r`n"

    Write-Host "Configuring Dependencies..." -BackgroundColor DarkGreen -ForegroundColor White
    Set-Imports

    $serverNumber = 1
    foreach ($spServer in $spServers)
    {
        $Script:currentServerName = $spServer.Name

        <## SQL servers are returned by Get-SPServer but they have a Role of 'Invalid'. Therefore we need to ignore these. The resulting PowerShell DSC Configuration script does not take into account the configuration of the SQL server for the SharePoint Farm at this point in time. We are activaly working on giving our users an experience that is as painless as possible, and are planning on integrating the SQL DSC Configuration as part of our feature set. #>
        if ($spServer.Role -ne "Invalid")
        {
            Add-ConfigurationDataEntry -Node $Script:currentServerName -Key "ServerNumber" -Value $serverNumber -Description ""
            $Script:dscConfigContent += "`r`n    Node `$AllNodes.Where{`$_.ServerNumber -eq '" + $serverNumber.ToString() + "'}.NodeName`r`n    {`r`n"

            Write-Host "["$spServer.Name"] Generating the SharePoint Prerequisites Installation..." -BackgroundColor DarkGreen -ForegroundColor White
            $Script:dscConfigContent += Read-TargetResource -ResourceName SPInstallPrereqs

            Write-Host "["$spServer.Name"] Generating the SharePoint Binary Installation..." -BackgroundColor DarkGreen -ForegroundColor White
            $Script:dscConfigContent += Read-TargetResource -ResourceName SPInstall

            Write-Host "["$spServer.Name"] Scanning the SharePoint Farm..." -BackgroundColor DarkGreen -ForegroundColor White
            $Script:dscConfigContent += Read-TargetResource -ResourceName SPFarm -ExportParams @{ServerName = $spServer.Address }

            if ($serverNumber -eq 1)
            {
                Write-Host "["$spServer.Name"] Scanning Managed Account(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPManagedAccount

                Write-Host "["$spServer.Name"] Scanning Web Application(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPWebApplication

                Write-Host "["$spServer.Name"] Scanning Web Application(s) Permissions..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPWebAppPermissions

                Write-Host "["$spServer.Name"] Scanning Alternate Url(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPAlternateUrl

                Write-Host "["$spServer.Name"] Scanning Managed Path(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPManagedPath

                Write-Host "["$spServer.Name"] Scanning Application Pool(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPServiceAppPool

                Write-Host "["$spServer.Name"] Scanning Content Database(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPContentDatabase

                Write-Host "["$spServer.Name"] Scanning Quota Template(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPQuotaTemplate

                Write-Host "["$spServer.Name"] Scanning Site Collection(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPSite

                Write-Host "["$spServer.Name"] Scanning Diagnostic Logging Settings..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPDiagnosticLoggingSettings

                Write-Host "["$spServer.Name"] Scanning Usage Service Application..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPUsageApplication

                Write-Host "["$spServer.Name"] Scanning Web Application Policy..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPWebAppPolicy

                Write-Host "["$spServer.Name"] Scanning State Service Application..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPStateServiceApp

                Write-Host "["$spServer.Name"] Scanning User Profile Service Application(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPUserProfileServiceApp

                Write-Host "["$spServer.Name"] Scanning Machine Translation Service Application(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPMachineTranslationServiceApp

                Write-Host "["$spServer.Name"] Cache Account(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPCacheAccounts

                Write-Host "["$spServer.Name"] Scanning Secure Store Service Application(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPSecureStoreServiceApp

                Write-Host "["$spServer.Name"] Scanning Business Connectivity Service Application(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPBCSServiceApp

                Write-Host "["$spServer.Name"] Scanning Search Service Application(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPSearchServiceApp

                Write-Host "["$spServer.Name"] Scanning Managed Metadata Service Application(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPManagedMetadataServiceApp

                Write-Host "["$spServer.Name"] Scanning Access Service Application(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPAccessServiceApp

                Write-Host "["$spServer.Name"] Scanning Antivirus Settings(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPAntivirusSettings

                Write-Host "["$spServer.Name"] Scanning App Catalog Settings(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPAppCatalog

                Write-Host "["$spServer.Name"] Scanning Subscription Settings Service Application Settings(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPSubscriptionSettingsServiceApp

                Write-Host "["$spServer.Name"] Scanning App Domain Settings(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPAppDomain

                Write-Host "["$spServer.Name"] Scanning App Management Service App Settings(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPAppManagementServiceApp

                Write-Host "["$spServer.Name"] Scanning App Store Settings(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPAppStoreSettings

                Write-Host "["$spServer.Name"] Scanning Blob Cache Settings(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPBlobCacheSettings
                <#
                Write-Host "["$spServer.Name"] Scanning Configuration Wizard Settings(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPConfigWizard
#>
                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host "["$spServer.Name"] Scanning Database(s) Availability Group Settings(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName SPDatabaseAAG
                }

                Write-Host "["$spServer.Name"] Scanning Distributed Cache Settings(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPDistributedCacheService

                Write-Host "["$spServer.Name"] Scanning Excel Services Application Settings(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPExcelServiceApp

                Write-Host "["$spServer.Name"] Scanning Farm Administrator(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPFarmAdministrators

                Write-Host "["$spServer.Name"] Scanning Farm Solution(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPFarmSolution

                if ($Global:ExtractionModeValue -eq 3)
                {
                    Write-Host "["$spServer.Name"] Scanning Health Rule(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName SPHealthAnalyzerRuleState
                }

                Write-Host "["$spServer.Name"] Scanning IRM Settings(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPIrmSettings

                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host "["$spServer.Name"] Scanning Office Online Binding(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName SPOfficeOnlineServerBinding
                }

                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host "["$spServer.Name"] Scanning Crawl Rules(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName SPSearchCrawlRule
                }

                if ($Global:ExtractionModeValue -eq 3)
                {
                    Write-Host "["$spServer.Name"] Scanning Search File Type(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName SPSearchFileType
                }

                Write-Host "["$spServer.Name"] Scanning Search Index Partition(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPSearchIndexPartition

                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host "["$spServer.Name"] Scanning Search Result Source(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName SPSearchResultSource
                }

                Write-Host "["$spServer.Name"] Scanning Search Topology..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPSearchTopology

                Write-Host "["$spServer.Name"] Scanning Word Automation Service Application..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPWordAutomationServiceApp

                Write-Host "["$spServer.Name"] Scanning Visio Graphics Service Application..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPVisioServiceApp

                Write-Host "["$spServer.Name"] Scanning Work Management Service Application..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPWorkManagementServiceApp

                Write-Host "["$spServer.Name"] Scanning Performance Point Service Application..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPPerformancePointServiceApp

                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host "["$spServer.Name"] Scanning Web Applications Workflow Settings..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName SPWebAppWorkflowSettings
                }

                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host "["$spServer.Name"] Scanning Web Applications Throttling Settings..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName SPWebAppThrottlingSettings
                }

                if ($Global:ExtractionModeValue -eq 3)
                {
                    Write-Host "["$spServer.Name"] Scanning the Timer Job States..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName SPTimerJobState
                }

                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host "["$spServer.Name"] Scanning Web Applications Usage and Deletion Settings..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName SPWebAppSiteUseAndDeletion
                }

                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host "["$spServer.Name"] Scanning Web Applications Proxy Groups..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName SPWebAppProxyGroup
                }

                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host "["$spServer.Name"] Scanning Web Applications Extension(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName SPWebApplicationExtension
                }

                Write-Host "["$spServer.Name"] Scanning Web Applications App Domain(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPWebApplicationAppDomain

                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host "["$spServer.Name"] Scanning Web Application(s) General Settings..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName SPWebAppGeneralSettings
                }

                Write-Host "["$spServer.Name"] Scanning Web Application(s) Blocked File Types..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPWebAppBlockedFileTypes

                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host "["$spServer.Name"] Scanning User Profile Section(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName SPUserProfileSection
                }

                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host "["$spServer.Name"] Scanning User Profile Properties..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName SPUserProfileProperty
                }

                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host "["$spServer.Name"] Scanning User Profile Permissions..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName SPUserProfileServiceAppPermissions
                }
                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host "["$spServer.Name"] Scanning User Profile Sync Connections..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName SPUserProfileSyncConnection
                }

                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host "["$spServer.Name"] Scanning Trusted Identity Token Issuer(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName SPTrustedIdentityTokenIssuer
                }

                Write-Host "["$spServer.Name"] Scanning Farm Property Bag..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPFarmPropertyBag

                Write-Host "["$spServer.Name"] Scanning Session State Service..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPSessionStateService

                Write-Host "["$spServer.Name"] Scanning Published Service Application(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPPublishServiceApplication

                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host "["$spServer.Name"] Scanning Remote Farm Trust(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName SPRemoteFarmTrust
                }

                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host "["$spServer.Name"] Scanning Farm Password Change Settings..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName SPPasswordChangeSettings
                }

                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host "["$spServer.Name"] Scanning Service Application(s) Security Settings..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName SPServiceAppSecurity
                }
            }

            Write-Host "["$spServer.Name"] Scanning Service Instance(s)..." -BackgroundColor DarkGreen -ForegroundColor White
            if (!$Standalone)
            {
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPUserProfileSyncService -ExportParams @{Servers = @($spServer.Name) }
            }
            else
            {
                $servers = Get-SPServer
                $serverAddresses = @()
                foreach ($server in $servers)
                {
                    $serverAddresses += $server.Address
                }
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPUserProfileSyncService -ExportParams @{Servers = $serverAddresses }
            }

            Write-Host "["$spServer.Name"] Configuring Local Configuration Manager (LCM)..." -BackgroundColor DarkGreen -ForegroundColor White
            Set-LCM

            $Script:dscConfigContent += "`r`n    }`r`n"
            $serverNumber++
        }
    }
    $Script:dscConfigContent += "`r`n}`r`n"
    Write-Host "Configuring Credentials..." -BackgroundColor DarkGreen -ForegroundColor White
    Set-ObtainRequiredCredentials

    $Script:dscConfigContent += "$configName -ConfigurationData .\ConfigurationData.psd1"
}

function Repair-Credentials
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $results
    )
    if ($null -ne $results)
    {
        <## Cleanup the InstallAccount param first (even if we may be adding it back) #>
        if ($null -ne $results.ContainsKey("InstallAccount"))
        {
            $results.Remove("InstallAccount")
        }

        if ($null -ne $results.ContainsKey("PsDscRunAsCredential"))
        {
            $results.Remove("PsDscRunAsCredential")
        }

        $results.Add("PsDscRunAsCredential", "`$Creds" + ($Global:spFarmAccount.Username.Split('\'))[1].Replace("-", "_").Replace(".", "_").Replace("@", "").Replace(" ", ""))

        return $results
    }
    return $null
}

function Set-LCM()
{
    $Script:dscConfigContent += "        LocalConfigurationManager" + "`r`n"
    $Script:dscConfigContent += "        {`r`n"
    $Script:dscConfigContent += "            RebootNodeIfNeeded = `$True`r`n"
    $Script:dscConfigContent += "        }`r`n"
}

function Read-SQLVersion
{
    $uniqueServers = @()
    $sqlServers = Get-SPDatabase | Select-Object Server -Unique
    foreach ($sqlServer in $sqlServers)
    {
        $serverName = $sqlServer.Server.Address

        if ($null -eq $serverName)
        {
            $serverName = $sqlServer.Server
        }

        if (!($uniqueServers -contains $serverName))
        {
            try
            {
                $sqlVersionInfo = Invoke-SQL -Server $serverName -dbName "Master" -sqlQuery "SELECT @@VERSION AS 'SQLVersion'"
                $uniqueServers += $serverName.ToString()
                $Content = "<#`r`n    SQL Server Product Versions Installed on this Farm`r`n-------------------------------------------`r`n"
                $Content += "    Products and Language Packs`r`n"
                $Content += "-------------------------------------------`r`n"
                $Content += "    [" + $serverName.ToUpper() + "]: " + $sqlVersionInfo.SQLversion.Split("`n")[0] + "`r`n#>`r`n`r`n"
            }
            catch
            {
                $Global:ErrorLog += "[SQL Server]" + $serverName + "`r`n"
                $Global:ErrorLog += "$_`r`n`r`n"
            }
        }
    }
    return $Content
}

function Read-OperatingSystemVersion
{
    $servers = Get-SPServer
    $Content = "<#`r`n    Operating Systems in this Farm`r`n-------------------------------------------`r`n"
    $Content += "    Products and Language Packs`r`n"
    $Content += "-------------------------------------------`r`n"
    $i = 1
    $total = $servers.Length
    foreach ($spServer in $servers)
    {
        Write-Host "Scanning Operating System Settings [$i/$total] for server {$($spServer.Name)}"
        $serverName = $spServer.Name
        try
        {
            $osInfo = Get-CimInstance Win32_OperatingSystem  -ComputerName $serverName -ErrorAction SilentlyContinue | Select-Object @{Label = "OSName"; Expression = { $_.Name.Substring($_.Name.indexof("W"), $_.Name.indexof("|") - $_.Name.indexof("W")) } } , Version , OSArchitecture -ErrorAction SilentlyContinue
            $Content += "    [" + $serverName + "]: " + $osInfo.OSName + "(" + $osInfo.OSArchitecture + ")    ----    " + $osInfo.Version + "`r`n"
        }
        catch
        {
            $Global:ErrorLog += "[Operating System]" + $spServer.Name + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
    }
    $Content += "#>`r`n`r`n"
    return $Content
}

function Read-SPProductVersions
{
    $Content = "<#`r`n    SharePoint Product Versions Installed on this Farm`r`n-------------------------------------------`r`n"
    $Content += "    Products and Language Packs`r`n"
    $Content += "-------------------------------------------`r`n"

    if ($PSVersionTable.PSVersion -like "2.*")
    {
        $RegLoc = Get-ChildItem HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall
        $Programs = $RegLoc | Where-Object { $_.PsPath -like "*\Office*" } | ForEach-Object { Get-ItemProperty $_.PsPath }

        foreach ($program in $Programs)
        {
            $Content += "    " + $program.DisplayName + " -- " + $program.DisplayVersion + "`r`n"
        }
    }
    else
    {
        $regLoc = Get-ChildItem HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall
        $programs = $regLoc | Where-Object { $_.PsPath -like "*\Office*" } | ForEach-Object { Get-ItemProperty $_.PsPath }
        $components = $regLoc | Where-Object { $_.PsPath -like "*1000-0000000FF1CE}" } | ForEach-Object { Get-ItemProperty $_.PsPath }

        foreach ($program in $programs)
        {
            $productCodes = $_.ProductCodes
            $component = @() + ($components |     Where-Object { $_.PSChildName -in $productCodes } | ForEach-Object { Get-ItemProperty $_.PsPath })
            foreach ($component in $components)
            {
                $Content += "    " + $component.DisplayName + " -- " + $component.DisplayVersion + "`r`n"
            }
        }
    }
    $Content += "#>`r`n"
    return $Content
}

function Get-SPWebPolicyPermissions
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $Params
    )
    $permission = "            MSFT_SPWebPolicyPermissions`r`n            {`r`n"
    foreach ($key in $params.Keys)
    {
        try
        {
            $isCredentials = $false
            if ($key.ToLower() -eq "username")
            {
                if (!($params[$key].ToUpper() -like "NT AUTHORITY*"))
                {
                    $memberUserName = Get-Credentials -UserName $params[$key]
                    if ($memberUserName)
                    {
                        $isCredentials = $true
                    }
                }
            }

            if (($params[$key].ToString().ToLower() -eq "false" -or $params[$key].ToString().ToLower() -eq "true") -and !$isCredentials)
            {
                $permission += "                " + $key + " = `$" + $params[$key] + "`r`n"
            }
            elseif (!$isCredentials)
            {
                $permission += "                " + $key + " = '" + $params[$key] + "'`r`n"
            }
            else
            {
                $permission += "                " + $key + " =  " + (Resolve-Credentials -UserName $params[$key]) + ".UserName`r`n"
            }
        }
        catch
        {
            $Global:ErrorLog += "[MSFT_SPWebPolicyPermissions]" + $key + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
    }
    $permission += "            }`r`n"
    return $permission
}

function CheckDBForAliases()
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $DatabaseName
    )

    $dbServer = Get-SPDatabase | Where-Object { $_.Name -eq $DatabaseName }
    return $dbServer.NormalizedDataSource
}

function Set-SPFarmAdministrators
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Members
    )
    $newMemberList = @()
    foreach ($member in $members)
    {
        if (!($member.ToUpper() -like "BUILTIN*"))
        {
            $memberUser = Get-Credentials -UserName $member
            if ($memberUser)
            {
                $accountName = Resolve-Credentials -UserName $member
                $newMemberList += $accountName + ".UserName"
            }
            else
            {
                $newMemberList += $member
            }
        }
        else
        {
            $newMemberList += $member
        }
    }
    return $newMemberList
}

function Get-SPWebAppHappyHour
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $Params
    )
    $happyHour = "MSFT_SPWebApplicationHappyHour{`r`n"
    foreach ($key in $params.Keys)
    {
        try
        {
            $happyHour += "                " + $key + " = `"" + $params[$key] + "`"`r`n"
        }
        catch
        {
            $Global:ErrorLog += "[MSFT_SPWebApplicationHappyHour]" + $key + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
    }
    $happyHour += "            }"
    return $happyHour
}

function Get-SPServiceAppSecurityMembers
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $Member
    )
    try
    {
        [System.Guid]::Parse($member.UserName) | Out-Null
        $isUserGuid = $true
    }
    catch
    {
        $isUserGuid = $false
    }

    if ($null -ne $member.AccessLevel -and !($member.AccessLevel -match "^[\d\.]+$") -and (!$isUserGuid) -and $member.AccessLevel -ne "")
    {
        $userName = Get-Credentials -UserName $member.UserName
        $value = $userName
        if ($userName)
        {
            $value = (Resolve-Credentials -UserName $member.UserName) + ".UserName;"
        }
        else
        {
            $value = "`"" + $member.UserName + "`";"
        }
        return "MSFT_SPServiceAppSecurityEntry { `
            Username    = " + $value + " `
            AccessLevel = `"" + $member.AccessLevel + "`" `
        }"
    }
    return $null
}

function Set-ObtainRequiredCredentials
{
    $credsContent = ""

    foreach ($credential in $Global:CredsRepo)
    {
        if (!$credential.ToLower().StartsWith("builtin"))
        {
            if (!$chckAzure.Checked)
            {
                $credsContent += "    " + (Resolve-Credentials $credential) + " = Get-Credential -UserName `"" + $credential + "`" -Message `"Please provide credentials`"`r`n"
            }
            else
            {
                $resolvedName = (Resolve-Credentials $credential)
                $credsContent += "    " + $resolvedName + " = Get-AutomationPSCredential -Name " + ($resolvedName.Replace("$", "")) + "`r`n"
            }
        }
    }
    $credsContent += "`r`n"
    $startPosition = $Script:dscConfigContent.IndexOf("<# Credentials #>") + 19
    $Script:dscConfigContent = $Script:dscConfigContent.Insert($startPosition, $credsContent)
}

function Set-Imports
{
    $Script:dscConfigContent += "    Import-DscResource -ModuleName `"PSDesiredStateConfiguration`"`r`n"
    $Script:dscConfigContent += "    Import-DscResource -ModuleName `"SharePointDSC`""

    if ($PSVersionTable.PSVersion.Major -eq 5)
    {
        $SPDSCVersion = (Get-Module SharePointDSC).Version.ToString()
        $Script:dscConfigContent += " -ModuleVersion `"" + $SPDSCVersion + "`""
    }
    $Script:dscConfigContent += "`r`n"
}

function Get-SPCrawlSchedule
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $Params
    )
    $currentSchedule = "MSFT_SPSearchCrawlSchedule{`r`n"
    foreach ($key in $params.Keys)
    {
        try
        {
            $currentSchedule += "                " + $key + " = `"" + $params[$key] + "`"`r`n"
        }
        catch
        {
            $_
            $Global:ErrorLog += "[MSFT_SPSearchCrawlSchedule]" + $key + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
    }
    $currentSchedule += "            }"
    return $currentSchedule
}

#region GUI Related Functions
function Select-ComponentsForMode
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Mode
    )
    $components = $null
    if ($mode -eq 1)
    {
        $components = $Global:liteComponents
    }
    elseif ($mode -eq 2)
    {
        $components = $Global:defaultComponents
    }
    foreach ($panel in $panelMain.Controls)
    {
        if ($panel.GetType().ToString() -eq "System.Windows.Forms.Panel")
        {
            foreach ($control in ([System.Windows.Forms.Panel]$panel).Controls)
            {
                try
                {
                    if ($mode -ne 3)
                    {
                        $control.Checked = $false
                    }
                    else
                    {
                        $control.Checked = $true
                    }
                }
                catch
                {
                }
            }
        }
    }
    foreach ($control in $components)
    {
        try
        {
            $control.Checked = $true
        }
        catch
        {
        }
    }
}

function DisplayGUI()
{
    #region Global
    $firstColumnLeft = 10
    $secondColumnLeft = 280
    $thirdColumnLeft = 540
    $topBannerHeight = 70
    #endregion


    $form = New-Object System.Windows.Forms.Form
    $screens = [System.Windows.Forms.Screen]::AllScreens
    $form.Width = $screens[0].Bounds.Width
    $form.Height = $screens[0].Bounds.Height - 60
    $form.WindowState = [System.Windows.Forms.FormWindowState]::Maximized

    $panelMain = New-Object System.Windows.Forms.Panel
    $panelMain.Width = $form.Width
    $panelMain.Height = $form.Height
    $panelMain.AutoScroll = $true

    #region Information Architecture
    $labelInformationArchitecture = New-Object System.Windows.Forms.Label
    $labelInformationArchitecture.Left = $firstColumnLeft
    $labelInformationArchitecture.Top = $topBannerHeight
    $labelInformationArchitecture.Text = "Information Architecture:"
    $labelInformationArchitecture.AutoSize = $true
    $labelInformationArchitecture.Font = [System.Drawing.Font]::new($labelInformationArchitecture.Font.Name, 14, [System.Drawing.FontStyle]::Bold)
    $panelMain.Controls.Add($labelInformationArchitecture)

    $panelInformationArchitecture = New-Object System.Windows.Forms.Panel
    $panelInformationArchitecture.Top = 30 + $topBannerHeight
    $panelInformationArchitecture.Left = $firstColumnLeft
    $panelInformationArchitecture.Height = 80
    $panelInformationArchitecture.Width = 220
    $panelInformationArchitecture.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

    $chckContentDB = New-Object System.Windows.Forms.CheckBox
    $chckContentDB.Top = 0
    $chckContentDB.AutoSize = $true;
    $chckContentDB.Name = "SPContentDatabase"
    $chckContentDB.Checked = $true
    $chckContentDB.Text = "Content Databases"
    $panelInformationArchitecture.Controls.Add($chckContentDB)

    $chckQuotaTemplates = New-Object System.Windows.Forms.CheckBox
    $chckQuotaTemplates.Top = 20
    $chckQuotaTemplates.AutoSize = $true;
    $chckQuotaTemplates.Name = "SPQuotaTemplate"
    $chckQuotaTemplates.Checked = $true
    $chckQuotaTemplates.Text = "Quota Templates"
    $panelInformationArchitecture.Controls.Add($chckQuotaTemplates);

    $chckSiteCollection = New-Object System.Windows.Forms.CheckBox
    $chckSiteCollection.Top = 40
    $chckSiteCollection.AutoSize = $true;
    $chckSiteCollection.Name = "SPSite"
    $chckSiteCollection.Checked = $true
    $chckSiteCollection.Text = "Site Collections (SPSite)"
    $panelInformationArchitecture.Controls.Add($chckSiteCollection)

    $chckSPWeb = New-Object System.Windows.Forms.CheckBox
    $chckSPWeb.Top = 60
    $chckSPWeb.AutoSize = $true;
    $chckSPWeb.Name = "SPWeb"
    $chckSPWeb.Checked = $false
    $chckSPWeb.Text = "Subsites (SPWeb)"
    $panelInformationArchitecture.Controls.Add($chckSPWeb)

    $panelMain.Controls.Add($panelInformationArchitecture)
    #endregion

    #region Security
    $labelSecurity = New-Object System.Windows.Forms.Label
    $labelSecurity.Text = "Security:"
    $labelSecurity.AutoSize = $true
    $labelSecurity.Top = 120 + $topBannerHeight
    $labelSecurity.Left = $firstColumnLeft
    $labelSecurity.Font = [System.Drawing.Font]::new($labelSecurity.Font.Name, 14, [System.Drawing.FontStyle]::Bold)
    $panelMain.Controls.Add($labelSecurity)

    $panelSecurity = New-Object System.Windows.Forms.Panel
    $panelSecurity.Top = 150 + $topBannerHeight
    $panelSecurity.Left = $firstColumnLeft
    $panelSecurity.AutoSize = $true
    $panelSecurity.Width = 220
    $panelSecurity.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

    $chckFarmAdmin = New-Object System.Windows.Forms.CheckBox
    $chckFarmAdmin.Top = 0
    $chckFarmAdmin.AutoSize = $true;
    $chckFarmAdmin.Name = "SPFarmAdministrators"
    $chckFarmAdmin.Checked = $true
    $chckFarmAdmin.Text = "Farm Administrators"
    $panelSecurity.Controls.Add($chckFarmAdmin);

    $chckManagedAccount = New-Object System.Windows.Forms.CheckBox
    $chckManagedAccount.Top = 20
    $chckManagedAccount.AutoSize = $true;
    $chckManagedAccount.Name = "SPManagedAccount"
    $chckManagedAccount.Checked = $true
    $chckManagedAccount.Text = "Managed Accounts"
    $panelSecurity.Controls.Add($chckManagedAccount);

    $chckPasswordChange = New-Object System.Windows.Forms.CheckBox
    $chckPasswordChange.Top = 40
    $chckPasswordChange.AutoSize = $true;
    $chckPasswordChange.Name = "SPPasswordChangeSettings"
    $chckPasswordChange.Checked = $true
    $chckPasswordChange.Text = "Password Change Settings"
    $panelSecurity.Controls.Add($chckPasswordChange);

    $chckRemoteTrust = New-Object System.Windows.Forms.CheckBox
    $chckRemoteTrust.Top = 60
    $chckRemoteTrust.AutoSize = $true;
    $chckRemoteTrust.Name = "SPRemoteFarmTrust"
    $chckRemoteTrust.Checked = $true
    $chckRemoteTrust.Text = "Remote Farm Trust"
    $panelSecurity.Controls.Add($chckRemoteTrust);

    $chckSASecurity = New-Object System.Windows.Forms.CheckBox
    $chckSASecurity.Top = 80
    $chckSASecurity.AutoSize = $true;
    $chckSASecurity.Name = "SPServiceAppSecurity"
    $chckSASecurity.Checked = $true
    $chckSASecurity.Text = "Service Applications Security"
    $panelSecurity.Controls.Add($chckSASecurity)

    $chckTrustedIdentity = New-Object System.Windows.Forms.CheckBox
    $chckTrustedIdentity.Top = 100
    $chckTrustedIdentity.AutoSize = $true;
    $chckTrustedIdentity.Name = "chckTrustedIdentity"
    $chckTrustedIdentity.Checked = $true
    $chckTrustedIdentity.Text = "Trusted Identity Token Issuer"
    $panelSecurity.Controls.Add($chckTrustedIdentity);

    $panelMain.Controls.Add($panelSecurity)
    #endregion

    #region Service Applications
    $labelSA = New-Object System.Windows.Forms.Label
    $labelSA.Text = "Service Applications:"
    $labelSA.AutoSize = $true
    $labelSA.Top = 285 + $topBannerHeight
    $labelSA.Left = $firstColumnLeft
    $labelSA.Font = [System.Drawing.Font]::new($labelSA.Font.Name, 14, [System.Drawing.FontStyle]::Bold)
    $panelMain.Controls.Add($labelSA)

    $panelSA = New-Object System.Windows.Forms.Panel
    $panelSA.Top = 315 + $topBannerHeight
    $panelSA.Left = $firstColumnLeft
    $panelSA.AutoSize = $true
    $panelSA.Width = 220
    $panelSA.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

    $chckSAAccess = New-Object System.Windows.Forms.CheckBox
    $chckSAAccess.Top = 0
    $chckSAAccess.AutoSize = $true;
    $chckSAAccess.Name = "SPAccessServiceApp"
    $chckSAAccess.Checked = $true
    $chckSAAccess.Text = "Access Services"
    $panelSA.Controls.Add($chckSAAccess);

    $chckSAAccess2010 = New-Object System.Windows.Forms.CheckBox
    $chckSAAccess2010.Top = 20
    $chckSAAccess2010.AutoSize = $true;
    $chckSAAccess2010.Name = "SPAccessServices2010"
    $chckSAAccess2010.Checked = $true
    $chckSAAccess2010.Text = "Access Services 2010"
    $panelSA.Controls.Add($chckSAAccess2010);

    $chckSAAppMan = New-Object System.Windows.Forms.CheckBox
    $chckSAAppMan.Top = 40
    $chckSAAppMan.AutoSize = $true;
    $chckSAAppMan.Name = "SPAppManagementServiceApp"
    $chckSAAppMan.Checked = $true
    $chckSAAppMan.Text = "App Management"
    $panelSA.Controls.Add($chckSAAppMan);

    $chckSABCS = New-Object System.Windows.Forms.CheckBox
    $chckSABCS.Top = 60
    $chckSABCS.AutoSize = $true;
    $chckSABCS.Name = "SPBCSServiceApp"
    $chckSABCS.Checked = $true
    $chckSABCS.Text = "Business Connectivity Services"
    $panelSA.Controls.Add($chckSABCS);

    $chckSAExcel = New-Object System.Windows.Forms.CheckBox
    $chckSAExcel.Top = 80
    $chckSAExcel.AutoSize = $true;
    $chckSAExcel.Name = "SPExcelServiceApp"
    $chckSAExcel.Checked = $true
    $chckSAExcel.Text = "Excel Services"
    $panelSA.Controls.Add($chckSAExcel);

    $chckSAMachine = New-Object System.Windows.Forms.CheckBox
    $chckSAMachine.Top = 100
    $chckSAMachine.AutoSize = $true;
    $chckSAMachine.Name = "SPMachineTranslationServiceApp"
    $chckSAMachine.Checked = $true
    $chckSAMachine.Text = "Machine Translation"
    $panelSA.Controls.Add($chckSAMachine);

    $chckSAMMS = New-Object System.Windows.Forms.CheckBox
    $chckSAMMS.Top = 120
    $chckSAMMS.AutoSize = $true;
    $chckSAMMS.Name = "SPManagedMetadataServiceApp"
    $chckSAMMS.Checked = $true
    $chckSAMMS.Text = "Managed Metadata"
    $panelSA.Controls.Add($chckSAMMS);

    $chckSAPerformance = New-Object System.Windows.Forms.CheckBox
    $chckSAPerformance.Top = 140
    $chckSAPerformance.AutoSize = $true;
    $chckSAPerformance.Name = "SPPerformancePointServiceApp"
    $chckSAPerformance.Checked = $true
    $chckSAPerformance.Text = "PerformancePoint"
    $panelSA.Controls.Add($chckSAPerformance);

    $chckSAPublish = New-Object System.Windows.Forms.CheckBox
    $chckSAPublish.Top = 160
    $chckSAPublish.AutoSize = $true;
    $chckSAPublish.Name = "SPPublishServiceApplication"
    $chckSAPublish.Checked = $true
    $chckSAPublish.Text = "Publish"
    $panelSA.Controls.Add($chckSAPublish);

    $chckSASecureStore = New-Object System.Windows.Forms.CheckBox
    $chckSASecureStore.Top = 180
    $chckSASecureStore.AutoSize = $true;
    $chckSASecureStore.Name = "SPSecureStoreServiceApp"
    $chckSASecureStore.Checked = $true
    $chckSASecureStore.Text = "Secure Store"
    $panelSA.Controls.Add($chckSASecureStore);

    $chckSAState = New-Object System.Windows.Forms.CheckBox
    $chckSAState.Top = 200
    $chckSAState.AutoSize = $true;
    $chckSAState.Name = "SPStateServiceApp"
    $chckSAState.Checked = $true
    $chckSAState.Text = "State Service Application"
    $panelSA.Controls.Add($chckSAState);

    $chckSASub = New-Object System.Windows.Forms.CheckBox
    $chckSASub.Top = 220
    $chckSASub.AutoSize = $true;
    $chckSASub.Name = "SPSubscriptionSettingsServiceApp"
    $chckSASub.Checked = $true
    $chckSASub.Text = "Subscription settings"
    $panelSA.Controls.Add($chckSASub);

    $chckSAUsage = New-Object System.Windows.Forms.CheckBox
    $chckSAUsage.AutoSize = $true;
    $chckSAUsage.Top = 240;
    $chckSAUsage.Name = "SPUsageApplication"
    $chckSAUsage.Checked = $true
    $chckSAUsage.Text = "Usage Service Application"
    $panelSA.Controls.Add($chckSAUsage);

    $chckSAVisio = New-Object System.Windows.Forms.CheckBox
    $chckSAVisio.Top = 260
    $chckSAVisio.AutoSize = $true;
    $chckSAVisio.Name = "SPVisioServiceApp"
    $chckSAVisio.Checked = $true
    $chckSAVisio.Text = "Visio Graphics"
    $panelSA.Controls.Add($chckSAVisio);

    $chckSAWord = New-Object System.Windows.Forms.CheckBox
    $chckSAWord.Top = 280
    $chckSAWord.AutoSize = $true;
    $chckSAWord.Name = "SPWordAutomationServiceApp"
    $chckSAWord.Checked = $true
    $chckSAWord.Text = "Word Automation"
    $panelSA.Controls.Add($chckSAWord);

    $chckSAWork = New-Object System.Windows.Forms.CheckBox
    $chckSAWork.Top = 300
    $chckSAWork.AutoSize = $true;
    $chckSAWork.Name = "SPWorkManagementServiceApp"
    $chckSAWork.Checked = $true
    $chckSAWork.Text = "Work Management"
    $panelSA.Controls.Add($chckSAWork);

    $panelMain.Controls.Add($panelSA)
    #endregion

    #region Search
    $labelSearch = New-Object System.Windows.Forms.Label
    $labelSearch.Top = $topBannerHeight
    $labelSearch.Text = "Search:"
    $labelSearch.AutoSize = $true
    $labelSearch.Left = $secondColumnLeft
    $labelSearch.Font = [System.Drawing.Font]::new($labelSearch.Font.Name, 14, [System.Drawing.FontStyle]::Bold)
    $panelMain.Controls.Add($labelSearch)

    $panelSearch = New-Object System.Windows.Forms.Panel
    $panelSearch.Top = 30 + $topBannerHeight
    $panelSearch.Left = $secondColumnLeft
    $panelSearch.AutoSize = $true
    $panelSearch.Width = 220
    $panelSearch.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

    $chckSearchContentSource = New-Object System.Windows.Forms.CheckBox
    $chckSearchContentSource.Top = 0
    $chckSearchContentSource.AutoSize = $true;
    $chckSearchContentSource.Name = "SPSearchContentSource"
    $chckSearchContentSource.Checked = $true
    $chckSearchContentSource.Text = "Content Sources"
    $panelSearch.Controls.Add($chckSearchContentSource);

    $chckSearchCrawlRule = New-Object System.Windows.Forms.CheckBox
    $chckSearchCrawlRule.Top = 20
    $chckSearchCrawlRule.AutoSize = $true;
    $chckSearchCrawlRule.Name = "SPSearchCrawlRule"
    $chckSearchCrawlRule.Checked = $true
    $chckSearchCrawlRule.Text = "Crawl Rules"
    $panelSearch.Controls.Add($chckSearchCrawlRule);

    $chckSearchCrawlerImpact = New-Object System.Windows.Forms.CheckBox
    $chckSearchCrawlerImpact.Top = 40
    $chckSearchCrawlerImpact.AutoSize = $true;
    $chckSearchCrawlerImpact.Name = "SPSearchCrawlerImpactRule"
    $chckSearchCrawlerImpact.Checked = $true
    $chckSearchCrawlerImpact.Text = "Crawler Impact Rules"
    $panelSearch.Controls.Add($chckSearchCrawlerImpact);

    $chckSearchFileTypes = New-Object System.Windows.Forms.CheckBox
    $chckSearchFileTypes.Top = 60
    $chckSearchFileTypes.AutoSize = $true;
    $chckSearchFileTypes.Name = "SPSearchFileType"
    $chckSearchFileTypes.Checked = $false
    $chckSearchFileTypes.Text = "File Types"
    $panelSearch.Controls.Add($chckSearchFileTypes);

    $chckSearchIndexPart = New-Object System.Windows.Forms.CheckBox
    $chckSearchIndexPart.Top = 80
    $chckSearchIndexPart.AutoSize = $true;
    $chckSearchIndexPart.Name = "SPSearchIndexPartition"
    $chckSearchIndexPart.Checked = $true
    $chckSearchIndexPart.Text = "Index Partitions"
    $panelSearch.Controls.Add($chckSearchIndexPart);

    $chckManagedProp = New-Object System.Windows.Forms.CheckBox
    $chckManagedProp.Top = 100
    $chckManagedProp.AutoSize = $true;
    $chckManagedProp.Name = "SPSearchManagedProperty"
    $chckManagedProp.Checked = $false
    $chckManagedProp.Text = "Managed Properties"
    $panelSearch.Controls.Add($chckManagedProp);

    $chckSearchResultSources = New-Object System.Windows.Forms.CheckBox
    $chckSearchResultSources.Top = 120
    $chckSearchResultSources.AutoSize = $true;
    $chckSearchResultSources.Name = "SPSearchResultSource"
    $chckSearchResultSources.Checked = $true
    $chckSearchResultSources.Text = "Result Sources"
    $panelSearch.Controls.Add($chckSearchResultSources);

    $chckSearchSA = New-Object System.Windows.Forms.CheckBox
    $chckSearchSA.Top = 140
    $chckSearchSA.AutoSize = $true;
    $chckSearchSA.Name = "SPSearchServiceApp"
    $chckSearchSA.Checked = $true
    $chckSearchSA.Text = "Search Service Applications"
    $panelSearch.Controls.Add($chckSearchSA);

    $chckSearchTopo = New-Object System.Windows.Forms.CheckBox
    $chckSearchTopo.Top = 160
    $chckSearchTopo.AutoSize = $true
    $chckSearchTopo.Name = "SPSearchTopology"
    $chckSearchTopo.Checked = $true
    $chckSearchTopo.Text = "Topology"
    $panelSearch.Controls.Add($chckSearchTopo);

    $panelMain.Controls.Add($panelSearch)
    #endregion

    #region Web Applications
    $labelWebApplications = New-Object System.Windows.Forms.Label
    $labelWebApplications.Text = "Web Applications:"
    $labelWebApplications.AutoSize = $true
    $labelWebApplications.Top = $panelSearch.Height + $topBannerHeight + 40
    $labelWebApplications.Left = $secondColumnLeft
    $labelWebApplications.Font = [System.Drawing.Font]::new($labelWebApplications.Font.Name, 14, [System.Drawing.FontStyle]::Bold)
    $panelMain.Controls.Add($labelWebApplications)

    $panelWebApp = New-Object System.Windows.Forms.Panel
    $panelWebApp.Top = $panelSearch.Height + $topBannerHeight + 70
    $panelWebApp.Left = $secondColumnLeft
    $panelWebApp.AutoSize = $true
    $panelWebApp.Width = 220
    $panelWebApp.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

    $chckWAAppDomain = New-Object System.Windows.Forms.CheckBox
    $chckWAAppDomain.Top = 0
    $chckWAAppDomain.AutoSize = $true;
    $chckWAAppDomain.Name = "SPWebApplicationAppDomain"
    $chckWAAppDomain.Checked = $true
    $chckWAAppDomain.Text = "App Domain"
    $panelWebApp.Controls.Add($chckWAAppDomain);

    $chckWABlockedFiles = New-Object System.Windows.Forms.CheckBox
    $chckWABlockedFiles.Top = 20
    $chckWABlockedFiles.AutoSize = $true;
    $chckWABlockedFiles.Name = "SPWebAppBlockedFileTypes"
    $chckWABlockedFiles.Checked = $true
    $chckWABlockedFiles.Text = "Blocked File Types"
    $panelWebApp.Controls.Add($chckWABlockedFiles);

    $chckWAExtension = New-Object System.Windows.Forms.CheckBox
    $chckWAExtension.Top = 40
    $chckWAExtension.AutoSize = $true;
    $chckWAExtension.Name = "SPWebApplicationExtension"
    $chckWAExtension.Checked = $true
    $chckWAExtension.Text = "Extensions"
    $panelWebApp.Controls.Add($chckWAExtension);

    $chckWAGeneral = New-Object System.Windows.Forms.CheckBox
    $chckWAGeneral.Top = 60
    $chckWAGeneral.AutoSize = $true;
    $chckWAGeneral.Name = "SPWebAppGeneralSettings"
    $chckWAGeneral.Checked = $true
    $chckWAGeneral.Text = "General Settings"
    $panelWebApp.Controls.Add($chckWAGeneral);

    $chckWebAppPerm = New-Object System.Windows.Forms.CheckBox
    $chckWebAppPerm.Top = 80
    $chckWebAppPerm.AutoSize = $true
    $chckWebAppPerm.Name = "SPWebAppPermissions"
    $chckWebAppPerm.Checked = $true
    $chckWebAppPerm.Text = "Permissions"
    $panelWebApp.Controls.Add($chckWebAppPerm);

    $chckWebAppPolicy = New-Object System.Windows.Forms.CheckBox
    $chckWebAppPolicy.Top = 100
    $chckWebAppPolicy.AutoSize = $true;
    $chckWebAppPolicy.Name = "SPWebAppPolicy"
    $chckWebAppPolicy.Checked = $true
    $chckWebAppPolicy.Text = "Policies"
    $panelWebApp.Controls.Add($chckWebAppPolicy);

    $chckWAProxyGroup = New-Object System.Windows.Forms.CheckBox
    $chckWAProxyGroup.Top = 120
    $chckWAProxyGroup.AutoSize = $true;
    $chckWAProxyGroup.Name = "SPWebAppProxyGroup"
    $chckWAProxyGroup.Checked = $true
    $chckWAProxyGroup.Text = "Proxy Groups"
    $panelWebApp.Controls.Add($chckWAProxyGroup);

    $chckWADeletion = New-Object System.Windows.Forms.CheckBox
    $chckWADeletion.Top = 140
    $chckWADeletion.AutoSize = $true;
    $chckWADeletion.Name = "SPWebAppSiteUseAndDeletion"
    $chckWADeletion.Checked = $true
    $chckWADeletion.Text = "Site Usage and Deletion"
    $panelWebApp.Controls.Add($chckWADeletion);

    $chckWAThrottling = New-Object System.Windows.Forms.CheckBox
    $chckWAThrottling.Top = 160
    $chckWAThrottling.AutoSize = $true;
    $chckWAThrottling.Name = "chckWAThrottling"
    $chckWAThrottling.Checked = $true
    $chckWAThrottling.Text = "Throttling Settings"
    $panelWebApp.Controls.Add($chckWAThrottling);

    $chckWebApp = New-Object System.Windows.Forms.CheckBox
    $chckWebApp.Top = 180
    $chckWebApp.AutoSize = $true;
    $chckWebApp.Name = "SPWebApplication"
    $chckWebApp.Checked = $true
    $chckWebApp.Text = "Web Applications"
    $panelWebApp.Controls.Add($chckWebApp);

    $chckWAWorkflow = New-Object System.Windows.Forms.CheckBox
    $chckWAWorkflow.Top = 200
    $chckWAWorkflow.AutoSize = $true;
    $chckWAWorkflow.Name = "SPWebAppWorkflowSettings"
    $chckWAWorkflow.Checked = $true
    $chckWAWorkflow.Text = "Workflow Settings"
    $panelWebApp.Controls.Add($chckWAWorkflow);

    $panelMain.Controls.Add($panelWebApp)
    #endregion

    #region Customization
    $labelCustomization = New-Object System.Windows.Forms.Label
    $labelCustomization.Text = "Customization:"
    $labelCustomization.AutoSize = $true
    $labelCustomization.Top = $panelWebApp.Top + $panelWebApp.Height + 10
    $labelCustomization.Left = $secondColumnLeft
    $labelCustomization.Font = [System.Drawing.Font]::new($labelCustomization.Font.Name, 14, [System.Drawing.FontStyle]::Bold)
    $panelMain.Controls.Add($labelCustomization)

    $panelCustomization = New-Object System.Windows.Forms.Panel
    $panelCustomization.Top = $panelWebApp.Top + $panelWebApp.Height + 40
    $panelCustomization.Left = $secondColumnLeft
    $panelCustomization.Height = 80
    $panelCustomization.Width = 220
    $panelCustomization.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

    $chckAppCatalog = New-Object System.Windows.Forms.CheckBox
    $chckAppCatalog.Top = 0
    $chckAppCatalog.AutoSize = $true;
    $chckAppCatalog.Name = "chckAppCatalog"
    $chckAppCatalog.Checked = $true
    $chckAppCatalog.Text = "App Catalog"
    $panelCustomization.Controls.Add($chckAppCatalog);

    $chckAppDomain = New-Object System.Windows.Forms.CheckBox
    $chckAppDomain.Top = 20
    $chckAppDomain.AutoSize = $true;
    $chckAppDomain.Name = "SPAppCatalog"
    $chckAppDomain.Checked = $true
    $chckAppDomain.Text = "App Domain"
    $panelCustomization.Controls.Add($chckAppDomain);

    $chckAppStore = New-Object System.Windows.Forms.CheckBox
    $chckAppStore.Top = 40
    $chckAppStore.AutoSize = $true
    $chckAppStore.Name = "SPAppStoreSettings"
    $chckAppStore.Checked = $true
    $chckAppStore.Text = "App Store Settings"
    $panelCustomization.Controls.Add($chckAppStore);

    $chckFarmSolution = New-Object System.Windows.Forms.CheckBox
    $chckFarmSolution.Top = 60
    $chckFarmSolution.AutoSize = $true;
    $chckFarmSolution.Name = "SPFarmSolution"
    $chckFarmSolution.Checked = $true
    $chckFarmSolution.Text = "Farm Solutions"
    $panelCustomization.Controls.Add($chckFarmSolution);

    $panelMain.Controls.Add($panelCustomization)
    #endregion

    #region Configuration
    $labelConfiguration = New-Object System.Windows.Forms.Label
    $labelConfiguration.Text = "Configuration:"
    $labelConfiguration.AutoSize = $true
    $labelConfiguration.Top = $topBannerHeight
    $labelConfiguration.Left = $thirdColumnLeft
    $labelConfiguration.Font = [System.Drawing.Font]::new($labelConfiguration.Font.Name, 14, [System.Drawing.FontStyle]::Bold)
    $panelMain.Controls.Add($labelConfiguration)

    $panelConfig = New-Object System.Windows.Forms.Panel
    $panelConfig.Top = 30 + $topBannerHeight
    $panelConfig.Left = $thirdColumnLeft
    $panelConfig.AutoSize = $true
    $panelConfig.Width = 400
    $panelConfig.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

    $chckAlternateUrl = New-Object System.Windows.Forms.CheckBox
    $chckAlternateUrl.Top = 0
    $chckAlternateUrl.AutoSize = $true;
    $chckAlternateUrl.Name = "SPAlternateUrl"
    $chckAlternateUrl.Checked = $true
    $chckAlternateUrl.Text = "Alternate URL"
    $panelConfig.Controls.Add($chckAlternateUrl);

    $chckAntivirus = New-Object System.Windows.Forms.CheckBox
    $chckAntivirus.Top = 20
    $chckAntivirus.AutoSize = $true;
    $chckAntivirus.Name = "SPAntivirusSettings"
    $chckAntivirus.Checked = $true
    $chckAntivirus.Text = "Antivirus Settings"
    $panelConfig.Controls.Add($chckAntivirus);

    $chckBlobCache = New-Object System.Windows.Forms.CheckBox
    $chckBlobCache.Top = 40
    $chckBlobCache.AutoSize = $true;
    $chckBlobCache.Name = "SPBlobCacheSettings"
    $chckBlobCache.Checked = $true
    $chckBlobCache.Text = "Blob Cache Settings"
    $panelConfig.Controls.Add($chckBlobCache);

    $chckCacheAccounts = New-Object System.Windows.Forms.CheckBox
    $chckCacheAccounts.Top = 60
    $chckCacheAccounts.AutoSize = $true;
    $chckCacheAccounts.Name = "SPCacheAccounts"
    $chckCacheAccounts.Checked = $true
    $chckCacheAccounts.Text = "Cache Accounts"
    $panelConfig.Controls.Add($chckCacheAccounts);

    $chckDiagLogging = New-Object System.Windows.Forms.CheckBox
    $chckDiagLogging.Top = 80
    $chckDiagLogging.AutoSize = $true;
    $chckDiagLogging.Name = "SPDiagnosticLoggingSettings"
    $chckDiagLogging.Checked = $true
    $chckDiagLogging.Text = "Diagnostic Logging Settings"
    $panelConfig.Controls.Add($chckDiagLogging);

    $chckDistributedCache = New-Object System.Windows.Forms.CheckBox
    $chckDistributedCache.Top = 100
    $chckDistributedCache.AutoSize = $true;
    $chckDistributedCache.Name = "SPDistributedCacheService"
    $chckDistributedCache.Checked = $true
    $chckDistributedCache.Text = "Distributed Cache Service"
    $panelConfig.Controls.Add($chckDistributedCache);

    $chckFarmConfig = New-Object System.Windows.Forms.CheckBox
    $chckFarmConfig.Top = 120
    $chckFarmConfig.AutoSize = $true;
    $chckFarmConfig.Name = "SPFarm"
    $chckFarmConfig.Checked = $true
    $chckFarmConfig.Text = "Farm Configuration"
    $panelConfig.Controls.Add($chckFarmConfig);

    $chckFarmPropBag = New-Object System.Windows.Forms.CheckBox
    $chckFarmPropBag.Top = 140
    $chckFarmPropBag.AutoSize = $true;
    $chckFarmPropBag.Name = "SPFarmPropertyBag"
    $chckFarmPropBag.Checked = $true
    $chckFarmPropBag.Text = "Farm Property Bag"
    $panelConfig.Controls.Add($chckFarmPropBag);

    $chckFeature = New-Object System.Windows.Forms.CheckBox
    $chckFeature.Top = 160
    $chckFeature.AutoSize = $true;
    $chckFeature.Name = "SPFeature"
    $chckFeature.Checked = $false
    $chckFeature.Text = "Features"
    $panelConfig.Controls.Add($chckFeature);

    $chckHealth = New-Object System.Windows.Forms.CheckBox
    $chckHealth.Top = 180
    $chckHealth.AutoSize = $true;
    $chckHealth.Name = "SPHealthAnalyzerRuleState"
    $chckHealth.Checked = $false
    $chckHealth.Text = "Health Analyzer Rule States"
    $panelConfig.Controls.Add($chckHealth);

    $chckIRM = New-Object System.Windows.Forms.CheckBox
    $chckIRM.Top = 200
    $chckIRM.AutoSize = $true;
    $chckIRM.Name = "SPIrmSettings"
    $chckIRM.Checked = $true
    $chckIRM.Text = "Information Rights Management Settings"
    $panelConfig.Controls.Add($chckIRM);

    $chckManagedPaths = New-Object System.Windows.Forms.CheckBox
    $chckManagedPaths.Top = 220
    $chckManagedPaths.AutoSize = $true;
    $chckManagedPaths.Name = "SPManagedPath"
    $chckManagedPaths.Checked = $true
    $chckManagedPaths.Text = "Managed Paths"
    $panelConfig.Controls.Add($chckManagedPaths);

    $chckOOS = New-Object System.Windows.Forms.CheckBox
    $chckOOS.Top = 240
    $chckOOS.AutoSize = $true;
    $chckOOS.Name = "SPOfficeOnlineServerBinding"
    $chckOOS.Checked = $true
    $chckOOS.Text = "Office Online Server Bindings"
    $panelConfig.Controls.Add($chckOOS);

    $chckOutgoingEmail = New-Object System.Windows.Forms.CheckBox
    $chckOutgoingEmail.Top = 260
    $chckOutgoingEmail.AutoSize = $true;
    $chckOutgoingEmail.Name = "SPOutgoingEmailSettings"
    $chckOutgoingEmail.Checked = $true
    $chckOutgoingEmail.Text = "Outgoing Email Settings"
    $panelConfig.Controls.Add($chckOutgoingEmail);

    $chckServiceAppPool = New-Object System.Windows.Forms.CheckBox
    $chckServiceAppPool.Top = 280
    $chckServiceAppPool.AutoSize = $true;
    $chckServiceAppPool.Name = "SPServiceAppPool"
    $chckServiceAppPool.Checked = $true
    $chckServiceAppPool.Text = "Service Application Pools"
    $panelConfig.Controls.Add($chckServiceAppPool);

    $chckServiceInstance = New-Object System.Windows.Forms.CheckBox
    $chckServiceInstance.Top = 300
    $chckServiceInstance.AutoSize = $true;
    $chckServiceInstance.Name = "SPServiceInstance"
    $chckServiceInstance.Checked = $true
    $chckServiceInstance.Text = "Service Instances"
    $panelConfig.Controls.Add($chckServiceInstance);

    $chckSessionState = New-Object System.Windows.Forms.CheckBox
    $chckSessionState.Top = 320
    $chckSessionState.AutoSize = $true;
    $chckSessionState.Name = "SPSessionStateService"
    $chckSessionState.Checked = $true
    $chckSessionState.Text = "Session State Service"
    $panelConfig.Controls.Add($chckSessionState);

    $chckDatabaseAAG = New-Object System.Windows.Forms.CheckBox
    $chckDatabaseAAG.Top = 340
    $chckDatabaseAAG.AutoSize = $true;
    $chckDatabaseAAG.Name = "SPDatabaseAAG"
    $chckDatabaseAAG.Checked = $false
    $chckDatabaseAAG.Text = "SQL Always On Availability Groups"
    $panelConfig.Controls.Add($chckDatabaseAAG);

    $chckTimerJob = New-Object System.Windows.Forms.CheckBox
    $chckTimerJob.Top = 360
    $chckTimerJob.AutoSize = $true;
    $chckTimerJob.Name = "SPTimerJobState"
    $chckTimerJob.Checked = $false
    $chckTimerJob.Text = "Timer Job States"
    $panelConfig.Controls.Add($chckTimerJob);

    $panelMain.Controls.Add($panelConfig)
    #endregion

    #region User Profile Service
    $lblUPS = New-Object System.Windows.Forms.Label
    $lblUPS.Top = $panelConfig.Height + $topBannerHeight + 40
    $lblUPS.Text = "User Profile:"
    $lblUPS.AutoSize = $true
    $lblUPS.Left = $thirdColumnLeft
    $lblUPS.Font = [System.Drawing.Font]::new($lblUPS.Font.Name, 14, [System.Drawing.FontStyle]::Bold)
    $panelMain.Controls.Add($lblUPS)

    $panelUPS = New-Object System.Windows.Forms.Panel
    $panelUPS.Top = $panelConfig.Height + $topBannerHeight + 70
    $panelUPS.Left = $thirdColumnLeft
    $panelUPS.AutoSize = $true
    $panelUPS.Width = 400
    $panelUPS.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

    $chckUPSProp = New-Object System.Windows.Forms.CheckBox
    $chckUPSProp.Top = 0
    $chckUPSProp.AutoSize = $true;
    $chckUPSProp.Name = "SPUserProfileProperty"
    $chckUPSProp.Checked = $false
    $chckUPSProp.Text = "Profile Properties"
    $panelUPS.Controls.Add($chckUPSProp);

    $chckUPSSection = New-Object System.Windows.Forms.CheckBox
    $chckUPSSection.Top = 20
    $chckUPSSection.AutoSize = $true
    $chckUPSSection.Name = "SPUserProfileSection"
    $chckUPSSection.Checked = $false
    $chckUPSSection.Text = "Profile Sections"
    $panelUPS.Controls.Add($chckUPSSection);

    $chckUPSSync = New-Object System.Windows.Forms.CheckBox
    $chckUPSSync.Top = 40
    $chckUPSSync.AutoSize = $true;
    $chckUPSSync.Name = "SPUserProfileSyncConnection"
    $chckUPSSync.Checked = $true
    $chckUPSSync.Text = "Synchronization Connections"
    $panelUPS.Controls.Add($chckUPSSync);

    $chckUPSA = New-Object System.Windows.Forms.CheckBox
    $chckUPSA.Top = 60
    $chckUPSA.AutoSize = $true;
    $chckUPSA.Name = "SPUserProfileServiceApp"
    $chckUPSA.Checked = $true
    $chckUPSA.Text = "User Profile Service Applications"
    $panelUPS.Controls.Add($chckUPSA);

    $chckUPSPermissions = New-Object System.Windows.Forms.CheckBox
    $chckUPSPermissions.Top = 80
    $chckUPSPermissions.AutoSize = $true;
    $chckUPSPermissions.Name = "SPUserProfileServiceAppPermissions"
    $chckUPSPermissions.Checked = $true
    $chckUPSPermissions.Text = "User Profile Service Permissions"
    $panelUPS.Controls.Add($chckUPSPermissions);

    $panelMain.Controls.Add($panelUPS)
    #endregion

    #region Extraction Modes
    $Global:liteComponents = @($chckSAAccess, $chckSAAccess2010, $chckAlternateURL, $chckAntivirus, $chckAppCatalog, $chckAppDomain, $chckSAAppMan, $chckAppStore, $chckSABCS, $chckBlobCache, $chckCacheAccounts, $chckContentDB, $chckDiagLogging, $chckDistributedCache, $chckSAExcel, $chckFarmConfig, $chckFarmAdmin, $chckFarmPropBag, $chckFarmSolution, $chckIRM, $chckSAMachine, $chckManagedAccount, $chckSAMMS, $chckManagedPaths, $chckOutgoingEmail, $chckSAPerformance, $chckSAPublish, $chckQuotaTemplates, $chckSearchContentSource, $chckSearchIndexPart, $chckSearchSA, $chckSearchTopo, $chckSASecureStore, $chckServiceAppPool, $chckWAProxyGroup, $chckServiceInstance, $chckSAState, $chckSiteCollection, $chckSessionState, $chckSASub, $chckUPSA, $chckSAVisio, $chckWebApp, $chckWebAppPerm, $chckWebAppPolicy, $chckSAWord, $chckSAWork, $chckSearchIndexPart, $chckWAAppDomain, $chckSessionState, $chckSAUsage)
    $Global:defaultComponents = @($chckSAAccess, $chckSAAccess2010, $chckAlternateURL, $chckAntivirus, $chckAppCatalog, $chckAppDomain, $chckSAAppMan, $chckAppStore, $chckSABCS, $chckBlobCache, $chckCacheAccounts, $chckContentDB, $chckDiagLogging, $chckDistributedCache, $chckSAExcel, $chckFarmConfig, $chckFarmAdmin, $chckFarmPropBag, $chckFarmSolution, $chckIRM, $chckSAMachine, $chckManagedAccount, $chckSAMMS, $chckManagedPaths, $chckOutgoingEmail, $chckSAPerformance, $chckSAPublish, $chckQuotaTemplates, $chckSearchContentSource, $chckSearchIndexPart, $chckSearchSA, $chckSearchTopo, $chckSASecureStore, $chckServiceAppPool, $chckWAProxyGroup, $chckServiceInstance, $chckSAState, $chckSiteCollection, $chckSessionState, $chckSASub, $chckUPSA, $chckSAVisio, $chckWebApp, $chckWebAppPerm, $chckWebAppPolicy, $chckSAWord, $chckSAWork, $chckOOS, $chckPasswordChange, $chckRemoteTrust, $chckSearchCrawlerImpact, $chckSearchCrawlRule, $chckSearchResultSources, $chckSASecurity, $chckTrustedIdentity, $chckUPSPermissions, $chckUPSSync, $chckWABlockedFiles, $chckWAGeneral, $chckWAProxyGroup, $chckWADeletion, $chckWAThrottling, $chckWAWorkflow, $chckSearchIndexPart, $chckWAAppDomain, $chckWAExtension, $chckSessionState, $chckSAUsage)
    #endregion

    #region Top Menu
    $panelMenu = New-Object System.Windows.Forms.Panel
    $panelMenu.Height = $topBannerHeight
    $panelMenu.Width = $form.Width
    $panelMenu.BackColor = [System.Drawing.Color]::Silver

    $lblMode = New-Object System.Windows.Forms.Label
    $lblMode.Top = 25
    $lblMode.Text = "Extraction Modes:"
    $lblMode.AutoSize = $true
    $lblMode.Left = 10
    $lblMode.Font = [System.Drawing.Font]::new($lblMode.Font.Name, 8, [System.Drawing.FontStyle]::Bold)
    $panelMenu.Controls.Add($lblMode)

    $btnLite = New-Object System.Windows.Forms.Button
    $btnLite.Width = 50
    $btnLite.Top = 20
    $btnLite.Left = 120
    $btnLite.Text = "Lite"
    $btnLite.Add_Click( { Select-ComponentsForMode(1) })
    $panelMenu.Controls.Add($btnLite);

    $btnDefault = New-Object System.Windows.Forms.Button
    $btnDefault.Width = 50
    $btnDefault.Top = 20
    $btnDefault.Left = 170
    $btnDefault.Text = "Default"
    $btnDefault.Add_Click( { Select-ComponentsForMode(2) })
    $panelMenu.Controls.Add($btnDefault);

    $btnFull = New-Object System.Windows.Forms.Button
    $btnFull.Width = 50
    $btnFull.Top = 20
    $btnFull.Left = 220
    $btnFull.Text = "Full"
    $btnFull.Add_Click( { Select-ComponentsForMode(3) })
    $panelMenu.Controls.Add($btnFull);

    $btnClear = New-Object System.Windows.Forms.Button
    $btnClear.Width = 90
    $btnClear.Top = 20
    $btnClear.Left = 270
    $btnClear.BackColor = [System.Drawing.Color]::IndianRed
    $btnClear.ForeColor = [System.Drawing.Color]::White
    $btnClear.Text = "Unselect All"
    $btnClear.Add_Click( { Select-ComponentsForMode(0) })
    $panelMenu.Controls.Add($btnClear);

    $chckStandAlone = New-Object System.Windows.Forms.CheckBox
    $chckStandAlone.Width = 90
    $chckStandAlone.Top = 5
    $chckStandAlone.Name = "chckStandAlone"
    $chckStandAlone.Left = 370
    $chckStandAlone.Text = "Standalone"
    $panelMenu.Controls.Add($chckStandAlone)

    $chckAzure = New-Object System.Windows.Forms.CheckBox
    $chckAzure.Width = 90
    $chckAzure.Top = 25
    $chckAzure.Name = "chckAzure"
    $chckAzure.Left = 370
    $chckAzure.Text = "Azure"
    $panelMenu.Controls.Add($chckAzure)

    $chckRequiredUsers = New-Object System.Windows.Forms.CheckBox
    $chckRequiredUsers.Width = 200
    $chckRequiredUsers.Top = 45
    $chckRequiredUsers.Left = 370
    $chckRequiredUsers.Name = "chckRequiredUsers"
    $chckRequiredUsers.Checked = $true
    $chckRequiredUsers.Text = "Generate Required Users Script"
    $panelMenu.Controls.Add($chckRequiredUsers)

    $lblFarmAccount = New-Object System.Windows.Forms.Label
    $lblFarmAccount.Text = "Farm Account:"
    $lblFarmAccount.Top = 10
    $lblFarmAccount.Left = 560
    $lblFarmAccount.Width = 90
    $lblFarmAccount.TextAlign = [System.Drawing.ContentAlignment]::TopRight
    $lblFarmAccount.Font = [System.Drawing.Font]::new($lblFarmAccount.Font.Name, 8, [System.Drawing.FontStyle]::Bold)
    $panelMenu.Controls.Add($lblFarmAccount)

    $txtFarmAccount = New-Object System.Windows.Forms.Textbox
    $txtFarmAccount.Text = "$($env:USERDOMAIN)\$($env:USERNAME)"
    $txtFarmAccount.Top = 5
    $txtFarmAccount.Left = 650
    $txtFarmAccount.Width = 150
    $txtFarmAccount.Font = [System.Drawing.Font]::new($txtFarmAccount.Font.Name, 10)
    $panelMenu.Controls.Add($txtFarmAccount)

    $lblPassword = New-Object System.Windows.Forms.Label
    $lblPassword.Text = "Password:"
    $lblPassword.Top = 47
    $lblPassword.Left = 560
    $lblPassword.Width = 90
    $lblPassword.TextAlign = [System.Drawing.ContentAlignment]::TopRight
    $lblPassword.Font = [System.Drawing.Font]::new($lblPassword.Font.Name, 8, [System.Drawing.FontStyle]::Bold)
    $panelMenu.Controls.Add($lblPassword)

    $txtPassword = New-Object System.Windows.Forms.Textbox
    $txtPassword.Top = 40
    $txtPassword.Left = 650
    $txtPassword.Width = 150
    $txtPassword.PasswordChar = "*"
    $txtPassword.Font = [System.Drawing.Font]::new($txtPassword.Font.Name, 10)
    $txtPassword.Add_KeyDown( {
            if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter)
            {
                $btnExtract.PerformClick()
            }
        })
    $panelMenu.Controls.Add($txtPassword)

    $btnExtract = New-Object System.Windows.Forms.Button
    $btnExtract.Width = 178
    $btnExtract.Height = 70
    $btnExtract.Top = 0
    $btnExtract.Left = $form.Width - 200
    $btnExtract.BackColor = [System.Drawing.Color]::ForestGreen
    $btnExtract.ForeColor = [System.Drawing.Color]::White
    $btnExtract.Text = "Start Extraction"
    $btnExtract.Add_Click( {
            if ($txtPassword.Text.Length -gt 0)
            {
                $SelectedComponents = @()
                foreach ($panel in ($form.Controls[0].Controls | Where-Object { $_.GetType().Name -eq "Panel" }))
                {
                    foreach ($checkbox in ($panel.Controls | Where-Object { $_.GetType().Name -eq "Checkbox" }))
                    {
                        if ($checkbox.Checked -and $checkbox.Name -NotIn @("chckRequiredUsers", "chckAzure", "chckRequiredUsers"))
                        {
                            $SelectedComponents += $checkbox.Name
                        }
                    }
                }
                $form.Hide()
                $componentsToString = "@("
                foreach ($component in $SelectedComponents)
                {
                    $componentsToString += "`"" + $component + "`","
                }
                $componentsToString = $componentsToString.Substring(0, $componentsToString.Length - 1) + ")"
                Write-Host "To execute the same extraction process unattended, run the following command:" -BackgroundColor DarkGreen -ForegroundColor White
                Write-Host ".\SharePointDSC.Reverse.ps1 -ComponentsToExtract $componentsToString"

                $password = ConvertTo-SecureString $txtPassword.Text -AsPlainText -Force
                $credentials = New-Object System.Management.Automation.PSCredential ($txtFarmAccount.Text, $password)
                Get-SPReverseDSC -ComponentsToExtract $SelectedComponents -Credentials $credentials
            }
            else
            {
                [System.Windows.Forms.MessageBox]::Show("Please provide a password for the Farm Account")
            }
        })
    $panelMenu.Controls.Add($btnExtract);

    $panelMain.Controls.Add($panelMenu);
    #endregion

    $panelMain.AutoScroll = $true
    $form.Controls.Add($panelMain)
    $form.Text = "ReverseDSC for SharePoint - v" + $Script:version
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.ShowDialog() | Out-Null
}

function Invoke-SQL()
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Server,

        [Parameter(Mandatory = $true)]
        [System.String]
        $dbName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $sqlQuery
    )

    $ConnectString = "Data Source=${Server}; Integrated Security=SSPI; Initial Catalog=${dbName}"

    $Conn = New-Object System.Data.SqlClient.SQLConnection($ConnectString)
    $Command = New-Object System.Data.SqlClient.SqlCommand($sqlQuery, $Conn)
    $Conn.Open()

    $Adapter = New-Object System.Data.SqlClient.SqlDataAdapter $Command
    $DataSet = New-Object System.Data.DataSet
    $Adapter.Fill($DataSet) | Out-Null

    $Conn.Close()
    $DataSet.Tables
}

function Set-TermStoreAdministratorsBlock
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $TermStoreAdminsLine
    )
    $newArray = @()
    foreach ($admin in $TermStoreAdminsLine)
    {
        if (!($admin -like "BUILTIN*"))
        {
            $account = Get-Credentials -UserName $admin
            if ($account)
            {
                $newArray += (Resolve-Credentials -UserName $admin) + ".UserName"
            }
            else
            {
                $newArray += $admin
            }
        }
        else
        {
            $newArray += $admin
        }
    }
    return $newArray
}

function Set-SPFarmAdministratorsBlock
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DSCBlock,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ParameterName
    )
    $longestParamLength = 21 #PsDscRunAsCredential
    $missingSpaces = $longestParamLength - $ParameterName.Length
    $spaceContent = ""
    for ($i = 1; $i -le $missingSpaces; $i++)
    {
        $spaceContent += " "
    }
    $newLine = $ParameterName + $spaceContent + "= @("
    $startPosition = $DSCBlock.IndexOf($ParameterName + $spaceContent + "= @")
    if ($startPosition -ge 0)
    {
        $endPosition = $DSCBlock.IndexOf("`r`n", $startPosition)
        if ($endPosition -ge 0)
        {
            $DSCLine = $DSCBlock.Substring($startPosition, $endPosition - $startPosition)
            $originalLine = $DSCLine
            $DSCLine = $DSCLine.Replace($ParameterName + $spaceContent + "= @(", "").Replace(");", "").Replace(" ", "")
            $members = $DSCLine.Split(',')

            foreach ($member in $members)
            {
                if ($member.StartsWith("`"`$"))
                {
                    $newLine += $member.Replace("`"", "") + ", "
                }
                else
                {
                    $newLine += $member + ", "
                }
            }
            if ($newLine.EndsWith(", "))
            {
                $newLine = $newLine.Remove($newLine.Length - 2, 2)
            }
            $newLine += ");"
            $DSCBlock = $DSCBlock.Replace($originalLine, $newLine)
        }
    }

    return $DSCBlock
}

function Set-TermStoreAdministrators
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DSCBlock
    )
    $newLine = "TermStoreAdministrators = @("

    $startPosition = $DSCBlock.IndexOf("TermStoreAdministrators = @")
    if ($startPosition -ge 0)
    {
        $endPosition = $DSCBlock.IndexOf("`r`n", $startPosition)
        if ($endPosition -ge 0)
        {
            $DSCLine = $DSCBlock.Substring($startPosition, $endPosition - $startPosition)
            $originalLine = $DSCLine
            $DSCLine = $DSCLine.Replace("TermStoreAdministrators = @(", "").Replace(");", "").Replace(" ", "")
            $members = $DSCLine.Split(',')

            $i = 1
            $total = $members.Length
            foreach ($member in $members)
            {
                Write-Host "    -> Scanning TermStore Admins [$i/$total]"
                if ($member.StartsWith("`"`$"))
                {
                    $newLine += $member.Replace("`"", "") + ", "
                }
                else
                {
                    $newLine += $member + ", "
                }
                $i++
            }
            if ($newLine.EndsWith(", "))
            {
                $newLine = $newLine.Remove($newLine.Length - 2, 2)
            }
            $newLine += ");"
            $DSCBlock = $DSCBlock.Replace($originalLine, $newLine)
        }
    }

    return $DSCBlock
}

function Save-SPFarmsolution
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path
    )
    Add-ConfigurationDataEntry -Node $env:COMPUTERNAME -Key "SPSolutionPath" -Value $Path -Description "Path where the custom solutions (.wsp) to be installed on the SharePoint Farm are located (local path or Network Share);"
    $solutions = Get-SPSolution
    $farm = Get-SPFarm
    foreach ($solution in $solutions)
    {
        try
        {
            $file = $farm.Solutions.Item($solution.Name).SolutionFile
            $filePath = $Path + $solution.Name
            $file.SaveAs($filePath)
        }
        catch
        {
            $Script:ErrorLog += "[Saving Farm Solution]" + $solution.Name + "`r`n"
            $Script:ErrorLog += "$_`r`n`r`n"
        }
    }
}

function New-RequiredUsersScript
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $Location
    )
    $content = "Import-Module ActiveDirectory`r`n"
    $content += "`$RequiredUsers = @("

    foreach ($user in $Global:AllUsers)
    {
        $currentUser = $user
        if ($user.Contains('\'))
        {
            $currentUser = $user.Split('\')[1]
        }
        $content += "`"" + $currentUser + "`","
    }

    # Remove trailing comma
    if ($content.EndsWith(','))
    {
        $content = $content.Remove($content.Length - 1, 1)
    }

    $content += ")`r`n`r`n"
    $content += "`$Password = ConvertTo-SecureString -String `"pass@word1`" -AsPlainText -Force`r`n"
    $content += "foreach(`$user in `$RequiredUsers)`r`n"
    $content += "{`r`n"
    $content += "    New-ADUser -Name `$user -Enabled:`$true -AccountPassword `$Password"
    $content += "`r`n}"

    $content | Out-File $location
}

Export-ModuleMember -Function *
