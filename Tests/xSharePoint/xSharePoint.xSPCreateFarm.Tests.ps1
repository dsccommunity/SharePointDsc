[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_xSPCreateFarm"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPCreateFarm" {
    InModuleScope $ModuleName {
        $testParams = @{
            FarmConfigDatabaseName = "SP_Config"
            DatabaseServer = "DatabaseServer\Instance"
            FarmAccount = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
            Passphrase = "passphrase"
            AdminContentDatabaseName = "Admin_Content"
            CentralAdministrationPort = 1234
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
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
        Mock Get-xSharePointInstalledProductVersion { return @{ FileMajorPart = $majorBuildNumber } }

        Context "no farm is configured locally and a supported version of SharePoint is installed" {
            Mock Get-SPFarm { return $null }

            It "the get method returns null when the farm is not configured" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "calls the appropriate cmdlets in the set method" {
                Set-TargetResource @testParams
                switch ($majorBuildNumber)
                {
                    15 {
                        Assert-MockCalled New-SPConfigurationDatabase
                    }
                    16 {
                        Assert-MockCalled New-SPConfigurationDatabase -ParameterFilter { $LocalServerRole -ne $null }
                    }
                    Default {
                        throw [Exception] "A supported version of SharePoint was not used in testing"
                    }
                }
                
            }
        }

        Context "no farm is configured locally and an unsupported version of SharePoint is installed on the server" {
            Mock Get-xSharePointInstalledProductVersion { return @{ FileMajorPart = 14 } }

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

        Context "no farm is configured locally, a supported version is installed and no central admin port is specified" {
            $testParams.Remove("CentralAdministrationPort")

            It "uses a default value for the central admin port" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPCentralAdministration -ParameterFilter { $Port -eq 9999 }
            }
        }
    }    
}