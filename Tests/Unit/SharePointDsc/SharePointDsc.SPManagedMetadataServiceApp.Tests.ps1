[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
            -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
        -ChildPath "..\UnitTestHelper.psm1" `
        -Resolve)

$Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
    -DscResource "SPManagedMetaDataServiceApp"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        #Initialize Tests
        $getTypeFullName = "Microsoft.SharePoint.Taxonomy.MetadataWebServiceApplication"

        # Mocks for all contexts
        Mock -CommandName New-SPMetadataServiceApplication -MockWith { return @{} }
        Mock -CommandName New-SPMetadataServiceApplicationProxy -MockWith { return @{} }
        Mock -CommandName Set-SPMetadataServiceApplication -MockWith { }
        Mock -CommandName Remove-SPServiceApplication -MockWith { }
        Mock -CommandName Get-SPWebApplication -MockWith {
            return @(
                @{
                    Url                            = "http://FakeCentralAdmin.Url"
                    IsAdministrationWebApplication = $true
                }
            )
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

        # Test contexts
        Context -Name "When no service applications exist in the current farm" -Fixture {
            $testParams = @{
                Name                    = "Managed Metadata Service App"
                ApplicationPool         = "SharePoint Service Applications"
                DatabaseServer          = "databaseserver\instance"
                DatabaseName            = "SP_MMS"
                TermStoreAdministrators = @()
                ContentTypeHubUrl       = ""
                ProxyName               = "Proxy Name"
                DefaultLanguage         = 1033
                Languages               = @()
                Ensure                  = "Present"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { return $null }

            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should create a new service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPMetadataServiceApplication
            }
        }

        Context -Name "When service applications exist in the current farm but the specific MMS app does not" -Fixture {
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
                return $spServiceApp
            }

            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context -Name "When a service application exists and is configured correctly" -Fixture {
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

                    return $spServiceApp
                }
            }

            It "Should return present from the get method" {
                $results = Get-TargetResource @testParams
                $results.Ensure | Should Be "Present"
                $results.ContentTypeHubUrl | Should Not BeNullOrEmpty
            }

            It "Should return true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
        }


        Context -Name "When a service application exists and the app pool is not configured correctly" -Fixture {
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
                            Name   = $testParams.DatabaseName
                            Server = @{
                                Name = $testParams.DatabaseServer
                            }
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

                    return $spServiceApp
                }
            }

            Mock -CommandName Get-SPServiceApplicationPool -MockWith {
                return @{
                    Name = $testParams.ApplicationPool
                }
            }

            It "Should return Wrong App Pool Name from the Get method" {
                (Get-TargetResource @testParams).ApplicationPool | Should Be "Wrong App Pool Name"
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
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
                            Name = $testParams.AookucationPool
                        }
                        Database        = @{
                            Name   = $testParams.DatabaseName
                            Server = @{
                                Name = $testParams.DatabaseServer
                            }
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

                    return $spServiceApp
                }
            }

            Mock -CommandName Get-SPServiceApplicationPool -MockWith {
                return @{
                    Name = $testParams.ApplicationPool
                }
            }

            It "Should return wrong content type url from the Get method" {
                (Get-TargetResource @testParams).ContentTypeHubUrl | Should Be "https://contenttypes.contoso.com/wrong"
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call the update service app cmdlet from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Set-SPMetadataServiceApplication
            }
        }

        Context -Name "When the service application exists but it shouldn't" -Fixture {
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
                            Name   = $testParams.DatabaseName
                            Server = @{
                                Name = $testParams.DatabaseServer
                            }
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

                    return $spServiceApp
                }
            }

            It "Should return present from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call the remove service application cmdlet in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPServiceApplication
            }
        }

        Context -Name "When the service application doesn't exist and it shouldn't" -Fixture {
            $testParams = @{
                Name            = "Test App"
                ApplicationPool = "-"
                Ensure          = "Absent"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith {
                return $null
            }

            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "A service app exists and has a correct list of term store administrators" -Fixture {
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
                return $spServiceApp
            }

            It "Should return the current users from the get method" {
                (Get-TargetResource @testParams).TermStoreAdministrators | Should Not BeNullOrEmpty
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should be $true
            }
        }

        Context -Name "A service app exists and is missing a user from the term store administrators list" -Fixture {
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
                return $spServiceApp
            }

            It "Should return the current users from the get method" {
                (Get-TargetResource @testParams).TermStoreAdministrators | Should Not BeNullOrEmpty
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should be $false
            }

            It "Should call the add method from the set method" {
                $Global:SPDscAddUserCalled = $false
                $Global:SPDscDeleteUserCalled = $false
                Set-TargetResource @testParams

                $Global:SPDscAddUserCalled | Should Be $true
            }
        }

        Context -Name "A service app exists and has an extra user on the term store administrators list" -Fixture {
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

            It "Should return the current users from the get method" {
                (Get-TargetResource @testParams).TermStoreAdministrators | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should be $false
            }

            It "Should call the delete method from the set method" {
                $Global:SPDscAddUserCalled = $false
                $Global:SPDscDeleteUserCalled = $false
                Set-TargetResource @testParams

                $Global:SPDscDeleteUserCalled | Should Be $true
            }
        }

        Context -Name "A service app exists and the proxy name has to be changed" -Fixture {
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
                    return ($true)
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
                )
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should be $false
            }

            It "Should call the delete method from the set method" {
                $Global:SPDscServiceProxyUpdateCalled = $false
                Set-TargetResource @testParams

                $Global:SPDscServiceProxyUpdateCalled | Should Be $true
            }
        }

        Context -Name "A service app exists and has a non-windows term store administrator in the list" -Fixture {
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

            It "Should return the current users from the get method" {
                (Get-TargetResource @testParams).TermStoreAdministrators | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should be $false
            }

            It "Should call the delete method from the set method" {
                $Global:SPDscAddUserCalled = $false
                $Global:SPDscDeleteUserCalled = $false
                Set-TargetResource @testParams

                $Global:SPDscDeleteUserCalled | Should Be $true
            }
        }

        # New Test
        Context -Name "When a service proxy exists, it should return the proxy name" -Fixture {
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

            It "Should return the proxy name" {
                (Get-TargetResource @testParams).ProxyName | Should Be "$($testParams.Name) Proxy Test"
            }
        }

        Context -Name "When the termstore for the service application proxy exists in the current farm and is not configured correctly" -Fixture {
            $testParams = @{
                Name            = "Managed Metadata Service Application"
                ApplicationPool = "SharePoint Service Applications"
                DatabaseServer  = "databaseserver\instance"
                DatabaseName    = "SP_MMS"
                Ensure          = "Present"
                DefaultLanguage = 1033
                Languages       = @(1033)
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

                    return $spServiceApp
                }
            }

            $termStores = @{
                "Managed Metadata Service Application Proxy" = @{
                    Name                    = "Managed Metadata Service Application Proxy"
                    Languages               = @(1031)
                    DefaultLanguage         = 1031
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

            It "Should return false when the Test method is called" {
                 Test-TargetResource @testParams | Should Be $false
            }

            It "Should match the mocked values" {
                $result = Get-TargetResource @testParams
                $result.DefaultLanguage | Should Be 1031
                $result.Languages | Should Be @(1031)
            }

            It "Should change the value for 'Default Language'" {
                Set-TargetResource @testParams
                $termStores["$($testParams.Name) Proxy"].DefaultLanguage | Should Be $testParams.DefaultLanguage
            }

            It "Should change the value for 'Languages'" {
                $Global:SPDscAddLanguageCalled = $false
                $Global:SPDscDeleteLanguageCalled = $false
                Set-TargetResource @testParams
                $Global:SPDscAddLanguageCalled | Should Be $true
                $Global:SPDscDeleteLanguageCalled | Should Be $true
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
