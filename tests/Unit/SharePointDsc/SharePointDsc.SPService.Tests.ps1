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
$script:DSCResourceName = 'SPService'
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

                # Mocks for all contexts
                Mock -CommandName Start-Sleep -MockWith {}

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
            switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major)
            {
                15
                {
                    Context -Name "All methods throw exceptions as MinRole doesn't exist in 2013" -Fixture {
                        $testParams = @{
                            Name   = "Microsoft SharePoint Foundation Sandboxed Code Service"
                            Ensure = "Present"
                        }

                        It "Should throw on the get method" {
                            { Get-TargetResource @testParams } | Should -Throw "This resource is only supported on SharePoint 2016 and later. SharePoint 2013 does not support MinRole."
                        }

                        It "Should throw on the test method" {
                            { Test-TargetResource @testParams } | Should -Throw "This resource is only supported on SharePoint 2016 and later. SharePoint 2013 does not support MinRole."
                        }

                        It "Should throw on the set method" {
                            { Set-TargetResource @testParams } | Should -Throw "This resource is only supported on SharePoint 2016 and later. SharePoint 2013 does not support MinRole."
                        }
                    }
                }
                16
                {
                    Context -Name "The service instance is not running but should be" -Fixture {
                        BeforeAll {
                            $testParams = @{
                                Name   = "Microsoft SharePoint Foundation Sandboxed Code Service"
                                Ensure = "Present"
                            }

                            Mock -CommandName Start-SPService -MockWith { }
                            Mock -CommandName Stop-SPService -MockWith { }

                            Mock -CommandName Get-SPService -MockWith {
                                return @{
                                    AutoProvision = $false
                                }
                            }
                        }

                        It "Should return absent from the get method" {
                            (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                        }

                        It "Should return false from the set method" {
                            Test-TargetResource @testParams | Should -Be $false
                        }

                        It "Should call the start service call from the set method" {
                            Set-TargetResource @testParams
                            Assert-MockCalled Start-SPService
                        }
                    }

                    Context -Name "The service is running and should be" -Fixture {
                        BeforeAll {
                            $testParams = @{
                                Name   = "Microsoft SharePoint Foundation Sandboxed Code Service"
                                Ensure = "Present"
                            }

                            Mock -CommandName Start-SPService -MockWith { }
                            Mock -CommandName Stop-SPService -MockWith { }

                            Mock -CommandName Get-SPService -MockWith {
                                return @{
                                    AutoProvision = $true
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

                    Context -Name "An invalid service is specified to start" -Fixture {
                        BeforeAll {
                            $testParams = @{
                                Name   = "Does not exist"
                                Ensure = "Present"
                            }

                            Mock -CommandName Get-SPServiceInstance {
                                return $null
                            }
                        }

                        It "Should throw when the set method is called" {
                            { Set-TargetResource @testParams } | Should -Throw "Specified service does not exist '$($testParams.Name)'"
                        }
                    }

                    Context -Name "The service is not running and should not be" -Fixture {
                        BeforeAll {
                            $testParams = @{
                                Name   = "Microsoft SharePoint Foundation Sandboxed Code Service"
                                Ensure = "Absent"
                            }

                            Mock -CommandName Start-SPService -MockWith { }
                            Mock -CommandName Stop-SPService -MockWith { }

                            Mock -CommandName Get-SPService -MockWith {
                                return @{
                                    AutoProvision = $false
                                }
                            }
                        }

                        It "Should return absent from the get method" {
                            (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                        }

                        It "Should return true from the test method" {
                            Test-TargetResource @testParams | Should -Be $true
                        }
                    }

                    Context -Name "The service instance is running and should not be" -Fixture {
                        BeforeAll {
                            $testParams = @{
                                Name   = "Microsoft SharePoint Foundation Sandboxed Code Service"
                                Ensure = "Absent"
                            }

                            Mock -CommandName Start-SPService -MockWith { }
                            Mock -CommandName Stop-SPService -MockWith { }

                            Mock -CommandName Get-SPService -MockWith {
                                return @{
                                    AutoProvision = $true
                                }
                            }
                        }

                        It "Should return present from the get method" {
                            (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                        }

                        It "Should return false from the set method" {
                            Test-TargetResource @testParams | Should -Be $false
                        }

                        It "Should call the stop service call from the set method" {
                            Set-TargetResource @testParams
                            Assert-MockCalled Stop-SPService
                        }
                    }

                    Context -Name "An invalid service application is specified to stop" -Fixture {
                        BeforeAll {
                            $testParams = @{
                                Name   = "Microsoft SharePoint Foundation Sandboxed Code Service"
                                Ensure = "Absent"
                            }

                            Mock -CommandName Get-SPServiceInstance {
                                return $null
                            }
                        }

                        It "Should throw when the set method is called" {
                            { Set-TargetResource @testParams } | Should -Throw "Specified service does not exist '$($testParams.Name)'"
                        }
                    }

                    Context -Name "Running ReverseDsc Export" -Fixture {
                        BeforeAll {
                            Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")

                            Mock -CommandName Write-Host -MockWith { }

                            Mock -CommandName Get-SPService -MockWith {
                                return @(
                                    @{
                                        TypeName      = "Microsoft SharePoint Foundation Sandboxed Code Service"
                                        AutoProvision = $true
                                    }
                                )
                            }

                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    Name   = "Microsoft SharePoint Foundation Sandboxed Code Service"
                                    Ensure = "Present"
                                }
                            }

                            if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                            {
                                $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                                $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                            }

                            if ($null -eq (Get-Variable -Name 'DynamicCompilation' -ErrorAction SilentlyContinue))
                            {
                                $DynamicCompilation = $false
                            }

                            if ($null -eq (Get-Variable -Name 'StandAlone' -ErrorAction SilentlyContinue))
                            {
                                $StandAlone = $true
                            }

                            if ($null -eq (Get-Variable -Name 'ExtractionModeValue' -ErrorAction SilentlyContinue))
                            {
                                $Global:ExtractionModeValue = 2
                                $Global:ComponentsToExtract = @('SPFarm')
                            }

                            $result = @'
        SPService Service_MicrosoftSharePointFoundationSandboxedCodeService
        {
            Ensure               = "Present";
            Name                 = "Microsoft SharePoint Foundation Sandboxed Code Service";
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
    }
}
finally
{
    Invoke-TestCleanup
}
