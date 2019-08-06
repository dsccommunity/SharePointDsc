[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]
    $UnitTestFilePath,

    [Parameter(Mandatory = $true)]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
            -Resolve)
)

if ($UnitTestFilePath.EndsWith("Tests.ps1"))
{

    $pesterParameters = @{
        Path       = $unitTestFilePath
        Parameters = @{
            SharePointCmdletModule = $SharePointCmdletModule
        }
    }

    $unitTest = Get-Item -Path $UnitTestFilePath
    $unitTestName = "$($unitTest.Name.Split('.')[1])"

    $unitTestFilePath = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Modules\SharePointDsc\DSCResources\MSFT_$($unitTestName)\MSFT_$($unitTestName).psm1" `
            -Resolve)

    Invoke-Pester -Script $pesterParameters -CodeCoverage $UnitTestFilePath -Verbose
}
