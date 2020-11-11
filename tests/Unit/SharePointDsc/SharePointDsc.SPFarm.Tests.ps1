[CmdletBinding()]
param
(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath '..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1' `
            -Resolve)
)

$script:DSCModuleName = 'SharePointDsc'
$script:DSCResourceName = 'SPFarm'
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
                Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

                # Initialize tests
                $mockPassword = ConvertTo-SecureString -String 'password' -AsPlainText -Force
                $mockFarmAccount = New-Object -TypeName 'System.Management.Automation.PSCredential' `
                    -ArgumentList @('username', $mockPassword)
                $mockPassphrase = New-Object -TypeName "System.Management.Automation.PSCredential" `
                    -ArgumentList @('PASSPHRASEUSER', $mockPassword)

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
                        DisplayLevel = 'Off'
                    }

                    $developerDashboardSettings = $developerDashboardSettings | Add-Member -MemberType ScriptMethod -Name Update -Value {
                        $Global:SPDscDevDashUpdated = $true
                    } -PassThru

                    $returnVal = @{
                        DeveloperDashboardSettings = $developerDashboardSettings
                    }
                    return $returnVal
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

            # Test Contexts
            Context -Name "No config databases exists, and this server should be connected to one" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance          = 'Yes'
                        Ensure                    = 'Present'
                        FarmConfigDatabaseName    = 'SP_Config'
                        CentralAdministrationPort = 80000
                        DatabaseServer            = 'sql.contoso.com'
                        FarmAccount               = $mockFarmAccount
                        Passphrase                = $mockPassphrase
                        AdminContentDatabaseName  = 'SP_AdminContent'
                        RunCentralAdmin           = $true
                    }

                    $expectedException = "Cannot validate argument on parameter 'CentralAdministrationPort'. " +
                    "The 80000 argument is greater than the maximum allowed range of 65535. " +
                    "Supply an argument that is less than or equal to 65535 and then try the command again."
                }

                It 'Should throw parameter validation exception in the get method' {
                    { Get-TargetResource @testParams } | Should -Throw $expectedException
                }

                It 'Should throw parameter validation exception in the test method' {
                    { Test-TargetResource @testParams } | Should -Throw $expectedException
                }

                It 'Should throw parameter validation exception in the Set method' {
                    { Set-TargetResource @testParams } | Should -Throw $expectedException
                }
            }

            Context -Name "CA URL passed in cannot be parsed as System.Uri" -Fixture {
                BeforeAll {
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
                }

                It "Should throw exception in the test method" {
                    { Test-TargetResource @testParams } | Should -Throw "CentralAdministrationUrl is not a valid URI. It should include the scheme (http/https) and address."
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "CentralAdministrationUrl is not a valid URI. It should include the scheme (http/https) and address."
                }
            }

            Context -Name "CA URL has been passed in, and the port does not match the one specified in CA Port" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance          = "Yes"
                        Ensure                    = "Present"
                        FarmConfigDatabaseName    = "SP_Config"
                        CentralAdministrationPort = 80
                        CentralAdministrationUrl  = "https://admin.contoso.com"
                        DatabaseServer            = "sql.contoso.com"
                        FarmAccount               = $mockFarmAccount
                        Passphrase                = $mockPassphrase
                        AdminContentDatabaseName  = "SP_AdminContent"
                        RunCentralAdmin           = $true
                    }
                }

                It "Should throw exception in the test method" {
                    { Test-TargetResource @testParams } | Should -Throw ("CentralAdministrationPort does not match port number specified in CentralAdministrationUrl. " +
                        "Either make the values match or don't specify CentralAdministrationPort.")
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw ("CentralAdministrationPort does not match port number specified in CentralAdministrationUrl. " +
                        "Either make the values match or don't specify CentralAdministrationPort.")
                }
            }

            Context -Name "No config databases exists, and this server should be connected to one" -Fixture {
                BeforeAll {
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
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create the config database in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName "New-SPConfigurationDatabase"
                    Assert-MockCalled -CommandName "New-SPCentralAdministration"
                }
            }

            Context -Name "No config databases exists, and this server should be connected to one but won't run central admin" -Fixture {
                BeforeAll {
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
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should join the config database in the set method as it wont be running central admin" {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName "Connect-SPConfigurationDatabase"
                }
            }

            Context -Name "A config database exists, and this server should be connected to it but isn't and this server won't run central admin" -Fixture {
                BeforeAll {
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
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should join the config database in the set method" {
                    $global:SPDscCentralAdminCheckDone = $false
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName "Connect-SPConfigurationDatabase"
                }
            }

            Context -Name "A config database exists, and this server should be connected to it but isn't and this server will run central admin" -Fixture {
                BeforeAll {
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
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should join the config database in the set method" {
                    $global:SPDscCentralAdminCheckDone = $false
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName "Connect-SPConfigurationDatabase"
                    Assert-MockCalled -CommandName "Start-SPServiceInstance"
                }
            }

            Context -Name "A config and lock database exist, and this server should be connected to it but isn't" -Fixture {
                BeforeAll {
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
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should wait for the lock to be released then join the config DB in the set method" {
                    $global:SPDscConfigLockTriggered = $false
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName "Get-SPDscConfigDBStatus" -Times 2
                    Assert-MockCalled -CommandName "Connect-SPConfigurationDatabase"
                }
            }

            # Adding coverage here for when CA URL is HTTPS but port is not specified
            Context -Name "Server is connected to farm, but Central Admin isn't started" -Fixture {
                BeforeAll {
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
                            Services                 = @{
                                TypeName         = "Central Administration"
                                ApplicationPools = @{
                                    Name = "SharePoint Central Administration v4"
                                }
                            }
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
                }

                It "Should return false from the get method" {
                    $global:SPDscSIRunCount = 0
                    (Get-TargetResource @testParams).RunCentralAdmin | Should -Be $false
                }

                It "Should start the central administration instance" {
                    $global:SPDscSIRunCount = 0
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName "Start-SPServiceInstance"
                }

                It "Should return false from the test method" {
                    $global:SPDscCentralAdminCheckDone = $false
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "Server is connected to farm, but CentralAdminPort is different (specified by CAUrl)" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance         = "Yes"
                        Ensure                   = "Present"
                        FarmConfigDatabaseName   = "SP_Config"
                        DatabaseServer           = "sql.contoso.com"
                        FarmAccount              = $mockFarmAccount
                        Passphrase               = $mockPassphrase
                        AdminContentDatabaseName = "SP_AdminContent"
                        RunCentralAdmin          = $true
                        CentralAdministrationUrl = "http://localhost:8080"
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
                            Services                 = @{
                                TypeName         = "Central Administration"
                                ApplicationPools = @{
                                    Name = "SharePoint Central Administration v4"
                                }
                            }
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
                }

                It "Should return 9999 as CA Port from the get method" {
                    (Get-TargetResource @testParams).CentralAdministrationPort | Should -Be 9999
                }

                It "Should remove, and re-extend CA web application in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName "Remove-SPWebApplication"
                    Assert-MockCalled -CommandName "New-SPWebApplicationExtension"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "Server is connected to farm, but CentralAdminPort is different (specified by CAPort)" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance          = "Yes"
                        Ensure                    = "Present"
                        FarmConfigDatabaseName    = "SP_Config"
                        DatabaseServer            = "sql.contoso.com"
                        FarmAccount               = $mockFarmAccount
                        Passphrase                = $mockPassphrase
                        AdminContentDatabaseName  = "SP_AdminContent"
                        RunCentralAdmin           = $true
                        CentralAdministrationUrl  = ""
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
                }

                It "Should return 9999 as CA Port from the get method" {
                    (Get-TargetResource @testParams).CentralAdministrationPort | Should -Be 9999
                }

                It "Should update the central administration port" {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName "Set-SPCentralAdministration"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "This server is running CA as NTLM, but authentication method should be Kerberos" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance          = "Yes"
                        Ensure                    = "Present"
                        FarmConfigDatabaseName    = "SP_Config"
                        DatabaseServer            = "sql.contoso.com"
                        FarmAccount               = $mockFarmAccount
                        Passphrase                = $mockPassphrase
                        AdminContentDatabaseName  = "SP_AdminContent"
                        RunCentralAdmin           = $true
                        CentralAdministrationUrl  = "http://admin.contoso.com"
                        CentralAdministrationPort = 80
                        CentralAdministrationAuth = "Kerberos"
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
                                    ServerBindings  = @(
                                        @{
                                            HostHeader = "admin.contoso.com"
                                            Port       = "80"
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

                    Mock -CommandName Set-SPWebApplication -MockWith { }
                }

                It "Should return current values for the Get method" {
                    $global:SPDscSIRunCount = 2
                    $result = Get-TargetResource @testParams
                    $result.RunCentralAdmin | Should -Be $true
                    $result.CentralAdministrationUrl | Should -Be $testParams.CentralAdministrationUrl
                    $result.CentralAdministrationPort | Should -Be $testParams.CentralAdministrationPort
                    $result.CentralAdministrationAuth | Should -Be "NTLM"
                }

                It "Should change Authentication Mode of CA from NTLM to Kerberos" {
                    $global:SPDscSIRunCount = 2
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName "Set-SPWebApplication"
                }

                It "Should return false from the test method" {
                    $global:SPDscSIRunCount = 2
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "This server is running CA as Kerberos, but authentication method should be NTLM" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance          = "Yes"
                        Ensure                    = "Present"
                        FarmConfigDatabaseName    = "SP_Config"
                        DatabaseServer            = "sql.contoso.com"
                        FarmAccount               = $mockFarmAccount
                        Passphrase                = $mockPassphrase
                        AdminContentDatabaseName  = "SP_AdminContent"
                        RunCentralAdmin           = $true
                        CentralAdministrationUrl  = "http://admin.contoso.com"
                        CentralAdministrationPort = 80
                        CentralAdministrationAuth = "NTLM"
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
                                    DisableKerberos = $false
                                    ServerBindings  = @(
                                        @{
                                            HostHeader = "admin.contoso.com"
                                            Port       = "80"
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

                    Mock -CommandName Set-SPWebApplication -MockWith { }
                }

                It "Should return current values for the Get method" {
                    $global:SPDscSIRunCount = 2
                    $result = Get-TargetResource @testParams
                    $result.RunCentralAdmin | Should -Be $true
                    $result.CentralAdministrationUrl | Should -Be $testParams.CentralAdministrationUrl
                    $result.CentralAdministrationPort | Should -Be $testParams.CentralAdministrationPort
                    $result.CentralAdministrationAuth | Should -Be "Kerberos"
                }

                It "Should change Authentication Mode of CA from Kerberos to NTLM" {
                    $global:SPDscSIRunCount = 2
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName "Set-SPWebApplication"
                }

                It "Should return false from the test method" {
                    $global:SPDscSIRunCount = 2
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "This server is running CA on HTTP, but secure bindings do not match CA URL" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance          = "Yes"
                        Ensure                    = "Present"
                        FarmConfigDatabaseName    = "SP_Config"
                        DatabaseServer            = "sql.contoso.com"
                        FarmAccount               = $mockFarmAccount
                        Passphrase                = $mockPassphrase
                        AdminContentDatabaseName  = "SP_AdminContent"
                        RunCentralAdmin           = $true
                        CentralAdministrationUrl  = "http://admin.contoso.com"
                        CentralAdministrationPort = 80
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
                            Services                 = @{
                                TypeName         = "Central Administration"
                                ApplicationPools = @{
                                    Name = "SharePoint Central Administration v4"
                                }
                            }
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
                                    ServerBindings  = @(
                                        @{
                                            HostHeader = "different.contoso.com"
                                            Port       = "80"
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
                }

                It "Should return current values for the Get method" {
                    $global:SPDscSIRunCount = 0
                    $result = Get-TargetResource @testParams
                    $result.RunCentralAdmin | Should -Be $false
                    $result.CentralAdministrationUrl | Should -Be $testParams.CentralAdministrationUrl
                    $result.CentralAdministrationPort | Should -Be $testParams.CentralAdministrationPort
                }

                It "Should start the central administration instance" {
                    $global:SPDscSIRunCount = 0
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName "Start-SPServiceInstance"
                }

                It "Should return false from the test method" {
                    $global:SPDscCentralAdminCheckDone = $false
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "This server is running CA on HTTPS, but secure bindings do not match CA URL" -Fixture {
                BeforeAll {
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
                            Services                 = @{
                                TypeName         = "Central Administration"
                                ApplicationPools = @{
                                    Name = "SharePoint Central Administration v4"
                                }
                            }
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
                }

                It "Should return current values for the Get method" {
                    $global:SPDscSIRunCount = 0
                    $result = Get-TargetResource @testParams
                    $result.RunCentralAdmin | Should -Be $false
                    $result.CentralAdministrationUrl | Should -Be $testParams.CentralAdministrationUrl
                    $result.CentralAdministrationPort | Should -Be $testParams.CentralAdministrationPort
                }

                It "Should start the central administration instance" {
                    $global:SPDscSIRunCount = 0
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName "Start-SPServiceInstance"
                }

                It "Should return false from the test method" {
                    $global:SPDscCentralAdminCheckDone = $false
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "Server not yet part of the farm, and will run Central Admin on HTTP with vanity host name" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IsSingleInstance         = "Yes"
                        Ensure                   = "Present"
                        FarmConfigDatabaseName   = "SP_Config"
                        DatabaseServer           = "sql.contoso.com"
                        FarmAccount              = $mockFarmAccount
                        Passphrase               = $mockPassphrase
                        AdminContentDatabaseName = "SP_AdminContent"
                        CentralAdministrationUrl = "http://admin.contoso.com"
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
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should provision, remove, and re-extend CA web application in the set method" {
                    $global:SPDscCentralAdminCheckDone = $false
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName "New-SPCentralAdministration"
                    Assert-MockCalled -CommandName "Remove-SPWebApplication"
                    Assert-MockCalled -CommandName "New-SPWebApplicationExtension"
                }
            }

            Context -Name "Server not yet part of the farm, and will run Central Admin on HTTPS" -Fixture {
                BeforeAll {
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
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should provision, remove, and re-extend CA web application in the set method" {
                    $global:SPDscCentralAdminCheckDone = $false
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName "New-SPCentralAdministration"
                    Assert-MockCalled -CommandName "Remove-SPWebApplication"
                    Assert-MockCalled -CommandName "New-SPWebApplicationExtension"
                }
            }

            Context -Name "This server is running CA on HTTPS, but secure bindings do not contain valid hostname" -Fixture {
                BeforeAll {
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
                            Services                 = @{
                                TypeName         = "Central Administration"
                                ApplicationPools = @{
                                    Name = "SharePoint Central Administration v4"
                                }
                            }
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
                }

                It "Should return current values for the Get method" {
                    $global:SPDscSIRunCount = 0
                    $result = Get-TargetResource @testParams
                    $result.RunCentralAdmin | Should -Be $false
                    $result.CentralAdministrationUrl | Should -Be $testParams.CentralAdministrationUrl
                    $result.CentralAdministrationPort | Should -Be $testParams.CentralAdministrationPort
                }

                It "Should start the central administration instance" {
                    $global:SPDscSIRunCount = 0
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName "Start-SPServiceInstance"
                }

                It "Should return false from the test method" {
                    $global:SPDscCentralAdminCheckDone = $false
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "This server is connected to the farm and is running CA, but shouldn't" -Fixture {
                BeforeAll {
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
                }

                It "Should return present from the get method" {
                    $global:SPDscSIRunCount = 0
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Present"
                    $result.RunCentralAdmin | Should -Be $true
                }

                It "Should stop the CA instance in the set method" {
                    $global:SPDscSIRunCount = 0
                    Set-TargetResource @testParams
                    Assert-MockCalled Stop-SPServiceInstance
                }

                It "Should return false from the test method" {
                    $global:SPDscSIRunCount = 0
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "Server is connected to a farm, but Developer Dashboard settings are incorrect" -Fixture {
                BeforeAll {
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
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).DeveloperDashboard | Should -Be "Off"
                }

                It "Should update DevDashboard settings in the set method" {
                    $Global:SPDscDevDashUpdated = $false
                    Set-TargetResource @testParams
                    $Global:SPDscDevDashUpdated | Should -Be $true
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "A config database exists, and this server is connected to it and should be" -Fixture {
                BeforeAll {
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
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Absent is specified for the ensure property" -Fixture {
                BeforeAll {
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
                }

                It "Should throw an exception from the get method" {
                    { Get-TargetResource @testParams } | Should -Throw
                }

                It "Should throw an exception from the test method" {
                    { Test-TargetResource @testParams } | Should -Throw
                }

                It "Should throw an exception from the set method" {
                    { Set-TargetResource @testParams } | Should -Throw
                }
            }

            if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
            {
                Context -Name "Only valid parameters for SharePoint 2013 are used" -Fixture {
                    BeforeAll {
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
                    }

                    It "Should throw if server role is used in the get method" {
                        { Get-TargetResource @testParams } | Should -Throw
                    }

                    It "Should throw if server role is used in the test method" {
                        { Test-TargetResource @testParams } | Should -Throw
                    }

                    It "Should throw if server role is used in the set method" {
                        { Set-TargetResource @testParams } | Should -Throw
                    }
                }

                Context -Name "no serverrole is specified and get-targetresource needs to return null" -Fixture {
                    BeforeAll {
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
                    }

                    It "Should return WebFrontEnd from the get method" {
                        (Get-TargetResource @testParams).ServerRole | Should -Be $null
                    }
                }
            }

            if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 16)
            {
                Context -Name "enhanced minrole options fail when Feature Pack 1 is not installed" -Fixture {
                    BeforeAll {
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
                    }

                    It "Should throw if an invalid server role is used in the get method" {
                        { Get-TargetResource @testParams } | Should -Throw
                    }

                    It "Should throw if an invalid server role is used in the test method" {
                        { Test-TargetResource @testParams } | Should -Throw
                    }

                    It "Should throw if an invalid server role is used in the set method" {
                        { Set-TargetResource @testParams } | Should -Throw
                    }
                }

                Context -Name "enhanced minrole options succeed when Feature Pack 1 is installed" -Fixture {
                    BeforeAll {
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
                    }

                    It "Should throw if an invalid server role is used in the get method" {
                        { Get-TargetResource @testParams } | Should -Not -Throw
                    }

                    It "Should throw if an invalid server role is used in the test method" {
                        { Test-TargetResource @testParams } | Should -Not -Throw
                    }

                    It "Should throw if an invalid server role is used in the set method" {
                        { Set-TargetResource @testParams } | Should -Not -Throw
                    }
                }

                Context -Name "DeveloperDashboard is set to OnDemand, which is not allowed in SP2016 and above" -Fixture {
                    BeforeAll {
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
                    }

                    It "Should throw an exception in the get method" {
                        { Get-TargetResource @testParams } | Should -Throw "The DeveloperDashboard value 'OnDemand' is not allowed in SharePoint 2016 and 2019"
                    }

                    It "Should throw an exception in the set method" {
                        { Set-TargetResource @testParams } | Should -Throw "The DeveloperDashboard value 'OnDemand' is not allowed in SharePoint 2016 and 2019"
                    }

                    It "Should throw an exception in the test method" {
                        { Test-TargetResource @testParams } | Should -Throw "The DeveloperDashboard value 'OnDemand' is not allowed in SharePoint 2016 and 2019"
                    }
                }
            }

            if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 16 -and
                $Global:SPDscHelper.CurrentStubBuildNumber.Build.ToString().Length -ne 4)
            {
                Context -Name "ApplicationCredentialKey is specified on SP2019 installation" -Fixture {
                    BeforeAll {
                        $testParams = @{
                            IsSingleInstance         = "Yes"
                            Ensure                   = "Present"
                            FarmConfigDatabaseName   = "SP_Config"
                            DatabaseServer           = "sql.contoso.com"
                            FarmAccount              = $mockFarmAccount
                            Passphrase               = $mockPassphrase
                            AdminContentDatabaseName = "SP_AdminContent"
                            ApplicationCredentialKey = $mockPassphrase
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

                        Mock -CommandName Set-SPApplicationCredentialKey -MockWith { return $null }
                    }

                    It "Should not throw an exception in the get method" {
                        { Get-TargetResource @testParams } | Should -Not -Throw "Specifying ApplicationCredentialKey is only supported on SharePoint 2019"
                    }

                    It "Should set application credential key" {
                        Set-TargetResource @testParams
                        Assert-MockCalled -CommandName "Set-SPApplicationCredentialKey"
                    }

                    It "Should not throw an exception in the test method" {
                        { Test-TargetResource @testParams } | Should -Not -Throw "Specifying ApplicationCredentialKey is only supported on SharePoint 2019"
                    }
                }
            }

            Context -Name "no serverrole is specified but get-targetresource needs to identify and return it" -Fixture {
                BeforeAll {
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
                }

                It "Should return WebFrontEnd from the get method" {
                    (Get-TargetResource @testParams).ServerRole | Should -Be "WebFrontEnd"
                }
            }

            Context -Name "no farm is configured locally and an unsupported version of SharePoint is installed on the server" -Fixture {
                BeforeAll {
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
                }

                It "Should throw when an unsupported version is installed and set is called" {
                    { Set-TargetResource @testParams } | Should -Throw
                }
            }

            Context -Name "The server is joined to the farm, but SQL server is unavailable" -Fixture {
                BeforeAll {
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
                }

                It "Should still return present in the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Present"
                    $result.RunCentralAdmin | Should -BeNullOrEmpty
                }

                It "Should return false in the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "A config database exists, and this server is connected (with FQDN) to it and should be" -Fixture {
                BeforeAll {
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
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
