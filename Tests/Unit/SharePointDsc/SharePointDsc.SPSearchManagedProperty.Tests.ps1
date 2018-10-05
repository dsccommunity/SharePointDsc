[CmdletBinding()]
param(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
                                         -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
                                         -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
                                -ChildPath "..\UnitTestHelper.psm1" `
                                -Resolve)

$Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
                                              -DscResource "SPSearchManagedProperty"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        $Script:PropertyCreated = $false

        # Mocks for all contexts
        Mock -CommandName New-SPEnterpriseSearchMetadataManagedProperty -MockWith { $Script:PropertyCreated = $true }
        Mock -CommandName Set-SPEnterpriseSearchMetadataManagedProperty -MockWith {}
        Mock -CommandName Remove-SPEnterpriseSearchMetadataManagedProperty -MockWith {}
        Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith {
            return @(
                @{
                    Name = "Search Service Application"
                }
            )
        }

        try { [Microsoft.Office.Server.Search.Administration] }
        catch {
            try {
                Add-Type -TypeDefinition @"
                namespace Microsoft.Office.Server.Search.Administration {
                public enum ManagedDataType { Text, YesNo, Integer, DateTime, Double };
                }
"@ -ErrorAction SilentlyContinue
            }
            catch {
                Write-Verbose "The Type Microsoft.Office.Server.Search.Administration.ManagedDataType was already added."
            }
        }

        try { [Microsoft.Office.Server.Search.Administration.MappingCollection] }
        catch {
            try {
                Add-Type -TypeDefinition @"
                namespace Microsoft.Office.Server.Search.Administration {
                    public class MappingCollection
                    {
                        public void Add(object mapping){}
                    }
                }
"@ -ErrorAction SilentlyContinue
            }
            catch {
                Write-Verbose "The Type Microsoft.Office.Server.Search.Administration.MappingCollection was already added."
            }
        }

        try { [Microsoft.Office.Server.Search.Administration.Mapping] }
        catch {
            try {
                Add-Type -TypeDefinition @"
                namespace Microsoft.Office.Server.Search.Administration {
                    public class Mapping
                    {
                        public string CrawledPropertyName{get; set;}
                        public string CrawledPropSet{get; set;}
                        public int ManagedPID{get;set;}
                    }
                }
"@ -ErrorAction SilentlyContinue
            }
            catch {
                Write-Verbose "The Type Microsoft.Office.Server.Search.Administration.Mapping was already added."
            }
        }

        Context -Name "When the property doesn't exist and should" -Fixture {
            $testParams = @{
                Name = "TestParam"
                PropertyType = "Text"
                ServiceAppName = "Search Service Application"
                HasMultipleValues = $false
                Alias = "TestAlias"
                CrawledProperties = @("CP1", "CP2")
                Ensure = "Present"
            }

            $Script:PropertyCreated = $false
            Mock -CommandName Get-SPEnterpriseSearchMetadataManagedProperty -MockWith {
                return $null
            } -ParameterFilter { $Script:PropertyCreated -eq $false }

            Mock -CommandName Get-SPEnterpriseSearchMetadataManagedProperty -MockWith {
                $results = @{
                    Name = "TestParam"
                    PID = 1
                    ManagedType = "Text"
                    Searchable = $true
                    Refinable = $true
                    Queryable = $true
                    Sortable = $true
                    NoWordBreaker = $true
                    HasMultipleValues = $false
                } | Add-Member -MemberType ScriptMethod `
                    -Name GetAliases `
                    -Value {
                        @("Alias1", "Alias2")
                    } -PassThru -Force |
                    Add-Member -MemberType ScriptMethod `
                    -Name GetMappedCrawledProperties `
                    -Value {
                        return @("Map1")
                    } -PassThru -Force |
                    Add-Member -MemberType ScriptMethod `
                    -Name Update `
                    -Value {
                        $null
                    } -PassThru -Force |
                    Add-Member -MemberType ScriptMethod `
                    -Name AddAlias `
                    -Value {
                        $null
                    } -PassThru -Force |
                    Add-Member -MemberType ScriptMethod `
                    -Name SetMappings `
                    -Value {
                        $null
                    } -PassThru -Force
                return $results

            } -ParameterFilter { $Script:PropertyCreated -eq $true }

            Mock -CommandName Get-SPEnterpriseSearchMetadataCrawledProperty -MockWith {
                return @{CrawledPropertyName = 'FakeValue';}
            }

            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should create the managed property" {
                Set-TargetResource @testParams
                Assert-MockCalled -CommandName Set-SPEnterpriseSearchMetadataManagedProperty -Exactly 1
            }

            It "Should now return Present from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }
        }

        Context -Name "When the property already exists with the proper type and should" -Fixture {
            $testParams = @{
                Name = "TestParam"
                PropertyType = "Text"
                ServiceAppName = "Search Service Application"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPEnterpriseSearchMetadataManagedProperty -MockWith {
                $results = @{
                    Name = "TestParam"
                    PID = 1
                    ManagedType = "Text"
                    Searchable = $true
                    Refinable = $true
                    Queryable = $true
                    Sortable = $true
                    NoWordBreaker = $true
                    HasMultipleValues = $false
                    Ensure = "Present"
                } | Add-Member -MemberType ScriptMethod `
                    -Name GetAliases `
                    -Value {
                        $null
                    } -PassThru -Force |
                    Add-Member -MemberType ScriptMethod `
                    -Name GetMappedCrawledProperties `
                    -Value {
                        $null
                    } -PassThru -Force |
                    Add-Member -MemberType ScriptMethod `
                    -Name Update `
                    -Value {
                        $null
                    } -PassThru -Force |
                    Add-Member -MemberType ScriptMethod `
                    -Name AddAlias `
                    -Value {
                        $null
                    } -PassThru -Force |
                    Add-Member -MemberType ScriptMethod `
                    -Name SetMappings `
                    -Value {
                        $null
                    } -PassThru -Force |
                    Add-Member -MemberType ScriptMethod `
                    -Name DeleteAllMappings `
                    -Value {
                        $null
                    } -PassThru -Force
                return $results
            }

            It "Should return present from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should do nothing" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPEnterpriseSearchMetadataManagedProperty -Exactly 0 -Scope Context
                Assert-MockCalled New-SPEnterpriseSearchMetadataManagedProperty -Exactly 0 -Scope Context
            }
        }

        Context -Name "When the property already exists, but with the invalid property type" -Fixture {
            $testParams = @{
                Name = "TestParam"
                PropertyType = "Text"
                ServiceAppName = "Search Service Application"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPEnterpriseSearchMetadataManagedProperty -MockWith {
                $results = @{
                    Name = "TestParam"
                    PID = 1
                    ManagedType = "Number"
                    Searchable = $true
                    Refinable = $true
                    Queryable = $true
                    Sortable = $true
                    NoWordBreaker = $true
                    HasMultipleValues = $false
                    Ensure = "Present"
                } | Add-Member -MemberType ScriptMethod `
                    -Name GetAliases `
                    -Value {
                        $null
                    } -PassThru -Force |
                    Add-Member -MemberType ScriptMethod `
                    -Name GetMappedCrawledProperties `
                    -Value {
                        $null
                    } -PassThru -Force |
                    Add-Member -MemberType ScriptMethod `
                    -Name Update `
                    -Value {
                        $null
                    } -PassThru -Force |
                    Add-Member -MemberType ScriptMethod `
                    -Name AddAlias `
                    -Value {
                        $null
                    } -PassThru -Force |
                    Add-Member -MemberType ScriptMethod `
                    -Name SetMappings `
                    -Value {
                        $null
                    } -PassThru -Force |
                    Add-Member -MemberType ScriptMethod `
                    -Name DeleteAllMappings `
                    -Value {
                        $null
                    } -PassThru -Force
                return $results
            }

            It "Should return present from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should recreate the property with the proper type" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPEnterpriseSearchMetadataManagedProperty -Exactly 1 -Scope Context
                Assert-MockCalled New-SPEnterpriseSearchMetadataManagedProperty -Exactly 1 -Scope Context
            }
        }

        Context -Name "When the property should not exist" -Fixture {
            $testParams = @{
                Name = "TestParam"
                PropertyType = "Text"
                ServiceAppName = "Search Service Application"
                Ensure = "Absent"
            }

            Mock -CommandName Get-SPEnterpriseSearchMetadataManagedProperty -MockWith {
                $results = @{
                    Name = "TestParam"
                    PID = 1
                    ManagedType = "Text"
                    Searchable = $true
                    Refinable = $true
                    Queryable = $true
                    Sortable = $true
                    NoWordBreaker = $true
                    HasMultipleValues = $false
                    Ensure = "Present"
                } | Add-Member -MemberType ScriptMethod `
                    -Name GetAliases `
                    -Value {
                        $null
                    } -PassThru -Force |
                    Add-Member -MemberType ScriptMethod `
                    -Name GetMappedCrawledProperties `
                    -Value {
                        $null
                    } -PassThru -Force |
                    Add-Member -MemberType ScriptMethod `
                    -Name Update `
                    -Value {
                        $null
                    } -PassThru -Force |
                    Add-Member -MemberType ScriptMethod `
                    -Name AddAlias `
                    -Value {
                        $null
                    } -PassThru -Force |
                    Add-Member -MemberType ScriptMethod `
                    -Name SetMappings `
                    -Value {
                        $null
                    } -PassThru -Force |
                    Add-Member -MemberType ScriptMethod `
                    -Name DeleteAllMappings `
                    -Value {
                        $null
                    } -PassThru -Force
                return $results
            }

            It "Should return present from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should recreate the property with the proper type" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPEnterpriseSearchMetadataManagedProperty -Exactly 1 -Scope Context
                Assert-MockCalled New-SPEnterpriseSearchMetadataManagedProperty -Exactly 0 -Scope Context
            }
        }

        Context -Name "When specified Service Application does not exist" -Fixture {
            $testParams = @{
                Name = "TestParam"
                PropertyType = "Text"
                ServiceAppName = "InvalidSSA"
                Ensure = "Absent"
            }

            Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith{
                return $null
            }

            It "Should throw an error" {
                { Get-TargetResource @testParams }| Should Throw "The specified Search Service Application InvalidSSA is  `
                   invalid. Please make sure you specify the name of an existing service application."
            }
        }

        Context -Name "When specified Service Application does not exist" -Fixture {
            $testParams = @{
                Name = "TestParam"
                PropertyType = "Text"
                ServiceAppName = "InvalidSSA"
                Ensure = "Absent"
            }

            Mock -CommandName Get-SPEnterpriseSearchServiceApplication -MockWith{
                return $null
            }

            It "Should throw an error" {
                { Get-TargetResource @testParams }| Should Throw "The specified Search Service Application InvalidSSA is  `
                   invalid. Please make sure you specify the name of an existing service application."
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
