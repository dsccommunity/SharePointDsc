[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 
    
$ModuleName = "MSFT_SPUserProfileServiceApp"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDSC\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPUserProfileServiceApp - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "User Profile Service App"
            ApplicationPool = "SharePoint Service Applications"
            FarmAccount = New-Object System.Management.Automation.PSCredential ("domain\username", (ConvertTo-SecureString "password" -AsPlainText -Force))
            Ensure = "Present"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\SharePointDSC")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        
        Mock Get-SPFarm { return @{
            DefaultServiceAccount = @{ Name = $testParams.FarmAccount.Username }
        }}
        Mock New-SPProfileServiceApplication { return @{} }
        Mock New-SPProfileServiceApplicationProxy { }
        Mock Add-SPDSCUserToLocalAdmin { } 
        Mock Test-SPDSCUserIsLocalAdmin { return $false }
        Mock Remove-SPDSCUserToLocalAdmin { }
        Mock New-PSSession { return $null } -ModuleName "SharePointDSC.Util"
        Mock Remove-SPServiceApplication { } 

        Context "When no service applications exist in the current farm" {

            Mock Get-SPServiceApplication { return $null }

            It "returns absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"  
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

            It "returns absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"  
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

            It "returns present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"  
            }

            It "returns true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }

            Mock Get-SPFarm { return @{
                DefaultServiceAccount = @{ Name = "WRONG\account" }
            }}

            It "returns present from the get method where the farm account doesn't match" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"  
            }
        }
        
        $testParams = @{
            Name = "Test App"
            ApplicationPool = "-"
            Ensure = "Absent"
        }
        
        Context "When the service app exists but it shouldn't" {
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
            
            It "returns present from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present" 
            }
            
            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "should remove the service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPServiceApplication
            }
        }
        
        Context "When the service app doesn't exist and shouldn't" {
            Mock Get-SPServiceApplication { return $null }
            
            It "returns absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }
            
            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }    
}