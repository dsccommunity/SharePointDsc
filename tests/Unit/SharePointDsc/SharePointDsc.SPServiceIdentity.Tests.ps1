[CmdletBinding()]
param
(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
            -Resolve)
)

$script:DSCModuleName = 'SharePointDsc'
$script:DSCResourceName = 'SPServiceIdentity'
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
    Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
        InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
            Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

            #Initialize tests
            Add-Type -TypeDefinition @"
        namespace Microsoft.SharePoint.Administration
        {
            public class IdentityType
            {
                public string SpecificUser { get; set; }
            }
        }
"@


            # Mocks for all contexts
            Mock -CommandName Get-SPManagedAccount -MockWith {
                return "CONTOSO\svc.c2wts"
            }

            # Test contexts
            Context -Name "Service is set to use the specified identity" -Fixture {

                $testParams = @{
                    Name           = "Claims to Windows Token Service"
                    ManagedAccount = "CONTOSO\svc.c2wts"
                }

                Mock -CommandName Get-SPServiceInstance -MockWith {
                    $ProcessIdentity = @{
                        username = $testParams.ManagedAccount
                    }

                    $ProcessIdentity = $ProcessIdentity | Add-Member -MemberType ScriptMethod -Name Update -Value {
                        $Global:SPDscSPServiceInstanceUpdateCalled = $true
                    } -PassThru

                    $ProcessIdentity = $ProcessIdentity | Add-Member -MemberType ScriptMethod -Name Deploy -Value {
                    } -PassThru

                    $ServiceIdentity = @{
                        TypeName = $testParams.Name
                        Service  = @{
                            processidentity = $ProcessIdentity
                        }
                    }

                    return $ServiceIdentity
                }

                It "Should return the current identity from the get method" {
                    (Get-TargetResource @testParams).ManagedAccount | Should Not BeNullOrEmpty

                }

                It "Should return true for the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }

            Context -Name "Service is not set to use the specified identity" -Fixture {
                $testParams = @{
                    Name           = "Claims to Windows Token Service"
                    ManagedAccount = "CONTOSO\svc.c2wts"
                }

                Mock -CommandName Get-SPServiceInstance -MockWith {
                    $ProcessIdentity = @{
                        username = "NT AUTHORITY\SYSTEM"
                    }

                    $ProcessIdentity = $ProcessIdentity | Add-Member -MemberType ScriptMethod -Name Update -Value {
                        $Global:SPDscSPServiceInstanceUpdateCalled = $true
                    } -PassThru

                    $ProcessIdentity = $ProcessIdentity | Add-Member -MemberType ScriptMethod -Name Deploy -Value {
                    } -PassThru

                    $ServiceIdentity = @{
                        TypeName = $testParams.Name
                        Service  = @{
                            processidentity = $ProcessIdentity
                        }
                    }

                    return $ServiceIdentity
                }

                It "Should return the current identity from the get method" {
                    (Get-TargetResource @testParams).ManagedAccount | Should Not BeNullOrEmpty
                }

                It "Should return false for the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                $Global:SPDscSPServiceInstanceUpdateCalled = $false
                It "Should call the SPServiceInstance update method" {
                    Set-TargetResource @testParams
                    $Global:SPDscSPServiceInstanceUpdateCalled | Should Be $true
                }
            }

            Context -Name "Search Service is not set to use the specified identity" -Fixture {
                $testParams = @{
                    Name           = "SharePoint Server Search"
                    ManagedAccount = "CONTOSO\svc.search"
                }

                Mock -CommandName Get-SPEnterpriseSearchService -MockWith {
                    $EnterpriseSearchService = @{ }

                    $EnterpriseSearchService = $EnterpriseSearchService | Add-Member -MemberType ScriptMethod -Name get_ProcessIdentity -Value {
                        $ProcessIdentity = @{
                            CurrentIdentityType = "account"
                            Username            = "CONTOSO\wrong_account"
                        }

                        $ProcessIdentity = $ProcessIdentity | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscSPServiceInstanceUpdateCalled = $true
                        } -PassThru

                        $ProcessIdentity = $ProcessIdentity | Add-Member -MemberType ScriptMethod -Name Deploy -Value {
                        } -PassThru

                        return $ProcessIdentity
                    } -PassThru

                    return $EnterpriseSearchService
                }

                It "Should return the current identity from the get method" {
                    (Get-TargetResource @testParams).ManagedAccount | Should Not BeNullOrEmpty
                }

                It "Should return false for the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                $Global:SPDscSPServiceInstanceUpdateCalled = $false
                It "Should call the SPServiceInstance update method" {
                    Set-TargetResource @testParams
                    $Global:SPDscSPServiceInstanceUpdateCalled | Should Be $true
                }
            }

            Context -Name "Search Service is not set to use the LocalSystem" -Fixture {
                $testParams = @{
                    Name           = "SharePoint Server Search"
                    ManagedAccount = "LocalSystem"
                }

                Mock -CommandName Get-SPEnterpriseSearchService -MockWith {
                    $EnterpriseSearchService = @{ }

                    $EnterpriseSearchService = $EnterpriseSearchService | Add-Member -MemberType ScriptMethod -Name get_ProcessIdentity -Value {
                        $ProcessIdentity = @{
                            CurrentIdentityType = "LocalService"
                            Username            = "CONTOSO\wrong_account"
                        }

                        $ProcessIdentity = $ProcessIdentity | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPDscSPServiceInstanceUpdateCalled = $true
                        } -PassThru

                        $ProcessIdentity = $ProcessIdentity | Add-Member -MemberType ScriptMethod -Name Deploy -Value {
                        } -PassThru

                        return $ProcessIdentity
                    } -PassThru

                    return $EnterpriseSearchService
                }

                It "Should return the current identity from the get method" {
                    (Get-TargetResource @testParams).ManagedAccount | Should Not BeNullOrEmpty
                }

                It "Should return false for the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                $Global:SPDscSPServiceInstanceUpdateCalled = $false
                It "Should call the SPServiceInstance update method" {
                    Set-TargetResource @testParams
                    $Global:SPDscSPServiceInstanceUpdateCalled | Should Be $true
                }
            }

            Context -Name "Invalid Service Specified" -Fixture {

                $testParams = @{
                    Name           = "No Such Windows Token Service"
                    ManagedAccount = "CONTOSO\svc.c2wts"
                }

                Mock -CommandName Get-SPServiceInstance -MockWith {
                    return $null
                }

                It "Should return null from the get method" {
                    (Get-TargetResource @testParams).ManagedAccount | Should BeNullOrEmpty

                }

                It "Should return false for the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "Should throw an error for the set method" {
                    { Set-TargetResource @testParams } | Should throw "Unable to locate service $($testParams.name)"
                }
            }

            Context -Name "Invalid managed account specified" -Fixture {

                $testParams = @{
                    Name           = "Claims to Windows Token Service"
                    ManagedAccount = "CONTOSO\svc.badAccount"
                }

                Mock -CommandName Get-SPManagedAccount -MockWith {
                    return $null
                }

                Mock -CommandName Get-SPServiceInstance -MockWith {
                    $ProcessIdentity = @{
                        username = "CONTOSO\svc.c2wts"
                    }

                    $ProcessIdentity = $ProcessIdentity | Add-Member -MemberType ScriptMethod -Name Update -Value {
                        $Global:SPDscSPServiceInstanceUpdateCalled = $true
                    } -PassThru

                    $ProcessIdentity = $ProcessIdentity | Add-Member -MemberType ScriptMethod -Name Deploy -Value {
                    } -PassThru

                    $ServiceIdentity = @{
                        TypeName = $testParams.Name
                        Service  = @{
                            processidentity = $ProcessIdentity
                        }
                    }

                    return $ServiceIdentity
                }

                It "Should return the current identity from the get method" {
                    (Get-TargetResource @testParams).ManagedAccount | Should Not BeNullOrEmpty

                }

                It "Should return false for the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "Should throw an error for the set method" {
                    { Set-TargetResource @testParams } | Should throw "Unable to locate Managed Account $($testParams.ManagedAccount)"
                }
            }

            Context -Name "Service does not support setting process identity" -Fixture {

                $testParams = @{
                    Name           = "Machine Translation Service"
                    ManagedAccount = "CONTOSO\svc.mts"
                }

                Mock -CommandName Get-SPManagedAccount -MockWith {
                    return $null
                }

                Mock -CommandName Get-SPServiceInstance -MockWith {
                    $ServiceIdentity = @{
                        TypeName = $testParams.Name
                        Service  = @{
                            TypeName = $testParams.Name
                        }
                    }

                    return $ServiceIdentity
                }

                It "Should return null for the current identity from the get method" {
                    (Get-TargetResource @testParams).ManagedAccount | Should BeNullOrEmpty
                }

                It "Should return false for the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "Should throw an error for the set method" {
                    Mock -CommandName Get-SPManagedAccount -MockWith {
                        return "CONTOSO\svc.mts"
                    }
                    { Set-TargetResource @testParams } | Should throw "Service $($testParams.name) does not support setting the process identity"
                }
            }
        }

    }
}
finally
{
    Invoke-TestCleanup
}
