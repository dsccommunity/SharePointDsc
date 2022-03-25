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
$script:DSCResourceName = 'SPFarmPropertyBag'
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
            Context -Name 'No local SharePoint farm was detected' {
                BeforeAll {
                    $testParams = @{
                        Key   = 'FARM_TYPE'
                        Value = 'SearchFarm'
                    }

                    Mock -CommandName Get-SPFarm -MockWith {
                        throw 'Unable to detect local farm'
                    }

                    $result = Get-TargetResource @testParams
                }

                It 'Should return absent from the get method' {
                    $result.Ensure | Should -Be 'absent'
                }

                It 'Should return the same values as passed as parameters' {
                    $result.Key | Should -Be $testParams.Key
                }

                It 'Should return null as the value used' {
                    $result.value | Should -Be $null
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It 'Should throw an exception in the set method to say there is no local farm' {
                    { Set-TargetResource @testParams } | Should -Throw "No local SharePoint farm was detected"
                }
            }

            Context -Name 'ParameterType is Boolean, but Value is not True or False' {
                BeforeAll {
                    $testParams = @{
                        Key           = 'Property'
                        Value         = 'String'
                        ParameterType = 'Boolean'
                    }

                }

                It 'Should throw exception from the get method' {
                    { Get-TargetResource @testParams } | Should -Throw 'Value can only be True or False when ParameterType is Boolean. Current value:'
                }

                It 'Should throw exception from the set method' {
                    { Set-TargetResource @testParams } | Should -Throw 'Value can only be True or False when ParameterType is Boolean. Current value:'
                }

                It 'Should throw exception from the test method' {
                    { Test-TargetResource @testParams } | Should -Throw 'Value can only be True or False when ParameterType is Boolean. Current value:'
                }
            }

            Context -Name 'ParameterType is Int32, but Value is not an integer' {
                BeforeAll {
                    $testParams = @{
                        Key           = 'Property'
                        Value         = 'String'
                        ParameterType = 'Int32'
                    }

                }

                It 'Should throw exception from the get method' {
                    { Get-TargetResource @testParams } | Should -Throw 'Value has to be a number when ParameterType is Int32. Current value:'
                }

                It 'Should throw exception from the set method' {
                    { Set-TargetResource @testParams } | Should -Throw 'Value has to be a number when ParameterType is Int32. Current value:'
                }

                It 'Should throw exception from the test method' {
                    { Test-TargetResource @testParams } | Should -Throw 'Value has to be a number when ParameterType is Int32. Current value:'
                }
            }

            Context -Name 'The farm property does not exist, but should be' -Fixture {
                BeforeAll {
                    $testParams = @{
                        Key   = 'FARM_TYPE'
                        Value = 'NewSearchFarm'
                    }

                    Mock -CommandName Get-SPFarm -MockWith {
                        $spFarm = [pscustomobject]@{
                            Properties = @{
                                FARM_TYPE = 'SearchFarm'
                            }
                        }
                        $spFarm = $spFarm | Add-Member ScriptMethod Update {
                            $Global:SPDscFarmPropertyUpdated = $true
                        } -PassThru
                        $spFarm = $spFarm | Add-Member ScriptMethod Remove {
                            $Global:SPDscFarmPropertyRemoved = $true
                        } -PassThru
                        return $spFarm
                    }

                    $result = Get-TargetResource @testParams
                }

                It 'Should return present from the get method' {
                    $result.Ensure | Should -Be 'present'
                }

                It 'Should return the same key value as passed as parameter' {
                    $result.Key | Should -Be $testParams.Key
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It 'Should not throw an exception in the set method' {
                    { Set-TargetResource @testParams } | Should -Not -Throw
                }

                $Global:SPDscFarmPropertyUpdated = $false
                It 'Calls Get-SPFarm and update farm property bag from the set method' {
                    Set-TargetResource @testParams

                    $Global:SPDscFarmPropertyUpdated | Should -Be $true
                }
            }

            Context -Name 'The farm property exists, and should be' -Fixture {
                BeforeAll {
                    $testParams = @{
                        Key    = 'FARM_TYPE'
                        Value  = 'SearchFarm'
                        Ensure = 'Present'
                    }

                    Mock -CommandName Get-SPFarm -MockWith {
                        $spFarm = [pscustomobject]@{
                            Properties = @{
                                FARM_TYPE = 'SearchFarm'
                            }
                        }
                        $spFarm = $spFarm | Add-Member ScriptMethod Update {
                            $Global:SPDscFarmPropertyUpdated = $true
                        } -PassThru
                        $spFarm = $spFarm | Add-Member ScriptMethod Remove {
                            $Global:SPDscFarmPropertyRemoved = $true
                        } -PassThru
                        return $spFarm
                    }

                    $result = Get-TargetResource @testParams
                }

                It 'Should return present from the get method' {
                    $result.Ensure | Should -Be 'present'
                }

                It 'Should return the same values as passed as parameters' {
                    $result.Key | Should -Be $testParams.Key
                    $result.value | Should -Be $testParams.value
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name 'The farm property exists, but with wrong type (Boolean)' -Fixture {
                BeforeAll {
                    $testParams = @{
                        Key           = 'FARM_TYPE'
                        Value         = '5'
                        ParameterType = "Int32"
                        Ensure        = 'Present'
                    }

                    Mock -CommandName Get-SPFarm -MockWith {
                        $spFarm = [pscustomobject]@{
                            Properties = @{
                                FARM_TYPE = $true
                            }
                        }
                        $spFarm = $spFarm | Add-Member ScriptMethod Update {
                            $Global:SPDscFarmPropertyUpdated = $true
                        } -PassThru
                        $spFarm = $spFarm | Add-Member ScriptMethod Remove {
                            $Global:SPDscFarmPropertyRemoved = $true
                        } -PassThru
                        return $spFarm
                    }
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be 'present'
                    $result.Key | Should -Be $testParams.Key
                    $result.Value | Should -Be 'True'
                    $result.ParameterType | Should -Be 'Boolean'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParams | Should -Be $false
                }

                $Global:SPDscFarmPropertyUpdated = $false
                It 'Calls Get-SPFarm and updates farm property bag from the set method' {
                    Set-TargetResource @testParams

                    $Global:SPDscFarmPropertyUpdated | Should -Be $true
                }
            }

            Context -Name 'The farm property exists, but with wrong type (Boolean)' -Fixture {
                BeforeAll {
                    $testParams = @{
                        Key           = 'FARM_TYPE'
                        Value         = 'False'
                        ParameterType = "Boolean"
                        Ensure        = 'Present'
                    }

                    Mock -CommandName Get-SPFarm -MockWith {
                        $spFarm = [pscustomobject]@{
                            Properties = @{
                                FARM_TYPE = 5
                            }
                        }
                        $spFarm = $spFarm | Add-Member ScriptMethod Update {
                            $Global:SPDscFarmPropertyUpdated = $true
                        } -PassThru
                        $spFarm = $spFarm | Add-Member ScriptMethod Remove {
                            $Global:SPDscFarmPropertyRemoved = $true
                        } -PassThru
                        return $spFarm
                    }
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be 'present'
                    $result.Key | Should -Be $testParams.Key
                    $result.Value | Should -Be '5'
                    $result.ParameterType | Should -Be 'Int32'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParams | Should -Be $false
                }

                $Global:SPDscFarmPropertyUpdated = $false
                It 'Calls Get-SPFarm and updates farm property bag from the set method' {
                    Set-TargetResource @testParams

                    $Global:SPDscFarmPropertyUpdated | Should -Be $true
                }
            }

            Context -Name 'The farm property does not exist, and should not be' -Fixture {
                BeforeAll {
                    $testParams = @{
                        Key    = 'FARM_TYPED'
                        Ensure = 'Absent'
                    }

                    Mock -CommandName Get-SPFarm -MockWith {
                        $spFarm = [pscustomobject]@{
                            Properties = @{
                                FARM_TYPE = 'SearchFarm'
                            }
                        }
                        $spFarm = $spFarm | Add-Member ScriptMethod Update {
                            $Global:SPDscFarmPropertyUpdated = $true
                        } -PassThru
                        $spFarm = $spFarm | Add-Member ScriptMethod Remove {
                            $Global:SPDscFarmPropertyRemoved = $true
                        } -PassThru
                        return $spFarm
                    }

                    $result = Get-TargetResource @testParams
                }

                It 'Should return absent from the get method' {
                    $result.Ensure | Should -Be 'absent'
                }

                It 'Should return the same values as passed as parameters' {
                    $result.Key | Should -Be $testParams.Key
                    $result.value | Should -Be $testParams.value
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name 'The farm property exists, but should not be' -Fixture {
                BeforeAll {
                    $testParams = @{
                        Key    = 'FARM_TYPE'
                        Value  = 'SearchFarm'
                        Ensure = 'Absent'
                    }

                    Mock -CommandName Get-SPFarm -MockWith {
                        $spFarm = [pscustomobject]@{
                            Properties = @{
                                FARM_TYPE = 5
                            }
                        }
                        $spFarm = $spFarm | Add-Member ScriptMethod Update {
                            $Global:SPDscFarmPropertyUpdated = $true
                        } -PassThru
                        $spFarm = $spFarm | Add-Member ScriptMethod Remove {
                            $Global:SPDscFarmPropertyRemoved = $true
                        } -PassThru
                        return $spFarm
                    }

                    $result = Get-TargetResource @testParams
                }

                It 'Should return Present from the get method' {
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return the same values as passed as parameters' {
                    $result.Key | Should -Be $testParams.Key
                    $result.Value | Should -Be '5'
                    $result.ParameterType | Should -Be 'Int32'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It 'Should not throw an exception in the set method' {
                    { Set-TargetResource @testParams } | Should -Not -Throw
                }

                $Global:SPDscFarmPropertyUpdated = $false
                It 'Calls Get-SPFarm and remove farm property bag from the set method' {
                    Set-TargetResource @testParams

                    $Global:SPDscFarmPropertyUpdated | Should -Be $true
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")

                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Key           = "Key"
                            Value         = "Value"
                            ParameterType = "String"
                            Ensure        = "Present"
                        }
                    }

                    Mock -CommandName Get-SPFarm -MockWith {
                        $spFarm = @{
                            Properties = @{
                                Key = "Value"
                            }
                        }
                        return $spFarm
                    }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        SPFarmPropertyBag [0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            Ensure               = "Present";
            Key                  = "Key";
            ParameterType        = "String";
            PsDscRunAsCredential = \$Credsspfarm;
            Value                = "Value";
        }

'@
                }

                It "Should return valid DSC block from the Export method" {
                    Export-TargetResource | Should -Match $result
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
