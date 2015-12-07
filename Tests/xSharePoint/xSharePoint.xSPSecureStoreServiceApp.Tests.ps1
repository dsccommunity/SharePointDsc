[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_xSPSecureStoreServiceApp"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPSecureStoreServiceApp" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Secure Store Service Application"
            ApplicationPool = "SharePoint Search Services"
            AuditingEnabled = $false
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        $versionBeingTested = (Get-Item $Global:CurrentSharePointStubModule).Directory.BaseName
        $majorBuildNumber = $versionBeingTested.Substring(0, $versionBeingTested.IndexOf("."))

        Mock Get-xSharePointInstalledProductVersion { return @{ FileMajorPart = $majorBuildNumber } }

        Context "When no service application exists in the current farm" {

            Mock Get-SPServiceApplication { return $null }
            Mock New-SPSecureStoreServiceApplication { }
            Mock New-SPSecureStoreServiceApplicationProxy { }

            It "returns null from the Get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name } 
            }

            It "returns false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "creates a new service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPSecureStoreServiceApplication 
            }

            $testParams.Add("InstallAccount", (New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))))
            It "creates a new service application in the set method where InstallAccount is used" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPSecureStoreServiceApplication 
            }
            $testParams.Remove("InstallAccount")

            $testParams.Add("DatabaseName", "SP_SecureStore")
            It "creates a new service application in the set method where parameters beyond the minimum required set" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPSecureStoreServiceApplication 
            }
            $testParams.Remove("DatabaseName")
        }

        Context "When service applications exist in the current farm but the specific search app does not" {
            Mock Get-SPServiceApplication { return @(@{
                TypeName = "Some other service app type"
            }) }
        
            It "returns null from the Get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name } 
            }

            It "returns false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context "When a service application exists and is configured correctly" {
            Mock Get-SPServiceApplication { 
                return @(@{
                    TypeName = "Secure Store Service Application"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                    Database = @{
                        Name = $testParams.DatabaseName
                        Server = @{ Name = $testParams.DatabaseServer }
                    }
                })
            }

            It "returns values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name } 
            }

            It "returns true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "When a service application exists and the app pool is not configured correctly" {
            Mock Get-SPServiceApplication { 
                return @(@{
                    TypeName = "Secure Store Service Application"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = "Wrong App Pool Name" }
                    Database = @{
                        Name = $testParams.DatabaseName
                        Server = @{ Name = $testParams.DatabaseServer }
                    }
                })
            }
            Mock Get-SPServiceApplicationPool { return @{ Name = $testParams.ApplicationPool } }
            Mock Set-SPSecureStoreServiceApplication { }

            It "returns false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "calls the update service app cmdlet from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Get-SPServiceApplicationPool
                Assert-MockCalled Set-SPSecureStoreServiceApplication
            }
        }

        Context "When an unsupported version of SharePoint is installed" {
            Mock Get-xSharePointInstalledProductVersion { return @{ FileMajorPart = 14 } }
            Mock Get-SPServiceApplication { 
                return @(@{
                    TypeName = "Secure Store Service Application"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = "Wrong App Pool Name" }
                    Database = @{
                        Name = $testParams.DatabaseName
                        Server = @{ Name = $testParams.DatabaseServer }
                    }
                })
            }
            Mock Get-SPServiceApplicationPool { return @{ Name = $testParams.ApplicationPool } }
            Mock Set-SPSecureStoreServiceApplication { }

            It "the set method throws an exception" {
                { Set-TargetResource @testParams } | Should Throw
            }
        }

        Context "When specific windows credentials are to be used for the database" {
            $testParams = @{
                Name = "Secure Store Service Application"
                ApplicationPool = "SharePoint Search Services"
                AuditingEnabled = $false
                DatabaseName = "SP_ManagedMetadata"
                DatabaseCredentials = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
                DatabaseAuthenticationType = "Windows"
            }

            Mock Get-SPServiceApplication { return $null }
            Mock New-SPSecureStoreServiceApplication { }
            Mock New-SPSecureStoreServiceApplicationProxy { }

            It "allows valid Windows credentials can be passed" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPSecureStoreServiceApplication 
            }

            It "throws an exception if database authentication type is not specified" {
                $testParams.Remove("DatabaseAuthenticationType")
                { Set-TargetResource @testParams } | Should Throw
            }

            It "throws an exception if the credentials aren't provided and the authentication type is set" {
                $testParams.Add("DatabaseAuthenticationType", "Windows")
                $testParams.Remove("DatabaseCredentials")
                { Set-TargetResource @testParams } | Should Throw
            }
        }

        Context "When specific SQL credentials are to be used for the database" {
            $testParams = @{
                Name = "Secure Store Service Application"
                ApplicationPool = "SharePoint Search Services"
                AuditingEnabled = $false
                DatabaseName = "SP_ManagedMetadata"
                DatabaseCredentials = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
                DatabaseAuthenticationType = "SQL"
            }

            Mock Get-SPServiceApplication { return $null }
            Mock New-SPSecureStoreServiceApplication { }
            Mock New-SPSecureStoreServiceApplicationProxy { }

            It "allows valid SQL credentials can be passed" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPSecureStoreServiceApplication 
            }

            It "throws an exception if database authentication type is not specified" {
                $testParams.Remove("DatabaseAuthenticationType")
                { Set-TargetResource @testParams } | Should Throw
            }

            It "throws an exception if the credentials aren't provided and the authentication type is set" {
                $testParams.Add("DatabaseAuthenticationType", "Windows")
                $testParams.Remove("DatabaseCredentials")
                { Set-TargetResource @testParams } | Should Throw
            }
        }
    }    
}