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
        $getTypeFullName = "Microsoft.Office.Server.Administration.UserProfileApplication"

        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDsc")
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        $versionBeingTested = (Get-Item $Global:CurrentSharePointStubModule).Directory.BaseName
        $majorBuildNumber = $versionBeingTested.Substring(0, $versionBeingTested.IndexOf("."))
        Mock Get-SPDSCInstalledProductVersion { return @{ FileMajorPart = $majorBuildNumber } }

        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        
        Mock Get-SPFarm { return @{
            DefaultServiceAccount = @{ Name = $testParams.FarmAccount.Username }
        }}
        Mock Start-SPServiceInstance { }
        Mock Stop-SPServiceInstance { }
        Mock Restart-Service { }
        Mock Add-SPDSCUserToLocalAdmin { } 
        Mock Test-SPDSCUserIsLocalAdmin { return $false }
        Mock Remove-SPDSCUserToLocalAdmin { }
        Mock New-PSSession { return $null } -ModuleName "SharePointDsc.Util"
        Mock Start-Sleep { }
        Mock Get-SPServiceApplication { 
            return @(
                New-Object Object |            
                    Add-Member NoteProperty DisplayName $testParams.Name -PassThru | 
                    Add-Member NoteProperty ApplicationPool @{ Name = $testParams.ApplicationPool } -PassThru |             
                    Add-Member ScriptMethod GetType {
                        New-Object Object |
                            Add-Member NoteProperty FullName $getTypeFullName -PassThru -Force |
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

        switch ($majorBuildNumber) {
            15 {
                Context "User profile sync service is not found locally" {
                    Mock Get-SPServiceInstance { return $null }

                    It "returns absent from the get method" {
                        $Global:SPDSCUPACheck = $false
                        (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                    }
                }

                Context "User profile sync service is not running and should be" {
                    Mock Get-SPServiceInstance {
                        $spSvcInstance = [pscustomobject]@{
                            ID = [Guid]::Parse("21946987-5163-418f-b781-2beb83aa191f")
                        }
                        $spSvcInstance = $spSvcInstance | Add-Member ScriptMethod GetType { 
                            return @{ Name = "UserProfileServiceInstance" } 
                        } -PassThru -Force
                        if ($Global:SPDSCUPACheck -eq $false) 
                        {
                            $Global:SPDSCUPACheck = $true
                            $spSvcInstance = $spSvcInstance | Add-Member NoteProperty Status "Disabled" -PassThru
                            $spSvcInstance = $spSvcInstance | Add-Member NoteProperty UserProfileApplicationGuid [Guid]::Empty -PassThru
                        } 
                        else
                        {
                            $spSvcInstance = $spSvcInstance | Add-Member NoteProperty Status "Online" -PassThru
                            $spSvcInstance = $spSvcInstance | Add-Member NoteProperty UserProfileApplicationGuid ([Guid]::NewGuid()) -PassThru
                        }
                        return $spSvcInstance
                    }

                    Mock Get-SPServiceApplication {
                        $spServiceApp = [pscustomobject]@{
                            ID = [Guid]::Parse("21946987-5163-418f-b781-2beb83aa191f")
                        }
                        $spServiceApp = $spServiceApp | Add-Member ScriptMethod SetSynchronizationMachine { 
                            param($computerName, $syncServiceID, $FarmUserName, $FarmPassword) 
                        } -PassThru -Force
                        $spServiceApp = $spServiceApp | Add-Member ScriptMethod GetType { 
                            return @{ FullName = $getTypeFullName } 
                        } -PassThru -Force
                        return $spServiceApp
                    }

                    It "returns absent from the get method" {
                        $Global:SPDSCUPACheck = $false
                        (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                    }

                    It "returns false from the test method" {
                        $Global:SPDSCUPACheck = $false
                        Test-TargetResource @testParams | Should Be $false
                    }

                    It "calls the start service cmdlet from the set method" {
                        $Global:SPDSCUPACheck = $false
                        Set-TargetResource @testParams 

                        Assert-MockCalled Start-SPServiceInstance
                    }

                    Mock Get-SPFarm { return @{
                        DefaultServiceAccount = @{ Name = "WRONG\account" }
                    }}

                    It "returns values from the get method where the farm account doesn't match" {
                        Get-TargetResource @testParams | Should Not BeNullOrEmpty
                    }

                    $Global:SPDSCUPACheck = $false
                    Mock Get-SPServiceApplication { return $null } 
                    It "throws in the set method if the user profile service app can't be found" {
                        { Set-TargetResource @testParams } | Should Throw
                    }
                }

                Context "User profile sync service is running and should be" {
                    Mock Get-SPServiceInstance {
                        $spSvcInstance = [pscustomobject]@{
                            ID = [Guid]::Parse("21946987-5163-418f-b781-2beb83aa191f")
                        }
                        $spSvcInstance = $spSvcInstance | Add-Member ScriptMethod GetType { 
                            return @{ Name = "UserProfileServiceInstance" } 
                        } -PassThru -Force
                        $spSvcInstance = $spSvcInstance | Add-Member NoteProperty Status "Online" -PassThru
                        $spSvcInstance = $spSvcInstance | Add-Member NoteProperty UserProfileApplicationGuid ([Guid]::NewGuid()) -PassThru
                        return $spSvcInstance
                    }

                    It "returns present from the get method" {
                        (Get-TargetResource @testParams).Ensure | Should Be "Present"
                    }

                    It "returns true from the test method" {
                        Test-TargetResource @testParams | Should Be $true
                    }
                }

                $testParams.Ensure = "Absent"

                Context "User profile sync service is running and shouldn't be" {
                    Mock Get-SPServiceInstance {
                        $spSvcInstance = [pscustomobject]@{
                            ID = [Guid]::Parse("21946987-5163-418f-b781-2beb83aa191f")
                        }
                        $spSvcInstance = $spSvcInstance | Add-Member ScriptMethod GetType { 
                            return @{ Name = "UserProfileServiceInstance" } 
                        } -PassThru -Force
                        if ($Global:SPDSCUPACheck -eq $false) 
                        {
                            $Global:SPDSCUPACheck = $true
                            $spSvcInstance = $spSvcInstance | Add-Member NoteProperty Status "Online" -PassThru
                            $spSvcInstance = $spSvcInstance | Add-Member NoteProperty UserProfileApplicationGuid ([Guid]::NewGuid()) -PassThru
                        } 
                        else
                        {
                            $spSvcInstance = $spSvcInstance | Add-Member NoteProperty Status "Disabled" -PassThru
                            $spSvcInstance = $spSvcInstance | Add-Member NoteProperty UserProfileApplicationGuid [Guid]::Empty -PassThru
                        }
                        return $spSvcInstance
                    }

                    It "returns present from the get method" {
                        $Global:SPDSCUPACheck = $false
                        (Get-TargetResource @testParams).Ensure | Should Be "Present"
                    }

                    It "returns false from the test method" {
                        $Global:SPDSCUPACheck = $false
                        Test-TargetResource @testParams | Should Be $false
                    }

                    It "calls the stop service cmdlet from the set method" {
                        $Global:SPDSCUPACheck = $false
                        Set-TargetResource @testParams 

                        Assert-MockCalled Stop-SPServiceInstance
                    }
                }

                Context "User profile sync service is not running and shouldn't be" {
                    Mock Get-SPServiceInstance {
                        $spSvcInstance = [pscustomobject]@{
                            ID = [Guid]::Parse("21946987-5163-418f-b781-2beb83aa191f")
                        }
                        $spSvcInstance = $spSvcInstance | Add-Member ScriptMethod GetType { 
                            return @{ Name = "UserProfileServiceInstance" } 
                        } -PassThru -Force
                        $spSvcInstance = $spSvcInstance | Add-Member NoteProperty Status "Disabled" -PassThru
                        $spSvcInstance = $spSvcInstance | Add-Member NoteProperty UserProfileApplicationGuid [Guid]::Empty -PassThru
                        return $spSvcInstance
                    }

                    It "returns absent from the get method" {
                        (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                    }

                    It "returns true from the test method" {
                        Test-TargetResource @testParams | Should Be $true
                    }
                }

                $testParams.Ensure = "Present"
                $testParams.Add("RunOnlyWhenWriteable", $true)

                Context "User profile sync service is not running and shouldn't be because the database is read only" {
                    Mock Get-SPServiceInstance {
                        $spSvcInstance = [pscustomobject]@{
                            ID = [Guid]::Parse("21946987-5163-418f-b781-2beb83aa191f")
                        }
                        $spSvcInstance = $spSvcInstance | Add-Member ScriptMethod GetType { 
                            return @{ Name = "UserProfileServiceInstance" } 
                        } -PassThru -Force
                        $spSvcInstance = $spSvcInstance | Add-Member NoteProperty Status "Disabled" -PassThru
                        $spSvcInstance = $spSvcInstance | Add-Member NoteProperty UserProfileApplicationGuid [Guid]::Empty -PassThru
                        return $spSvcInstance
                    }

                    Mock Get-SPDatabase {
                        return @(
                            @{
                                Name = "SP_ProfileDB"
                                IsReadyOnly = $true
                            }
                        )
                    } 

                    It "returns absent from the get method" {
                        (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                    }

                    It "returns true from the test method" {
                        Test-TargetResource @testParams | Should Be $true
                    }
                }

                Context "User profile sync service is running and shouldn't be because the database is read only" {
                    Mock Get-SPServiceInstance {
                        $spSvcInstance = [pscustomobject]@{
                            ID = [Guid]::Parse("21946987-5163-418f-b781-2beb83aa191f")
                        }
                        $spSvcInstance = $spSvcInstance | Add-Member ScriptMethod GetType { 
                            return @{ Name = "UserProfileServiceInstance" } 
                        } -PassThru -Force
                        $spSvcInstance = $spSvcInstance | Add-Member NoteProperty Status "Online" -PassThru
                        $spSvcInstance = $spSvcInstance | Add-Member NoteProperty UserProfileApplicationGuid ([Guid]::NewGuid()) -PassThru
                        return $spSvcInstance
                    }

                    Mock Get-SPDatabase {
                        return @(
                            @{
                                Name = "SP_ProfileDB"
                                IsReadyOnly = $true
                            }
                        )
                    } 

                    It "returns absent from the get method" {
                        (Get-TargetResource @testParams).Ensure | Should Be "Present"
                    }

                    It "returns true from the test method" {
                        Test-TargetResource @testParams | Should Be $false
                    }

                    It "calls the stop service cmdlet from the set method" {
                        $Global:SPDSCUPACheck = $false
                        Set-TargetResource @testParams 

                        Assert-MockCalled Stop-SPServiceInstance
                    }
                }
            }

            16 {
                Context "All methods throw exceptions as user profile sync doesn't exist in 2016" {
                    It "throws on the get method" {
                        { Get-TargetResource @testParams } | Should Throw
                    }

                    It "throws on the test method" {
                        { Test-TargetResource @testParams } | Should Throw
                    }

                    It "throws on the set method" {
                        { Set-TargetResource @testParams } | Should Throw
                    }
                }
            }
        }          
    }    
}
