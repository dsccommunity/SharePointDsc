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
$script:DSCResourceName = 'SPSearchResultSource'
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
                try
                {
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
                catch
                {
                    Write-Verbose "Could not instantiante the enum Microsoft.Office.Server.Search.Administration.SearchObjectLevel"
                }

                # Mocks for all contexts
                Mock -CommandName Get-SPEnterpriseSearchServiceApplication {
                    return @{
                        SearchCenterUrl = "http://example.sharepoint.com/pages"
                    }
                }

                Mock -CommandName Get-SPWeb -MockWith {
                    return @{ }
                }

                $Global:SPDscResultSourceProviders = @(
                    @{
                        "Exchange Search Provider" = @{
                            Id   = "c1e2843d-1825-4a37-ad15-dce5d50f46d2"
                            Name = "Exchange Search Provider"
                        }
                    },
                    @{
                        "Local People Provider" = @{
                            Id   = "5acc53f4-64b1-4f5d-ad16-7e9ab7372f93"
                            Name = "Local People Provider"
                        }
                    },
                    @{
                        "Local SharePoint Provider" = @{
                            Id   = "2d443d0a-61ba-472d-9964-ef27b14c8a07"
                            Name = "Local SharePoint Provider"
                        }
                    },
                    @{
                        "OpenSearch Provider" = @{
                            Id   = "eec636ac-013c-4dea-b794-dadcb4136dfe"
                            Name = "OpenSearch Provider"
                        }
                    },
                    @{
                        "Remote People Provider" = @{
                            Id   = "bb76bb0b-035d-4981-86ae-bd9587f3b0e4"
                            Name = "Remote People Provider"
                        }
                    },
                    @{
                        "Remote SharePoint Provider" = @{
                            Id   = "f7a3db86-fb85-40e4-a178-7ad85c732ba6"
                            Name = "Remote SharePoint Provider"
                        }
                    }
                )

                Mock -CommandName New-Object {
                    switch ($TypeName)
                    {
                        "Microsoft.Office.Server.Search.Administration.SearchObjectOwner"
                        {
                            return [System.Object]::new()
                        }
                        "Microsoft.Office.Server.Search.Administration.Query.FederationManager"
                        {
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
                                        Name           = "Test source"
                                        ProviderId     = "f7a3db86-fb85-40e4-a178-7ad85c732ba6"
                                        QueryTransform = @{
                                            QueryTemplate = "{searchTerms}"
                                        }
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
                        "Microsoft.Office.Server.Search.Administration.SearchObjectFilter"
                        {
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
            Context -Name "A search result source doesn't exist and should" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                 = "New source"
                        ScopeName            = "SSA"
                        ScopeUrl             = "Global"
                        SearchServiceAppName = "Search Service Application"
                        ProviderType         = "Remote SharePoint Provider"
                        Query                = "{searchTerms}"
                        ConnectionUrl        = "https://sharepoint.contoso.com"
                        Ensure               = "Present"
                    }

                    $Global:SPDscCurrentResultSourceMocks = $null
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create the result source in the set method" {
                    Set-TargetResource @testParams
                }
            }

            Context -Name "A search result source exists and should" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                 = "Test source"
                        ScopeName            = "SSA"
                        ScopeUrl             = "https://sharepoint.contoso.com"
                        SearchServiceAppName = "Search Service Application"
                        ProviderType         = "Remote SharePoint Provider"
                        Query                = "{searchTerms}"
                        ConnectionUrl        = "https://sharepoint.contoso.com"
                        Ensure               = "Present"
                    }

                    $Global:SPDscCurrentResultSourceMocks = @{
                        Name           = $testParams.Name
                        QueryTransform = @{
                            QueryTemplate = $testParams.Query
                        }
                        ProviderId     = "f7a3db86-fb85-40e4-a178-7ad85c732ba6"
                    }
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "A search result source exists and shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                 = "Test source"
                        ScopeUrl             = "Global"
                        SearchServiceAppName = "Search Service Application"
                        ProviderType         = "Remote SharePoint Provider"
                        Query                = "{searchTerms}"
                        ScopeName            = "SSA"
                        ConnectionUrl        = "https://sharepoint.contoso.com"
                        Ensure               = "Absent"
                    }

                    $Global:SPDscCurrentResultSourceMocks = @{
                        Name           = $testParams.Name
                        QueryTransform = @{
                            QueryTemplate = $testParams.Query
                        }
                        ProviderId     = "f7a3db86-fb85-40e4-a178-7ad85c732ba6"
                    }
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should remove the result source in the set method" {
                    Set-TargetResource @testParams
                }
            }

            Context -Name "A search result source doesn't exist and shouldn't" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                 = "Non-Existing source"
                        ScopeName            = "SSA"
                        ScopeUrl             = "Global"
                        SearchServiceAppName = "Search Service Application"
                        ProviderType         = "Remote SharePoint Provider"
                        Query                = "{searchTerms}"
                        ConnectionUrl        = "https://sharepoint.contoso.com"
                        Ensure               = "Absent"
                    }

                    $Global:SPDscCurrentResultSourceMocks = $null
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Valid SPWeb ScopeName was provided" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                 = "New source"
                        ScopeName            = "SPWeb"
                        ScopeUrl             = "https://SharePoint.contoso.com"
                        SearchServiceAppName = "Search Service Application"
                        ProviderType         = "Remote SharePoint Provider"
                        Query                = "{searchTerms}"
                        ConnectionUrl        = "https://sharepoint.contoso.com"
                        Ensure               = "Present"
                    }
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create the result source in the set method" {
                    Set-TargetResource @testParams
                }
            }

            Context -Name "Local Result Source" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                 = "Test source Local"
                        SearchServiceAppName = "Search Service Application"
                        ProviderType         = "Remote SharePoint Provider"
                        Query                = "{searchTerms}"
                        ConnectionUrl        = "https://sharepoint.contoso.com"
                        ScopeName            = "SSA"
                        ScopeUrl             = "Global"
                        Ensure               = "Present"
                    }
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create the result source in the set method" {
                    Set-TargetResource @testParams
                }
            }

            Context -Name "The specified ProviderType doesn't exist" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                 = "New source"
                        ScopeName            = "SSA"
                        ScopeUrl             = "Global"
                        SearchServiceAppName = "Search Service Application"
                        ProviderType         = "DoesNotExist"
                        Query                = "{searchTerms}"
                        ConnectionUrl        = "https://sharepoint.contoso.com"
                        Ensure               = "Present"
                    }

                    $Global:SPDscCurrentResultSourceMocks = $null
                    $Global:SPDscResultSourceProviders = @()
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create the result source in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Unknown ProviderType"
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Name                 = "External SharePoint results"
                            ScopeName            = "SPSite"
                            ScopeUrl             = "https://SharePoint.contoso.com"
                            SearchServiceAppName = "Search Service Application"
                            Query                = "{searchTerms}"
                            ProviderType         = "Remote SharePoint Provider"
                        }
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        $spServiceApp = [PSCustomObject]@{
                            DisplayName = "Search Service Application"
                            Name        = "Search Service Application"
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod `
                            -Name GetType `
                            -Value {
                            return @{
                                FullName = "Microsoft.Office.Server.Search.Administration.SearchServiceApplication"
                            }
                        } -PassThru -Force
                        return $spServiceApp
                    }

                    Mock -CommandName Get-SPEnterpriseSearchFileFormat -MockWith {
                        return @(
                            @{
                                Identity = "pdf"
                            }
                        )
                    }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    if ($null -eq (Get-Variable -Name 'SkipSitesAndWebs' -ErrorAction SilentlyContinue))
                    {
                        $Global:SkipSitesAndWebs = $true
                    }

                    $result = @'
        SPSearchResultSource [0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            Ensure               = "Present";
            Name                 = "External SharePoint results";
            PsDscRunAsCredential = \$Credsspfarm;
            Query                = "{searchTerms}";
            ScopeName            = "SPSite";
            ScopeUrl             = "Global";
            SearchServiceAppName = "Search Service Application";
        }

'@
                }

                It "Should return valid DSC block from the Export method" {
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")
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
