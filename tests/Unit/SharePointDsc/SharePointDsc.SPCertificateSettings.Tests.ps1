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
$script:DSCResourceName = 'SPCertificateSettings'
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
                                IsSingleInstance = 'Yes'
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
                                    IsSingleInstance = 'Yes'
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
                        Context -Name "CertificateExpirationAttentionThreshold is lower than CertificateExpirationWarningThreshold" -Fixture {
                            BeforeAll {
                                $testParams = @{
                                    IsSingleInstance                        = 'Yes'
                                    CertificateExpirationAttentionThreshold = 10
                                    CertificateExpirationWarningThreshold   = 15
                                }
                            }

                            It "Should throw an exception in the set method" {
                                { Set-TargetResource @testParams } | Should -Throw "CertificateExpirationAttentionThreshold should be larger than CertificateExpirationWarningThreshold"
                            }
                        }

                        Context -Name "The server is not part of SharePoint farm" -Fixture {
                            BeforeAll {
                                $testParams = @{
                                    IsSingleInstance                        = 'Yes'
                                    OrganizationalUnit                      = 'IT'
                                    Organization                            = 'Contoso'
                                    Locality                                = 'Seattle'
                                    State                                   = 'Washington'
                                    Country                                 = 'US'
                                    KeyAlgorithm                            = 'RSA'
                                    KeySize                                 = 2048
                                    EllipticCurve                           = 'nistP256'
                                    HashAlgorithm                           = 'SHA256'
                                    RsaSignaturePadding                     = 'Pkcs1'
                                    CertificateExpirationAttentionThreshold = 60
                                    CertificateExpirationWarningThreshold   = 15
                                    CertificateExpirationErrorThreshold     = 15
                                }

                                Mock -CommandName Get-SPFarm -MockWith {
                                    throw "Unable to detect local farm"
                                }

                                Mock -CommandName Set-SPCertificateSettings -MockWith {}
                            }

                            It "Should return null from the get method" {
                                $result = Get-TargetResource @testParams
                                $result.Count | Should -Be 1
                            }

                            It "Should return false from the test method" {
                                Test-TargetResource @testParams | Should -Be $false
                            }

                            It "Should throw an exception in the set method to say there is no local farm" {
                                { Set-TargetResource @testParams } | Should -Throw "No local SharePoint farm was detected"
                            }
                        }

                        Context -Name "The server is in a farm and the incorrect settings have been applied" -Fixture {
                            BeforeAll {
                                $testParams = @{
                                    IsSingleInstance                        = 'Yes'
                                    OrganizationalUnit                      = 'IT'
                                    Organization                            = 'Contoso'
                                    Locality                                = 'Seattle'
                                    State                                   = 'Washington'
                                    Country                                 = 'US'
                                    KeyAlgorithm                            = 'RSA'
                                    KeySize                                 = 2048
                                    EllipticCurve                           = 'nistP256'
                                    HashAlgorithm                           = 'SHA256'
                                    RsaSignaturePadding                     = 'Pkcs1'
                                    CertificateExpirationAttentionThreshold = 60
                                    CertificateExpirationWarningThreshold   = 15
                                    CertificateExpirationErrorThreshold     = 15
                                }

                                Mock -CommandName Get-SPCertificateSettings -MockWith {
                                    $returnVal = @{
                                        DefaultOrganizationalUnit                   = ''
                                        DefaultOrganization                         = ''
                                        DefaultLocality                             = ''
                                        DefaultState                                = ''
                                        DefaultCountry                              = ''
                                        DefaultKeyAlgorithm                         = 'RSA'
                                        DefaultRsaKeySize                           = 2048
                                        DefaultEllipticCurve                        = 'nistP256'
                                        DefaultHashAlgorithm                        = 'SHA256'
                                        DefaultRsaSignaturePadding                  = 'Pkcs1'
                                        CertificateExpirationAttentionThresholdDays = 60
                                        CertificateExpirationWarningThresholdDays   = 15
                                        CertificateExpirationErrorThresholdDays     = 15
                                    }
                                    return $returnVal
                                }
                                Mock -CommandName Get-SPFarm -MockWith { return @{ } }
                                Mock -CommandName Set-SPCertificateSettings -MockWith {}
                            }

                            It "Should return values from the get method" {
                                $result = Get-TargetResource @testParams
                                $result.KeySize | Should -Be 2048
                                $result.OrganizationalUnit  | Should -BeNullOrEmpty
                            }

                            It "Should return false from the test method" {
                                Test-TargetResource @testParams | Should -Be $false
                            }

                            It "Should update the certificate settings" {
                                Set-TargetResource @testParams
                                Assert-MockCalled Set-SPCertificateSettings
                            }
                        }

                        Context -Name "The server is in a farm and the incorrect contacts have been applied" -Fixture {
                            BeforeAll {
                                $testParams = @{
                                    IsSingleInstance                = 'Yes'
                                    CertificateNotificationContacts = 'admin@contoso.com'
                                }

                                Mock -CommandName Get-SPCertificateSettings -MockWith {
                                    $returnVal = @{
                                        DefaultOrganizationalUnit                   = ''
                                        DefaultOrganization                         = ''
                                        DefaultLocality                             = ''
                                        DefaultState                                = ''
                                        DefaultCountry                              = ''
                                        DefaultKeyAlgorithm                         = 'RSA'
                                        DefaultRsaKeySize                           = 2048
                                        DefaultEllipticCurve                        = 'nistP256'
                                        DefaultHashAlgorithm                        = 'SHA256'
                                        DefaultRsaSignaturePadding                  = 'Pkcs1'
                                        CertificateExpirationAttentionThresholdDays = 60
                                        CertificateExpirationWarningThresholdDays   = 15
                                        CertificateExpirationErrorThresholdDays     = 15
                                        CertificateNotificationContacts             = @(
                                            @{
                                                Address = 'wrong@contoso.com'
                                            }
                                        )
                                    }
                                    return $returnVal
                                }
                                Mock -CommandName Get-SPFarm -MockWith { return @{ } }
                                Mock -CommandName Get-SPCertificateNotificationContact -MockWith {
                                    return @(
                                        @{
                                            Address = 'wrong@contoso.com'
                                        }
                                    )
                                }
                                Mock -CommandName Add-SPCertificateNotificationContact -MockWith {}
                                Mock -CommandName Remove-SPCertificateNotificationContact -MockWith {}
                            }

                            It "Should return values from the get method" {
                                $result = Get-TargetResource @testParams
                                $result.CertificateNotificationContacts.Count | Should -Be 1
                            }

                            It "Should return false from the test method" {
                                Test-TargetResource @testParams | Should -Be $false
                            }

                            It "Should update the certificate settings" {
                                Set-TargetResource @testParams
                                Assert-MockCalled Add-SPCertificateNotificationContact
                                Assert-MockCalled Remove-SPCertificateNotificationContact
                            }
                        }

                        Context -Name "The server is in a farm and the correct settings have been applied" -Fixture {
                            BeforeAll {
                                $testParams = @{
                                    IsSingleInstance                        = 'Yes'
                                    OrganizationalUnit                      = 'IT'
                                    Organization                            = 'Contoso'
                                    Locality                                = 'Seattle'
                                    State                                   = 'Washington'
                                    Country                                 = 'US'
                                    KeyAlgorithm                            = 'RSA'
                                    KeySize                                 = 2048
                                    EllipticCurve                           = 'nistP256'
                                    HashAlgorithm                           = 'SHA256'
                                    RsaSignaturePadding                     = 'Pkcs1'
                                    CertificateExpirationAttentionThreshold = 60
                                    CertificateExpirationWarningThreshold   = 15
                                    CertificateExpirationErrorThreshold     = 15
                                }

                                Mock -CommandName Get-SPCertificateSettings -MockWith {
                                    $returnVal = @{
                                        DefaultOrganizationalUnit                   = 'IT'
                                        DefaultOrganization                         = 'Contoso'
                                        DefaultLocality                             = 'Seattle'
                                        DefaultState                                = 'Washington'
                                        DefaultCountry                              = 'US'
                                        DefaultKeyAlgorithm                         = 'RSA'
                                        DefaultRsaKeySize                           = 2048
                                        DefaultEllipticCurve                        = 'nistP256'
                                        DefaultHashAlgorithm                        = 'SHA256'
                                        DefaultRsaSignaturePadding                  = 'Pkcs1'
                                        CertificateExpirationAttentionThresholdDays = 60
                                        CertificateExpirationWarningThresholdDays   = 15
                                        CertificateExpirationErrorThresholdDays     = 15
                                    }
                                    return $returnVal
                                }
                                Mock -CommandName Get-SPFarm -MockWith { return @{ } }
                            }

                            It "Should return values from the get method" {
                                $result = Get-TargetResource @testParams
                                $result.KeySize | Should -Be 2048
                                $result.OrganizationalUnit  | Should -Be 'IT'
                            }

                            It "Should return true from the test method" {
                                Test-TargetResource @testParams | Should -Be $true
                            }
                        }

                        Context -Name "Running ReverseDsc Export" -Fixture {
                            BeforeAll {
                                Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")

                                Mock -CommandName Write-Host -MockWith { }

                                Mock -CommandName Get-TargetResource -MockWith {
                                    return @{
                                        IsSingleInstance                        = 'Yes'
                                        OrganizationalUnit                      = 'IT'
                                        Organization                            = 'Contoso'
                                        Locality                                = 'Seattle'
                                        State                                   = 'Washington'
                                        Country                                 = 'US'
                                        KeyAlgorithm                            = 'RSA'
                                        KeySize                                 = 2048
                                        EllipticCurve                           = 'nistP256'
                                        HashAlgorithm                           = 'SHA256'
                                        RsaSignaturePadding                     = 'Pkcs1'
                                        CertificateExpirationAttentionThreshold = 60
                                        CertificateExpirationWarningThreshold   = 15
                                        CertificateExpirationErrorThreshold     = 15
                                        CertificateNotificationContacts         = 'admin@contoso.com'
                                    }
                                }

                                if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                                {
                                    $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                                    $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                                }

                                $result = @'
        SPCertificateSettings CertificateSettings
        {
            CertificateExpirationAttentionThreshold = 60;
            CertificateExpirationErrorThreshold     = 15;
            CertificateExpirationWarningThreshold   = 15;
            CertificateNotificationContacts         = "admin@contoso.com";
            Country                                 = "US";
            EllipticCurve                           = "nistP256";
            HashAlgorithm                           = "SHA256";
            IsSingleInstance                        = "Yes";
            KeyAlgorithm                            = "RSA";
            KeySize                                 = 2048;
            Locality                                = "Seattle";
            Organization                            = "Contoso";
            OrganizationalUnit                      = "IT";
            PsDscRunAsCredential                    = $Credsspfarm;
            RsaSignaturePadding                     = "Pkcs1";
            State                                   = "Washington";
        }

'@
                            }

                            It "Should return valid DSC block from the Export method" {
                                Export-TargetResource | Should -Be $result
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
