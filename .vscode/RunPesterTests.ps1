Import-Module (Join-Path $PSScriptRoot "..\Tests\Unit\SharePointDsc.TestHarness.psm1"  -Resolve) -Force

$DscTestsPath = Join-Path $PSScriptRoot "..\Modules\SharePointDsc\DscResource.Tests" -Resolve
if ((Test-Path $DscTestsPath) -eq $false) {
    Write-Warning "Unable to locate DscResource.Tests repo at '$DscTestsPath', common DSC resource tests will not be executed"
    Invoke-SPDscUnitTestSuite -CalculateTestCoverage $false
} else {
    Invoke-SPDscUnitTestSuite -DscTestsPath $DscTestsPath -CalculateTestCoverage $false
}

