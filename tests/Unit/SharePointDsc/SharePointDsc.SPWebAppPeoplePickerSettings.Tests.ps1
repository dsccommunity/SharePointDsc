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
$script:DSCResourceName = 'SPWebAppPeoplePickerSettings'
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

            # Initialize tests
            $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
            $mockAccount = New-Object -TypeName "System.Management.Automation.PSCredential" `
                -ArgumentList @("username", $mockPassword)

            try
            { [Microsoft.SharePoint.Administration.SPPeoplePickerSearchActiveDirectoryDomain]
            }
            catch
            {
                Add-Type -TypeDefinition @"
    namespace Microsoft.SharePoint.Administration {
        public class SPPeoplePickerSearchActiveDirectoryDomain {
            public string DomainName { get; set; }
            public string ShortDomainName { get; set; }
            public bool IsForest { get; set; }
            public string LoginName { get; set; }
            public void SetPassword(string password)
            {

            }
        }
    }
"@
            }
            # Mocks for all contexts

            # Test contexts
            Context -Name "The web application doesn't exist" -Fixture {
                $testParams = @{
                    WebAppUrl                      = "http://sharepoint.contoso.com"
                    ActiveDirectoryCustomFilter    = $null
                    ActiveDirectoryCustomQuery     = $null
                    ActiveDirectorySearchTimeout   = 30
                    OnlySearchWithinSiteCollection = $false
                    SearchActiveDirectoryDomains   = @()
                }

                Mock -CommandName Get-SPWebApplication -MockWith { return $null }

                It "Should return null for all properties from the get method" {
                    (Get-TargetResource @testParams).OnlySearchWithinSiteCollection | Should -BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception from the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Specified web application could not be found."
                }
            }

            Context -Name "Search domain settings do not match actual values" -Fixture {
                $testParams = @{
                    WebAppUrl                    = "http://sharepoint.contoso.com"
                    SearchActiveDirectoryDomains = @(
                        (New-CimInstance -ClassName MSFT_SPWebAppPPSearchDomain -Property @{
                                FQDN          = "contoso.intra"
                                IsForest      = $false
                                AccessAccount = (New-CimInstance -ClassName MSFT_Credential `
                                        -Property @{
                                        Username = [string]$mockAccount.UserName;
                                        Password = [string]$mockAccount.Password;
                                    } `
                                        -Namespace root/microsoft/windows/desiredstateconfiguration `
                                        -ClientOnly)
                            } -ClientOnly)
                    )
                }

                Mock -CommandName Get-SPWebApplication -MockWith {
                    $searchADdom = New-Object -TypeName "System.Collections.Generic.List[System.Object]"
                    $searchDom1 = New-Object -TypeName "Object" | `
                        Add-Member -MemberType NoteProperty `
                        -Name DomainName `
                        -Value ( "contosonew.intra" ) -PassThru | `
                        Add-Member -MemberType NoteProperty `
                        -Name IsForest `
                        -Value ( $false ) -PassThru | `
                        Add-Member -MemberType NoteProperty `
                        -Name LoginName `
                        -Value ( $mockAccount.UserName ) -PassThru
                    $searchADdom.Add($searchDom1)

                    $returnval = @{
                        PeoplePickerSettings = @{
                            ActiveDirectoryCustomFilter    = "()"
                            ActiveDirectoryCustomQuery     = "()"
                            ActiveDirectorySearchTimeout   = @{
                                TotalSeconds = 10
                            }
                            OnlySearchWithinSiteCollection = $true
                            SearchActiveDirectoryDomains   = $searchADdom
                        }
                    }
                    $returnval = $returnval | Add-Member -MemberType ScriptMethod -Name Update -Value {
                        $Global:SPDscWebApplicationUpdateCalled = $true
                    } -PassThru

                    return $returnval
                }

                It "Should return SearchTimeOut=10 from the get method" {
                    (Get-TargetResource @testParams).ActiveDirectorySearchTimeout | Should -Be 10
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                $Global:SPDscWebApplicationUpdateCalled = $false
                It "Should update the people picker settings" {
                    Set-TargetResource @testParams
                    $Global:SPDscWebApplicationUpdateCalled | Should -Be $true
                }
            }

            Context -Name "Settings do not match actual values" -Fixture {
                $testParams = @{
                    WebAppUrl                      = "http://sharepoint.contoso.com"
                    ActiveDirectoryCustomFilter    = $null
                    ActiveDirectoryCustomQuery     = $null
                    ActiveDirectorySearchTimeout   = 30
                    OnlySearchWithinSiteCollection = $false
                }

                Mock -CommandName Get-SPWebApplication -MockWith {
                    $searchADdom = New-Object -TypeName "System.Collections.Generic.List[System.Object]"
                    $searchDom1 = New-Object -TypeName "Object" | `
                        Add-Member -MemberType NoteProperty `
                        -Name DomainName `
                        -Value ( "contoso.intra" ) -PassThru | `
                        Add-Member -MemberType NoteProperty `
                        -Name IsForest `
                        -Value ( $false ) -PassThru | `
                        Add-Member -MemberType NoteProperty `
                        -Name LoginName `
                        -Value ( $mockAccount.UserName ) -PassThru
                    $searchADdom.Add($searchDom1)

                    $returnval = @{
                        PeoplePickerSettings = @{
                            ActiveDirectoryCustomFilter    = "()"
                            ActiveDirectoryCustomQuery     = "()"
                            ActiveDirectorySearchTimeout   = @{
                                TotalSeconds = 10
                            }
                            OnlySearchWithinSiteCollection = $true
                            SearchActiveDirectoryDomains   = $searchADdom
                        }
                    }
                    $returnval = $returnval | Add-Member -MemberType ScriptMethod -Name Update -Value {
                        $Global:SPDscWebApplicationUpdateCalled = $true
                    } -PassThru

                    return $returnval
                }

                It "Should return SearchTimeOut=10 from the get method" {
                    (Get-TargetResource @testParams).ActiveDirectorySearchTimeout | Should -Be 10
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                $Global:SPDscWebApplicationUpdateCalled = $false
                It "Should update the people picker settings" {
                    Set-TargetResource @testParams
                    $Global:SPDscWebApplicationUpdateCalled | Should -Be $true
                }
            }

            Context -Name "Search domain settings match actual values" -Fixture {
                $testParams = @{
                    WebAppUrl                    = "http://sharepoint.contoso.com"
                    SearchActiveDirectoryDomains = @(
                        (New-CimInstance -ClassName MSFT_SPWebAppPPSearchDomain -Property @{
                                FQDN          = "contoso.intra"
                                IsForest      = $false
                                AccessAccount = (New-CimInstance -ClassName MSFT_Credential `
                                        -Property @{
                                        Username = [string]$mockAccount.UserName;
                                        Password = [string]$mockAccount.Password;
                                    } `
                                        -Namespace root/microsoft/windows/desiredstateconfiguration `
                                        -ClientOnly)
                            } -ClientOnly)
                    )
                }

                Mock -CommandName Get-SPWebApplication -MockWith {
                    $searchADdom = New-Object -TypeName "System.Collections.Generic.List[System.Object]"
                    $searchDom1 = New-Object -TypeName "Object" | `
                        Add-Member -MemberType NoteProperty `
                        -Name DomainName `
                        -Value ( "contoso.intra" ) -PassThru | `
                        Add-Member -MemberType NoteProperty `
                        -Name IsForest `
                        -Value ( $false ) -PassThru | `
                        Add-Member -MemberType NoteProperty `
                        -Name LoginName `
                        -Value ( $mockAccount.UserName ) -PassThru
                    $searchADdom.Add($searchDom1)

                    $returnval = @{
                        PeoplePickerSettings = @{
                            ActiveDirectoryCustomFilter    = "()"
                            ActiveDirectoryCustomQuery     = "()"
                            ActiveDirectorySearchTimeout   = @{
                                TotalSeconds = 10
                            }
                            OnlySearchWithinSiteCollection = $true
                            SearchActiveDirectoryDomains   = $searchADdom
                        }
                    }
                    $returnval = $returnval | Add-Member -MemberType ScriptMethod -Name Update -Value {
                        $Global:SPDscWebApplicationUpdateCalled = $true
                    } -PassThru

                    return $returnval
                }

                It "Should return SearchTimeOut=10 from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.ActiveDirectorySearchTimeout | Should -Be 10
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Settings match actual values" -Fixture {
                $testParams = @{
                    WebAppUrl                      = "http://sharepoint.contoso.com"
                    ActiveDirectoryCustomFilter    = $null
                    ActiveDirectoryCustomQuery     = $null
                    ActiveDirectorySearchTimeout   = 30
                    OnlySearchWithinSiteCollection = $false
                }

                Mock -CommandName Get-SPWebApplication -MockWith {
                    $returnval = @{
                        PeoplePickerSettings = @{
                            ActiveDirectoryCustomFilter    = $null
                            ActiveDirectoryCustomQuery     = $null
                            ActiveDirectorySearchTimeout   = @{
                                TotalSeconds = 30
                            }
                            OnlySearchWithinSiteCollection = $false
                            SearchActiveDirectoryDomains   = @()
                        }
                    }
                    $returnval = $returnval | Add-Member -MemberType ScriptMethod -Name Update -Value {
                        $Global:SPDscWebApplicationUpdateCalled = $true
                    } -PassThru

                    return $returnval
                }

                It "Should return SearchTimeOut=30 from the get method" {
                    (Get-TargetResource @testParams).ActiveDirectorySearchTimeout | Should -Be 30
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
