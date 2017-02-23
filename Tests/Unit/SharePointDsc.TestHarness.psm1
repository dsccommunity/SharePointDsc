function New-SPDscUnitTestHelper
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]
        $SharePointStubModule,

        [Parameter(Mandatory = $true, ParameterSetName = 'DscResource')]
        [String]
        $DscResource,

        [Parameter(Mandatory = $true, ParameterSetName = 'SubModule')]
        [String]
        $SubModulePath,

        [Parameter(Mandatory = $false)]
        [Switch]
        $ExcludeInvokeHelper,

        [Parameter(Mandatory = $false)]
        [Switch]
        $IncludeDistributedCacheStubs
    )

    $repoRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\..\" -Resolve
    $moduleRoot = Join-Path -Path $repoRoot -ChildPath "Modules\SharePointDsc"

    if ($PSBoundParameters.ContainsKey("SubModulePath") -eq $true)
    {
        $describeHeader = "Sub-module '$SubModulePath'"
        $moduleToLoad = Join-Path -Path $moduleRoot -ChildPath $SubModulePath
        $moduleName = (Get-Item -Path $moduleToLoad).BaseName
    }

    if ($PSBoundParameters.ContainsKey("DscResource") -eq $true)
    {
        $describeHeader = "DSC Resource '$DscResource'"
        $moduleName = "MSFT_$DscResource"
        $modulePath = "DSCResources\MSFT_$DscResource\MSFT_$DscResource.psm1"
        $moduleToLoad = Join-Path -Path $moduleRoot -ChildPath $modulePath
    }

    $spBuild = (Get-Item -Path $SharePointStubModule).Directory.BaseName
    $firstDot = $spBuild.IndexOf(".")
    $majorBuildNumber = $spBuild.Substring(0, $firstDot)

    $describeHeader += " [SP Build: $spBuild]"

    Import-Module -Name $moduleToLoad -Global

    

    $initScript = @"
            Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
            Import-Module -Name "$SharePointStubModule" -WarningAction SilentlyContinue
            Import-Module -Name "$moduleToLoad"
            
            Mock -CommandName Get-SPDSCInstalledProductVersion -MockWith { 
                return @{ 
                    FileMajorPart = $majorBuildNumber 
                } 
            }

            Mock -CommandName Get-SPDSCAssemblyVersion -MockWith {
                return $majorBuildNumber
            }
            
"@

    if ($ExcludeInvokeHelper -eq $false) 
    {
        $initScript += @"
            Mock Invoke-SPDSCCommand { 
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
        DescribeHeader = $describeHeader
        ModuleName = $moduleName
        CurrentStubModulePath = $SharePointStubModule
        CurrentStubBuildNumber = [Version]::Parse($spBuild)
        InitializeScript = [ScriptBlock]::Create($initScript)
        RepoRoot = $repoRoot
        CleanupScript = [ScriptBlock]::Create(@"

            Get-Variable -Scope Global -Name "SPDsc*" | Remove-Variable -Force -Scope "Global"
            `$global:DSCMachineStatus = 0
            
"@)
    }
}

function Write-SPDSCStubFile() {
    param
    (
        [parameter(Mandatory = $true)] 
        [System.String] 
        $SharePointStubPath
    )

    Add-PSSnapin Microsoft.SharePoint.PowerShell 

    $SPStubContent = ((Get-Command | Where-Object -FilterScript { 
        $_.Source -eq "Microsoft.SharePoint.PowerShell" 
    } )  |  ForEach-Object -Process {
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