[CmdletBinding()]
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
                                              -DscResource "SPFarm"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

# Initialize tests
        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
        $mockFarmAccount = New-Object -TypeName "System.Management.Automation.PSCredential" `
                                      -ArgumentList @("username", $mockPassword)
        $mockPassphrase = New-Object -TypeName "System.Management.Automation.PSCredential" `
                                     -ArgumentList @("PASSPHRASEUSER", $mockPassword)

        $modulePath = "Modules\SharePointDsc\Modules\SharePointDsc.Farm\SPFarm.psm1"
        Import-Module -Name (Join-Path -Path $Global:SPDscHelper.RepoRoot -ChildPath $modulePath -Resolve)

        # Mocks for all contexts
        Mock -CommandName "Add-SPDscConfigDBLock" -MockWith { }
        Mock -CommandName "Remove-SPDscConfigDBLock" -MockWith { }
        Mock -CommandName "New-SPConfigurationDatabase" -MockWith { }
        Mock -CommandName "Connect-SPConfigurationDatabase" -MockWith { }
        Mock -CommandName "Install-SPHelpCollection" -MockWith { }
        Mock -CommandName "Initialize-SPResourceSecurity" -MockWith { }
        Mock -CommandName "Install-SPService" -MockWith { }
        Mock -CommandName "Install-SPFeature" -MockWith { }
        Mock -CommandName "New-SPCentralAdministration" -MockWith { }
        Mock -CommandName "Import-Module" -MockWith { }
        Mock -CommandName "Start-Sleep" -MockWith { }
        Mock -CommandName "Start-Service" -MockWith { }
        Mock -CommandName "Stop-Service" -MockWith { }
        Mock -CommandName "Start-SPServiceInstance" -MockWith { }

        # Test Contexts
        Context -Name "No config databaes exists, and this server should be connected to one" -Fixture {
            $testParams = @{
                IsSingleInstance = "Yes"
                Ensure = "Present"
                FarmConfigDatabaseName = "SP_Config"
                DatabaseServer = "sql.contoso.com"
                FarmAccount = $mockFarmAccount
                Passphrase = $mockPassphrase
                AdminContentDatabaseName = "SP_AdminContent"
                RunCentralAdmin = $true
            }

            Mock -CommandName "Get-SPDSCRegistryKey" -MockWith { return $null }
            Mock -CommandName "Get-SPFarm" -MockWith { return $null }
            Mock -CommandName "Get-SPDSCConfigDBStatus" -MockWith {
                return @{
                    Locked = $false
                    ValidPermissions = $true
                    DatabaseExists = $false
                }
            }
            Mock -CommandName "Get-SPWebApplication" -MockWith {
                return @{
                    IsAdministrationWebApplication = $true
                    Url = "http://localhost:12345"
                }
            }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should be $false
            }

            It "Should create the config database in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled -CommandName "New-SPConfigurationDatabase"
                Assert-MockCalled -CommandName "New-SPCentralAdministration"
            }
        }

        Context -Name "No config databaes exists, and this server should be connected to one but won't run central admin" -Fixture {
            $testParams = @{
                IsSingleInstance = "Yes"
                Ensure = "Present"
                FarmConfigDatabaseName = "SP_Config"
                DatabaseServer = "sql.contoso.com"
                FarmAccount = $mockFarmAccount
                Passphrase = $mockPassphrase
                AdminContentDatabaseName = "SP_AdminContent"
                RunCentralAdmin = $false
            }

            Mock -CommandName "Get-SPDSCRegistryKey" -MockWith { return $null }
            Mock -CommandName "Get-SPFarm" -MockWith { return $null }
            Mock -CommandName "Get-SPDSCConfigDBStatus" -MockWith {
                return @{
                    Locked = $false
                    ValidPermissions = $true
                    DatabaseExists = $false
                }
            }
            Mock -CommandName "Get-SPWebApplication" -MockWith {
                return @{
                    IsAdministrationWebApplication = $true
                    Url = "http://localhost:12345"
                }
            }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should be $false
            }

            It "Should join the config database in the set method as it wont be running centrl admin" {
                Set-TargetResource @testParams
                Assert-MockCalled -CommandName "Connect-SPConfigurationDatabase"
            }
        }

        Context -Name "A config database exists, and this server should be connected to it but isn't and this sever won't run central admin" -Fixture {
            $testParams = @{
                IsSingleInstance = "Yes"
                Ensure = "Present"
                FarmConfigDatabaseName = "SP_Config"
                DatabaseServer = "sql.contoso.com"
                FarmAccount = $mockFarmAccount
                Passphrase = $mockPassphrase
                AdminContentDatabaseName = "SP_AdminContent"
                RunCentralAdmin = $false
            }

            Mock -CommandName "Get-SPDSCRegistryKey" -MockWith { return $null }
            Mock -CommandName "Get-SPFarm" -MockWith { return $null }
            Mock -CommandName "Get-SPDSCConfigDBStatus" -MockWith {
                return @{
                    Locked = $false
                    ValidPermissions = $true
                    DatabaseExists = $true
                }
            }
            Mock -CommandName "Get-SPWebApplication" -MockWith {
                return @{
                    IsAdministrationWebApplication = $true
                    Url = "http://localhost:9999"
                }
            }
            Mock -CommandName "Get-CimInstance" -MockWith {
                return @{
                    Domain = "test.lab"
                }
            }
            Mock -CommandName "Get-SPServiceInstance" -MockWith {
                if ($global:SPDscCentralAdminCheckDone -eq $true)
                {
                    return @(@{
                        TypeName = "Central Administration"
                    })
                }
                else
                {
                    $global:SPDscCentralAdminCheckDone = $true
                    return $null
                }
            }

            Mock -CommandName "Get-SPWebApplication" -MockWith {
                return @{
                    IsAdministrationWebApplication = $true
                    ContentDatabases = @(@{
                        Name = $testParams.AdminContentDatabaseName
                    })
                    Url = "http://localhost:9999"
                }
            }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should be $false
            }

            $global:SPDscCentralAdminCheckDone = $false
            It "Should join the config database in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled -CommandName "Connect-SPConfigurationDatabase"
            }
        }

        Context -Name "A config database exists, and this server should be connected to it but isn't and this sever will run central admin" -Fixture {
            $testParams = @{
                IsSingleInstance = "Yes"
                Ensure = "Present"
                FarmConfigDatabaseName = "SP_Config"
                DatabaseServer = "sql.contoso.com"
                FarmAccount = $mockFarmAccount
                Passphrase = $mockPassphrase
                AdminContentDatabaseName = "SP_AdminContent"
                RunCentralAdmin = $true
            }

            Mock -CommandName "Get-SPDSCRegistryKey" -MockWith { return $null }
            Mock -CommandName "Get-SPFarm" -MockWith { return $null }
            Mock -CommandName "Get-SPDSCConfigDBStatus" -MockWith {
                return @{
                    Locked = $false
                    ValidPermissions = $true
                    DatabaseExists = $true
                }
            }
            Mock -CommandName "Get-SPWebApplication" -MockWith {
                return @{
                    IsAdministrationWebApplication = $true
                    Url = "http://localhost:9999"
                }
            }

            Mock -CommandName "Get-SPWebApplication" -MockWith {
                return @{
                    IsAdministrationWebApplication = $true
                    ContentDatabases = @(@{
                        Name = $testParams.AdminContentDatabaseName
                    })
                    Url = "http://localhost:9999"
                }
            }
            Mock -CommandName "Get-SPServiceInstance" -MockWith {
                if ($global:SPDscCentralAdminCheckDone -eq $true)
                {
                    return @(@{
                        TypeName = "Central Administration"
                    })
                }
                else
                {
                    $global:SPDscCentralAdminCheckDone = $true
                    return $null
                }
            }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should be $false
            }

            $global:SPDscCentralAdminCheckDone = $false
            It "Should join the config database in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled -CommandName "Connect-SPConfigurationDatabase"
                Assert-MockCalled -CommandName "Start-SPServiceInstance"
            }
        }

        Context -Name "A config and lock database exist, and this server should be connected to it but isn't" -Fixture {
            $testParams = @{
                IsSingleInstance = "Yes"
                Ensure = "Present"
                FarmConfigDatabaseName = "SP_Config"
                DatabaseServer = "sql.contoso.com"
                FarmAccount = $mockFarmAccount
                Passphrase = $mockPassphrase
                AdminContentDatabaseName = "SP_AdminContent"
                RunCentralAdmin = $true
            }

            Mock -CommandName "Get-SPDSCRegistryKey" -MockWith { return $null }
            Mock -CommandName "Get-SPFarm" -MockWith { return $null }
            Mock -CommandName "Get-SPDSCConfigDBStatus" -MockWith {
                if ($global:SPDscConfigLockTriggered)
                {
                    return @{
                        Locked = $false
                        ValidPermissions = $true
                        DatabaseExists = $true
                    }
                }
                else
                {
                    $global:SPDscConfigLockTriggered = $true
                    return @{
                        Locked = $true
                        ValidPermissions = $true
                        DatabaseExists = $true
                    }
                }
            }
            Mock -CommandName "Get-SPWebApplication" -MockWith {
                return @{
                    IsAdministrationWebApplication = $true
                    Url = "http://localhost:12345"
                }
            }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should be $false
            }

            $global:SPDscConfigLockTriggered = $false
            It "Should wait for the lock to be released then join the config DB in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled -CommandName "Get-SPDSCConfigDBStatus" -Times 2
                Assert-MockCalled -CommandName "Connect-SPConfigurationDatabase"
            }
        }

        Context -Name "Server is connected to farm, but Central Admin isn't started" -Fixture {
            $testParams = @{
                Ensure = "Present"
                FarmConfigDatabaseName = "SP_Config"
                DatabaseServer = "sql.contoso.com"
                FarmAccount = $mockFarmAccount
                Passphrase = $mockPassphrase
                AdminContentDatabaseName = "SP_AdminContent"
                RunCentralAdmin = $true
            }

            Mock -CommandName Get-SPDSCRegistryKey -MockWith {
                return "Connection string example"
            }

            Mock -CommandName Get-SPFarm -MockWith {
                return @{
                    Name = $testParams.FarmConfigDatabaseName
                    DatabaseServer = @{
                        Name = $testParams.DatabaseServer
                    }
                    AdminContentDatabaseName = $testParams.AdminContentDatabaseName
                }
            }
            Mock -CommandName Get-SPDSCConfigDBStatus -MockWith {
                return @{
                    Locked = $false
                    ValidPermissions = $true
                    DatabaseExists = $true
                }
            }
            Mock -CommandName Get-SPDatabase -MockWith {
                return @(@{
                    Name = $testParams.FarmConfigDatabaseName
                    Type = "Configuration Database"
                    NormalizedDataSource = $testParams.DatabaseServer
                })
            }
            Mock -CommandName Get-SPWebApplication -MockWith {
                return @{
                    IsAdministrationWebApplication = $true
                    ContentDatabases = @(@{
                        Name = $testParams.AdminContentDatabaseName
                    })
                    IISSettings = @(@{
                        DisableKerberos = $true
                    })
                    Url = "http://localhost:9999"
                }
            }
            Mock -CommandName Get-CimInstance -MockWith {
                return @{
                    Domain = "domain.com"
                }
            }

            Mock -CommandName Get-SPServiceInstance -MockWith {
                switch ($global:SPDscSIRunCount)
                {
                    { 2 -contains $_ }
                        {
                            $global:SPDscSIRunCount++
                            return @(@{
                                TypeName = "Central Administration"
                                Status = "Online"
                            })
                        }
                    { 0,1 -contains $_ }
                        {
                            $global:SPDscSIRunCount++
                            return $null
                        }
                }
            }

            $global:SPDscSIRunCount = 0
            It "Should return false from the get method" {
                (Get-TargetResource @testParams).RunCentralAdmin | Should Be $false
            }

            $global:SPDscSIRunCount = 0
            It "Should start the central administration instance" {
                Set-TargetResource @testParams
                Assert-MockCalled -CommandName "Start-SPServiceInstance"
            }

            $global:SPDscCentralAdminCheckDone = $false
            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should be $false
            }
        }

        Context -Name "This server is connected to the farm and is running CA, but shouldn't" -Fixture {
            $testParams = @{
                Ensure = "Present"
                FarmConfigDatabaseName = "SP_Config"
                DatabaseServer = "sql.contoso.com"
                FarmAccount = $mockFarmAccount
                Passphrase = $mockPassphrase
                AdminContentDatabaseName = "SP_AdminContent"
                RunCentralAdmin = $false
            }

            Mock -CommandName "Get-SPDSCRegistryKey" -MockWith {
                return "Connection string example"
            }

            Mock -CommandName "Get-SPFarm" -MockWith {
                return @{
                    Name = $testParams.FarmConfigDatabaseName
                    DatabaseServer = @{
                        Name = $testParams.DatabaseServer
                    }
                    AdminContentDatabaseName = $testParams.AdminContentDatabaseName
                }
            }
            Mock -CommandName "Get-SPDSCConfigDBStatus" -MockWith {
                return @{
                    Locked = $false
                    ValidPermissions = $true
                    DatabaseExists = $true
                }
            }
            Mock -CommandName "Get-SPDatabase" -MockWith {
                return @(@{
                    Name = $testParams.FarmConfigDatabaseName
                    Type = "Configuration Database"
                    NormalizedDataSource = $testParams.DatabaseServer
                })
            }
            Mock -CommandName "Get-SPWebApplication" -MockWith {
                return @{
                    IsAdministrationWebApplication = $true
                    ContentDatabases = @(@{
                        Name = $testParams.AdminContentDatabaseName
                    })
                    IISSettings = @(@{
                        DisableKerberos = $true
                    })
                    Url = "http://localhost:9999"
                }
            }
            Mock -CommandName Start-Sleep -MockWith {}
            Mock -CommandName Get-SPServiceInstance -MockWith {
                switch ($global:SPDscSIRunCount)
                {
                    { 0,2 -contains $_ }
                        {
                            $global:SPDscSIRunCount++
                            return @(@{
                                TypeName = "Central Administration"
                                Status = "Online"
                            })
                        }
                    { 1 -contains $_ }
                        {
                            $global:SPDscSIRunCount++
                            return $null
                        }
                }
            }
            Mock -CommandName "Stop-SPServiceInstance" -MockWith {}

            $global:SPDscSIRunCount = 0
            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            $global:SPDscSIRunCount = 0
            It "Should return present from the get method" {
                Set-TargetResource @testParams
                Assert-MockCalled Stop-SPServiceInstance
            }

            $global:SPDscSIRunCount = 0
            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should be $false
            }
        }

        Context -Name "A config database exists, and this server is connected to it and should be" -Fixture {
            $testParams = @{
                IsSingleInstance = "Yes"
                Ensure = "Present"
                FarmConfigDatabaseName = "SP_Config"
                DatabaseServer = "sql.contoso.com"
                FarmAccount = $mockFarmAccount
                Passphrase = $mockPassphrase
                AdminContentDatabaseName = "SP_AdminContent"
                RunCentralAdmin = $true
            }

            Mock -CommandName "Get-SPDSCRegistryKey" -MockWith {
                return "Connection string example"
            }

            Mock -CommandName "Get-SPFarm" -MockWith {
                return @{
                    Name = $testParams.FarmConfigDatabaseName
                    DatabaseServer = @{
                        Name = $testParams.DatabaseServer
                    }
                    AdminContentDatabaseName = $testParams.AdminContentDatabaseName
                }
            }
            Mock -CommandName "Get-SPDSCConfigDBStatus" -MockWith {
                return @{
                    Locked = $false
                    ValidPermissions = $true
                    DatabaseExists = $true
                }
            }
            Mock -CommandName "Get-SPDatabase" -MockWith {
                return @(@{
                    Name = $testParams.FarmConfigDatabaseName
                    Type = "Configuration Database"
                    NormalizedDataSource = $testParams.DatabaseServer
                })
            }
            Mock -CommandName "Get-SPWebApplication" -MockWith {
                return @{
                    IsAdministrationWebApplication = $true
                    ContentDatabases = @(@{
                        Name = $testParams.AdminContentDatabaseName
                    })
                    IISSettings = @(@{
                        DisableKerberos = $true
                    })
                    Url = "http://localhost:9999"
                }
            }
            Mock -CommandName "Get-SPServiceInstance" -MockWith {
                if ($global:SPDscCentralAdminCheckDone -eq $true)
                {
                    return @(@{
                        TypeName = "Central Administration"
                        Status = "Online"
                    })
                }
                else
                {
                    $global:SPDscCentralAdminCheckDone = $true
                    return $null
                }
            }

            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should be $true
            }
        }

        Context -Name "Absent is specified for the ensure property" -Fixture {
            $testParams = @{
                IsSingleInstance = "Yes"
                Ensure = "Absent"
                FarmConfigDatabaseName = "SP_Config"
                DatabaseServer = "sql.contoso.com"
                FarmAccount = $mockFarmAccount
                Passphrase = $mockPassphrase
                AdminContentDatabaseName = "SP_AdminContent"
                RunCentralAdmin = $true
            }

            It "Should throw an exception from the get method" {
                { Get-TargetResource @testParams } | Should Throw
            }

            It "Should throw an exception from the test method" {
                { Test-TargetResource @testParams } | Should Throw
            }

            It "Should throw an exception from the set method" {
                { Set-TargetResource @testParams } | Should Throw
            }
        }

        if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
        {
            Context -Name "Only valid parameters for SharePoint 2013 are used" -Fixture {
                $testParams = @{
                    IsSingleInstance = "Yes"
                    Ensure = "Present"
                    FarmConfigDatabaseName = "SP_Config"
                    DatabaseServer = "DatabaseServer\Instance"
                    FarmAccount = $mockFarmAccount
                    Passphrase =  $mockPassphrase
                    AdminContentDatabaseName = "Admin_Content"
                    CentralAdministrationAuth = "Kerberos"
                    CentralAdministrationPort = 1234
                    ServerRole = "WebFrontEnd"
                    RunCentralAdmin = $true
                }

                It "Should throw if server role is used in the get method" {
                    { Get-TargetResource @testParams } | Should Throw
                }

                It "Should throw if server role is used in the test method" {
                    { Test-TargetResource @testParams } | Should Throw
                }

                It "Should throw if server role is used in the set method" {
                    { Set-TargetResource @testParams } | Should Throw
                }
            }

            Context -Name "no serverrole is specified and get-targetresource needs to return null" -Fixture {
                $testParams = @{
                    IsSingleInstance = "Yes"
                    Ensure = "Present"
                    FarmConfigDatabaseName = "SP_Config"
                    DatabaseServer = "sql.contoso.com"
                    FarmAccount = $mockFarmAccount
                    Passphrase = $mockPassphrase
                    AdminContentDatabaseName = "SP_AdminContent"
                    RunCentralAdmin = $true
                }

                Mock -CommandName "Get-SPDSCRegistryKey" -MockWith {
                    return "Connection string example"
                }

                Mock -CommandName "Get-SPFarm" -MockWith {
                    return @{
                        Name = $testParams.FarmConfigDatabaseName
                        DatabaseServer = @{
                            Name = $testParams.DatabaseServer
                        }
                        AdminContentDatabaseName = $testParams.AdminContentDatabaseName
                    }
                }
                Mock -CommandName "Get-SPDSCConfigDBStatus" -MockWith {
                    return @{
                        Locked = $false
                        ValidPermissions = $true
                        DatabaseExists = $true
                    }
                }
                Mock -CommandName "Get-SPDatabase" -MockWith {
                    return @(@{
                        Name = $testParams.FarmConfigDatabaseName
                        Type = "Configuration Database"
                        Server = @{
                            Name = $testParams.DatabaseServer
                        }
                    })
                }
                Mock -CommandName "Get-SPWebApplication" -MockWith {
                    return @{
                        IsAdministrationWebApplication = $true
                        ContentDatabases = @(@{
                            Name = $testParams.AdminContentDatabaseName
                        })
                        IISSettings = @(@{
                            DisableKerberos = $true
                        })
                        Url = "http://localhost:9999"
                    }
                }

                Mock -CommandName Get-SPServer -MockWith{
                    return @{
                        Name = "spwfe"
                        Role = "WebFrontEnd"
                    }
                }

                Mock -CommandName Get-SPDSCInstalledProductVersion -MockWith { return @{ FileMajorPart = 15 } }

                It "Should return WebFrontEnd from the get method"{
                    (Get-TargetResource @testParams).ServerRole | Should Be $null
                }
            }
        }

        if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 16)
        {
            Context -Name "enhanced minrole options fail when Feature Pack 1 is not installed" -Fixture {
                $testParams = @{
                    IsSingleInstance = "Yes"
                    Ensure = "Present"
                    FarmConfigDatabaseName = "SP_Config"
                    DatabaseServer = "DatabaseServer\Instance"
                    FarmAccount = $mockFarmAccount
                    Passphrase =  $mockPassphrase
                    AdminContentDatabaseName = "Admin_Content"
                    CentralAdministrationAuth = "Kerberos"
                    CentralAdministrationPort = 1234
                    ServerRole = "ApplicationWithSearch"
                    RunCentralAdmin = $false
                }

                Mock -CommandName Get-SPDSCInstalledProductVersion -MockWith {
                    return @{
                        FileMajorPart = 16
                        FileBuildPart = 0
                    }
                }

                It "Should throw if an invalid server role is used in the get method" {
                    { Get-TargetResource @testParams } | Should Throw
                }

                It "Should throw if an invalid server role is used in the test method" {
                    { Test-TargetResource @testParams } | Should Throw
                }

                It "Should throw if an invalid server role is used in the set method" {
                    { Set-TargetResource @testParams } | Should Throw
                }
            }

            Context -Name "enhanced minrole options succeed when Feature Pack 1 is installed" -Fixture {
                $testParams = @{
                    IsSingleInstance = "Yes"
                    Ensure = "Present"
                    FarmConfigDatabaseName = "SP_Config"
                    DatabaseServer = "sql.contoso.com"
                    FarmAccount = $mockFarmAccount
                    Passphrase = $mockPassphrase
                    AdminContentDatabaseName = "SP_AdminContent"
                    ServerRole = "ApplicationWithSearch"
                    RunCentralAdmin = $true
                }

                Mock -CommandName "Get-SPDSCRegistryKey" -MockWith { return $null }
                Mock -CommandName "Get-SPFarm" -MockWith { return $null }
                Mock -CommandName "Get-SPDSCConfigDBStatus" -MockWith {
                    return @{
                        Locked = $false
                        ValidPermissions = $true
                        DatabaseExists = $false
                    }
                }
                Mock -CommandName "Get-SPWebApplication" -MockWith {
                    return @{
                        IsAdministrationWebApplication = $true
                        Url = "http://localhost:12345"
                    }
                }

                Mock -CommandName Get-SPDSCInstalledProductVersion -MockWith {
                    return @{
                        FileMajorPart = 16
                        FileBuildPart = 4456
                    }
                }

                It "Should throw if an invalid server role is used in the get method" {
                    { Get-TargetResource @testParams } | Should Not Throw
                }

                It "Should throw if an invalid server role is used in the test method" {
                    { Test-TargetResource @testParams } | Should Not Throw
                }

                It "Should throw if an invalid server role is used in the set method" {
                    { Set-TargetResource @testParams } | Should Not Throw
                }
            }
        }

        Context -Name "no serverrole is specified but get-targetresource needs to identify and return it" -Fixture {
            $testParams = @{
                IsSingleInstance = "Yes"
                Ensure = "Present"
                FarmConfigDatabaseName = "SP_Config"
                DatabaseServer = "sql.contoso.com"
                FarmAccount = $mockFarmAccount
                Passphrase = $mockPassphrase
                AdminContentDatabaseName = "SP_AdminContent"
                RunCentralAdmin = $true
            }
            Mock -CommandName "Get-SPDSCRegistryKey" -MockWith {
                return "Connection string example"
            }

            Mock -CommandName "Get-SPFarm" -MockWith {
                return @{
                    Name = $testParams.FarmConfigDatabaseName
                    DatabaseServer = @{
                        Name = $testParams.DatabaseServer
                    }
                    AdminContentDatabaseName = $testParams.AdminContentDatabaseName
                }
            }
            Mock -CommandName "Get-SPDSCConfigDBStatus" -MockWith {
                return @{
                    Locked = $false
                    ValidPermissions = $true
                    DatabaseExists = $true
                }
            }
            Mock -CommandName "Get-SPDatabase" -MockWith {
                return @(@{
                    Name = $testParams.FarmConfigDatabaseName
                    Type = "Configuration Database"
                    Server = @{
                        Name = $testParams.DatabaseServer
                    }
                })
            }
            Mock -CommandName "Get-SPWebApplication" -MockWith {
                return @{
                    IsAdministrationWebApplication = $true
                    ContentDatabases = @(@{
                        Name = $testParams.AdminContentDatabaseName
                    })
                    IISSettings = @(@{
                        DisableKerberos = $true
                    })
                    Url = "http://localhost:9999"
                }
            }
            Mock -CommandName Get-SPServer -MockWith{
                return @{
                    Name = "spwfe"
                    Role = "WebFrontEnd"
                }
            }

            Mock -CommandName Get-SPDSCInstalledProductVersion -MockWith { return @{ FileMajorPart = 16 } }

            It "Should return WebFrontEnd from the get method"{
                (Get-TargetResource @testParams).ServerRole | Should Be "WebFrontEnd"
            }
        }

        Context -Name "no farm is configured locally and an unsupported version of SharePoint is installed on the server" -Fixture {
            $testParams = @{
                IsSingleInstance = "Yes"
                Ensure = "Present"
                FarmConfigDatabaseName = "SP_Config"
                DatabaseServer = "sql.contoso.com"
                FarmAccount = $mockFarmAccount
                Passphrase = $mockPassphrase
                AdminContentDatabaseName = "SP_AdminContent"
                ServerRole = "ApplicationWithSearch"
                RunCentralAdmin = $true
            }

            Mock -CommandName Get-SPDSCInstalledProductVersion -MockWith { return @{ FileMajorPart = 14 } }

            It "Should throw when an unsupported version is installed and set is called" {
                { Set-TargetResource @testParams } | Should throw
            }
        }

        Context -Name "The server is joined to the farm, but SQL server is unavailable" -Fixture {
            $testParams = @{
                IsSingleInstance = "Yes"
                Ensure = "Present"
                FarmConfigDatabaseName = "SP_Config"
                DatabaseServer = "sql.contoso.com"
                FarmAccount = $mockFarmAccount
                Passphrase = $mockPassphrase
                AdminContentDatabaseName = "SP_AdminContent"
                RunCentralAdmin = $true
            }

            Mock -CommandName "Get-SPDSCRegistryKey" -MockWith {
                return "Connection string example"
            }
            Mock -CommandName "Get-SPFarm" -MockWith {
                return $null
            }
            Mock -CommandName "Get-SPDSCConfigDBStatus" -MockWith {
                return @{
                    Locked = $false
                    ValidPermissions = $false
                    DatabaseExists = $false
                }
            }
            Mock -CommandName "Get-SPDatabase" -MockWith {
                return $null
            }
            Mock -CommandName "Get-SPWebApplication" -MockWith {
                return $null
            }
            Mock -CommandName "Get-SPServiceInstance" -MockWith {
                if ($global:SPDscCentralAdminCheckDone -eq $true)
                {
                    return @(@{
                        TypeName = "Central Administration"
                        Status = "Online"
                    })
                }
                else
                {
                    $global:SPDscCentralAdminCheckDone = $true
                    return $null
                }
            }

            It "Should still return present in the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Present"
                $result.RunCentralAdmin | Should BeNullOrEmpty
            }

            It "Should return false in the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context -Name "A config database exists, and this server is connected (with FQDN) to it and should be" -Fixture {
            $testParams = @{
                IsSingleInstance = "Yes"
                Ensure = "Present"
                FarmConfigDatabaseName = "SP_Config"
                DatabaseServer = "sql.contoso.com"
                FarmAccount = $mockFarmAccount
                Passphrase = $mockPassphrase
                AdminContentDatabaseName = "SP_AdminContent"
                RunCentralAdmin = $true
            }

            Mock -CommandName "Get-SPServer" -MockWith {
                return $null
            } -ParameterFilter { $Identity -eq $env:COMPUTERNAME }

            Mock -CommandName "Get-SPServer" -MockWith {
                return @{
                    Name = "spwfe"
                    Role = "WebFrontEnd"
                }
            }

            Mock -CommandName "Get-SPDSCRegistryKey" -MockWith {
                return "Connection string example"
            }

            Mock -CommandName "Get-SPFarm" -MockWith {
                return @{
                    Name = $testParams.FarmConfigDatabaseName
                    DatabaseServer = @{
                        Name = $testParams.DatabaseServer
                    }
                    AdminContentDatabaseName = $testParams.AdminContentDatabaseName
                }
            }
            Mock -CommandName "Get-SPDSCConfigDBStatus" -MockWith {
                return @{
                    Locked = $false
                    ValidPermissions = $true
                    DatabaseExists = $true
                }
            }
            Mock -CommandName "Get-SPDatabase" -MockWith {
                return @(@{
                    Name = $testParams.FarmConfigDatabaseName
                    Type = "Configuration Database"
                    NormalizedDataSource = $testParams.DatabaseServer
                })
            }
            Mock -CommandName "Get-SPWebApplication" -MockWith {
                return @{
                    IsAdministrationWebApplication = $true
                    ContentDatabases = @(@{
                        Name = $testParams.AdminContentDatabaseName
                    })
                    IISSettings = @(@{
                        DisableKerberos = $true
                    })
                    Url = "http://localhost:9999"
                }
            }
            Mock -CommandName "Get-SPServiceInstance" -MockWith {
                if ($global:SPDscCentralAdminCheckDone -eq $true)
                {
                    return @(@{
                        TypeName = "Central Administration"
                        Status = "Online"
                    })
                }
                else
                {
                    $global:SPDscCentralAdminCheckDone = $true
                    return $null
                }
            }

            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should be $true
            }
        }
    }
}
