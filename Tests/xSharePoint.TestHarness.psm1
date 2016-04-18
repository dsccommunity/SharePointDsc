function Invoke-xSharePointTests() {
    param
    (
        [parameter(Mandatory = $false)] [System.String] $testResultsFile,
        [parameter(Mandatory = $false)] [System.String] $DscTestsPath
    )

    Write-Verbose "Commencing xSharePoint unit tests"

    $repoDir = Join-Path $PSScriptRoot "..\" -Resolve

    $testCoverageFiles = @()
    Get-ChildItem "$repoDir\modules\xSharePoint\**\*.psm1" -Recurse | ForEach-Object { 
        if ($_.FullName -like "*\DSCResource.Tests\*") {
            $testCoverageFiles += $_.FullName    
        }
    }

    $testResultSettings = @{ }
    if ([string]::IsNullOrEmpty($testResultsFile) -eq $false) {
        $testResultSettings.Add("OutputFormat", "NUnitXml" )
        $testResultSettings.Add("OutputFile", $testResultsFile)
    }
    Import-Module "$repoDir\modules\xSharePoint\xSharePoint.psd1"
    
    
    $versionsToTest = (Get-ChildItem (Join-Path $repoDir "\Tests\Stubs\SharePoint\")).Name
    
    # Import the first stub found so that there is a base module loaded before the tests start
    $firstVersion = $versionsToTest | Select -First 1
    Import-Module (Join-Path $repoDir "\Tests\Stubs\SharePoint\$firstVersion\Microsoft.SharePoint.PowerShell.psm1") -WarningAction SilentlyContinue

    $testsToRun = @()
    $versionsToTest | ForEach-Object {
        $testsToRun += @(@{
            'Path' = "$repoDir\Tests"
            'Parameters' = @{ 
                'SharePointCmdletModule' = (Join-Path $repoDir "\Tests\Stubs\SharePoint\$_\Microsoft.SharePoint.PowerShell.psm1")
            }
        })
    }
    
    if ($PSBoundParameters.ContainsKey("DscTestsPath") -eq $true) {
        $testsToRun += @{
            'Path' = $DscTestsPath
            'Parameters' = @{ }
        }
    }
    $results = Invoke-Pester -Script $testsToRun -CodeCoverage $testCoverageFiles -PassThru @testResultSettings

    return $results
}

function Write-xSharePointStubFiles() {
    param
    (
        [parameter(Mandatory = $true)] [System.String] $SharePointStubPath
    )

    Add-PSSnapin Microsoft.SharePoint.PowerShell 

    $SPStubContent = ((Get-Command | Where-Object { $_.Source -eq "Microsoft.SharePoint.PowerShell" } )  |  ForEach-Object -Process {
       $signature = $null
       $command = $_
       $metadata = New-Object -TypeName System.Management.Automation.CommandMetaData -ArgumentList $command
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

    foreach ($line in $SPStubContent.Split([Environment]::NewLine)) {
        $line = $line.Replace("[System.Nullable``1[[Microsoft.Office.Server.Search.Cmdlet.ContentSourceCrawlScheduleType, Microsoft.Office.Server.Search.PowerShell, Version=15.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c]], mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089]", "[object]")
        $line = $line.Replace("[System.Collections.Generic.List``1[[Microsoft.SharePoint.PowerShell.SPUserLicenseMapping, Microsoft.SharePoint.PowerShell, Version=15.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c]], mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089]", "[object]")
        $line = $line -replace "\[System.Nullable\[Microsoft.*]]", "[System.Nullable[object]]"
        $line = $line -replace "\[Microsoft.*.\]", "[object]"
        
        $line | Out-File $SharePointStubPath -Encoding utf8 -Append
    }
}