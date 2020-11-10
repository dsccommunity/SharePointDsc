# Ignoring this because we need to generate a stub credential to run the tests here
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
[CmdletBinding()]
param
(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
            -Resolve)
)

#region HEADER
$script:projectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$script:projectName = (Get-ChildItem -Path "$script:projectPath\*\*.psd1" | Where-Object -FilterScript {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try
            { Test-ModuleManifest -Path $_.FullName -ErrorAction Stop
            }
            catch
            { $false
            })
    }).BaseName

$script:parentModule = Get-Module -Name $script:projectName -ListAvailable | Select-Object -First 1
$script:subModulesFolder = Join-Path -Path $script:parentModule.ModuleBase -ChildPath 'Modules'
Remove-Module -Name $script:parentModule -Force -ErrorAction 'SilentlyContinue'

$script:subModuleName = (Split-Path -Path $PSCommandPath -Leaf) -replace '\.Tests.ps1'
$script:subModuleFile = Join-Path -Path $script:subModulesFolder -ChildPath "$($script:subModuleName)\SPFarm.psm1"

Import-Module $script:subModuleFile -Force -ErrorAction Stop
#endregion HEADER

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force

        Import-Module -Name (Join-Path -Path $PSScriptRoot `
                -ChildPath "..\UnitTestHelper.psm1" `
                -Resolve)

        $moduleVersionFolder = ($ModuleVersion -split "-")[0]

        $Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
            -SubModulePath "Modules\SharePointDsc.Farm\SPFarm.psm1" `
            -ExcludeInvokeHelper `
            -ModuleVersion $moduleVersionFolder
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }
}

function Invoke-TestCleanup
{
}

Invoke-TestSetup

