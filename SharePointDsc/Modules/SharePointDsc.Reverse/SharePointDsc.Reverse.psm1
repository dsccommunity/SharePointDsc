[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Scope = 'Function', Target = '*')]
param
()

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
    if (-not $outputfile)
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
    while (-not (Test-Path -Path $OutputDSCPath -PathType Container -ErrorAction SilentlyContinue))
    {
        try
        {
            Write-Output "Directory `"$OutputDSCPath`" doesn't exist; creating..."
            New-Item -Path $OutputDSCPath -ItemType Directory | Out-Null
            if ($?)
            {
                break
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
        Save-SPFarmsolution -Path $OutputDSCPath
    }

    <## Save the content of the resulting DSC Configuration file into a file at the specified path. #>
    $outputDSCFile = Join-Path -Path $OutputDSCPath -ChildPath $fileName
    if (Test-Path -Path $outputDSCFile)
    {
        Remove-Item -Path $outputDSCFile -Force -Confirm:$false
    }
    $Script:dscConfigContent | Out-File -FilePath $outputDSCFile

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
    if (-not $Azure)
    {
        $outputConfigurationData = Join-Path -Path $OutputDSCPath -ChildPath "ConfigurationData.psd1"
        if (Test-Path -Path $outputConfigurationData)
        {
            Remove-Item -Path $outputConfigurationData -Force -Confirm:$false
        }
        New-ConfigurationDataDocument -Path $outputConfigurationData
    }
    else
    {
        $resGroupName = Read-Host "Destination Resource Group Name"
        $automationAccountName = Read-Host "Destination Automation Account Name"

        $azureDeployScriptPath = Join-Path -Path $OutputDSCPath -ChildPath "DeployToAzure.ps1"
        if (Test-Path -Path $azureDeployScriptPath)
        {
            Remove-Item -Path $azureDeployScriptPath -Force -Confirm $false
        }
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
        $errorLogPath = Join-Path -Path $OutputDSCPath -ChildPath "SharePointDSC.Reverse-Errors.log"
        $Global:ErrorLog | Out-File $errorLogPath
    }

    <## Wait a second, then open our $outputDSCPath in Windows Explorer so we can review the glorious output. ##>
    Start-Sleep -Seconds 1
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
    $ResourceModule = Get-ChildItem -Path $ResourcesPath -Recurse | Where-Object -FilterScript {
        $_.Name -like "MSFT_$($ResourceName).psm1"
    }

    try
    {
        $ModuleName = $ResourceModule.Name.Split('.')[0]
    }
    catch
    {
        Write-Host -Object "$($ResourceName) not found" -ForegroundColor Magenta
    }

    try
    {
        $FriendlyName = $ModuleName.Replace("MSFT_", "")
        if ($null -eq $Global:ComponentsToExtract -or $Global:ComponentsToExtract.Contains($FriendlyName))
        {
            Import-Module $ResourceModule.FullName -Scope Local | Out-Null
            $module = Get-Module -Name ($ModuleName) | Where-Object -FilterScript {
                $_.ExportedCommands.Keys -contains 'Export-TargetResource'
            }
            if ($null -ne $module)
            {
                Write-Information "Exporting $($module.Name)"
                $exportString = Export-TargetResource @ExportParams
                return $exportString
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

    $spFarm = Get-SPFarm
    $spServers = $spFarm.Servers
    if ($Standalone)
    {
        $i = 0
        foreach ($spServer in $spServers)
        {
            if ($i -eq 0)
            {
                $spServers = @($spServer)
            }
            $i++
        }
    }
    $Script:dscConfigContent = "<# Generated with SharePointDSC " + $script:version + " #>`r`n"

    Write-Host -Object "Scanning Operating System Version..." -BackgroundColor DarkGreen -ForegroundColor White
    $Script:dscConfigContent += Read-OperatingSystemVersion

    Write-Host -Object "Scanning SQL Server Version..." -BackgroundColor DarkGreen -ForegroundColor White
    $Script:dscConfigContent += Read-SQLVersion

    Write-Host -Object "Scanning Patch Levels..." -BackgroundColor DarkGreen -ForegroundColor White
    $Script:dscConfigContent += Read-SPProductVersions

    $configName = "SharePointFarm"
    if ($Standalone)
    {
        $configName = "SharePointStandalone"
    }
    $Script:dscConfigContent += "Configuration $configName`r`n"
    $Script:dscConfigContent += "{`r`n"
    $Script:dscConfigContent += "    <# Credentials #>`r`n"

    Write-Host -Object "Configuring Dependencies..." -BackgroundColor DarkGreen -ForegroundColor White
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

            Write-Host -Object "[$($spServer.Name)] Generating the SharePoint Prerequisites Installation..." -BackgroundColor DarkGreen -ForegroundColor White
            $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPInstallPrereqs'

            Write-Host -Object "[$($spServer.Name)] Generating the SharePoint Binary Installation..." -BackgroundColor DarkGreen -ForegroundColor White
            $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPInstall'

            Write-Host -Object "[$($spServer.Name)] Scanning the SharePoint Farm..." -BackgroundColor DarkGreen -ForegroundColor White
            $Properties = @{
                ServerName = $spServer.Address
            }
            $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPFarm' -ExportParams $Properties

            if ($serverNumber -eq 1)
            {
                Write-Host -Object "[$($spServer.Name)] Scanning Managed Account(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPManagedAccount'

                Write-Host -Object "[$($spServer.Name)] Scanning Web Application(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPWebApplication'

                Write-Host -Object "[$($spServer.Name)] Scanning Web Application(s) Permissions..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPWebAppPermissions'

                Write-Host -Object "[$($spServer.Name)] Scanning Alternate Url(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPAlternateUrl'

                Write-Host -Object "[$($spServer.Name)] Scanning Managed Path(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPManagedPath

                Write-Host -Object "[$($spServer.Name)] Scanning Application Pool(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPServiceAppPool'

                Write-Host -Object "[$($spServer.Name)] Scanning Content Database(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPContentDatabase'

                Write-Host -Object "[$($spServer.Name)] Scanning Quota Template(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPQuotaTemplate'

                Write-Host -Object "[$($spServer.Name)] Scanning Site Collection(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPSite'

                Write-Host -Object "[$($spServer.Name)] Scanning Diagnostic Logging Settings..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPDiagnosticLoggingSettings'

                Write-Host -Object "[$($spServer.Name)] Scanning Diagnostic Logging Levels..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPLogLevel'

                Write-Host -Object "[$($spServer.Name)] Scanning Usage Service Application..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPUsageApplication'

                Write-Host -Object "[$($spServer.Name)] Scanning Web Application Policy..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPWebAppPolicy'

                Write-Host -Object "[$($spServer.Name)] Scanning State Service Application..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPStateServiceApp'

                Write-Host -Object "[$($spServer.Name)] Scanning User Profile Service Application(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPUserProfileServiceApp'

                Write-Host -Object "[$($spServer.Name)] Scanning Machine Translation Service Application(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPMachineTranslationServiceApp'

                Write-Host -Object "[$($spServer.Name)] Scanning Cache Account(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPCacheAccounts'

                Write-Host -Object "[$($spServer.Name)] Scanning Secure Store Service Application(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPSecureStoreServiceApp'

                Write-Host -Object "[$($spServer.Name)] Scanning Business Connectivity Service Application(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPBCSServiceApp'

                Write-Host -Object "[$($spServer.Name)] Scanning Search Service Application(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPSearchServiceApp'

                Write-Host -Object "[$($spServer.Name)] Scanning Managed Metadata Service Application(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPManagedMetadataServiceApp'

                Write-Host -Object "[$($spServer.Name)] Scanning Access Service Application(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPAccessServiceApp'

                Write-Host -Object "[$($spServer.Name)] Scanning Antivirus Settings(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPAntivirusSettings'

                Write-Host -Object "[$($spServer.Name)] Scanning App Catalog Settings(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPAppCatalog'

                Write-Host -Object "[$($spServer.Name)] Scanning Subscription Settings Service Application Settings(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPSubscriptionSettingsServiceApp'

                Write-Host -Object "[$($spServer.Name)] Scanning App Domain Settings(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPAppDomain'

                Write-Host -Object "[$($spServer.Name)] Scanning App Management Service App Settings(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPAppManagementServiceApp'

                Write-Host -Object "[$($spServer.Name)] Scanning App Store Settings(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPAppStoreSettings'

                Write-Host -Object "[$($spServer.Name)] Scanning Blob Cache Settings(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPBlobCacheSettings'
                <#
                Write-Host "[$($spServer.Name)] Scanning Configuration Wizard Settings(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName SPConfigWizard
#>
                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host -Object "[$($spServer.Name)] Scanning Database(s) Availability Group Settings(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPDatabaseAAG'
                }

                Write-Host -Object "[$($spServer.Name)] Scanning Distributed Cache Settings(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPDistributedCacheService'

                Write-Host -Object "[$($spServer.Name)] Scanning Doc Icon(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPDocIcon'

                Write-Host -Object "[$($spServer.Name)] Scanning Excel Services Application Settings(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPExcelServiceApp'

                Write-Host -Object "[$($spServer.Name)] Scanning Farm Administrator(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPFarmAdministrators'

                Write-Host -Object "[$($spServer.Name)] Scanning Farm Solution(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPFarmSolution'

                if ($Global:ExtractionModeValue -eq 3)
                {
                    Write-Host -Object "[$($spServer.Name)] Scanning Health Rule(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPHealthAnalyzerRuleState'
                }

                Write-Host -Object "[$($spServer.Name)] Scanning IRM Settings(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPIrmSettings'

                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host -Object "[$($spServer.Name)] Scanning Office Online Binding(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPOfficeOnlineServerBinding'
                }

                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host -Object "[$($spServer.Name)] Scanning Crawl Rules(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPSearchCrawlRule'
                }

                if ($Global:ExtractionModeValue -eq 3)
                {
                    Write-Host -Object "[$($spServer.Name)] Scanning Search File Type(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPSearchFileType'
                }

                Write-Host -Object "[$($spServer.Name)] Scanning Search Index Partition(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPSearchIndexPartition'

                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host -Object "[$($spServer.Name)] Scanning Search Result Source(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPSearchResultSource'
                }

                Write-Host -Object "[$($spServer.Name)] Scanning Search Topology..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPSearchTopology'

                Write-Host -Object "[$($spServer.Name)] Scanning Word Automation Service Application..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPWordAutomationServiceApp'

                Write-Host -Object "[$($spServer.Name)] Scanning Visio Graphics Service Application..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPVisioServiceApp'

                Write-Host -Object "[$($spServer.Name)] Scanning Work Management Service Application..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPWorkManagementServiceApp'

                Write-Host -Object "[$($spServer.Name)] Scanning Performance Point Service Application..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPPerformancePointServiceApp'

                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host -Object "[$($spServer.Name)] Scanning Web Applications Workflow Settings..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPWebAppWorkflowSettings'
                }

                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host -Object "[$($spServer.Name)] Scanning Web Applications Throttling Settings..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPWebAppThrottlingSettings'
                }

                if ($Global:ExtractionModeValue -eq 3)
                {
                    Write-Host -Object "[$($spServer.Name)] Scanning the Timer Job States..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPTimerJobState'
                }

                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host -Object "[$($spServer.Name)] Scanning Web Applications Usage and Deletion Settings..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPWebAppSiteUseAndDeletion'
                }

                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host -Object "[$($spServer.Name)] Scanning Web Applications Proxy Groups..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPWebAppProxyGroup'
                }

                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host -Object "[$($spServer.Name)] Scanning Web Applications Extension(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPWebApplicationExtension'
                }

                Write-Host -Object "[$($spServer.Name)] Scanning Web Applications App Domain(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPWebApplicationAppDomain'

                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host -Object "[$($spServer.Name)] Scanning Web Application(s) General Settings..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPWebAppGeneralSettings'
                }

                Write-Host -Object "[$($spServer.Name)] Scanning Web Application(s) Blocked File Types..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPWebAppBlockedFileTypes'

                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host -Object "[$($spServer.Name)] Scanning User Profile Section(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPUserProfileSection'
                }

                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host -Object "[$($spServer.Name)] Scanning User Profile Properties..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPUserProfileProperty'
                }

                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host -Object "[$($spServer.Name)] Scanning User Profile Permissions..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPUserProfileServiceAppPermissions'
                }
                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host -Object "[$($spServer.Name)] Scanning User Profile Sync Connections..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPUserProfileSyncConnection'
                }

                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host -Object "[$($spServer.Name)] Scanning Trusted Identity Token Issuer(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPTrustedIdentityTokenIssuer'
                }

                Write-Host -Object "[$($spServer.Name)] Scanning Farm Property Bag..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPFarmPropertyBag'

                Write-Host -Object "[$($spServer.Name)] Scanning Session State Service..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPSessionStateService'

                Write-Host -Object "[$($spServer.Name)] Scanning Published Service Application(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPPublishServiceApplication'

                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host -Object "[$($spServer.Name)] Scanning Remote Farm Trust(s)..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPRemoteFarmTrust'
                }

                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host -Object "[$($spServer.Name)] Scanning Farm Password Change Settings..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPPasswordChangeSettings'
                }

                if ($Global:ExtractionModeValue -ge 2)
                {
                    Write-Host -Object "[$($spServer.Name)] Scanning Service Application(s) Security Settings..." -BackgroundColor DarkGreen -ForegroundColor White
                    $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPServiceAppSecurity'
                }
            }

            Write-Host -Object "[$($spServer.Name)] Scanning Service Instance(s)..." -BackgroundColor DarkGreen -ForegroundColor White
            if (!$Standalone)
            {
                $Properties = @{
                    Servers = @($spServer.Name)
                }
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPUserProfileSyncService' `
                    -ExportParams $Properties
            }
            else
            {
                $servers = Get-SPServer
                $serverAddresses = @()
                foreach ($server in $servers)
                {
                    $serverAddresses += $server.Address
                }
                $Properties = @{
                    Servers = $serverAddresses
                }
                $Script:dscConfigContent += Read-TargetResource -ResourceName 'SPUserProfileSyncService' `
                    -ExportParams $Properties
            }

            Write-Host -Object "[$($spServer.Name)] Configuring Local Configuration Manager (LCM)..." -BackgroundColor DarkGreen -ForegroundColor White
            Set-LCM

            $Script:dscConfigContent += "`r`n    }`r`n"
            $serverNumber++
        }
    }
    $Script:dscConfigContent += "`r`n}`r`n"
    Write-Host -Object "Configuring Credentials..." -BackgroundColor DarkGreen -ForegroundColor White
    Set-ObtainRequiredCredentials

    $Script:dscConfigContent += "$configName -ConfigurationData .\ConfigurationData.psd1"
    $Script:dscConfigContent += "`r`n`r`n"
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
    $servers = Get-SPServer | Where-Object { $_.Role -ne "Invalid" }
    $Content = "<#`r`n    Operating Systems in this Farm`r`n-------------------------------------------`r`n"
    $Content += "    Products and Language Packs`r`n"
    $Content += "-------------------------------------------`r`n"
    $i = 1
    $total = $servers.Length
    foreach ($spServer in $servers)
    {
        Write-Host -Object "Scanning Operating System Settings [$i/$total] for server {$($spServer.Name)}"
        $serverName = $spServer.Name
        try
        {
            $ObjectParam = @{
                Label      = "OSName"
                Expression = { $_.Name.Substring($_.Name.indexof("W"), $_.Name.indexof("|") - $_.Name.indexof("W")) }
            }
            $osInfo = Get-CimInstance Win32_OperatingSystem  -ComputerName $serverName -ErrorAction SilentlyContinue | Select-Object $ObjectParam , Version , OSArchitecture -ErrorAction SilentlyContinue
            $Content += "    [" + $serverName + "]: " + $osInfo.OSName + "(" + $osInfo.OSArchitecture + ")    ----    " + $osInfo.Version + "`r`n"
        }
        catch
        {
            $Global:ErrorLog += "[Operating System]" + $spServer.Name + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
        $i++
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
    $permission = "`r`n                MSFT_SPWebPolicyPermissions {`r`n"
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
                $permission += "                    " + $key + " = `$" + $params[$key] + "`r`n"
            }
            elseif (!$isCredentials)
            {
                $permission += "                    " + $key + " = '" + $params[$key] + "'`r`n"
            }
            else
            {
                $permission += "                    " + $key + " =  " + (Resolve-Credentials -UserName $params[$key]) + ".UserName`r`n"
            }
        }
        catch
        {
            $Global:ErrorLog += "[MSFT_SPWebPolicyPermissions]" + $key + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
    }
    $permission += "                }"
    return $permission
}

