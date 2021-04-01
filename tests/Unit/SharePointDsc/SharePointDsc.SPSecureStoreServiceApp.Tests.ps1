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
$script:DSCResourceName = 'SPSecureStoreServiceApp'
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

                # Initialize tests
                $getTypeFullName = "Microsoft.Office.SecureStoreService.Server.SecureStoreServiceApplication"
                $mockPassword = ConvertTo-SecureString -String "passwprd" -AsPlainText -Force
                $mockCredential = New-Object -TypeName System.Management.Automation.PSCredential `
                    -ArgumentList @("SqlUser", $mockPassword)

                # Mocks for all contexts
                Mock -CommandName Remove-SPServiceApplication -MockWith { }
                Mock -CommandName New-SPSecureStoreServiceApplication -MockWith { return "" }
                Mock -CommandName New-SPSecureStoreServiceApplicationProxy -MockWith { }
                Mock -CommandName Set-SPSecureStoreServiceApplication -MockWith { }

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
            Context -Name "When no service application exists in the current farm" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Secure Store Service Application"
                        ApplicationPool = "SharePoint Services"
                        AuditingEnabled = $false
                        Ensure          = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        return $null
                    }

                    Mock -CommandName Update-SPSecureStoreMasterKey -MockWith { }
                }

                It "Should return absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create a new service application in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPSecureStoreServiceApplication
                }

                It "Should create a new service application in the set method where parameters beyond the minimum required set" {
                    $testParams.Add("DatabaseName", "SP_SecureStore")

                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName New-SPSecureStoreServiceApplication -Times 1
                    Assert-MockCalled -CommandName New-SPSecureStoreServiceApplicationProxy -Times 1
                    Assert-MockCalled -CommandName Update-SPSecureStoreMasterKey -Times 0
                }
            }

            Context -Name "When no service application exists in the current farm, MasterKey specified" -Fixture {
                BeforeAll {
                    $mockSecret = ConvertTo-SecureString -String 'password' -AsPlainText -Force
                    $mockMasterKey = New-Object -TypeName 'System.Management.Automation.PSCredential' `
                        -ArgumentList @('dummy', $mockSecret)

                    $testParams = @{
                        Name            = "Secure Store Service Application"
                        ApplicationPool = "SharePoint Services"
                        AuditingEnabled = $false
                        MasterKey       = $mockMasterKey
                        Ensure          = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        return $null
                    }

                    Mock -CommandName Update-SPSecureStoreMasterKey -MockWith { }
                }

                It "Should return absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create a new service application in the set method" {
                    Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                        return @{
                            Name = "$($testParams.Name) Proxy"
                        }
                    }

                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName New-SPSecureStoreServiceApplication -Times 1
                    Assert-MockCalled -CommandName New-SPSecureStoreServiceApplicationProxy -Times 1
                    Assert-MockCalled -CommandName Update-SPSecureStoreMasterKey -Times 1
                }
            }

            Context -Name "When service applications exist in the current farm but the specific search app does not" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Secure Store Service Application"
                        ApplicationPool = "SharePoint Services"
                        AuditingEnabled = $false
                        Ensure          = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            DisplayName = $testParams.Name
                            Name        = $testParams.Name
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
                        Name            = "Secure Store Service Application"
                        ApplicationPool = "SharePoint Services"
                        AuditingEnabled = $false
                        Ensure          = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName        = "Secure Store Service Application"
                            DisplayName     = $testParams.Name
                            Name            = $testParams.Name
                            ApplicationPool = @{
                                Name = $testParams.ApplicationPool
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
                                                        -Value "Database" `
                                                        -PassThru |
                                                        Add-Member -MemberType ScriptMethod `
                                                            -Name GetValue `
                                                            -Value {
                                                            param ($x)
                                                            return (
                                                                @{
                                                                    FullName             = $getTypeFullName
                                                                    Name                 = "Database"
                                                                    NormalizedDataSource = "DBServer"
                                                                    Server               = @{
                                                                        Name = "DBServer"
                                                                    }
                                                                    FailoverServer       = @{
                                                                        Name = "DBServer_Failover"
                                                                    }
                                                                }
                                                            )
                                                        } -PassThru
                                                    ),
                                                    (New-Object -TypeName "Object" |
                                                            Add-Member -MemberType NoteProperty `
                                                                -Name Name `
                                                                -Value "AuditEnabled" `
                                                                -PassThru |
                                                                Add-Member -MemberType ScriptMethod `
                                                                    -Name GetValue `
                                                                    -Value {
                                                                    param($x)
                                                                    return $params.AuditEnabled
                                                                } -PassThru
                                                            )
                                                        )
                                                    } -PassThru
                        } -PassThru -Force

                        return $spServiceApp
                    }
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return true when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "When a service application exists and the app pool is not configured correctly" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Secure Store Service Application"
                        ApplicationPool = "SharePoint Services"
                        AuditingEnabled = $false
                        Ensure          = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName        = "Secure Store Service Application"
                            DisplayName     = $testParams.Name
                            Name            = $testParams.Name
                            ApplicationPool = @{
                                Name = "Wrong App Pool Name"
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
                                                        -Value "Database" `
                                                        -PassThru |
                                                        Add-Member -MemberType ScriptMethod `
                                                            -Name GetValue `
                                                            -Value {
                                                            param($x)
                                                            return (
                                                                @{
                                                                    FullName             = $getTypeFullName
                                                                    Name                 = "Database"
                                                                    NormalizedDataSource = "DBServer"
                                                                    Server               = @{
                                                                        Name = "DBServer"
                                                                    }
                                                                    FailoverServer       = @{
                                                                        Name = "DBServer_Failover"
                                                                    }
                                                                }
                                                            )
                                                        } -PassThru
                                                    ),
                                                    (New-Object -TypeName "Object" |
                                                            Add-Member -MemberType NoteProperty `
                                                                -Name Name `
                                                                -Value "AuditEnabled" `
                                                                -PassThru |
                                                                Add-Member -MemberType ScriptMethod `
                                                                    -Name GetValue `
                                                                    -Value {
                                                                    param($x)
                                                                    return $params.AuditEnabled
                                                                } -PassThru
                                                            )
                                                        )
                                                    } -PassThru
                        } -PassThru -Force

                        return $spServiceApp
                    }

                    Mock -CommandName Get-SPServiceApplicationPool -MockWith {
                        return @{
                            Name = $testParams.ApplicationPool
                        }
                    }
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the update service app cmdlet from the set method" {
                    Set-TargetResource @testParams

                    Assert-MockCalled Get-SPServiceApplicationPool
                    Assert-MockCalled Set-SPSecureStoreServiceApplication
                }
            }

            Context -Name "When specific windows credentials are to be used for the database" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                = "Secure Store Service Application"
                        ApplicationPool     = "SharePoint Services"
                        AuditingEnabled     = $false
                        DatabaseName        = "SP_ManagedMetadata"
                        DatabaseCredentials = $mockCredential
                        Ensure              = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        return $null
                    }
                }

                It "allows valid Windows credentials can be passed" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPSecureStoreServiceApplication
                }
            }

            Context -Name "When specific SQL credentials are to be used for the database" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                = "Secure Store Service Application"
                        ApplicationPool     = "SharePoint Services"
                        AuditingEnabled     = $false
                        DatabaseName        = "SP_ManagedMetadata"
                        DatabaseCredentials = $mockCredential
                        Ensure              = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith { return $null }
                }

                It "allows valid SQL credentials can be passed" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPSecureStoreServiceApplication
                }

            }

            Context -Name "When the service app exists but it shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Secure Store Service Application"
                        ApplicationPool = "-"
                        AuditingEnabled = $false
                        Ensure          = "Absent"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName        = "Secure Store Service Application"
                            DisplayName     = $testParams.Name
                            Name            = $testParams.Name
                            ApplicationPool = @{
                                Name = "Wrong App Pool Name"
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
                                                        -Value "Database" `
                                                        -PassThru |
                                                        Add-Member -MemberType ScriptMethod `
                                                            -Name GetValue `
                                                            -Value {
                                                            param($x)
                                                            return (
                                                                @{
                                                                    FullName             = $getTypeFullName
                                                                    Name                 = "Database"
                                                                    NormalizedDataSource = "DBServer"
                                                                    Server               = @{
                                                                        Name = "DBServer"
                                                                    }
                                                                    FailoverServer       = @{
                                                                        Name = "DBServer_Failover"
                                                                    }
                                                                }
                                                            )
                                                        } -PassThru
                                                    ),
                                                    (New-Object -TypeName "Object" |
                                                            Add-Member -MemberType NoteProperty `
                                                                -Name Name `
                                                                -Value "AuditEnabled" `
                                                                -PassThru |
                                                                Add-Member -MemberType ScriptMethod `
                                                                    -Name GetValue `
                                                                    -Value {
                                                                    param($x)
                                                                    return $params.AuditEnabled
                                                                } -PassThru
                                                            )
                                                        )
                                                    } -PassThru
                        } -PassThru -Force

                        return $spServiceApp
                    }
                }

                It "Should return present from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should remove the service application in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-SPServiceApplication
                }
            }

            Context -Name "When the database name does not match the actual name" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Secure Store Service Application"
                        ApplicationPool = "Service App Pool"
                        AuditingEnabled = $false
                        DatabaseName    = "SecureStoreDB"
                        Ensure          = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName        = "Secure Store Service Application"
                            DisplayName     = $testParams.Name
                            Name            = $testParams.Name
                            ApplicationPool = @{
                                Name = $testParams.ApplicationPool
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
                                                        -Value "Database" `
                                                        -PassThru |
                                                        Add-Member -MemberType ScriptMethod `
                                                            -Name GetValue `
                                                            -Value {
                                                            param($x)
                                                            return (
                                                                @{
                                                                    FullName             = $getTypeFullName
                                                                    Name                 = "Wrong Database"
                                                                    NormalizedDataSource = "DBServer"
                                                                    Server               = @{
                                                                        Name = "DBServer"
                                                                    }
                                                                    FailoverServer       = @{
                                                                        Name = "DBServer_Failover"
                                                                    }
                                                                }
                                                            )
                                                        } -PassThru
                                                    ),
                                                    (New-Object -TypeName "Object" |
                                                            Add-Member -MemberType NoteProperty `
                                                                -Name Name `
                                                                -Value "AuditEnabled" `
                                                                -PassThru |
                                                                Add-Member -MemberType ScriptMethod `
                                                                    -Name GetValue `
                                                                    -Value {
                                                                    param($x)
                                                                    return $params.AuditEnabled
                                                                } -PassThru
                                                            )
                                                        )
                                                    } -PassThru
                        } -PassThru -Force

                        return $spServiceApp
                    }
                }

                It "Should return present from the Get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Present"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw ("Specified database name does not match " + `
                            "the actual database name. This resource " + `
                            "cannot rename the database.")
                }
            }

            Context -Name "When the database server does not match the actual server" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Secure Store Service Application"
                        ApplicationPool = "Service App Pool"
                        AuditingEnabled = $false
                        DatabaseName    = "SecureStoreDB"
                        DatabaseServer  = "SQL_Instance"
                        Ensure          = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            TypeName        = "Secure Store Service Application"
                            DisplayName     = $testParams.Name
                            Name            = $testParams.Name
                            ApplicationPool = @{
                                Name = $testParams.ApplicationPool
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
                                                        -Value "Database" `
                                                        -PassThru |
                                                        Add-Member -MemberType ScriptMethod `
                                                            -Name GetValue `
                                                            -Value {
                                                            param($x)
                                                            return (
                                                                @{
                                                                    FullName             = $getTypeFullName
                                                                    Name                 = "SecureStoreDB"
                                                                    NormalizedDataSource = "Wrong DBServer"
                                                                    Server               = @{
                                                                        Name = "Wrong DBServer"
                                                                    }
                                                                    FailoverServer       = @{
                                                                        Name = "DBServer_Failover"
                                                                    }
                                                                }
                                                            )
                                                        } -PassThru
                                                    ),
                                                    (New-Object -TypeName "Object" |
                                                            Add-Member -MemberType NoteProperty `
                                                                -Name Name `
                                                                -Value "AuditEnabled" `
                                                                -PassThru |
                                                                Add-Member -MemberType ScriptMethod `
                                                                    -Name GetValue `
                                                                    -Value {
                                                                    param($x)
                                                                    return $params.AuditEnabled
                                                                } -PassThru
                                                            )
                                                        )
                                                    } -PassThru
                        } -PassThru -Force

                        return $spServiceApp
                    }
                }

                It "Should return present from the Get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Present"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw ("Specified database server does " + `
                            "not match the actual database server. " + `
                            "This resource cannot move the database " + `
                            "to a different SQL instance.")
                }
            }

            Context -Name "When the service app doesn't exist and shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name            = "Secure Store Service Application"
                        ApplicationPool = "-"
                        AuditingEnabled = $false
                        Ensure          = "Absent"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        return $null
                    }
                }

                It "Should return absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")

                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Name            = "Secure Store Service Application"
                            ProxyName       = "Secure Store Service Application Proxy"
                            DatabaseName    = "SP_SecureStore"
                            DatabaseServer  = "SQL01"
                            ApplicationPool = "Service App Pool"
                            AuditingEnabled = $true
                            AuditlogMaxSize = 30
                            Ensure          = "Present"
                        }
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            DisplayName = "Secure Store Service Application"
                            Name        = "Secure Store Service Application"
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return @{
                                Name = "SecureStoreServiceApplication"
                            }
                        } -PassThru -Force
                        return $spServiceApp
                    }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        SPSecureStoreServiceApp SecureStoreServiceApplication
        {
            ApplicationPool      = "Service App Pool";
            AuditingEnabled      = $True;
            AuditlogMaxSize      = 30;
            DatabaseName         = "SP_SecureStore";
            DatabaseServer       = $ConfigurationData.NonNodeData.DatabaseServer;
            Ensure               = "Present";
            Name                 = "Secure Store Service Application";
            ProxyName            = "Secure Store Service Application Proxy";
            PsDscRunAsCredential = $Credsspfarm;
        }

'@
                }

                It "Should return valid DSC block from the Export method" {
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
