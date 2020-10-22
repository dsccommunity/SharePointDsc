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
$script:DSCResourceName = 'SPTrustedSecurityTokenIssuer'
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

                # global variables
                $SPTrustName = "HighTrust"
                $SPTrustDescription = "HighTrust fake"
                $SPTrustRegisteredIssuerNameIdentifier = "22222222-2222-2222-2222-222222222222"
                $SPTrustSigningCertificateThumbprint = "123ABCFACE123ABCFACE123ABCFACE123ABCFACE"
                $SPTrustSigningCertificateFilePath = "F:\Data\DSC\FakeSigning.cer"
                $SPTrustAuthenticationRealm = [Guid]::New("D683A811-9F0E-49BC-8BF1-DC1C5FEC8447")

                # Mocks for all contexts
                Mock -CommandName New-SPTrustedSecurityTokenIssuer -MockWith {
                    $sptrust = [pscustomobject]@{
                        RegisteredIssuerName = "$SPTrustRegisteredIssuerNameIdentifier@$(Get-SPAuthenticationRealm)"
                        Name                 = $testParams.Name
                        Description          = $SPTrustDescription
                    }
                    $sptrust | Add-Member -Name Update -MemberType ScriptMethod -Value { }
                    return $sptrust
                }

                Mock -CommandName Get-ChildItem -MockWith {
                    return @(
                        @{
                            Thumbprint = $SPTrustSigningCertificateThumbprint
                        }
                    )
                } -ParameterFilter { $Path -eq "Cert:\LocalMachine\My" }

                Mock -CommandName New-Object -MockWith {
                    return @(
                        @{
                            Thumbprint = $SPTrustSigningCertificateThumbprint
                        }
                    )
                } -ParameterFilter { $TypeName -eq "System.Security.Cryptography.X509Certificates.X509Certificate2" }
                #} -ParameterFilter { $TypeName -eq "System.Security.Cryptography.X509Certificates.X509Certificate2" -and $PSBoundParameters[0] -match $SPTrustSigningCertificateFilePath }

                Mock -CommandName Get-SPAuthenticationRealm -MockWith {
                    return $SPTrustAuthenticationRealm
                }

                Mock -CommandName Set-SPTrustedSecurityTokenIssuer -MockWith { }

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
            Context -Name "The SPTrustedSecurityTokenIssuer does not exist and should be created, using a signing certificate in the certificate store and the realm of the farm" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                           = $SPTrustName
                        Description                    = $SPTrustDescription
                        RegisteredIssuerNameIdentifier = $SPTrustRegisteredIssuerNameIdentifier
                        RegisteredIssuerNameRealm      = ""
                        SigningCertificateThumbprint   = $SPTrustSigningCertificateThumbprint
                        IsTrustBroker                  = $true
                        Ensure                         = "Present"
                    }
                }

                It "Should create the SPTrustedSecurityTokenIssuer using the realm of the farm" {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName "New-SPTrustedSecurityTokenIssuer"
                    Assert-MockCalled -Times 1 -CommandName "Get-SPAuthenticationRealm"
                }
            }

            Context -Name "The SPTrustedSecurityTokenIssuer does not exist and should be created, using a signing certificate in the file system and the realm of the farm" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                           = $SPTrustName
                        Description                    = $SPTrustDescription
                        RegisteredIssuerNameIdentifier = $SPTrustRegisteredIssuerNameIdentifier
                        RegisteredIssuerNameRealm      = $null
                        SigningCertificateFilePath     = $SPTrustSigningCertificateFilePath
                        IsTrustBroker                  = $true
                        Ensure                         = "Present"
                    }
                }

                It "Should create the SPTrustedSecurityTokenIssuer using the realm of the farm" {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName "New-SPTrustedSecurityTokenIssuer"
                    Assert-MockCalled -Times 1 -CommandName "Get-SPAuthenticationRealm"
                }
            }

            Context -Name "The SPTrustedSecurityTokenIssuer does not exist and should be created, using a signing certificate in the file system, SigningCertificateThumbprint and the realm of the farm" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                           = $SPTrustName
                        Description                    = $SPTrustDescription
                        RegisteredIssuerNameIdentifier = $SPTrustRegisteredIssuerNameIdentifier
                        RegisteredIssuerNameRealm      = $SPTrustSigningCertificateThumbprint
                        SigningCertificateFilePath     = $SPTrustSigningCertificateFilePath
                        IsTrustBroker                  = $true
                        Ensure                         = "Present"
                    }

                    Mock -CommandName New-Object -MockWith {
                        $retVal = [pscustomobject]@{
                            Subject       = "CN=CertIdentifer"
                            Thumbprint    = $SPTrustSigningCertificateThumbprint
                            HasPrivateKey = $false
                        }
                        Add-Member -InputObject $retVal -MemberType ScriptMethod Import { }

                        return $retVal
                    } -ParameterFilter { $TypeName -eq "System.Security.Cryptography.X509Certificates.X509Certificate2" }
                }

                It "Should create the SPTrustedSecurityTokenIssuer using the realm of the farm" {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName "New-SPTrustedSecurityTokenIssuer"
                    Assert-MockCalled -Times 1 -CommandName "Get-SPAuthenticationRealm"
                }

                It "Should return false from the Test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "The SPTrustedSecurityTokenIssuer does not exist and should be created, using a custom realm" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                           = $SPTrustName
                        Description                    = $SPTrustDescription
                        RegisteredIssuerNameIdentifier = $SPTrustRegisteredIssuerNameIdentifier
                        RegisteredIssuerNameRealm      = "C47023F3-4109-4C6E-8913-DFC3DBACD8C5"
                        SigningCertificateThumbprint   = $SPTrustSigningCertificateThumbprint
                        IsTrustBroker                  = $true
                        Ensure                         = "Present"
                    }

                    Mock -CommandName New-SPTrustedSecurityTokenIssuer -MockWith {
                        $sptrust = [pscustomobject]@{
                            Name                 = $testParams.Name
                            RegisteredIssuerName = "$($testParams.RegisteredIssuerNameIdentifier)@$($testParams.RegisteredIssuerNameRealm)"
                            Description          = $SPTrustDescription
                        }
                        $sptrust | Add-Member -Name Update -MemberType ScriptMethod -Value { }
                        return $sptrust
                    }
                }

                It "Should create the SPTrustedSecurityTokenIssuer using the custom realm" {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName "New-SPTrustedSecurityTokenIssuer"
                    Assert-MockCalled -Times 0 -CommandName "Get-SPAuthenticationRealm"
                }
            }

            Context -Name "The SPTrustedSecurityTokenIssuer does not exist and should be created, using a MetadataEndPoint" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name             = $SPTrustName
                        Description      = $SPTrustDescription
                        MetadataEndPoint = "https://accounts.accesscontrol.windows.net/TENANT.onmicrosoft.com/metadata/json/1"
                        IsTrustBroker    = $true
                        Ensure           = "Present"
                    }

                    Mock -CommandName Get-SPTrustedSecurityTokenIssuer -MockWith {
                        return $null
                    }

                    Mock -CommandName New-SPTrustedSecurityTokenIssuer -MockWith {
                        $sptrust = [pscustomobject]@{
                            Name                 = $testParams.Name
                            RegisteredIssuerName = "$SPTrustRegisteredIssuerNameIdentifier@5d38d3ac-eeb7-4fa4-992b-8d1d3a1cb405"
                            Description          = $SPTrustDescription
                            MetadataEndPoint     = $testParams.MetadataEndPoint
                        }
                        $sptrust | Add-Member -Name Update -MemberType ScriptMethod -Value { }
                        return $sptrust
                    }
                }

                It "Should create the SPTrustedSecurityTokenIssuer using a MetadataEndPoint" {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName "New-SPTrustedSecurityTokenIssuer"
                    Assert-MockCalled -Times 0 -CommandName "Get-SPAuthenticationRealm"
                }
            }

            Context -Name "The SPTrustedSecurityTokenIssuer is desired, and both parameters SigningCertificateThumbprint and SigningCertificateFilePath are set but thumbprints does not match" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                           = $SPTrustName
                        Description                    = $SPTrustDescription
                        RegisteredIssuerNameIdentifier = $SPTrustRegisteredIssuerNameIdentifier
                        SigningCertificateThumbprint   = $SPTrustSigningCertificateThumbprint
                        SigningCertificateFilePath     = $SPTrustSigningCertificateFilePath
                        IsTrustBroker                  = $true
                        Ensure                         = "Present"
                    }

                    Mock -CommandName New-Object -MockWith {
                        $retVal = [pscustomobject]@{
                            Subject       = "CN=CertIdentifer"
                            Thumbprint    = "1111111111111111111111111111111111111111"
                            HasPrivateKey = $false
                        }
                        Add-Member -InputObject $retVal -MemberType ScriptMethod Import { }

                        return $retVal
                    } -ParameterFilter { $TypeName -eq "System.Security.Cryptography.X509Certificates.X509Certificate2" }
                }

                It "should fail validation of signing certificate parameters in the Set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Imported certificate thumbprint (1111111111111111111111111111111111111111) does not match expected thumbprint ($SPTrustSigningCertificateThumbprint)."
                }

                It "should fail validation of signing certificate parameters in the Test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "The SPTrustedSecurityTokenIssuer is desired, and SigningCertificateFilePath are set but thumbprint does not match existing configuration" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                           = $SPTrustName
                        Description                    = $SPTrustDescription
                        RegisteredIssuerNameIdentifier = $SPTrustRegisteredIssuerNameIdentifier
                        SigningCertificateFilePath     = $SPTrustSigningCertificateFilePath
                        IsTrustBroker                  = $true
                        Ensure                         = "Present"
                    }

                    Mock -CommandName New-Object -MockWith {
                        $retVal = [pscustomobject]@{
                            Subject       = CertIdentifer
                            Thumbprint    = "1111111111111111111111111111111111111"
                            HasPrivateKey = $false
                        }
                        Add-Member -InputObject $retVal -MemberType ScriptMethod Import
                        {
                        }

                        return $retVal
                    } -ParameterFilter { $TypeName -eq "System.Security.Cryptography.X509Certificates.X509Certificate2" }

                    Mock -CommandName New-Object -MockWith {
                        $retVal = [pscustomobject]@{
                            Subject       = "CN = CertIdentifer"
                            Thumbprint    = $SigningCertificateThumbprint
                            HasPrivateKey = $false
                        }
                        Add-Member -InputObject $retVal -MemberType ScriptMethod Import { }

                        return $retVal
                    } -ParameterFilter { $TypeName -eq "System.Security.Cryptography.X509Certificates.X509Certificate2" }
                }

                It "should fail validation of signing certificate parameters in the Set method" {
                    { Set-TargetResource @testParams } | Should -Not -Throw
                }

                It "should fail validation of signing certificate parameters in the Test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "The SPTrustedSecurityTokenIssuer is desired, but both parameters SigningCertificateThumbprint and MetadataEndPoint are set while exactly 1 should" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                           = $SPTrustName
                        Description                    = $SPTrustDescription
                        RegisteredIssuerNameIdentifier = $SPTrustRegisteredIssuerNameIdentifier
                        SigningCertificateThumbprint   = $SPTrustSigningCertificateThumbprint
                        MetadataEndPoint               = "https://accounts.accesscontrol.windows.net/TENANT.onmicrosoft.com/metadata/json/1"
                        IsTrustBroker                  = $true
                        Ensure                         = "Present"
                    }
                }

                It "should fail validation of signing certificate parameters in the Set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Cannot use both parameters SigningCertificateThumbprint and MetadataEndPoint at the same time."
                }

                It "should fail validation of signing certificate parameters in the Test method" {
                    { Test-TargetResource @testParams } | Should -Throw "Cannot use both parameters SigningCertificateThumbprint and MetadataEndPoint at the same time."
                }
            }

            Context -Name "The SPTrustedSecurityTokenIssuer is desired, but both parameters SigningCertificateFilePath and MetadataEndPoint are set while exactly 1 should" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                           = $SPTrustName
                        Description                    = $SPTrustDescription
                        RegisteredIssuerNameIdentifier = $SPTrustRegisteredIssuerNameIdentifier
                        SigningCertificateFilePath     = $SPTrustSigningCertificateFilePath
                        MetadataEndPoint               = "https://accounts.accesscontrol.windows.net/TENANT.onmicrosoft.com/metadata/json/1"
                        IsTrustBroker                  = $true
                        Ensure                         = "Present"
                    }
                }

                It "should fail validation of signing certificate parameters in the Set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Cannot use both parameters SigningCertificateFilePath and MetadataEndPoint at the same time."
                }

                It "should fail validation of signing certificate parameters in the Test method" {
                    { Test-TargetResource @testParams } | Should -Throw "Cannot use both parameters SigningCertificateFilePath and MetadataEndPoint at the same time."
                }
            }

            Context -Name "The SPTrustedSecurityTokenIssuer is desired, but the thumbprint of the signing certificate in parameter SigningCertificateThumbprint is invalid" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                           = $SPTrustName
                        Description                    = $SPTrustDescription
                        RegisteredIssuerNameIdentifier = $SPTrustRegisteredIssuerNameIdentifier
                        SigningCertificateThumbprint   = "XX123ABCFACEXX"
                        IsTrustBroker                  = $true
                        Ensure                         = "Present"
                    }
                }

                It "should fail validation of parameter SigningCertificateThumbprint in the Set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Parameter SigningCertificateThumbprint does not match valid format '^[A-Fa-f0-9]{40}$'."
                }
            }

            Context -Name "The SPTrustedSecurityTokenIssuer already exists and its signing certificate is specified using SigningCertificateThumbprint, and should not be changed" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                           = $SPTrustName
                        Description                    = $SPTrustDescription
                        RegisteredIssuerNameIdentifier = $SPTrustRegisteredIssuerNameIdentifier
                        SigningCertificateThumbprint   = $SPTrustSigningCertificateThumbprint
                        IsTrustBroker                  = $true
                        Ensure                         = "Present"
                    }

                    Mock -CommandName Get-SPTrustedSecurityTokenIssuer -MockWith {
                        $sptrust = [pscustomobject]@{
                            Name                 = $testParams.Name
                            RegisteredIssuerName = "$($testParams.RegisteredIssuerNameIdentifier)@$(Get-SPAuthenticationRealm)"
                            Description          = $testParams.Description
                            IsSelfIssuer         = !$testParams.IsTrustBroker
                            SigningCertificate   = [pscustomobject]@{
                                Thumbprint = $testParams.SigningCertificateThumbprint
                            }
                        }
                        return $sptrust
                    }
                }

                It "Should be returned the get method with expected properties" {
                    $getResults = Get-TargetResource @testParams
                    $getResults.Ensure | Should -Be "Present"
                    $getResults.Description | Should -Be "$($testParams.Description)"
                    $getResults.RegisteredIssuerNameIdentifier | Should -Be "$($testParams.RegisteredIssuerNameIdentifier)"
                    $getResults.RegisteredIssuerNameRealm | Should -Be $null
                    $getResults.SigningCertificateThumbprint | Should -Be "$($testParams.SigningCertificateThumbprint)"
                    $getResults.IsTrustBroker | Should -Be "$($testParams.IsTrustBroker)"
                }

                It "Should return true from the Test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The SPTrustedSecurityTokenIssuer already exists and its signing certificate is specified using SigningCertificateFilePath, and should not be changed" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                           = $SPTrustName
                        Description                    = $SPTrustDescription
                        RegisteredIssuerNameIdentifier = $SPTrustRegisteredIssuerNameIdentifier
                        SigningCertificateFilePath     = $SPTrustSigningCertificateFilePath
                        IsTrustBroker                  = $true
                        Ensure                         = "Present"
                    }

                    Mock -CommandName Get-SPTrustedSecurityTokenIssuer -MockWith {
                        $sptrust = [pscustomobject]@{
                            Name                 = $testParams.Name
                            RegisteredIssuerName = "$($testParams.RegisteredIssuerNameIdentifier)@$(Get-SPAuthenticationRealm)"
                            Description          = $testParams.Description
                            IsSelfIssuer         = !$testParams.IsTrustBroker
                            SigningCertificate   = [pscustomobject]@{
                                Thumbprint = $testParams.SigningCertificateThumbprint
                            }
                        }
                        return $sptrust
                    }

                    Mock -CommandName New-Object -MockWith {
                        $retVal = [pscustomobject]@{
                            Subject       = "CN = CertIdentifer"
                            Thumbprint    = $SigningCertificateThumbprint
                            HasPrivateKey = $false
                        }
                        Add-Member -InputObject $retVal -MemberType ScriptMethod Import { }

                        return $retVal
                    } -ParameterFilter { $TypeName -eq "System.Security.Cryptography.X509Certificates.X509Certificate2" }
                }

                It "Should be returned the get method with expected properties" {
                    $getResults = Get-TargetResource @testParams
                    $getResults.Ensure | Should -Be "Present"
                    $getResults.Description | Should -Be "$($testParams.Description)"
                    $getResults.RegisteredIssuerNameIdentifier | Should -Be "$($testParams.RegisteredIssuerNameIdentifier)"
                    $getResults.RegisteredIssuerNameRealm | Should -Be $null
                    $getResults.SigningCertificateFilePath | Should -Be "$($testParams.SigningCertificateFilePath)"
                    $getResults.IsTrustBroker | Should -Be "$($testParams.IsTrustBroker)"
                }

                It "Should return true from the Test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The SPTrustedSecurityTokenIssuer exists and should be removed" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                           = $SPTrustName
                        Description                    = $SPTrustDescription
                        RegisteredIssuerNameIdentifier = $SPTrustRegisteredIssuerNameIdentifier
                        SigningCertificateThumbprint   = $SPTrustSigningCertificateThumbprint
                        IsTrustBroker                  = $true
                        Ensure                         = "Absent"
                    }

                    Mock -CommandName Get-SPTrustedSecurityTokenIssuer -MockWith {
                        $sptrust = [pscustomobject]@{
                            Name                 = $testParams.Name
                            RegisteredIssuerName = "$($testParams.RegisteredIssuerNameIdentifier)@$(Get-SPAuthenticationRealm)"
                        }
                        return $sptrust
                    }

                    Mock -CommandName Remove-SPTrustedSecurityTokenIssuer -MockWith { }
                }

                It "Should be returned the get method with expected properties" {
                    $getResults = Get-TargetResource @testParams
                    $getResults.Ensure | Should -Be "Present"
                    $getResults.RegisteredIssuerNameIdentifier | Should -Be "$($testParams.RegisteredIssuerNameIdentifier)"
                    $getResults.RegisteredIssuerNameRealm | Should -Be $null
                }

                It "Should return false from the Test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should remove the SPTrustedSecurityTokenIssuer" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-SPTrustedSecurityTokenIssuer
                }
            }

            Context -Name "The SPTrustedSecurityTokenIssuer exists and should be updated with a new RegisteredIssuerName" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                           = $SPTrustName
                        Description                    = $SPTrustDescription
                        RegisteredIssuerNameIdentifier = "22222222-2222-2222-2222-333333333333"
                        SigningCertificateThumbprint   = $SPTrustSigningCertificateThumbprint
                        IsTrustBroker                  = $true
                        Ensure                         = "Present"
                    }

                    Mock -CommandName Get-SPTrustedSecurityTokenIssuer -MockWith {
                        $sptrust = [pscustomobject]@{
                            Name                 = $testParams.Name
                            RegisteredIssuerName = "$SPTrustRegisteredIssuerNameIdentifier@$(Get-SPAuthenticationRealm)"
                            Description          = $SPTrustDescription
                            IsSelfIssuer         = $true
                            SigningCertificate   = [pscustomobject]@{
                                Thumbprint = $testParams.$SPTrustSigningCertificateThumbprint
                            }
                        }
                        return $sptrust
                    }
                }

                It "Should be returned the get method with expected properties" {
                    $getResults = Get-TargetResource @testParams
                    $getResults.Ensure | Should -Be "Present"
                }

                It "Should return false from the Test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the SPTrustedSecurityTokenIssuer" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-SPTrustedSecurityTokenIssuer
                }
            }

            Context -Name "The SPTrustedSecurityTokenIssuer exists and should be updated with a new RegisteredIssuerRealm" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                           = $SPTrustName
                        Description                    = $SPTrustDescription
                        RegisteredIssuerNameIdentifier = $SPTrustRegisteredIssuerNameIdentifier
                        RegisteredIssuerNameRealm      = [Guid]::NewGuid()
                        SigningCertificateThumbprint   = $SPTrustSigningCertificateThumbprint
                        IsTrustBroker                  = $true
                        Ensure                         = "Present"
                    }

                    Mock -CommandName Get-SPTrustedSecurityTokenIssuer -MockWith {
                        $sptrust = [pscustomobject]@{
                            Name                 = $testParams.Name
                            RegisteredIssuerName = "$SPTrustRegisteredIssuerNameIdentifier@$(Get-SPAuthenticationRealm)"
                            Description          = $SPTrustDescription
                            IsSelfIssuer         = $true
                            SigningCertificate   = [pscustomobject]@{
                                Thumbprint = $testParams.$SPTrustSigningCertificateThumbprint
                            }
                        }
                        return $sptrust
                    }
                }

                It "Should be returned the get method with expected properties" {
                    $getResults = Get-TargetResource @testParams
                    $getResults.Ensure | Should -Be "Present"
                }

                It "Should return false from the Test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the SPTrustedSecurityTokenIssuer" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-SPTrustedSecurityTokenIssuer
                }
            }

            Context -Name "The SPTrustedSecurityTokenIssuer exists and should be updated with a new Description" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                           = $SPTrustName
                        Description                    = "New description"
                        RegisteredIssuerNameIdentifier = $SPTrustRegisteredIssuerNameIdentifier
                        SigningCertificateThumbprint   = $SPTrustSigningCertificateThumbprint
                        IsTrustBroker                  = $true
                        Ensure                         = "Present"
                    }

                    Mock -CommandName Get-SPTrustedSecurityTokenIssuer -MockWith {
                        $sptrust = [pscustomobject]@{
                            Name                 = $testParams.Name
                            RegisteredIssuerName = "$SPTrustRegisteredIssuerNameIdentifier@$(Get-SPAuthenticationRealm)"
                            Description          = $SPTrustDescription
                            IsSelfIssuer         = $true
                            SigningCertificate   = [pscustomobject]@{
                                Thumbprint = $testParams.$SPTrustSigningCertificateThumbprint
                            }
                        }
                        return $sptrust
                    }
                }

                It "Should be returned the get method with expected properties" {
                    $getResults = Get-TargetResource @testParams
                    $getResults.Ensure | Should -Be "Present"
                }

                It "Should return false from the Test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the SPTrustedSecurityTokenIssuer" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-SPTrustedSecurityTokenIssuer
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
