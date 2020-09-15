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
$script:DSCResourceName = 'SPVisioServiceApp'
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

            # Initialize Tests
            $getTypeFullName = "Microsoft.Office.Visio.Server.Administration.VisioGraphicsServiceApplication"

            # Mocks for all contexts
            Mock -CommandName New-SPVisioServiceApplication -MockWith { }
            Mock -CommandName Remove-SPServiceApplication -MockWith { }
            Mock -CommandName New-SPVisioServiceApplicationProxy -MockWith { }

            # Test contexts
            Context -Name "When no service applications exist in the current farm" -Fixture {
                $testParams = @{
                    Name            = "Test Visio App"
                    ProxyName       = "Visio Proxy"
                    ApplicationPool = "Test App Pool"
                    Ensure          = "Present"
                }

                Mock -CommandName Get-SPServiceApplication -MockWith {
                    return $null
                }

                It "Should return absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create a new service application in the set method" {
                    Set-TargetResource @testParams
                }
            }

            Context -Name "When service applications exist in the current farm but the specific Visio Graphics app does not" -Fixture {
                $testParams = @{
                    Name            = "Test Visio App"
                    ApplicationPool = "Test App Pool"
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
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }
            }

            Context -Name "When a service application exists and is configured correctly" -Fixture {
                $testParams = @{
                    Name            = "Test Visio App"
                    ProxyName       = "Visio Proxy"
                    ApplicationPool = "Test App Pool"
                    Ensure          = "Present"
                }

                Mock -CommandName Get-SPServiceApplication -MockWith {
                    $spServiceApp = [PSCustomObject]@{
                        TypeName        = "Visio Graphics Service Application"
                        DisplayName     = $testParams.Name
                        ApplicationPool = @{ Name = $testParams.ApplicationPool }
                    }
                    $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                        return @{ FullName = $getTypeFullName }
                    } -PassThru -Force
                    $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name IsConnected -Value {
                        return $true
                    } -PassThru -Force
                    return $spServiceApp
                }
                Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                    $proxiesToReturn = @()
                    $proxy = @{
                        Name        = $testParams.ProxyName
                        DisplayName = $testParams.ProxyName
                    }
                    $proxy = $proxy | Add-Member -MemberType ScriptMethod `
                        -Name Delete `
                        -Value { } `
                        -PassThru
                    $proxiesToReturn += $proxy

                    return $proxiesToReturn
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return true when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "When a service application exists and is not configured correctly" -Fixture {
                $testParams = @{
                    Name            = "Test Visio App"
                    ApplicationPool = "Test App Pool"
                    Ensure          = "Present"
                }

                Mock -CommandName Get-SPServiceApplication -MockWith {
                    $spServiceApp = [PSCustomObject]@{
                        TypeName        = "Visio Graphics Service Application"
                        DisplayName     = $testParams.Name
                        ApplicationPool = @{ Name = "Wrong App Pool Name" }
                    }
                    $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                        return @{ FullName = $getTypeFullName }
                    } -PassThru -Force
                    return $spServiceApp
                }
                Mock -CommandName Get-SPServiceApplicationPool {
                    return @{
                        Name = $testParams.ApplicationPool
                    }
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should call the update service app cmdlet from the set method" {
                    Set-TargetResource @testParams

                    Assert-MockCalled Get-SPServiceApplicationPool
                }
            }

            Context -Name "When the service app exists but it shouldn't" -Fixture {
                $testParams = @{
                    Name            = "Test App"
                    ApplicationPool = "-"
                    Ensure          = "Absent"
                }

                Mock -CommandName Get-SPServiceApplication -MockWith {
                    $spServiceApp = [PSCustomObject]@{
                        TypeName        = "Visio Graphics Service Application"
                        DisplayName     = $testParams.Name
                        ApplicationPool = @{ Name = $testParams.ApplicationPool }
                    }
                    $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                        return @{ FullName = $getTypeFullName }
                    } -PassThru -Force
                    return $spServiceApp
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
                $testParams = @{
                    Name            = "Test App"
                    ApplicationPool = "-"
                    Ensure          = "Absent"
                }

                Mock -CommandName Get-SPServiceApplication -MockWith {
                    return $null
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