try
{
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
            BeforeAll {
                Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope
            }

            Context -Name "Validate Get-SPDscConfigDBStatus" -Fixture {
                BeforeAll {
                    Mock -CommandName New-Object -MockWith {
                        $returnval = @{
                            ConnectionString = ''
                            State            = 'Open'
                        }

                        $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                            -Name Open `
                            -Value {
                        } -PassThru -Force

                        $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                            -Name ChangeDatabase `
                            -Value {
                        } -PassThru -Force

                        $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                            -Name Close `
                            -Value {
                        } -PassThru -Force

                        $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                            -Name Dispose `
                            -Value {
                        } -PassThru -Force

                        return $returnval
                    } -ParameterFilter {
                        $TypeName -eq "System.Data.SqlClient.SqlConnection"
                    }
                }

                It "Should return ValidPermissions=False" {
                    Mock -CommandName New-Object -MockWith {
                        $returnval = @{
                            Connection = ''
                        }

                        $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                            -name ExecuteScalar `
                            -Value {
                            $global:RunQuery++
                            switch ($global:RunQuery)
                            {
                                1 # ConfigDB exists
                                { return 1
                                }
                                2 # Check permissions
                                { return "0"
                                }
                                3 # Check permissions
                                { return "1"
                                }
                                4 # Database empty
                                { return 20
                                }
                                5 # Locked
                                { return 0
                                }
                            }
                        } -PassThru -Force

                        return $returnval
                    } -ParameterFilter {
                        $TypeName -eq "System.Data.SqlClient.SqlCommand"
                    }

                    $global:RunQuery = 0
                    $result = Get-SPDscConfigDBStatus -SQLServer 'sql01' -Database 'SP_Config'
                    $result.DatabaseExists | Should -Be $true
                    $result.DatabaseEmpty | Should -Be $false
                    $result.ValidPermissions | Should -Be $false
                    $result.Locked | Should -Be $false
                }

                It "Should return DatabaseEmpty=False" {
                    Mock -CommandName New-Object -MockWith {
                        $returnval = @{
                            Connection = ''
                        }

                        $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                            -name ExecuteScalar `
                            -Value {
                            $global:RunQuery++
                            switch ($global:RunQuery)
                            {
                                1 # ConfigDB exists
                                { return 1
                                }
                                2 # Check permissions
                                { return "1"
                                }
                                3 # Check permissions
                                { return "1"
                                }
                                4 # Database empty
                                { return 20
                                }
                                5 # Locked
                                { return 0
                                }
                            }
                        } -PassThru -Force

                        return $returnval
                    } -ParameterFilter {
                        $TypeName -eq "System.Data.SqlClient.SqlCommand"
                    }

                    $global:RunQuery = 0
                    $result = Get-SPDscConfigDBStatus -SQLServer 'sql01' -Database 'SP_Config'
                    $result.DatabaseExists | Should -Be $true
                    $result.DatabaseEmpty | Should -Be $false
                    $result.ValidPermissions | Should -Be $true
                    $result.Locked | Should -Be $false
                }

                It "Should return DatabaseExists=True" {
                    Mock -CommandName New-Object -MockWith {
                        $returnval = @{
                            Connection = ''
                        }

                        $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                            -name ExecuteScalar `
                            -Value {
                            $global:RunQuery++
                            switch ($global:RunQuery)
                            {
                                1 # ConfigDB exists
                                { return 1
                                }
                                2 # Check permissions
                                { return "1"
                                }
                                3 # Check permissions
                                { return "1"
                                }
                                4 # Database empty
                                { return 0
                                }
                                5 # Locked
                                { return 0
                                }
                            }
                        } -PassThru -Force

                        return $returnval
                    } -ParameterFilter {
                        $TypeName -eq "System.Data.SqlClient.SqlCommand"
                    }

                    $global:RunQuery = 0
                    $result = Get-SPDscConfigDBStatus -SQLServer 'sql01' -Database 'SP_Config'
                    $result.DatabaseExists | Should -Be $true
                    $result.DatabaseEmpty | Should -Be $true
                    $result.ValidPermissions | Should -Be $true
                    $result.Locked | Should -Be $false
                }

                It "Should return DatabaseExists=False, ValidPermissions=True, DatabaseEmpty=False and Locked=False" {
                    Mock -CommandName New-Object -MockWith {
                        $returnval = @{
                            Connection = ''
                        }

                        $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                            -name ExecuteScalar `
                            -Value {
                            $global:RunQuery++
                            switch ($global:RunQuery)
                            {
                                1 # ConfigDB exists
                                { return 0
                                }
                                2 # Check permissions
                                { return "1"
                                }
                                3 # Check permissions
                                { return "1"
                                }
                                4 # Locked
                                { return 0
                                }
                            }
                        } -PassThru -Force

                        return $returnval
                    } -ParameterFilter {
                        $TypeName -eq "System.Data.SqlClient.SqlCommand"
                    }

                    $global:RunQuery = 0
                    $result = Get-SPDscConfigDBStatus -SQLServer 'sql01' -Database 'SP_Config'
                    $result.DatabaseExists | Should -Be $false
                    $result.DatabaseEmpty | Should -Be $false
                    $result.ValidPermissions | Should -Be $true
                    $result.Locked | Should -Be $false
                }
            }

            Context -Name "Validate Get-SPDscSQLInstanceStatus" -Fixture {
                BeforeAll {
                    Mock -CommandName New-Object -MockWith {
                        $returnval = @{
                            ConnectionString = ''
                            State            = 'Open'
                        }

                        $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                            -Name Open `
                            -Value {
                        } -PassThru -Force

                        $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                            -Name Close `
                            -Value {
                        } -PassThru -Force

                        $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                            -Name Dispose `
                            -Value {
                        } -PassThru -Force

                        return $returnval
                    } -ParameterFilter {
                        $TypeName -eq "System.Data.SqlClient.SqlConnection"
                    }
                }

                It "Should return MaxDopCorrect=True" {
                    Mock -CommandName New-Object -MockWith {
                        $returnval = @{
                            Connection = ''
                        }

                        $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                            -name ExecuteScalar `
                            -Value {
                            return 1
                        } -PassThru -Force

                        return $returnval
                    } -ParameterFilter {
                        $TypeName -eq "System.Data.SqlClient.SqlCommand"
                    }

                    $result = Get-SPDscSQLInstanceStatus -SQLServer 'sql01'
                    $result.MaxDOPCorrect | Should -Be $true
                }

                It "Should return MaxDopCorrect=False" {
                    Mock -CommandName New-Object -MockWith {
                        $returnval = @{
                            Connection = ''
                        }

                        $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                            -name ExecuteScalar `
                            -Value {
                            return 0
                        } -PassThru -Force

                        return $returnval
                    } -ParameterFilter {
                        $TypeName -eq "System.Data.SqlClient.SqlCommand"
                    }

                    $result = Get-SPDscSQLInstanceStatus -SQLServer 'sql01'
                    $result.MaxDOPCorrect | Should -Be $false
                }
            }

            Context -Name "Validate Add-SPDscConfigDBLock" -Fixture {
                BeforeAll {
                    Mock -CommandName New-Object -MockWith {
                        $returnval = @{
                            ConnectionString = ''
                            State            = 'Open'
                        }

                        $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                            -Name Open `
                            -Value {
                        } -PassThru -Force

                        $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                            -Name Close `
                            -Value {
                        } -PassThru -Force

                        $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                            -Name Dispose `
                            -Value {
                        } -PassThru -Force

                        return $returnval
                    } -ParameterFilter {
                        $TypeName -eq "System.Data.SqlClient.SqlConnection"
                    }
                }

                It "Should run query to create TempDB Lock table" {
                    Mock -CommandName New-Object -MockWith {
                        $returnval = @{
                            Connection = ''
                        }

                        $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                            -name ExecuteNonQuery `
                            -Value {
                            $global:ExecutedQuery = $true
                        } -PassThru -Force

                        return $returnval
                    } -ParameterFilter {
                        $TypeName -eq "System.Data.SqlClient.SqlCommand"
                    }

                    $global:ExecutedQuery = $false
                    $result = Add-SPDscConfigDBLock -SQLServer 'sql01' -Database 'SP_Config'
                    $global:ExecutedQuery | Should -Be $true
                }
            }

            Context -Name "Validate Remove-SPDscConfigDBLock" -Fixture {
                BeforeAll {
                    Mock -CommandName New-Object -MockWith {
                        $returnval = @{
                            ConnectionString = ''
                            State            = 'Open'
                        }

                        $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                            -Name Open `
                            -Value {
                        } -PassThru -Force

                        $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                            -Name Close `
                            -Value {
                        } -PassThru -Force

                        $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                            -Name Dispose `
                            -Value {
                        } -PassThru -Force

                        return $returnval
                    } -ParameterFilter {
                        $TypeName -eq "System.Data.SqlClient.SqlConnection"
                    }
                }

                It "Should run query to create TempDB Lock table" {
                    Mock -CommandName New-Object -MockWith {
                        $returnval = @{
                            Connection = ''
                        }

                        $returnval = $returnval | Add-Member -MemberType ScriptMethod `
                            -name ExecuteNonQuery `
                            -Value {
                            $global:ExecutedQuery = $true
                        } -PassThru -Force

                        return $returnval
                    } -ParameterFilter {
                        $TypeName -eq "System.Data.SqlClient.SqlCommand"
                    }

                    $global:ExecutedQuery = $false
                    $result = Remove-SPDscConfigDBLock -SQLServer 'sql01' -Database 'SP_Config'
                    $global:ExecutedQuery | Should -Be $true
                }
            }
        }
    }
}
finally
{
}
