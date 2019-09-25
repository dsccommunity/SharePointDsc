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

        try
        {
            [Microsoft.SharePoint.Administration.SPDeveloperDashboardLevel]
        }
        catch
        {
            Add-Type -TypeDefinition @"
namespace Microsoft.SharePoint.Administration {
    public enum SPDeveloperDashboardLevel { On, OnDemand, Off };
}
"@
        }

        # Mocks for all contexts
        Mock -CommandName Add-SPDscConfigDBLock -MockWith { }
        Mock -CommandName Remove-SPDscConfigDBLock -MockWith { }
        Mock -CommandName New-SPConfigurationDatabase -MockWith { }
        Mock -CommandName Connect-SPConfigurationDatabase -MockWith { }
        Mock -CommandName Install-SPHelpCollection -MockWith { }
        Mock -CommandName Initialize-SPResourceSecurity -MockWith { }
        Mock -CommandName Install-SPService -MockWith { }
        Mock -CommandName Install-SPFeature -MockWith { }
        Mock -CommandName New-SPCentralAdministration -MockWith { }
        Mock -CommandName Remove-SPWebApplication -MockWith { }
        Mock -CommandName New-SPWebApplicationExtension -MockWith { }
        Mock -CommandName Start-Sleep -MockWith { }
        Mock -CommandName Start-Service -MockWith { }
        Mock -CommandName Stop-Service -MockWith { }
        Mock -CommandName Start-SPServiceInstance -MockWith { }
        Mock -CommandName Get-SPDscInstalledProductVersion {
            return @{
                FileMajorPart    = $Global:SPDscHelper.CurrentStubBuildNumber.Major
                FileBuildPart    = $Global:SPDscHelper.CurrentStubBuildNumber.Build
                ProductBuildPart = $Global:SPDscHelper.CurrentStubBuildNumber.Build
            }
        }
        Mock -CommandName Get-SPDscContentService -MockWith {
            $developerDashboardSettings = @{
                DisplayLevel = "Off"
            }

            $developerDashboardSettings = $developerDashboardSettings | Add-Member -MemberType ScriptMethod -Name Update -Value {
                $Global:SPDscDevDashUpdated = $true
            } -PassThru

            $returnVal = @{
                DeveloperDashboardSettings = $developerDashboardSettings
            }
            return $returnVal
        }

        # Test Contexts
        Context -Name "No config databases exists, and this server should be connected to one" -Fixture {
            $testParams = @{
                IsSingleInstance          = "Yes"
                Ensure                    = "Present"
                FarmConfigDatabaseName    = "SP_Config"
                CentralAdministrationPort = 80000
                DatabaseServer            = "sql.contoso.com"
                FarmAccount               = $mockFarmAccount
                Passphrase                = $mockPassphrase
                AdminContentDatabaseName  = "SP_AdminContent"
                RunCentralAdmin           = $true
            }

            It "Should throw exception in the get method" {
                { Get-TargetResource @testParams } | Should Throw "An invalid value for CentralAdministrationPort is specified:"
            }

            It "Should throw exception in the test method" {
                { Test-TargetResource @testParams } | Should Throw "An invalid value for CentralAdministrationPort is specified:"
            }

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should Throw "An invalid value for CentralAdministrationPort is specified:"
            }
        }

        Context -Name "CA URL passed in cannot be parsed as System.Uri" -Fixture {
            $testParams = @{
                IsSingleInstance          = "Yes"
                Ensure                    = "Present"
                FarmConfigDatabaseName    = "SP_Config"
                CentralAdministrationPort = 443
                CentralAdministrationUrl  = "admin.contoso.com"
                DatabaseServer            = "sql.contoso.com"
                FarmAccount               = $mockFarmAccount
                Passphrase                = $mockPassphrase
                AdminContentDatabaseName  = "SP_AdminContent"
                RunCentralAdmin           = $true
            }

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should Throw "CentralAdministrationUrl is not a valid URI. It should include the scheme (http/https) and address."
            }
        }

        Context -Name "Invalid CA URL has been passed in with port included" -Fixture {
            $testParams = @{
                IsSingleInstance          = "Yes"
                Ensure                    = "Present"
                FarmConfigDatabaseName    = "SP_Config"
                CentralAdministrationPort = 443
                CentralAdministrationUrl  = "https://admin.contoso.com:443"
                DatabaseServer            = "sql.contoso.com"
                FarmAccount               = $mockFarmAccount
                Passphrase                = $mockPassphrase
                AdminContentDatabaseName  = "SP_AdminContent"
                RunCentralAdmin           = $true
            }

            It "Should throw exception in the set method" {
                { Set-TargetResource @testParams } | Should Throw "CentralAdministrationUrl should not specify port. Use CentralAdministrationPort instead."
            }
        }

        Context -Name "No config databaes exists, and this server should be connected to one" -Fixture {
            $testParams = @{
                IsSingleInstance         = "Yes"
                Ensure                   = "Present"
                FarmConfigDatabaseName   = "SP_Config"
                DatabaseServer           = "sql.contoso.com"
                FarmAccount              = $mockFarmAccount
                Passphrase               = $mockPassphrase
                AdminContentDatabaseName = "SP_AdminContent"
                RunCentralAdmin          = $true
            }

            Mock -CommandName "Get-SPDscRegistryKey" -MockWith { return $null }
            Mock -CommandName "Get-SPFarm" -MockWith { return $null }
            Mock -CommandName "Get-SPDscConfigDBStatus" -MockWith {
                return @{
                    Locked           = $false
                    ValidPermissions = $true
                    DatabaseExists   = $false
                }
            }
            Mock -CommandName "Get-SPDscSQLInstanceStatus" -MockWith {
                return @{
                    MaxDOPCorrect = $true
                }
            }
            Mock -CommandName "Get-SPWebApplication" -MockWith {
                return @{
                    IsAdministrationWebApplication = $true
                    Url                            = "http://localhost:12345"
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

        Context -Name "No config databases exists, and this server should be connected to one but won't run central admin" -Fixture {
            $testParams = @{
                IsSingleInstance         = "Yes"
                Ensure                   = "Present"
                FarmConfigDatabaseName   = "SP_Config"
                DatabaseServer           = "sql.contoso.com"
                FarmAccount              = $mockFarmAccount
                Passphrase               = $mockPassphrase
                AdminContentDatabaseName = "SP_AdminContent"
                RunCentralAdmin          = $false
            }

            Mock -CommandName "Get-SPDscRegistryKey" -MockWith { return $null }
            Mock -CommandName "Get-SPFarm" -MockWith { return $null }
            Mock -CommandName "Get-SPDscConfigDBStatus" -MockWith {
                return @{
                    Locked           = $false
                    ValidPermissions = $true
                    DatabaseExists   = $false
                }
            }
            Mock -CommandName "Get-SPDscSQLInstanceStatus" -MockWith {
                return @{
                    MaxDOPCorrect = $true
                }
            }
            Mock -CommandName "Get-SPWebApplication" -MockWith {
                return @{
                    IsAdministrationWebApplication = $true
                    Url                            = "http://localhost:12345"
                }
            }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should be $false
            }

            It "Should join the config database in the set method as it wont be running central admin" {
                Set-TargetResource @testParams
                Assert-MockCalled -CommandName "Connect-SPConfigurationDatabase"
            }
        }

        Context -Name "A config database exists, and this server should be connected to it but isn't and this server won't run central admin" -Fixture {
            $testParams = @{
                IsSingleInstance         = "Yes"
                Ensure                   = "Present"
                FarmConfigDatabaseName   = "SP_Config"
                DatabaseServer           = "sql.contoso.com"
                FarmAccount              = $mockFarmAccount
                Passphrase               = $mockPassphrase
                AdminContentDatabaseName = "SP_AdminContent"
                RunCentralAdmin          = $false
            }

            Mock -CommandName "Get-SPDscRegistryKey" -MockWith { return $null }
            Mock -CommandName "Get-SPFarm" -MockWith { return $null }
            Mock -CommandName "Get-SPDscConfigDBStatus" -MockWith {
                return @{
                    Locked           = $false
                    ValidPermissions = $true
                    DatabaseExists   = $true
                }
            }
            Mock -CommandName "Get-SPDscSQLInstanceStatus" -MockWith {
                return @{
                    MaxDOPCorrect = $true
                }
            }
            Mock -CommandName "Get-SPWebApplication" -MockWith {
                return @{
                    IsAdministrationWebApplication = $true
                    Url                            = "http://localhost:9999"
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
                    return @(
                        $null | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return @{
                                Name = "SPWebServiceInstance"
                            }
                        } -PassThru -Force | Add-Member -Name Name `
                            -MemberType ScriptProperty `
                            -PassThru `
                        {
                            # get
                            ""
                        }`
                        {
                            # set
                            param ( $arg )
                        }
                    )
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
                    ContentDatabases               = @(@{
                            Name = $testParams.AdminContentDatabaseName
                        })
                    Url                            = "http://localhost:9999"
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

        Context -Name "A config database exists, and this server should be connected to it but isn't and this server will run central admin" -Fixture {
            $testParams = @{
                IsSingleInstance         = "Yes"
                Ensure                   = "Present"
                FarmConfigDatabaseName   = "SP_Config"
                DatabaseServer           = "sql.contoso.com"
                FarmAccount              = $mockFarmAccount
                Passphrase               = $mockPassphrase
                AdminContentDatabaseName = "SP_AdminContent"
                RunCentralAdmin          = $true
            }

            Mock -CommandName "Get-SPDscRegistryKey" -MockWith { return $null }
            Mock -CommandName "Get-SPFarm" -MockWith { return $null }
            Mock -CommandName "Get-SPDscConfigDBStatus" -MockWith {
                return @{
                    Locked           = $false
                    ValidPermissions = $true
                    DatabaseExists   = $true
                }
            }
            Mock -CommandName "Get-SPDscSQLInstanceStatus" -MockWith {
                return @{
                    MaxDOPCorrect = $true
                }
            }
            Mock -CommandName "Get-SPWebApplication" -MockWith {
                return @{
                    IsAdministrationWebApplication = $true
                    Url                            = "http://localhost:9999"
                }
            }

            Mock -CommandName "Get-SPWebApplication" -MockWith {
                return @{
                    IsAdministrationWebApplication = $true
                    ContentDatabases               = @(@{
                            Name = $testParams.AdminContentDatabaseName
                        })
                    Url                            = "http://localhost:9999"
                }
            }
            Mock -CommandName "Get-SPServiceInstance" -MockWith {
                if ($global:SPDscCentralAdminCheckDone -eq $true)
                {
                    return @(
                        @{
                            Name = "WSS_Administration"
                        } | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return @{
                                Name = "SPWebServiceInstance"
                            }
                        } -PassThru -Force
                    )
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
                IsSingleInstance         = "Yes"
                Ensure                   = "Present"
                FarmConfigDatabaseName   = "SP_Config"
                DatabaseServer           = "sql.contoso.com"
                FarmAccount              = $mockFarmAccount
                Passphrase               = $mockPassphrase
                AdminContentDatabaseName = "SP_AdminContent"
                RunCentralAdmin          = $true
            }

            Mock -CommandName "Get-SPDscRegistryKey" -MockWith { return $null }
            Mock -CommandName "Get-SPFarm" -MockWith { return $null }
            Mock -CommandName "Get-SPDscConfigDBStatus" -MockWith {
                if ($global:SPDscConfigLockTriggered)
                {
                    return @{
                        Locked           = $false
                        ValidPermissions = $true
                        DatabaseExists   = $true
                    }
                }
                else
                {
                    $global:SPDscConfigLockTriggered = $true
                    return @{
                        Locked           = $true
                        ValidPermissions = $true
                        DatabaseExists   = $true
                    }
                }
            }
            Mock -CommandName "Get-SPDscSQLInstanceStatus" -MockWith {
                return @{
                    MaxDOPCorrect = $true
                }
            }
            Mock -CommandName "Get-SPWebApplication" -MockWith {
                return @{
                    IsAdministrationWebApplication = $true
                    Url                            = "http://localhost:12345"
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
                Assert-MockCalled -CommandName "Get-SPDscConfigDBStatus" -Times 2
                Assert-MockCalled -CommandName "Connect-SPConfigurationDatabase"
            }
        }

        # Adding coverage here for when CA URL is HTTPS but port is not specified
        Context -Name "Server is connected to farm, but Central Admin isn't started" -Fixture {
            $testParams = @{
                IsSingleInstance         = "Yes"
                Ensure                   = "Present"
                FarmConfigDatabaseName   = "SP_Config"
                DatabaseServer           = "sql.contoso.com"
                FarmAccount              = $mockFarmAccount
                Passphrase               = $mockPassphrase
                AdminContentDatabaseName = "SP_AdminContent"
                RunCentralAdmin          = $true
                CentralAdministrationUrl = "https://admin.contoso.com"
            }

            Mock -CommandName Get-SPDscRegistryKey -MockWith {
                return "Connection string example"
            }

            Mock -CommandName Get-SPFarm -MockWith {
                return @{
                    Name                     = $testParams.FarmConfigDatabaseName
                    DatabaseServer           = @{
                        Name = $testParams.DatabaseServer
                    }
                    AdminContentDatabaseName = $testParams.AdminContentDatabaseName
                }
            }
            Mock -CommandName Get-SPDscConfigDBStatus -MockWith {
                return @{
                    Locked           = $false
                    ValidPermissions = $true
                    DatabaseExists   = $true
                }
            }
            Mock -CommandName "Get-SPDscSQLInstanceStatus" -MockWith {
                return @{
                    MaxDOPCorrect = $true
                }
            }
            Mock -CommandName Get-SPDatabase -MockWith {
                return @(@{
                        Name                 = $testParams.FarmConfigDatabaseName
                        Type                 = "Configuration Database"
                        NormalizedDataSource = $testParams.DatabaseServer
                    })
            }
            Mock -CommandName Get-SPWebApplication -MockWith {
                return @{
                    IsAdministrationWebApplication = $true
                    ContentDatabases               = @(@{
                            Name = $testParams.AdminContentDatabaseName
                        })
                    IISSettings                    = @(@{
                            DisableKerberos = $true
                        })
                    Url                            = "http://localhost:9999"
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
                        return @(
                            @{
                                Name   = "WSS_Administration"
                                Status = "Online"
                            } | Add-Member -MemberType ScriptMethod `
                                -Name GetType `
                                -Value {
                                return @{
                                    Name = "SPWebServiceInstance"
                                }
                            } -PassThru -Force
                        )
                    }
                    { 0, 1 -contains $_ }
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

        Context -Name "Server is connected to farm, but CentralAdminPort is different" -Fixture {
            $testParams = @{
                IsSingleInstance          = "Yes"
                Ensure                    = "Present"
                FarmConfigDatabaseName    = "SP_Config"
                DatabaseServer            = "sql.contoso.com"
                FarmAccount               = $mockFarmAccount
                Passphrase                = $mockPassphrase
                AdminContentDatabaseName  = "SP_AdminContent"
                RunCentralAdmin           = $true
                CentralAdministrationPort = 8080
            }

            Mock -CommandName Get-SPDscRegistryKey -MockWith {
                return "Connection string example"
            }

            Mock -CommandName Get-SPFarm -MockWith {
                return @{
                    Name                     = $testParams.FarmConfigDatabaseName
                    DatabaseServer           = @{
                        Name = $testParams.DatabaseServer
                    }
                    AdminContentDatabaseName = $testParams.AdminContentDatabaseName
                }
            }
            Mock -CommandName Get-SPDscConfigDBStatus -MockWith {
                return @{
                    Locked           = $false
                    ValidPermissions = $true
                    DatabaseExists   = $true
                }
            }
            Mock -CommandName Get-SPDatabase -MockWith {
                return @(@{
                        Name                 = $testParams.FarmConfigDatabaseName
                        Type                 = "Configuration Database"
                        NormalizedDataSource = $testParams.DatabaseServer
                    })
            }
            Mock -CommandName Get-SPWebApplication -MockWith {
                return @{
                    IsAdministrationWebApplication = $true
                    ContentDatabases               = @(@{
                            Name = $testParams.AdminContentDatabaseName
                        })
                    IISSettings                    = @(@{
                            DisableKerberos = $true
                        })
                    Url                            = "http://localhost:9999"
                }
            }
            Mock -CommandName Get-CimInstance -MockWith {
                return @{
                    Domain = "domain.com"
                }
            }

            Mock -CommandName Get-SPServiceInstance -MockWith {
                return @(
                    @{
                        Name   = "WSS_Administration"
                        Status = "Online"
                    } | Add-Member -MemberType ScriptMethod `
                        -Name GetType `
                        -Value {
                        return @{
                            Name = "SPWebServiceInstance"
                        }
                    } -PassThru -Force
                )
            }

            Mock -CommandName Set-SPCentralAdministration -MockWith { }

            It "Should return 9999 as CA Port from the get method" {
                (Get-TargetResource @testParams).CentralAdministrationPort | Should Be 9999
            }

            It "Should update the central administration port" {
                Set-TargetResource @testParams
                Assert-MockCalled -CommandName "Set-SPCentralAdministration"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should be $false
            }
        }

        Context -Name "This server is running CA on HTTPS, but secure bindings do not match CA URL" -Fixture {
            $testParams = @{
                IsSingleInstance          = "Yes"
                Ensure                    = "Present"
                FarmConfigDatabaseName    = "SP_Config"
                DatabaseServer            = "sql.contoso.com"
                FarmAccount               = $mockFarmAccount
                Passphrase                = $mockPassphrase
                AdminContentDatabaseName  = "SP_AdminContent"
                RunCentralAdmin           = $true
                CentralAdministrationUrl  = "https://admin.contoso.com"
                CentralAdministrationPort = 443
            }

            Mock -CommandName Get-SPDscRegistryKey -MockWith {
                return "Connection string example"
            }

            Mock -CommandName Get-SPFarm -MockWith {
                return @{
                    Name                     = $testParams.FarmConfigDatabaseName
                    DatabaseServer           = @{
                        Name = $testParams.DatabaseServer
                    }
                    AdminContentDatabaseName = $testParams.AdminContentDatabaseName
                }
            }
            Mock -CommandName Get-SPDscConfigDBStatus -MockWith {
                return @{
                    Locked           = $false
                    ValidPermissions = $true
                    DatabaseExists   = $true
                }
            }
            Mock -CommandName "Get-SPDscSQLInstanceStatus" -MockWith {
                return @{
                    MaxDOPCorrect = $true
                }
            }
            Mock -CommandName Get-SPDatabase -MockWith {
                return @(@{
                        Name                 = $testParams.FarmConfigDatabaseName
                        Type                 = "Configuration Database"
                        NormalizedDataSource = $testParams.DatabaseServer
                    })
            }
            Mock -CommandName Get-SPWebApplication -MockWith {
                $webapp = @{
                    ContentDatabases               = @(
                        @{
                            Name = $testParams.AdminContentDatabaseName
                        }
                    )
                    Url                            = $testParams.CentralAdministrationUrl
                    IsAdministrationWebApplication = $true
                    IisSettings                    = [ordered]@{
                        Default = @{
                            DisableKerberos = $true
                            SecureBindings  = @(
                                @{
                                    HostHeader = "different.contoso.com"
                                    Port       = "443"
                                }
                            )
                        }
                    }
                }

                $webapp | Add-Member -MemberType ScriptMethod -Name GetIisSettingsWithFallback -Value {
                    [CmdletBinding()]
                    param(
                        [Parameter(Mandatory = $true)]
                        [string]
                        $Zone
                    )

                    return $this.IisSettings[$Zone]
                }

                return $webapp
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
                        return @(
                            @{
                                Name   = "WSS_Administration"
                                Status = "Online"
                            } | Add-Member -MemberType ScriptMethod `
                                -Name GetType `
                                -Value {
                                return @{
                                    Name = "SPWebServiceInstance"
                                }
                            } -PassThru -Force
                        )
                    }
                    { 0, 1 -contains $_ }
                    {
                        $global:SPDscSIRunCount++
                        return $null
                    }
                }
            }

            $global:SPDscSIRunCount = 0
            It "Should return current values for the Get method" {
                $result = Get-TargetResource @testParams
                $result.RunCentralAdmin | Should Be $false
                $result.CentralAdministrationUrl | Should Be $testParams.CentralAdministrationUrl
                $result.CentralAdministrationPort | Should Be $testParams.CentralAdministrationPort
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

        Context -Name "Server not yet part of the farm, and will run Central Admin on HTTPS" -Fixture {
            $testParams = @{
                IsSingleInstance         = "Yes"
                Ensure                   = "Present"
                FarmConfigDatabaseName   = "SP_Config"
                DatabaseServer           = "sql.contoso.com"
                FarmAccount              = $mockFarmAccount
                Passphrase               = $mockPassphrase
                AdminContentDatabaseName = "SP_AdminContent"
                CentralAdministrationUrl = "https://admin.contoso.com"
                RunCentralAdmin          = $true
            }

            Mock -CommandName "Get-SPDscRegistryKey" -MockWith { return $null }
            Mock -CommandName "Get-SPFarm" -MockWith { return $null }
            Mock -CommandName "Get-SPDscConfigDBStatus" -MockWith {
                return @{
                    Locked           = $false
                    ValidPermissions = $true
                    DatabaseExists   = $true
                }
            }
            Mock -CommandName "Get-SPDscSQLInstanceStatus" -MockWith {
                return @{
                    MaxDOPCorrect = $true
                }
            }

            Mock -CommandName "Get-SPWebApplication" -MockWith {
                return @{
                    IsAdministrationWebApplication = $true
                    ContentDatabases               = @(@{
                            Name = $testParams.AdminContentDatabaseName
                        })
                    Url                            = "http://localhost:9999"
                }
            }
            Mock -CommandName "Get-SPServiceInstance" -MockWith {
                if ($global:SPDscCentralAdminCheckDone -eq $true)
                {
                    return @(
                        @{
                            Name = "WSS_Administration"
                        } | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return @{
                                Name = "SPWebServiceInstance"
                            }
                        } -PassThru -Force
                    )
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
            It "Should provision, remove, and re-extend CA web application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled -CommandName "New-SPCentralAdministration"
                Assert-MockCalled -CommandName "Remove-SPWebApplication"
                Assert-MockCalled -CommandName "New-SPWebApplicationExtension"
            }
        }

        Context -Name "This server is running CA on HTTPS, but secure bindings do not contain valid hostname" -Fixture {
            $testParams = @{
                IsSingleInstance          = "Yes"
                Ensure                    = "Present"
                FarmConfigDatabaseName    = "SP_Config"
                DatabaseServer            = "sql.contoso.com"
                FarmAccount               = $mockFarmAccount
                Passphrase                = $mockPassphrase
                AdminContentDatabaseName  = "SP_AdminContent"
                RunCentralAdmin           = $true
                CentralAdministrationUrl  = "https://admin.contoso.com"
                CentralAdministrationPort = 443
            }

            Mock -CommandName Get-SPDscRegistryKey -MockWith {
                return "Connection string example"
            }

            Mock -CommandName Get-SPFarm -MockWith {
                return @{
                    Name                     = $testParams.FarmConfigDatabaseName
                    DatabaseServer           = @{
                        Name = $testParams.DatabaseServer
                    }
                    AdminContentDatabaseName = $testParams.AdminContentDatabaseName
                }
            }
            Mock -CommandName Get-SPDscConfigDBStatus -MockWith {
                return @{
                    Locked           = $false
                    ValidPermissions = $true
                    DatabaseExists   = $true
                }
            }
            Mock -CommandName "Get-SPDscSQLInstanceStatus" -MockWith {
                return @{
                    MaxDOPCorrect = $true
                }
            }
            Mock -CommandName Get-SPDatabase -MockWith {
                return @(@{
                        Name                 = $testParams.FarmConfigDatabaseName
                        Type                 = "Configuration Database"
                        NormalizedDataSource = $testParams.DatabaseServer
                    })
            }
            Mock -CommandName Get-SPWebApplication -MockWith {
                $webapp = @{
                    ContentDatabases               = @(
                        @{
                            Name = $testParams.AdminContentDatabaseName
                        }
                    )
                    Url                            = $testParams.CentralAdministrationUrl
                    IsAdministrationWebApplication = $true
                    IisSettings                    = [ordered]@{
                        Default = @{
                            DisableKerberos = $true
                            SecureBindings  = @(
                                @{
                                    HostHeader = ""
                                    Port       = "443"
                                }
                            )
                        }
                    }
                }

                $webapp | Add-Member -MemberType ScriptMethod -Name GetIisSettingsWithFallback -Value {
                    [CmdletBinding()]
                    param(
                        [Parameter(Mandatory = $true)]
                        [string]
                        $Zone
                    )

                    return $this.IisSettings[$Zone]
                }

                return $webapp
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
                        return @(
                            @{
                                Name   = "WSS_Administration"
                                Status = "Online"
                            } | Add-Member -MemberType ScriptMethod `
                                -Name GetType `
                                -Value {
                                return @{
                                    Name = "SPWebServiceInstance"
                                }
                            } -PassThru -Force
                        )
                    }
                    { 0, 1 -contains $_ }
                    {
                        $global:SPDscSIRunCount++
                        return $null
                    }
                }
            }

            $global:SPDscSIRunCount = 0
            It "Should return current values for the Get method" {
                $result = Get-TargetResource @testParams
                $result.RunCentralAdmin | Should Be $false
                $result.CentralAdministrationUrl | Should Be $testParams.CentralAdministrationUrl
                $result.CentralAdministrationPort | Should Be $testParams.CentralAdministrationPort
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
                IsSingleInstance         = "Yes"
                Ensure                   = "Present"
                FarmConfigDatabaseName   = "SP_Config"
                DatabaseServer           = "sql.contoso.com"
                FarmAccount              = $mockFarmAccount
                Passphrase               = $mockPassphrase
                AdminContentDatabaseName = "SP_AdminContent"
                RunCentralAdmin          = $false
            }

            Mock -CommandName "Get-SPDscRegistryKey" -MockWith {
                return "Connection string example"
            }

            Mock -CommandName "Get-SPFarm" -MockWith {
                return @{
                    Name                     = $testParams.FarmConfigDatabaseName
                    DatabaseServer           = @{
                        Name = $testParams.DatabaseServer
                    }
                    AdminContentDatabaseName = $testParams.AdminContentDatabaseName
                }
            }
            Mock -CommandName "Get-SPDscConfigDBStatus" -MockWith {
                return @{
                    Locked           = $false
                    ValidPermissions = $true
                    DatabaseExists   = $true
                }
            }
            Mock -CommandName "Get-SPDscSQLInstanceStatus" -MockWith {
                return @{
                    MaxDOPCorrect = $true
                }
            }
            Mock -CommandName "Get-SPDatabase" -MockWith {
                return @(@{
                        Name                 = $testParams.FarmConfigDatabaseName
                        Type                 = "Configuration Database"
                        NormalizedDataSource = $testParams.DatabaseServer
                    })
            }
            Mock -CommandName "Get-SPWebApplication" -MockWith {
                return @{
                    IsAdministrationWebApplication = $true
                    ContentDatabases               = @(@{
                            Name = $testParams.AdminContentDatabaseName
                        })
                    IISSettings                    = @(@{
                            DisableKerberos = $true
                        })
                    Url                            = "http://localhost:9999"
                }
            }
            Mock -CommandName Start-Sleep -MockWith { }
            Mock -CommandName Get-SPServiceInstance -MockWith {
                switch ($global:SPDscSIRunCount)
                {
                    { 0, 2 -contains $_ }
                    {
                        $global:SPDscSIRunCount++
                        return @(
                            @{
                                Name   = "WSS_Administration"
                                Status = "Online"
                            } | Add-Member -MemberType ScriptMethod `
                                -Name GetType `
                                -Value {
                                return @{
                                    Name = "SPWebServiceInstance"
                                }
                            } -PassThru -Force
                        )
                    }
                    { 1 -contains $_ }
                    {
                        $global:SPDscSIRunCount++
                        return $null
                    }
                }
            }
            Mock -CommandName "Stop-SPServiceInstance" -MockWith { }

            $global:SPDscSIRunCount = 0
            It "Should return present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Present"
                $result.RunCentralAdmin | Should Be $true
            }

            $global:SPDscSIRunCount = 0
            It "Should stop the CA instance in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Stop-SPServiceInstance
            }

            $global:SPDscSIRunCount = 0
            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should be $false
            }
        }

        Context -Name "Server is connected to a farm, but Developer Dashboard settings are incorrect" -Fixture {
            $testParams = @{
                IsSingleInstance         = "Yes"
                Ensure                   = "Present"
                FarmConfigDatabaseName   = "SP_Config"
                DatabaseServer           = "sql.contoso.com"
                FarmAccount              = $mockFarmAccount
                Passphrase               = $mockPassphrase
                AdminContentDatabaseName = "SP_AdminContent"
                RunCentralAdmin          = $true
                DeveloperDashboard       = "On"
            }

            Mock -CommandName "Get-SPDscRegistryKey" -MockWith {
                return "Connection string example"
            }

            Mock -CommandName "Get-SPFarm" -MockWith {
                return @{
                    Name                     = $testParams.FarmConfigDatabaseName
                    DatabaseServer           = @{
                        Name = $testParams.DatabaseServer
                    }
                    AdminContentDatabaseName = $testParams.AdminContentDatabaseName
                }
            }
            Mock -CommandName "Get-SPDscConfigDBStatus" -MockWith {
                return @{
                    Locked           = $false
                    ValidPermissions = $true
                    DatabaseExists   = $true
                }
            }
            Mock -CommandName "Get-SPDscSQLInstanceStatus" -MockWith {
                return @{
                    MaxDOPCorrect = $true
                }
            }
            Mock -CommandName "Get-SPDatabase" -MockWith {
                return @(@{
                        Name                 = $testParams.FarmConfigDatabaseName
                        Type                 = "Configuration Database"
                        NormalizedDataSource = $testParams.DatabaseServer
                    })
            }
            Mock -CommandName "Get-SPWebApplication" -MockWith {
                return @{
                    IsAdministrationWebApplication = $true
                    ContentDatabases               = @(@{
                            Name = $testParams.AdminContentDatabaseName
                        })
                    IISSettings                    = @(@{
                            DisableKerberos = $true
                        })
                    Url                            = "http://localhost:9999"
                }
            }
            Mock -CommandName "Get-SPServiceInstance" -MockWith {
                if ($global:SPDscCentralAdminCheckDone -eq $true)
                {
                    return @(
                        @{
                            Name   = "WSS_Administration"
                            Status = "Online"
                        } | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return @{
                                Name = "SPWebServiceInstance"
                            }
                        } -PassThru -Force
                    )
                }
                else
                {
                    $global:SPDscCentralAdminCheckDone = $true
                    return $null
                }
            }

            It "Should return present from the get method" {
                (Get-TargetResource @testParams).DeveloperDashboard | Should Be "Off"
            }

            $Global:SPDscDevDashUpdated = $false
            It "Should update DevDashboard settings in the set method" {
                Set-TargetResource @testParams
                $Global:SPDscDevDashUpdated | Should Be $true
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should be $false
            }
        }

        Context -Name "A config database exists, and this server is connected to it and should be" -Fixture {
            $testParams = @{
                IsSingleInstance         = "Yes"
                Ensure                   = "Present"
                FarmConfigDatabaseName   = "SP_Config"
                DatabaseServer           = "sql.contoso.com"
                FarmAccount              = $mockFarmAccount
                Passphrase               = $mockPassphrase
                AdminContentDatabaseName = "SP_AdminContent"
                RunCentralAdmin          = $true
            }

            Mock -CommandName "Get-SPDscRegistryKey" -MockWith {
                return "Connection string example"
            }

            Mock -CommandName "Get-SPFarm" -MockWith {
                return @{
                    Name                     = $testParams.FarmConfigDatabaseName
                    DatabaseServer           = @{
                        Name = $testParams.DatabaseServer
                    }
                    AdminContentDatabaseName = $testParams.AdminContentDatabaseName
                }
            }
            Mock -CommandName "Get-SPDscConfigDBStatus" -MockWith {
                return @{
                    Locked           = $false
                    ValidPermissions = $true
                    DatabaseExists   = $true
                }
            }
            Mock -CommandName "Get-SPDscSQLInstanceStatus" -MockWith {
                return @{
                    MaxDOPCorrect = $true
                }
            }
            Mock -CommandName "Get-SPDatabase" -MockWith {
                return @(@{
                        Name                 = $testParams.FarmConfigDatabaseName
                        Type                 = "Configuration Database"
                        NormalizedDataSource = $testParams.DatabaseServer
                    })
            }
            Mock -CommandName "Get-SPWebApplication" -MockWith {
                return @{
                    IsAdministrationWebApplication = $true
                    ContentDatabases               = @(@{
                            Name = $testParams.AdminContentDatabaseName
                        })
                    IISSettings                    = @(@{
                            DisableKerberos = $true
                        })
                    Url                            = "http://localhost:9999"
                }
            }
            Mock -CommandName "Get-SPServiceInstance" -MockWith {
                if ($global:SPDscCentralAdminCheckDone -eq $true)
                {
                    return @(
                        @{
                            Name   = "WSS_Administration"
                            Status = "Online"
                        } | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return @{
                                Name = "SPWebServiceInstance"
                            }
                        } -PassThru -Force
                    )
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
                IsSingleInstance         = "Yes"
                Ensure                   = "Absent"
                FarmConfigDatabaseName   = "SP_Config"
                DatabaseServer           = "sql.contoso.com"
                FarmAccount              = $mockFarmAccount
                Passphrase               = $mockPassphrase
                AdminContentDatabaseName = "SP_AdminContent"
                RunCentralAdmin          = $true
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
                    IsSingleInstance          = "Yes"
                    Ensure                    = "Present"
                    FarmConfigDatabaseName    = "SP_Config"
                    DatabaseServer            = "DatabaseServer\Instance"
                    FarmAccount               = $mockFarmAccount
                    Passphrase                = $mockPassphrase
                    AdminContentDatabaseName  = "Admin_Content"
                    CentralAdministrationAuth = "Kerberos"
                    CentralAdministrationPort = 1234
                    ServerRole                = "WebFrontEnd"
                    RunCentralAdmin           = $true
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
                    IsSingleInstance         = "Yes"
                    Ensure                   = "Present"
                    FarmConfigDatabaseName   = "SP_Config"
                    DatabaseServer           = "sql.contoso.com"
                    FarmAccount              = $mockFarmAccount
                    Passphrase               = $mockPassphrase
                    AdminContentDatabaseName = "SP_AdminContent"
                    RunCentralAdmin          = $true
                }

                Mock -CommandName "Get-SPDscRegistryKey" -MockWith {
                    return "Connection string example"
                }

                Mock -CommandName "Get-SPFarm" -MockWith {
                    return @{
                        Name                     = $testParams.FarmConfigDatabaseName
                        DatabaseServer           = @{
                            Name = $testParams.DatabaseServer
                        }
                        AdminContentDatabaseName = $testParams.AdminContentDatabaseName
                    }
                }
                Mock -CommandName "Get-SPDscConfigDBStatus" -MockWith {
                    return @{
                        Locked           = $false
                        ValidPermissions = $true
                        DatabaseExists   = $true
                    }
                }
                Mock -CommandName "Get-SPDscSQLInstanceStatus" -MockWith {
                    return @{
                        MaxDOPCorrect = $true
                    }
                }
                Mock -CommandName "Get-SPDatabase" -MockWith {
                    return @(@{
                            Name   = $testParams.FarmConfigDatabaseName
                            Type   = "Configuration Database"
                            Server = @{
                                Name = $testParams.DatabaseServer
                            }
                        })
                }
                Mock -CommandName "Get-SPWebApplication" -MockWith {
                    return @{
                        IsAdministrationWebApplication = $true
                        ContentDatabases               = @(@{
                                Name = $testParams.AdminContentDatabaseName
                            })
                        IISSettings                    = @(@{
                                DisableKerberos = $true
                            })
                        Url                            = "http://localhost:9999"
                    }
                }

                Mock -CommandName Get-SPServer -MockWith {
                    return @{
                        Name = "spwfe"
                        Role = "WebFrontEnd"
                    }
                }

                Mock -CommandName Get-SPDscInstalledProductVersion -MockWith { return @{ FileMajorPart = 15 } }

                It "Should return WebFrontEnd from the get method" {
                    (Get-TargetResource @testParams).ServerRole | Should Be $null
                }
            }
        }

        if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 16)
        {
            Context -Name "enhanced minrole options fail when Feature Pack 1 is not installed" -Fixture {
                $testParams = @{
                    IsSingleInstance          = "Yes"
                    Ensure                    = "Present"
                    FarmConfigDatabaseName    = "SP_Config"
                    DatabaseServer            = "DatabaseServer\Instance"
                    FarmAccount               = $mockFarmAccount
                    Passphrase                = $mockPassphrase
                    AdminContentDatabaseName  = "Admin_Content"
                    CentralAdministrationAuth = "Kerberos"
                    CentralAdministrationPort = 1234
                    ServerRole                = "ApplicationWithSearch"
                    RunCentralAdmin           = $false
                }

                Mock -CommandName Get-SPDscInstalledProductVersion -MockWith {
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
                    IsSingleInstance         = "Yes"
                    Ensure                   = "Present"
                    FarmConfigDatabaseName   = "SP_Config"
                    DatabaseServer           = "sql.contoso.com"
                    FarmAccount              = $mockFarmAccount
                    Passphrase               = $mockPassphrase
                    AdminContentDatabaseName = "SP_AdminContent"
                    ServerRole               = "ApplicationWithSearch"
                    RunCentralAdmin          = $true
                }

                Mock -CommandName "Get-SPDscRegistryKey" -MockWith { return $null }
                Mock -CommandName "Get-SPFarm" -MockWith { return $null }
                Mock -CommandName "Get-SPDscConfigDBStatus" -MockWith {
                    return @{
                        Locked           = $false
                        ValidPermissions = $true
                        DatabaseExists   = $false
                    }
                }
                Mock -CommandName "Get-SPDscSQLInstanceStatus" -MockWith {
                    return @{
                        MaxDOPCorrect = $true
                    }
                }
                Mock -CommandName "Get-SPWebApplication" -MockWith {
                    return @{
                        IsAdministrationWebApplication = $true
                        Url                            = "http://localhost:12345"
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

            Context -Name "DeveloperDashboard is set to OnDemand, which is not allowed in SP2016 and above" -Fixture {
                $testParams = @{
                    IsSingleInstance         = "Yes"
                    Ensure                   = "Present"
                    FarmConfigDatabaseName   = "SP_Config"
                    DatabaseServer           = "sql.contoso.com"
                    FarmAccount              = $mockFarmAccount
                    Passphrase               = $mockPassphrase
                    AdminContentDatabaseName = "SP_AdminContent"
                    RunCentralAdmin          = $true
                    DeveloperDashboard       = "OnDemand"
                }

                Mock -CommandName "Get-SPDscRegistryKey" -MockWith {
                    return "Connection string example"
                }

                Mock -CommandName "Get-SPFarm" -MockWith {
                    return @{
                        Name                     = $testParams.FarmConfigDatabaseName
                        DatabaseServer           = @{
                            Name = $testParams.DatabaseServer
                        }
                        AdminContentDatabaseName = $testParams.AdminContentDatabaseName
                    }
                }
                Mock -CommandName "Get-SPDscConfigDBStatus" -MockWith {
                    return @{
                        Locked           = $false
                        ValidPermissions = $true
                        DatabaseExists   = $true
                    }
                }
                Mock -CommandName "Get-SPDscSQLInstanceStatus" -MockWith {
                    return @{
                        MaxDOPCorrect = $true
                    }
                }
                Mock -CommandName "Get-SPDatabase" -MockWith {
                    return @(@{
                            Name                 = $testParams.FarmConfigDatabaseName
                            Type                 = "Configuration Database"
                            NormalizedDataSource = $testParams.DatabaseServer
                        })
                }
                Mock -CommandName "Get-SPWebApplication" -MockWith {
                    return @{
                        IsAdministrationWebApplication = $true
                        ContentDatabases               = @(@{
                                Name = $testParams.AdminContentDatabaseName
                            })
                        IISSettings                    = @(@{
                                DisableKerberos = $true
                            })
                        Url                            = "http://localhost:9999"
                    }
                }
                Mock -CommandName "Get-SPServiceInstance" -MockWith {
                    if ($global:SPDscCentralAdminCheckDone -eq $true)
                    {
                        return @(
                            @{
                                Name   = "WSS_Administration"
                                Status = "Online"
                            } | Add-Member -MemberType ScriptMethod `
                                -Name GetType `
                                -Value {
                                return @{
                                    Name = "SPWebServiceInstance"
                                }
                            } -PassThru -Force
                        )
                    }
                    else
                    {
                        $global:SPDscCentralAdminCheckDone = $true
                        return $null
                    }
                }

                It "Should throw and exception in the get method" {
                    { Get-TargetResource @testParams } | Should Throw "The DeveloperDashboard value 'OnDemand' is not allowed in SharePoint 2016 and 2019"
                }

                It "Should throw and exception in the set method" {
                    { Set-TargetResource @testParams } | Should Throw "The DeveloperDashboard value 'OnDemand' is not allowed in SharePoint 2016 and 2019"
                }

                It "Should throw and exception in the test method" {
                    { Test-TargetResource @testParams } | Should Throw "The DeveloperDashboard value 'OnDemand' is not allowed in SharePoint 2016 and 2019"
                }
            }
        }

        Context -Name "no serverrole is specified but get-targetresource needs to identify and return it" -Fixture {
            $testParams = @{
                IsSingleInstance         = "Yes"
                Ensure                   = "Present"
                FarmConfigDatabaseName   = "SP_Config"
                DatabaseServer           = "sql.contoso.com"
                FarmAccount              = $mockFarmAccount
                Passphrase               = $mockPassphrase
                AdminContentDatabaseName = "SP_AdminContent"
                RunCentralAdmin          = $true
            }
            Mock -CommandName "Get-SPDscRegistryKey" -MockWith {
                return "Connection string example"
            }

            Mock -CommandName "Get-SPFarm" -MockWith {
                return @{
                    Name                     = $testParams.FarmConfigDatabaseName
                    DatabaseServer           = @{
                        Name = $testParams.DatabaseServer
                    }
                    AdminContentDatabaseName = $testParams.AdminContentDatabaseName
                }
            }
            Mock -CommandName "Get-SPDscConfigDBStatus" -MockWith {
                return @{
                    Locked           = $false
                    ValidPermissions = $true
                    DatabaseExists   = $true
                }
            }
            Mock -CommandName "Get-SPDscSQLInstanceStatus" -MockWith {
                return @{
                    MaxDOPCorrect = $true
                }
            }
            Mock -CommandName "Get-SPDatabase" -MockWith {
                return @(@{
                        Name   = $testParams.FarmConfigDatabaseName
                        Type   = "Configuration Database"
                        Server = @{
                            Name = $testParams.DatabaseServer
                        }
                    })
            }
            Mock -CommandName "Get-SPWebApplication" -MockWith {
                return @{
                    IsAdministrationWebApplication = $true
                    ContentDatabases               = @(@{
                            Name = $testParams.AdminContentDatabaseName
                        })
                    IISSettings                    = @(@{
                            DisableKerberos = $true
                        })
                    Url                            = "http://localhost:9999"
                }
            }
            Mock -CommandName Get-SPServer -MockWith {
                return @{
                    Name = "spwfe"
                    Role = "WebFrontEnd"
                }
            }

            Mock -CommandName Get-SPDscInstalledProductVersion -MockWith { return @{ FileMajorPart = 16; ProductBuildPart = 4700 } }

            It "Should return WebFrontEnd from the get method" {
                (Get-TargetResource @testParams).ServerRole | Should Be "WebFrontEnd"
            }
        }

        Context -Name "no farm is configured locally and an unsupported version of SharePoint is installed on the server" -Fixture {
            $testParams = @{
                IsSingleInstance         = "Yes"
                Ensure                   = "Present"
                FarmConfigDatabaseName   = "SP_Config"
                DatabaseServer           = "sql.contoso.com"
                FarmAccount              = $mockFarmAccount
                Passphrase               = $mockPassphrase
                AdminContentDatabaseName = "SP_AdminContent"
                ServerRole               = "ApplicationWithSearch"
                RunCentralAdmin          = $true
            }

            Mock -CommandName Get-SPDscInstalledProductVersion -MockWith { return @{ FileMajorPart = 14 } }

            It "Should throw when an unsupported version is installed and set is called" {
                { Set-TargetResource @testParams } | Should throw
            }
        }

        Context -Name "The server is joined to the farm, but SQL server is unavailable" -Fixture {
            $testParams = @{
                IsSingleInstance         = "Yes"
                Ensure                   = "Present"
                FarmConfigDatabaseName   = "SP_Config"
                DatabaseServer           = "sql.contoso.com"
                FarmAccount              = $mockFarmAccount
                Passphrase               = $mockPassphrase
                AdminContentDatabaseName = "SP_AdminContent"
                RunCentralAdmin          = $true
            }

            Mock -CommandName "Get-SPDscRegistryKey" -MockWith {
                return "Connection string example"
            }
            Mock -CommandName "Get-SPFarm" -MockWith {
                return $null
            }
            Mock -CommandName "Get-SPDscConfigDBStatus" -MockWith {
                return @{
                    Locked           = $false
                    ValidPermissions = $false
                    DatabaseExists   = $false
                }
            }
            Mock -CommandName "Get-SPDscSQLInstanceStatus" -MockWith {
                return @{
                    MaxDOPCorrect = $true
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
                    return @(
                        @{
                            Name   = "WSS_Administration"
                            Status = "Online"
                        } | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return @{
                                Name = "SPWebServiceInstance"
                            }
                        } -PassThru -Force
                    )
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
                IsSingleInstance         = "Yes"
                Ensure                   = "Present"
                FarmConfigDatabaseName   = "SP_Config"
                DatabaseServer           = "sql.contoso.com"
                FarmAccount              = $mockFarmAccount
                Passphrase               = $mockPassphrase
                AdminContentDatabaseName = "SP_AdminContent"
                RunCentralAdmin          = $true
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

            Mock -CommandName "Get-SPDscRegistryKey" -MockWith {
                return "Connection string example"
            }

            Mock -CommandName "Get-SPFarm" -MockWith {
                return @{
                    Name                     = $testParams.FarmConfigDatabaseName
                    DatabaseServer           = @{
                        Name = $testParams.DatabaseServer
                    }
                    AdminContentDatabaseName = $testParams.AdminContentDatabaseName
                }
            }
            Mock -CommandName "Get-SPDscConfigDBStatus" -MockWith {
                return @{
                    Locked           = $false
                    ValidPermissions = $true
                    DatabaseExists   = $true
                }
            }
            Mock -CommandName "Get-SPDscSQLInstanceStatus" -MockWith {
                return @{
                    MaxDOPCorrect = $true
                }
            }
            Mock -CommandName "Get-SPDatabase" -MockWith {
                return @(@{
                        Name                 = $testParams.FarmConfigDatabaseName
                        Type                 = "Configuration Database"
                        NormalizedDataSource = $testParams.DatabaseServer
                    })
            }
            Mock -CommandName "Get-SPWebApplication" -MockWith {
                return @{
                    IsAdministrationWebApplication = $true
                    ContentDatabases               = @(@{
                            Name = $testParams.AdminContentDatabaseName
                        })
                    IISSettings                    = @(@{
                            DisableKerberos = $true
                        })
                    Url                            = "http://localhost:9999"
                }
            }
            Mock -CommandName "Get-SPServiceInstance" -MockWith {
                if ($global:SPDscCentralAdminCheckDone -eq $true)
                {
                    return @(
                        @{
                            Name   = "WSS_Administration"
                            Status = "Online"
                        } | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return @{
                                Name = "SPWebServiceInstance"
                            }
                        } -PassThru -Force
                    )
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
