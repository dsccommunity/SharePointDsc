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
$script:DSCResourceName = 'SPUserProfileServiceApp'
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
                $getTypeFullName = "Microsoft.Office.Server.Administration.UserProfileApplication"
                $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                $mockCredential = New-Object -TypeName System.Management.Automation.PSCredential `
                    -ArgumentList @("$($Env:USERDOMAIN)\$($Env:USERNAME)", $mockPassword)
                $mockFarmCredential = New-Object -TypeName System.Management.Automation.PSCredential `
                    -ArgumentList @("DOMAIN\sp_farm", $mockPassword)

                try
                {
                    [Microsoft.Office.Server.UserProfiles.UserProfileManager]
                }
                catch
                {
                    try
                    {
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
                    catch
                    {
                        Write-Verbose -Message "The Type Microsoft.Office.Server.UserProfiles.DirectoryServiceNamingContext was already added."
                    }
                }

                Add-Type -TypeDefinition @"
        using System.Collections;

        namespace Microsoft.SharePoint.Administration.AccessControl {
            public class SPNamedIisWebServiceApplicationRights
            {
                public static Hashtable FullControl
                {
                    get
                    {
                        Hashtable returnval = new Hashtable();
                        returnval.Add("Name","Full Control");
                        return returnval;
                    }
                }
            }
        }
"@

                # Mocks for all contexts
                $correctProxy = @{
                    DisplayName = "UPS"
                }

                $incorrectProxy = @{
                    DisplayName = "Incorrect"
                }

                $proxyGroup = @{
                    FriendlyName = "ProxyGroup"
                    Name         = "ProxyGroup"
                    Proxies      = @($correctProxy, $incorrectProxy)
                }

                Mock -CommandName Get-SPDscFarmAccount -MockWith {
                    return $mockFarmCredential
                }
                Mock -CommandName New-SPProfileServiceApplication -MockWith {
                    $returnval = @{
                        NetBIOSDomainNamesEnabled    = $false
                        NoILMUsed                    = $false
                        ServiceApplicationProxyGroup = $proxyGroup
                    }

                    $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                        -Name IsConnected `
                        -Value {
                        return $true
                    } -PassThru

                    return $returnval
                }
                Mock -CommandName New-SPProfileServiceApplicationProxy -MockWith { }
                Mock -CommandName Add-SPDscUserToLocalAdmin -MockWith { }
                Mock -CommandName Test-SPDscUserIsLocalAdmin -MockWith { return $false }
                Mock -CommandName Remove-SPDscUserToLocalAdmin -MockWith { }
                Mock -CommandName Remove-SPServiceApplication -MockWith { }

                Mock -CommandName Get-SPWebApplication -MockWith {
                    return @{
                        IsAdministrationWebApplication = $true
                        Url                            = "http://fake.contoso.com"
                        Sites                          = @("FakeSite1")
                    }
                }
                Mock -CommandName Get-SPServiceContext -MockWith {
                    return (@{
                            Fake1 = $true
                        })
                }
            }

            # Test contexts
            Context -Name "When PSDSCRunAsCredential matches the Farm Account and Service App is null" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name               = "User Profile Service App"
                        ApplicationPool    = "SharePoint Service Applications"
                        Ensure             = "Present"
                        MySiteHostLocation = "https://my.contoso.com"
                    }

                    Mock -CommandName Get-SPDscFarmAccount -MockWith {
                        return $mockCredential
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        return $null
                    }

                    Mock -CommandName Restart-Service { }
                }

                It "Should throw exception in the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should throw exception in the Test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Specified PSDSCRunAsCredential "
                }
            }

            Context -Name "When PSDSCRunAsCredential matches the Farm Account and Service App is not null" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name               = "User Profile Service App"
                        ApplicationPool    = "SharePoint Service Applications"
                        Ensure             = "Present"
                        MySiteHostLocation = "https://my.contoso.com"
                    }

                    Mock -CommandName Get-SPServiceApplicationProxyGroup -MockWith {
                        return @($proxyGroup)
                    }

                    Mock -CommandName Get-SPDscFarmAccount -MockWith {
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
                                $Global:SPDscUPSAUpdateCalled = $true
                            } -PassThru |
                            Add-Member -MemberType NoteProperty `
                                -Name ApplicationPool `
                                -Value @{
                                Name = $testParams.ApplicationPool
                            } -PassThru |
                            Add-Member -MemberType NoteProperty `
                                -Name ServiceApplicationProxyGroup `
                                -Value $proxyGroup `
                                -PassThru |
                            Add-Member -MemberType ScriptMethod `
                                -Name IsConnected `
                                -Value {
                                return $true
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
                                                    Name                 = "SP_SocialDB"
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
                                                    Name                 = "SP_ProfileDB"
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
                                                    Name                 = "SP_ProfileSyncDB"
                                                    NormalizedDataSource = "SQL.domain.local"
                                                }
                                            } -PassThru
                                        )
                                    )
                                } -PassThru
                            } -PassThru -Force
                        )
                    }

                    Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                        $proxiesToReturn = @()
                        $proxy = @{
                            Name        = "UPS"
                            DisplayName = "UPS"
                        }
                        $proxiesToReturn += $proxy

                        return $proxiesToReturn
                    }

                    Mock -CommandName Restart-Service { }
                }

                It "Should NOT throw exception in the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should throw exception in the Test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Specified PSDSCRunAsCredential "
                }
            }

            Context -Name "When InstallAccount matches the Farm Account" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name               = "User Profile Service App"
                        ApplicationPool    = "SharePoint Service Applications"
                        Ensure             = "Present"
                        MySiteHostLocation = "https://my.contoso.com"
                        InstallAccount     = $mockFarmCredential
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        return $null
                    }

                    Mock -CommandName Restart-Service { }
                }

                It "Should throw exception in the Get method" {
                    { Get-TargetResource @testParams } | Should -Throw "Specified InstallAccount "
                }

                It "Should throw exception in the Test method" {
                    { Test-TargetResource @testParams } | Should -Throw "Specified InstallAccount "
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Specified InstallAccount "
                }
            }

            Context -Name "When no service applications exist in the current farm" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name               = "User Profile Service App"
                        ApplicationPool    = "SharePoint Service Applications"
                        Ensure             = "Present"
                        MySiteHostLocation = "https://my.contoso.com"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        if ($global:ranGetServiceApp -eq $false)
                        {
                            $global:ranGetServiceApp = $true
                            return $null
                        }
                        else
                        {
                            return @(
                                New-Object -TypeName "Object" |
                                Add-Member -MemberType NoteProperty `
                                    -Name DisplayName `
                                    -Value $testParams.Name `
                                    -PassThru |
                                Add-Member -MemberType NoteProperty `
                                    -Name ServiceApplicationProxyGroup `
                                    -Value $proxyGroup `
                                    -PassThru |
                                Add-Member -MemberType ScriptMethod `
                                    -Name IsConnected `
                                    -Value {
                                    return $true
                                } -PassThru
                            )
                        }
                    }

                    Mock -CommandName New-SPClaimsPrincipal -MockWith { return @("") }
                    Mock -CommandName Get-SPServiceApplicationSecurity -MockWith { return @("") }
                    Mock -CommandName Grant-SPObjectSecurity -MockWith { }
                    Mock -CommandName Set-SPServiceApplicationSecurity -MockWith { }

                    Mock -CommandName Restart-Service { }

                    Mock -CommandName Get-SPServiceApplicationProxyGroup -MockWith {
                        return @($proxyGroup)
                    }

                    Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                        $proxiesToReturn = @()
                        $proxy = @{
                            Name        = "UPS"
                            DisplayName = "UPS"
                        }
                        $proxiesToReturn += $proxy

                        return $proxiesToReturn
                    }
                }

                It "Should return absent from the Get method" {
                    $global:ranGetServiceApp = $false
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false when the Test method is called" {
                    $global:ranGetServiceApp = $false
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create a new service application in the set method" {
                    $global:ranGetServiceApp = $false
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPProfileServiceApplication
                }
            }

            Context -Name "When service applications exist in the current farm but not the specific user profile service app" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name               = "User Profile Service App"
                        ApplicationPool    = "SharePoint Service Applications"
                        Ensure             = "Present"
                        MySiteHostLocation = "https://my.contoso.com"
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
                }

                It "Should return absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "When service applications exist in the current farm and NetBios isn't enabled but it needs to be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name               = "User Profile Service App"
                        ApplicationPool    = "SharePoint Service Applications"
                        EnableNetBIOS      = $true
                        Ensure             = "Present"
                        MySiteHostLocation = "https://my.contoso.com"
                    }

                    Mock -CommandName Restart-Service -MockWith { }
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
                                $Global:SPDscUPSAUpdateCalled = $true
                            } -PassThru |
                            Add-Member -MemberType NoteProperty `
                                -Name ApplicationPool `
                                -Value @{
                                Name = $testParams.ApplicationPool
                            } -PassThru |
                            Add-Member -MemberType NoteProperty `
                                -Name ServiceApplicationProxyGroup `
                                -Value $proxyGroup `
                                -PassThru |
                            Add-Member -MemberType ScriptMethod `
                                -Name IsConnected `
                                -Value {
                                return $true
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
                                                    Name                 = "SP_SocialDB"
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
                                                    Name                 = "SP_ProfileDB"
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
                                                    Name                 = "SP_ProfileSyncDB"
                                                    NormalizedDataSource = "SQL.domain.local"
                                                }
                                            } -PassThru
                                        )
                                    )
                                } -PassThru
                            } -PassThru -Force
                        )
                    }

                    Mock -CommandName Get-SPServiceApplicationProxyGroup -MockWith {
                        return @($proxyGroup)
                    }

                    Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                        $proxiesToReturn = @()
                        $proxy = @{
                            Name        = "UPS"
                            DisplayName = "UPS"
                        }
                        $proxiesToReturn += $proxy

                        return $proxiesToReturn
                    }
                }

                It "Should return false from the Get method" {
                    (Get-TargetResource @testParams).EnableNetBIOS | Should -Be $false
                }

                It "Should call Update method on Service Application before finishing set method" {
                    $Global:SPDscUPSAUpdateCalled = $false
                    Set-TargetResource @testParams
                    $Global:SPDscUPSAUpdateCalled | Should -Be $true
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should return true when the Test method is called" {
                    $testParams.EnableNetBIOS = $false
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "When service applications exist in the current farm and NoILMUsed isn't enabled but it needs to be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name               = "User Profile Service App"
                        ApplicationPool    = "SharePoint Service Applications"
                        NoILMUsed          = $true
                        Ensure             = "Present"
                        MySiteHostLocation = "https://my.contoso.com"
                    }

                    Mock -CommandName Restart-Service -MockWith { }
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
                                $Global:SPDscUPSAUpdateCalled = $true
                            } -PassThru |
                            Add-Member -MemberType NoteProperty `
                                -Name ApplicationPool `
                                -Value @{
                                Name = $testParams.ApplicationPool
                            } -PassThru |
                            Add-Member -MemberType NoteProperty `
                                -Name ServiceApplicationProxyGroup `
                                -Value $proxyGroup `
                                -PassThru |
                            Add-Member -MemberType ScriptMethod `
                                -Name IsConnected `
                                -Value {
                                return $true
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
                                                    Name                 = "SP_SocialDB"
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
                                                    Name                 = "SP_ProfileDB"
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
                                                    Name                 = "SP_ProfileSyncDB"
                                                    NormalizedDataSource = "SQL.domain.local"
                                                }
                                            } -PassThru
                                        )
                                    )
                                } -PassThru
                            } -PassThru -Force
                        )
                    }

                    Mock -CommandName Get-SPServiceApplicationProxyGroup -MockWith {
                        return @($proxyGroup)
                    }

                    Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                        $proxiesToReturn = @()
                        $proxy = @{
                            Name        = "UPS"
                            DisplayName = "UPS"
                        }
                        $proxiesToReturn += $proxy

                        return $proxiesToReturn
                    }
                }

                It "Should return false from the Get method" {
                    (Get-TargetResource @testParams).NoILMUsed | Should -Be $false
                }

                It "Should call Update method on Service Application before finishing set method" {
                    $Global:SPDscUPSAUpdateCalled = $false
                    Set-TargetResource @testParams
                    $Global:SPDscUPSAUpdateCalled | Should -Be $true
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should return true when the Test method is called" {
                    $testParams.NoILMUsed = $false
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "When service applications exist in the current farm and SiteNamingConflictResolution is incorrect" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                         = "User Profile Service App"
                        ApplicationPool              = "SharePoint Service Applications"
                        SiteNamingConflictResolution = "Username_CollisionDomain"
                        Ensure                       = "Present"
                        MySiteHostLocation           = "https://my.contoso.com"
                    }

                    Mock -CommandName Restart-Service -MockWith { }
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
                                $Global:SPDscUPSAUpdateCalled = $true
                            } -PassThru |
                            Add-Member -MemberType NoteProperty `
                                -Name ApplicationPool `
                                -Value @{
                                Name = $testParams.ApplicationPool
                            } -PassThru |
                            Add-Member -MemberType NoteProperty `
                                -Name ServiceApplicationProxyGroup `
                                -Value $proxyGroup `
                                -PassThru |
                            Add-Member -MemberType ScriptMethod `
                                -Name IsConnected `
                                -Value {
                                return $true
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
                                                    Name                 = "SP_SocialDB"
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
                                                    Name                 = "SP_ProfileDB"
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
                                                    Name                 = "SP_ProfileSyncDB"
                                                    NormalizedDataSource = "SQL.domain.local"
                                                }
                                            } -PassThru
                                        )
                                    )
                                } -PassThru
                            } -PassThru -Force
                        )
                    }

                    Mock -CommandName Get-SPServiceApplicationProxyGroup -MockWith {
                        return @($proxyGroup)
                    }

                    Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                        $proxiesToReturn = @()
                        $proxy = @{
                            Name        = "UPS"
                            DisplayName = "UPS"
                        }
                        $proxiesToReturn += $proxy

                        return $proxiesToReturn
                    }
                }

                It "Should return SiteNamingConflictResolution=Domain_Username from the Get method" {
                    (Get-TargetResource @testParams).SiteNamingConflictResolution | Should -Be "Domain_Username"
                }

                It "Should call Get-SPWebApplication before finishing set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Get-SPWebApplication
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "When service applications exist in the current farm and UpdateProxyGroup is True, so should update" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name               = "User Profile Service App"
                        ApplicationPool    = "SharePoint Service Applications"
                        UpdateProxyGroup   = $true
                        Ensure             = "Present"
                        MySiteHostLocation = "https://my.contoso.com"
                    }

                    $incorrectProxy = @{
                        DisplayName = "Incorrect"
                    }

                    $incorrectProxyGroup = @{
                        FriendlyName = "ProxyGroup2"
                        Name         = "ProxyGroup2"
                        Proxies      = @($incorrectProxy)
                    }

                    Mock -CommandName Restart-Service -MockWith { }
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
                                $Global:SPDscUPSAUpdateCalled = $true
                            } -PassThru |
                            Add-Member -MemberType NoteProperty `
                                -Name ApplicationPool `
                                -Value @{
                                Name = $testParams.ApplicationPool
                            } -PassThru |
                            Add-Member -MemberType NoteProperty `
                                -Name ServiceApplicationProxyGroup `
                                -Value $incorrectProxyGroup `
                                -PassThru |
                            Add-Member -MemberType ScriptMethod `
                                -Name IsConnected `
                                -Value {
                                return $true
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
                                                    Name                 = "SP_SocialDB"
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
                                                    Name                 = "SP_ProfileDB"
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
                                                    Name                 = "SP_ProfileSyncDB"
                                                    NormalizedDataSource = "SQL.domain.local"
                                                }
                                            } -PassThru
                                        )
                                    )
                                } -PassThru
                            } -PassThru -Force
                        )
                    }

                    Mock -CommandName Get-SPServiceApplicationProxyGroup -MockWith {
                        return @($proxyGroup)
                    }

                    Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                        $proxiesToReturn = @()
                        $proxy = @{
                            Name        = "UPS"
                            DisplayName = "UPS"
                        }
                        $proxiesToReturn += $proxy

                        return $proxiesToReturn
                    }
                }

                It "Should return UpdateProxyGroup=true from the Get method" {
                    (Get-TargetResource @testParams).UpdateProxyGroup | Should -Be $true
                }

                It "Should call Update method on Service Application before finishing set method" {
                    $Global:SPDscUPSAUpdateCalled = $false
                    Set-TargetResource @testParams
                    $Global:SPDscUPSAUpdateCalled | Should -Be $true
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "When service applications exist in the current farm and UpdateProxyGroup is False, so should not update" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name               = "User Profile Service App"
                        ApplicationPool    = "SharePoint Service Applications"
                        UpdateProxyGroup   = $false
                        Ensure             = "Present"
                        MySiteHostLocation = "https://my.contoso.com"
                    }

                    Mock -CommandName Restart-Service -MockWith { }
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
                                $Global:SPDscUPSAUpdateCalled = $true
                            } -PassThru |
                            Add-Member -MemberType NoteProperty `
                                -Name ApplicationPool `
                                -Value @{
                                Name = $testParams.ApplicationPool
                            } -PassThru |
                            Add-Member -MemberType NoteProperty `
                                -Name ServiceApplicationProxyGroup `
                                -Value $proxyGroup `
                                -PassThru |
                            Add-Member -MemberType ScriptMethod `
                                -Name IsConnected `
                                -Value {
                                return $true
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
                                                    Name                 = "SP_SocialDB"
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
                                                    Name                 = "SP_ProfileDB"
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
                                                    Name                 = "SP_ProfileSyncDB"
                                                    NormalizedDataSource = "SQL.domain.local"
                                                }
                                            } -PassThru
                                        )
                                    )
                                } -PassThru
                            } -PassThru -Force
                        )
                    }

                    $incorrectProxy = @{
                        DisplayName = "Incorrect"
                    }

                    $incorrectProxyGroup = @{
                        FriendlyName = "ProxyGroup"
                        Name         = "ProxyGroup"
                        Proxies      = @($incorrectProxy)
                    }

                    Mock -CommandName Get-SPServiceApplicationProxyGroup -MockWith {
                        return @($incorrectProxyGroup)
                    }

                    Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                        $proxiesToReturn = @()
                        $proxy = @{
                            Name        = "UPS"
                            DisplayName = "UPS"
                        }
                        $proxiesToReturn += $proxy

                        return $proxiesToReturn
                    }
                }

                It "Should return UpdateProxyGroup=true from the Get method" {
                    (Get-TargetResource @testParams).UpdateProxyGroup | Should -Be $true
                }

                It "Should return true when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "When a service application exists and is configured correctly" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name               = "User Profile Service App"
                        ApplicationPool    = "SharePoint Service Applications"
                        Ensure             = "Present"
                        MySiteHostLocation = "https://my.contoso.com"
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
                                $Global:SPDscUPSAUpdateCalled = $true
                            } -PassThru |
                            Add-Member -MemberType NoteProperty `
                                -Name ApplicationPool `
                                -Value @{
                                Name = $testParams.ApplicationPool
                            } -PassThru |
                            Add-Member -MemberType NoteProperty `
                                -Name ServiceApplicationProxyGroup `
                                -Value $proxyGroup `
                                -PassThru |
                            Add-Member -MemberType ScriptMethod `
                                -Name IsConnected `
                                -Value {
                                return $true
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
                                                    Name                 = "SP_SocialDB"
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
                                                    Name                 = "SP_ProfileDB"
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
                                                    Name                 = "SP_ProfileSyncDB"
                                                    NormalizedDataSource = "SQL.domain.local"
                                                }
                                            } -PassThru
                                        )
                                    )
                                } -PassThru
                            } -PassThru -Force
                        )
                    }

                    Mock -CommandName Get-SPServiceApplicationProxyGroup -MockWith {
                        return @($proxyGroup)
                    }

                    Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                        $proxiesToReturn = @()
                        $proxy = @{
                            Name        = "UPS"
                            DisplayName = "UPS"
                        }
                        $proxiesToReturn += $proxy

                        return $proxiesToReturn
                    }
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return true when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "When the service app exists but it shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name               = "Test App"
                        ApplicationPool    = "-"
                        Ensure             = "Absent"
                        MySiteHostLocation = "https://my.contoso.com"
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
                                $Global:SPDscUPSAUpdateCalled = $true
                            } -PassThru |
                            Add-Member -MemberType NoteProperty `
                                -Name ApplicationPool `
                                -Value @{
                                Name = $testParams.ApplicationPool
                            } -PassThru |
                            Add-Member -MemberType NoteProperty `
                                -Name ServiceApplicationProxyGroup `
                                -Value $proxyGroup `
                                -PassThru |
                            Add-Member -MemberType ScriptMethod `
                                -Name IsConnected `
                                -Value {
                                return $true
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
                                                    Name                 = "SP_SocialDB"
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
                                                    Name                 = "SP_ProfileDB"
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
                                                    Name                 = "SP_ProfileSyncDB"
                                                    NormalizedDataSource = "SQL.domain.local"
                                                }
                                            } -PassThru
                                        )
                                    )
                                } -PassThru
                            } -PassThru -Force
                        )
                    }

                    Mock -CommandName Get-SPServiceApplicationProxyGroup -MockWith {
                        return @($proxyGroup)
                    }

                    Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                        $proxiesToReturn = @()
                        $proxy = @{
                            Name        = "UPS"
                            DisplayName = "UPS"
                        }
                        $proxiesToReturn += $proxy

                        $proxiesToReturn = $proxiesToReturn | Add-Member -MemberType ScriptMethod `
                            -Name Delete `
                            -Value {
                            return $null
                        } -PassThru
                        return $proxiesToReturn
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

            Context -Name "When the service app doesn't exist and shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name               = "Test App"
                        ApplicationPool    = "-"
                        Ensure             = "Absent"
                        MySiteHostLocation = "https://my.contoso.com"
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
        }
    }
}
finally
{
    Invoke-TestCleanup
}
