#Requires -RunAsAdministrator

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [System.String]
    $Resource,

    [Parameter()]
    [Switch]
    $DoNotBuildModule
)

$modulePath = Split-Path -Path $PSScriptRoot

if ($DoNotBuildModule -eq $false)
{
    & $modulePath\build.ps1 -Tasks Build
}

$path15 = Join-Path -Path $modulePath -ChildPath '\Tests\Unit\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1'
$path16 = Join-Path -Path $modulePath -ChildPath '\Tests\Unit\Stubs\SharePoint\16.0.4456.1000\Microsoft.SharePoint.PowerShell.psm1'
$path19 = Join-Path -Path $modulePath -ChildPath '\Tests\Unit\Stubs\SharePoint\16.0.10337.12109\Microsoft.SharePoint.PowerShell.psm1'
$pathSE = Join-Path -Path $modulePath -ChildPath '\Tests\Unit\Stubs\SharePoint\16.0.14326.20450\SharePointServer.psm1'

$testPath = Join-Path -Path $modulePath -ChildPath ".\Tests\Unit\SharePointDsc\SharePointDsc.$resource.Tests.ps1"
$compiledModulePath = Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path
$resourcePath = Join-Path -Path $compiledModulePath -ChildPath "\DSCResources\MSFT_$resource\MSFT_$resource.psm1"
Invoke-Pester -Script @(
    @{ Path = $testPath; Parameters = @{SharePointCmdletModule = $path15 } },
    @{ Path = $testPath; Parameters = @{SharePointCmdletModule = $path16 } },
    @{ Path = $testPath; Parameters = @{SharePointCmdletModule = $path19 } },
    @{ Path = $testPath; Parameters = @{SharePointCmdletModule = $pathSE } }
) -CodeCoverage $resourcePath
