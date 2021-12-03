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
$script:DSCResourceName = 'SPCertificate'
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

                Mock -CommandName Test-Path -MockWith {
                    return $true
                }

                $mockPassword = ConvertTo-SecureString -String 'password' -AsPlainText -Force
                $mockCertPassword = New-Object -TypeName "System.Management.Automation.PSCredential" `
                    -ArgumentList @('CertPassword', $mockPassword)
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
            switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major)
            {
                15
                {
                    Context -Name "All methods throw exceptions as Certificate Management doesn't exist in 2019 and earlier" -Fixture {
                        BeforeAll {
                            $testParams = @{
                                CertificateFilePath = 'C:\Certificate\Intranet.pfx'
                            }
                        }

                        It "Should throw on the get method" {
                            { Get-TargetResource @testParams } | Should -Throw "Certificate Management is not available in SharePoint 2019 or earlier"
                        }

                        It "Should throw on the test method" {
                            { Test-TargetResource @testParams } | Should -Throw "Certificate Management is not available in SharePoint 2019 or earlier"
                        }

                        It "Should throw on the set method" {
                            { Set-TargetResource @testParams } | Should -Throw "Certificate Management is not available in SharePoint 2019 or earlier"
                        }
                    }
                }
                16
                {
                    if ($Global:SPDscHelper.CurrentStubBuildNumber.Build -lt 13000)
                    {
                        Context -Name "All methods throw exceptions as Certificate Management doesn't exist in 2019 and earlier" -Fixture {
                            BeforeAll {
                                $testParams = @{
                                    CertificateFilePath = 'C:\Certificate\Intranet.pfx'
                                }
                            }

                            It "Should throw on the get method" {
                                { Get-TargetResource @testParams } | Should -Throw "Certificate Management is not available in SharePoint 2019 or earlier"
                            }

                            It "Should throw on the test method" {
                                { Test-TargetResource @testParams } | Should -Throw "Certificate Management is not available in SharePoint 2019 or earlier"
                            }

                            It "Should throw on the set method" {
                                { Set-TargetResource @testParams } | Should -Throw "Certificate Management is not available in SharePoint 2019 or earlier"
                            }
                        }
                    }
                    else
                    {
                        Context -Name "CertificateFilePath does not exist" -Fixture {
                            BeforeAll {
                                $testParams = @{
                                    CertificateFilePath = 'C:\Certificate\Intranet.pfx'
                                }

                                Mock -CommandName Test-Path -MockWith {
                                    return $false
                                }
                            }

                            It "Should throw an exception in the get method" {
                                { Get-TargetResource @testParams } | Should -Throw "CertificateFilePath '$($testParams.CertificateFilePath)' not found"
                            }

                            It "Should throw an exception in the set method" {
                                { Set-TargetResource @testParams } | Should -Throw "CertificateFilePath '$($testParams.CertificateFilePath)' not found"
                            }
                        }

                        Context -Name "CertificateFilePath is a PFX, but CertificatePassword is not specified" -Fixture {
                            BeforeAll {
                                $testParams = @{
                                    CertificateFilePath = 'C:\Certificate\Intranet.pfx'
                                }

                                Mock -CommandName Get-ChildItem -MockWith {
                                    return @{
                                        Extension = ".pfx"
                                    }
                                }
                            }

                            It "Should throw an exception in the get method" {
                                { Get-TargetResource @testParams } | Should -Throw "You have to specify a CertificatePassword when CertificateFilePath is a PFX file."
                            }

                            It "Should throw an exception in the set method" {
                                { Set-TargetResource @testParams } | Should -Throw "You have to specify a CertificatePassword when CertificateFilePath is a PFX file."
                            }
                        }

                        Context -Name "CertificateFilePath is not a PFX or CER" -Fixture {
                            BeforeAll {
                                $testParams = @{
                                    CertificateFilePath = 'C:\Certificate\Intranet.abc'
                                }

                                Mock -CommandName Get-ChildItem -MockWith {
                                    return @{
                                        Extension = ".abc"
                                    }
                                }
                            }

                            It "Should throw an exception in the get method" {
                                { Get-TargetResource @testParams } | Should -Throw "Unsupported file extension. Please specify a PFX or CER file"
                            }

                            It "Should throw an exception in the set method" {
                                { Set-TargetResource @testParams } | Should -Throw "Unsupported file extension. Please specify a PFX or CER file"
                            }
                        }

                        Context -Name "The server is not part of SharePoint farm" -Fixture {
                            BeforeAll {
                                $testParams = @{
                                    CertificateFilePath = 'C:\Certificate\Intranet.pfx'
                                    CertificatePassword = $mockCertPassword
                                    Ensure              = 'Present'
                                }

                                Mock -CommandName Get-ChildItem -MockWith {
                                    return @{
                                        Extension = ".pfx"
                                    }
                                }

                                Mock -CommandName Get-SPFarm -MockWith {
                                    throw
                                }
                            }

                            It "Should return Ensure=Absent from the get method" {
                                $result = Get-TargetResource @testParams
                                $result.Ensure | Should -Be 'Absent'
                            }

                            It "Should return false from the test method" {
                                Test-TargetResource @testParams | Should -Be $false
                            }

                            It "Should throw an exception in the set method to say there is no local farm" {
                                { Set-TargetResource @testParams } | Should -Throw "No local SharePoint farm was detected"
                            }
                        }

                        Context -Name "PFX cert is specified, Ensure=Absent and certificate does not exist in SharePoint" -Fixture {
                            BeforeAll {
                                $testParams = @{
                                    CertificateFilePath = 'C:\Certificate\Intranet.pfx'
                                    CertificatePassword = $mockCertPassword
                                    Store               = 'EndEntity'
                                    Ensure              = 'Absent'
                                }

                                Mock -CommandName Get-ChildItem -MockWith {
                                    return @{
                                        Extension = ".pfx"
                                    }
                                }

                                Mock -CommandName Get-SPFarm -MockWith {
                                    return ""
                                }

                                Mock -CommandName New-Object -MockWith {
                                    return @(
                                        @{
                                            Thumbprint = '7CF9E91F141FCA1049F56AB96BE2A1D7D3F9198D'
                                        }
                                    )
                                } -ParameterFilter { $TypeName -eq "System.Security.Cryptography.X509Certificates.X509Certificate2" }

                                Mock -CommandName Get-SPCertificate -MockWith {
                                }
                            }

                            It "Should return Ensure=Absent from the get method" {
                                $result = Get-TargetResource @testParams
                                $result.Ensure | Should -Be 'Absent'
                            }

                            It "Should return true from the test method" {
                                Test-TargetResource @testParams | Should -Be $true
                            }
                        }

                        Context -Name "CER cert is specified, Ensure=Absent and certificate does not exist in SharePoint" -Fixture {
                            BeforeAll {
                                $testParams = @{
                                    CertificateFilePath = 'C:\Certificate\Intranet.cer'
                                    Store               = 'Root'
                                    Ensure              = 'Absent'
                                }

                                Mock -CommandName Get-ChildItem -MockWith {
                                    return @{
                                        Extension = ".cer"
                                    }
                                }

                                Mock -CommandName Get-SPFarm -MockWith {
                                    return ""
                                }

                                Mock -CommandName New-Object -MockWith {
                                    return @(
                                        @{
                                            Thumbprint = '7CF9E91F141FCA1049F56AB96BE2A1D7D3F9198D'
                                        }
                                    )
                                } -ParameterFilter { $TypeName -eq "System.Security.Cryptography.X509Certificates.X509Certificate2" }

                                Mock -CommandName Get-SPCertificate -MockWith {
                                }
                            }

                            It "Should return Ensure=Absent from the get method" {
                                $result = Get-TargetResource @testParams
                                $result.Ensure | Should -Be 'Absent'
                            }

                            It "Should return true from the test method" {
                                Test-TargetResource @testParams | Should -Be $true
                            }
                        }

                        Context -Name "PFX cert is specified, Ensure=Present and certificate does not exist in SharePoint" -Fixture {
                            BeforeAll {
                                $testParams = @{
                                    CertificateFilePath = 'C:\Certificate\Intranet.pfx'
                                    CertificatePassword = $mockCertPassword
                                    Store               = 'EndEntity'
                                    Ensure              = 'Present'
                                }

                                Mock -CommandName Get-ChildItem -MockWith {
                                    return @{
                                        Extension = ".pfx"
                                    }
                                }

                                Mock -CommandName Get-SPFarm -MockWith {
                                    return ""
                                }

                                Mock -CommandName New-Object -MockWith {
                                    return @(
                                        @{
                                            Thumbprint = '7CF9E91F141FCA1049F56AB96BE2A1D7D3F9198D'
                                        }
                                    )
                                } -ParameterFilter { $TypeName -eq "System.Security.Cryptography.X509Certificates.X509Certificate2" }

                                Mock -CommandName Get-SPCertificate -MockWith { }

                                Mock -CommandName Import-SPCertificate -MockWith { }
                            }

                            It "Should return Ensure=Absent from the get method" {
                                $result = Get-TargetResource @testParams
                                $result.Ensure | Should -Be 'Absent'
                            }

                            It "Should return false from the test method" {
                                Test-TargetResource @testParams | Should -Be $false
                            }

                            It "Should import certificate from the set method" {
                                Set-TargetResource @testParams
                                Assert-MockCalled Import-SPCertificate
                            }
                        }

                        Context -Name "CER cert is specified, Ensure=Present and certificate does not exist in SharePoint" -Fixture {
                            BeforeAll {
                                $testParams = @{
                                    CertificateFilePath = 'C:\Certificate\Intranet.cer'
                                    CertificatePassword = $mockCertPassword
                                    Store               = 'Root'
                                    Ensure              = 'Present'
                                }

                                Mock -CommandName Get-ChildItem -MockWith {
                                    return @{
                                        Extension = ".cer"
                                    }
                                }

                                Mock -CommandName Get-SPFarm -MockWith {
                                    return ""
                                }

                                Mock -CommandName New-Object -MockWith {
                                    return @(
                                        @{
                                            Thumbprint = '7CF9E91F141FCA1049F56AB96BE2A1D7D3F9198D'
                                        }
                                    )
                                } -ParameterFilter { $TypeName -eq "System.Security.Cryptography.X509Certificates.X509Certificate2" }

                                Mock -CommandName Get-SPCertificate -MockWith { }

                                Mock -CommandName Import-SPCertificate -MockWith { }
                            }

                            It "Should return Ensure=Absent from the get method" {
                                $result = Get-TargetResource @testParams
                                $result.Ensure | Should -Be 'Absent'
                            }

                            It "Should return false from the test method" {
                                Test-TargetResource @testParams | Should -Be $false
                            }

                            It "Should import certificate from the set method" {
                                Set-TargetResource @testParams
                                Assert-MockCalled Import-SPCertificate
                            }
                        }

                        Context -Name "PFX cert is specified, Ensure=Present and CER certificate does exist in SharePoint" -Fixture {
                            BeforeAll {
                                $testParams = @{
                                    CertificateFilePath = 'C:\Certificate\Intranet.pfx'
                                    CertificatePassword = $mockCertPassword
                                    Store               = 'EndEntity'
                                    Exportable          = $true
                                    Ensure              = 'Present'
                                }

                                Mock -CommandName Get-ChildItem -MockWith {
                                    return @{
                                        Extension = ".pfx"
                                    }
                                }

                                Mock -CommandName Get-SPFarm -MockWith {
                                    return ""
                                }

                                Mock -CommandName New-Object -MockWith {
                                    return @(
                                        @{
                                            Thumbprint = '7CF9E91F141FCA1049F56AB96BE2A1D7D3F9198D'
                                        }
                                    )
                                } -ParameterFilter { $TypeName -eq "System.Security.Cryptography.X509Certificates.X509Certificate2" }

                                Mock -CommandName Get-SPCertificate -MockWith {
                                    return @{
                                        HasPrivateKey = $false
                                        StoreType     = 'Root'
                                    }
                                }

                                Mock -CommandName Import-SPCertificate -MockWith { }
                            }

                            It "Should return Ensure=Absent from the get method" {
                                $result = Get-TargetResource @testParams
                                $result.Ensure | Should -Be 'Absent'
                            }

                            It "Should return false from the test method" {
                                Test-TargetResource @testParams | Should -Be $false
                            }

                            It "Should import certificate from the set method" {
                                Set-TargetResource @testParams
                                Assert-MockCalled Import-SPCertificate
                            }
                        }

                        Context -Name "CER cert is specified, Ensure=Present and PFX certificate does exist in SharePoint" -Fixture {
                            BeforeAll {
                                $testParams = @{
                                    CertificateFilePath = 'C:\Certificate\Intranet.cer'
                                    CertificatePassword = $mockCertPassword
                                    Store               = 'Root'
                                    Ensure              = 'Present'
                                }

                                Mock -CommandName Get-ChildItem -MockWith {
                                    return @{
                                        Extension = ".cer"
                                    }
                                }

                                Mock -CommandName Get-SPFarm -MockWith {
                                    return ""
                                }

                                Mock -CommandName New-Object -MockWith {
                                    return @(
                                        @{
                                            Thumbprint = '7CF9E91F141FCA1049F56AB96BE2A1D7D3F9198D'
                                        }
                                    )
                                } -ParameterFilter { $TypeName -eq "System.Security.Cryptography.X509Certificates.X509Certificate2" }

                                Mock -CommandName Get-SPCertificate -MockWith {
                                    return @{
                                        HasPrivateKey = $true
                                        StoreType     = 'EndEntity'
                                    }
                                }

                                Mock -CommandName Import-SPCertificate -MockWith { }
                            }

                            It "Should return Ensure=Absent from the get method" {
                                $result = Get-TargetResource @testParams
                                $result.Ensure | Should -Be 'Present'
                            }

                            It "Should return false from the test method" {
                                Test-TargetResource @testParams | Should -Be $false
                            }

                            It "Should import certificate from the set method" {
                                Set-TargetResource @testParams
                                Assert-MockCalled Import-SPCertificate
                            }
                        }

                        Context -Name "PFX cert is specified, Ensure=Present and PFX certificate does exist in SharePoint in wrong store" -Fixture {
                            BeforeAll {
                                $testParams = @{
                                    CertificateFilePath = 'C:\Certificate\Intranet.pfx'
                                    CertificatePassword = $mockCertPassword
                                    Store               = 'EndEntity'
                                    Ensure              = 'Present'
                                }

                                Mock -CommandName Get-ChildItem -MockWith {
                                    return @{
                                        Extension = ".pfx"
                                    }
                                }

                                Mock -CommandName Get-SPFarm -MockWith {
                                    return ""
                                }

                                Mock -CommandName New-Object -MockWith {
                                    return @(
                                        @{
                                            Thumbprint = '7CF9E91F141FCA1049F56AB96BE2A1D7D3F9198D'
                                        }
                                    )
                                } -ParameterFilter { $TypeName -eq "System.Security.Cryptography.X509Certificates.X509Certificate2" }

                                Mock -CommandName Get-SPCertificate -MockWith {
                                    return @{
                                        HasPrivateKey = $true
                                        StoreType     = 'Root'
                                    }
                                }

                                Mock -CommandName Move-SPCertificate -MockWith { }
                            }

                            It "Should return Ensure=Absent from the get method" {
                                $result = Get-TargetResource @testParams
                                $result.Ensure | Should -Be 'Present'
                            }

                            It "Should return false from the test method" {
                                Test-TargetResource @testParams | Should -Be $false
                            }

                            It "Should import certificate from the set method" {
                                Set-TargetResource @testParams
                                Assert-MockCalled Move-SPCertificate
                            }
                        }

                        Context -Name "CER cert is specified, Ensure=Present and CER certificate does exist in SharePoint in wrong store" -Fixture {
                            BeforeAll {
                                $testParams = @{
                                    CertificateFilePath = 'C:\Certificate\Intranet.cer'
                                    Store               = 'Root'
                                    Ensure              = 'Present'
                                }

                                Mock -CommandName Get-ChildItem -MockWith {
                                    return @{
                                        Extension = ".cer"
                                    }
                                }

                                Mock -CommandName Get-SPFarm -MockWith {
                                    return ""
                                }

                                Mock -CommandName New-Object -MockWith {
                                    return @(
                                        @{
                                            Thumbprint = '7CF9E91F141FCA1049F56AB96BE2A1D7D3F9198D'
                                        }
                                    )
                                } -ParameterFilter { $TypeName -eq "System.Security.Cryptography.X509Certificates.X509Certificate2" }

                                Mock -CommandName Get-SPCertificate -MockWith {
                                    return @{
                                        HasPrivateKey = $false
                                        StoreType     = 'EndEntity'
                                    }
                                }

                                Mock -CommandName Move-SPCertificate -MockWith { }
                            }

                            It "Should return Ensure=Absent from the get method" {
                                $result = Get-TargetResource @testParams
                                $result.Ensure | Should -Be 'Present'
                            }

                            It "Should return false from the test method" {
                                Test-TargetResource @testParams | Should -Be $false
                            }

                            It "Should move certificate from the set method" {
                                Set-TargetResource @testParams
                                Assert-MockCalled Move-SPCertificate
                            }
                        }

                        Context -Name "PFX cert is specified, Ensure=Present and multiple certificates exist in SharePoint" -Fixture {
                            BeforeAll {
                                $testParams = @{
                                    CertificateFilePath = 'C:\Certificate\Intranet.pfx'
                                    CertificatePassword = $mockCertPassword
                                    Store               = 'EndEntity'
                                    Ensure              = 'Present'
                                }

                                Mock -CommandName Get-ChildItem -MockWith {
                                    return @{
                                        Extension = ".pfx"
                                    }
                                }

                                Mock -CommandName Get-SPFarm -MockWith {
                                    return ""
                                }

                                Mock -CommandName New-Object -MockWith {
                                    return @(
                                        @{
                                            Thumbprint = '7CF9E91F141FCA1049F56AB96BE2A1D7D3F9198D'
                                        }
                                    )
                                } -ParameterFilter { $TypeName -eq "System.Security.Cryptography.X509Certificates.X509Certificate2" }

                                Mock -CommandName Get-SPCertificate -MockWith {
                                    return @(
                                        @{
                                            HasPrivateKey = $false
                                            StoreType     = 'Root'
                                        }
                                        @{
                                            HasPrivateKey = $true
                                            StoreType     = 'Intermediate'
                                        }
                                    )
                                }

                                Mock -CommandName Import-SPCertificate -MockWith { }
                            }

                            It "Should return Ensure=Absent from the get method" {
                                $result = Get-TargetResource @testParams
                                $result.Ensure | Should -Be 'Absent'
                            }

                            It "Should return false from the test method" {
                                Test-TargetResource @testParams | Should -Be $false
                            }

                            It "Should import certificate from the set method" {
                                Set-TargetResource @testParams
                                Assert-MockCalled Import-SPCertificate
                            }
                        }

                        Context -Name "CER cert is specified, Ensure=Present and multiple certificates exist in SharePoint" -Fixture {
                            BeforeAll {
                                $testParams = @{
                                    CertificateFilePath = 'C:\Certificate\Intranet.cer'
                                    Store               = 'Root'
                                    Ensure              = 'Present'
                                }

                                Mock -CommandName Get-ChildItem -MockWith {
                                    return @{
                                        Extension = ".cer"
                                    }
                                }

                                Mock -CommandName Get-SPFarm -MockWith {
                                    return ""
                                }

                                Mock -CommandName New-Object -MockWith {
                                    return @(
                                        @{
                                            Thumbprint = '7CF9E91F141FCA1049F56AB96BE2A1D7D3F9198D'
                                        }
                                    )
                                } -ParameterFilter { $TypeName -eq "System.Security.Cryptography.X509Certificates.X509Certificate2" }

                                Mock -CommandName Get-SPCertificate -MockWith {
                                    return @(
                                        @{
                                            HasPrivateKey = $false
                                            StoreType     = 'Root'
                                        }
                                        @{
                                            HasPrivateKey = $true
                                            StoreType     = 'Intermediate'
                                        }
                                    )
                                }

                                Mock -CommandName Import-SPCertificate -MockWith { }
                            }

                            It "Should return Ensure=Absent from the get method" {
                                $result = Get-TargetResource @testParams
                                $result.Ensure | Should -Be 'Present'
                            }

                            It "Should return false from the test method" {
                                Test-TargetResource @testParams | Should -Be $true
                            }
                        }

                        Context -Name "CER cert is specified, Ensure=Present and PFX certificate does exist in SharePoint" -Fixture {
                            BeforeAll {
                                $testParams = @{
                                    CertificateFilePath = 'C:\Certificate\Intranet.cer'
                                    Store               = 'Root'
                                    Ensure              = 'Present'
                                }

                                Mock -CommandName Get-ChildItem -MockWith {
                                    return @{
                                        Extension = ".cer"
                                    }
                                }

                                Mock -CommandName Get-SPFarm -MockWith {
                                    return ""
                                }

                                Mock -CommandName New-Object -MockWith {
                                    return @(
                                        @{
                                            Thumbprint = '7CF9E91F141FCA1049F56AB96BE2A1D7D3F9198D'
                                        }
                                    )
                                } -ParameterFilter { $TypeName -eq "System.Security.Cryptography.X509Certificates.X509Certificate2" }

                                Mock -CommandName Get-SPCertificate -MockWith {
                                    return @(
                                        @{
                                            HasPrivateKey = $false
                                            StoreType     = 'Intermediate'
                                        }
                                        @{
                                            HasPrivateKey = $true
                                            StoreType     = 'EndEntity'
                                        }
                                    )
                                }

                                Mock -CommandName Import-SPCertificate -MockWith { }
                            }

                            It "Should return Ensure=Absent from the get method" {
                                $result = Get-TargetResource @testParams
                                $result.Ensure | Should -Be 'Absent'
                            }

                            It "Should return false from the test method" {
                                Test-TargetResource @testParams | Should -Be $false
                            }

                            It "Should import certificate from the set method" {
                                Set-TargetResource @testParams
                                Assert-MockCalled Import-SPCertificate
                            }
                        }

                        Context -Name "PFX cert is specified, Ensure=Present and multiple certificates exist, but cert does not have private key" -Fixture {
                            BeforeAll {
                                $testParams = @{
                                    CertificateFilePath = 'C:\Certificate\Intranet.pfx'
                                    CertificatePassword = $mockCertPassword
                                    Store               = 'EndEntity'
                                    Ensure              = 'Present'
                                }

                                Mock -CommandName Get-ChildItem -MockWith {
                                    return @{
                                        Extension = ".pfx"
                                    }
                                }

                                Mock -CommandName Get-SPFarm -MockWith {
                                    return ""
                                }

                                Mock -CommandName New-Object -MockWith {
                                    return @(
                                        @{
                                            Thumbprint = '7CF9E91F141FCA1049F56AB96BE2A1D7D3F9198D'
                                        }
                                    )
                                } -ParameterFilter { $TypeName -eq "System.Security.Cryptography.X509Certificates.X509Certificate2" }

                                Mock -CommandName Get-SPCertificate -MockWith {
                                    return @(
                                        @{
                                            HasPrivateKey = $false
                                            StoreType     = 'EndEntity'
                                        }
                                        @{
                                            HasPrivateKey = $false
                                            StoreType     = 'Root'
                                        }
                                    )
                                }

                                Mock -CommandName Import-SPCertificate -MockWith { }
                            }

                            It "Should return Ensure=Absent from the get method" {
                                $result = Get-TargetResource @testParams
                                $result.Ensure | Should -Be 'Absent'
                            }

                            It "Should return false from the test method" {
                                Test-TargetResource @testParams | Should -Be $false
                            }

                            It "Should import certificate from the set method" {
                                Set-TargetResource @testParams
                                Assert-MockCalled Import-SPCertificate
                            }
                        }
                        Context -Name "PFX cert is specified, Ensure=Absent, but certificate does exist in SharePoint" -Fixture {
                            BeforeAll {
                                $testParams = @{
                                    CertificateFilePath = 'C:\Certificate\Intranet.pfx'
                                    CertificatePassword = $mockCertPassword
                                    Store               = 'EndEntity'
                                    Ensure              = 'Absent'
                                }

                                Mock -CommandName Get-ChildItem -MockWith {
                                    return @{
                                        Extension = ".pfx"
                                    }
                                }

                                Mock -CommandName Get-SPFarm -MockWith {
                                    return ""
                                }

                                Mock -CommandName New-Object -MockWith {
                                    return @(
                                        @{
                                            Thumbprint = '7CF9E91F141FCA1049F56AB96BE2A1D7D3F9198D'
                                        }
                                    )
                                } -ParameterFilter { $TypeName -eq "System.Security.Cryptography.X509Certificates.X509Certificate2" }

                                Mock -CommandName Get-SPCertificate -MockWith {
                                    return @(
                                        @{
                                            HasPrivateKey = $true
                                            StoreType     = 'EndEntity'
                                        }
                                    )
                                }

                                Mock -CommandName Remove-SPCertificate -MockWith { }
                            }

                            It "Should return Ensure=Absent from the get method" {
                                $result = Get-TargetResource @testParams
                                $result.Ensure | Should -Be 'Present'
                            }

                            It "Should return false from the test method" {
                                Test-TargetResource @testParams | Should -Be $false
                            }

                            It "Should remove the certificate from the set method" {
                                Set-TargetResource @testParams
                                Assert-MockCalled Remove-SPCertificate
                            }
                        }

                        Context -Name "CER cert is specified, Ensure=Absent, but certificate does exist in SharePoint" -Fixture {
                            BeforeAll {
                                $testParams = @{
                                    CertificateFilePath = 'C:\Certificate\Intranet.cer'
                                    CertificatePassword = $mockCertPassword
                                    Store               = 'Root'
                                    Ensure              = 'Absent'
                                }

                                Mock -CommandName Get-ChildItem -MockWith {
                                    return @{
                                        Extension = ".cer"
                                    }
                                }

                                Mock -CommandName Get-SPFarm -MockWith {
                                    return ""
                                }

                                Mock -CommandName New-Object -MockWith {
                                    return @(
                                        @{
                                            Thumbprint = '7CF9E91F141FCA1049F56AB96BE2A1D7D3F9198D'
                                        }
                                    )
                                } -ParameterFilter { $TypeName -eq "System.Security.Cryptography.X509Certificates.X509Certificate2" }

                                Mock -CommandName Get-SPCertificate -MockWith {
                                    return @(
                                        @{
                                            HasPrivateKey = $false
                                            StoreType     = 'Root'
                                        }
                                    )
                                }

                                Mock -CommandName Remove-SPCertificate -MockWith { }
                            }

                            It "Should return Ensure=Absent from the get method" {
                                $result = Get-TargetResource @testParams
                                $result.Ensure | Should -Be 'Present'
                            }

                            It "Should return false from the test method" {
                                Test-TargetResource @testParams | Should -Be $false
                            }

                            It "Should remove the certificate from the set method" {
                                Set-TargetResource @testParams
                                Assert-MockCalled Remove-SPCertificate
                            }
                        }

                        Context -Name "Running ReverseDsc Export" -Fixture {
                            BeforeAll {
                                Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")

                                Mock -CommandName Write-Host -MockWith { }

                                Mock -CommandName Get-SPCertificate -MockWith {
                                    return @(
                                        @{
                                            Subject       = "intranet.contoso.com"
                                            HasPrivateKey = $true
                                            Exportable    = $true
                                            StoreType     = "EndEntity"
                                        },
                                        @{
                                            Subject       = "root.contoso.com"
                                            HasPrivateKey = $false
                                            Exportable    = $false
                                            StoreType     = "Root"
                                        }
                                    )
                                }

                                Mock -CommandName Export-SPCertificate -MockWith { }

                                Mock -CommandName Get-TargetResource -MockWith {
                                    if ($global:SPDscCertCounter -eq 1)
                                    {
                                        $global:SPDscCertCounter++
                                        return @{
                                            CertificateFilePath = 'C:\Certificates\Intranet.pfx'
                                            CertificatePassword = $mockCertPassword
                                            Store               = 'EndEntity'
                                            Exportable          = $false
                                            Ensure              = "Present"
                                        }
                                    }
                                    else
                                    {
                                        $global:SPDscCertCounter++
                                        return @{
                                            CertificateFilePath = 'C:\Certificates\Intranet.cer'
                                            CertificatePassword = $mockCertPassword
                                            Store               = 'Root'
                                            Exportable          = $false
                                            Ensure              = "Present"
                                        }
                                    }
                                }

                                if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                                {
                                    $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                                    $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                                }

                                $result = @'
        SPCertificate [0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            CertificateFilePath  = "C:\\Certificates\\Intranet.pfx";
            CertificatePassword  = \$Credsspfarm;
            Ensure               = "Present";
            Exportable           = \$False;
            PsDscRunAsCredential = \$Credsspfarm;
            Store                = "EndEntity";
        }
        SPCertificate [0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            CertificateFilePath  = "C:\\Certificates\\Intranet.cer";
            CertificatePassword  = \$Credsspfarm;
            Ensure               = "Present";
            Exportable           = \$False;
            PsDscRunAsCredential = \$Credsspfarm;
            Store                = "Root";
        }

'@
                            }

                            It "Should return valid DSC block from the Export method" {
                                $global:SPDscCertCounter = 1
                                Export-TargetResource | Should -Match $result
                            }
                        }
                    }
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
