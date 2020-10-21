[CmdletBinding()]
param(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
            -Resolve)
)

$script:DSCModuleName = 'SharePointDsc'
$script:DSCResourceName = 'SPInstallLanguagePack'
$script:DSCResourceFullName = 'MSFT_' + $script:DSCResourceName

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force

        Import-Module -Name (Join-Path -Path $PSScriptRoot `
                -ChildPath "..\UnitTestHelper.psm1" `
                -Resolve)

        $Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
            -DscResource $script:DSCResourceName
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:DSCModuleName `
        -DSCResourceName $script:DSCResourceFullName `
        -ResourceType 'Mof' `
        -TestType 'Unit'
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    InModuleScope -ModuleName $script:DSCResourceFullName -ScriptBlock {
        Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
            BeforeAll {
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

                Mock -CommandName Start-Process -MockWith {
                    return @{
                        ExitCode = 0
                    }
                }

                Mock -CommandName Get-SPDscInstalledProductVersion {
                    return @{
                        FileMajorPart    = $Global:SPDscHelper.CurrentStubBuildNumber.Major
                        FileBuildPart    = $Global:SPDscHelper.CurrentStubBuildNumber.Build
                        ProductBuildPart = $Global:SPDscHelper.CurrentStubBuildNumber.Build
                    }
                }

                Mock -CommandName Test-Path -MockWith {
                    return $true
                } -ParameterFilter { $Path -eq $testParams.BinaryDir }

                Mock -CommandName Test-Path -MockWith {
                    return $true
                } -ParameterFilter { $Path -eq (Join-Path -Path $testParams.BinaryDir -ChildPath "setup.exe") }

                function Add-SPDscEvent
                {
                    param (
                        [Parameter(Mandatory = $true)]
                        [System.String]
                        $Message,

                        [Parameter(Mandatory = $true)]
                        [System.String]
                        $Source,

                        [Parameter()]
                        [ValidateSet('Error', 'Information', 'FailureAudit', 'SuccessAudit', 'Warning')]
                        [System.String]
                        $EntryType,

                        [Parameter()]
                        [System.UInt32]
                        $EventID
                    )
                }
            }

            # Test contexts
            Context -Name "Specified BinaryDir not found" -Fixture {
                BeforeAll {
                    $testParams = @{
                        BinaryDir = "C:\SPInstall"
                        Ensure    = "Present"
                    }

                    Mock -CommandName Test-Path -MockWith {
                        return $false
                    } -ParameterFilter { $Path -eq $testParams.BinaryDir }
                }

                It "Should throw exception in the get method" {
                    { Get-TargetResource @testParams } | Should -Throw "Specified path cannot be found"
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Specified path cannot be found"
                }

                It "Should throw exception in the test method" {
                    { Test-TargetResource @testParams } | Should -Throw "Specified path cannot be found"
                }
            }

            Context -Name "Setup.exe file not found in BinaryDir" -Fixture {
                BeforeAll {
                    $testParams = @{
                        BinaryDir = "C:\SPInstall"
                        Ensure    = "Present"
                    }

                    Mock -CommandName Test-Path -MockWith {
                        return $false
                    } -ParameterFilter { $Path -eq (Join-Path -Path $testParams.BinaryDir -ChildPath "setup.exe") }
                }

                It "Should throw exception in the get method" {
                    { Get-TargetResource @testParams } | Should -Throw "Setup.exe cannot be found"
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Setup.exe cannot be found"
                }

                It "Should throw exception in the test method" {
                    { Test-TargetResource @testParams } | Should -Throw "Setup.exe cannot be found"
                }
            }

            Context -Name "Setup.exe file is blocked" -Fixture {
                BeforeAll {
                    $testParams = @{
                        BinaryDir = "C:\SPInstall"
                        Ensure    = "Present"
                    }

                    Mock -CommandName Get-Item -MockWith {
                        return "data"
                    }
                }

                It "Should throw exception in the get method" {
                    { Get-TargetResource @testParams } | Should -Throw "Setup file is blocked!"
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Setup file is blocked!"
                }

                It "Should throw exception in the test method" {
                    { Test-TargetResource @testParams } | Should -Throw "Setup file is blocked!"
                }
            }

            Context -Name "Language Pack is installed, installation not required" -Fixture {
                BeforeAll {
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

                    Mock -CommandName Get-SPDscRegProductsInfo -MockWith {
                        switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major)
                        {
                            15
                            {
                                return @("Microsoft SharePoint Server 2013", "Language Pack for SharePoint and Project Server 2013  - Dutch/Nederlands")
                            }
                            16
                            {
                                if ($Global:SPDscHelper.CurrentStubBuildNumber.Minor.ToString().Length -le 4)
                                {
                                    return @("Microsoft SharePoint Server 2016", "Language Pack for SharePoint and Project Server 2016  - Dutch/Nederlands")
                                }
                                else
                                {
                                    return @("Microsoft SharePoint Server 2019", "Language Pack for SharePoint and Project Server 2010  - Dutch/Nederlands")
                                }
                            }
                            Default
                            {
                                throw [Exception] "A supported version of SharePoint was not used in testing"
                            }
                        }
                    }
                }

                It "Should return Ensure is Present from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Present"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Chinese (Taiwan) Language Pack (naming not according naming standard) is installed, installation not required" -Fixture {
                BeforeAll {
                    $testParams = @{
                        BinaryDir = "C:\SPInstall"
                        Ensure    = "Present"
                    }

                    Mock -CommandName Test-Path -MockWith {
                        return $true
                    }

                    Mock -CommandName Get-ChildItem -MockWith {
                        return @{
                            Name = "C:\SPInstall\osmui.zh-tw"
                        }
                    }

                    Mock -CommandName Get-SPDscRegProductsInfo -MockWith {
                        switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major)
                        {
                            15
                            {
                                return @("Microsoft SharePoint Server 2013", 'Language Pack for SharePoint and Project Server 2013  - Chinese (Taiwan)/中文 (繁體)')
                            }
                            16
                            {
                                if ($Global:SPDscHelper.CurrentStubBuildNumber.Build.ToString().Length -le 4)
                                {
                                    return @("Microsoft SharePoint Server 2016", 'Language Pack for SharePoint and Project Server 2016  - Chinese (Taiwan)/中文 (繁體)')
                                }
                                else
                                {
                                    return @("Microsoft SharePoint Server 2019", 'Language Pack for SharePoint and Project Server 2019 - Chinese (Traditional)/中文 (繁體)')
                                }
                            }
                            Default
                            {
                                throw [Exception] "A supported version of SharePoint was not used in testing"
                            }
                        }
                    }
                }

                It "Should return Ensure is Present from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Present"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Chinese (China) Language Pack (naming not according naming standard) is installed, installation not required" -Fixture {
                BeforeAll {
                    $testParams = @{
                        BinaryDir = "C:\SPInstall"
                        Ensure    = "Present"
                    }

                    Mock -CommandName Test-Path -MockWith {
                        return $true
                    }

                    Mock -CommandName Get-ChildItem -MockWith {
                        return @{
                            Name = "C:\SPInstall\osmui.zh-cn"
                        }
                    }

                    Mock -CommandName Get-SPDscRegProductsInfo -MockWith {
                        switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major)
                        {
                            15
                            {
                                return @("Microsoft SharePoint Server 2013", 'Language Pack for SharePoint and Project Server 2013  - Chinese (PRC)/中文(简体)')
                            }
                            16
                            {
                                if ($Global:SPDscHelper.CurrentStubBuildNumber.Build.ToString().Length -le 4)
                                {
                                    return @("Microsoft SharePoint Server 2016", 'Language Pack for SharePoint and Project Server 2016  - Chinese (PRC)/中文(简体)')
                                }
                                else
                                {
                                    return @("Microsoft SharePoint Server 2019", 'Language Pack for SharePoint and Project Server 2019  - Chinese (Simplified)/中文(简体)')
                                }
                            }
                            Default
                            {
                                throw [Exception] "A supported version of SharePoint was not used in testing"
                            }
                        }
                    }
                }

                It "Should return Ensure is Present from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Present"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Dari Language Pack (naming not according naming standard) is installed, installation not required" -Fixture {
                BeforeAll {
                    $testParams = @{
                        BinaryDir = "C:\SPInstall"
                        Ensure    = "Present"
                    }

                    Mock -CommandName Test-Path -MockWith {
                        return $true
                    }

                    Mock -CommandName Get-ChildItem -MockWith {
                        return @{
                            Name = "C:\SPInstall\osmui.prs-AF"
                        }
                    }

                    Mock -CommandName Get-SPDscRegProductsInfo -MockWith {
                        switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major)
                        {
                            15
                            {
                                return @("Microsoft SharePoint Server 2013", 'Language Pack for SharePoint and Project Server 2013  - درى Dari')
                            }
                            16
                            {
                                if ($Global:SPDscHelper.CurrentStubBuildNumber.Minor.ToString().Length -le 4)
                                {
                                    return @("Microsoft SharePoint Server 2016", 'Language Pack for SharePoint and Project Server 2016  - درى Dari')
                                }
                                else
                                {
                                    return @("Microsoft SharePoint Server 2019", 'Language Pack for SharePoint and Project Server 2019  - درى Dari')
                                }
                            }
                            Default
                            {
                                throw [Exception] "A supported version of SharePoint was not used in testing"
                            }
                        }
                    }
                }

                It "Should return Ensure is Present from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Present"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Serbian (Latin) Language Pack (naming not according naming standard) is installed, installation not required" -Fixture {
                BeforeAll {
                    $testParams = @{
                        BinaryDir = "C:\SPInstall"
                        Ensure    = "Present"
                    }

                    Mock -CommandName Test-Path -MockWith {
                        return $true
                    }

                    Mock -CommandName Get-ChildItem -MockWith {
                        return @{
                            Name = "C:\SPInstall\osmui.sr-Latn-RS"
                        }
                    }

                    Mock -CommandName Get-SPDscRegProductsInfo -MockWith {
                        switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major)
                        {
                            15
                            {
                                return @("Microsoft SharePoint Server 2013", 'Language Pack for SharePoint and Project Server 2013  - Serbian/srpski')
                            }
                            16
                            {
                                if ($Global:SPDscHelper.CurrentStubBuildNumber.Minor.ToString().Length -le 4)
                                {
                                    return @("Microsoft SharePoint Server 2016", 'Language Pack for SharePoint and Project Server 2016  - Serbian/srpski')
                                }
                                else
                                {
                                    return @("Microsoft SharePoint Server 2019", 'Language Pack for SharePoint and Project Server 2019  - Serbian/srpski')
                                }
                            }
                            Default
                            {
                                throw [Exception] "A supported version of SharePoint was not used in testing"
                            }
                        }
                    }
                }

                It "Should return Ensure is Present from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Present"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Serbian (Cyrillic) Language Pack (naming not according naming standard) is installed, installation not required" -Fixture {
                BeforeAll {
                    $testParams = @{
                        BinaryDir = "C:\SPInstall"
                        Ensure    = "Present"
                    }

                    Mock -CommandName Test-Path -MockWith {
                        return $true
                    }

                    Mock -CommandName Get-ChildItem -MockWith {
                        return @{
                            Name = "C:\SPInstall\osmui.sr-Cyrl-RS"
                        }
                    }

                    Mock -CommandName Get-SPDscRegProductsInfo -MockWith {
                        switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major)
                        {
                            15
                            {
                                return @("Microsoft SharePoint Server 2013", 'Language Pack for SharePoint and Project Server 2013  - Serbian/српски')
                            }
                            16
                            {
                                if ($Global:SPDscHelper.CurrentStubBuildNumber.Minor.ToString().Length -le 4)
                                {
                                    return @("Microsoft SharePoint Server 2016", 'Language Pack for SharePoint and Project Server 2016  - Serbian/српски')
                                }
                                else
                                {
                                    return @("Microsoft SharePoint Server 2019", 'Language Pack for SharePoint and Project Server 2019  - Serbian/српски')
                                }
                            }
                            Default
                            {
                                throw [Exception] "A supported version of SharePoint was not used in testing"
                            }
                        }
                    }
                }

                It "Should return Ensure is Present from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Present"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Portuguese (Brasil) Language Pack (naming not according naming standard) is installed, installation not required" -Fixture {
                BeforeAll {
                    $testParams = @{
                        BinaryDir = "C:\SPInstall"
                        Ensure    = "Present"
                    }

                    Mock -CommandName Test-Path -MockWith {
                        return $true
                    }

                    Mock -CommandName Get-ChildItem -MockWith {
                        return @{
                            Name = "C:\SPInstall\osmui.pt-br"
                        }
                    }

                    Mock -CommandName Get-SPDscRegProductsInfo -MockWith {
                        switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major)
                        {
                            15
                            {
                                return @("Microsoft SharePoint Server 2013", 'Language Pack for SharePoint and Project Server 2013  - Portuguese/Português (Brasil)')
                            }
                            16
                            {
                                if ($Global:SPDscHelper.CurrentStubBuildNumber.Minor.ToString().Length -le 4)
                                {
                                    return @("Microsoft SharePoint Server 2016", 'Language Pack for SharePoint and Project Server 2016  - Portuguese/Português (Brasil)')
                                }
                                else
                                {
                                    return @("Microsoft SharePoint Server 2019", 'Language Pack for SharePoint and Project Server 2019  - Portuguese/Português (Brasil)')
                                }
                            }
                            Default
                            {
                                throw [Exception] "A supported version of SharePoint was not used in testing"
                            }
                        }
                    }
                }

                It "Should return Ensure is Present from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Present"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Portuguese (Portugal) Language Pack (naming not according naming standard) is installed, installation not required" -Fixture {
                BeforeAll {
                    $testParams = @{
                        BinaryDir = "C:\SPInstall"
                        Ensure    = "Present"
                    }

                    Mock -CommandName Test-Path -MockWith {
                        return $true
                    }

                    Mock -CommandName Get-ChildItem -MockWith {
                        return @{
                            Name = "C:\SPInstall\osmui.pt-pt"
                        }
                    }

                    Mock -CommandName Get-SPDscRegProductsInfo -MockWith {
                        switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major)
                        {
                            15
                            {
                                return @("Microsoft SharePoint Server 2013", 'Language Pack for SharePoint and Project Server 2013  - Portuguese/Português')
                            }
                            16
                            {
                                if ($Global:SPDscHelper.CurrentStubBuildNumber.Minor.ToString().Length -le 4)
                                {
                                    return @("Microsoft SharePoint Server 2016", 'Language Pack for SharePoint and Project Server 2016  - Portuguese/Português')
                                }
                                else
                                {
                                    return @("Microsoft SharePoint Server 2019", 'Language Pack for SharePoint and Project Server 2019  - Portuguese/Português')
                                }
                            }
                            Default
                            {
                                throw [Exception] "A supported version of SharePoint was not used in testing"
                            }
                        }
                    }
                }

                It "Should return Ensure is Present from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Present"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Arabic Language Pack (naming not according naming standard) is installed, installation not required" -Fixture {
                BeforeAll {
                    $testParams = @{
                        BinaryDir = "C:\SPInstall"
                        Ensure    = "Present"
                    }

                    Mock -CommandName Test-Path -MockWith {
                        return $true
                    }

                    Mock -CommandName Get-ChildItem -MockWith {
                        return @{
                            Name = "C:\SPInstall\osmui.ar-SA"
                        }
                    }

                    Mock -CommandName Get-SPDscRegProductsInfo -MockWith {
                        switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major)
                        {
                            15
                            {
                                return @("Microsoft SharePoint Server 2013", 'Language Pack for SharePoint and Project Server 2013  - Arabic/LOCAL ARABIC')
                            }
                            16
                            {
                                if ($Global:SPDscHelper.CurrentStubBuildNumber.Minor.ToString().Length -le 4)
                                {
                                    return @("Microsoft SharePoint Server 2016", 'Language Pack for SharePoint and Project Server 2016  - Arabic/LOCAL ARABIC')
                                }
                                else
                                {
                                    return @("Microsoft SharePoint Server 2019", 'Language Pack for SharePoint and Project Server 2019  - Arabic/LOCAL ARABIC')
                                }
                            }
                            Default
                            {
                                throw [Exception] "A supported version of SharePoint was not used in testing"
                            }
                        }
                    }
                }

                It "Should return Ensure is Present from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Present"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Language Pack is not installed, installation executed successfully" -Fixture {
                BeforeAll {
                    $testParams = @{
                        BinaryDir = "C:\SPInstall"
                        Ensure    = "Present"
                    }

                    Mock -CommandName Get-SPDscFarmProductsInfo -MockWith {
                        switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major)
                        {
                            15
                            {
                                return @("Microsoft SharePoint Server 2013")
                            }
                            16
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
                            Default
                            {
                                throw [Exception] "A supported version of SharePoint was not used in testing"
                            }
                        }
                    }

                    Mock -CommandName Get-SPDscRegProductsInfo -MockWith {
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

                    Mock -CommandName Start-Process -MockWith {
                        return @{
                            ExitCode = 0
                        }
                    }
                }

                It "Should return Ensure is Present from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Absent"
                }

                It "Should run the Start-Process function in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Start-Process
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "Language Pack is not installed, installation executed successfully using UNC path" -Fixture {
                BeforeAll {
                    $testParams = @{
                        BinaryDir = "\\server\install\SPInstall"
                        Ensure    = "Present"
                    }

                    Mock -CommandName Get-SPDscFarmProductsInfo -MockWith {
                        switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major)
                        {
                            15
                            {
                                return @("Microsoft SharePoint Server 2013")
                            }
                            16
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
                            Default
                            {
                                throw [Exception] "A supported version of SharePoint was not used in testing"
                            }
                        }
                    }

                    Mock -CommandName Get-SPDscRegProductsInfo -MockWith {
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

                    Mock -CommandName Get-Item -MockWith {
                        return $null
                    }

                    Mock -CommandName Start-Process -MockWith {
                        return @{
                            ExitCode = 0
                        }
                    }
                }

                It "Should run the Start-Process function in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Start-Process
                }
            }

            Context -Name "Language Pack is not installed, installation executed successfully using CDROM drive" -Fixture {
                BeforeAll {
                    $testParams = @{
                        BinaryDir = "C:\SPInstall"
                        Ensure    = "Present"
                    }

                    Mock -CommandName Get-SPDscFarmProductsInfo -MockWith {
                        switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major)
                        {
                            15
                            {
                                return @("Microsoft SharePoint Server 2013")
                            }
                            16
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
                            Default
                            {
                                throw [Exception] "A supported version of SharePoint was not used in testing"
                            }
                        }
                    }

                    Mock -CommandName Get-SPDscRegProductsInfo -MockWith {
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

                    Mock -CommandName Get-Volume -MockWith {
                        return @{
                            DriveType = "CD-ROM"
                        }
                    }

                    Mock -CommandName Get-Item -MockWith {
                        return $null
                    }

                    Mock -CommandName Start-Process -MockWith {
                        return @{
                            ExitCode = 0
                        }
                    }
                }

                It "Should not unblock file and run the Start-Process function in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Get-Item -Times 0
                    Assert-MockCalled Start-Process
                }
            }

            Context -Name "Language Pack is not installed, installation executed, reboot required" -Fixture {
                BeforeAll {
                    $testParams = @{
                        BinaryDir = "C:\SPInstall"
                        Ensure    = "Present"
                    }

                    Mock -CommandName Get-SPDscFarmProductsInfo -MockWith {
                        switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major)
                        {
                            15
                            {
                                return @("Microsoft SharePoint Server 2013")
                            }
                            16
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
                            Default
                            {
                                throw [Exception] "A supported version of SharePoint was not used in testing"
                            }
                        }
                    }

                    Mock -CommandName Get-SPDscRegProductsInfo -MockWith {
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

                    Mock -CommandName Start-Process -MockWith {
                        return @{
                            ExitCode = 17022
                        }
                    }
                }

                It "Should return Ensure is Present from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Absent"
                }

                It "Should run the Start-Process function in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Start-Process
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "Language Pack is not installed, installation executed, which failed" -Fixture {
                BeforeAll {
                    $testParams = @{
                        BinaryDir = "C:\SPInstall"
                        Ensure    = "Present"
                    }

                    Mock -CommandName Get-SPDscFarmProductsInfo -MockWith {
                        switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major)
                        {
                            15
                            {
                                return @("Microsoft SharePoint Server 2013")
                            }
                            16
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
                            Default
                            {
                                throw [Exception] "A supported version of SharePoint was not used in testing"
                            }
                        }
                    }

                    Mock -CommandName Get-SPDscRegProductsInfo -MockWith {
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

                    Mock -CommandName Start-Process -MockWith {
                        return @{
                            ExitCode = 1
                        }
                    }
                }

                It "Should return Ensure is Present from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Absent"
                }

                It "Should run the Start-Process function in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "SharePoint Language Pack install failed, exit code was 1"
                    Assert-MockCalled Start-Process
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "Language Pack does not have language in the name, throws exception" -Fixture {
                BeforeAll {
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
                            15
                            {
                                return @("Microsoft SharePoint Server 2013", "Language Pack for SharePoint and Project Server 2013  - Dutch/Nederlands")
                            }
                            16
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
                            Default
                            {
                                throw [Exception] "A supported version of SharePoint was not used in testing"
                            }
                        }
                    }

                    Mock -CommandName Get-SPDscRegProductsInfo -MockWith {
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
                }

                It "Should throw exception in the get method" {
                    { Get-TargetResource @testParams } | Should -Throw "Update does not contain the language code in the correct format."
                }
            }

            Context -Name "Language Pack has unknown language in the name, throws exception" -Fixture {
                BeforeAll {
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
                            15
                            {
                                return @("Microsoft SharePoint Server 2013", "Language Pack for SharePoint and Project Server 2013  - Dutch/Nederlands")
                            }
                            16
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
                            Default
                            {
                                throw [Exception] "A supported version of SharePoint was not used in testing"
                            }
                        }
                    }

                    Mock -CommandName Get-SPDscRegProductsInfo -MockWith {
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
                }

                It "Should throw exception in the get method" {
                    { Get-TargetResource @testParams } | Should -Throw "Error while converting language information:"
                }
            }

            Context -Name "Upgrade pending - Skipping install" -Fixture {
                BeforeAll {
                    $testParams = @{
                        BinaryDir = "C:\SPInstall"
                        Ensure    = "Present"
                    }
                }

                It "Should return null from  the set method" {
                    Set-TargetResource @testParams | Should -BeNullOrEmpty
                }
            }

            Context -Name "BinaryInstallDays outside range" -Fixture {
                BeforeAll {
                    $testParams = @{
                        BinaryDir         = "C:\SPInstall"
                        BinaryInstallDays = "mon"
                        Ensure            = "Present"
                    }

                    $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00

                    Mock -CommandName Get-Date -MockWith {
                        return $testDate
                    }
                }

                It "Should return null from the set method" {
                    Set-TargetResource @testParams | Should -BeNullOrEmpty
                }
            }

            Context -Name "BinaryInstallTime outside range" -Fixture {
                BeforeAll {
                    $testParams = @{
                        BinaryDir         = "C:\SPInstall"
                        BinaryInstallDays = "sun"
                        BinaryInstallTime = "3:00am to 5:00am"
                        Ensure            = "Present"
                    }

                    $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00

                    Mock -CommandName Get-Date -MockWith {
                        return $testDate
                    }
                }

                It "Should return null from the set method" {
                    Set-TargetResource @testParams | Should -BeNullOrEmpty
                }
            }

            Context -Name "BinaryInstallTime incorrectly formatted, too many arguments" -Fixture {
                BeforeAll {
                    $testParams = @{
                        BinaryDir         = "C:\SPInstall"
                        BinaryInstallDays = "sun"
                        BinaryInstallTime = "error 3:00am to 5:00am"
                        Ensure            = "Present"
                    }

                    $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00

                    Mock -CommandName Get-Date -MockWith {
                        return $testDate
                    }
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Time window incorrectly formatted."
                }
            }

            Context -Name "BinaryInstallTime incorrectly formatted, incorrect start time" -Fixture {
                BeforeAll {
                    $testParams = @{
                        BinaryDir         = "C:\SPInstall"
                        BinaryInstallDays = "sun"
                        BinaryInstallTime = "3:00xm to 5:00am"
                        Ensure            = "Present"
                    }

                    $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00

                    Mock -CommandName Get-Date -MockWith {
                        return $testDate
                    }
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Error converting start time"
                }
            }

            Context -Name "BinaryInstallTime incorrectly formatted, incorrect end time" -Fixture {
                BeforeAll {
                    $testParams = @{
                        BinaryDir         = "C:\SPInstall"
                        BinaryInstallDays = "sun"
                        BinaryInstallTime = "3:00am to 5:00xm"
                        Ensure            = "Present"
                    }

                    $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00

                    Mock -CommandName Get-Date -MockWith {
                        return $testDate
                    }
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Error converting end time"
                }
            }

            Context -Name "BinaryInstallTime start time larger than end time" -Fixture {
                BeforeAll {
                    $testParams = @{
                        BinaryDir         = "C:\SPInstall"
                        BinaryInstallDays = "sun"
                        BinaryInstallTime = "3:00pm to 5:00am"
                        Ensure            = "Present"
                    }

                    $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00

                    Mock -CommandName Get-Date -MockWith {
                        return $testDate
                    }
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Error: Start time cannot be larger than end time"
                }
            }

            Context -Name "Ensure is set to Absent" -Fixture {
                BeforeAll {
                    $testParams = @{
                        BinaryDir = "C:\SPInstall"
                        Ensure    = "Absent"
                    }
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "SharePointDsc does not support uninstalling SharePoint Language Packs. Please remove this manually."
                }

                It "Should throw exception in the test method" {
                    { Test-TargetResource @testParams } | Should -Throw "SharePointDsc does not support uninstalling SharePoint Language Packs. Please remove this manually."
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
