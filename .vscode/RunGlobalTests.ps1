$harnessPath = Join-Path -Path $PSScriptRoot `
                         -ChildPath "..\Tests\TestHarness.psm1"
Import-Module -Name $harnessPath

$DscTestsPath = Join-Path -Path $PSScriptRoot `
                          -ChildPath "..\Modules\SharePointDsc\DscResource.Tests"

if ((Test-Path -Path $DscTestsPath) -eq $false) 
{
    throw ("Unable to locate DscResource.Tests repo at '$DscTestsPath', " + `
           "common DSC resource tests will not be executed")
}

$helperPath = Join-Path -Path $PSScriptRoot `
                        -ChildPath "..\Modules\SharePointDsc\DscResource.Tests\TestHelper.psm1"
Import-Module -Name $helperPath

$helperTestsPath = Join-Path -Path $PSScriptRoot `
                             -ChildPath "..\Modules\SharePointDsc\DscResource.Tests"
Set-Location -Path $helperTestsPath

$result = Invoke-Pester -PassThru

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
