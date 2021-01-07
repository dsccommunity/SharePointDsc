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
$script:DSCResourceName = 'SPSearchFileType'
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
                $getTypeFullName = "Microsoft.Office.Server.Search.Administration.SearchServiceApplication"

                # Mocks for all contexts
                Mock -CommandName Remove-SPEnterpriseSearchFileFormat -MockWith { }
                Mock -CommandName New-SPEnterpriseSearchFileFormat -MockWith { }
                Mock -CommandName Set-SPEnterpriseSearchFileFormatState -MockWith { }

                Mock -CommandName Get-SPServiceApplication -MockWith {
                    return @(
                        New-Object -TypeName "Object" |
                            Add-Member -MemberType ScriptMethod `
                                -Name GetType `
                                -Value {
                                New-Object -TypeName "Object" |
                                    Add-Member -MemberType NoteProperty `
                                        -Name FullName `
                                        -Value $getTypeFullName `
                                        -PassThru
                                } `
                                    -PassThru -Force)
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

            Context -Name "When no service applications exist in the current farm" -Fixture {
                BeforeAll {
                    $testParams = @{
                        FileType       = "abc"
                        Description    = "ABC"
                        MimeType       = "application/abc"
                        ServiceAppName = "Search Service Application"
                        Ensure         = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        return $null
                    }
                }

                It "Should return absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Service Application $($testParams.ServiceAppName) is not found"
                }
            }

            Context -Name "When service applications exist in the current farm but the specific search app does not" -Fixture {
                BeforeAll {
                    $testParams = @{
                        FileType       = "abc"
                        Description    = "ABC"
                        MimeType       = "application/abc"
                        ServiceAppName = "Search Service Application"
                        Ensure         = "Present"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith {
                        return @(@{
                                TypeName = "Some other service app type"
                            })
                    }
                }

                It "Should return absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Service Application $($testParams.ServiceAppName) is not a search service application"
                }
            }

            Context -Name "When Ensure=Present, but Description and MimeType parameters are missing" -Fixture {
                BeforeAll {
                    $testParams = @{
                        FileType       = "abc"
                        ServiceAppName = "Search Service Application"
                        Ensure         = "Present"
                    }
                }

                It "Should return absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Ensure is configured as Present, but MimeType and/or Description is missing"
                }
            }

            Context -Name "When a file type does not exists, but should be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        FileType       = "abc"
                        Description    = "ABC"
                        MimeType       = "application/abc"
                        ServiceAppName = "Search Service Application"
                        Ensure         = "Present"
                    }

                    Mock -CommandName Get-SPEnterpriseSearchFileFormat -MockWith {
                        return $null
                    }
                }

                It "Should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create a new file type in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPEnterpriseSearchFileFormat
                }
            }

            Context -Name "When a file type does not exists, but should be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        FileType       = "abc"
                        ServiceAppName = "Search Service Application"
                        Ensure         = "Absent"
                    }

                    Mock -CommandName Get-SPEnterpriseSearchFileFormat -MockWith {
                        return @{
                            Identity = $testParams.FileType
                            Name     = "ABC"
                            MimeType = "application/abc"
                            Enabled  = $true
                        }
                    }
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should remove the file type in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-SPEnterpriseSearchFileFormat
                }
            }

            Context -Name "When a file type exists, but with the incorrect settings" -Fixture {
                BeforeAll {
                    $testParams = @{
                        FileType       = "abc"
                        ServiceAppName = "Search Service Application"
                        Description    = "XYZ"
                        MimeType       = "application/xyz"
                        Ensure         = "Present"
                    }

                    Mock -CommandName Get-SPEnterpriseSearchFileFormat -MockWith {
                        return @{
                            Identity = $testParams.FileType
                            Name     = "ABC"
                            MimeType = "application/abc"
                            Enabled  = $true
                        }
                    }
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should recreate the file type in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-SPEnterpriseSearchFileFormat
                    Assert-MockCalled New-SPEnterpriseSearchFileFormat
                }
            }

            Context -Name "When a file type exists, but with the incorrect state" -Fixture {
                BeforeAll {
                    $testParams = @{
                        FileType       = "abc"
                        ServiceAppName = "Search Service Application"
                        Description    = "ABC"
                        MimeType       = "application/abc"
                        Enabled        = $true
                        Ensure         = "Present"
                    }

                    Mock -CommandName Get-SPEnterpriseSearchFileFormat -MockWith {
                        return @{
                            Identity = $testParams.FileType
                            Name     = "ABC"
                            MimeType = "application/abc"
                            Enabled  = $false
                        }
                    }
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should enable the file type in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-SPEnterpriseSearchFileFormatState
                }
            }

            Context -Name "When a file type exists and is configured correctly" -Fixture {
                BeforeAll {
                    $testParams = @{
                        FileType       = "abc"
                        ServiceAppName = "Search Service Application"
                        Description    = "ABC"
                        MimeType       = "application/abc"
                        Ensure         = "Present"
                    }

                    Mock -CommandName Get-SPEnterpriseSearchFileFormat -MockWith {
                        return @{
                            Identity = $testParams.FileType
                            Name     = "ABC"
                            MimeType = "application/abc"
                            Enabled  = $true
                        }
                    }
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return true when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            FileType       = "pdf"
                            ServiceAppName = "Search Service Application"
                            Description    = "PDF"
                            MimeType       = "application/pdf"
                            Ensure         = "Present"
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

                    $result = @'
        SPSearchFileType [0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            Description          = "PDF";
            Ensure               = "Present";
            FileType             = "pdf";
            MimeType             = "application/pdf";
            PsDscRunAsCredential = \$Credsspfarm;
            ServiceAppName       = "Search Service Application";
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
