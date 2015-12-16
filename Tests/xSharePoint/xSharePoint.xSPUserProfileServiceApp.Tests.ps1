[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 
    
$ModuleName = "MSFT_xSPUserProfileSyncConnection"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPUserProfileSyncConnection" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "User Profile Service App"
            ApplicationPool = "SharePoint Service Applications"
            FarmAccount = New-Object System.Management.Automation.PSCredential ("domain\username", (ConvertTo-SecureString "password" -AsPlainText -Force))
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        
        Mock Get-SPFarm { return @{
            DefaultServiceAccount = @{ Name = $testParams.FarmAccount.Username }
        }}
        Mock New-SPProfileServiceApplication { return @{} }
        Mock New-SPProfileServiceApplicationProxy { }
        Mock Add-xSharePointUserToLocalAdmin { } 
        Mock Test-xSharePointUserIsLocalAdmin { return $false }
        Mock Remove-xSharePointUserToLocalAdmin { }
        Mock New-PSSession { return $null } -ModuleName "xSharePoint.Util"

        Context "When no service applications exist in the current farm" {

            Mock Get-SPServiceApplication { return $null }

            It "returns null from the Get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name } 
            }

            It "returns false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "creates a new service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPProfileServiceApplication
            }

            $testParams.Add("InstallAccount", (New-Object System.Management.Automation.PSCredential ("domain\username", (ConvertTo-SecureString "password" -AsPlainText -Force))))
            It "creates a new service application in the set method when InstallAccount is used" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPProfileServiceApplication
            }
            $testParams.Remove("InstallAccount")
        }

        Context "When service applications exist in the current farm but not the specific user profile service app" {

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
                return @(
                    New-Object Object |            
                        Add-Member NoteProperty TypeName "User Profile Service Application" -PassThru |
                        Add-Member NoteProperty DisplayName $testParams.Name -PassThru | 
                        Add-Member NoteProperty ApplicationPool @{ Name = $testParams.ApplicationPool } -PassThru |             
                        Add-Member ScriptMethod GetType {
                            New-Object Object |
                                Add-Member ScriptMethod GetProperties {
                                    param($x)
                                    return @(
                                        (New-Object Object |
                                            Add-Member NoteProperty Name "SocialDatabase" -PassThru |
                                            Add-Member ScriptMethod GetValue {
                                                param($x)
                                                return @{
                                                    Name = "SP_SocialDB"
                                                    Server = @{ Name = "SQL.domain.local" }
                                                }
                                            } -PassThru
                                        ),
                                        (New-Object Object |
                                            Add-Member NoteProperty Name "ProfileDatabase" -PassThru |
                                            Add-Member ScriptMethod GetValue {
                                                return @{
                                                    Name = "SP_ProfileDB"
                                                    Server = @{ Name = "SQL.domain.local" }
                                                }
                                            } -PassThru
                                        ),
                                        (New-Object Object |
                                            Add-Member NoteProperty Name "SynchronizationDatabase" -PassThru |
                                            Add-Member ScriptMethod GetValue {
                                                return @{
                                                    Name = "SP_ProfileSyncDB"
                                                    Server = @{ Name = "SQL.domain.local" }
                                                }
                                            } -PassThru
                                        )
                                    )
                                } -PassThru
                    } -PassThru -Force 
                )
            }

            It "returns values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name } 
            }

            It "returns true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }

            Mock Get-SPFarm { return @{
                DefaultServiceAccount = @{ Name = "WRONG\account" }
            }}

            It "returns values from the get method where the farm account doesn't match" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name } 
            }
        }
    }    
}