[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
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
                                              -DscResource "SPJoinFarm"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests
        $mockPassphrase = ConvertTo-SecureString -String "MyFarmPassphrase" -AsPlainText -Force
        $mockPassphraseCredential = New-Object -TypeName System.Management.Automation.PSCredential `
                                               -ArgumentList @("passphrase", $mockPassphrase)

        # Mocks for all contexts   
        Mock Connect-SPConfigurationDatabase -MockWith {}
        Mock -CommandName Install-SPHelpCollection -MockWith {}
        Mock Initialize-SPResourceSecurity -MockWith {}
        Mock -CommandName Install-SPService -MockWith {}
        Mock -CommandName Install-SPFeature -MockWith {}
        Mock -CommandName New-SPCentralAdministration -MockWith {}
        Mock -CommandName Install-SPApplicationContent -MockWith {}
        Mock -CommandName Start-Service -MockWith {}
        Mock -CommandName Start-Sleep -MockWith {}

        # Test contexts
        Context -Name "no farm is configured locally and a supported version of SharePoint is installed" {
            $testParams = @{
                FarmConfigDatabaseName = "SP_Config"
                DatabaseServer = "DatabaseServer\Instance"
                Passphrase = $mockPassphraseCredential
            }

            Mock -CommandName Get-SPFarm -MockWith { 
                throw "Unable to detect local farm" 
            }

            It "Should return null from the get method when the farm is not configured" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call the appropriate cmdlets in the set method" {
                Set-TargetResource @testParams
                switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major)
                {
                    15 {
                        Assert-MockCalled Connect-SPConfigurationDatabase
                    }
                    16 {
                        Assert-MockCalled Connect-SPConfigurationDatabase
                    }
                    Default {
                        throw [Exception] "A supported version of SharePoint was not used in testing"
                    }
                }
            }
        }

        if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15) 
        {
            Context -Name "only valid parameters for SharePoint 2013 are used" {
                $testParams = @{
                    FarmConfigDatabaseName = "SP_Config"
                    DatabaseServer = "DatabaseServer\Instance"
                    Passphrase = $mockPassphraseCredential
                    ServerRole = "WebFrontEnd"
                }

                It "Should throw if server role is used in the get method" {
                    { Get-TargetResource @testParams } | Should Throw
                }

                It "Should throw if server role is used in the test method" {
                    { Test-TargetResource @testParams } | Should Throw
                }

                It "Should throw if server role is used in the set method" {
                    { Set-TargetResource @testParams } | Should Throw
                }
            }
        }

        if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 16)
        {
            Context -Name "enhanced minrole options fail when Feature Pack 1 is not installed" -Fixture {
                $testParams = @{
                    FarmConfigDatabaseName = "SP_Config"
                    DatabaseServer = "DatabaseServer\Instance"
                    Passphrase = $mockPassphraseCredential
                    ServerRole = "ApplicationWithSearch"
                }

                Mock -CommandName Get-SPDSCInstalledProductVersion -MockWith {
                    return @{
                        FileMajorPart = 16
                        FileBuildPart = 0
                    }
                }

                It "Should throw if an invalid server role is used in the get method" {
                    { Get-TargetResource @testParams } | Should Throw
                }

                It "Should throw if an invalid server role is used in the test method" {
                    { Test-TargetResource @testParams } | Should Throw
                }

                It "Should throw if an invalid server role is used in the set method" {
                    { Set-TargetResource @testParams } | Should Throw
                }
            }

            Context -Name "enhanced minrole options succeed when Feature Pack 1 is installed" -Fixture {
                $testParams = @{
                    FarmConfigDatabaseName = "SP_Config"
                    DatabaseServer = "DatabaseServer\Instance"
                    Passphrase = $mockPassphraseCredential
                    ServerRole = "ApplicationWithSearch"
                }

                Mock -CommandName Get-SPDSCInstalledProductVersion -MockWith {
                    return @{
                        FileMajorPart = 16
                        FileBuildPart = 4456
                    }
                }

                It "Should throw if an invalid server role is used in the get method" {
                    { Get-TargetResource @testParams } | Should Not Throw
                }

                It "Should throw if an invalid server role is used in the test method" {
                    { Test-TargetResource @testParams } | Should Not Throw
                }

                It "Should throw if an invalid server role is used in the set method" {
                    { Set-TargetResource @testParams } | Should Not Throw
                }
            }
        }

        Context -Name "no farm is configured locally and an unsupported version of SharePoint is installed on the server" {
            $testParams = @{
                FarmConfigDatabaseName = "SP_Config"
                DatabaseServer = "DatabaseServer\Instance"
                Passphrase = $mockPassphraseCredential
            }
            
            Mock -CommandName Get-SPDSCInstalledProductVersion { 
                return @{ FileMajorPart = 14 } 
            }

            It "Should throw when an unsupported version is installed and set is called" {
                { Set-TargetResource @testParams } | Should throw
            }
        }

        Context -Name "a farm exists locally and is the correct farm" {
            $testParams = @{
                FarmConfigDatabaseName = "SP_Config"
                DatabaseServer = "DatabaseServer\Instance"
                Passphrase = $mockPassphraseCredential
            }
            
            Mock -CommandName Get-SPFarm -MockWith { 
                return @{ 
                    DefaultServiceAccount = @{ 
                        Name = $testParams.FarmAccount.UserName 
                    }
                    Name = $testParams.FarmConfigDatabaseName
                }
            }
            
            Mock -CommandName Get-SPDatabase -MockWith { 
                return @(@{ 
                    Name = $testParams.FarmConfigDatabaseName
                    Type = "Configuration Database"
                    Server = @{ 
                        Name = $testParams.DatabaseServer 
                    }
                })
            } 

            It "the get method returns values when the farm is configured" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "a farm exists locally and is not the correct farm" {
            $testParams = @{
                FarmConfigDatabaseName = "SP_Config"
                DatabaseServer = "DatabaseServer\Instance"
                Passphrase = $mockPassphraseCredential
            }
            
            Mock -CommandName Get-SPFarm -MockWith { 
                return @{ 
                    DefaultServiceAccount = @{ Name = $testParams.FarmAccount.UserName }
                    Name = "WrongDBName"
                }
            }
            
            Mock -CommandName Get-SPDatabase -MockWith { 
                return @(@{ 
                    Name = "WrongDBName"
                    Type = "Configuration Database"
                    Server = @{ Name = $testParams.DatabaseServer }
                })
            } 

            It "Should throw an error in the set method" {
                { Set-TargetResource @testParams } | Should throw
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
