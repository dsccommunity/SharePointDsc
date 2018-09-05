[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
                                         -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
                                         -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
                                -ChildPath "..\UnitTestHelper.psm1" `
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
                                     -ArgumentList @("$($Env:USERDOMAIN)\$($Env:USERNAME)", $mockPassword)
        $mockFarmCredential = New-Object -TypeName System.Management.Automation.PSCredential `
                                         -ArgumentList @("DOMAIN\sp_farm", $mockPassword)

        try { [Microsoft.Office.Server.UserProfiles.UserProfileManager] }
        catch {
            try {
                Add-Type -TypeDefinition @"
                    namespace Microsoft.Office.Server.UserProfiles {
                        public class UserProfileManager {
                            public UserProfileManager(System.Object a)
                            {
                            }

                            public string PersonalSiteFormat
                            {
                                get
                                {
                                    return "Domain_Username";
                                }
                                set
                                {
                                }
                            }
                        }
                    }
"@ -ErrorAction SilentlyContinue
            }
            catch {
                Write-Verbose -Message "The Type Microsoft.Office.Server.UserProfiles.DirectoryServiceNamingContext was already added."
            }
        }
        # Mocks for all contexts
        Mock -CommandName Get-SPDSCFarmAccount -MockWith {
            return $mockFarmCredential
        }
        Mock -CommandName New-SPProfileServiceApplication -MockWith {
            return (@{
                NetBIOSDomainNamesEnabled =  $false
                NoILMUsed = $false
            }
            )
        }
        Mock -CommandName New-SPProfileServiceApplicationProxy -MockWith { }
        Mock -CommandName Add-SPDSCUserToLocalAdmin -MockWith { }
        Mock -CommandName Test-SPDSCUserIsLocalAdmin -MockWith { return $false }
        Mock -CommandName Remove-SPDSCUserToLocalAdmin -MockWith { }
        Mock -CommandName Remove-SPServiceApplication -MockWith { }

        Mock -CommandName Get-SPWebApplication -MockWith {
            return @{
                IsAdministrationWebApplication = $true
                Url = "http://fake.contoso.com"
                Sites = @("FakeSite1")
            }
        }
        Mock -CommandName Get-SPServiceContext -MockWith {
            return (@{
                Fake1 = $true
            })
        }

        # Test contexts
        Context -Name "When PSDSCRunAsCredential matches the Farm Account and Service App is null" -Fixture {
            $testParams = @{
                Name = "User Profile Service App"
                ApplicationPool = "SharePoint Service Applications"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPDSCFarmAccount -MockWith {
                return $mockCredential
            }

            Mock -CommandName Get-SPServiceApplication -MockWith {
                return $null
            }

            Mock -CommandName Restart-Service {}

            It "Should throw exception in the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should throw exception in the Test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "Specified PSDSCRunAsCredential "
            }
        }

        Context -Name "When PSDSCRunAsCredential matches the Farm Account and Service App is not null" -Fixture {
            $testParams = @{
                Name = "User Profile Service App"
                ApplicationPool = "SharePoint Service Applications"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPDSCFarmAccount -MockWith {
                return $mockCredential
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
                                                                                        NormalizedDataSource = "SQL.domain.local"
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
                                                                                        NormalizedDataSource = "SQL.domain.local"
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
                                                                                        NormalizedDataSource = "SQL.domain.local"
                                                                                    }
                                                                                } -PassThru
                                                                )
                                                            )
                                                        } -PassThru
                                    } -PassThru -Force
                )
            }
            Mock -CommandName Restart-Service {}

            It "Should NOT throw exception in the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should throw exception in the Test method" {
                Test-TargetResource @testParams | Should Be $true
            }

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "Specified PSDSCRunAsCredential "
            }
        }

        Context -Name "When InstallAccount matches the Farm Account" -Fixture {
            $testParams = @{
                Name = "User Profile Service App"
                ApplicationPool = "SharePoint Service Applications"
                Ensure = "Present"
                InstallAccount = $mockFarmCredential
            }

            Mock -CommandName Get-SPServiceApplication -MockWith {
                return $null
            }

            Mock -CommandName Restart-Service {}

            It "Should throw exception in the Get method" {
                { Get-TargetResource @testParams } | Should throw "Specified InstallAccount "
            }

            It "Should throw exception in the Test method" {
                { Test-TargetResource @testParams } | Should throw "Specified InstallAccount "
            }

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "Specified InstallAccount "
            }
        }

        Context -Name "When no service applications exist in the current farm" -Fixture {
            $testParams = @{
                Name = "User Profile Service App"
                ApplicationPool = "SharePoint Service Applications"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith {
                return $null
            }

            Mock -CommandName Restart-Service {}

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
                Ensure = "Present"
            }

            Mock -CommandName Restart-Service -MockWith {}
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
                                                                                        NormalizedDataSource = "SQL.domain.local"
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
                                                                                        NormalizedDataSource = "SQL.domain.local"
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
                                                                                        NormalizedDataSource = "SQL.domain.local"
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

        Context -Name "When service applications exist in the current farm and NoILMUsed isn't enabled but it needs to be" -Fixture {
            $testParams = @{
                Name = "User Profile Service App"
                ApplicationPool = "SharePoint Service Applications"
                NoILMUsed = $true
                Ensure = "Present"
            }

            Mock -CommandName Restart-Service -MockWith {}
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
                                   -Name "NoILMUsed" `
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
                                                                                        NormalizedDataSource = "SQL.domain.local"
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
                                                                                        NormalizedDataSource = "SQL.domain.local"
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
                                                                                        NormalizedDataSource = "SQL.domain.local"
                                                                                    }
                                                                                } -PassThru
                                                                )
                                                            )
                                                        } -PassThru
                                    } -PassThru -Force
                )
            }

            It "Should return false from the Get method" {
                (Get-TargetResource @testParams).NoILMUsed | Should Be $false
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
                $testParams.NoILMUsed = $false
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "When service applications exist in the current farm and SiteNamingConflictResolution is incorrect" -Fixture {
            $testParams = @{
                Name                         = "User Profile Service App"
                ApplicationPool              = "SharePoint Service Applications"
                SiteNamingConflictResolution = "Username_CollisionDomain"
                Ensure                       = "Present"
            }

            Mock -CommandName Restart-Service -MockWith {}
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
                                   -Name "NoILMUsed" `
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
                                                                                        NormalizedDataSource = "SQL.domain.local"
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
                                                                                        NormalizedDataSource = "SQL.domain.local"
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
                                                                                        NormalizedDataSource = "SQL.domain.local"
                                                                                    }
                                                                                } -PassThru
                                                                )
                                                            )
                                                        } -PassThru
                                    } -PassThru -Force
                )
            }

            It "Should return SiteNamingConflictResolution=Domain_Username from the Get method" {
                (Get-TargetResource @testParams).SiteNamingConflictResolution | Should Be "Domain_Username"
            }

            It "Should call Get-SPWebApplication before finishing set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Get-SPWebApplication
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context -Name "When a service application exists and is configured correctly" -Fixture {
            $testParams = @{
                Name = "User Profile Service App"
                ApplicationPool = "SharePoint Service Applications"
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
                                                                                        NormalizedDataSource = "SQL.domain.local"
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
                                                                                        NormalizedDataSource = "SQL.domain.local"
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
                                                                                        NormalizedDataSource = "SQL.domain.local"
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
                                                                                        NormalizedDataSource = "SQL.domain.local"
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
                                                                                        NormalizedDataSource = "SQL.domain.local"
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
                                                                                        NormalizedDataSource = "SQL.domain.local"
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
