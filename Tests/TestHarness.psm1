function Invoke-TestHarness
{
    [CmdletBinding()]
    param
    (
        [System.String]
        $TestResultsFile,

        [System.String]
        $DscTestsPath
    )

    Write-Verbose -Message 'Commencing all SharePointDsc tests'

    $repoDir = Join-Path -Path $PSScriptRoot -ChildPath '..\' -Resolve

    $testCoverageFiles = @()
    Get-ChildItem -Path "$repoDir\modules\SharePointDsc\DSCResources\**\*.psm1" -Recurse | ForEach-Object {
        if ($_.FullName -notlike '*\DSCResource.Tests\*') {
            $testCoverageFiles += $_.FullName
        }
    }

    $testResultSettings = @{ }
    if ([String]::IsNullOrEmpty($TestResultsFile) -eq $false) {
        $testResultSettings.Add('OutputFormat', 'NUnitXml' )
        $testResultSettings.Add('OutputFile', $TestResultsFile)
    }

    Import-Module -Name "$repoDir\modules\SharePointDsc\SharePointDsc.psd1"
    $testsToRun = @()

    # Run Unit Tests
    $versionsPath = Join-Path -Path $repoDir -ChildPath "\Tests\Unit\Stubs\SharePoint\"
    $versionsToTest = (Get-ChildItem -Path $versionsPath).Name
    # Import the first stub found so that there is a base module loaded before the tests start
    $firstVersion = $versionsToTest | Select-Object -First 1
    $firstStub = Join-Path -Path $repoDir `
                           -ChildPath "\Tests\Unit\Stubs\SharePoint\$firstVersion\Microsoft.SharePoint.PowerShell.psm1"
    Import-Module $firstStub -WarningAction SilentlyContinue

    $versionsToTest | ForEach-Object -Process {
        $stubPath = Join-Path -Path $repoDir `
                              -ChildPath "\Tests\Unit\Stubs\SharePoint\$_\Microsoft.SharePoint.PowerShell.psm1"
        $testsToRun += @(@{
            'Path' = (Join-Path -Path $repoDir -ChildPath "\Tests\Unit")
            'Parameters' = @{ 
                'SharePointCmdletModule' = $stubPath
            }
        })
    }

    # Integration Tests (not run in appveyor due to time/reboots needed to install SharePoint)
    #$integrationTestsPath = Join-Path -Path $repoDir -ChildPath 'Tests\Integration'
    #$testsToRun += @( (Get-ChildItem -Path $integrationTestsPath -Filter '*.Tests.ps1').FullName )

    # DSC Common Tests
    if ($PSBoundParameters.ContainsKey('DscTestsPath') -eq $true)
    {
        $testsToRun += @( $DscTestsPath )
    }

    $results = Invoke-Pester -Script $testsToRun `
                             -CodeCoverage $testCoverageFiles `
                             -PassThru @testResultSettings

    return $results
}