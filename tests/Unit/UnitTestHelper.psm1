function New-SPDscUnitTestHelper
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $SharePointStubModule,

        [Parameter(Mandatory = $true, ParameterSetName = 'DscResource')]
        [String]
        $DscResource,

        [Parameter()]
        [String]
        $ModuleVersion,

        [Parameter(Mandatory = $true, ParameterSetName = 'SubModule')]
        [String]
        $SubModulePath,

        [Parameter()]
        [Switch]
        $ExcludeInvokeHelper,

        [Parameter()]
        [Switch]
        $IncludeDistributedCacheStubs
    )

    $spBuild = (Get-Item -Path $SharePointStubModule).Directory.BaseName
    $spBuildParts = $spBuild.Split('.')
    $majorBuildNumber = $spBuildParts[0]
    $minorBuildNumber = $spBuildParts[2]

    $describeHeader += "[SP Build: $spBuild] "

    $repoRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\..\" -Resolve
    $moduleRoot = (Get-Module SharePointDsc -ListAvailable).ModuleBase

    $initScript = @"
    Set-StrictMode -Version 1
    Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
    Import-Module -Name "$SharePointStubModule" -WarningAction SilentlyContinue

"@

    if ($PSBoundParameters.ContainsKey("SubModulePath") -eq $true)
    {
        $describeHeader += "Sub-module '$SubModulePath'"
        $moduleToLoad = Join-Path -Path $moduleRoot -ChildPath $SubModulePath
        $moduleName = (Get-Item -Path $moduleToLoad).BaseName

        if ($null -eq (Get-Module -Name $moduleName))
        {
            Import-Module -Name $moduleToLoad -Global
        }

        #$initScript += @"
        #if (`$null -eq (Get-Module -Name $moduleName))
        #{
        #    Import-Module -Name "$moduleToLoad"
        #}

        #"@
    }

    if ($PSBoundParameters.ContainsKey("DscResource") -eq $true)
    {
        $describeHeader += "DSC Resource '$DscResource'"
        $moduleName = "MSFT_$DscResource"
    }

    $initScript += @"
    Mock -CommandName Get-SPDscInstalledProductVersion -MockWith {
        return @{
            FileMajorPart = $majorBuildNumber
            FileBuildPart = $minorBuildNumber
            ProductBuildPart = $minorBuildNumber
        }
    }

    Mock -CommandName Get-SPDscAssemblyVersion -MockWith {
        return $majorBuildNumber
    }

    Mock -CommandName Get-SPDscBuildVersion -MockWith {
        return $minorBuildNumber
    }

"@

    if ($ExcludeInvokeHelper -eq $false)
    {
        $initScript += @"
            Mock Invoke-SPDscCommand {
                return Invoke-Command -ScriptBlock `$ScriptBlock -ArgumentList `$Arguments -NoNewScope
            }
"@
    }

    if ($IncludeDistributedCacheStubs -eq $true)
    {
        $dcachePath = Join-Path -Path $repoRoot `
            -ChildPath "Tests\Unit\Stubs\DistributedCache\DistributedCache.psm1"
        $initScript += @"

            Import-Module -Name "$dcachePath" -WarningAction SilentlyContinue

"@
    }

    return @{
        DescribeHeader         = $describeHeader
        ModuleName             = $moduleName
        ModuleVersion          = $ModuleVersion
        CurrentStubModulePath  = $SharePointStubModule
        CurrentStubBuildNumber = [Version]::Parse($spBuild)
        InitializeScript       = [ScriptBlock]::Create($initScript)
        RepoRoot               = $repoRoot
        CleanupScript          = [ScriptBlock]::Create(@"

            Get-Variable -Scope Global -Name "SPDsc*" | Remove-Variable -Force -Scope "Global"
            `$global:DSCMachineStatus = 0

"@)
    }
}

function Write-SPDscStubFile
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $SharePointStubPath
    )

    Add-PSSnapin Microsoft.SharePoint.PowerShell

    $SPStubContent = ((Get-Command | Where-Object -FilterScript {
                $_.Source -eq "Microsoft.SharePoint.PowerShell"
            } ) | ForEach-Object -Process {
            $signature = $null
            $command = $_
            $metadata = New-Object -TypeName System.Management.Automation.CommandMetaData `
                -ArgumentList $command
            $definition = [System.Management.Automation.ProxyCommand]::Create($metadata)
            foreach ($line in $definition -split "`n")
            {
                if ($line.Trim() -eq 'begin')
                {
                    break
                }
                $signature += $line
            }
            "function $($command.Name) { `n  $signature `n } `n"
        }) | Out-String

    foreach ($line in $SPStubContent.Split([Environment]::NewLine))
    {
        $line = $line.Replace("[System.Nullable``1[[Microsoft.Office.Server.Search.Cmdlet.ContentSourceCrawlScheduleType, Microsoft.Office.Server.Search.PowerShell, Version=15.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c]], mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089]", "[object]")
        $line = $line.Replace("[System.Collections.Generic.List``1[[Microsoft.SharePoint.PowerShell.SPUserLicenseMapping, Microsoft.SharePoint.PowerShell, Version=15.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c]], mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089]", "[object]")
        $line = $line -replace "\[System.Nullable\[Microsoft.*]]", "[System.Nullable[object]]"
        $line = $line -replace "\[Microsoft.*.\]", "[object]"

        $line | Out-File -FilePath $SharePointStubPath -Encoding utf8 -Append
    }
}

function Get-SPDscRegistryValue
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $OutPath
    )

    $patchRegistryPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Patches"

    $installerRegistryPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products"
    $installerEntries = Get-ChildItem $installerRegistryPath -ErrorAction SilentlyContinue
    $officeProductKeys = $installerEntries | Where-Object -FilterScript { $_.PsPath -like "*00000000F01FEC" }

    $productInfo = @()
    $productPatches = @()
    $detailedPatchInformation = @()
    $null = $officeProductKeys | ForEach-Object -Process {

        $officeProductKey = $_

        $productInfo += Get-ItemProperty "Registry::$($officeProductKey)\InstallProperties" -ErrorAction SilentlyContinue

        $patchInformationFolder = Get-ItemProperty "Registry::$($officeProductKey)\Patches" -ErrorAction SilentlyContinue
        $productPatches += $patchInformationFolder

        if ($patchInformationFolder.AllPatches.GetType().Name -eq "String[]" -and $patchInformationFolder.AllPatches.Length -gt 0)
        {
            $patchGuid = $patchInformationFolder.AllPatches[$patchInformationFolder.AllPatches.Length - 1]
        }
        else
        {
            $patchGuid = $patchInformationFolder.AllPatches
        }

        if ($null -ne $patchGuid)
        {
            $detailedPatchInformation += Get-ItemProperty "$($patchRegistryPath)\$($patchGuid)"
        }

    }

    $registryHash = @{
        Products                  = $officeProductKeys
        ProductsInstallProperties = $productInfo
        ProductsPatches           = $productPatches
        Patches                   = $detailedPatchInformation
    }

    ConvertTo-Json $registryHash -Compress > $OutPath
}
