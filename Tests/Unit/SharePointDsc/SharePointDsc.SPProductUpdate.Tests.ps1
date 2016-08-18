[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPProductUpdate"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\Modules\SharePointDsc.Util\SharePointDsc.Util.psm1") -Force

Describe "SPProductUpdate - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            SetupFile            = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
            ShutdownServices     = $true
            Ensure               = "Present"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDsc")

        $versionBeingTested = (Get-Item $Global:CurrentSharePointStubModule).Directory.BaseName
        $majorBuildNumber = $versionBeingTested.Substring(0, $versionBeingTested.IndexOf("."))
        Mock Get-SPDSCAssemblyVersion { return $majorBuildNumber }
                
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
 
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        
        Context "Specified update file not found" {
            Mock Test-Path { return $false }

            It "should throw exception in the get method" {
                { Get-TargetResource @testParams } | Should Throw "Setup file cannot be found."
            }

            It "should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should Throw "Setup file cannot be found."
            }

            It "should throw exception in the test method"  {
                { Test-TargetResource @testParams } | Should Throw "Setup file cannot be found."
            }
        }

        Context "Ensure is set to Absent" {
            Mock Test-Path { return $false }

            It "should throw exception in the get method" {
                { Get-TargetResource @testParams } | Should Throw "Setup file cannot be found."
            }

            It "should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should Throw "Setup file cannot be found."
            }

            It "should throw exception in the test method"  {
                { Test-TargetResource @testParams } | Should Throw "Setup file cannot be found."
            }
        }

        Context "Update CU has lower version, update not required" {
            Mock Test-Path {
                return $true
            }
            
            Mock Get-ItemProperty {
                if ($majorBuildNumber -eq  15)
                {
                    return @{
                        VersionInfo = @{
                            FileVersion = $versionBeingTested
                            FileDescription = "Cumulative Update"
                        }
                        Name = "serverlpksp2013-kb2880554-fullfile-x64-en-us.exe"
                    } 
                }
                else 
                {
                    return @{
                        VersionInfo = @{
                            FileVersion = $versionBeingTested
                            FileDescription = "Cumulative Update"
                        }
                        Name = "serverlpksp2016-kb2880554-fullfile-x64-en-us.exe"
                    } 
                }
            }

            Mock Get-SPDSCInstalledProductVersion {
                if ($majorBuildNumber -eq  15)
                {
                    return @{
                        FileMajorPart = 15
                    }
                }
                else 
                {
                    return @{
                        FileMajorPart = 16
                    }
                }
            }

            Mock Get-SPDSCRegistryKey {
                if ($Value -eq "SetupType")
                {
                    return "CLEAN_INSTALL"
                }

                if ($Value -eq "LanguagePackInstalled")
                {
                    return 0
                }
            }
            
            Mock Get-SPDscFarmProductsInfo {
                if ($majorBuildNumber -eq  15)
                {
                    return @("Microsoft SharePoint Server 2013")
                }
                else 
                {
                    return @("Microsoft SharePoint Server 2016")
                }
            }
            
            Mock Get-SPDscFarmVersionInfo {
                return @{
                    Lowest = $versionBeingTested
                }
            }

            Mock Get-Service {
                $service = @{
                        Status = "Running"
                }
                $service = $service | Add-Member ScriptMethod Stop { 
                               return $null
                           } -PassThru 
                $service = $service | Add-Member ScriptMethod Start { 
                               return $null
                           } -PassThru 
                $service = $service | Add-Member ScriptMethod WaitForStatus { 
                               return $null
                           } -PassThru 
                return $service
            }

            Mock Set-Service {
                return $null
            }

            Mock Start-Process {
                return @{
                    ExitCode = 0
                }
            }

            It "should return Ensure is Present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Present"
            }

            It "should return true from the test method"  {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "Update CU has higher version, update executed successfully" {
            Mock Test-Path {
                return $true
            }
            
            Mock Get-ItemProperty {
                if ($majorBuildNumber -eq  15)
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

            Mock Get-SPDSCInstalledProductVersion {
                if ($majorBuildNumber -eq  15)
                {
                    return @{
                        FileMajorPart = 15
                    }
                }
                else 
                {
                    return @{
                        FileMajorPart = 16
                    }
                }
            }

            Mock Get-SPDSCRegistryKey {
                if ($Value -eq "SetupType")
                {
                    return "CLEAN_INSTALL"
                }

                if ($Value -eq "LanguagePackInstalled")
                {
                    return 0
                }
            }
            
            Mock Get-SPDscFarmProductsInfo {
                if ($majorBuildNumber -eq  15)
                {
                    return @("Microsoft SharePoint Server 2013")
                }
                else 
                {
                    return @("Microsoft SharePoint Server 2016")
                }
            }
            
            Mock Get-SPDscFarmVersionInfo {
                return @{
                    Lowest = $versionBeingTested
                }
            }

            Mock Get-Service {
                $service = @{
                        Status = "Running"
                }
                $service = $service | Add-Member ScriptMethod Stop { 
                               return $null
                           } -PassThru 
                $service = $service | Add-Member ScriptMethod Start { 
                               return $null
                           } -PassThru 
                $service = $service | Add-Member ScriptMethod WaitForStatus { 
                               return $null
                           } -PassThru 
                return $service
            }

            Mock Set-Service {
                return $null
            }

            Mock Start-Process {
                return @{
                    ExitCode = 0
                }
            }

            It "should return Ensure is Present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Absent"
            }

            It "should run the Start-Process function in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Start-Process
            }

            It "should return true from the test method"  {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context "Update CU has higher version, update executed, reboot required" {
            Mock Test-Path {
                return $true
            }
            
            Mock Get-ItemProperty {
                if ($majorBuildNumber -eq  15)
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

            Mock Get-SPDSCInstalledProductVersion {
                if ($majorBuildNumber -eq  15)
                {
                    return @{
                        FileMajorPart = 15
                    }
                }
                else 
                {
                    return @{
                        FileMajorPart = 16
                    }
                }
            }

            Mock Get-SPDSCRegistryKey {
                if ($Value -eq "SetupType")
                {
                    return "CLEAN_INSTALL"
                }

                if ($Value -eq "LanguagePackInstalled")
                {
                    return 0
                }
            }
            
            Mock Get-SPDscFarmProductsInfo {
                if ($majorBuildNumber -eq  15)
                {
                    return @("Microsoft SharePoint Server 2013")
                }
                else 
                {
                    return @("Microsoft SharePoint Server 2016")
                }
            }
            
            Mock Get-SPDscFarmVersionInfo {
                return @{
                    Lowest = $versionBeingTested
                }
            }

            Mock Get-Service {
                $service = @{
                        Status = "Running"
                }
                $service = $service | Add-Member ScriptMethod Stop { 
                               return $null
                           } -PassThru 
                $service = $service | Add-Member ScriptMethod Start { 
                               return $null
                           } -PassThru 
                $service = $service | Add-Member ScriptMethod WaitForStatus { 
                               return $null
                           } -PassThru 
                return $service
            }

            Mock Set-Service {
                return $null
            }

            Mock Start-Process {
                return @{
                    ExitCode = 17022
                }
            }

            It "should return Ensure is Present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Absent"
            }

            It "should run the Start-Process function in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Start-Process
            }

            It "should return true from the test method"  {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context "Update CU has higher version, update executed, which failed" {
            Mock Test-Path {
                return $true
            }
            
            Mock Get-ItemProperty {
                if ($majorBuildNumber -eq  15)
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

            Mock Get-SPDSCInstalledProductVersion {
                if ($majorBuildNumber -eq  15)
                {
                    return @{
                        FileMajorPart = 15
                    }
                }
                else 
                {
                    return @{
                        FileMajorPart = 16
                    }
                }
            }

            Mock Get-SPDSCRegistryKey {
                if ($Value -eq "SetupType")
                {
                    return "CLEAN_INSTALL"
                }

                if ($Value -eq "LanguagePackInstalled")
                {
                    return 0
                }
            }
            
            Mock Get-SPDscFarmProductsInfo {
                if ($majorBuildNumber -eq  15)
                {
                    return @("Microsoft SharePoint Server 2013")
                }
                else 
                {
                    return @("Microsoft SharePoint Server 2016")
                }
            }
            
            Mock Get-SPDscFarmVersionInfo {
                return @{
                    Lowest = $versionBeingTested
                }
            }

            Mock Get-Service {
                $service = @{
                        Status = "Running"
                }
                $service = $service | Add-Member ScriptMethod Stop { 
                               return $null
                           } -PassThru 
                $service = $service | Add-Member ScriptMethod Start { 
                               return $null
                           } -PassThru 
                $service = $service | Add-Member ScriptMethod WaitForStatus { 
                               return $null
                           } -PassThru 
                return $service
            }

            Mock Set-Service {
                return $null
            }

            Mock Start-Process {
                return @{
                    ExitCode = 1
                }
            }

            It "should return Ensure is Present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Absent"
            }

            It "should run the Start-Process function in the set method" {
                { Set-TargetResource @testParams } | Should Throw "SharePoint update install failed, exit code was 1"
                Assert-MockCalled Start-Process
            }

            It "should return true from the test method"  {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context "Update SP has lower version, update not required" {
            Mock Test-Path {
                return $true
            }
            
            Mock Get-ItemProperty {
                if ($majorBuildNumber -eq  15)
                {
                    return @{
                        VersionInfo = @{
                            FileVersion = $versionBeingTested
                            FileDescription = "Service Pack"
                        }
                        Name = "serverlpksp2013-kb2880554-fullfile-x64-en-us.exe"
                    }
                }
                else 
                {
                    return @{
                        VersionInfo = @{
                            FileVersion = $versionBeingTested
                            FileDescription = "Service Pack"
                        }
                        Name = "serverlpksp2016-kb2880554-fullfile-x64-en-us.exe"
                    }
                }
            }

            Mock Get-SPDSCInstalledProductVersion {
                if ($majorBuildNumber -eq  15)
                {
                    return @{
                        FileMajorPart = 15
                    }
                }
                else 
                {
                    return @{
                        FileMajorPart = 16
                    }
                }
            }

            Mock Get-SPDSCRegistryKey {
                if ($Value -eq "SetupType")
                {
                    return "CLEAN_INSTALL"
                }

                if ($Value -eq "LanguagePackInstalled")
                {
                    return 0
                }
            }
            
            Mock Get-SPDscFarmProductsInfo {
                if ($majorBuildNumber -eq  15)
                {
                    return @("Microsoft SharePoint Server 2013")
                }
                else 
                {
                    return @("Microsoft SharePoint Server 2016")
                }
            }
            
            Mock Get-SPDscFarmVersionInfo {
                return @{
                    Lowest = $versionBeingTested
                }
            }

            Mock Get-Service {
                $service = @{
                        Status = "Running"
                }
                $service = $service | Add-Member ScriptMethod Stop { 
                               return $null
                           } -PassThru 
                $service = $service | Add-Member ScriptMethod Start { 
                               return $null
                           } -PassThru 
                $service = $service | Add-Member ScriptMethod WaitForStatus { 
                               return $null
                           } -PassThru 
                return $service
            }

            Mock Set-Service {
                return $null
            }

            Mock Start-Process {
                return @{
                    ExitCode = 0
                }
            }

            It "should return Ensure is Present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Present"
            }

            It "should return true from the test method"  {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "Update SP has higher version, update executed" {
            Mock Test-Path {
                return $true
            }
            
            Mock Get-ItemProperty {
                if ($majorBuildNumber -eq  15)
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

            Mock Get-SPDSCInstalledProductVersion {
                if ($majorBuildNumber -eq  15)
                {
                    return @{
                        FileMajorPart = 15
                    }
                }
                else 
                {
                    return @{
                        FileMajorPart = 16
                    }
                }
            }

            Mock Get-SPDSCRegistryKey {
                if ($Value -eq "SetupType")
                {
                    return "CLEAN_INSTALL"
                }

                if ($Value -eq "LanguagePackInstalled")
                {
                    return 0
                }
            }
            
            Mock Get-SPDscFarmProductsInfo {
                if ($majorBuildNumber -eq  15)
                {
                    return @("Microsoft SharePoint Server 2013")
                }
                else 
                {
                    return @("Microsoft SharePoint Server 2016")
                }
            }
            
            Mock Get-SPDscFarmVersionInfo {
                return @{
                    Lowest = $versionBeingTested
                }
            }

            Mock Get-Service {
                $service = @{
                        Status = "Running"
                }
                $service = $service | Add-Member ScriptMethod Stop { 
                               return $null
                           } -PassThru 
                $service = $service | Add-Member ScriptMethod Start { 
                               return $null
                           } -PassThru 
                $service = $service | Add-Member ScriptMethod WaitForStatus { 
                               return $null
                           } -PassThru 
                return $service
            }

            Mock Set-Service {
                return $null
            }

            Mock Start-Process {
                return @{
                    ExitCode = 0
                }
            }

            It "should return Ensure is Present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Absent"
            }

            It "should run the Start-Process function in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Start-Process
            }

            It "should return true from the test method"  {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context "Update SP for LP has lower version, update not required" {
            Mock Test-Path {
                return $true
            }
            
            Mock Get-ItemProperty {
                if ($majorBuildNumber -eq  15)
                {
                    return @{
                        VersionInfo = @{
                            FileVersion = $versionBeingTested
                            FileDescription = "Service Pack Language Pack"
                        }
                        Name = "serverlpksp2013-kb2880554-fullfile-x64-nl-nl.exe"
                    } 
                }
                else 
                {
                    return @{
                        VersionInfo = @{
                            FileVersion = $versionBeingTested
                            FileDescription = "Service Pack Language Pack"
                        }
                        Name = "serverlpksp2016-kb2880554-fullfile-x64-nl-nl.exe"
                    } 
                }
            }

            Mock Get-SPDSCInstalledProductVersion {
                if ($majorBuildNumber -eq  15)
                {
                    return @{
                        FileMajorPart = 15
                    }
                }
                else 
                {
                    return @{
                        FileMajorPart = 16
                    }
                }
            }

            Mock Get-SPDSCRegistryKey {
                if ($Value -eq "SetupType")
                {
                    return "CLEAN_INSTALL"
                }

                if ($Value -eq "LanguagePackInstalled")
                {
                    return 0
                }
            }
            
            Mock Get-SPDscFarmProductsInfo {
                if ($majorBuildNumber -eq  15)
                {
                    return @("Microsoft SharePoint Server 2013", "Language Pack for SharePoint and Project Server 2013  - Dutch/Nederlands")
                }
                else 
                {
                    return @("Microsoft SharePoint Server 2016", "Language Pack for SharePoint and Project Server 2016  - Dutch/Nederlands")
                }
            }
            
            Mock Get-SPDscFarmVersionInfo {
                return @{
                    Lowest = $versionBeingTested
                }
            }

            Mock Get-Service {
                $service = @{
                        Status = "Running"
                }
                $service = $service | Add-Member ScriptMethod Stop { 
                               return $null
                           } -PassThru 
                $service = $service | Add-Member ScriptMethod Start { 
                               return $null
                           } -PassThru 
                $service = $service | Add-Member ScriptMethod WaitForStatus { 
                               return $null
                           } -PassThru 
                return $service
            }

            Mock Set-Service {
                return $null
            }

            Mock Start-Process {
                return @{
                    ExitCode = 0
                }
            }

            It "should return Ensure is Present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Present"
            }

            It "should return true from the test method"  {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "Update SP for LP has higher version, update required" {
            Mock Test-Path {
                return $true
            }
            
            Mock Get-ItemProperty {
                if ($majorBuildNumber -eq  15)
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

            Mock Get-SPDSCInstalledProductVersion {
                if ($majorBuildNumber -eq  15)
                {
                    return @{
                        FileMajorPart = 15
                    }
                }
                else 
                {
                    return @{
                        FileMajorPart = 16
                    }
                }
            }

            Mock Get-SPDSCRegistryKey {
                if ($Value -eq "SetupType")
                {
                    return "CLEAN_INSTALL"
                }

                if ($Value -eq "LanguagePackInstalled")
                {
                    return 0
                }
            }
            
            Mock Get-SPDscFarmProductsInfo {
                if ($majorBuildNumber -eq  15)
                {
                    return @("Microsoft SharePoint Server 2013", "Language Pack for SharePoint and Project Server 2013  - Dutch/Nederlands")
                }
                else 
                {
                    return @("Microsoft SharePoint Server 2016", "Language Pack for SharePoint and Project Server 2016  - Dutch/Nederlands")
                }
            }
            
            Mock Get-SPDscFarmVersionInfo {
                return @{
                    Lowest = $versionBeingTested
                }
            }

            Mock Get-Service {
                $service = @{
                        Status = "Running"
                }
                $service = $service | Add-Member ScriptMethod Stop { 
                               return $null
                           } -PassThru 
                $service = $service | Add-Member ScriptMethod Start { 
                               return $null
                           } -PassThru 
                $service = $service | Add-Member ScriptMethod WaitForStatus { 
                               return $null
                           } -PassThru 
                return $service
            }

            Mock Set-Service {
                return $null
            }

            Mock Start-Process {
                return @{
                    ExitCode = 0
                }
            }

            It "should return Ensure is Present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Absent"
            }

            It "should run the Start-Process function in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Start-Process
            }

            It "should return true from the test method"  {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context "Update SP LP does not have language in the name, throws exception" {
            Mock Test-Path {
                return $true
            }
            
            Mock Get-ItemProperty {
                if ($majorBuildNumber -eq  15)
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

            Mock Get-SPDSCInstalledProductVersion {
                if ($majorBuildNumber -eq  15)
                {
                    return @{
                        FileMajorPart = 15
                    }
                }
                else 
                {
                    return @{
                        FileMajorPart = 16
                    }
                }
            }

            Mock Get-SPDSCRegistryKey {
                if ($Value -eq "SetupType")
                {
                    return "CLEAN_INSTALL"
                }

                if ($Value -eq "LanguagePackInstalled")
                {
                    return 0
                }
            }
            
            Mock Get-SPDscFarmProductsInfo {
                if ($majorBuildNumber -eq  15)
                {
                    return @("Microsoft SharePoint Server 2013", "Language Pack for SharePoint and Project Server 2013  - Dutch/Nederlands")
                }
                else 
                {
                    return @("Microsoft SharePoint Server 2016", "Language Pack for SharePoint and Project Server 2016  - Dutch/Nederlands")
                }
            }
            
            Mock Get-SPDscFarmVersionInfo {
                return @{
                    Lowest = $versionBeingTested
                }
            }

            Mock Get-Service {
                $service = @{
                        Status = "Running"
                }
                $service = $service | Add-Member ScriptMethod Stop { 
                               return $null
                           } -PassThru 
                $service = $service | Add-Member ScriptMethod Start { 
                               return $null
                           } -PassThru 
                $service = $service | Add-Member ScriptMethod WaitForStatus { 
                               return $null
                           } -PassThru 
                return $service
            }

            Mock Set-Service {
                return $null
            }

            Mock Start-Process {
                return @{
                    ExitCode = 0
                }
            }

            It "should throw exception in the get method" {
                { Get-TargetResource @testParams } | Should Throw "Update does not contain the language code in the correct format."
            }
        }

        Context "Update SP LP has unknown language in the name, throws exception" {
            Mock Test-Path {
                return $true
            }
            
            Mock Get-ItemProperty {
                if ($majorBuildNumber -eq  15)
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

            Mock Get-SPDSCInstalledProductVersion {
                if ($majorBuildNumber -eq  15)
                {
                    return @{
                        FileMajorPart = 15
                    }
                }
                else 
                {
                    return @{
                        FileMajorPart = 16
                    }
                }
            }

            Mock Get-SPDSCRegistryKey {
                if ($Value -eq "SetupType")
                {
                    return "CLEAN_INSTALL"
                }

                if ($Value -eq "LanguagePackInstalled")
                {
                    return 0
                }
            }
            
            Mock Get-SPDscFarmProductsInfo {
                if ($majorBuildNumber -eq  15)
                {
                    return @("Microsoft SharePoint Server 2013", "Language Pack for SharePoint and Project Server 2013  - Dutch/Nederlands")
                }
                else 
                {
                    return @("Microsoft SharePoint Server 2016", "Language Pack for SharePoint and Project Server 2016  - Dutch/Nederlands")
                }
            }
            
            Mock Get-SPDscFarmVersionInfo {
                return @{
                    Lowest = $versionBeingTested
                }
            }

            Mock Get-Service {
                $service = @{
                        Status = "Running"
                }
                $service = $service | Add-Member ScriptMethod Stop { 
                               return $null
                           } -PassThru 
                $service = $service | Add-Member ScriptMethod Start { 
                               return $null
                           } -PassThru 
                $service = $service | Add-Member ScriptMethod WaitForStatus { 
                               return $null
                           } -PassThru 
                return $service
            }

            Mock Set-Service {
                return $null
            }

            Mock Start-Process {
                return @{
                    ExitCode = 0
                }
            }

            It "should throw exception in the get method" {
                { Get-TargetResource @testParams } | Should Throw "Error while converting language information:"
            }
        }

        Context "Update SP LP specified language is not installed, throws exception" {
            Mock Test-Path {
                return $true
            }
            
            Mock Get-ItemProperty {
                if ($majorBuildNumber -eq  15)
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

            Mock Get-SPDSCInstalledProductVersion {
                if ($majorBuildNumber -eq  15)
                {
                    return @{
                        FileMajorPart = 15
                    }
                }
                else 
                {
                    return @{
                        FileMajorPart = 16
                    }
                }
            }

            Mock Get-SPDSCRegistryKey {
                if ($Value -eq "SetupType")
                {
                    return "CLEAN_INSTALL"
                }

                if ($Value -eq "LanguagePackInstalled")
                {
                    return 0
                }
            }
            
            Mock Get-SPDscFarmProductsInfo {
                if ($majorBuildNumber -eq  15)
                {
                    return @("Microsoft SharePoint Server 2013", "Language Pack for SharePoint and Project Server 2013  - Dutch/Nederlands")
                }
                else 
                {
                    return @("Microsoft SharePoint Server 2016", "Language Pack for SharePoint and Project Server 2016  - Dutch/Nederlands")
                }
            }
            
            Mock Get-SPDscFarmVersionInfo {
                return @{
                    Lowest = $versionBeingTested
                }
            }

            Mock Get-Service {
                $service = @{
                        Status = "Running"
                }
                $service = $service | Add-Member ScriptMethod Stop { 
                               return $null
                           } -PassThru 
                $service = $service | Add-Member ScriptMethod Start { 
                               return $null
                           } -PassThru 
                $service = $service | Add-Member ScriptMethod WaitForStatus { 
                               return $null
                           } -PassThru 
                return $service
            }

            Mock Set-Service {
                return $null
            }

            Mock Start-Process {
                return @{
                    ExitCode = 0
                }
            }

            It "should throw exception in the get method" {
                { Get-TargetResource @testParams } | Should Throw "Error: Product for language fr-fr is not found."
            }
        }

        Context "Upgrade pending - Skipping install" {
            Mock Test-Path {
                return $true
            }
            
            Mock Get-ItemProperty {
                if ($majorBuildNumber -eq  15)
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

            Mock Get-SPDSCInstalledProductVersion {
                if ($majorBuildNumber -eq  15)
                {
                    return @{
                        FileMajorPart = 15
                    }
                }
                else 
                {
                    return @{
                        FileMajorPart = 16
                    }
                }
            }

            Mock Get-SPDSCRegistryKey {
                if ($Value -eq "SetupType")
                {
                    return "CLEAN_INSTALL"
                }

                if ($Value -eq "LanguagePackInstalled")
                {
                    return 1
                }
            }

            It "should return null from  the set method" {
                Set-TargetResource @testParams | Should BeNullOrEmpty
            }
        }

        Context "BinaryInstallDays outside range" {
            $testParams = @{
                SetupFile            = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices     = $true
                BinaryInstallDays    = "mon"
                Ensure               = "Present"
            }

            Mock Test-Path {
                return $true
            }

            $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00

            Mock Get-Date {
                 return $testDate
            }
            
            It "should return null from the set method" {
                Set-TargetResource @testParams | Should BeNullOrEmpty
            }
        }

        Context "BinaryInstallTime outside range" {
            $testParams = @{
                SetupFile            = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices     = $true
                BinaryInstallDays    = "sun"
                BinaryInstallTime    = "3:00am to 5:00am"
                Ensure               = "Present"
            }

            Mock Test-Path {
                return $true
            }

            $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00

            Mock Get-Date {
                 return $testDate
            }
            
            It "should return null from the set method" {
                Set-TargetResource @testParams | Should BeNullOrEmpty
            }
        }

        Context "BinaryInstallTime incorrectly formatted, too many arguments" {
            $testParams = @{
                SetupFile            = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices     = $true
                BinaryInstallDays    = "sun"
                BinaryInstallTime    = "error 3:00am to 5:00am"
                Ensure               = "Present"
            }

            Mock Test-Path {
                return $true
            }

            $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00

            Mock Get-Date {
                 return $testDate
            }
            
            It "should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should Throw "Time window incorrectly formatted."
            }
        }

        Context "BinaryInstallTime incorrectly formatted, incorrect start time" {
            $testParams = @{
                SetupFile            = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices     = $true
                BinaryInstallDays    = "sun"
                BinaryInstallTime    = "3:00xm to 5:00am"
                Ensure               = "Present"
            }

            Mock Test-Path {
                return $true
            }

            $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00

            Mock Get-Date {
                 return $testDate
            }
            
            It "should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should Throw "Error converting start time"
            }
        }

        Context "BinaryInstallTime incorrectly formatted, incorrect end time" {
            $testParams = @{
                SetupFile            = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices     = $true
                BinaryInstallDays    = "sun"
                BinaryInstallTime    = "3:00am to 5:00xm"
                Ensure               = "Present"
            }

            Mock Test-Path {
                return $true
            }

            $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00

            Mock Get-Date {
                 return $testDate
            }
            
            It "should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should Throw "Error converting end time"
            }
        }

        Context "BinaryInstallTime start time larger than end time" {
            $testParams = @{
                SetupFile            = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                ShutdownServices     = $true
                BinaryInstallDays    = "sun"
                BinaryInstallTime    = "3:00pm to 5:00am"
                Ensure               = "Present"
            }

            Mock Test-Path {
                return $true
            }

            $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00

            Mock Get-Date {
                 return $testDate
            }
            
            It "should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should Throw "Error: Start time cannot be larger than end time"
            }
        }
    }    
}
