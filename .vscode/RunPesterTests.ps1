
$harnessPath = Join-Path -Path $PSScriptRoot `
                         -ChildPath "..\Tests\Unit\SharePointDsc.TestHarness.psm1" `
                         -Resolve
Import-Module -Name $harnessPath -Force

$DscTestsPath = Join-Path -Path $PSScriptRoot `
                          -ChildPath "..\Modules\SharePointDsc\DscResource.Tests" `
                          -Resolve
if ((Test-Path $DscTestsPath) -eq $false) 
{
    Write-Warning -Message ("Unable to locate DscResource.Tests repo at '$DscTestsPath', " + `
                            "common DSC resource tests will not be executed")
    Invoke-SPDscUnitTestSuite -CalculateTestCoverage $false
} 
else 
{
    Invoke-SPDscUnitTestSuite -DscTestsPath $DscTestsPath -CalculateTestCoverage $false
}
