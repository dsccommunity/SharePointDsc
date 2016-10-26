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
                                              -DscResource "SPUserProfileServiceApp"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests
        $getTypeFullName = "Microsoft.Office.Server.Administration.UserProfileApplication"
        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
        $mockCredential = New-Object -TypeName System.Management.Automation.PSCredential `
                                     -ArgumentList @("DOMAIN\username", $mockPassword)

        # Mocks for all contexts   
        Mock -CommandName Get-SPFarm -MockWith { 
            return @{
                DefaultServiceAccount = @{ 
                    Name = $mockCredential.Username 
                }
            }
        }
        Mock -CommandName New-SPProfileServiceApplication -MockWith { 
            return (@{
                NetBIOSDomainNamesEnabled =  $false}
            )
        } 
        Mock -CommandName New-SPProfileServiceApplicationProxy -MockWith { }
        Mock -CommandName Add-SPDSCUserToLocalAdmin -MockWith { } 
        Mock -CommandName Test-SPDSCUserIsLocalAdmin -MockWith { return $false }
        Mock -CommandName Remove-SPDSCUserToLocalAdmin -MockWith { }
        Mock -CommandName Remove-SPServiceApplication -MockWith { } 

        # Test contexts
        Context -Name "When no service applications exist in the current farm" -Fixture {
            $testParams = @{
                Name = "User Profile Service App"
                ApplicationPool = "SharePoint Service Applications"
                FarmAccount = $mockCredential
                Ensure = "Present"
            } 

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return $null 
            }

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
        }

        Context -Name "When service applications exist in the current farm but not the specific user profile service app" -Fixture {
            $testParams = @{
                Name = "User Profile Service App"
                ApplicationPool = "SharePoint Service Applications"
                FarmAccount = $mockCredential
                Ensure = "Present"
            } 

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                $spServiceApp = [PSCustomObject]@{ 
                                    DisplayName = $testParams.Name 
                                } 
                $spServiceApp | Add-Member -MemberType ScriptMethod `
                                           -Name GetType `
                                           -Value {  
                                                return @{ 
                                                    FullName = "Microsoft.Office.UnKnownWebServiceApplication" 
                                                }  
                                            } -PassThru -Force 
                return $spServiceApp 
            }

            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"  
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context -Name "When service applications exist in the current farm and NetBios isn't enabled but it needs to be" -Fixture {
            $testParams = @{
                Name = "User Profile Service App"
                ApplicationPool = "SharePoint Service Applications"
                EnableNetBIOS = $true
                FarmAccount = $mockCredential
                Ensure = "Present"
            }
            
            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return @(
                    New-Object -TypeName "Object" |            
                        Add-Member -MemberType NoteProperty `
                                   -Name TypeName `
                                   -Value "User Profile Service Application" `
                                   -PassThru |
                        Add-Member -MemberType NoteProperty `
                                   -Name DisplayName `
                                   -Value $testParams.Name `
                                   -PassThru | 
                        Add-Member -MemberType NoteProperty `
                                   -Name "NetBIOSDomainNamesEnabled" `
                                   -Value $false `
                                   -PassThru |
                        Add-Member -MemberType ScriptMethod `
                                   -Name Update `
                                   -Value {
                                       $Global:SPDscUPSAUpdateCalled  = $true
                                    } -PassThru |
                        Add-Member -MemberType NoteProperty `
                                   -Name ApplicationPool `
                                   -Value @{ 
                                       Name = $testParams.ApplicationPool 
                                    } -PassThru |             
                        Add-Member -MemberType ScriptMethod `
                                   -Name GetType `
                                   -Value {
                                        New-Object -TypeName "Object" |
                                            Add-Member -MemberType NoteProperty `
                                                       -Name FullName `
                                                       -Value $getTypeFullName `
                                                       -PassThru | 
                                            Add-Member -MemberType ScriptMethod `
                                                       -Name GetProperties `
                                                       -Value {
                                                            param($x)
                                                            return @(
                                                                (New-Object -TypeName "Object" |
                                                                    Add-Member -MemberType NoteProperty `
                                                                               -Name Name `
                                                                               -Value "SocialDatabase" `
                                                                               -PassThru |
                                                                    Add-Member -MemberType ScriptMethod `
                                                                               -Name GetValue `
                                                                               -Value {
                                                                                    param($x)
                                                                                    return @{
                                                                                        Name = "SP_SocialDB"
                                                                                        Server = @{ 
                                                                                            Name = "SQL.domain.local" 
                                                                                        }
                                                                                    }
                                                                                } -PassThru
                                                                ),
                                                                (New-Object -TypeName "Object" |
                                                                    Add-Member -MemberType NoteProperty `
                                                                               -Name Name `
                                                                               -Value "ProfileDatabase" `
                                                                               -PassThru |
                                                                    Add-Member -MemberType ScriptMethod `
                                                                               -Name GetValue `
                                                                               -Value {
                                                                                    return @{
                                                                                        Name = "SP_ProfileDB"
                                                                                        Server = @{ 
                                                                                            Name = "SQL.domain.local" 
                                                                                        }
                                                                                    }
                                                                                } -PassThru
                                                                ),
                                                                (New-Object -TypeName "Object" |
                                                                    Add-Member -MemberType NoteProperty `
                                                                               -Name Name `
                                                                               -Value "SynchronizationDatabase" `
                                                                               -PassThru |
                                                                    Add-Member -MemberType ScriptMethod `
                                                                               -Name GetValue `
                                                                               -Value {
                                                                                    return @{
                                                                                        Name = "SP_ProfileSyncDB"
                                                                                        Server = @{ 
                                                                                            Name = "SQL.domain.local" 
                                                                                        }
                                                                                    }
                                                                                } -PassThru
                                                                )
                                                            )
                                                        } -PassThru
                                    } -PassThru -Force 
                )
            }
            
            It "Should return false from the Get method" {
                (Get-TargetResource @testParams).EnableNetBIOS | Should Be $false  
            }

            It "Should call Update method on Service Application before finishing set method" {
                $Global:SPDscUPSAUpdateCalled = $false            
                Set-TargetResource @testParams
                $Global:SPDscUPSAUpdateCalled | Should Be $true  
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should return true when the Test method is called" {
                $testParams.EnableNetBIOS = $false
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "When a service application exists and is configured correctly" -Fixture {
            $testParams = @{
                Name = "User Profile Service App"
                ApplicationPool = "SharePoint Service Applications"
                FarmAccount = $mockCredential
                Ensure = "Present"
            } 

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return @(
                    New-Object -TypeName "Object" |            
                        Add-Member -MemberType NoteProperty `
                                   -Name TypeName `
                                   -Value "User Profile Service Application" `
                                   -PassThru |
                        Add-Member -MemberType NoteProperty `
                                   -Name DisplayName `
                                   -Value $testParams.Name `
                                   -PassThru | 
                        Add-Member -MemberType NoteProperty `
                                   -Name "NetBIOSDomainNamesEnabled" `
                                   -Value $false `
                                   -PassThru |
                        Add-Member -MemberType ScriptMethod `
                                   -Name Update `
                                   -Value {
                                       $Global:SPDscUPSAUpdateCalled  = $true
                                    } -PassThru |
                        Add-Member -MemberType NoteProperty `
                                   -Name ApplicationPool `
                                   -Value @{ 
                                       Name = $testParams.ApplicationPool 
                                    } -PassThru |             
                        Add-Member -MemberType ScriptMethod `
                                   -Name GetType `
                                   -Value {
                                        New-Object -TypeName "Object" |
                                            Add-Member -MemberType NoteProperty `
                                                       -Name FullName `
                                                       -Value $getTypeFullName `
                                                       -PassThru |
                                            Add-Member -MemberType ScriptMethod `
                                                       -Name GetProperties `
                                                       -Value {
                                                            param($x)
                                                            return @(
                                                                (New-Object -TypeName "Object" |
                                                                    Add-Member -MemberType NoteProperty `
                                                                               -Name Name `
                                                                               -Value "SocialDatabase" `
                                                                               -PassThru |
                                                                    Add-Member -MemberType ScriptMethod `
                                                                               -Name GetValue `
                                                                               -Value {
                                                                                    param($x)
                                                                                    return @{
                                                                                        Name = "SP_SocialDB"
                                                                                        Server = @{ 
                                                                                            Name = "SQL.domain.local" 
                                                                                        }
                                                                                    }
                                                                                } -PassThru
                                                                ),
                                                                (New-Object -TypeName "Object" |
                                                                    Add-Member -MemberType NoteProperty `
                                                                               -Name Name `
                                                                               -Value "ProfileDatabase" `
                                                                               -PassThru |
                                                                    Add-Member -MemberType ScriptMethod `
                                                                               -Name GetValue `
                                                                               -Value {
                                                                                    return @{
                                                                                        Name = "SP_ProfileDB"
                                                                                        Server = @{ 
                                                                                            Name = "SQL.domain.local" 
                                                                                        }
                                                                                    }
                                                                                } -PassThru
                                                                ),
                                                                (New-Object -TypeName "Object" |
                                                                    Add-Member -MemberType NoteProperty `
                                                                               -Name Name `
                                                                               -Value "SynchronizationDatabase" `
                                                                               -PassThru |
                                                                    Add-Member -MemberType ScriptMethod `
                                                                               -Name GetValue `
                                                                               -Value {
                                                                                    return @{
                                                                                        Name = "SP_ProfileSyncDB"
                                                                                        Server = @{ 
                                                                                            Name = "SQL.domain.local" 
                                                                                        }
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
        
        Context -Name "When the service app exists but it shouldn't" -Fixture {
            $testParams = @{
                Name = "Test App"
                ApplicationPool = "-"
                Ensure = "Absent"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return @(
                    New-Object -TypeName "Object" |            
                        Add-Member -MemberType NoteProperty `
                                   -Name TypeName `
                                   -Value "User Profile Service Application" `
                                   -PassThru |
                        Add-Member -MemberType NoteProperty `
                                   -Name DisplayName `
                                   -Value $testParams.Name `
                                   -PassThru | 
                        Add-Member -MemberType NoteProperty `
                                   -Name "NetBIOSDomainNamesEnabled" `
                                   -Value $false `
                                   -PassThru |
                        Add-Member -MemberType ScriptMethod `
                                   -Name Update `
                                   -Value {
                                       $Global:SPDscUPSAUpdateCalled  = $true
                                    } -PassThru |
                        Add-Member -MemberType NoteProperty `
                                   -Name ApplicationPool `
                                   -Value @{ 
                                       Name = $testParams.ApplicationPool 
                                    } -PassThru |             
                        Add-Member -MemberType ScriptMethod `
                                   -Name GetType `
                                   -Value {
                                        New-Object -TypeName "Object" |
                                            Add-Member -MemberType NoteProperty `
                                                       -Name FullName `
                                                       -Value $getTypeFullName `
                                                       -PassThru |
                                            Add-Member -MemberType ScriptMethod `
                                                       -Name GetProperties `
                                                       -Value {
                                                            param($x)
                                                            return @(
                                                                (New-Object -TypeName "Object" |
                                                                    Add-Member -MemberType NoteProperty `
                                                                               -Name Name `
                                                                               -Value "SocialDatabase" `
                                                                               -PassThru |
                                                                    Add-Member -MemberType ScriptMethod `
                                                                               -Name GetValue `
                                                                               -Value {
                                                                                    param($x)
                                                                                    return @{
                                                                                        Name = "SP_SocialDB"
                                                                                        Server = @{ 
                                                                                            Name = "SQL.domain.local" 
                                                                                        }
                                                                                    }
                                                                                } -PassThru
                                                                ),
                                                                (New-Object -TypeName "Object" |
                                                                    Add-Member -MemberType NoteProperty `
                                                                               -Name Name `
                                                                               -Value "ProfileDatabase" `
                                                                               -PassThru |
                                                                    Add-Member -MemberType ScriptMethod `
                                                                               -Name GetValue `
                                                                               -Value {
                                                                                    return @{
                                                                                        Name = "SP_ProfileDB"
                                                                                        Server = @{ 
                                                                                            Name = "SQL.domain.local" 
                                                                                        }
                                                                                    }
                                                                                } -PassThru
                                                                ),
                                                                (New-Object -TypeName "Object" |
                                                                    Add-Member -MemberType NoteProperty `
                                                                               -Name Name `
                                                                               -Value "SynchronizationDatabase" `
                                                                               -PassThru |
                                                                    Add-Member -MemberType ScriptMethod `
                                                                               -Name GetValue `
                                                                               -Value {
                                                                                    return @{
                                                                                        Name = "SP_ProfileSyncDB"
                                                                                        Server = @{ 
                                                                                            Name = "SQL.domain.local" 
                                                                                        }
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
        
        Context -Name "When the service app doesn't exist and shouldn't" -Fixture {
            $testParams = @{
                Name = "Test App"
                ApplicationPool = "-"
                Ensure = "Absent"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return $null 
            }
            
            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }
            
            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
