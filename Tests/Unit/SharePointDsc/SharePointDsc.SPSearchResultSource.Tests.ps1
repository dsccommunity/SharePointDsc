[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPSearchresultSource"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPSearchresultSource - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Test source"
            SearchServiceAppName = "Search Service Application"
            ProviderType = "Remote SharePoint Provider"
            Query = "{searchTerms}"
            ConnectionUrl = "https://sharepoint.contoso.com"
            Ensure = "Present"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDsc")
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 

        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }

        Add-Type -TypeDefinition @"
            namespace Microsoft.Office.Server.Search.Administration
            {
                public class SearchObjectLevel {
                    public static string Ssa { get { return ""; } }
                }
            }
"@
        
        Mock Get-SPEnterpriseSearchServiceApplication {
            return @{
                SearchCenterUrl = "http://example.sharepoint.com/pages"
            }
        }
        Mock Get-SPWeb {
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
 
        Mock New-Object {
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
                                             -Value { }
                }
            }
        }

        Context "A search result source doesn't exist and should" {

            $Global:SPDscCurrentResultSourceMocks = $null

            It "should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "should create the result source in the set method" {
                Set-TargetResource @testParams
            }
        }

        Context "A search result source exists and should" {

            $Global:SPDscCurrentResultSourceMocks = @{
                Name = $testParams.Name
                QueryTransform = @{
                    QueryTemplate = $testParams.Query
                }
                ProviderId = "f7a3db86-fb85-40e4-a178-7ad85c732ba6"
            }

            It "should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        $testParams.Ensure = "Absent"

        Context "A search result source exists and shouldn't" {

            $Global:SPDscCurrentResultSourceMocks = @{
                Name = $testParams.Name
                QueryTransform = @{
                    QueryTemplate = $testParams.Query
                }
                ProviderId = "f7a3db86-fb85-40e4-a178-7ad85c732ba6"
            }

            It "should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "should remove the result source in the set method" {
                Set-TargetResource @testParams
            }
        }

        Context "A search result source doesn't exist and shouldn't" {

            $Global:SPDscCurrentResultSourceMocks = $null

            It "should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should be "Absent"
            }

            It "should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }
}