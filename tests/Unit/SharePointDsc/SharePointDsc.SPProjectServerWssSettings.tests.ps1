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
$script:DSCResourceName = 'SPProjectServerWssSettings'
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

                if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 16)
                {
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

                    $modulePath = Join-Path -Path $script:subModulesFolder -ChildPath "SharePointDsc.ProjectServerConnector\SharePointDsc.ProjectServerConnector.psm1" -Resolve
                    Import-Module -Name $modulePath

                    Mock -CommandName "Import-Module" -MockWith { }

                    Mock -CommandName Get-SPSite -MockWith {
                        return @{
                            WebApplication = @{
                                Url = "http://server"
                            }
                        }
                    }

                    Mock -CommandName Get-SPAuthenticationProvider -MockWith {
                        return @{
                            DisableKerberos = $true
                        }
                    }

                    try
                    {
                        [SPDscTests.DummyWebService] | Out-Null
                    }
                    catch
                    {
                        Add-Type -TypeDefinition @"
                            namespace SPDscTests
                            {
                                public class DummyWebService : System.IDisposable
                                {
                                    public void Dispose()
                                    {

                                    }
                                }
                            }
"@
                    }

                    function New-SPDscWssAdminTable
                    {
                        param(
                            [Parameter(Mandatory = $true)]
                            [System.Collections.Hashtable]
                            $Values
                        )
                        $ds = New-Object -TypeName "System.Data.DataSet"
                        $ds.Tables.Add("WssAdmin")
                        $Values.Keys | ForEach-Object -Process {
                            $ds.Tables[0].Columns.Add($_, [System.Object]) | Out-Null
                        }
                        $row = $ds.Tables[0].NewRow()
                        $Values.Keys | ForEach-Object -Process {
                            $row[$_] = $Values.$_
                        }
                        $ds.Tables[0].Rows.Add($row) | Out-Null
                        return $ds
                    }

                    Mock -CommandName "New-SPDscProjectServerWebService" -MockWith {
                        $service = [SPDscTests.DummyWebService]::new()
                        $service = $service | Add-Member -MemberType ScriptMethod `
                            -Name ReadWssSettings `
                            -Value {
                            return $global:SPDscCurrentWssSettings
                        } -PassThru -Force `
                        | Add-Member -MemberType ScriptMethod `
                            -Name UpdateWssSettings `
                            -Value {
                            $global:SPDscUpdateWssSettingsCalled = $true
                        } -PassThru -Force
                        return $service
                    }

                    Mock -CommandName "Set-SPProjectUserSync" -MockWith { }

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
            }

            switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major)
            {
                15
                {
                    Context -Name "All methods throw exceptions as Project Server support in SharePointDsc is only for 2016" -Fixture {
                        It "Should throw on the get method" {
                            { Get-TargetResource @testParams } | Should -Throw
                        }

                        It "Should throw on the test method" {
                            { Test-TargetResource @testParams } | Should -Throw
                        }

                        It "Should throw on the set method" {
                            { Set-TargetResource @testParams } | Should -Throw
                        }
                    }
                }
                16
                {
                    Context -Name "WSS settings can not be found" -Fixture {
                        BeforeAll {
                            $testParams = @{
                                Url                   = "http://sites.contoso.com/pwa"
                                CreateProjectSiteMode = "AutoCreate"
                            }

                            $global:SPDscCurrentWssSettings = $null
                        }

                        It "Should return unknown on settings in the get method" {
                            (Get-TargetResource @testParams).CreateProjectSiteMode | Should -Be "Unknown"
                        }
                    }

                    Context -Name "WSS settings are not applied correctly" -Fixture {
                        BeforeAll {
                            $testParams = @{
                                Url                   = "http://sites.contoso.com/pwa"
                                CreateProjectSiteMode = "AutoCreate"
                            }

                            $global:SPDscCurrentWssSettings = @{
                                WssAdmin = (New-SPDscWssAdminTable -Values @{
                                        WADMIN_AUTO_CREATE_SUBWEBS = 2
                                    }).Tables[0]
                            }
                        }

                        It "should return false on the values from the get method" {
                            (Get-TargetResource @testParams).CreateProjectSiteMode | Should -Be "DontCreate"
                        }

                        It "should return false from the test method" {
                            Test-TargetResource @testParams | Should -Be $false
                        }

                        It "should call update from the set method" {
                            $global:SPDscUpdateWssSettingsCalled = $false
                            Set-TargetResource @testParams
                            $global:SPDscUpdateWssSettingsCalled | Should -Be $true
                        }
                    }

                    Context -Name "WSS settings are applied correctly" -Fixture {
                        BeforeAll {
                            $testParams = @{
                                Url                   = "http://sites.contoso.com/pwa"
                                CreateProjectSiteMode = "AutoCreate"
                            }

                            $global:SPDscCurrentWssSettings = @{
                                WssAdmin = (New-SPDscWssAdminTable -Values @{
                                        WADMIN_AUTO_CREATE_SUBWEBS = 1
                                    }).Tables[0]
                            }
                        }

                        It "should return true on the values from the get method" {
                            (Get-TargetResource @testParams).CreateProjectSiteMode | Should -Be "AutoCreate"
                        }

                        It "should return true from the test method" {
                            Test-TargetResource @testParams | Should -Be $true
                        }
                    }
                }
                Default
                {
                    throw [Exception] "A supported version of SharePoint was not used in testing"
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
