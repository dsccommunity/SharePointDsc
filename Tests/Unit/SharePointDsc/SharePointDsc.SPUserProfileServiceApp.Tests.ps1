[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 
    
$ModuleName = "MSFT_SPUserProfileServiceApp"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPUserProfileServiceApp - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "User Profile Service App"
            ApplicationPool = "SharePoint Service Applications"
            FarmAccount = New-Object System.Management.Automation.PSCredential ("domain\username", (ConvertTo-SecureString "password" -AsPlainText -Force))
            Ensure = "Present"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDsc")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        
        Mock -CommandName Get-SPFarm -MockWith { return @{
            DefaultServiceAccount = @{ Name = $testParams.FarmAccount.Username }
        }}
        Mock -CommandName New-SPProfileServiceApplication { return (@{
                                        NetBIOSDomainNamesEnabled =  $false})


         } 
        Mock -CommandName New-SPProfileServiceApplicationProxy { }
        Mock -CommandName Add-SPDSCUserToLocalAdmin { } 
        Mock -CommandName Test-SPDSCUserIsLocalAdmin { return $false }
        Mock -CommandName Remove-SPDSCUserToLocalAdmin { }
        Mock -CommandName New-PSSession { return $null } -ModuleName "SharePointDsc.Util"
        Mock -CommandName Remove-SPServiceApplication { } 

        Context -Name "When no service applications exist in the current farm" {

            Mock -CommandName Get-SPServiceApplication -MockWith { return $null }

            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"  
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should create a new service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPProfileServiceApplication
            }

            $testParams.Add("InstallAccount", (New-Object System.Management.Automation.PSCredential ("domain\username", (ConvertTo-SecureString "password" -AsPlainText -Force))))
            It "Should create a new service application in the set method when InstallAccount is used" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPProfileServiceApplication
            }
            $testParams.Remove("InstallAccount")
        }

        Context -Name "When service applications exist in the current farm but not the specific user profile service app" {

            Mock -CommandName Get-SPServiceApplication -MockWith { return @(@{
                TypeName = "Some other service app type"
            }) }

            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"  
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

       Context -Name "When service applications exist in the current farm and NetBios isn't enabled but it needs to be" {
        $testParamsEnableNetBIOS = @{
            Name = "User Profile Service App"
            ApplicationPool = "SharePoint Service Applications"
            EnableNetBIOS=$true
            FarmAccount = New-Object System.Management.Automation.PSCredential ("domain\username", (ConvertTo-SecureString "password" -AsPlainText -Force))
            Ensure = "Present"
        }
                Mock -CommandName Get-SPServiceApplication -MockWith { 
                return @(
                    New-Object -TypeName "Object" |            
                        Add-Member -MemberType NoteProperty TypeName "User Profile Service Application" -PassThru |
                        Add-Member -MemberType NoteProperty DisplayName $testParamsEnableNetBIOS.Name -PassThru | 
                        Add-Member -MemberType NoteProperty "NetBIOSDomainNamesEnabled" $false -PassThru |
                        Add-Member -MemberType ScriptMethod -Name Update -Value {$Global:SPUPSAUpdateCalled  = $true} -PassThru |
                        Add-Member -MemberType NoteProperty ApplicationPool @{ Name = $testParamsEnableNetBIOS.ApplicationPool } -PassThru |             
                        Add-Member -MemberType ScriptMethod GetType {
                            New-Object -TypeName "Object" |
                                Add-Member -MemberType ScriptMethod GetProperties {
                                    param($x)
                                    return @(
                                        (New-Object -TypeName "Object" |
                                            Add-Member -MemberType NoteProperty Name "SocialDatabase" -PassThru |
                                            Add-Member -MemberType ScriptMethod GetValue {
                                                param($x)
                                                return @{
                                                    Name = "SP_SocialDB"
                                                    Server = @{ Name = "SQL.domain.local" }
                                                }
                                            } -PassThru
                                        ),
                                        (New-Object -TypeName "Object" |
                                            Add-Member -MemberType NoteProperty Name "ProfileDatabase" -PassThru |
                                            Add-Member -MemberType ScriptMethod GetValue {
                                                return @{
                                                    Name = "SP_ProfileDB"
                                                    Server = @{ Name = "SQL.domain.local" }
                                                }
                                            } -PassThru
                                        ),
                                        (New-Object -TypeName "Object" |
                                            Add-Member -MemberType NoteProperty Name "SynchronizationDatabase" -PassThru |
                                            Add-Member -MemberType ScriptMethod GetValue {
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

            
            It "Should return false from the Get method" {
                (Get-TargetResource @testParamsEnableNetBIOS).EnableNetBIOS | Should Be $false  
            }
            It "Should call Update method on Service Application before finishing set  method" {
                $Global:SPUPSAUpdateCalled= $false
            
                Set-TargetResource @testParamsEnableNetBIOS
                $Global:SPUPSAUpdateCalled | Should Be $true  

            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParamsEnableNetBIOS | Should Be $false
            }

               It "Should return true when the Test method is called" {
               $testParamsEnableNetBIOS.EnableNetBIOS = $false
                Test-TargetResource @testParamsEnableNetBIOS | Should Be $true
            }
        }

        Context -Name "When a service application exists and is configured correctly" {
            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return @(
                    New-Object -TypeName "Object" |            
                        Add-Member -MemberType NoteProperty TypeName "User Profile Service Application" -PassThru |
                        Add-Member -MemberType NoteProperty DisplayName $testParams.Name -PassThru | 
                        Add-Member -MemberType NoteProperty "NetBIOSDomainNamesEnabled" $false -PassThru |
                        Add-Member -MemberType NoteProperty ApplicationPool @{ Name = $testParams.ApplicationPool } -PassThru |             
                        Add-Member -MemberType ScriptMethod GetType {
                            New-Object -TypeName "Object" |
                                Add-Member -MemberType ScriptMethod GetProperties {
                                    param($x)
                                    return @(
                                        (New-Object -TypeName "Object" |
                                            Add-Member -MemberType NoteProperty Name "SocialDatabase" -PassThru |
                                            Add-Member -MemberType ScriptMethod GetValue {
                                                param($x)
                                                return @{
                                                    Name = "SP_SocialDB"
                                                    Server = @{ Name = "SQL.domain.local" }
                                                }
                                            } -PassThru
                                        ),
                                        (New-Object -TypeName "Object" |
                                            Add-Member -MemberType NoteProperty Name "ProfileDatabase" -PassThru |
                                            Add-Member -MemberType ScriptMethod GetValue {
                                                return @{
                                                    Name = "SP_ProfileDB"
                                                    Server = @{ Name = "SQL.domain.local" }
                                                }
                                            } -PassThru
                                        ),
                                        (New-Object -TypeName "Object" |
                                            Add-Member -MemberType NoteProperty Name "SynchronizationDatabase" -PassThru |
                                            Add-Member -MemberType ScriptMethod GetValue {
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

            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"  
            }

            It "Should return true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }

            Mock -CommandName Get-SPFarm -MockWith { return @{
                DefaultServiceAccount = @{ Name = "WRONG\account" }
            }}

            It "Should return present from the get method where the farm account doesn't match" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"  
            }
        }
        
        $testParams = @{
            Name = "Test App"
            ApplicationPool = "-"
            Ensure = "Absent"
        }
        
        Context -Name "When the service app exists but it shouldn't" {
            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return @(
                    New-Object -TypeName "Object" |            
                        Add-Member -MemberType NoteProperty TypeName "User Profile Service Application" -PassThru |
                        Add-Member -MemberType NoteProperty DisplayName $testParams.Name -PassThru | 
                        Add-Member -MemberType NoteProperty "NetBIOSDomainNamesEnabled" -value $false -PassThru |
                        Add-Member -MemberType NoteProperty ApplicationPool @{ Name = $testParams.ApplicationPool } -PassThru |             
                        Add-Member -MemberType ScriptMethod GetType {
                            New-Object -TypeName "Object" |
                                Add-Member -MemberType ScriptMethod GetProperties {
                                    param($x)
                                    return @(
                                        (New-Object -TypeName "Object" |
                                            Add-Member -MemberType NoteProperty Name "SocialDatabase" -PassThru |
                                            Add-Member -MemberType ScriptMethod GetValue {
                                                param($x)
                                                return @{
                                                    Name = "SP_SocialDB"
                                                    Server = @{ Name = "SQL.domain.local" }
                                                }
                                            } -PassThru
                                        ),
                                        (New-Object -TypeName "Object" |
                                            Add-Member -MemberType NoteProperty Name "ProfileDatabase" -PassThru |
                                            Add-Member -MemberType ScriptMethod GetValue {
                                                return @{
                                                    Name = "SP_ProfileDB"
                                                    Server = @{ Name = "SQL.domain.local" }
                                                }
                                            } -PassThru
                                        ),
                                        (New-Object -TypeName "Object" |
                                            Add-Member -MemberType NoteProperty Name "SynchronizationDatabase" -PassThru |
                                            Add-Member -MemberType ScriptMethod GetValue {
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
            
            It "Should return present from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present" 
            }
            
            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "Should remove the service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPServiceApplication
            }
        }
        
        Context -Name "When the service app doesn't exist and shouldn't" {
            Mock -CommandName Get-SPServiceApplication -MockWith { return $null }
            
            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }
            
            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }    
}