Import-Module (Join-Path $PSScriptRoot "..\Tests\xSharePoint.TestHarness.psm1"  -Resolve)

$DscTestsPath = Join-Path $PSScriptRoot "..\Modules\xSharePoint\DscResource.Tests" -Resolve
if ((Test-Path $DscTestsPath) -eq $false) {
    Write-Warning "Unable to locate DscResource.Tests repo at '$DscTestsPath', common DSC resource tests will not be executed"
    Invoke-xSharePointTests
} else {
    Invoke-xSharePointTests -DscTestsPath $DscTestsPath
}

