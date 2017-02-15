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
                                              -DscResource "SPUserProfileSyncService"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests
        $getTypeFullName = "Microsoft.Office.Server.Administration.UserProfileApplication"
        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
        $mockCredential = New-Object -TypeName System.Management.Automation.PSCredential `
                                     -ArgumentList @("DOMAIN\username", $mockPassword)

        # Mocks for all contexts   
        Mock -CommandName Get-SPFarm -MockWith { return @{
            DefaultServiceAccount = @{ 
                Name = $mockCredential.UserName
            }
        }}
        Mock -CommandName Start-SPServiceInstance -MockWith { }
        Mock -CommandName Stop-SPServiceInstance -MockWith { }
        Mock -CommandName Restart-Service -MockWith { }
        Mock -CommandName Add-SPDSCUserToLocalAdmin -MockWith { } 
        Mock -CommandName Test-SPDSCUserIsLocalAdmin -MockWith { 
            return $false 
        }
        Mock -CommandName Remove-SPDSCUserToLocalAdmin -MockWith { }
        Mock -CommandName Start-Sleep -MockWith { }
        Mock -CommandName Get-SPServiceApplication -MockWith { 
            return @(
                New-Object -TypeName "Object" |            
                    Add-Member -MemberType NoteProperty `
                               -Name TypeName `
                               -Value "User Profile Service Application" `
                               -PassThru |
                    Add-Member -MemberType NoteProperty `
                               -Name DisplayName `
                               -Value "User Profile Service Service App" `
                               -PassThru | 
                    Add-Member -MemberType NoteProperty `
                               -Name ApplicationPool `
                               -Value @{ 
                                   Name = "Service Pool"
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

        # Test contexts
        switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major) 
        {
            15 {
                Context -Name "User profile sync service is not found locally" -Fixture {
                    $testParams = @{
                        UserProfileServiceAppName = "User Profile Service Service App"
                        FarmAccount = $mockCredential
                        Ensure = "Present"
                    }

                    Mock -CommandName Get-SPServiceInstance -MockWith { 
                        return $null 
                    }

                    It "Should return absent from the get method" {
                        $Global:SPDscUPACheck = $false
                        (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                    }
                }

                Context -Name "User profile sync service is not running and should be" -Fixture {
                    $testParams = @{
                        UserProfileServiceAppName = "User Profile Service Service App"
                        FarmAccount = $mockCredential
                        Ensure = "Present"
                    }

                    Mock -CommandName Get-SPServiceInstance -MockWith {
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

                    Mock -CommandName Get-SPServiceApplication -MockWith { 
                        return @(
                            New-Object -TypeName "Object" |            
                                Add-Member -MemberType NoteProperty `
                                           -Name ID `
                                           -Value ([Guid]::Parse("21946987-5163-418f-b781-2beb83aa191f")) `
                                           -PassThru |
                                Add-Member -MemberType ScriptMethod `
                                           -Name GetType `
                                           -Value {
                                   New-Object -TypeName "Object" |
                                        Add-Member -MemberType NoteProperty `
                                                   -Name FullName `
                                                   -Value $getTypeFullName `
                                                   -PassThru
                                           } `
                                           -PassThru -Force |
                                Add-Member -MemberType ScriptMethod `
                                           -Name SetSynchronizationMachine `
                                           -Value {
                                                param(
                                                    $computerName, 
                                                    $syncServiceID, 
                                                    $FarmUserName, 
                                                    $FarmPassword
                                                )
                                            } -PassThru
                        )
                    } 

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

                    Mock -CommandName Get-SPFarm -MockWith { 
                        return @{
                            DefaultServiceAccount = @{ Name = "WRONG\account" }
                        }
                    }

                    It "Should return values from the get method where the farm account doesn't match" {
                        Get-TargetResource @testParams | Should Not BeNullOrEmpty
                    }

                    $Global:SPDscUPACheck = $false
                    Mock -CommandName Get-SPServiceApplication -MockWith { 
                        return $null 
                    }

                    It "Should throw in the set method if the user profile service app can't be found" {
                        { Set-TargetResource @testParams } | Should Throw
                    }
                }

                Context -Name "User profile sync service is running and should be" -Fixture {
                    $testParams = @{
                        UserProfileServiceAppName = "User Profile Service Service App"
                        FarmAccount = $mockCredential
                        Ensure = "Present"
                    }

                    Mock -CommandName Get-SPServiceInstance -MockWith { 
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
        
                    It "Should return present from the get method" {
                        (Get-TargetResource @testParams).Ensure | Should Be "Present"
                    }

                    It "Should return true from the test method" {
                        Test-TargetResource @testParams | Should Be $true
                    }
                }
                
                Context -Name "User profile sync service is running and shouldn't be" -Fixture {
                    $testParams = @{
                        UserProfileServiceAppName = "User Profile Service Service App"
                        FarmAccount = $mockCredential
                        Ensure = "Absent"
                    }

                    Mock -CommandName Get-SPServiceInstance -MockWith { 
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

                Context -Name "User profile sync service is not running and shouldn't be" -Fixture {
                    $testParams = @{
                        UserProfileServiceAppName = "User Profile Service Service App"
                        FarmAccount = $mockCredential
                        Ensure = "Absent"
                    }

                    Mock -CommandName Get-SPServiceInstance -MockWith { 
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

                    It "Should return absent from the get method" {
                        (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                    }

                    It "Should return true from the test method" {
                        Test-TargetResource @testParams | Should Be $true
                    }
                }

                Context -Name "User profile sync service is not running and shouldn't be because the database is read only" -Fixture {
                    $testParams = @{
                        UserProfileServiceAppName = "User Profile Service Service App"
                        FarmAccount = $mockCredential
                        Ensure = "Present"
                        RunOnlyWhenWriteable = $true
                    }

                    Mock -CommandName Get-SPServiceInstance -MockWith { 
                        $spSvcInstance = [pscustomobject]@{
                            ID = [Guid]::Parse("21946987-5163-418f-b781-2beb83aa191f")
                        }
                        $spSvcInstance = $spSvcInstance | Add-Member ScriptMethod GetType { 
                            return @{ Name = "UserProfileServiceInstance" } 
                        } -PassThru -Force
                        $spSvcInstance = $spSvcInstance | Add-Member NoteProperty Status "Disabled" -PassThru
                        $spSvcInstance = $spSvcInstance | Add-Member NoteProperty UserProfileApplicationGuid ([Guid]::NewGuid()) -PassThru
                        return $spSvcInstance
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

                Context -Name "User profile sync service is running and shouldn't be because the database is read only" -Fixture {
                    $testParams = @{
                        UserProfileServiceAppName = "User Profile Service Service App"
                        FarmAccount = $mockCredential
                        Ensure = "Present"
                        RunOnlyWhenWriteable = $true
                    }

                    Mock -CommandName Get-SPServiceInstance -MockWith { 
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

                    Mock -CommandName Get-SPDatabase -MockWith {
                        return @(
                            @{
                                Name = "SP_ProfileDB"
                                IsReadyOnly = $true
                            }
                        )
                    } 

                    It "Should return present from the get method" {
                        (Get-TargetResource @testParams).Ensure | Should Be "Present"
                    }

                    It "Should return false from the test method" {
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
                Context -Name "All methods throw exceptions as user profile sync doesn't exist in 2016" -Fixture {
                    $testParams = @{
                        UserProfileServiceAppName = "User Profile Service Service App"
                        FarmAccount = $mockCredential
                    }

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

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
