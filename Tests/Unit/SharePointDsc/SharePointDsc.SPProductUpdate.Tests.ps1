[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string] 
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
                                         -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
                                         -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
                                -ChildPath "..\SharePointDsc.TestHarness.psm1" `
                                -Resolve)

$Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
                                              -DscResource "SPProductUpdate"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

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

        # Test contexts        
        Context -Name "Specified update file not found" -Fixture {
            $testParams = @{
                SetupFile            = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices     = $true
                Ensure               = "Present"
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

            It "Should throw exception in the test method"  {
                { Test-TargetResource @testParams } | Should Throw "Setup file cannot be found."
            }
        }

        Context -Name "Ensure is set to Absent" -Fixture {
            $testParams = @{
                SetupFile            = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices     = $true
                Ensure               = "Absent"
            }

            It "Should throw exception in the get method" {
                { Get-TargetResource @testParams } | Should Throw "SharePoint does not support uninstalling updates."
            }

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should Throw "SharePoint does not support uninstalling updates."
            }

            It "Should throw exception in the test method"  {
                { Test-TargetResource @testParams } | Should Throw "SharePoint does not support uninstalling updates."
            }
        }

        Context -Name "Update CU has lower version, update not required" -Fixture {
            $testParams = @{
                SetupFile            = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices     = $true
                Ensure               = "Present"
            }
            
            Mock -CommandName Get-ItemProperty -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq  15)
                {
                    return @{
                        VersionInfo = @{
                            FileVersion = $Global:SPDscHelper.CurrentStubBuildNumber
                            FileDescription = "Cumulative Update"
                        }
                        Name = "serverlpksp2013-kb2880554-fullfile-x64-en-us.exe"
                    } 
                }
                else 
                {
                    return @{
                        VersionInfo = @{
                            FileVersion = $Global:SPDscHelper.CurrentStubBuildNumber
                            FileDescription = "Cumulative Update"
                        }
                        Name = "serverlpksp2016-kb2880554-fullfile-x64-en-us.exe"
                    } 
                }
            }
            
            Mock -CommandName Get-SPDscFarmProductsInfo -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq  15)
                {
                    return @("Microsoft SharePoint Server 2013")
                }
                else 
                {
                    return @("Microsoft SharePoint Server 2016")
                }
            }

            It "Should return Ensure is Present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Present"
            }

            It "Should return true from the test method"  {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "Update CU has higher version, update executed successfully" -Fixture {
            $testParams = @{
                SetupFile            = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices     = $true
                Ensure               = "Present"
            }

            Mock -CommandName Get-ItemProperty -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq  15)
                {
                    return @{
                        VersionInfo = @{
                            FileVersion = "15.0.8000"
                            FileDescription = "Cumulative Update"
                        }
                        Name = "serverlpksp2013-kb2880554-fullfile-x64-en-us.exe"
                    } 
                }
                else 
                {
                    return @{
                        VersionInfo = @{
                            FileVersion = "16.0.8000"
                            FileDescription = "Cumulative Update"
                        }
                        Name = "serverlpksp2016-kb2880554-fullfile-x64-en-us.exe"
                    } 
                }
            }
            
            Mock -CommandName Get-SPDscFarmProductsInfo -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq  15)
                {
                    return @("Microsoft SharePoint Server 2013")
                }
                else 
                {
                    return @("Microsoft SharePoint Server 2016")
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

            It "Should return true from the test method"  {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context -Name "Update CU has higher version, update executed, reboot required" -Fixture {
            $testParams = @{
                SetupFile            = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices     = $true
                Ensure               = "Present"
            }
            
            Mock -CommandName Get-ItemProperty -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq  15)
                {
                    return @{
                        VersionInfo = @{
                            FileVersion = "15.0.8000"
                            FileDescription = "Cumulative Update"
                        }
                        Name = "serverlpksp2013-kb2880554-fullfile-x64-en-us.exe"
                    } 
                }
                else 
                {
                    return @{
                        VersionInfo = @{
                            FileVersion = "16.0.8000"
                            FileDescription = "Cumulative Update"
                        }
                        Name = "serverlpksp2016-kb2880554-fullfile-x64-en-us.exe"
                    } 
                }
            }
            
            Mock -CommandName Get-SPDscFarmProductsInfo -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq  15)
                {
                    return @("Microsoft SharePoint Server 2013")
                }
                else 
                {
                    return @("Microsoft SharePoint Server 2016")
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

            It "Should return true from the test method"  {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context -Name "Update CU has higher version, update executed, which failed" -Fixture {
            $testParams = @{
                SetupFile            = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices     = $true
                Ensure               = "Present"
            }
            
            Mock -CommandName Get-ItemProperty -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq  15)
                {
                    return @{
                        VersionInfo = @{
                            FileVersion = "15.0.8000"
                            FileDescription = "Cumulative Update"
                        }
                        Name = "serverlpksp2013-kb2880554-fullfile-x64-en-us.exe"
                    } 
                }
                else 
                {
                    return @{
                        VersionInfo = @{
                            FileVersion = "16.0.8000"
                            FileDescription = "Cumulative Update"
                        }
                        Name = "serverlpksp2016-kb2880554-fullfile-x64-en-us.exe"
                    } 
                }
            }

            Mock -CommandName Get-SPDscFarmProductsInfo -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq  15)
                {
                    return @("Microsoft SharePoint Server 2013")
                }
                else 
                {
                    return @("Microsoft SharePoint Server 2016")
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

            It "Should return true from the test method"  {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context -Name "Update SP has lower version, update not required" -Fixture {
            $testParams = @{
                SetupFile            = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices     = $true
                Ensure               = "Present"
            }
            
            Mock -CommandName Get-ItemProperty -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq  15)
                {
                    return @{
                        VersionInfo = @{
                            FileVersion = $Global:SPDscHelper.CurrentStubBuildNumber
                            FileDescription = "Service Pack"
                        }
                        Name = "serverlpksp2013-kb2880554-fullfile-x64-en-us.exe"
                    }
                }
                else 
                {
                    return @{
                        VersionInfo = @{
                            FileVersion = $Global:SPDscHelper.CurrentStubBuildNumber
                            FileDescription = "Service Pack"
                        }
                        Name = "serverlpksp2016-kb2880554-fullfile-x64-en-us.exe"
                    }
                }
            }

            Mock -CommandName Get-SPDscFarmProductsInfo -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq  15)
                {
                    return @("Microsoft SharePoint Server 2013")
                }
                else 
                {
                    return @("Microsoft SharePoint Server 2016")
                }
            }

            It "Should return Ensure is Present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Present"
            }

            It "Should return true from the test method"  {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "Update SP has higher version, update executed" -Fixture {
            $testParams = @{
                SetupFile            = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices     = $true
                Ensure               = "Present"
            }
            
            Mock -CommandName Get-ItemProperty -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq  15)
                {
                    return @{
                        VersionInfo = @{
                            FileVersion = "15.0.8000"
                            FileDescription = "Service Pack"
                        }
                        Name = "serverlpksp2013-kb2880554-fullfile-x64-en-us.exe"
                    } 
                }
                else 
                {
                    return @{
                        VersionInfo = @{
                            FileVersion = "16.0.8000"
                            FileDescription = "Service Pack"
                        }
                        Name = "serverlpksp2016-kb2880554-fullfile-x64-en-us.exe"
                    } 
                }
            }

            Mock -CommandName Get-SPDscFarmProductsInfo -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq  15)
                {
                    return @("Microsoft SharePoint Server 2013")
                }
                else 
                {
                    return @("Microsoft SharePoint Server 2016")
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

            It "Should return true from the test method"  {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context -Name "Update SP for LP has lower version, update not required" -Fixture {
            $testParams = @{
                SetupFile            = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices     = $true
                Ensure               = "Present"
            }
            
            Mock -CommandName Get-ItemProperty -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq  15)
                {
                    return @{
                        VersionInfo = @{
                            FileVersion = $Global:SPDscHelper.CurrentStubBuildNumber
                            FileDescription = "Service Pack Language Pack"
                        }
                        Name = "serverlpksp2013-kb2880554-fullfile-x64-nl-nl.exe"
                    } 
                }
                else 
                {
                    return @{
                        VersionInfo = @{
                            FileVersion = $Global:SPDscHelper.CurrentStubBuildNumber
                            FileDescription = "Service Pack Language Pack"
                        }
                        Name = "serverlpksp2016-kb2880554-fullfile-x64-nl-nl.exe"
                    } 
                }
            }

            Mock -CommandName Get-SPDscFarmProductsInfo -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq  15)
                {
                    return @("Microsoft SharePoint Server 2013", "Language Pack for SharePoint and Project Server 2013  - Dutch/Nederlands")
                }
                else 
                {
                    return @("Microsoft SharePoint Server 2016", "Language Pack for SharePoint and Project Server 2016  - Dutch/Nederlands")
                }
            }

            It "Should return Ensure is Present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Present"
            }

            It "Should return true from the test method"  {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "Update SP for LP has higher version, update required" -Fixture {
            $testParams = @{
                SetupFile            = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices     = $true
                Ensure               = "Present"
            }

            Mock -CommandName Get-ItemProperty -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq  15)
                {
                    return @{
                        VersionInfo = @{
                            FileVersion = "15.0.8000"
                            FileDescription = "Service Pack Language Pack"
                        }
                        Name = "serverlpksp2013-kb2880554-fullfile-x64-nl-nl.exe"
                    } 
                }
                else 
                {
                    return @{
                        VersionInfo = @{
                            FileVersion = "16.0.8000"
                            FileDescription = "Service Pack Language Pack"
                        }
                        Name = "serverlpksp2016-kb2880554-fullfile-x64-nl-nl.exe"
                    } 
                }
            }

            Mock -CommandName Get-SPDscFarmProductsInfo -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq  15)
                {
                    return @("Microsoft SharePoint Server 2013", "Language Pack for SharePoint and Project Server 2013  - Dutch/Nederlands")
                }
                else 
                {
                    return @("Microsoft SharePoint Server 2016", "Language Pack for SharePoint and Project Server 2016  - Dutch/Nederlands")
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

            It "Should return true from the test method"  {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context -Name "Update SP LP does not have language in the name, throws exception" -Fixture {
            $testParams = @{
                SetupFile            = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices     = $true
                Ensure               = "Present"
            }
            
            Mock -CommandName Get-ItemProperty -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq  15)
                {
                    return @{
                        VersionInfo = @{
                            FileVersion = "15.0.8000"
                            FileDescription = "Service Pack Language Pack"
                        }
                        Name = "serverlpksp2013-kb2880554-fullfile-x64.exe"
                    } 
                }
                else 
                {
                    return @{
                        VersionInfo = @{
                            FileVersion = "16.0.8000"
                            FileDescription = "Service Pack Language Pack"
                        }
                        Name = "serverlpksp2016-kb2880554-fullfile-x64.exe"
                    }
                }
            }

            Mock -CommandName Get-SPDscFarmProductsInfo -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq  15)
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
                SetupFile            = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices     = $true
                Ensure               = "Present"
            }
            
            Mock -CommandName Get-ItemProperty -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq  15)
                {
                    return @{
                        VersionInfo = @{
                            FileVersion = "15.0.8000"
                            FileDescription = "Service Pack Language Pack"
                        }
                        Name = "serverlpksp2013-kb2880554-fullfile-x64-ab-yz.exe"
                    } 
                }
                else 
                {
                    return @{
                        VersionInfo = @{
                            FileVersion = "16.0.8000"
                            FileDescription = "Service Pack Language Pack"
                        }
                        Name = "serverlpksp2016-kb2880554-fullfile-x64-ab-yz.exe"
                    } 
                }
            }

            Mock -CommandName Get-SPDscFarmProductsInfo -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq  15)
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
                SetupFile            = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices     = $true
                Ensure               = "Present"
            }
            
            Mock -CommandName Get-ItemProperty -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq  15)
                {
                    return @{
                        VersionInfo = @{
                            FileVersion = "15.0.8000"
                            FileDescription = "Service Pack Language Pack"
                        }
                        Name = "serverlpksp2013-kb2880554-fullfile-x64-fr-fr.exe"
                    } 
                }
                else 
                {
                    return @{
                        VersionInfo = @{
                            FileVersion = "16.0.8000"
                            FileDescription = "Service Pack Language Pack"
                        }
                        Name = "serverlpksp2016-kb2880554-fullfile-x64-fr-fr.exe"
                    } 
                }
            }

            Mock -CommandName Get-SPDscFarmProductsInfo -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq  15)
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
                SetupFile            = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices     = $true
                Ensure               = "Present"
            }
            
            Mock -CommandName Get-ItemProperty -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq  15)
                {
                    return @{
                        VersionInfo = @{
                            FileVersion = "15.0.8000"
                            FileDescription = "Service Pack Language Pack"
                        }
                        Name = "serverlpksp2013-kb2880554-fullfile-x64-fr-fr.exe"
                    } 
                }
                else 
                {
                    return @{
                        VersionInfo = @{
                            FileVersion = "16.0.8000"
                            FileDescription = "Service Pack Language Pack"
                        }
                        Name = "serverlpksp2016-kb2880554-fullfile-x64-fr-fr.exe"
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
                SetupFile            = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices     = $true
                BinaryInstallDays    = "mon"
                Ensure               = "Present"
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
                SetupFile            = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices     = $true
                BinaryInstallDays    = "sun"
                BinaryInstallTime    = "3:00am to 5:00am"
                Ensure               = "Present"
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
                SetupFile            = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices     = $true
                BinaryInstallDays    = "sun"
                BinaryInstallTime    = "error 3:00am to 5:00am"
                Ensure               = "Present"
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
                SetupFile            = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices     = $true
                BinaryInstallDays    = "sun"
                BinaryInstallTime    = "3:00xm to 5:00am"
                Ensure               = "Present"
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
                SetupFile            = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices     = $true
                BinaryInstallDays    = "sun"
                BinaryInstallTime    = "3:00am to 5:00xm"
                Ensure               = "Present"
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
                SetupFile            = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices     = $true
                BinaryInstallDays    = "sun"
                BinaryInstallTime    = "3:00pm to 5:00am"
                Ensure               = "Present"
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
