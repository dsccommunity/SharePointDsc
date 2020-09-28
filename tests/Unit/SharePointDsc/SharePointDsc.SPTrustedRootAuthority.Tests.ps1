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
$script:DSCResourceName = 'SPTrustedRootAuthority'
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

                Mock -CommandName Remove-SPTrustedRootAuthority -MockWith { }
                Mock -CommandName Set-SPTrustedRootAuthority -MockWith { }
                Mock -CommandName New-SPTrustedRootAuthority -MockWith { }
            }

            Context -Name "When both CertificalThumbprint and CertificateFilePath are specified and thumbprints does not match (root authority exists)" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                  = "CertIdentifier"
                        CertificateThumbprint = "770515261D1AB169057E246E0EE6431D557C3AFB"
                        CertificateFilePath   = "C:\cert.cer"
                        Ensure                = "Present"
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

                    Mock -CommandName Test-Path -MockWith {
                        return $true
                    }

                    Mock -CommandName Get-SPTrustedRootAuthority -MockWith {
                        return @{
                            Name        = $testParams.Name
                            Certificate = @{
                                Thumbprint = $testParams.CertificateThumbprint
                            }
                        }
                    }
                }

                It "Should return Present from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should fail validation of signing certificate parameters in the Set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Imported certificate thumbprint (1111111111111111111111111111111111111111) does not match expected thumbprint (770515261D1AB169057E246E0EE6431D557C3AFB)."
                }
            }

            Context -Name "When both CertificalThumbprint and CertificateFilePath are specified and thumbprints does not match (root authority does not exists)" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                  = "CertIdentifier"
                        CertificateThumbprint = "770515261D1AB169057E246E0EE6431D557C3AFB"
                        CertificateFilePath   = "C:\cert.cer"
                        Ensure                = "Present"
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

                    Mock -CommandName Test-Path -MockWith {
                        return $true
                    }

                    Mock -CommandName Get-SPTrustedRootAuthority -MockWith {
                        return $null
                    }
                }

                It "Should return Present from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should fail validation of signing certificate parameters in the Set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Imported certificate thumbprint (1111111111111111111111111111111111111111) does not match expected thumbprint (770515261D1AB169057E246E0EE6431D557C3AFB)."
                }
            }

            Context -Name "When neither CertificalThumbprint and CertificateFilePath are specified" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name   = "CertIdentifier"
                        Ensure = "Present"
                    }

                    Mock -CommandName Get-Item -MockWith {
                        return @{
                            Subject    = "CN=CertName"
                            Thumbprint = $testParams.CertificateThumbprint
                        }
                    }

                    Mock -CommandName Test-Path -MockWith {
                        return $true
                    }

                    Mock -CommandName Get-SPTrustedRootAuthority -MockWith {
                        return @{
                            Name        = $testParams.Name
                            Certificate = @{
                                Thumbprint = $testParams.CertificateThumbprint
                            }
                        }
                    }
                }

                It "Should return Present from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return true when the Test method is called" {
                    { Test-TargetResource @testParams } | Should -Throw "At least one of the following parameters must be specified"
                }

                It "Should Update the SP Trusted Root Authority in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "At least one of the following parameters must be specified"
                }
            }

            Context -Name "When specified CertificateFilePath does not exist" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                = "CertIdentifier"
                        CertificateFilePath = "C:\cert.cer"
                        Ensure              = "Present"
                    }

                    Mock -CommandName Get-Item -MockWith {
                        return @{
                            Subject    = "CN=CertName"
                            Thumbprint = $testParams.CertificateThumbprint
                        }
                    }

                    Mock -CommandName Test-Path -MockWith {
                        return $false
                    }

                    Mock -CommandName Get-SPTrustedRootAuthority -MockWith {
                        return @{
                            Name        = $testParams.Name
                            Certificate = @{
                                Thumbprint = $testParams.CertificateThumbprint
                            }
                        }
                    }
                }

                It "Should return Present from the Get method" {
                    { Get-TargetResource @testParams } | Should -Throw "Specified CertificateFilePath does not exist"
                }

                It "Should return true when the Test method is called" {
                    { Test-TargetResource @testParams } | Should -Throw "Specified CertificateFilePath does not exist"
                }

                It "Should Update the SP Trusted Root Authority in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Specified CertificateFilePath does not exist"
                }
            }

            Context -Name "When TrustedRootAuthority should exist and does exist in the farm (Thumbprint)." -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                  = "CertIdentifier"
                        CertificateThumbprint = "770515261D1AB169057E246E0EE6431D557C3AFB"
                        Ensure                = "Present"
                    }

                    Mock -CommandName Get-Item -MockWith {
                        return @{
                            Subject    = "CN=CertName"
                            Thumbprint = $testParams.CertificateThumbprint
                        }
                    }

                    Mock -CommandName Get-SPTrustedRootAuthority -MockWith {
                        return @{
                            Name        = $testParams.Name
                            Certificate = @{
                                Thumbprint = $testParams.CertificateThumbprint
                            }
                        }
                    }
                }

                It "Should return Present from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return true when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $true
                }

                It "Should Update the SP Trusted Root Authority in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Get-SPTrustedRootAuthority -Times 1
                    Assert-MockCalled Set-SPTrustedRootAuthority -Times 1
                }
            }

            Context -Name "When TrustedRootAuthority should exist and does exist in the farm (FilePath)." -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                = "CertIdentifier"
                        CertificateFilePath = "C:\cert.cer"
                        Ensure              = "Present"
                    }

                    Mock -CommandName Test-Path -MockWith {
                        return $true
                    }

                    Mock -CommandName New-Object -MockWith {
                        $retVal = [pscustomobject]@{
                            Subject       = "CN=CertIdentifer"
                            Thumbprint    = "770515261D1AB169057E246E0EE6431D557C3AFC"
                            HasPrivateKey = $false
                        }
                        Add-Member -InputObject $retVal -MemberType ScriptMethod Import { }

                        return $retVal
                    } -ParameterFilter { $TypeName -eq "System.Security.Cryptography.X509Certificates.X509Certificate2" }

                    Mock -CommandName Get-SPTrustedRootAuthority -MockWith {
                        return @{
                            Name        = $testParams.Name
                            Certificate = @{
                                Thumbprint = "770515261D1AB169057E246E0EE6431D557C3AFC"
                            }
                        }
                    }
                }

                It "Should return Present from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return true when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $true
                }

                It "Should Update the SP Trusted Root Authority in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Get-SPTrustedRootAuthority -Times 1
                    Assert-MockCalled Set-SPTrustedRootAuthority -Times 1
                }
            }

            Context -Name "When TrustedRootAuthority should exist and does exist in the farm (FilePath and Thumbprint)." -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                  = "CertIdentifier"
                        CertificateFilePath   = "C:\cert.cer"
                        CertificateThumbprint = "770515261D1AB169057E246E0EE6431D557C3AFC"
                        Ensure                = "Present"
                    }

                    Mock -CommandName Test-Path -MockWith {
                        return $true
                    }

                    Mock -CommandName New-Object -MockWith {
                        $retVal = [pscustomobject]@{
                            Subject       = "CN=CertIdentifer"
                            Thumbprint    = "770515261D1AB169057E246E0EE6431D557C3AFC"
                            HasPrivateKey = $false
                        }
                        Add-Member -InputObject $retVal -MemberType ScriptMethod Import { }

                        return $retVal
                    } -ParameterFilter { $TypeName -eq "System.Security.Cryptography.X509Certificates.X509Certificate2" }

                    Mock -CommandName Get-SPTrustedRootAuthority -MockWith {
                        return @{
                            Name        = $testParams.Name
                            Certificate = @{
                                Thumbprint = "770515261D1AB169057E246E0EE6431D557C3AFC"
                            }
                        }
                    }
                }

                It "Should return Present from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return true when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $true
                }

                It "Should Update the SP Trusted Root Authority in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Get-SPTrustedRootAuthority -Times 1
                    Assert-MockCalled Set-SPTrustedRootAuthority -Times 1
                }
            }

            Context -Name "When TrustedRootAuthority should exist and does exist in the farm, but has incorrect certificate (Thumbprint)." -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                  = "CertIdentifier"
                        CertificateThumbprint = "770515261D1AB169057E246E0EE6431D557C3AFB"
                        Ensure                = "Present"
                    }

                    Mock -CommandName Get-SPTrustedRootAuthority -MockWith {
                        return @{
                            Name        = $testParams.Name
                            Certificate = @{
                                Thumbprint = "770515261D1AB169057E246E0EE6431D557C3AFC"
                            }
                        }
                    }

                    Mock -CommandName Get-Item -MockWith {
                        return  @{
                            Subject    = "CN=CertName"
                            Thumbprint = $testParams.CertificateThumbprint
                        }
                    }
                }

                It "Should return Present from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the certificate in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Get-SPTrustedRootAuthority -Times 1
                    Assert-MockCalled Set-SPTrustedRootAuthority -Times 1
                }
            }

            Context -Name "When TrustedRootAuthority should exist and does exist in the farm, but has incorrect certificate (FilePath)." -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                = "CertIdentifier"
                        CertificateFilePath = "C:\cert.cer"
                        Ensure              = "Present"
                    }

                    Mock -CommandName Get-SPTrustedRootAuthority -MockWith {
                        return @{
                            Name        = $testParams.Name
                            Certificate = @{
                                Thumbprint = "770515261D1AB169057E246E0EE6431D557C3AFC"
                            }
                        }
                    }

                    Mock -CommandName Test-Path -MockWith {
                        return $true
                    }

                    Mock -CommandName Get-Item -MockWith {
                        return  @{
                            Subject    = "CN=CertName"
                            Thumbprint = $testParams.CertificateThumbprint
                        }
                    }

                    Mock -CommandName New-Object -MockWith {
                        $retVal = [pscustomobject]@{
                            Subject       = "CN=CertIdentifer"
                            Thumbprint    = "770515261D1AB169057E246E0EE6431D557C3AFB"
                            HasPrivateKey = $false
                        }
                        Add-Member -InputObject $retVal -MemberType ScriptMethod Import { }

                        return $retVal
                    } -ParameterFilter { $TypeName -eq "System.Security.Cryptography.X509Certificates.X509Certificate2" }
                }

                It "Should return Present from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the certificate in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Get-SPTrustedRootAuthority -Times 1
                    Assert-MockCalled Set-SPTrustedRootAuthority -Times 1
                }
            }

            Context -Name "When TrustedRootAuthority should exist and does exist in the farm, but has incorrect certificate (FilePath and Thumbprint)." -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                  = "CertIdentifier"
                        CertificateFilePath   = "C:\cert.cer"
                        CertificateThumbprint = "770515261D1AB169057E246E0EE6431D557C3AFB"
                        Ensure                = "Present"
                    }

                    Mock -CommandName Test-Path -MockWith {
                        return $true
                    }

                    Mock -CommandName New-Object -MockWith {
                        $retVal = [pscustomobject]@{
                            Subject       = "CN=CertIdentifer"
                            Thumbprint    = "770515261D1AB169057E246E0EE6431D557C3AFB"
                            HasPrivateKey = $false
                        }
                        Add-Member -InputObject $retVal -MemberType ScriptMethod Import { }

                        return $retVal
                    } -ParameterFilter { $TypeName -eq "System.Security.Cryptography.X509Certificates.X509Certificate2" }

                    Mock -CommandName Get-SPTrustedRootAuthority -MockWith {
                        return @{
                            Name        = $testParams.Name
                            Certificate = @{
                                Thumbprint = "770515261D1AB169057E246E0EE6431D557C3AFC"
                            }
                        }
                    }
                }

                It "Should return Present from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should Update the SP Trusted Root Authority in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Get-SPTrustedRootAuthority -Times 1
                    Assert-MockCalled Set-SPTrustedRootAuthority -Times 1
                }
            }

            Context -Name "When TrustedRootAuthority should exist and does exist in the farm, but has incorrect certificate, but specified certificate doesn't exist;" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                  = "CertIdentifier"
                        CertificateThumbprint = "770515261D1AB169057E246E0EE6431D557C3AFB"
                        Ensure                = "Present"
                    }

                    Mock -CommandName Get-SPTrustedRootAuthority -MockWith {
                        return @{
                            Name        = $testParams.Name
                            Certificate = @{
                                Thumbprint = "770515261D1AB169057E246E0EE6431D557C3AFC"
                            }
                        }
                    }

                    Mock -CommandName Get-Item -MockWith {
                        return  $null
                    }
                }

                It "Should return Present from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should thorw Certificate not found error in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Certificate not found in the local Certificate Store"
                }
            }

            Context -Name "When TrustedRootAuthority should exist and doesn't exist in the farm, but has an invalid certificate." -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                  = "CertIdentifier"
                        CertificateThumbprint = "770515261D1AB169057E246E0EE6431D557C3AFB"
                        Ensure                = "Present"
                    }

                    Mock -CommandName Get-SPTrustedRootAuthority -MockWith {
                        return $null
                    }

                    Mock -CommandName Get-Item -MockWith {
                        return $null
                    }
                }

                It "Should return Absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should throw a Certificate not found error" {
                    { Set-TargetResource @testParams } | Should -Throw "Certificate not found in the local Certificate Store"
                }
            }

            Context -Name "When TrustedRootAuthority should exist and doesn't exist in the farm (Thumbprint)." -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                  = "CertIdentifier"
                        CertificateThumbprint = "770515261D1AB169057E246E0EE6431D557C3AFB"
                        Ensure                = "Present"
                    }

                    Mock -CommandName Get-Item -MockWith {
                        return @{
                            Subject    = "CN=CertIdentifier"
                            Thumbprint = $testParams.CertificateThumbprint
                        }
                    }

                    Mock -CommandName Get-SPTrustedRootAuthority -MockWith {
                        return $null
                    }
                }

                It "Should return Absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return true when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create a new trusted root authority in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Get-Item -Times 1
                    Assert-MockCalled New-SPTrustedRootAuthority -Times 1
                }
            }

            Context -Name "When TrustedRootAuthority should exist and doesn't exist in the farm (FilePath)." -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                = "CertIdentifier"
                        CertificateFilePath = "c:\cert.cer"
                        Ensure              = "Present"
                    }

                    Mock -CommandName Test-Path -MockWith {
                        return $true
                    }

                    Mock -CommandName Get-Item -MockWith {
                        return  @{
                            Subject    = "CN=CertName"
                            Thumbprint = $testParams.CertificateThumbprint
                        }
                    }

                    Mock -CommandName New-Object -MockWith {
                        $retVal = [pscustomobject]@{
                            Subject       = "CN=CertIdentifer"
                            Thumbprint    = "770515261D1AB169057E246E0EE6431D557C3AFB"
                            HasPrivateKey = $false
                        }
                        Add-Member -InputObject $retVal -MemberType ScriptMethod Import { }

                        return $retVal
                    } -ParameterFilter { $TypeName -eq "System.Security.Cryptography.X509Certificates.X509Certificate2" }

                    Mock -CommandName Get-SPTrustedRootAuthority -MockWith {
                        return $null
                    }
                }

                It "Should return Absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return true when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create a new trusted root authority in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPTrustedRootAuthority -Times 1
                }
            }

            Context -Name "When TrustedRootAuthority should exist and doesn't exist in the farm (FilePath and Thumbprint)." -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                  = "CertIdentifier"
                        CertificateThumbprint = "770515261D1AB169057E246E0EE6431D557C3AFB"
                        CertificateFilePath   = "c:\cert.cer"
                        Ensure                = "Present"
                    }

                    Mock -CommandName Test-Path -MockWith {
                        return $true
                    }

                    Mock -CommandName Get-Item -MockWith {
                        return  @{
                            Subject    = "CN=CertName"
                            Thumbprint = $testParams.CertificateThumbprint
                        }
                    }

                    Mock -CommandName New-Object -MockWith {
                        $retVal = [pscustomobject]@{
                            Subject       = "CN=CertIdentifer"
                            Thumbprint    = "770515261D1AB169057E246E0EE6431D557C3AFB"
                            HasPrivateKey = $false
                        }
                        Add-Member -InputObject $retVal -MemberType ScriptMethod Import { }

                        return $retVal
                    } -ParameterFilter { $TypeName -eq "System.Security.Cryptography.X509Certificates.X509Certificate2" }

                    Mock -CommandName Get-SPTrustedRootAuthority -MockWith {
                        return $null
                    }
                }

                It "Should return Absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return true when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create a new Trusted Root Authority in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPTrustedRootAuthority -Times 1
                    Assert-MockCalled New-Object -Times 1
                }
            }

            Context -Name "When TrustedRootAuthority should exist and does exist but is incorrect certificate and specified cert contains a private key" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                  = "CertIdentifier"
                        CertificateThumbprint = "770515261D1AB169057E246E0EE6431D557C3AFB"
                        Ensure                = "Present"
                    }

                    Mock -CommandName Get-Item -MockWith {
                        $retVal = [pscustomobject]@{
                            Subject       = "CN=CertIdentifier"
                            Thumbprint    = $testParams.CertificateThumbprint
                            HasPrivateKey = $true
                        }

                        Add-Member -InputObject $retVal -MemberType ScriptMethod Export {
                            $bytes = [System.Byte[]]::CreateInstance([System.Byte], 512)
                            return $bytes
                        }

                        return $retVal
                    }

                    Mock -CommandName New-Object -MockWith {
                        $retVal = [pscustomobject]@{ }
                        Add-Member -InputObject $retVal -MemberType ScriptMethod Import {
                            param([System.Byte[]]$bytes)
                            return @{
                                Subject       = "CN=CertIdentifer"
                                Thumbprint    = $testParams.CertificateThumbprint
                                HasPrivateKey = $false
                            }
                        }

                        return $retVal
                    } -ParameterFilter { $TypeName -eq "System.Security.Cryptography.X509Certificates.X509Certificate2" }

                    Mock -CommandName Get-SPTrustedRootAuthority -MockWith {
                        return @{
                            Name        = $testParams.Name
                            Certificate = @{
                                Thumbprint = "770515261D1AB169057E246E0EE6431D557C3AFC"
                            }
                        }
                    }
                }

                It "Should return Absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return true when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should create a new Trusted Root Authority in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Get-Item -Times 1
                    Assert-MockCalled Set-SPTrustedRootAuthority -Times 1
                    Assert-MockCalled New-Object -Times 1
                }
            }

            Context -Name "When TrustedRootAuthority shouldn't exist and does exist in the farm." -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                  = "CertIdentifier"
                        CertificateThumbprint = "770515261D1AB169057E246E0EE6431D557C3AFB"
                        Ensure                = "Absent"
                    }

                    Mock -CommandName Get-Item -MockWith {
                        return @{
                            Subject    = "CN=CertIdentifier"
                            Thumbprint = $testParams.CertificateThumbprint
                        }
                    }

                    Mock -CommandName Get-SPTrustedRootAuthority -MockWith {
                        return @{
                            Name        = $testParams.Name
                            Certificate = @{
                                Thumbprint = $testParams.CertificateThumbprint
                            }
                        }
                    }
                }

                It "Should return Present from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should remove the Trusted Root Authority" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-SPTrustedRootAuthority -Times 1
                }
            }

            Context -Name "When TrustedRootAuthority shouldn't exist and doesn't exist in the farm." -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name                  = "CertIdentifier"
                        CertificateThumbprint = "770515261D1AB169057E246E0EE6431D557C3AFB"
                        Ensure                = "Absent"
                    }

                    Mock -CommandName Get-Item -MockWith {
                        return  @{
                            Subject    = "CN=CertIdentifier"
                            Thumbprint = $testParams.CertificateThumbprint
                        }
                    }

                    Mock -CommandName Get-SPTrustedRootAuthority -MockWith {
                        return $null
                    }
                }

                It "Should return Absent from the Get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should return false when the Test method is called" {
                    Test-TargetResource @testParams | Should -Be $true
                }

                It "Should remove the Trusted Root Authority" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-SPTrustedRootAuthority -Times 1
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
