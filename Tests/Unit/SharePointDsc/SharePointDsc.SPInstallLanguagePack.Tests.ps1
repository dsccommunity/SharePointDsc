[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPInstallLanguagePack"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\Modules\SharePointDsc.Util\SharePointDsc.Util.psm1") -Force

Describe "SPInstallLanguagePack - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            BinaryDir = "C:\SPInstall"
            Ensure    = "Present"
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
                { Get-TargetResource @testParams } | Should Throw "Specified path cannot be found"
            }

            It "should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should Throw "Specified path cannot be found"
            }

            It "should throw exception in the test method"  {
                { Test-TargetResource @testParams } | Should Throw "Specified path cannot be found"
            }
        }

        Context "Language Pack is installed, installation not required" {
            Mock Test-Path {
                return $true
            }
            
            Mock Get-ChildItem {
                return @{
                    Name = "C:\SPInstall\osrv.nl-nl"
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

            It "should return Ensure is Present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Present"
            }

            It "should return true from the test method"  {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "Language Pack is not installed, installation executed successfully" {
            Mock Test-Path {
                return $true
            }
            
            Mock Get-ChildItem {
                return @{
                    Name = "C:\SPInstall\osrv.nl-nl"
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

        Context "Language Pack is not installed, installation executed, reboot required" {
            Mock Test-Path {
                return $true
            }
            
            Mock Get-ChildItem {
                return @{
                    Name = "C:\SPInstall\osrv.nl-nl"
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

        Context "Language Pack is not installed, installation executed, which failed" {
            Mock Test-Path {
                return $true
            }
            
            Mock Get-ChildItem {
                return @{
                    Name = "C:\SPInstall\osrv.nl-nl"
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
                { Set-TargetResource @testParams } | Should Throw "SharePoint Language Pack install failed, exit code was 1"
                Assert-MockCalled Start-Process
            }

            It "should return true from the test method"  {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context "Language Pack does not have language in the name, throws exception" {
            Mock Test-Path {
                return $true
            }
            
            Mock Get-ChildItem {
                return @{
                    Name = "C:\SPInstall\osrv"
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

            It "should throw exception in the get method" {
                { Get-TargetResource @testParams } | Should Throw "Update does not contain the language code in the correct format."
            }
        }

        Context "Language Pack has unknown language in the name, throws exception" {
            Mock Test-Path {
                return $true
            }
            
            Mock Get-ChildItem {
                return @{
                    Name = "C:\SPInstall\osrv.ab-cd"
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
            
            It "should throw exception in the get method" {
                { Get-TargetResource @testParams } | Should Throw "Error while converting language information:"
            }
        }

        Context "Upgrade pending - Skipping install" {
            Mock Test-Path {
                return $true
            }
            
            Mock Get-ChildItem {
                return @{
                    Name = "C:\SPInstall\osrv.nl-nl"
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
                BinaryDir            = "C:\SPInstall"
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
                BinaryDir            = "C:\SPInstall"
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
                BinaryDir            = "C:\SPInstall"
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
                BinaryDir            = "C:\SPInstall"
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
                BinaryDir            = "C:\SPInstall"
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
                BinaryDir            = "C:\SPInstall"
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

        Context "Ensure is set to Absent" {
            $testParams = @{
                BinaryDir            = "C:\SPInstall"
                Ensure               = "Absent"
            }
            Mock Test-Path { return $true }

            It "should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should Throw "SharePointDsc does not support uninstalling SharePoint Language Packs. Please remove this manually."
            }

            It "should throw exception in the test method"  {
                { Test-TargetResource @testParams } | Should Throw "SharePointDsc does not support uninstalling SharePoint Language Packs. Please remove this manually."
            }
        }
    }    
}
