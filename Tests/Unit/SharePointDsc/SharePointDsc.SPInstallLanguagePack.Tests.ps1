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
                                              -DscResource "SPInstallLanguagePack"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests

        # Mocks for all contexts   
        Mock -CommandName Test-Path -MockWith {
            return $true
        }

        Mock -CommandName Get-ChildItem -MockWith {
            return @{
                Name = "C:\SPInstall\osmui.nl-nl"
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

        Mock -CommandName Start-Process -MockWith {
            return @{
                ExitCode = 0
            }
        }

        # Test contexts
        Context -Name "Specified update file not found" -Fixture {
            $testParams = @{
                BinaryDir = "C:\SPInstall"
                Ensure    = "Present"
            }

            Mock -CommandName Test-Path { 
                return $false 
            }

            It "Should throw exception in the get method" {
                { Get-TargetResource @testParams } | Should Throw "Specified path cannot be found"
            }

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should Throw "Specified path cannot be found"
            }

            It "Should throw exception in the test method"  {
                { Test-TargetResource @testParams } | Should Throw "Specified path cannot be found"
            }
        }

        Context -Name "Language Pack is installed, installation not required" -Fixture {
            $testParams = @{
                BinaryDir = "C:\SPInstall"
                Ensure    = "Present"
            }

            Mock -CommandName Test-Path -MockWith {
                return $true
            }

            Mock -CommandName Get-ChildItem -MockWith {
                return @{
                    Name = "C:\SPInstall\osmui.nl-nl"
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
            
            Mock -CommandName Get-SPDscRegProductsInfo -MockWith {
                switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major)
                {
                    15 {
                        return @("Microsoft SharePoint Server 2013", "Language Pack for SharePoint and Project Server 2013  - Dutch/Nederlands")
                    }
                    16 {
                        return @("Microsoft SharePoint Server 2016", "Language Pack for SharePoint and Project Server 2016  - Dutch/Nederlands")
                    }
                    Default {
                        throw [Exception] "A supported version of SharePoint was not used in testing"
                    }
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

        Context -Name "Language Pack is not installed, installation executed successfully" -Fixture {
            $testParams = @{
                BinaryDir = "C:\SPInstall"
                Ensure    = "Present"
            }
            
            Mock -CommandName Get-SPDscFarmProductsInfo -MockWith {
                switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major)
                {
                    15 {
                        return @("Microsoft SharePoint Server 2013")
                    }
                    16 {
                        return @("Microsoft SharePoint Server 2016")
                    }
                    Default {
                        throw [Exception] "A supported version of SharePoint was not used in testing"
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
                    return 0
                }
            }
            
            Mock -CommandName Get-SPDscRegProductsInfo -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq  15)
                {
                    return @("Microsoft SharePoint Server 2013")
                }
                else 
                {
                    return @("Microsoft SharePoint Server 2016")
                }
            }
            
            Mock -CommandName Start-Process -MockWith {
                return @{
                    ExitCode = 0
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

        Context -Name "Language Pack is not installed, installation executed, reboot required" -Fixture {
            $testParams = @{
                BinaryDir = "C:\SPInstall"
                Ensure    = "Present"
            }
            
            Mock -CommandName Get-SPDscFarmProductsInfo -MockWith {
                switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major)
                {
                    15 {
                        return @("Microsoft SharePoint Server 2013")
                    }
                    16 {
                        return @("Microsoft SharePoint Server 2016")
                    }
                    Default {
                        throw [Exception] "A supported version of SharePoint was not used in testing"
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
                    return 0
                }
            }
            
            Mock -CommandName Get-SPDscRegProductsInfo -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq  15)
                {
                    return @("Microsoft SharePoint Server 2013")
                }
                else 
                {
                    return @("Microsoft SharePoint Server 2016")
                }
            }
            
            Mock -CommandName Start-Process -MockWith {
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

        Context -Name "Language Pack is not installed, installation executed, which failed" -Fixture {
            $testParams = @{
                BinaryDir = "C:\SPInstall"
                Ensure    = "Present"
            }

            Mock -CommandName Get-SPDscFarmProductsInfo -MockWith {
                switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major)
                {
                    15 {
                        return @("Microsoft SharePoint Server 2013")
                    }
                    16 {
                        return @("Microsoft SharePoint Server 2016")
                    }
                    Default {
                        throw [Exception] "A supported version of SharePoint was not used in testing"
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
                    return 0
                }
            }
            
            Mock -CommandName Get-SPDscRegProductsInfo -MockWith {
                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq  15)
                {
                    return @("Microsoft SharePoint Server 2013")
                }
                else 
                {
                    return @("Microsoft SharePoint Server 2016")
                }
            }

            Mock -CommandName Start-Process -MockWith {
                return @{
                    ExitCode = 1
                }
            }

            It "Should return Ensure is Present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Absent"
            }

            It "Should run the Start-Process function in the set method" {
                { Set-TargetResource @testParams } | Should Throw "SharePoint Language Pack install failed, exit code was 1"
                Assert-MockCalled Start-Process
            }

            It "Should return true from the test method"  {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context -Name "Language Pack does not have language in the name, throws exception" -Fixture {
            $testParams = @{
                BinaryDir = "C:\SPInstall"
                Ensure    = "Present"
            }

            Mock -CommandName Get-ChildItem {
                return @{
                    Name = "C:\SPInstall\osmui"
                }
            }
            
            Mock -CommandName Get-SPDscFarmProductsInfo {
                switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major)
                {
                    15 {
                        return @("Microsoft SharePoint Server 2013", "Language Pack for SharePoint and Project Server 2013  - Dutch/Nederlands")
                    }
                    16 {
                        return @("Microsoft SharePoint Server 2016", "Language Pack for SharePoint and Project Server 2016  - Dutch/Nederlands")
                    }
                    Default {
                        throw [Exception] "A supported version of SharePoint was not used in testing"
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
                    return 0
                }
            }
            
            Mock -CommandName Get-SPDscRegProductsInfo -MockWith {
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

        Context -Name "Language Pack has unknown language in the name, throws exception" -Fixture {
            $testParams = @{
                BinaryDir = "C:\SPInstall"
                Ensure    = "Present"
            }

            Mock -CommandName Get-ChildItem -MockWith {
                return @{
                    Name = "C:\SPInstall\osmui.xx-xx"
                }
            }
            
            Mock -CommandName Get-SPDscFarmProductsInfo -MockWith {
                switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major)
                {
                    15 {
                        return @("Microsoft SharePoint Server 2013", "Language Pack for SharePoint and Project Server 2013  - Dutch/Nederlands")
                    }
                    16 {
                        return @("Microsoft SharePoint Server 2016", "Language Pack for SharePoint and Project Server 2016  - Dutch/Nederlands")
                    }
                    Default {
                        throw [Exception] "A supported version of SharePoint was not used in testing"
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
                    return 0
                }
            }
            
            Mock -CommandName Get-SPDscRegProductsInfo -MockWith {
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

        Context -Name "Upgrade pending - Skipping install" -Fixture {
            $testParams = @{
                BinaryDir = "C:\SPInstall"
                Ensure    = "Present"
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
                BinaryDir            = "C:\SPInstall"
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
                BinaryDir            = "C:\SPInstall"
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
                BinaryDir            = "C:\SPInstall"
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
                BinaryDir            = "C:\SPInstall"
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
                BinaryDir            = "C:\SPInstall"
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
                BinaryDir            = "C:\SPInstall"
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

        Context -Name "Ensure is set to Absent" -Fixture {
            $testParams = @{
                BinaryDir            = "C:\SPInstall"
                Ensure               = "Absent"
            }

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should Throw "SharePointDsc does not support uninstalling SharePoint Language Packs. Please remove this manually."
            }

            It "Should throw exception in the test method"  {
                { Test-TargetResource @testParams } | Should Throw "SharePointDsc does not support uninstalling SharePoint Language Packs. Please remove this manually."
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
