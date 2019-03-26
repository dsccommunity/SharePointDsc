[CmdletBinding()]
param(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
            -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
        -ChildPath "..\UnitTestHelper.psm1" `
        -Resolve)

$Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
    -DscResource "SPProductUpdate"

   # Write-Host $PSScriptRoot
$Global:TestRegistryData = Import-PowerShellDataFile -Path (Join-Path -Path $PSScriptRoot `
    -ChildPath "SharePointDsc.SPProductUpdate.Tests.psd1" `
    -Resolve)

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        function Add-TestRegistryData
        {
            param(
                # Use Registry Values with an update
                [Parameter(Mandatory = $true)]
                [ValidateSet("RTM", "CU", "SP1")]
                [System.String]
                $PatchLevel
            )

            $productVersion = 2013
            if($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 16) {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Build.ToString().Length -eq 4)
                {
                    $productVersion = 2016
                }
                else
                {
                    $productVersion = 2019
                }
            }

            if ($productVersion -ne 2013 -and $PatchLevel -eq "SP1")
            {
                throw "Invalid Parameter Set. 'SP1' can only be used with SharePoint Server 2013. Server version was $productVersion"
            }

            $registryValuesToImport = @(
                "Windows Registry Editor Version 5.00"
            )
            $registryValuesToImport += $Global:TestRegistryData["$($productVersion)"]["$($PatchLevel)"].Keys | ForEach-Object -Process {
                return $Global:TestRegistryData["$($productVersion)"]["$($PatchLevel)"]["$($_)"]
            }
            $registryFileContent = $registryValuesToImport -join "`n`n"

            $testRegistryPath = Get-Item "TestRegistry:\\"

            $testDrivePath = Get-Item "TestDrive:\"

            $tempFileName = "$($productVersion)_$($PatchLevel).reg"

            $modifiedFileDestination = $(Join-Path $testDrivePath.FullName -ChildPath $tempFileName)
            $registryFileContent.Replace("[HKEY_LOCAL_MACHINE\", "[$($testRegistryPath.Name)\HKEY_LOCAL_MACHINE\") | Out-File -FilePath $modifiedFileDestination

            $null = reg import $modifiedFileDestination

            $PrepDataForTests = $true
            if($PrepDataForTests)
            {
                Get-Childitem "Registry::$($testRegistryPath)\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products" | Where-Object -FilterScript {
                    $_.PsPath -notlike "*00000000F01FEC"
                } | Remove-Item -Confirm:$false -Force -Recurse

                reg export "$($testRegistryPath)\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products" "C:\temp\$($tempFileName)"
            }
        }

        # Mocks for all contexts
        Mock -CommandName Test-Path {
            return $true
        }

        Mock -CommandName Get-Service -MockWith {
            $service = @{
                Status = "Running"
            }
            $service = $service | Add-Member -MemberType ScriptMethod `
                -Name Stop `
                -Value {
                return $null
            } -PassThru
            $service = $service | Add-Member -MemberType ScriptMethod `
                -Name Start `
                -Value {
                return $null
            } -PassThru
            $service = $service | Add-Member -MemberType ScriptMethod `
                -Name WaitForStatus `
                -Value {
                return $null
            } -PassThru
            return $service
        }

        Mock -CommandName Get-SPDSCInstalledProductVersion {
            return @{
                FileMajorPart    = $Global:SPDscHelper.CurrentStubBuildNumber.Major
                FileBuildPart    = $Global:SPDscHelper.CurrentStubBuildNumber.Build
                ProductBuildPart = $Global:SPDscHelper.CurrentStubBuildNumber.Build
            }
        }

        Mock -CommandName Set-Service {
            return $null
        }

        Mock -CommandName Start-Process {
            return @{
                ExitCode = 0
            }
        }

        Mock -CommandName Get-SPDSCRegistryKey -MockWith {
            if ($Value -eq "SetupType")
            {
                return "CLEAN_INSTALL"
            }

            if ($Value -eq "LanguagePackInstalled")
            {
                return 0
            }
        }

        Mock -CommandName Get-SPDscFarmVersionInfo -MockWith {
            return @{
                Lowest = $Global:SPDscHelper.CurrentStubBuildNumber
            }
        }

        Mock -CommandName Get-ChildItem -MockWith {
            $getChildItemCmdlet = Get-Command Get-ChildItem -CommandType Cmdlet
            return & $getChildItemCmdlet -Path "$($Path[0].Replace("Registry::HKEY_LOCAL_MACHINE", "TestRegistry:\"))"
        } -ParameterFilter {
            $Path -and $Path.Length -eq 1 -and $Path[0].Contains("HKEY_LOCAL_MACHINE")
        }


        Mock -CommandName Get-ItemProperty -MockWith {
            $getItemPropertyCmdlet = Get-Command Get-ItemProperty -CommandType Cmdlet
            return & $getItemPropertyCmdlet -Path "$($Path[0].Replace("Registry::HKEY_LOCAL_MACHINE", "TestRegistry:\"))"
        } -ParameterFilter {
            $Path -and $Path.Length -eq 1 -and $Path[0].Contains("HKEY_LOCAL_MACHINE")
        }

        # Test contexts
        Context -Name "Specified update file not found" -Fixture {
            $testParams = @{
                SetupFile        = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices = $true
                Ensure           = "Present"
            }

            Mock -CommandName Test-Path -MockWith {
                return $false
            }

            It "Should throw exception in the get method" {
                { Get-TargetResource @testParams } | Should Throw "Setup file cannot be found."
            }

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should Throw "Setup file cannot be found."
            }

            It "Should throw exception in the test method" {
                { Test-TargetResource @testParams } | Should Throw "Setup file cannot be found."
            }
        }

        Context -Name "Specified update file is blocked" -Fixture {
            $testParams = @{
                SetupFile        = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices = $true
                Ensure           = "Present"
            }

            Mock -CommandName Test-Path -MockWith {
                return $true
            }

            Mock -CommandName Get-Item -MockWith {
                return "Zone data"
            }

            It "Should throw exception in the get method" {
                { Get-TargetResource @testParams } | Should Throw "Setup file is blocked! Please use Unblock-File to unblock the file"
            }

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should Throw "Setup file is blocked! Please use Unblock-File to unblock the file"
            }

            It "Should throw exception in the test method" {
                { Test-TargetResource @testParams } | Should Throw "Setup file is blocked! Please use Unblock-File to unblock the file"
            }
        }

        Context -Name "Ensure is set to Absent" -Fixture {
            $testParams = @{
                SetupFile        = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices = $true
                Ensure           = "Absent"
            }

            It "Should throw exception in the get method" {
                { Get-TargetResource @testParams } | Should Throw "SharePoint does not support uninstalling updates."
            }

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should Throw "SharePoint does not support uninstalling updates."
            }

            It "Should throw exception in the test method" {
                { Test-TargetResource @testParams } | Should Throw "SharePoint does not support uninstalling updates."
            }
        }

        Context -Name "Update CU has lower version, update not required" -Fixture {
            $testParams = @{
                SetupFile        = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices = $true
                Ensure           = "Present"
            }

            Mock -CommandName Get-ItemProperty -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                {
                    return @{
                        VersionInfo = @{
                            FileVersion     = $Global:SPDscHelper.CurrentStubBuildNumber
                            FileDescription = "Cumulative Update"
                        }
                        Name        = "serverlpksp2013-kb2880554-fullfile-x64-en-us.exe"
                    }
                }
                else
                {
                    if ($Global:SPDscHelper.CurrentStubBuildNumber.Build.ToString().Length -eq 4)
                    {
                        return @{
                            VersionInfo = @{
                                FileVersion     = $Global:SPDscHelper.CurrentStubBuildNumber
                                FileDescription = "Cumulative Update"
                            }
                            Name        = "serverlpksp2016-kb2880554-fullfile-x64-en-us.exe"
                        }
                    }
                    else
                    {
                        return @{
                            VersionInfo = @{
                                FileVersion     = $Global:SPDscHelper.CurrentStubBuildNumber
                                FileDescription = "Cumulative Update"
                            }
                            Name        = "serverlpksp2019-kb2880554-fullfile-x64-en-us.exe"
                        }
                    }
                }
            } -ParameterFilter {
                $Path -and $Path.Length -eq 1 -and $Path[0].StartsWith("C:\")
            }

            # Mock -CommandName Get-SPDscFarmProductsInfo -MockWith {
            #     if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
            #     {
            #         return @("Microsoft SharePoint Server 2013")
            #     }
            #     else
            #     {
            #         if ($Global:SPDscHelper.CurrentStubBuildNumber.Minor.ToString().Length -le 4)
            #         {
            #             return @("Microsoft SharePoint Server 2016")
            #         }
            #         else
            #         {
            #             return @("Microsoft SharePoint Server 2019")
            #         }
            #     }
            # }

            It "Should return Ensure is Present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Present"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "Update CU has higher version, update executed successfully" -Fixture {
            $testParams = @{
                SetupFile        = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices = $true
                Ensure           = "Present"
            }

            Mock -CommandName Get-ItemProperty -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                {
                    return @{
                        VersionInfo = @{
                            FileVersion     = "15.0.8000"
                            FileDescription = "Cumulative Update"
                        }
                        Name        = "serverlpksp2013-kb2880554-fullfile-x64-en-us.exe"
                    }
                }
                else
                {
                    return @{
                        VersionInfo = @{
                            FileVersion     = "16.0.15000"
                            FileDescription = "Cumulative Update"
                        }
                        Name        = "serverlpksp2016-kb2880554-fullfile-x64-en-us.exe"
                    }
                }
            }

            Mock -CommandName Get-SPDscFarmProductsInfo -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                {
                    return @("Microsoft SharePoint Server 2013")
                }
                else
                {
                    if ($Global:SPDscHelper.CurrentStubBuildNumber.Minor.ToString().Length -le 4)
                    {
                        return @("Microsoft SharePoint Server 2016")
                    }
                    else
                    {
                        return @("Microsoft SharePoint Server 2019")
                    }
                }
            }

            It "Should return Ensure is Present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Absent"
            }

            It "Should run the Start-Process function in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Start-Process
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context -Name "Update CU has higher version, update executed, reboot required" -Fixture {
            $testParams = @{
                SetupFile        = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices = $true
                Ensure           = "Present"
            }

            Mock -CommandName Get-ItemProperty -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                {
                    return @{
                        VersionInfo = @{
                            FileVersion     = "15.0.8000"
                            FileDescription = "Cumulative Update"
                        }
                        Name        = "serverlpksp2013-kb2880554-fullfile-x64-en-us.exe"
                    }
                }
                else
                {
                    return @{
                        VersionInfo = @{
                            FileVersion     = "16.0.15000"
                            FileDescription = "Cumulative Update"
                        }
                        Name        = "serverlpksp2016-kb2880554-fullfile-x64-en-us.exe"
                    }
                }
            }

            Mock -CommandName Get-SPDscFarmProductsInfo -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                {
                    return @("Microsoft SharePoint Server 2013")
                }
                else
                {
                    if ($Global:SPDscHelper.CurrentStubBuildNumber.Minor.ToString().Length -le 4)
                    {
                        return @("Microsoft SharePoint Server 2016")
                    }
                    else
                    {
                        return @("Microsoft SharePoint Server 2019")
                    }
                }
            }

            Mock -CommandName Start-Process {
                return @{
                    ExitCode = 17022
                }
            }

            It "Should return Ensure is Present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Absent"
            }

            It "Should run the Start-Process function in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Start-Process
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context -Name "Update CU has higher version, update executed, which failed" -Fixture {
            $testParams = @{
                SetupFile        = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices = $true
                Ensure           = "Present"
            }

            Mock -CommandName Get-ItemProperty -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                {
                    return @{
                        VersionInfo = @{
                            FileVersion     = "15.0.8000"
                            FileDescription = "Cumulative Update"
                        }
                        Name        = "serverlpksp2013-kb2880554-fullfile-x64-en-us.exe"
                    }
                }
                else
                {
                    return @{
                        VersionInfo = @{
                            FileVersion     = "16.0.15000"
                            FileDescription = "Cumulative Update"
                        }
                        Name        = "serverlpksp2016-kb2880554-fullfile-x64-en-us.exe"
                    }
                }
            }

            Mock -CommandName Get-SPDscFarmProductsInfo -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                {
                    return @("Microsoft SharePoint Server 2013")
                }
                else
                {
                    if ($Global:SPDscHelper.CurrentStubBuildNumber.Minor.ToString().Length -le 4)
                    {
                        return @("Microsoft SharePoint Server 2016")
                    }
                    else
                    {
                        return @("Microsoft SharePoint Server 2019")
                    }
                }
            }

            Mock -CommandName Start-Process {
                return @{
                    ExitCode = 1
                }
            }

            It "Should return Ensure is Present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Absent"
            }

            It "Should run the Start-Process function in the set method" {
                { Set-TargetResource @testParams } | Should Throw "SharePoint update install failed, exit code was 1"
                Assert-MockCalled Start-Process
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context -Name "Update SP has lower version, update not required" -Fixture {
            $testParams = @{
                SetupFile        = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices = $true
                Ensure           = "Present"
            }

            Mock -CommandName Get-ItemProperty -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                {
                    return @{
                        VersionInfo = @{
                            FileVersion     = $Global:SPDscHelper.CurrentStubBuildNumber
                            FileDescription = "Service Pack"
                        }
                        Name        = "serverlpksp2013-kb2880554-fullfile-x64-en-us.exe"
                    }
                }
                else
                {
                    return @{
                        VersionInfo = @{
                            FileVersion     = $Global:SPDscHelper.CurrentStubBuildNumber
                            FileDescription = "Service Pack"
                        }
                        Name        = "serverlpksp2016-kb2880554-fullfile-x64-en-us.exe"
                    }
                }
            }

            Mock -CommandName Get-SPDscFarmProductsInfo -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                {
                    return @("Microsoft SharePoint Server 2013")
                }
                else
                {
                    if ($Global:SPDscHelper.CurrentStubBuildNumber.Minor.ToString().Length -le 4)
                    {
                        return @("Microsoft SharePoint Server 2016")
                    }
                    else
                    {
                        return @("Microsoft SharePoint Server 2019")
                    }
                }
            }

            It "Should return Ensure is Present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Present"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "Update SP has higher version, update executed" -Fixture {
            $testParams = @{
                SetupFile        = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices = $true
                Ensure           = "Present"
            }

            Mock -CommandName Get-ItemProperty -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                {
                    return @{
                        VersionInfo = @{
                            FileVersion     = "15.0.8000"
                            FileDescription = "Service Pack"
                        }
                        Name        = "serverlpksp2013-kb2880554-fullfile-x64-en-us.exe"
                    }
                }
                else
                {
                    return @{
                        VersionInfo = @{
                            FileVersion     = "16.0.15000"
                            FileDescription = "Service Pack"
                        }
                        Name        = "serverlpksp2016-kb2880554-fullfile-x64-en-us.exe"
                    }
                }
            }

            Mock -CommandName Get-SPDscFarmProductsInfo -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                {
                    return @("Microsoft SharePoint Server 2013")
                }
                else
                {
                    if ($Global:SPDscHelper.CurrentStubBuildNumber.Minor.ToString().Length -le 4)
                    {
                        return @("Microsoft SharePoint Server 2016")
                    }
                    else
                    {
                        return @("Microsoft SharePoint Server 2019")
                    }
                }
            }

            Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith {
                $returnval = @{}
                $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                    -Name IsPaused `
                    -Value {
                    if ($Global:SPDscSearchPaused -eq $false)
                    {
                        return 0
                    }
                    else
                    {
                        return 128
                    }
                } -PassThru -Force
                $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                    -Name Pause `
                    -Value {
                    $Global:SPDscSearchPaused = $true
                } -PassThru -Force
                $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                    -Name Resume `
                    -Value {
                    $Global:SPDscSearchPaused = $false
                } -PassThru -Force
                return $returnval
            }

            It "Should return Ensure is Present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Absent"
            }

            $Global:SPDscSearchPaused = $false
            It "Should run the Start-Process function in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Start-Process
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context -Name "Update SP for LP has lower version, update not required" -Fixture {
            $testParams = @{
                SetupFile        = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices = $true
                Ensure           = "Present"
            }

            Mock -CommandName Get-ItemProperty -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                {
                    return @{
                        VersionInfo = @{
                            FileVersion     = $Global:SPDscHelper.CurrentStubBuildNumber
                            FileDescription = "Service Pack Language Pack"
                        }
                        Name        = "serverlpksp2013-kb2880554-fullfile-x64-nl-nl.exe"
                    }
                }
                else
                {
                    return @{
                        VersionInfo = @{
                            FileVersion     = $Global:SPDscHelper.CurrentStubBuildNumber
                            FileDescription = "Service Pack Language Pack"
                        }
                        Name        = "serverlpksp2016-kb2880554-fullfile-x64-nl-nl.exe"
                    }
                }
            }

            Mock -CommandName Get-SPDscFarmProductsInfo -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                {
                    return @("Microsoft SharePoint Server 2013", "Language Pack for SharePoint and Project Server 2013  - Dutch/Nederlands")
                }
                else
                {
                    if ($Global:SPDscHelper.CurrentStubBuildNumber.Minor.ToString().Length -le 4)
                    {
                        return @("Microsoft SharePoint Server 2016", "Language Pack for SharePoint and Project Server 2016  - Dutch/Nederlands")
                    }
                    else
                    {
                        return @("Microsoft SharePoint Server 2019", "Language Pack for SharePoint and Project Server 2019  - Dutch/Nederlands")
                    }
                }
            }

            It "Should return Ensure is Present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Present"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "Update SP for LP has higher version, update required" -Fixture {
            $testParams = @{
                SetupFile        = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices = $true
                Ensure           = "Present"
            }

            Mock -CommandName Get-ItemProperty -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                {
                    return @{
                        VersionInfo = @{
                            FileVersion     = "15.0.8000"
                            FileDescription = "Service Pack Language Pack"
                        }
                        Name        = "serverlpksp2013-kb2880554-fullfile-x64-nl-nl.exe"
                    }
                }
                else
                {
                    return @{
                        VersionInfo = @{
                            FileVersion     = "16.0.15000"
                            FileDescription = "Service Pack Language Pack"
                        }
                        Name        = "serverlpksp2016-kb2880554-fullfile-x64-nl-nl.exe"
                    }
                }
            }

            Mock -CommandName Get-SPDscFarmProductsInfo -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                {
                    return @("Microsoft SharePoint Server 2013", "Language Pack for SharePoint and Project Server 2013  - Dutch/Nederlands")
                }
                else
                {
                    if ($Global:SPDscHelper.CurrentStubBuildNumber.Minor.ToString().Length -le 4)
                    {
                        return @("Microsoft SharePoint Server 2016", "Language Pack for SharePoint and Project Server 2016  - Dutch/Nederlands")
                    }
                    else
                    {
                        return @("Microsoft SharePoint Server 2019", "Language Pack for SharePoint and Project Server 2016\9  - Dutch/Nederlands")
                    }
                }
            }

            It "Should return Ensure is Present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Absent"
            }

            It "Should run the Start-Process function in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Start-Process
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context -Name "Update SP LP does not have language in the name, throws exception" -Fixture {
            $testParams = @{
                SetupFile        = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices = $true
                Ensure           = "Present"
            }

            Mock -CommandName Get-ItemProperty -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                {
                    return @{
                        VersionInfo = @{
                            FileVersion     = "15.0.8000"
                            FileDescription = "Service Pack Language Pack"
                        }
                        Name        = "serverlpksp2013-kb2880554-fullfile-x64.exe"
                    }
                }
                else
                {
                    return @{
                        VersionInfo = @{
                            FileVersion     = "16.0.15000"
                            FileDescription = "Service Pack Language Pack"
                        }
                        Name        = "serverlpksp2016-kb2880554-fullfile-x64.exe"
                    }
                }
            }

            Mock -CommandName Get-SPDscFarmProductsInfo -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                {
                    return @("Microsoft SharePoint Server 2013", "Language Pack for SharePoint and Project Server 2013  - Dutch/Nederlands")
                }
                else
                {
                    return @("Microsoft SharePoint Server 2016", "Language Pack for SharePoint and Project Server 2016  - Dutch/Nederlands")
                }
            }

            It "Should throw exception in the get method" {
                { Get-TargetResource @testParams } | Should Throw "Update does not contain the language code in the correct format."
            }
        }

        Context -Name "Update SP LP has unknown language in the name, throws exception" -Fixture {
            $testParams = @{
                SetupFile        = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices = $true
                Ensure           = "Present"
            }

            Mock -CommandName Get-ItemProperty -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                {
                    return @{
                        VersionInfo = @{
                            FileVersion     = "15.0.8000"
                            FileDescription = "Service Pack Language Pack"
                        }
                        Name        = "serverlpksp2013-kb2880554-fullfile-x64-ab-yz.exe"
                    }
                }
                else
                {
                    return @{
                        VersionInfo = @{
                            FileVersion     = "16.0.15000"
                            FileDescription = "Service Pack Language Pack"
                        }
                        Name        = "serverlpksp2016-kb2880554-fullfile-x64-ab-yz.exe"
                    }
                }
            }

            Mock -CommandName Get-SPDscFarmProductsInfo -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                {
                    return @("Microsoft SharePoint Server 2013", "Language Pack for SharePoint and Project Server 2013  - Dutch/Nederlands")
                }
                else
                {
                    return @("Microsoft SharePoint Server 2016", "Language Pack for SharePoint and Project Server 2016  - Dutch/Nederlands")
                }
            }

            It "Should throw exception in the get method" {
                { Get-TargetResource @testParams } | Should Throw "Error while converting language information:"
            }
        }

        Context -Name "Update SP LP specified language is not installed, throws exception" -Fixture {
            $testParams = @{
                SetupFile        = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices = $true
                Ensure           = "Present"
            }

            Mock -CommandName Get-ItemProperty -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                {
                    return @{
                        VersionInfo = @{
                            FileVersion     = "15.0.8000"
                            FileDescription = "Service Pack Language Pack"
                        }
                        Name        = "serverlpksp2013-kb2880554-fullfile-x64-fr-fr.exe"
                    }
                }
                else
                {
                    return @{
                        VersionInfo = @{
                            FileVersion     = "16.0.15000"
                            FileDescription = "Service Pack Language Pack"
                        }
                        Name        = "serverlpksp2016-kb2880554-fullfile-x64-fr-fr.exe"
                    }
                }
            }

            Mock -CommandName Get-SPDscFarmProductsInfo -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                {
                    return @("Microsoft SharePoint Server 2013", "Language Pack for SharePoint and Project Server 2013  - Dutch/Nederlands")
                }
                else
                {
                    return @("Microsoft SharePoint Server 2016", "Language Pack for SharePoint and Project Server 2016  - Dutch/Nederlands")
                }
            }

            It "Should throw exception in the get method" {
                { Get-TargetResource @testParams } | Should Throw "Error: Product for language fr-fr is not found."
            }
        }

        Context -Name "Upgrade pending - Skipping install" -Fixture {
            $testParams = @{
                SetupFile        = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices = $true
                Ensure           = "Present"
            }

            Mock -CommandName Get-ItemProperty -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                {
                    return @{
                        VersionInfo = @{
                            FileVersion     = "15.0.8000"
                            FileDescription = "Service Pack Language Pack"
                        }
                        Name        = "serverlpksp2013-kb2880554-fullfile-x64-fr-fr.exe"
                    }
                }
                else
                {
                    return @{
                        VersionInfo = @{
                            FileVersion     = "16.0.15000"
                            FileDescription = "Service Pack Language Pack"
                        }
                        Name        = "serverlpksp2016-kb2880554-fullfile-x64-fr-fr.exe"
                    }
                }
            }

            Mock -CommandName Get-SPDSCRegistryKey -MockWith {
                if ($Value -eq "SetupType")
                {
                    return "CLEAN_INSTALL"
                }

                if ($Value -eq "LanguagePackInstalled")
                {
                    return 1
                }
            }

            It "Should return null from  the set method" {
                Set-TargetResource @testParams | Should BeNullOrEmpty
            }
        }

        Context -Name "BinaryInstallDays outside range" -Fixture {
            $testParams = @{
                SetupFile         = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices  = $true
                BinaryInstallDays = "mon"
                Ensure            = "Present"
            }

            $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00

            Mock -CommandName Get-Date -MockWith {
                return $testDate
            }

            It "Should return null from the set method" {
                Set-TargetResource @testParams | Should BeNullOrEmpty
            }
        }

        Context -Name "BinaryInstallTime outside range" -Fixture {
            $testParams = @{
                SetupFile         = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices  = $true
                BinaryInstallDays = "sun"
                BinaryInstallTime = "3:00am to 5:00am"
                Ensure            = "Present"
            }

            $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00

            Mock -CommandName Get-Date -MockWith {
                return $testDate
            }

            It "Should return null from the set method" {
                Set-TargetResource @testParams | Should BeNullOrEmpty
            }
        }

        Context -Name "BinaryInstallTime incorrectly formatted, too many arguments" -Fixture {
            $testParams = @{
                SetupFile         = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices  = $true
                BinaryInstallDays = "sun"
                BinaryInstallTime = "error 3:00am to 5:00am"
                Ensure            = "Present"
            }

            $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00

            Mock -CommandName Get-Date -MockWith {
                return $testDate
            }

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should Throw "Time window incorrectly formatted."
            }
        }

        Context -Name "BinaryInstallTime incorrectly formatted, incorrect start time" -Fixture {
            $testParams = @{
                SetupFile         = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices  = $true
                BinaryInstallDays = "sun"
                BinaryInstallTime = "3:00xm to 5:00am"
                Ensure            = "Present"
            }

            $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00

            Mock -CommandName Get-Date -MockWith {
                return $testDate
            }

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should Throw "Error converting start time"
            }
        }

        Context -Name "BinaryInstallTime incorrectly formatted, incorrect end time" -Fixture {
            $testParams = @{
                SetupFile         = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices  = $true
                BinaryInstallDays = "sun"
                BinaryInstallTime = "3:00am to 5:00xm"
                Ensure            = "Present"
            }

            $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00

            Mock -CommandName Get-Date -MockWith {
                return $testDate
            }

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should Throw "Error converting end time"
            }
        }

        Context -Name "BinaryInstallTime start time larger than end time" -Fixture {
            $testParams = @{
                SetupFile         = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices  = $true
                BinaryInstallDays = "sun"
                BinaryInstallTime = "3:00pm to 5:00am"
                Ensure            = "Present"
            }

            $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00

            Mock -CommandName Get-Date -MockWith {
                return $testDate
            }

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should Throw "Error: Start time cannot be larger than end time"
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
