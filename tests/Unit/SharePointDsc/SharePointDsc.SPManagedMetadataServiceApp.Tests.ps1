[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param
(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
            -Resolve)
)

$script:DSCModuleName = 'SharePointDsc'
$script:DSCResourceName = 'SPManagedMetaDataServiceApp'
$script:DSCResourceFullName = 'MSFT_' + $script:DSCResourceName

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force

        Import-Module -Name (Join-Path -Path $PSScriptRoot `
                -ChildPath "..\UnitTestHelper.psm1" `
                -Resolve)

        $Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
            -DscResource $script:DSCResourceName
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:DSCModuleName `
        -DSCResourceName $script:DSCResourceFullName `
        -ResourceType 'Mof' `
        -TestType 'Unit'
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    InModuleScope -ModuleName $script:DSCResourceFullName -ScriptBlock {
        Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
            BeforeAll {
                Invoke-Command -Scriptblock $Global:SPDscHelper.InitializeScript -NoNewScope

                #Initialize Tests
                $getTypeFullName = "Microsoft.SharePoint.Taxonomy.MetadataWebServiceApplication"

                # Mocks for all contexts
                # SPMetadataServiceApplication Mocks
                Mock -CommandName New-SPMetadataServiceApplication -MockWith { return @{ } }
                Mock -CommandName Set-SPMetadataServiceApplication -MockWith { }

                # SPMetadataServiceApplicationProxy Mocks
                Mock -CommandName New-SPMetadataServiceApplicationProxy -MockWith {
                    return @(
                        @{
                            Name = "Managed Metadata Service App Proxy"
                        } | Add-Member -MemberType ScriptMethod `
                            -Name Update `
                            -Value { $Global:SPDscServiceProxyUpdateCalled = $true }  `
                            -PassThru -Force `
                        | Add-Member -MemberType ScriptMethod `
                            -Name Delete `
                            -Value { $Global:SPDscServiceProxyDeleteCalled = $true } `
                            -PassThru -Force
                    )
                }

                Mock -CommandName Get-SPMetadataServiceApplicationProxy -MockWith {
                    return @{
                        Name       = "Managed Metadata Service App Proxy"
                        Properties = @{
                            IsNPContentTypeSyndicationEnabled = $true
                            IsContentTypePushdownEnabled      = $true
                        }
                    } | Add-Member -MemberType ScriptMethod `
                        -Name update `
                        -Value { $Global:SPDscMetaDataServiceApplicationProxyUpdateCalled = $true } `
                        -PassThru -Force
                }

                Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                    return @(
                        @{
                            Name = "Managed Metadata Service App Proxy"
                        } | Add-Member -MemberType ScriptMethod `
                            -Name Update `
                            -Value { $Global:SPDscServiceProxyUpdateCalled = $true }  `
                            -PassThru -Force `
                        | Add-Member -MemberType ScriptMethod `
                            -Name Delete `
                            -Value { $Global:SPDscServiceProxyDeleteCalled = $true } `
                            -PassThru -Force
                    )
                }

                Mock -CommandName Remove-SPServiceApplication -MockWith { }

                # SPWebApplication Mocks
                Mock -CommandName Get-SPWebApplication -MockWith {
                    return @(
                        @{
                            Url                            = "http://FakeCentralAdmin.Url"
                            IsAdministrationWebApplication = $true
                        }
                    )
                }

                # SPTaxonomySession Mocks
                $termStores = @{
                    "Managed Metadata Service App Proxy" = @{
                        Name                    = "Managed Metadata Service App Proxy"
                        Languages               = @(1033)
                        DefaultLanguage         = 1033
                        WorkingLanguage         = 1033
                        TermStoreAdministrators = @(
                            New-Object -TypeName PSObject -Property @{
                                PrincipalName               = "Contoso\User1"
                                IsWindowsAuthenticationMode = $true
                            }
                        )
                    } | Add-Member -MemberType ScriptMethod `
                        -Name AddTermStoreAdministrator `
                        -Value { $Global:SPDscAddUserCalled = $true }  `
                        -PassThru -Force `
                    | Add-Member -MemberType ScriptMethod `
                        -Name DeleteTermStoreAdministrator `
                        -Value { $Global:SPDscDeleteUserCalled = $true }  `
                        -PassThru -Force `
                    | Add-Member -MemberType ScriptMethod `
                        -Name CommitAll `
                        -Value { }  `
                        -PassThru -Force `
                    | Add-Member -MemberType ScriptMethod `
                        -Name AddLanguage `
                        -Value { $Global:SPDscAddLanguageCalled = $true }  `
                        -PassThru -Force `
                    | Add-Member -MemberType ScriptMethod `
                        -Name DeleteLanguage `
                        -Value { $Global:SPDscDeleteLanguageCalled = $true }  `
                        -PassThru -Force `
                    | Add-Member -MemberType ScriptMethod `
                        -Name CommitAll `
                        -Value { }  `
                        -PassThru -Force
                }

                Mock -CommandName Get-SPTaxonomySession -MockWith {
                    return @{
                        TermStores = $termStores
                    }
                }

                # SPClaimsPrincipal Mocks
                Mock -CommandName New-SPClaimsPrincipal -MockWith {
                    return @{
                        Value = $Identity -replace "i:0#.w\|"
                    }
                } -ParameterFilter { $IdentityType -eq "EncodedClaim" }

                Mock -CommandName New-SPClaimsPrincipal -MockWith {
                    $Global:SPDscClaimsPrincipalUser = $Identity
                    return (
                        New-Object -TypeName "Object" | Add-Member -MemberType ScriptMethod ToEncodedString {
                            return "i:0#.w|$($Global:SPDscClaimsPrincipalUser)"
                        } -PassThru
                    )
                } -ParameterFilter { $IdentityType -eq "WindowsSamAccountName" }

                # Add Type Definitions
                try
                {
                    [Microsoft.SharePoint.Taxonomy.TaxonomyRights]
                }
                catch
                {
                    Add-Type -TypeDefinition @"
                    namespace Microsoft.SharePoint.Taxonomy {
                        public enum TaxonomyRights {
                            None,
                            ManageTermStore
                        }
                    }
"@
                }

                function Add-SPDscEvent
                {
                    param (
                        [Parameter(Mandatory = $true)]
                        [System.String]
                        $Message,

                        [Parameter(Mandatory = $true)]
                        [System.String]
                        $Source,

                        [Parameter()]
                        [ValidateSet('Error', 'Information', 'FailureAudit', 'SuccessAudit', 'Warning')]
                        [System.String]
                        $EntryType,

                        [Parameter()]
                        [System.UInt32]
                        $EventID
                    )
                }
            }

            # Test contexts
            Context -Name "When no service applications exist in the current farm" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                          = "Managed Metadata Service App"
                        ApplicationPool               = "SharePoint Service Applications"
                        DatabaseServer                = "databaseserver\instance"
                        DatabaseName                  = "SP_MMS"
                        TermStoreAdministrators       = @()
                        ContentTypeHubUrl             = ""
                        ProxyName                     = "Proxy Name"
                        DefaultLanguage               = 1033
                        Languages                     = @()
                        ContentTypePushdownEnabled    = $true
                        ContentTypeSyndicationEnabled = $true
                        Ensure                        = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith { return $null }
                }

                It "Should return absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create a new service application in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPMetadataServiceApplication
                }
            }

            Context -Name "When service applications exist in the current farm but the specific MMS app does not" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Managed Metadata Service App"
                        ApplicationPool = "SharePoint Service Applications"
                        DatabaseServer  = "databaseserver\instance"
                        DatabaseName    = "SP_MMS"
                        Ensure          = "Present"
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
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name IsConnected `
                            -Value {
                            param($x)
                            return $true
                        } -PassThru -Force
                        return $spServiceApp
                    }
                }

                It "Should return absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "When a service application exists and is configured correctly" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Managed Metadata Service App"
                        ApplicationPool = "SharePoint Service Applications"
                        DatabaseServer  = "databaseserver\instance"
                        DatabaseName    = "SP_MMS"
                        Ensure          = "Present"
                    }

                    if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                    {
                        Mock -CommandName Get-SPServiceApplication -MockWith {
                            $spServiceApp = [PSCustomObject]@{
                                TypeName        = "Managed Metadata Service"
                                DisplayName     = $testParams.Name
                                ApplicationPool = @{
                                    Name = $testParams.ApplicationPool
                                }
                                Database        = @{
                                    Name                 = $testParams.DatabaseName
                                    NormalizedDataSource = $testParams.DatabaseServer
                                }
                            }
                            $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                                return (@{
                                        FullName = $getTypeFullName
                                    }) | Add-Member -MemberType ScriptMethod -Name GetMethods -Value {
                                    return (@{
                                            Name = "GetContentTypeSyndicationHubLocal"
                                        }) | Add-Member -MemberType ScriptMethod -Name Invoke -Value {
                                        return @{
                                            AbsoluteUri = "http://contoso.sharepoint.com/sites/ct"
                                        }
                                    } -PassThru -Force
                                } -PassThru -Force
                            } -PassThru -Force
                            $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                                -Name IsConnected `
                                -Value {
                                param($x)
                                return $true
                            } -PassThru -Force
                            return $spServiceApp
                        }
                    }

                    if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 16)
                    {
                        Mock -CommandName Get-SPServiceApplication -MockWith {
                            $spServiceApp = [PSCustomObject]@{
                                TypeName        = "Managed Metadata Service"
                                DisplayName     = $testParams.Name
                                ApplicationPool = @{
                                    Name = $testParams.ApplicationPool
                                }
                                Database        = @{
                                    Name                 = $testParams.DatabaseName
                                    NormalizedDataSource = $testParams.DatabaseServer
                                }
                            }
                            $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
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
                                                            -Value "DatabaseMapper" `
                                                            -PassThru |
                                                            Add-Member -MemberType ScriptMethod `
                                                                -Name GetValue `
                                                                -Value {
                                                                param($x)
                                                                return (@{
                                                                        FullName = $getTypeFullName
                                                                    }) | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                                                                    return (@{
                                                                            FullName = $getTypeFullName
                                                                        }) | Add-Member -MemberType ScriptMethod -Name GetMethods -Value {
                                                                        return (@{
                                                                                Name = "GetContentTypeSyndicationHubLocal"
                                                                            }) | Add-Member -MemberType ScriptMethod -Name Invoke -Value {
                                                                            return @{
                                                                                AbsoluteUri = "http://contoso.sharepoint.com/sites/ct"
                                                                            }
                                                                        } -PassThru -Force
                                                                    } -PassThru -Force
                                                                } -PassThru -Force
                                                            } -PassThru
                                                        )
                                                    )
                                                } -PassThru
                                            } -PassThru -Force
                                            $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                                                -Name IsConnected `
                                                -Value {
                                                param($x)
                                                return $true
                                            } -PassThru -Force
                                            return $spServiceApp
                                        }
                                    }
                                }

                                It "Should return present from the get method" {
                                    $results = Get-TargetResource @testParams
                                    $results.Ensure | Should -Be "Present"
                                    $results.ContentTypeHubUrl | Should -Not -BeNullOrEmpty
                                }

                                It "Should return true when the Test method is called" {
                                    Test-TargetResource @testParams | Should -Be $true
                                }
                            }


                            Context -Name "When a service application exists and the app pool is not configured correctly" -Fixture {
                                BeforeAll {
                                    $testParams = @{
                                        Name            = "Managed Metadata Service App"
                                        ApplicationPool = "SharePoint Service Applications"
                                        DatabaseServer  = "databaseserver\instance"
                                        DatabaseName    = "SP_MMS"
                                        Ensure          = "Present"
                                    }

                                    if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                                    {
                                        Mock -CommandName Get-SPServiceApplication -MockWith {
                                            $spServiceApp = [PSCustomObject]@{
                                                TypeName        = "Managed Metadata Service"
                                                DisplayName     = $testParams.Name
                                                ApplicationPool = @{
                                                    Name = "Wrong App Pool Name"
                                                }
                                                Database        = @{
                                                    Name                 = $testParams.DatabaseName
                                                    NormalizedDataSource = $testParams.DatabaseServer
                                                }
                                            }
                                            $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                                                return (@{
                                                        FullName = $getTypeFullName
                                                    }) | Add-Member -MemberType ScriptMethod -Name GetMethods -Value {
                                                    return (@{
                                                            Name = "GetContentTypeSyndicationHubLocal"
                                                        }) | Add-Member -MemberType ScriptMethod -Name Invoke -Value {
                                                        return @{
                                                            AbsoluteUri = ""
                                                        }
                                                    } -PassThru -Force
                                                } -PassThru -Force
                                            } -PassThru -Force
                                            $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                                                -Name IsConnected `
                                                -Value {
                                                param($x)
                                                return $true
                                            } -PassThru -Force
                                            return $spServiceApp
                                        }
                                    }

                                    if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 16)
                                    {
                                        Mock -CommandName Get-SPServiceApplication -MockWith {
                                            $spServiceApp = [PSCustomObject]@{
                                                TypeName        = "Managed Metadata Service"
                                                DisplayName     = $testParams.Name
                                                ApplicationPool = @{
                                                    Name = "Wrong App Pool Name"
                                                }
                                                Database        = @{
                                                    Name                 = $testParams.DatabaseName
                                                    NormalizedDataSource = $testParams.DatabaseServer
                                                }
                                            }
                                            $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
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
                                                                            -Value "DatabaseMapper" `
                                                                            -PassThru |
                                                                            Add-Member -MemberType ScriptMethod `
                                                                                -Name GetValue `
                                                                                -Value {
                                                                                param($x)
                                                                                return (@{
                                                                                        FullName = $getTypeFullName
                                                                                    }) | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                                                                                    return (@{
                                                                                            FullName = $getTypeFullName
                                                                                        }) | Add-Member -MemberType ScriptMethod -Name GetMethods -Value {
                                                                                        return (@{
                                                                                                Name = "GetContentTypeSyndicationHubLocal"
                                                                                            }) | Add-Member -MemberType ScriptMethod -Name Invoke -Value {
                                                                                            return @{
                                                                                                AbsoluteUri = ""
                                                                                            }
                                                                                        } -PassThru -Force
                                                                                    } -PassThru -Force
                                                                                } -PassThru -Force
                                                                            } -PassThru
                                                                        )
                                                                    )
                                                                } -PassThru
                                                            } -PassThru -Force
                                                            $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                                                                -Name IsConnected `
                                                                -Value {
                                                                param($x)
                                                                return $true
                                                            } -PassThru -Force

                                                            return $spServiceApp
                                                        }
                                                    }

                                                    Mock -CommandName Get-SPServiceApplicationPool -MockWith {
                                                        return @{
                                                            Name = $testParams.ApplicationPool
                                                        }
                                                    }
                                                }

                                                It "Should return Wrong App Pool Name from the Get method" {
                                                    (Get-TargetResource @testParams).ApplicationPool | Should -Be "Wrong App Pool Name"
                                                }

                                                It "Should return false when the Test method is called" {
                                                    Test-TargetResource @testParams | Should -Be $false
                                                }

                                                It "Should call the update service app cmdlet from the set method" {
                                                    Set-TargetResource @testParams

                                                    Assert-MockCalled Get-SPServiceApplicationPool
                                                    Assert-MockCalled Set-SPMetadataServiceApplication -ParameterFilter {
                                                        $ApplicationPool.Name -eq $testParams.ApplicationPool
                                                    }
                                                }
                                            }

                                            Context -Name "When a service application exists and the content type hub is not configured correctly" -Fixture {
                                                BeforeAll {
                                                    $testParams = @{
                                                        Name              = "Managed Metadata Service App"
                                                        ApplicationPool   = "SharePoint Service Applications"
                                                        DatabaseServer    = "databaseserver\instance"
                                                        DatabaseName      = "SP_MMS"
                                                        ContentTypeHubUrl = "https://contenttypes.contoso.com"
                                                        Ensure            = "Present"
                                                    }

                                                    if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                                                    {
                                                        Mock -CommandName Get-SPServiceApplication -MockWith {
                                                            $spServiceApp = [PSCustomObject]@{
                                                                TypeName        = "Managed Metadata Service"
                                                                DisplayName     = $testParams.Name
                                                                ApplicationPool = @{
                                                                    Name = $testParams.ApplicationPool
                                                                }
                                                                Database        = @{
                                                                    Name                 = $testParams.DatabaseName
                                                                    NormalizedDataSource = $testParams.DatabaseServer
                                                                }
                                                            }
                                                            $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                                                                return (@{
                                                                        FullName = $getTypeFullName
                                                                    }) | Add-Member -MemberType ScriptMethod -Name GetMethods -Value {
                                                                    return (@{
                                                                            Name = "GetContentTypeSyndicationHubLocal"
                                                                        }) | Add-Member -MemberType ScriptMethod -Name Invoke -Value {
                                                                        return @{
                                                                            AbsoluteUri = "https://contenttypes.contoso.com/wrong"
                                                                        }
                                                                    } -PassThru -Force
                                                                } -PassThru -Force
                                                            } -PassThru -Force
                                                            $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                                                                -Name IsConnected `
                                                                -Value {
                                                                param($x)
                                                                return $true
                                                            } -PassThru -Force
                                                            return $spServiceApp
                                                        }
                                                    }

                                                    if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 16)
                                                    {
                                                        Mock -CommandName Get-SPServiceApplication -MockWith {
                                                            $spServiceApp = [PSCustomObject]@{
                                                                TypeName        = "Managed Metadata Service"
                                                                DisplayName     = $testParams.Name
                                                                ApplicationPool = @{
                                                                    Name = "Wrong App Pool Name"
                                                                }
                                                                Database        = @{
                                                                    Name                 = $testParams.DatabaseName
                                                                    NormalizedDataSource = $testParams.DatabaseServer
                                                                }
                                                            }
                                                            $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
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
                                                                                            -Value "DatabaseMapper" `
                                                                                            -PassThru |
                                                                                            Add-Member -MemberType ScriptMethod `
                                                                                                -Name GetValue `
                                                                                                -Value {
                                                                                                param($x)
                                                                                                return (@{
                                                                                                        FullName = $getTypeFullName
                                                                                                    }) | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                                                                                                    return (@{
                                                                                                            FullName = $getTypeFullName
                                                                                                        }) | Add-Member -MemberType ScriptMethod -Name GetMethods -Value {
                                                                                                        return (@{
                                                                                                                Name = "GetContentTypeSyndicationHubLocal"
                                                                                                            }) | Add-Member -MemberType ScriptMethod -Name Invoke -Value {
                                                                                                            return @{
                                                                                                                AbsoluteUri = "https://contenttypes.contoso.com/wrong"
                                                                                                            }
                                                                                                        } -PassThru -Force
                                                                                                    } -PassThru -Force
                                                                                                } -PassThru -Force
                                                                                            } -PassThru
                                                                                        )
                                                                                    )
                                                                                } -PassThru
                                                                            } -PassThru -Force
                                                                            $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                                                                                -Name IsConnected `
                                                                                -Value {
                                                                                param($x)
                                                                                return $true
                                                                            } -PassThru -Force

                                                                            return $spServiceApp
                                                                        }
                                                                    }

                                                                    Mock -CommandName Get-SPServiceApplicationPool -MockWith {
                                                                        return @{
                                                                            Name = $testParams.ApplicationPool
                                                                        }
                                                                    }
                                                                }

                                                                It "Should return wrong content type url from the Get method" {
                                                                    (Get-TargetResource @testParams).ContentTypeHubUrl | Should -Be "https://contenttypes.contoso.com/wrong"
                                                                }

                                                                It "Should return false when the Test method is called" {
                                                                    Test-TargetResource @testParams | Should -Be $false
                                                                }

                                                                It "Should call the update service app cmdlet from the set method" {
                                                                    Set-TargetResource @testParams

                                                                    Assert-MockCalled Set-SPMetadataServiceApplication
                                                                }
                                                            }

                                                            Context -Name "When the service application exists but it shouldn't" -Fixture {
                                                                BeforeAll {
                                                                    $testParams = @{
                                                                        Name            = "Test App"
                                                                        ApplicationPool = "-"
                                                                        Ensure          = "Absent"
                                                                    }

                                                                    if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                                                                    {
                                                                        Mock -CommandName Get-SPServiceApplication -MockWith {
                                                                            $spServiceApp = [PSCustomObject]@{
                                                                                TypeName        = "Managed Metadata Service"
                                                                                DisplayName     = $testParams.Name
                                                                                ApplicationPool = @{
                                                                                    Name = "Wrong App Pool Name"
                                                                                }
                                                                                Database        = @{
                                                                                    Name                 = $testParams.DatabaseName
                                                                                    NormalizedDataSource = $testParams.DatabaseServer
                                                                                }
                                                                            }
                                                                            $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                                                                                return (@{
                                                                                        FullName = $getTypeFullName
                                                                                    }) | Add-Member -MemberType ScriptMethod -Name GetMethods -Value {
                                                                                    return (@{
                                                                                            Name = "GetContentTypeSyndicationHubLocal"
                                                                                        }) | Add-Member -MemberType ScriptMethod -Name Invoke -Value {
                                                                                        return @{
                                                                                            AbsoluteUri = ""
                                                                                        }
                                                                                    } -PassThru -Force
                                                                                } -PassThru -Force
                                                                            } -PassThru -Force
                                                                            $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                                                                                -Name IsConnected `
                                                                                -Value {
                                                                                param($x)
                                                                                return $true
                                                                            } -PassThru -Force
                                                                            return $spServiceApp
                                                                        }
                                                                    }

                                                                    if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 16)
                                                                    {
                                                                        Mock -CommandName Get-SPServiceApplication -MockWith {
                                                                            $spServiceApp = [PSCustomObject]@{
                                                                                TypeName        = "Managed Metadata Service"
                                                                                DisplayName     = $testParams.Name
                                                                                ApplicationPool = @{
                                                                                    Name = "Wrong App Pool Name"
                                                                                }
                                                                                Database        = @{
                                                                                    Name                 = $testParams.DatabaseName
                                                                                    NormalizedDataSource = $testParams.DatabaseServer
                                                                                }
                                                                            }
                                                                            $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
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
                                                                                                            -Value "DatabaseMapper" `
                                                                                                            -PassThru |
                                                                                                            Add-Member -MemberType ScriptMethod `
                                                                                                                -Name GetValue `
                                                                                                                -Value {
                                                                                                                param($x)
                                                                                                                return (@{
                                                                                                                        FullName = $getTypeFullName
                                                                                                                    }) | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                                                                                                                    return (@{
                                                                                                                            FullName = $getTypeFullName
                                                                                                                        }) | Add-Member -MemberType ScriptMethod -Name GetMethods -Value {
                                                                                                                        return (@{
                                                                                                                                Name = "GetContentTypeSyndicationHubLocal"
                                                                                                                            }) | Add-Member -MemberType ScriptMethod -Name Invoke -Value {
                                                                                                                            return @{
                                                                                                                                AbsoluteUri = ""
                                                                                                                            }
                                                                                                                        } -PassThru -Force
                                                                                                                    } -PassThru -Force
                                                                                                                } -PassThru -Force
                                                                                                            } -PassThru
                                                                                                        )
                                                                                                    )
                                                                                                } -PassThru
                                                                                            } -PassThru -Force
                                                                                            $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                                                                                                -Name IsConnected `
                                                                                                -Value {
                                                                                                param($x)
                                                                                                return $true
                                                                                            } -PassThru -Force
                                                                                            return $spServiceApp
                                                                                        }
                                                                                    }

                                                                                    Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                                                                                        return @(
                                                                                            @{
                                                                                                Name = "Managed Metadata Service App Proxy"
                                                                                            } | Add-Member -MemberType ScriptMethod `
                                                                                                -Name Update `
                                                                                                -Value { $Global:SPDscServiceProxyUpdateCalled = $true }  `
                                                                                                -PassThru -Force `
                                                                                            | Add-Member -MemberType ScriptMethod `
                                                                                                -Name Delete `
                                                                                                -Value { $Global:SPDscServiceProxyDeleteCalled = $true } `
                                                                                                -PassThru -Force
                        )
                    }
                }

                It "Should return present from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the remove service application cmdlet in the set method" {
                    $Global:SPDscServiceProxyDeleteCalled = $false

                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-SPServiceApplication
                    $Global:SPDscServiceProxyDeleteCalled | Should -Be $true
                }
            }

            Context -Name "When the service application doesn't exist and it shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Test App"
                        ApplicationPool = "-"
                        Ensure          = "Absent"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        return $null
                    }
                }

                It "Should return absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return true when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "A service app exists and has a correct list of term store administrators" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                    = "Managed Metadata Service App"
                        ApplicationPool         = "SharePoint Service Applications"
                        DatabaseServer          = "databaseserver\instance"
                        DatabaseName            = "SP_MMS"
                        Ensure                  = "Present"
                        TermStoreAdministrators = @(
                            "CONTOSO\User1"
                        )
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName        = "Managed Metadata Service"
                            DisplayName     = $testParams.Name
                            ApplicationPool = @{
                                Name = $testParams.ApplicationPool
                            }
                            Database        = @{
                                Name                 = $testParams.DatabaseName
                                NormalizedDataSource = $testParams.DatabaseServer
                            }
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                            return (@{
                                    FullName = $getTypeFullName
                                }) | Add-Member -MemberType ScriptMethod -Name GetMethods -Value {
                                return (@(
                                        Name = "GetContentTypeSyndicationHubLocal"
                                    )) | Add-Member -MemberType ScriptMethod -Name Invoke -Value {
                                    return @{
                                        AbsoluteUri = ""
                                    }
                                } -PassThru -Force
                            } -PassThru -Force
                        } -PassThru -Force
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name IsConnected `
                            -Value {
                            param($x)
                            return $true
                        } -PassThru -Force
                        return $spServiceApp
                    }
                }

                It "Should return the current users from the get method" {
                    (Get-TargetResource @testParams).TermStoreAdministrators | Should -Not -BeNullOrEmpty
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "A service app exists and is missing a user from the term store administrators list" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                    = "Managed Metadata Service App"
                        ApplicationPool         = "SharePoint Service Applications"
                        DatabaseServer          = "databaseserver\instance"
                        DatabaseName            = "SP_MMS"
                        Ensure                  = "Present"
                        TermStoreAdministrators = @(
                            "CONTOSO\User1",
                            "CONTOSO\User2"
                        )
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName        = "Managed Metadata Service"
                            DisplayName     = $testParams.Name
                            ApplicationPool = @{
                                Name = $testParams.ApplicationPool
                            }
                            Database        = @{
                                Name                 = $testParams.DatabaseName
                                NormalizedDataSource = $testParams.DatabaseServer
                            }
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                            return (@{
                                    FullName = $getTypeFullName
                                }) | Add-Member -MemberType ScriptMethod -Name GetMethods -Value {
                                return (@(
                                        Name = "GetContentTypeSyndicationHubLocal"
                                    )) | Add-Member -MemberType ScriptMethod -Name Invoke -Value {
                                    return @{
                                        AbsoluteUri = ""
                                    }
                                } -PassThru -Force
                            } -PassThru -Force
                        } -PassThru -Force
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name IsConnected `
                            -Value {
                            param($x)
                            return $true
                        } -PassThru -Force
                        return $spServiceApp
                    }
                }

                It "Should return the current users from the get method" {
                    (Get-TargetResource @testParams).TermStoreAdministrators | Should -Not -BeNullOrEmpty
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the add method from the set method" {
                    $Global:SPDscAddUserCalled = $false
                    $Global:SPDscDeleteUserCalled = $false
                    Set-TargetResource @testParams

                    $Global:SPDscAddUserCalled | Should -Be $true
                }
            }

            Context -Name "A service app exists and has an extra user on the term store administrators list" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                    = "Managed Metadata Service App"
                        ApplicationPool         = "SharePoint Service Applications"
                        DatabaseServer          = "databaseserver\instance"
                        DatabaseName            = "SP_MMS"
                        Ensure                  = "Present"
                        TermStoreAdministrators = @(
                            "CONTOSO\User1"
                        )
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName        = "Managed Metadata Service"
                            DisplayName     = $testParams.Name
                            ApplicationPool = @{
                                Name = $testParams.ApplicationPool
                            }
                            Database        = @{
                                Name                 = $testParams.DatabaseName
                                NormalizedDataSource = $testParams.DatabaseServer
                            }
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                            return (@{
                                    FullName = $getTypeFullName
                                }) | Add-Member -MemberType ScriptMethod -Name GetMethods -Value {
                                return (@(
                                        Name = "GetContentTypeSyndicationHubLocal"
                                    )) | Add-Member -MemberType ScriptMethod -Name Invoke -Value {
                                    return @{
                                        AbsoluteUri = ""
                                    }
                                } -PassThru -Force
                            } -PassThru -Force
                        } -PassThru -Force
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name IsConnected `
                            -Value {
                            param($x)
                            return $true
                        } -PassThru -Force
                        return $spServiceApp
                    }

                    $termStores = @{
                        "Managed Metadata Service App Proxy" = @{
                            Name                    = "Managed Metadata Service App Proxy"
                            Languages               = @(1033)
                            DefaultLanguage         = 1033
                            WorkingLanguage         = 1033
                            TermStoreAdministrators = @(
                                New-Object -TypeName PSObject -Property @{
                                    PrincipalName               = "Contoso\User1"
                                    IsWindowsAuthenticationMode = $true
                                }
                                New-Object -TypeName PSObject -Property @{
                                    PrincipalName               = "Contoso\User2"
                                    IsWindowsAuthenticationMode = $true
                                }
                            )
                        } | Add-Member -MemberType ScriptMethod `
                            -Name AddTermStoreAdministrator `
                            -Value { $Global:SPDscAddUserCalled = $true }  `
                            -PassThru -Force `
                        | Add-Member -MemberType ScriptMethod `
                            -Name DeleteTermStoreAdministrator `
                            -Value { $Global:SPDscDeleteUserCalled = $true }  `
                            -PassThru -Force `
                        | Add-Member -MemberType ScriptMethod `
                            -Name CommitAll `
                            -Value { }  `
                            -PassThru -Force `
                        | Add-Member -MemberType ScriptMethod `
                            -Name AddLanguage `
                            -Value { $Global:SPDscAddLanguageCalled = $true }  `
                            -PassThru -Force `
                        | Add-Member -MemberType ScriptMethod `
                            -Name DeleteLanguage `
                            -Value { $Global:SPDscDeleteLanguageCalled = $true }  `
                            -PassThru -Force `
                        | Add-Member -MemberType ScriptMethod `
                            -Name CommitAll `
                            -Value { }  `
                            -PassThru -Force
                    }

                    Mock -CommandName Get-SPTaxonomySession -MockWith {
                        return @{
                            TermStores = $termStores
                        }
                    }
                }

                It "Should return the current users from the get method" {
                    (Get-TargetResource @testParams).TermStoreAdministrators | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the delete method from the set method" {
                    $Global:SPDscAddUserCalled = $false
                    $Global:SPDscDeleteUserCalled = $false
                    Set-TargetResource @testParams

                    $Global:SPDscDeleteUserCalled | Should -Be $true
                }
            }

            Context -Name "A service app exists and the proxy name has to be changed" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                    = "Managed Metadata Service App"
                        ProxyName               = "Managed Metadata Service App ProxyName"
                        ApplicationPool         = "SharePoint Service Applications"
                        DatabaseServer          = "databaseserver\instance"
                        DatabaseName            = "SP_MMS"
                        Ensure                  = "Present"
                        TermStoreAdministrators = @()
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName        = "Managed Metadata Service"
                            DisplayName     = $testParams.Name
                            ApplicationPool = @{
                                Name = $testParams.ApplicationPool
                            }
                            Database        = @{
                                Name   = $testParams.DatabaseName
                                Server = @{ Name = $testParams.DatabaseServer }
                            }
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return (@{
                                    FullName = $getTypeFullName
                                })
                        } -PassThru -Force `
                        | Add-Member -MemberType ScriptMethod `
                            -Name IsConnected `
                            -Value {
                            param($x)
                            return $true
                        } -PassThru -Force

                        return $spServiceApp
                    }

                    Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                        return @(
                            @{
                                Name = "$($testParams.Name) Proxy Test"
                            } | Add-Member -MemberType ScriptMethod `
                                -Name Update `
                                -Value { $Global:SPDscServiceProxyUpdateCalled = $true }  `
                                -PassThru -Force `
                            | Add-Member -MemberType ScriptMethod `
                                -Name Delete `
                                -Value { $Global:SPDscServiceProxyDeleteCalled = $true } `
                                -PassThru -Force
                        )
                    }
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the delete method from the set method" {
                    $Global:SPDscServiceProxyUpdateCalled = $false
                    Set-TargetResource @testParams

                    $Global:SPDscServiceProxyUpdateCalled | Should -Be $true
                }
            }

            Context -Name "A service app exists and has a non-windows term store administrator in the list" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                    = "Managed Metadata Service App"
                        ApplicationPool         = "SharePoint Service Applications"
                        DatabaseServer          = "databaseserver\instance"
                        DatabaseName            = "SP_MMS"
                        Ensure                  = "Present"
                        TermStoreAdministrators = @()
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName        = "Managed Metadata Service"
                            DisplayName     = $testParams.Name
                            ApplicationPool = @{
                                Name = $testParams.ApplicationPool
                            }
                            Database        = @{
                                Name   = $testParams.DatabaseName
                                Server = @{ Name = $testParams.DatabaseServer }
                            }
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                            return (@{
                                    FullName = $getTypeFullName
                                }) | Add-Member -MemberType ScriptMethod -Name GetMethods -Value {
                                return (@(
                                        Name = "GetContentTypeSyndicationHubLocal"
                                    )) | Add-Member -MemberType ScriptMethod -Name Invoke -Value {
                                    return @{
                                        AbsoluteUri = ""
                                    }
                                } -PassThru -Force
                            } -PassThru -Force
                        } -PassThru -Force
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name IsConnected `
                            -Value {
                            param($x)
                            return $true
                        } -PassThru -Force
                        return $spServiceApp
                    }

                    $termStores = @{
                        "Managed Metadata Service App Proxy" = @{
                            Name                    = "Managed Metadata Service App Proxy"
                            Languages               = @(1033)
                            DefaultLanguage         = 1033
                            WorkingLanguage         = 1033
                            TermStoreAdministrators = @(
                                New-Object -TypeName PSObject -Property @{
                                    PrincipalName               = "i:0#.w|Contoso\User2"
                                    IsWindowsAuthenticationMode = $false
                                }
                            )
                        } | Add-Member -MemberType ScriptMethod `
                            -Name AddTermStoreAdministrator `
                            -Value { $Global:SPDscAddUserCalled = $true }  `
                            -PassThru -Force `
                        | Add-Member -MemberType ScriptMethod `
                            -Name DeleteTermStoreAdministrator `
                            -Value { $Global:SPDscDeleteUserCalled = $true }  `
                            -PassThru -Force `
                        | Add-Member -MemberType ScriptMethod `
                            -Name CommitAll `
                            -Value { }  `
                            -PassThru -Force `
                        | Add-Member -MemberType ScriptMethod `
                            -Name AddLanguage `
                            -Value { $Global:SPDscAddLanguageCalled = $true }  `
                            -PassThru -Force `
                        | Add-Member -MemberType ScriptMethod `
                            -Name DeleteLanguage `
                            -Value { $Global:SPDscDeleteLanguageCalled = $true }  `
                            -PassThru -Force `
                        | Add-Member -MemberType ScriptMethod `
                            -Name CommitAll `
                            -Value { }  `
                            -PassThru -Force
                    }

                    Mock -CommandName Get-SPTaxonomySession -MockWith {
                        return @{
                            TermStores = $termStores
                        }
                    }
                }

                It "Should return the current users from the get method" {
                    (Get-TargetResource @testParams).TermStoreAdministrators | Should -Not -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the delete method from the set method" {
                    $Global:SPDscAddUserCalled = $false
                    $Global:SPDscDeleteUserCalled = $false
                    Set-TargetResource @testParams

                    $Global:SPDscDeleteUserCalled | Should -Be $true
                }
            }

            Context -Name "When a service proxy exists, it should return the proxy name" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Managed Metadata Service App"
                        ApplicationPool = "SharePoint Service Applications"
                        DatabaseServer  = "databaseserver\instance"
                        DatabaseName    = "SP_MMS"
                        Ensure          = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName        = "Managed Metadata Service"
                            DisplayName     = $testParams.Name
                            ApplicationPool = @{
                                Name = $testParams.ApplicationPool
                            }
                            Database        = @{
                                Name   = $testParams.DatabaseName
                                Server = @{ Name = $testParams.DatabaseServer }
                            }
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return (@{
                                    FullName = $getTypeFullName
                                })
                        } -PassThru -Force `
                        | Add-Member -MemberType ScriptMethod `
                            -Name IsConnected `
                            -Value {
                            param($x)
                            return ($true)
                        } -PassThru -Force

                        return $spServiceApp
                    }

                    Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                        return @(
                            @{
                                Name = "$($testParams.Name) Proxy Test"
                            }
                        )
                    }
                }

                It "Should return the proxy name" {
                    (Get-TargetResource @testParams).ProxyName | Should -Be "$($testParams.Name) Proxy Test"
                }
            }

            Context -Name "When the termstore for the service application proxy exists in the current farm and is not configured correctly" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                          = "Managed Metadata Service App"
                        ApplicationPool               = "SharePoint Service Applications"
                        DatabaseServer                = "databaseserver\instance"
                        DatabaseName                  = "SP_MMS"
                        Ensure                        = "Present"
                        DefaultLanguage               = 1033
                        Languages                     = @(1033)
                        ContentTypePushdownEnabled    = $false
                        ContentTypeSyndicationEnabled = $false
                    }

                    if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                    {
                        Mock -CommandName Get-SPServiceApplication -MockWith {
                            $spServiceApp = [PSCustomObject]@{
                                TypeName        = "Managed Metadata Service"
                                DisplayName     = $testParams.Name
                                ApplicationPool = @{
                                    Name = $testParams.ApplicationPool
                                }
                                Database        = @{
                                    Name   = $testParams.DatabaseName
                                    Server = @{ Name = $testParams.DatabaseServer }
                                }
                            }
                            $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                                return (@{
                                        FullName = $getTypeFullName
                                    }) | Add-Member -MemberType ScriptMethod -Name GetMethods -Value {
                                    return (@{
                                            Name = "GetContentTypeSyndicationHubLocal"
                                        }) | Add-Member -MemberType ScriptMethod -Name Invoke -Value {
                                        return @{
                                            AbsoluteUri = "http://contoso.sharepoint.com/sites/ct"
                                        }
                                    } -PassThru -Force
                                } -PassThru -Force
                            } -PassThru -Force
                            $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                                -Name IsConnected `
                                -Value {
                                param($x)
                                return $true
                            } -PassThru -Force
                            return $spServiceApp
                        }
                    }

                    if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 16)
                    {
                        Mock -CommandName Get-SPServiceApplication -MockWith {
                            $spServiceApp = [PSCustomObject]@{
                                TypeName        = "Managed Metadata Service"
                                DisplayName     = $testParams.Name
                                ApplicationPool = @{
                                    Name = $testParams.ApplicationPool
                                }
                                Database        = @{
                                    Name   = $testParams.DatabaseName
                                    Server = @{ Name = $testParams.DatabaseServer }
                                }
                            }
                            $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
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
                                                            -Value "DatabaseMapper" `
                                                            -PassThru |
                                                            Add-Member -MemberType ScriptMethod `
                                                                -Name GetValue `
                                                                -Value {
                                                                param($x)
                                                                return (@{
                                                                        FullName = $getTypeFullName
                                                                    }) | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                                                                    return (@{
                                                                            FullName = $getTypeFullName
                                                                        }) | Add-Member -MemberType ScriptMethod -Name GetMethods -Value {
                                                                        return (@{
                                                                                Name = "GetContentTypeSyndicationHubLocal"
                                                                            }) | Add-Member -MemberType ScriptMethod -Name Invoke -Value {
                                                                            return @{
                                                                                AbsoluteUri = "http://contoso.sharepoint.com/sites/ct"
                                                                            }
                                                                        } -PassThru -Force
                                                                    } -PassThru -Force
                                                                } -PassThru -Force
                                                            } -PassThru
                                                        )
                                                    )
                                                } -PassThru
                                            } -PassThru -Force
                                            $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                                                -Name IsConnected `
                                                -Value {
                                                param($x)
                                                return $true
                                            } -PassThru -Force
                                            return $spServiceApp
                                        }
                                    }

                                    $termStoreAdmins = @(
                                        New-Object -TypeName PSObject -Property @{
                                            PrincipalName               = "Contoso\User1"
                                            IsWindowsAuthenticationMode = $true
                                        }
                                        New-Object -TypeName PSObject -Property @{
                                            PrincipalName               = "Contoso\User2"
                                            IsWindowsAuthenticationMode = $true
                                        }
                                    )
                                    $termStoreAdmins = $termStoreAdmins | Add-Member -MemberType ScriptMethod `
                                        -Name DoesUserHavePermissions `
                                        -Value {
                                        param ($userName)
                                        return $true
                                    } -PassThru -Force

                                    $termStores = @{
                                        "Managed Metadata Service App Proxy" = @{
                                            Name                    = "Managed Metadata Service App Proxy"
                                            Languages               = @(1031)
                                            DefaultLanguage         = 1031
                                            WorkingLanguage         = 1033
                                            TermStoreAdministrators = $termStoreAdmins
                                        } | Add-Member -MemberType ScriptMethod `
                                            -Name AddTermStoreAdministrator `
                                            -Value { $Global:SPDscAddUserCalled = $true }  `
                                            -PassThru -Force `
                                        | Add-Member -MemberType ScriptMethod `
                                            -Name DeleteTermStoreAdministrator `
                                            -Value { $Global:SPDscDeleteUserCalled = $true }  `
                                            -PassThru -Force `
                                        | Add-Member -MemberType ScriptMethod `
                                            -Name CommitAll `
                                            -Value { }  `
                                            -PassThru -Force `
                                        | Add-Member -MemberType ScriptMethod `
                                            -Name AddLanguage `
                                            -Value { $Global:SPDscAddLanguageCalled = $true }  `
                                            -PassThru -Force `
                                        | Add-Member -MemberType ScriptMethod `
                                            -Name DeleteLanguage `
                                            -Value { $Global:SPDscDeleteLanguageCalled = $true }  `
                                            -PassThru -Force `
                                        | Add-Member -MemberType ScriptMethod `
                                            -Name CommitAll `
                                            -Value { }  `
                                            -PassThru -Force
                    }

                    Mock -CommandName Get-SPTaxonomySession -MockWith {
                        return @{
                            TermStores = $termStores
                        }
                    }

                    $metadataServiceApplicationProxy = @{
                        Name       = "Managed Metadata Service App Proxy"
                        Properties = @{
                            IsContentTypePushdownEnabled      = $true
                            IsNPContentTypeSyndicationEnabled = $true
                        }
                    } | Add-Member -MemberType ScriptMethod `
                        -Name Update `
                        -Value { $Global:SPDscMetaDataServiceApplicationProxyUpdateCalled = $true } `
                        -PassThru -Force

                    Mock -CommandName Get-SPMetadataServiceApplicationProxy -MockWith {
                        return $metadataServiceApplicationProxy
                    }
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should match the mocked values" {
                    $result = Get-TargetResource @testParams
                    $result.DefaultLanguage | Should -Be 1031
                    $result.Languages | Should -Be @(1031)
                }

                It "Should change the value for 'Default Language'" {
                    $result = Get-TargetResource @testParams
                    Set-TargetResource @testParams
                    $termStores["$($result.ProxyName)"].DefaultLanguage | Should -Be $testParams.DefaultLanguage
                }

                It "Should change the value for 'Languages'" {
                    $Global:SPDscAddLanguageCalled = $false
                    $Global:SPDscDeleteLanguageCalled = $false
                    Set-TargetResource @testParams
                    $Global:SPDscAddLanguageCalled | Should -Be $true
                    $Global:SPDscDeleteLanguageCalled | Should -Be $true
                }

                It "Should change the value for 'ContentTypePushdownEnabled'" {
                    $testParams = @{
                        Name                          = "Managed Metadata Service App"
                        ApplicationPool               = "SharePoint Service Applications"
                        DatabaseServer                = "databaseserver\instance"
                        DatabaseName                  = "SP_MMS"
                        Ensure                        = "Present"
                        DefaultLanguage               = 1033
                        Languages                     = @(1033)
                        ContentTypePushdownEnabled    = $true
                        ContentTypeSyndicationEnabled = $false
                    }

                    $Global:SPDscMetaDataServiceApplicationProxyUpdateCalled = $false
                    Set-TargetResource @testParams
                    $Global:SPDscMetaDataServiceApplicationProxyUpdateCalled | Should -Be $true
                    $metadataServiceApplicationProxy.Properties["IsContentTypePushdownEnabled"] | Should -Be $true
                }

                It "Should change the value for 'ContentTypeSyndicationEnabled'" {
                    $testParams = @{
                        Name                          = "Managed Metadata Service App"
                        ApplicationPool               = "SharePoint Service Applications"
                        DatabaseServer                = "databaseserver\instance"
                        DatabaseName                  = "SP_MMS"
                        Ensure                        = "Present"
                        DefaultLanguage               = 1033
                        Languages                     = @(1033)
                        ContentTypePushdownEnabled    = $false
                        ContentTypeSyndicationEnabled = $true
                    }

                    $Global:SPDscMetaDataServiceApplicationProxyUpdateCalled = $false
                    Set-TargetResource @testParams
                    $Global:SPDscMetaDataServiceApplicationProxyUpdateCalled | Should -Be $true
                    $metadataServiceApplicationProxy.Properties["IsNPContentTypeSyndicationEnabled"] | Should -Be $true
                }
            }

            Context -Name "When there is no Managed Metadata Service and everything should be created and configured correctly" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                    = "Managed Metadata Service App"
                        ProxyName               = "Managed Metadata Service Application Proxy"
                        ApplicationPool         = "SharePoint Service Applications"
                        DatabaseServer          = "databaseserver\instance"
                        DatabaseName            = "SP_MMS"
                        Ensure                  = "Present"
                        DefaultLanguage         = 1031
                        Languages               = @(1031)
                        TermStoreAdministrators = @(
                            "CONTOSO\User1",
                            "CONTOSO\User2"
                        )
                        ContentTypeHubUrl       = "http://contoso.sharepoint.com/sites/ctnew"
                    }

                    # There is no service application
                    Mock -CommandName Get-SPServiceApplication -MockWith { return $null }
                }

                It "Should return absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create a new service application and proxy in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPMetadataServiceApplication
                    Assert-MockCalled New-SPMetadataServiceApplicationProxy
                }
            }

            Context -Name "Update settings, making sure the service app is configured correctly" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                    = "Managed Metadata Service App"
                        ProxyName               = "Managed Metadata Service Application Proxy"
                        ApplicationPool         = "SharePoint Service Applications"
                        DatabaseServer          = "databaseserver\instance"
                        DatabaseName            = "SP_MMS"
                        Ensure                  = "Present"
                        DefaultLanguage         = 1031
                        Languages               = @(1031)
                        TermStoreAdministrators = @(
                            "CONTOSO\User1",
                            "CONTOSO\User2"
                        )
                        ContentTypeHubUrl       = "http://contoso.sharepoint.com/sites/ctnew"
                    }

                    # There is no service application
                    Mock -CommandName Get-SPServiceApplication -MockWith { return $null }

                    if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                    {
                        Mock -CommandName Get-SPServiceApplication -MockWith {
                            $spServiceApp = [PSCustomObject]@{
                                TypeName        = "Managed Metadata Service"
                                DisplayName     = $testParams.Name
                                ApplicationPool = @{
                                    Name = $testParams.ApplicationPool
                                }
                                Database        = @{
                                    Name   = $testParams.DatabaseName
                                    Server = @{ Name = $testParams.DatabaseServer }
                                }
                            }
                            $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                                return (@{
                                        FullName = $getTypeFullName
                                    }) | Add-Member -MemberType ScriptMethod -Name GetMethods -Value {
                                    return (@{
                                            Name = "GetContentTypeSyndicationHubLocal"
                                        }) | Add-Member -MemberType ScriptMethod -Name Invoke -Value {
                                        return @{
                                            AbsoluteUri = "http://contoso.sharepoint.com/sites/ct"
                                        }
                                    } -PassThru -Force
                                } -PassThru -Force
                            } -PassThru -Force
                            $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                                -Name IsConnected `
                                -Value {
                                param($x)
                                return $true
                            } -PassThru -Force
                            return $spServiceApp
                        }
                    }

                    if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 16)
                    {
                        Mock -CommandName Get-SPServiceApplication -MockWith {
                            $spServiceApp = [PSCustomObject]@{
                                TypeName        = "Managed Metadata Service"
                                DisplayName     = $testParams.Name
                                ApplicationPool = @{
                                    Name = $testParams.ApplicationPool
                                }
                                Database        = @{
                                    Name   = $testParams.DatabaseName
                                    Server = @{ Name = $testParams.DatabaseServer }
                                }
                            }
                            $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
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
                                                            -Value "DatabaseMapper" `
                                                            -PassThru |
                                                            Add-Member -MemberType ScriptMethod `
                                                                -Name GetValue `
                                                                -Value {
                                                                param($x)
                                                                return (@{
                                                                        FullName = $getTypeFullName
                                                                    }) | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                                                                    return (@{
                                                                            FullName = $getTypeFullName
                                                                        }) | Add-Member -MemberType ScriptMethod -Name GetMethods -Value {
                                                                        return (@{
                                                                                Name = "GetContentTypeSyndicationHubLocal"
                                                                            }) | Add-Member -MemberType ScriptMethod -Name Invoke -Value {
                                                                            return @{
                                                                                AbsoluteUri = "http://contoso.sharepoint.com/sites/ct"
                                                                            }
                                                                        } -PassThru -Force
                                                                    } -PassThru -Force
                                                                } -PassThru -Force
                                                            } -PassThru
                                                        )
                                                    )
                                                } -PassThru
                                            } -PassThru -Force
                                            $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                                                -Name IsConnected `
                                                -Value {
                                                param($x)
                                                return $true
                                            } -PassThru -Force
                                            return $spServiceApp
                                        }
                                    }

                                    Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                                        return @(
                                            @{
                                                Name = "Managed Metadata Service Application Proxy"
                                            } | Add-Member -MemberType ScriptMethod `
                                                -Name Update `
                                                -Value { $Global:SPDscServiceProxyUpdateCalled = $true }  `
                                                -PassThru -Force `
                                            | Add-Member -MemberType ScriptMethod `
                                                -Name Delete `
                                                -Value { $Global:SPDscServiceProxyDeleteCalled = $true } `
                                                -PassThru -Force
                        )
                    }

                    $termStoreAdmins = @(
                        New-Object -TypeName PSObject -Property @{
                            PrincipalName               = "Contoso\UserToGetAddMemberWorking"
                            IsWindowsAuthenticationMode = $true
                        }
                    )
                    $termStoreAdmins = $termStoreAdmins | Add-Member -MemberType ScriptMethod `
                        -Name DoesUserHavePermissions `
                        -Value {
                        param ($userName)
                        return $false
                    } -PassThru -Force

                    $termStores = @{
                        "Managed Metadata Service Application Proxy" = @{
                            Name                    = "Managed Metadata Service Application Proxy"
                            Languages               = @(1033)
                            DefaultLanguage         = 1033
                            WorkingLanguage         = 1033
                            TermStoreAdministrators = $termStoreAdmins
                        } | Add-Member -MemberType ScriptMethod `
                            -Name AddTermStoreAdministrator `
                            -Value { $Global:SPDscAddUserCalled = $true }  `
                            -PassThru -Force `
                        | Add-Member -MemberType ScriptMethod `
                            -Name DeleteTermStoreAdministrator `
                            -Value { $Global:SPDscDeleteUserCalled = $true }  `
                            -PassThru -Force `
                        | Add-Member -MemberType ScriptMethod `
                            -Name CommitAll `
                            -Value { }  `
                            -PassThru -Force `
                        | Add-Member -MemberType ScriptMethod `
                            -Name AddLanguage `
                            -Value { $Global:SPDscAddLanguageCalled = $true }  `
                            -PassThru -Force `
                        | Add-Member -MemberType ScriptMethod `
                            -Name DeleteLanguage `
                            -Value { $Global:SPDscDeleteLanguageCalled = $true }  `
                            -PassThru -Force `
                        | Add-Member -MemberType ScriptMethod `
                            -Name CommitAll `
                            -Value { }  `
                            -PassThru -Force
                    }

                    Mock -CommandName Get-SPTaxonomySession -MockWith {
                        return @{
                            TermStores = $termStores
                        }
                    }
                }

                It "Should call the update service app cmdlet from the set method for 'Content Type Hub Url'" {
                    Set-TargetResource @testParams

                    Assert-MockCalled Set-SPMetadataServiceApplication
                }

                It "Should call the add method from the set method for 'Term Store Administrators'" {
                    $Global:SPDscAddUserCalled = $false

                    Set-TargetResource @testParams

                    $Global:SPDscAddUserCalled | Should -Be $true
                }

                It "Should change the value for 'Default Language'" {
                    $Global:SPDscAddUserCalled = $false
                    $Global:SPDscDeleteUserCalled = $false

                    Set-TargetResource @testParams

                    $termStores["$($testParams.ProxyName)"].DefaultLanguage | Should -Be $testParams.DefaultLanguage
                    $Global:SPDscAddUserCalled | Should -Be $true
                    $Global:SPDscDeleteUserCalled | Should -Be $true
                }

                It "Should change the value for 'Languages'" {
                    $Global:SPDscAddLanguageCalled = $false
                    $Global:SPDscDeleteLanguageCalled = $false
                    $Global:SPDscAddUserCalled = $false
                    $Global:SPDscDeleteUserCalled = $false

                    Set-TargetResource @testParams

                    $Global:SPDscAddLanguageCalled | Should -Be $true
                    $Global:SPDscDeleteLanguageCalled | Should -Be $true
                    $Global:SPDscAddUserCalled | Should -Be $true
                    $Global:SPDscDeleteUserCalled | Should -Be $true
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Name                          = "Managed Metadata Service Application"
                            ProxyName                     = "Managed Metadata Service Application Proxy"
                            Ensure                        = "Present"
                            ApplicationPool               = "Service App Pool"
                            DatabaseServer                = "SQL01"
                            DatabaseName                  = "SP_ManagedMetadata"
                            TermStoreAdministrators       = @(
                                "CONTOSO\user1",
                                "CONTOSO\user2"
                            )
                            ContentTypeHubUrl             = "http://sharepoint.contoso.com/sites/ct"
                            DefaultLanguage               = 1033
                            Languages                     = @(1031, 1033)
                            ContentTypePushdownEnabled    = $true
                            ContentTypeSyndicationEnabled = $true
                        }
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            DisplayName = "Managed Metadata Service Application"
                            Name        = "Managed Metadata Service Application"
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return @{
                                Name = "MetadataWebServiceApplication"
                            }
                        } -PassThru -Force
                        return $spServiceApp
                    }

                    Mock -CommandName Get-SPDscDBForAlias -MockWith { return "SQL01" }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        SPManagedMetaDataServiceApp ManagedMetadataServiceApplication
        {
            ApplicationPool               = "Service App Pool";
            ContentTypeHubUrl             = "http://sharepoint.contoso.com/sites/ct";
            ContentTypePushdownEnabled    = $True;
            ContentTypeSyndicationEnabled = $True;
            DatabaseName                  = "SP_ManagedMetadata";
            DatabaseServer                = $ConfigurationData.NonNodeData.DatabaseServer;
            DefaultLanguage               = 1033;
            Ensure                        = "Present";
            Languages                     = @(10311033);
            Name                          = "Managed Metadata Service Application";
            ProxyName                     = "Managed Metadata Service Application Proxy";
            PsDscRunAsCredential          = $Credsspfarm;
            TermStoreAdministrators       = @("CONTOSO\user1","CONTOSO\user2");
        }

'@
                }

                It "Should return valid DSC block from the Export method" {
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")
                    Export-TargetResource | Should -Be $result
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
