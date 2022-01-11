#Requires -RunAsAdministrator

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("2013", "2016", "2019", "Subscription")]
    [System.String]
    $SharePointVersion,

    [Parameter()]
    [Switch]
    $DoNotBuildModule
)

$modulePath = Split-Path -Path $PSScriptRoot

if ($DoNotBuildModule -eq $false)
{
    & $modulePath\build.ps1 -Tasks Build
}

$testPath = Join-Path -Path $modulePath -ChildPath "\Tests\Unit\SharePointDsc"

$params = @{
    Tasks = 'Test'
}

switch ($SharePointVersion)
{
    "2013"
    {
        $stubPath = Join-Path -Path $modulePath -ChildPath '\Tests\Unit\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1'
    }
    "2016"
    {
        $stubPath = Join-Path -Path $modulePath -ChildPath '\Tests\Unit\Stubs\SharePoint\16.0.4456.1000\Microsoft.SharePoint.PowerShell.psm1'
    }
    "2019"
    {
        $stubPath = Join-Path -Path $modulePath -ChildPath '\Tests\Unit\Stubs\SharePoint\16.0.10337.12109\Microsoft.SharePoint.PowerShell.psm1'
    }
    "Subscription"
    {
        $stubPath = Join-Path -Path $modulePath -ChildPath '\Tests\Unit\Stubs\SharePoint\16.0.14326.20450/SharePointServer.psm1'
    }
}

$params.PesterScript = @(
    @{
        Path       = $testPath
        Parameters = @{
            SharePointCmdletModule = $stubPath
        }
    }
)

& $modulePath\build.ps1 @params
