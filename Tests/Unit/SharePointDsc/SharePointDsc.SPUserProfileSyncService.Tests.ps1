[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_SPUserProfileSyncService"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPUserProfileSyncService - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            UserProfileServiceAppName = "User Profile Service Service App"
            FarmAccount = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
            Ensure = "Present"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDsc")
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        $versionBeingTested = (Get-Item $Global:CurrentSharePointStubModule).Directory.BaseName
        $majorBuildNumber = $versionBeingTested.Substring(0, $versionBeingTested.IndexOf("."))
        Mock -CommandName Get-SPDSCInstalledProductVersion { return @{ FileMajorPart = $majorBuildNumber } }

        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        
        Mock -CommandName Get-SPFarm -MockWith { return @{
            DefaultServiceAccount = @{ Name = $testParams.FarmAccount.Username }
        }}
        Mock -CommandName Start-SPServiceInstance { }
        Mock Stop-SPServiceInstance { }
        Mock Restart-Service { }
        Mock -CommandName Add-SPDSCUserToLocalAdmin { } 
        Mock -CommandName Test-SPDSCUserIsLocalAdmin { return $false }
        Mock -CommandName Remove-SPDSCUserToLocalAdmin { }
        Mock -CommandName New-PSSession { return $null } -ModuleName "SharePointDsc.Util"
        Mock -CommandName Start-Sleep { }
        Mock -CommandName Get-SPServiceApplication -MockWith { 
            return @(
                New-Object -TypeName "Object" |            
                    Add-Member -MemberType NoteProperty TypeName "User Profile Service Application" -PassThru |
                    Add-Member -MemberType NoteProperty DisplayName $testParams.Name -PassThru | 
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

        switch ($majorBuildNumber) {
            15 {
                Context -Name "User profile sync service is not found locally" {
                    Mock -CommandName Get-SPServiceInstance { return $null }

                    It "Should return absent from the get method" {
                        $Global:SPDscUPACheck = $false
                        (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                    }
                }

                Context -Name "User profile sync service is not running and should be" {
                    Mock -CommandName Get-SPServiceInstance { if ($Global:SPDscUPACheck -eq $false) {
                            $Global:SPDscUPACheck = $true
                            return @( @{ 
                                Status = "Disabled"
                                ID = [Guid]::Parse("21946987-5163-418f-b781-2beb83aa191f")
                                UserProfileApplicationGuid = [Guid]::Empty
                                TypeName = "User Profile Synchronization Service" 
                            }) 
                        } else {
                            return @( @{ 
                                Status = "Online"
                                ID = [Guid]::Parse("21946987-5163-418f-b781-2beb83aa191f")
                                UserProfileApplicationGuid = [Guid]::NewGuid()
                                TypeName = "User Profile Synchronization Service" 
                            })
                        }
                    }
                    Mock -CommandName Get-SPServiceApplication -MockWith { return @(
                        New-Object -TypeName "Object" |            
                            Add-Member -MemberType NoteProperty ID ([Guid]::Parse("21946987-5163-418f-b781-2beb83aa191f")) -PassThru |
                            Add-Member -MemberType NoteProperty TypeName "User Profile Service Application" -PassThru |
                            Add-Member -MemberType ScriptMethod SetSynchronizationMachine {
                                param($computerName, $syncServiceID, $FarmUserName, $FarmPassword)
                            } -PassThru      
                    )} 

                    It "Should return absent from the get method" {
                        $Global:SPDscUPACheck = $false
                        (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                    }

                    It "Should return false from the test method" {
                        $Global:SPDscUPACheck = $false
                        Test-TargetResource @testParams | Should Be $false
                    }

                    It "Should call the start service cmdlet from the set method" {
                        $Global:SPDscUPACheck = $false
                        Set-TargetResource @testParams 

                        Assert-MockCalled Start-SPServiceInstance
                    }

                    Mock -CommandName Get-SPFarm -MockWith { return @{
                        DefaultServiceAccount = @{ Name = "WRONG\account" }
                    }}

                    It "Should return values from the get method where the farm account doesn't match" {
                        Get-TargetResource @testParams | Should Not BeNullOrEmpty
                    }

                    $Global:SPDscUPACheck = $false
                    Mock -CommandName Get-SPServiceApplication -MockWith { return $null } 
                    It "Should throw in the set method if the user profile service app can't be found" {
                        { Set-TargetResource @testParams } | Should Throw
                    }
                }

                Context -Name "User profile sync service is running and should be" {
                    Mock -CommandName Get-SPServiceInstance { return @( @{ 
                                Status = "Online"
                                ID = [Guid]::Parse("21946987-5163-418f-b781-2beb83aa191f")
                                UserProfileApplicationGuid = [Guid]::NewGuid()
                                TypeName = "User Profile Synchronization Service" 
                            })
                    } 
        
                    It "Should return present from the get method" {
                        (Get-TargetResource @testParams).Ensure | Should Be "Present"
                    }

                    It "Should return true from the test method" {
                        Test-TargetResource @testParams | Should Be $true
                    }
                }

                $testParams.Ensure = "Absent"

                Context -Name "User profile sync service is running and shouldn't be" {
                    Mock -CommandName Get-SPServiceInstance { if ($Global:SPDscUPACheck -eq $false) {
                            $Global:SPDscUPACheck = $true
                            return @( @{ 
                                Status = "Online"
                                ID = [Guid]::Parse("21946987-5163-418f-b781-2beb83aa191f")
                                UserProfileApplicationGuid = [Guid]::NewGuid()
                                TypeName = "User Profile Synchronization Service" 
                            }) 
                        } else {
                            return @( @{ 
                                Status = "Disabled"
                                ID = [Guid]::Empty
                                UserProfileApplicationGuid = [Guid]::Empty
                                TypeName = "User Profile Synchronization Service" 
                            })
                        }
                    } 

                    It "Should return present from the get method" {
                        $Global:SPDscUPACheck = $false
                        (Get-TargetResource @testParams).Ensure | Should Be "Present"
                    }

                    It "Should return false from the test method" {
                        $Global:SPDscUPACheck = $false
                        Test-TargetResource @testParams | Should Be $false
                    }

                    It "Should call the stop service cmdlet from the set method" {
                        $Global:SPDscUPACheck = $false
                        Set-TargetResource @testParams 

                        Assert-MockCalled Stop-SPServiceInstance
                    }
                }

                Context -Name "User profile sync service is not running and shouldn't be" {
                    Mock -CommandName Get-SPServiceInstance { return @( @{ 
                            Status = "Disabled"
                            ID = [Guid]::Parse("21946987-5163-418f-b781-2beb83aa191f")
                            UserProfileApplicationGuid = [Guid]::Empty
                            TypeName = "User Profile Synchronization Service" 
                        })
                    } 

                    It "Should return absent from the get method" {
                        (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                    }

                    It "Should return true from the test method" {
                        Test-TargetResource @testParams | Should Be $true
                    }
                }



                $testParams.Ensure = "Present"
                $testParams.Add("RunOnlyWhenWriteable", $true)
                Context -Name "User profile sync service is not running and shouldn't be because the database is read only" {
                    Mock -CommandName Get-SPServiceInstance { return @( @{ 
                            Status = "Disabled"
                            ID = [Guid]::Parse("21946987-5163-418f-b781-2beb83aa191f")
                            UserProfileApplicationGuid = [Guid]::Empty
                            TypeName = "User Profile Synchronization Service" 
                        })
                    }

                    Mock -CommandName Get-SPDatabase -MockWith {
                        return @(
                            @{
                                Name = "SP_ProfileDB"
                                IsReadyOnly = $true
                            }
                        )
                    } 

                    It "Should return absent from the get method" {
                        (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                    }

                    It "Should return true from the test method" {
                        Test-TargetResource @testParams | Should Be $true
                    }
                }

                Context -Name "User profile sync service is running and shouldn't be because the database is read only" {
                    Mock -CommandName Get-SPServiceInstance { return @( @{ 
                                Status = "Online"
                                ID = [Guid]::Parse("21946987-5163-418f-b781-2beb83aa191f")
                                UserProfileApplicationGuid = [Guid]::NewGuid()
                                TypeName = "User Profile Synchronization Service" 
                            })
                    } 

                    Mock -CommandName Get-SPDatabase -MockWith {
                        return @(
                            @{
                                Name = "SP_ProfileDB"
                                IsReadyOnly = $true
                            }
                        )
                    } 

                    It "Should return absent from the get method" {
                        (Get-TargetResource @testParams).Ensure | Should Be "Present"
                    }

                    It "Should return true from the test method" {
                        Test-TargetResource @testParams | Should Be $false
                    }

                    It "Should call the stop service cmdlet from the set method" {
                        $Global:SPDscUPACheck = $false
                        Set-TargetResource @testParams 

                        Assert-MockCalled Stop-SPServiceInstance
                    }
                }
            }
            16 {
                Context -Name "All methods throw exceptions as user profile sync doesn't exist in 2016" {
                    It "Should throw on the get method" {
                        { Get-TargetResource @testParams } | Should Throw
                    }

                    It "Should throw on the test method" {
                        { Test-TargetResource @testParams } | Should Throw
                    }

                    It "Should throw on the set method" {
                        { Set-TargetResource @testParams } | Should Throw
                    }
                }
            }
        }
        


        

        
    }    
}