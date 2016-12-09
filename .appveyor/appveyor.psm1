function Start-AppveyorInstallTask
{
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    Install-Module -Name Pester -Force
    Start-Process -Wait -FilePath "git" -ArgumentList @(
        "clone",
        "-q",
        "https://github.com/PowerShell/DscResource.Tests",
        (Join-Path -Path $env:APPVEYOR_BUILD_FOLDER `
                   -ChildPath "Modules\SharePointDsc\DscResource.Tests")
    )
    Start-Process -Wait -FilePath "git" -ArgumentList @(
        "clone",
        "-q",
        "https://github.com/PowerShell/DscResources",
        (Join-Path -Path $env:APPVEYOR_BUILD_FOLDER -ChildPath "DscResources")
    )
    $testHelperPath = Join-Path -Path $env:APPVEYOR_BUILD_FOLDER `
                                -ChildPath "Modules\SharePointDsc\DscResource.Tests\TestHelper.psm1"
    Import-Module -Name $testHelperPath -Force
}

function Start-AppveyorTestScriptTask
{
    $testResultsFile = ".\TestsResults.xml"
    $testHarnessPath = Join-Path -Path $env:APPVEYOR_BUILD_FOLDER `
                                 -ChildPath "\Tests\Unit\SharePointDsc.TestHarness.psm1"
    $dscTestsPath = Join-Path -Path $env:APPVEYOR_BUILD_FOLDER `
                              -ChildPath "Modules\SharePointDsc\DscResource.Tests"
    Import-Module -Name $testHarnessPath

    $result = Invoke-SPDscUnitTestSuite -TestResultsFile $testResultsFile `
                                        -DscTestsPath $dscTestsPath

    $webClient = New-Object -TypeName "System.Net.WebClient" 

    $testResultsFilePath = Resolve-Path -Path $testResultsFile
    $webClient.UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", 
                          $testResultsFilePath)
    
    if ($result.FailedCount -gt 0) 
    { 
        throw "$($result.FailedCount) tests failed."
    }
}

function Start-AppveyorAfterTestTask
{
    # Move the DSC resource tests folder out so it isn't included in the ZIP module that is made
    $dscTestsPath = Join-Path -Path $env:APPVEYOR_BUILD_FOLDER `
                              -ChildPath "Modules\SharePointDsc\DscResource.Tests"
    Move-Item -Path $dscTestsPath -Destination $env:APPVEYOR_BUILD_FOLDER
    
    # Import the module again from its new location
    $testHelperPath = Join-Path -Path $env:APPVEYOR_BUILD_FOLDER `
                                -ChildPath "DscResource.Tests\TestHelper.psm1"
    Import-Module -Name $testHelperPath -Force

    $mainModulePath = Join-Path -Path $env:APPVEYOR_BUILD_FOLDER -ChildPath "modules\SharePointDsc"

    # Write the PowerShell help files
    $docoPath = Join-Path -Path $env:APPVEYOR_BUILD_FOLDER `
                          -ChildPath "modules\SharePointDsc\en-US"
    New-Item -Path $docoPath -ItemType Directory
    $docoHelperPath = Join-Path -Path $env:APPVEYOR_BUILD_FOLDER `
                                -ChildPath "DscResources\DscResource.DocumentationHelper"
    Import-Module -Name $docoHelperPath
    Write-DscResourcePowerShellHelp -OutputPath $docoPath -ModulePath $mainModulePath -Verbose

    # Import so we can create zip files
    Add-Type -assemblyname System.IO.Compression.FileSystem

    # Generate the wiki content for the release and zip/publish it to appveyor
    $wikiContentPath = Join-Path -Path $env:APPVEYOR_BUILD_FOLDER -ChildPath "wikicontent"
    New-Item -Path $wikiContentPath -ItemType Directory
    Write-DscResourceWikiSite -OutputPath $wikiContentPath -ModulePath $mainModulePath -Verbose

    $zipFileName = "SharePointDsc_$($env:APPVEYOR_BUILD_VERSION)_wikicontent.zip"
    [System.IO.Compression.ZipFile]::CreateFromDirectory($wikiContentPath, 
                                                         "$env:APPVEYOR_BUILD_FOLDER\$zipFileName")
    Get-ChildItem -Path "$env:APPVEYOR_BUILD_FOLDER\$zipFileName" | ForEach-Object -Process { 
        Push-AppveyorArtifact $_.FullName -FileName $_.Name 
    }

    # Remove the readme files that are used to generate documentation so they aren't shipped
    $readmePaths = "$env:APPVEYOR_BUILD_FOLDER\Modules\**\readme.md"
    Get-ChildItem -Path $readmePaths -Recurse | Remove-Item -Confirm:$false

    # Add the appropriate build number to the manifest and zip/publish everything to appveyor
    $manifest = Join-Path -Path $env:APPVEYOR_BUILD_FOLDER -ChildPath "modules\SharePointDsc\SharePointDsc.psd1"
    (Get-Content $manifest -Raw).Replace("1.5.0.0", $env:APPVEYOR_BUILD_VERSION) | Out-File $manifest
    $zipFileName = "SharePointDsc_$($env:APPVEYOR_BUILD_VERSION).zip"
    [System.IO.Compression.ZipFile]::CreateFromDirectory($mainModulePath, "$env:APPVEYOR_BUILD_FOLDER\$zipFileName")
    New-DscChecksum -Path $env:APPVEYOR_BUILD_FOLDER -Outpath $env:APPVEYOR_BUILD_FOLDER
    Get-ChildItem -Path "$env:APPVEYOR_BUILD_FOLDER\$zipFileName" | ForEach-Object -Process { 
        Push-AppveyorArtifact $_.FullName -FileName $_.Name 
    }
    Get-ChildItem -Path "$env:APPVEYOR_BUILD_FOLDER\$zipFileName.checksum" | ForEach-Object -Process { 
        Push-AppveyorArtifact $_.FullName -FileName $_.Name 
    }
    
    Set-Location -Path $mainModulePath
    $nuspecParams = @{
        packageName = "SharePointDsc"
        version = $env:APPVEYOR_BUILD_VERSION
        author = "Microsoft"
        owners = "Microsoft"
        licenseUrl = "https://github.com/PowerShell/DscResources/blob/master/LICENSE"
        projectUrl = "https://github.com/$($env:APPVEYOR_REPO_NAME)"
        packageDescription = "SharePointDsc"
        tags = "DesiredStateConfiguration DSC DSCResourceKit"
        destinationPath = "."
    }
    New-Nuspec @nuspecParams

    Start-Process -FilePath "nuget" -Wait -ArgumentList @(
        "pack",
        ".\SharePointDsc.nuspec",
        "-outputdirectory $env:APPVEYOR_BUILD_FOLDER"
    )
    $nuGetPackageName = "SharePointDsc." + $env:APPVEYOR_BUILD_VERSION + ".nupkg"
    Get-ChildItem "$env:APPVEYOR_BUILD_FOLDER\$nuGetPackageName" | ForEach-Object -Process { 
        Push-AppveyorArtifact $_.FullName -FileName $_.Name 
    }
}

Export-ModuleMember -Function *
