[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPCreateFarm"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDSC\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "SPCreateFarm" {
    InModuleScope $ModuleName {
        $testParams = @{
            FarmConfigDatabaseName = "SP_Config"
            DatabaseServer = "DatabaseServer\Instance"
            FarmAccount = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
            Passphrase =  New-Object System.Management.Automation.PSCredential ("PASSPHRASEUSER", (ConvertTo-SecureString "MyFarmPassphrase" -AsPlainText -Force))
            AdminContentDatabaseName = "Admin_Content"
            CentralAdministrationAuth = "Kerberos"
            CentralAdministrationPort = 1234
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\SharePointDSC")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        Mock New-SPConfigurationDatabase {}
        Mock Install-SPHelpCollection {}
        Mock Initialize-SPResourceSecurity {}
        Mock Install-SPService {}
        Mock Install-SPFeature {}
        Mock New-SPCentralAdministration {}
        Mock Install-SPApplicationContent {}

        $versionBeingTested = (Get-Item $Global:CurrentSharePointStubModule).Directory.BaseName
        $majorBuildNumber = $versionBeingTested.Substring(0, $versionBeingTested.IndexOf("."))
        Mock Get-SPDSCInstalledProductVersion { return @{ FileMajorPart = $majorBuildNumber } }

        Context "no farm is configured locally and a supported version of SharePoint is installed" {
            Mock Get-SPFarm { throw "Unable to detect local farm" }

            It "the get method returns null when the farm is not configured" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "calls the new configuration database cmdlet in the set method" {
                Set-TargetResource @testParams
                switch ($majorBuildNumber)
                {
                    15 {
                        Assert-MockCalled New-SPConfigurationDatabase
                    }
                    16 {
                        Assert-MockCalled New-SPConfigurationDatabase -ParameterFilter { $ServerRoleOptional -eq $true }
                    }
                    Default {
                        throw [Exception] "A supported version of SharePoint was not used in testing"
                    }
                }
                
            }

            if ($majorBuildNumber -eq 16) {
                $testParams.Add("ServerRole", "WebFrontEnd")
                It "creates a farm with a specific server role" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPConfigurationDatabase -ParameterFilter { $LocalServerRole -eq "WebFrontEnd" }
                }
                $testParams.Remove("ServerRole")
            }
        }

        if ($majorBuildNumber -eq 15) {
            $testParams.Add("ServerRole", "WebFrontEnd")

            Context "only valid parameters for SharePoint 2013 are used" {
                It "throws if server role is used in the get method" {
                    { Get-TargetResource @testParams } | Should Throw
                }

                It "throws if server role is used in the test method" {
                    { Test-TargetResource @testParams } | Should Throw
                }

                It "throws if server role is used in the set method" {
                    { Set-TargetResource @testParams } | Should Throw
                }
            }

            $testParams.Remove("ServerRole")
        }

        Context "no farm is configured locally and an unsupported version of SharePoint is installed on the server" {
            Mock Get-SPDSCInstalledProductVersion { return @{ FileMajorPart = 14 } }

            It "throws when an unsupported version is installed and set is called" {
                { Set-TargetResource @testParams } | Should throw
            }
        }

        Context "a farm exists locally" {
            Mock Get-SPFarm { return @{ 
                DefaultServiceAccount = @{ Name = $testParams.FarmAccount.UserName }
                Name = $testParams.FarmConfigDatabaseName
            }}
            Mock Get-SPDatabase { return @(@{ 
                Name = $testParams.FarmConfigDatabaseName
                Type = "Configuration Database"
                Server = @{ Name = $testParams.DatabaseServer }
            })} 
            Mock Get-SPWebApplication { return @(@{
                IsAdministrationWebApplication = $true
                ContentDatabases = @(@{ Name = $testParams.AdminContentDatabaseName })
                Url = "http://$($env:ComputerName):$($testParams.CentralAdministrationPort)"
            })}

            It "the get method returns values when the farm is configured" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "a farm exists locally with the wrong farm account" {
            Mock Get-SPFarm { return @{ 
                DefaultServiceAccount = @{ Name = "WRONG\account" }
                Name = $testParams.FarmConfigDatabaseName
            }}
            Mock Get-SPWebApplication { return @(@{
                IsAdministrationWebApplication = $true
                ContentDatabases = @(@{ Name = $testParams.AdminContentDatabaseName })
                Url = "http://$($env:ComputerName):$($testParams.CentralAdministrationPort)"
            })}

            It "the get method returns current values" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns true from the test method as changing the farm account isn't supported so set shouldn't be called" {
                Test-TargetResource @testParams | Should Be $true
            }

        }

        Context "no farm is configured locally, a supported version is installed and no central admin port is specified" {
            $testParams.Remove("CentralAdministrationPort")

            It "uses a default value for the central admin port" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPCentralAdministration -ParameterFilter { $Port -eq 9999 }
            }
        }
        
        Context "no farm is configured locally, a supported version is installed and no central admin auth is specified" {
            $testParams.Remove("CentralAdministrationAuth")

            It "uses NTLM for the Central Admin web application authentication" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPCentralAdministration -ParameterFilter { $WindowsAuthProvider -eq "NTLM" }
            }
        }
    }    
}