
$harnessPath = Join-Path -Path $PSScriptRoot `
                         -ChildPath "..\Tests\TestHarness.psm1" `
                         -Resolve
Import-Module -Name $harnessPath -Force

$DscTestsPath = Join-Path -Path $PSScriptRoot `
                          -ChildPath "..\Modules\SharePointDsc\DscResource.Tests"

if ((Test-Path -Path $DscTestsPath) -eq $false)
{
    Write-Warning -Message ("Unable to locate DscResource.Tests repo at '$DscTestsPath', " + `
                            "common DSC resource tests will not be executed")
    $result = Invoke-TestHarness -IgnoreCodeCoverage
}
else
{
    $result = Invoke-TestHarness -DscTestsPath $DscTestsPath -IgnoreCodeCoverage
}

if ($result.FailedCount -gt 0)
{
    Write-Output -InputObject "Failed test result summary:"
    $result.TestResult | Where-Object -FilterScript {
        $_.Passed -eq $false
    } | ForEach-Object -Process {
        Write-Output -InputObject "-----------------------------------------------------------"
        $outputObject = @{
            Context = $_.Context
            Describe = $_.Describe
            Name = $_.Name
            FailureMessage = $_.FailureMessage
        }
        New-Object -TypeName PSObject -Property $outputObject | Format-List
    }

    throw "$($result.FailedCount) tests failed."
}
