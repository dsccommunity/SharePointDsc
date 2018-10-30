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
                                              -DscResource "SPSearchResultSource"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope
try {
        # Initialize tests
        Add-Type -TypeDefinition @"
        namespace Microsoft.Office.Server.Search.Administration {
            public enum SearchObjectLevel
            {
                SPWeb,
                SPSite,
                SPSiteSubscription,
                Ssa
            }
        }
"@ -ErrorAction SilentlyContinue
}
catch {
    Write-Verbose "Could not instantiante the enum Microsoft.Office.Server.Search.Administration.SearchObjectLevel"
}

        # Mocks for all contexts
        Mock -CommandName Get-SPEnterpriseSearchServiceApplication {
            return @{
                SearchCenterUrl = "http://example.sharepoint.com/pages"
            }
        }

        Mock -CommandName Get-SPWeb -MockWith {
            return @{}
        }

        $Global:SPDscResultSourceProvicers = @(
            @{
                Id = "c1e2843d-1825-4a37-ad15-dce5d50f46d2"
                Name = "Exchange Search Provider"
            },
            @{
                Id = "5acc53f4-64b1-4f5d-ad16-7e9ab7372f93"
                Name = "Local People Provider"
            },
            @{
                Id = "2d443d0a-61ba-472d-9964-ef27b14c8a07"
                Name = "Local SharePoint Provider"
            },
            @{
                Id = "eec636ac-013c-4dea-b794-dadcb4136dfe"
                Name = "OpenSearch Provider"
            },
            @{
                Id = "bb76bb0b-035d-4981-86ae-bd9587f3b0e4"
                Name = "Remote People Provider"
            },
            @{
                Id = "f7a3db86-fb85-40e4-a178-7ad85c732ba6"
                Name = "Remote SharePoint Provider"
            }
        )

        Mock -CommandName New-Object {
            switch ($TypeName) {
                "Microsoft.Office.Server.Search.Administration.SearchObjectOwner" {
                    return [System.Object]::new()
                }
                "Microsoft.Office.Server.Search.Administration.Query.FederationManager" {
                    return [System.Object]::new() | Add-Member -Name GetSourceByName `
                                             -MemberType ScriptMethod `
                                             -PassThru `
                                             -Value {
                                                 return $Global:SPDscCurrentResultSourceMocks
                                             } `
                                | Add-Member -Name ListProviders `
                                             -MemberType ScriptMethod `
                                             -PassThru `
                                             -Value {
                                                 return $Global:SPDscResultSourceProviders
                                             } `
                                | Add-Member -Name ListSources `
                                             -MemberType ScriptMethod `
                                             -PassThru `
                                             -Value {
                                                 return @(
                                                     @{
                                                        Name = "Test source"
                                                    }
                                                 )
                                             } `
                                | Add-Member -Name CreateSource `
                                             -MemberType ScriptMethod `
                                             -PassThru `
                                             -Value {
                                                 return [PSObject]@{
                                                    ProviderId            = [guid]::Empty
                                                    Name                  = [string]::Empty
                                                    ConnectionUrlTemplate = [string]::Empty
                                                } | Add-Member -Name CreateQueryTransform `
                                                            -MemberType ScriptMethod `
                                                            -PassThru `
                                                            -Value { } `
                                                | Add-Member -Name Commit `
                                                            -MemberType ScriptMethod `
                                                            -PassThru `
                                                            -Value {
                                                                $Global:SPDscResultSourceUpdated = $true
                                                            }
                                             } `
                                | Add-Member -Name RemoveSource `
                                             -MemberType ScriptMethod `
                                             -PassThru `
                                             -Value { } `
                }
                "Microsoft.Office.Server.Search.Administration.SearchObjectFilter" {
                    return [System.Object]::new() | Add-Member -Name IncludeHigherLevel `
                        -MemberType ScriptProperty `
                        -PassThru `
                        {
                            # get
                            "getter"
                        }`
                        {
                            # set
                            param ( $arg )
                        }
                }
            }
        }

        # Test contexts
        Context -Name "A search result source doesn't exist and should" -Fixture {
            $testParams = @{
                Name = "New source"
                ScopeName = "SSA"
                SearchServiceAppName = "Search Service Application"
                ProviderType = "Remote SharePoint Provider"
                Query = "{searchTerms}"
                ConnectionUrl = "https://sharepoint.contoso.com"
                Ensure = "Present"
            }

            $Global:SPDscCurrentResultSourceMocks = $null

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should create the result source in the set method" {
                Set-TargetResource @testParams
            }
        }

        Context -Name "Invalid parameters are specified" -Fixture {
            $testParams = @{
                Name = "Test source"
                ScopeName = "SPSite"
                SearchServiceAppName = "Search Service Application"
                ProviderType = "Remote SharePoint Provider"
                Query = "{searchTerms}"
                ConnectionUrl = "https://sharepoint.contoso.com"
                Ensure = "Present"
            }

            It "Should throw an error from the get method" {
                { Get-TargetResource @testParams } | Should Throw "When specifying a ScopeName of type SPSite you also need to provide a ScopeUrl value."
            }

            It "Should thow an error from the set method" {
                { Set-TargetResource @testParams } | Should Throw "When specifying a ScopeName of type SPSite you also need to provide a ScopeUrl value."
            }
        }

        Context -Name "A search result source exists and should" -Fixture {
            $testParams = @{
                Name = "Test source"
                ScopeName = "SSA"
                SearchServiceAppName = "Search Service Application"
                ProviderType = "Remote SharePoint Provider"
                Query = "{searchTerms}"
                ConnectionUrl = "https://sharepoint.contoso.com"
                Ensure = "Present"
            }

            $Global:SPDscCurrentResultSourceMocks = @{
                Name = $testParams.Name
                QueryTransform = @{
                    QueryTemplate = $testParams.Query
                }
                ProviderId = "f7a3db86-fb85-40e4-a178-7ad85c732ba6"
            }

            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "A search result source exists and shouldn't" -Fixture {
            $testParams = @{
                Name = "Test source"
                SearchServiceAppName = "Search Service Application"
                ProviderType = "Remote SharePoint Provider"
                Query = "{searchTerms}"
                ScopeName = "SSA"
                ConnectionUrl = "https://sharepoint.contoso.com"
                Ensure = "Absent"
            }

            $Global:SPDscCurrentResultSourceMocks = @{
                Name = $testParams.Name
                QueryTransform = @{
                    QueryTemplate = $testParams.Query
                }
                ProviderId = "f7a3db86-fb85-40e4-a178-7ad85c732ba6"
            }

            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should remove the result source in the set method" {
                Set-TargetResource @testParams
            }
        }

        Context -Name "A search result source doesn't exist and shouldn't" -Fixture {
            $testParams = @{
                Name = "Non-Existing source"
                ScopeName = "SSA"
                SearchServiceAppName = "Search Service Application"
                ProviderType = "Remote SharePoint Provider"
                Query = "{searchTerms}"
                ConnectionUrl = "https://sharepoint.contoso.com"
                Ensure = "Absent"
            }

            $Global:SPDscCurrentResultSourceMocks = $null

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should be "Absent"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "Valid SPWeb ScopeName was provided" -Fixture {
            $testParams = @{
                Name = "New source"
                ScopeName = "SPWeb"
                ScopeUrl = "https://SharePoint.contoso.com"
                SearchServiceAppName = "Search Service Application"
                ProviderType = "Remote SharePoint Provider"
                Query = "{searchTerms}"
                ConnectionUrl = "https://sharepoint.contoso.com"
                Ensure = "Present"
            }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should create the result source in the set method" {
                Set-TargetResource @testParams
            }
        }

        Context -Name "Local Result Source" -Fixture {
            $testParams = @{
                Name = "Test source Local"
                SearchServiceAppName = "Search Service Application"
                ProviderType = "Remote SharePoint Provider"
                Query = "{searchTerms}"
                ConnectionUrl = "https://sharepoint.contoso.com"
                ScopeName = "SSA"
                ScopeUrl = "https://sharepoint.contoso.com"
                Ensure = "Present"
            }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should create the result source in the set method" {
                Set-TargetResource @testParams
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
