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
$script:DSCResourceName = 'SPWeb'
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

                # Initialize tests
                $fakeWebApp = [PSCustomObject]@{ }
                $fakeWebApp | Add-Member -MemberType ScriptMethod `
                    -Name GrantAccessToProcessIdentity `
                    -PassThru `
                    -Value { }

                # Mocks for all contexts
                Mock -CommandName New-Object -MockWith {
                    [PSCustomObject]@{
                        WebApplication = $fakeWebApp
                    }
                } -ParameterFilter {
                    $TypeName -eq "Microsoft.SharePoint.SPSite"
                }
                Mock -CommandName Remove-SPWeb -MockWith { }
            }

            # Test contexts
            Context -Name "The SPWeb doesn't exist yet and should" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Url         = "http://site.sharepoint.com/sites/web"
                        Name        = "Team Site"
                        Description = "desc"
                    }

                    Mock -CommandName Get-SPWeb -MockWith { return $null }
                }

                It "Should return 'Absent' from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create a new SPWeb from the set method" {
                    Mock -CommandName New-SPWeb { } -Verifiable

                    Set-TargetResource @testParams

                    Assert-MockCalled New-SPWeb
                    Assert-MockCalled New-Object
                }
            }

            Context -Name "The SPWeb exists and has the correct name and description" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Url         = "http://site.sharepoint.com/sites/web"
                        Name        = "Team Site"
                        Description = "desc"
                    }

                    Mock -CommandName Get-SPWeb -MockWith {
                        return @{
                            Url                = $testParams.Url
                            Title              = $testParams.Name
                            Description        = $testParams.Description
                            WebTemplate        = "STS"
                            WebTemplateId      = "0"
                            Navigation         = @{ UseShared = $true }
                            Language           = 1033
                            HasUniquePerm      = $false
                            RequestAccessEmail = "valid@contoso.com"
                        }
                    }
                }

                It "Should return the SPWeb data from the get method" {

                    $result = Get-TargetResource @testParams

                    $result.Ensure | Should -Be "Present"
                    $result.Template | Should -Be "STS#0"
                    $result.UniquePermissions | Should -Be $false
                    $result.UseParentTopNav | Should -Be $true
                    $result.RequestAccessEmail | Should -Be "valid@contoso.com"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The SPWeb exists and should not" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Url         = "http://site.sharepoint.com/sites/web"
                        Name        = "Team Site"
                        Description = "desc"
                        Ensure      = "Absent"
                    }

                    Mock -CommandName Get-SPWeb -MockWith {
                        return @{
                            Url = $testParams.Url
                        }
                    }
                }

                It "Should return 'Present' from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should remove the SPWeb in the set method" {
                    Set-TargetResource @testParams

                    Assert-MockCalled Remove-SPWeb
                }
            }

            Context -Name "The SPWeb exists but has the wrong editable values" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Url               = "http://site.sharepoint.com/sites/web"
                        Name              = "Team Site"
                        Description       = "desc"
                        UseParentTopNav   = $false
                        UniquePermissions = $true
                    }

                    $web = [pscustomobject] @{
                        Url           = $testParams.Url
                        Title         = "Another title"
                        Description   = "Another description"
                        Navigation    = @{ UseShared = $true }
                        HasUniquePerm = $false
                    }

                    $web | Add-Member -Name Update `
                        -MemberType ScriptMethod `
                        -Value { }

                    Mock -CommandName Get-SPWeb -MockWith { $web }
                }

                It "Should return the SPWeb data from the get method" {
                    $result = Get-TargetResource @testParams

                    $result.Ensure | Should -Be "Present"
                    $result.UniquePermissions | Should -Be $false
                    $result.UseParentTopNav | Should -Be $true

                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the values in the set method" {
                    Set-TargetResource @testParams

                    $web.Title | Should -Be $testParams.Name
                    $web.Description | Should -Be $testParams.Description
                    $web.Navigation.UseShared | Should -Be $false
                    $web.HasUniquePerm | Should -Be $true

                    Assert-MockCalled New-Object
                }
            }

            Context -Name "The SPWeb exists and the request access settings need to be set" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Url                = "http://site.sharepoint.com/sites/web"
                        RequestAccessEmail = "valid@contoso.com"
                    }

                    $web = [pscustomobject] @{
                        Url                = $testParams.Url
                        HasUniquePerm      = $true
                        RequestAccessEmail = "notvalid@contoso.com"
                    }

                    $web | Add-Member -Name Update `
                        -MemberType ScriptMethod `
                        -Value { }

                    Mock -CommandName Get-SPWeb -MockWith { $web }
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the values in the set method" {
                    Set-TargetResource @testParams

                    $web.RequestAccessEmail | Should -Be $testParams.RequestAccessEmail

                    Assert-MockCalled New-Object
                }
            }

            Context -Name "The SPWeb exists and the request access has to be disabled" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Url                = "http://site.sharepoint.com/sites/web"
                        RequestAccessEmail = ""
                    }

                    $web = [pscustomobject] @{
                        Url                = $testParams.Url
                        HasUniquePerm      = $true
                        RequestAccessEmail = "valid@contoso.com"
                    }

                    $web | Add-Member -Name Update `
                        -MemberType ScriptMethod `
                        -Value { }

                    Mock -CommandName Get-SPWeb -MockWith { $web }
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the values in the set method" {
                    Set-TargetResource @testParams

                    $web.RequestAccessEmail | Should -Be ""

                    Assert-MockCalled New-Object
                }
            }

            Context -Name "The SPWeb exists and does not have unique permission, when request access should be enabled" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Url                = "http://site.sharepoint.com/sites/web"
                        RequestAccessEmail = ""
                        UniquePermissions  = $false
                    }

                    $web = [pscustomobject] @{
                        Url                = $testParams.Url
                        HasUniquePerm      = $false
                        RequestAccessEmail = "valid@contoso.com"
                    }

                    $web | Add-Member -Name Update `
                        -MemberType ScriptMethod `
                        -Value { }

                    Mock -CommandName Get-SPWeb -MockWith { $web }
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }

                It "Should not update the values set method" {
                    Set-TargetResource @testParams

                    $web.RequestAccessEmail | Should -Be "valid@contoso.com"
                    $web.HasUniquePerm | Should -Be $false

                    Assert-MockCalled New-Object
                }
            }

            Context -Name "The SPWeb exists and does have unique permission and should not have unique permissions" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Url                = "http://site.sharepoint.com/sites/web"
                        RequestAccessEmail = ""
                        UniquePermissions  = $false
                    }

                    $web = [pscustomobject] @{
                        Url                = $testParams.Url
                        HasUniquePerm      = $true
                        RequestAccessEmail = "notvalid@contoso.com"
                    }

                    $web | Add-Member -Name Update `
                        -MemberType ScriptMethod `
                        -Value { }

                    Mock -CommandName Get-SPWeb -MockWith { $web }
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the value of unique permissions and not change the request access email in the set method" {
                    Set-TargetResource @testParams

                    $web.RequestAccessEmail | Should -Be "notvalid@contoso.com"
                    $web.HasUniquePerm | Should -Be $false

                    Assert-MockCalled New-Object
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Url                = "http://sharepoint.contoso.com/sites/site/subweb"
                            Name               = "Team Sites"
                            Ensure             = "Present"
                            Description        = "A place to share documents with your team."
                            Template           = "STS#0"
                            Language           = 1033
                            AddToTopNav        = $true
                            UniquePermissions  = $true
                            UseParentTopNav    = $true
                            RequestAccessEmail = "sample@contoso.com"
                        }
                    }

                    Mock -CommandName Get-SPWeb -MockWith {
                        $spWeb = [PSCustomObject]@{
                            Url = "http://sharepoint.contoso.com/sites/site/subweb"
                        }
                        return $spWeb
                    }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    if ($null -eq (Get-Variable -Name 'ExtractionModeValue' -ErrorAction SilentlyContinue))
                    {
                        $Global:ExtractionModeValue = 1
                    }

                    if ($null -eq (Get-Variable -Name 'ComponentsToExtract' -ErrorAction SilentlyContinue))
                    {
                        $Global:ComponentsToExtract = @()
                    }

                    $result = @'
        SPWeb [0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            AddToTopNav          = \$True;
            Description          = "A place to share documents with your team.";
            Ensure               = "Present";
            Language             = 1033;
            Name                 = "Team Sites";
            PsDscRunAsCredential = \$Credsspfarm;
            RequestAccessEmail   = "sample\@contoso.com";
            Template             = "STS\#0";
            UniquePermissions    = \$True;
            Url                  = "http://sharepoint.contoso.com/sites/site/subweb";
            UseParentTopNav      = \$True;
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
