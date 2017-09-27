[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string] 
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
                                         -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
                                         -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
                                -ChildPath "..\UnitTestHelper.psm1" `
                                -Resolve)

$Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
                                              -DscResource "SPProjectServerWssSettings"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major) 
        {
            15 {
                Context -Name "All methods throw exceptions as Project Server support in SharePointDsc is only for 2016" -Fixture {
                    It "Should throw on the get method" {
                        { Get-TargetResource @testParams } | Should Throw
                    }

                    It "Should throw on the test method" {
                        { Test-TargetResource @testParams } | Should Throw
                    }

                    It "Should throw on the set method" {
                        { Set-TargetResource @testParams } | Should Throw
                    }
                }
            }
            16 {
                $modulePath = "Modules\SharePointDsc\Modules\SharePointDsc.ProjectServer\ProjectServerConnector.psm1"
                Import-Module -Name (Join-Path -Path $Global:SPDscHelper.RepoRoot -ChildPath $modulePath -Resolve)

                Mock -CommandName "Import-Module" -MockWith {}

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

                Context -Name "WSS settings can not be found" -Fixture {
                    $testParams = @{
                        Url = "http://sites.contoso.com/pwa"
                        CreateProjectSiteMode = "AutoCreate"
                    }

                    $global:SPDscCurrentWssSettings = $null

                    It "Should return unknown on settings in the get method" {
                        (Get-TargetResource @testParams).CreateProjectSiteMode | Should Be "Unknown"
                    }
                }

                Context -Name "WSS settings are not applied correctly" -Fixture {
                    $testParams = @{
                        Url = "http://sites.contoso.com/pwa"
                        CreateProjectSiteMode = "AutoCreate"
                    }

                    $global:SPDscCurrentWssSettings = @{
                        WssAdmin = (New-SPDscWssAdminTable -Values @{
                            WADMIN_AUTO_CREATE_SUBWEBS = 2
                        }).Tables[0]
                    }

                    It "should return false on the values from the get method" {
                        (Get-TargetResource @testParams).CreateProjectSiteMode | Should Be "DontCreate"
                    }

                    It "should return false from the test method" {
                        Test-TargetResource @testParams | Should Be $false
                    }

                    It "should call update from the set method" {
                        $global:SPDscUpdateWssSettingsCalled = $false
                        Set-TargetResource @testParams
                        $global:SPDscUpdateWssSettingsCalled | Should Be $true
                    }
                }
                
                Context -Name "WSS settings are applied correctly" -Fixture {
                    $testParams = @{
                        Url = "http://sites.contoso.com/pwa"
                        CreateProjectSiteMode = "AutoCreate"
                    }

                    $global:SPDscCurrentWssSettings = @{
                        WssAdmin = (New-SPDscWssAdminTable -Values @{
                            WADMIN_AUTO_CREATE_SUBWEBS = 1
                        }).Tables[0]
                    }

                    It "should return true on the values from the get method" {
                        (Get-TargetResource @testParams).CreateProjectSiteMode | Should Be "AutoCreate"
                    }

                    It "should return true from the test method" {
                        Test-TargetResource @testParams | Should Be $true
                    }
                }
            }
            Default {
                throw [Exception] "A supported version of SharePoint was not used in testing"
            }
        }
    }
}