function Get-SPDscDBForAlias()
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

function Get-SPDscClaimTypeMapping
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $params
    )

    $ctm = "MSFT_SPClaimTypeMapping {`r`n"
    foreach ($key in $params.Keys)
    {
        try
        {
            if ($params[$key].ToString().ToLower() -eq "false" -or $params[$key].ToString().ToLower() -eq "true")
            {
                $ctm += "                " + $key + " = `$" + $params[$key] + "`r`n"
            }
            else
            {
                $ctm += "                " + $key + " = `"" + $params[$key] + "`"`r`n"
            }
        }
        catch
        {
            $Script:ErrorLog += "[MSFT_SPClaimTypeMapping]" + $key + "`r`n"
            $Script:ErrorLog += "$_`r`n`r`n"
        }
    }
    $ctm += "            }"
    return $ctm
}

function Get-SPDscWebAppHappyHour
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $Params
    )
    $happyHour = "MSFT_SPWebApplicationHappyHour {`r`n"
    foreach ($key in $params.Keys)
    {
        try
        {
            $happyHour += "                " + $key + " = " + $params[$key] + "`r`n"
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

function Get-SPDscServiceAppSecurityMembers
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
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

    if ($null -ne $member.AccessLevels -and !($member.AccessLevels -match "^[\d\.]+$") -and (!$isUserGuid) -and $member.AccessLevels -ne "")
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
        $resultString = @()
        $resultString += "MSFT_SPServiceAppSecurityEntry`r`n"
        $resultString += "       {`r`n"
        $resultString += "           Username     = $value`r`n"
        $resultString += "           AccessLevels = @(`"$($member.AccessLevels -join "`", `"")`");`r`n"
        $resultString += "       }"

        return $resultString
    }
    return $null
}

function Set-ObtainRequiredCredentials
{
    $credsContent = ""

    foreach ($credential in $Global:CredsRepo)
    {
        if (-not $credential.ToLower().StartsWith("builtin"))
        {
            if ($chckAzure.Checked -eq $false)
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
                    if ($control.Name -NotIn @("chckRequiredUsers", "chckAzure", "chckStandAlone"))
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
    $components = @{
        InformationArchitecture = @(
            @{
                Name           = "SPContentDatabase"
                Text           = "Content Database"
                ExtractionMode = 1
            },
            @{
                Name           = "SPQuotaTemplate"
                Text           = "Quota Templates"
                ExtractionMode = 1
            },
            @{
                Name           = "SPSite"
                Text           = "Site Collections (SPSite)"
                ExtractionMode = 1
            },
            @{
                Name           = "SPWeb"
                Text           = "Subsites (SPWeb)"
                ExtractionMode = 3
            }
        )
        Security                = @(
            @{
                Name           = "SPFarmAdministrators"
                Text           = "Farm Administrators"
                ExtractionMode = 1
            },
            @{
                Name           = "SPManagedAccount"
                Text           = "Managed Accounts"
                ExtractionMode = 1
            },
            @{
                Name           = "SPPasswordChangeSettings"
                Text           = "Password Change Settings"
                ExtractionMode = 2
            },
            @{
                Name           = "SPRemoteFarmTrust"
                Text           = "Remote Farm Trusts"
                ExtractionMode = 2
            },
            @{
                Name           = "SPServiceAppSecurity"
                Text           = "Service App Security"
                ExtractionMode = 2
            },
            @{
                Name           = "SPTrustedIdentityTokenIssuer"
                Text           = "Trusted Identity Token Issuers"
                ExtractionMode = 2
            }
        )
        ServiceApplications     = @(
            @{
                Name           = "SPAccessServiceApp"
                Text           = "Access Services"
                ExtractionMode = 1
            },
            @{
                Name           = "SPAccessServices2010"
                Text           = "Access Services 2010"
                ExtractionMode = 1
            },
            @{
                Name           = "SPAppManagementServiceApp"
                Text           = "App Management"
                ExtractionMode = 1
            },
            @{
                Name           = "SPBCSServiceApp"
                Text           = "Business Connectivity Services"
                ExtractionMode = 1
            },
            @{
                Name           = "SPExcelServiceApp"
                Text           = "Excel Services"
                ExtractionMode = 1
            },
            @{
                Name           = "SPMachineTranslationServiceApp"
                Text           = "Machine Translation"
                ExtractionMode = 1
            },
            @{
                Name           = "SPManagedMetadataServiceApp"
                Text           = "Managed Metadata"
                ExtractionMode = 1
            },
            @{
                Name           = "SPPerformancePointServiceApp"
                Text           = "PerformancePoint Services"
                ExtractionMode = 1
            },
            @{
                Name           = "SPPublishServiceApplication"
                Text           = "Publish"
                ExtractionMode = 1
            },
            @{
                Name           = "SPSecureStoreServiceApp"
                Text           = "Secure Store"
                ExtractionMode = 1
            },
            @{
                Name           = "SPStateServiceApp"
                Text           = "State Service Application"
                ExtractionMode = 1
            },
            @{
                Name           = "SPSubscriptionSettingsServiceApp"
                Text           = "Subscription Settings"
                ExtractionMode = 1
            },
            @{
                Name           = "SPUsageApplication"
                Text           = "Usage Service Applications"
                ExtractionMode = 1
            },
            @{
                Name           = "SPVisioServiceApp"
                Text           = "Visio Graphics"
                ExtractionMode = 1
            },
            @{
                Name           = "SPWordAutomationServiceApp"
                Text           = "Word Automation"
                ExtractionMode = 1
            },
            @{
                Name           = "SPWorkManagementServiceApp"
                Text           = "Work Management"
                ExtractionMode = 1
            }
        )
        Search                  = @(
            @{
                Name           = "SPSearchContentSource"
                Text           = "Content Sources"
                ExtractionMode = 1
            },
            @{
                Name           = "SPSearchCrawlRule"
                Text           = "Crawl Rule"
                ExtractionMode = 2
            },
            @{
                Name           = "SPSearchCrawlerImpactRule";
                Text           = "Crawler Impact Rules"
                ExtractionMode = 2
            },
            @{
                Name           = "SPSearchFileType"
                Text           = "File Types"
                ExtractionMode = 3
            },
            @{
                Name           = "SPSearchIndexPartition"
                Text           = "Index Partitions"
                ExtractionMode = 1
            },
            @{
                Name           = "SPSearchManagedProperty"
                Text           = "Managed Properties"
                ExtractionMode = 3
            },
            @{
                Name           = "SPSearchResultSource"
                Text           = "Result Sources"
                ExtractionMode = 2
            },
            @{
                Name           = "SPSearchServiceApp"
                Text           = "Search Service Applications"
                ExtractionMode = 1
            },
            @{
                Name           = "SPSearchTopology"
                Text           = "Topologies"
                ExtractionMode = 1
            }
        )
        WebApplications         = @(
            @{
                Name           = "SPWebApplicationAppDomain"
                Text           = "App Domain"
                ExtractionMode = 1
            },
            @{
                Name           = "SPWebAppBlockedFileTypes"
                Text           = "Blocked File Types"
                ExtractionMode = 2
            },
            @{
                Name           = "SPWebApplicationExtension"
                Text           = "Extensions"
                ExtractionMode = 2
            },
            @{
                Name           = "SPWebAppGeneralSettings"
                Text           = "General Settings"
                ExtractionMode = 2
            },
            @{
                Name           = "SPWebAppPermissions"
                Text           = "Permissions"
                ExtractionMode = 1
            },
            @{
                Name           = "SPWebAppPolicy"
                Text           = "Policies"
                ExtractionMode = 1
            },
            @{
                Name           = "SPWebAppProxyGroup"
                Text           = "Proxy Groups"
                ExtractionMode = 1
            },
            @{
                Name           = "SPWebAppSiteUseAndDeletion";
                Text           = "Site Use And Deletion";
                ExtractionMode = 2
            },
            @{
                Name           = "SPWebAppThrottlingSettings";
                Text           = "Throttling Settings"
                ExtractionMode = 2
            },
            @{
                Name           = "SPWebApplication"
                Text           = "Web Applications"
                ExtractionMode = 1
            },
            @{
                Name           = "SPWebAppWorkflowSettings"
                Text           = "Workflow Settings"
                ExtractionMode = 2
            }
        )
        Customization           = @(
            @{
                Name           = "SPAppCatalog"
                Text           = "App Catalog"
                ExtractionMode = 1
            },
            @{
                Name           = "SPAppDomain"
                Text           = "App Domain"
                ExtractionMode = 1
            },
            @{
                Name           = "SPAppStoreSettings"
                Text           = "App Store Settings"
                ExtractionMode = 1
            },
            @{
                Name           = "SPFarmSolution"
                Text           = "Farm Solutions"
                ExtractionMode = 1
            }
        )
        Configuration           = @(
            @{
                Name           = "SPAlternateUrl"
                Text           = "Alternate Url"
                ExtractionMode = 1
            },
            @{
                Name           = "SPAntivirusSettings"
                Text           = "Antivirus Settings"
                ExtractionMode = 1
            },
            @{
                Name           = "SPBlobCacheSettings"
                Text           = "Blob Cache Settings"
                ExtractionMode = 1
            },
            @{
                Name           = "SPCacheAccounts"
                Text           = "Cache Accounts"
                ExtractionMode = 1
            },
            @{
                Name           = "SPLogLevel"
                Text           = "Diagnostic Logging Levels"
                ExtractionMode = 1
            },
            @{
                Name           = "SPDiagnosticLoggingSettings";
                Text           = "Diagnostic Logging Settings"
                ExtractionMode = 1
            },
            @{
                Name           = "SPDistributedCacheService"  ;
                Text           = "Distributed Cache Services"
                ExtractionMode = 1
            },
            @{
                Name           = "SPDocIcon"
                Text           = "Doc Icons"
                ExtractionMode = 2
            },
            @{
                Name           = "SPFarm"
                Text           = "Farm Configuration"
                ExtractionMode = 1
            },
            @{
                Name           = "SPFarmPropertyBag"
                Text           = "Farm Property Bag"
                ExtractionMode = 1
            },
            @{
                Name           = "SPFeature"
                Text           = "Features"
                ExtractionMode = 3
            },
            @{
                Name           = "SPHealthAnalyzerRuleState"
                Text           = "Health Analyzer Rule States"
                ExtractionMode = 3
            },
            @{
                Name           = "SPIrmSettings"
                Text           = "Information Rights Management Settings"
                ExtractionMode = 1
            },
            @{
                Name           = "SPManagedPath"
                Text           = "Managed Paths"
                ExtractionMode = 1
            },
            @{
                Name           = "SPOfficeOnlineServerBinding";
                Text           = "Office Online Server Bindings"
                ExtractionMode = 2
            },
            @{
                Name           = "SPOutgoingEmailSettings"
                Text           = "Outgoing Email Settings"
                ExtractionMode = 1
            },
            @{
                Name           = "SPServiceAppPool"
                Text           = "Service Application Pools"
                ExtractionMode = 1
            },
            @{
                Name           = "SPServiceInstance"
                Text           = "Service Instances"
                ExtractionMode = 1
            },
            @{
                Name           = "SPSessionStateService"
                Text           = "Session State Services"
                ExtractionMode = 1
            },
            @{
                Name           = "SPDatabaseAAG"
                Text           = "SQL Always On Availability Groups"
                ExtractionMode = 3
            },
            @{
                Name           = "SPTimerJobState"
                Text           = "Timer Job States"
                ExtractionMode = 3
            }
        )
        UserProfile             = @(
            @{
                Name           = "SPUserProfileProperty"
                Text           = "Profile Properties"
                ExtractionMode = 3
            },
            @{
                Name           = "SPUserProfileSection"
                Text           = "Profile Sections"
                ExtractionMode = 3
            },
            @{
                Name           = "SPUserProfileSyncConnection"
                Text           = "Synchronization Connections"
                ExtractionMode = 2
            },
            @{
                Name           = "SPUserProfileServiceApp"
                Text           = "User Profile Service Applications"
                ExtractionMode = 1
            },
            @{
                Name           = "SPUserProfileServiceAppPermissions"
                Text           = "User Profile Service Permissions"
                ExtractionMode = 2
            }
        )
    }

    #region Global
    $firstColumnLeft = 10
    $secondColumnLeft = 280
    $thirdColumnLeft = 540
    $topBannerHeight = 70
    #endregion

    $Global:liteComponents = @()
    $Global:defaultComponents = @()

    $form = New-Object System.Windows.Forms.Form
    $screens = [System.Windows.Forms.Screen]::AllScreens
    $form.Width = ($screens[0].Bounds.Width) / 2
    $form.Height = ($screens[0].Bounds.Height) / 2
    #$form.WindowState = [System.Windows.Forms.FormWindowState]::Maximized

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
    $panelInformationArchitecture.AutoSize = $true
    $panelInformationArchitecture.Height = 80
    $panelInformationArchitecture.Width = 220
    $panelInformationArchitecture.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

    $align = 0
    foreach ($resource in $components.InformationArchitecture)
    {
        $checkbox = New-Object System.Windows.Forms.CheckBox
        $checkbox.Top = $align
        $checkbox.AutoSize = $true;
        $checkbox.Name = $resource.Name
        $checkbox.Text = $resource.Text

        $checked = $false
        if ($resource.ExtractionMode -le 1)
        {
            $Global:liteComponents += $checkbox
        }

        if ($resource.ExtractionMode -le 2)
        {
            $Global:defaultComponents += $checkbox
            $checked = $true
        }
        $checkbox.Checked = $checked

        $panelInformationArchitecture.Controls.Add($checkbox)
        $align += 20
    }
    $panelMain.Controls.Add($panelInformationArchitecture)
    #endregion Information Architecture

    #region Security
    $labelSecurity = New-Object System.Windows.Forms.Label
    $labelSecurity.Text = "Security:"
    $labelSecurity.AutoSize = $true
    $labelSecurity.Top = $panelInformationArchitecture.Top + $panelInformationArchitecture.Height + 10
    $labelSecurity.Left = $firstColumnLeft
    $labelSecurity.Font = [System.Drawing.Font]::new($labelSecurity.Font.Name, 14, [System.Drawing.FontStyle]::Bold)
    $panelMain.Controls.Add($labelSecurity)

    $panelSecurity = New-Object System.Windows.Forms.Panel
    $panelSecurity.Top = $panelInformationArchitecture.Top + $panelInformationArchitecture.Height + 40
    $panelSecurity.Left = $firstColumnLeft
    $panelSecurity.AutoSize = $true
    $panelSecurity.Width = 220
    $panelSecurity.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

    $align = 0
    foreach ($resource in $components.Security)
    {
        $checkbox = New-Object System.Windows.Forms.CheckBox
        $checkbox.Top = $align
        $checkbox.AutoSize = $true;
        $checkbox.Name = $resource.Name
        $checkbox.Text = $resource.Text

        $checked = $false
        if ($resource.ExtractionMode -le 1)
        {
            $Global:liteComponents += $checkbox
        }

        if ($resource.ExtractionMode -le 2)
        {
            $Global:defaultComponents += $checkbox
            $checked = $true
        }
        $checkbox.Checked = $checked

        $panelSecurity.Controls.Add($checkbox)
        $align += 20
    }

    $panelMain.Controls.Add($panelSecurity)
    #endregion Security

    #region Service Applications
    $labelSA = New-Object System.Windows.Forms.Label
    $labelSA.Text = "Service Applications:"
    $labelSA.AutoSize = $true
    $labelSA.Top = $panelSecurity.Top + $panelSecurity.Height + 10
    $labelSA.Left = $firstColumnLeft
    $labelSA.Font = [System.Drawing.Font]::new($labelSA.Font.Name, 14, [System.Drawing.FontStyle]::Bold)
    $panelMain.Controls.Add($labelSA)

    $panelSA = New-Object System.Windows.Forms.Panel
    $panelSA.Top = $panelSecurity.Top + $panelSecurity.Height + 40
    $panelSA.Left = $firstColumnLeft
    $panelSA.AutoSize = $true
    $panelSA.Width = 220
    $panelSA.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

    $align = 0
    foreach ($resource in $components.ServiceApplications)
    {
        $checkbox = New-Object System.Windows.Forms.CheckBox
        $checkbox.Top = $align
        $checkbox.AutoSize = $true;
        $checkbox.Name = $resource.Name
        $checkbox.Text = $resource.Text

        $checked = $false
        if ($resource.ExtractionMode -le 1)
        {
            $Global:liteComponents += $checkbox
        }

        if ($resource.ExtractionMode -le 2)
        {
            $Global:defaultComponents += $checkbox
            $checked = $true
        }
        $checkbox.Checked = $checked

        $panelSA.Controls.Add($checkbox)
        $align += 20
    }

    $panelMain.Controls.Add($panelSA)
    #endregion Service Applications

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

    $align = 0
    foreach ($resource in $components.Search)
    {
        $checkbox = New-Object System.Windows.Forms.CheckBox
        $checkbox.Top = $align
        $checkbox.AutoSize = $true;
        $checkbox.Name = $resource.Name
        $checkbox.Text = $resource.Text

        $checked = $false
        if ($resource.ExtractionMode -le 1)
        {
            $Global:liteComponents += $checkbox
        }

        if ($resource.ExtractionMode -le 2)
        {
            $Global:defaultComponents += $checkbox
            $checked = $true
        }
        $checkbox.Checked = $checked

        $panelSearch.Controls.Add($checkbox)
        $align += 20
    }

    $panelMain.Controls.Add($panelSearch)
    #endregion Search

    #region Web Applications
    $labelWebApplications = New-Object System.Windows.Forms.Label
    $labelWebApplications.Text = "Web Applications:"
    $labelWebApplications.AutoSize = $true
    $labelWebApplications.Top = $panelSearch.Top + $panelSearch.Height + 10
    $labelWebApplications.Left = $secondColumnLeft
    $labelWebApplications.Font = [System.Drawing.Font]::new($labelWebApplications.Font.Name, 14, [System.Drawing.FontStyle]::Bold)
    $panelMain.Controls.Add($labelWebApplications)

    $panelWebApp = New-Object System.Windows.Forms.Panel
    $panelWebApp.Top = $panelSearch.Top + $panelSearch.Height + 40
    $panelWebApp.Left = $secondColumnLeft
    $panelWebApp.AutoSize = $true
    #$panelWebApp.Width = 220
    $panelWebApp.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

    $align = 0
    foreach ($resource in $components.WebApplications)
    {
        $checkbox = New-Object System.Windows.Forms.CheckBox
        $checkbox.Top = $align
        $checkbox.AutoSize = $true;
        $checkbox.Name = $resource.Name
        $checkbox.Text = $resource.Text

        $checked = $false
        if ($resource.ExtractionMode -le 1)
        {
            $Global:liteComponents += $checkbox
        }

        if ($resource.ExtractionMode -le 2)
        {
            $Global:defaultComponents += $checkbox
            $checked = $true
        }
        $checkbox.Checked = $checked

        $panelWebApp.Controls.Add($checkbox)
        $align += 20
    }

    $panelMain.Controls.Add($panelWebApp)
    #endregion Web Applications

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
    $panelCustomization.AutoSize = $true
    $panelCustomization.Height = 80
    $panelCustomization.Width = 220
    $panelCustomization.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

    $align = 0
    foreach ($resource in $components.Customization)
    {
        $checkbox = New-Object System.Windows.Forms.CheckBox
        $checkbox.Top = $align
        $checkbox.AutoSize = $true;
        $checkbox.Name = $resource.Name
        $checkbox.Text = $resource.Text

        $checked = $false
        if ($resource.ExtractionMode -le 1)
        {
            $Global:liteComponents += $checkbox
        }

        if ($resource.ExtractionMode -le 2)
        {
            $Global:defaultComponents += $checkbox
            $checked = $true
        }
        $checkbox.Checked = $checked

        $panelCustomization.Controls.Add($checkbox)
        $align += 20
    }

    $panelMain.Controls.Add($panelCustomization)
    #endregion Customization

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

    $align = 0
    foreach ($resource in $components.Configuration)
    {
        $checkbox = New-Object System.Windows.Forms.CheckBox
        $checkbox.Top = $align
        $checkbox.AutoSize = $true;
        $checkbox.Name = $resource.Name
        $checkbox.Text = $resource.Text

        $checked = $false
        if ($resource.ExtractionMode -le 1)
        {
            $Global:liteComponents += $checkbox
        }

        if ($resource.ExtractionMode -le 2)
        {
            $Global:defaultComponents += $checkbox
            $checked = $true
        }
        $checkbox.Checked = $checked

        $panelConfig.Controls.Add($checkbox)
        $align += 20
    }

    $panelMain.Controls.Add($panelConfig)
    #endregion Configuration

    #region User Profile Service
    $lblUPS = New-Object System.Windows.Forms.Label
    $lblUPS.Top = $panelConfig.Top + $panelConfig.Height + 10
    $lblUPS.Text = "User Profile:"
    $lblUPS.AutoSize = $true
    $lblUPS.Left = $thirdColumnLeft
    $lblUPS.Font = [System.Drawing.Font]::new($lblUPS.Font.Name, 14, [System.Drawing.FontStyle]::Bold)
    $panelMain.Controls.Add($lblUPS)

    $panelUPS = New-Object System.Windows.Forms.Panel
    $panelUPS.Top = $panelConfig.Top + $panelConfig.Height + 40
    $panelUPS.Left = $thirdColumnLeft
    $panelUPS.AutoSize = $true
    $panelUPS.Width = 400
    $panelUPS.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

    $align = 0
    foreach ($resource in $components.UserProfile)
    {
        $checkbox = New-Object System.Windows.Forms.CheckBox
        $checkbox.Top = $align
        $checkbox.AutoSize = $true;
        $checkbox.Name = $resource.Name
        $checkbox.Text = $resource.Text

        $checked = $false
        if ($resource.ExtractionMode -le 1)
        {
            $Global:liteComponents += $checkbox
        }

        if ($resource.ExtractionMode -le 2)
        {
            $Global:defaultComponents += $checkbox
            $checked = $true
        }
        $checkbox.Checked = $checked

        $panelUPS.Controls.Add($checkbox)
        $align += 20
    }

    $panelMain.Controls.Add($panelUPS)
    #endregion User Profile Service

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
                $SelectedComponents += "SPInstallPrereqs"
                $SelectedComponents += "SPInstall"
                foreach ($panel in ($form.Controls[0].Controls | Where-Object { $_.GetType().Name -eq "Panel" }))
                {
                    foreach ($checkbox in ($panel.Controls | Where-Object { $_.GetType().Name -eq "Checkbox" }))
                    {
                        if ($checkbox.Checked -and $checkbox.Name -NotIn @("chckRequiredUsers", "chckAzure", "chckStandAlone"))
                        {
                            $SelectedComponents += $checkbox.Name
                        }
                    }
                }
                $form.Hide()
                $componentsToString = "@(`"" + ($SelectedComponents -join "`",`"") + "`")"
                Write-Host -Object "To execute the same extraction process unattended, run the following command:" -BackgroundColor DarkGreen -ForegroundColor White
                Write-Host -Object "Export-SPConfiguration -ComponentsToExtract $componentsToString -Credentials (Get-Credential)"

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

    $spDscModule = (Get-Module "SharePointDSC")

    $panelMain.AutoScroll = $true
    $form.Controls.Add($panelMain)
    $form.Text = "ReverseDSC for SharePoint - v" + $spDscModule.Version.ToString()
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

function Set-SPDscTermStoreAdministratorsBlock
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

function Set-SPDscTermStoreAdministrators
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
                Write-Host -Object "    -> Scanning TermStore Admins [$i/$total]"
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
