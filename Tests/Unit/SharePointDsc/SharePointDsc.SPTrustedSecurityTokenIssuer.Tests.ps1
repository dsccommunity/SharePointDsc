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
    -DscResource "SPTrustedSecurityTokenIssuer"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Mocks for all contexts
        Mock -CommandName New-SPTrustedSecurityTokenIssuer -MockWith {
            $sptrust = [pscustomobject]@{
                NameId = "22222222-2222-2222-2222-222222222222@bc23e3e4-5899-4b5d-9cee-27344da5deb5"
                Name   = $testParams.Name
            }
            $sptrust | Add-Member -Name Update -MemberType ScriptMethod -Value { }
            return $sptrust
        }

        Mock -CommandName Get-ChildItem -MockWith {
            return @(
                @{
                    Thumbprint = "123ABCFACE123ABCFACE123ABCFACE123ABCFACE"
                }
            )
        } -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' }

        Mock -CommandName New-Object -MockWith {
            return @(
                @{
                    Thumbprint = "123ABCFACE123ABCFACE123ABCFACE123ABCFACE"
                }
            )
        } -ParameterFilter { $TypeName -eq 'System.Security.Cryptography.X509Certificates.X509Certificate2' }

        Mock -CommandName Get-SPAuthenticationRealm -MockWith {
            return [Guid]::New("D683A811-9F0E-49BC-8BF1-DC1C5FEC8447")
        }

        # Test contexts
        Context -Name "The SPTrustedSecurityTokenIssuer does not exist and should be created, using a signing certificate in the certificate store and the realm of the farm" -Fixture {
            $testParams = @{
                Name                           = "HighTrust"
                Description                    = "HighTrust fake"
                RegisteredIssuerNameIdentifier = "22222222-2222-2222-2222-222222222222"
                RegisteredIssuerNameRealm      = $null
                SigningCertificateThumbprint   = "123ABCFACE123ABCFACE123ABCFACE123ABCFACE"
                IsTrustBroker                  = $true
                Ensure                         = "Present"
            }

            It "Should create the SPTrustedSecurityTokenIssuer using the realm of the farm" {
                Set-TargetResource @testParams
                Assert-MockCalled -CommandName "New-SPTrustedSecurityTokenIssuer"
                Assert-MockCalled -Times 1 -CommandName "Get-SPAuthenticationRealm"
            }
        }

        Context -Name "The SPTrustedSecurityTokenIssuer does not exist and should be created, using a signing certificate in the fire system and the realm of the farm" -Fixture {
            $testParams = @{
                Name                           = "HighTrust"
                Description                    = "HighTrust fake"
                RegisteredIssuerNameIdentifier = "22222222-2222-2222-2222-222222222222"
                RegisteredIssuerNameRealm      = $null
                SigningCertificateFilePath     = "F:\Data\DSC\FakeSigning.cer"
                IsTrustBroker                  = $true
                Ensure                         = "Present"
            }

            It "Should create the SPTrustedSecurityTokenIssuer using the realm of the farm" {
                Set-TargetResource @testParams
                Assert-MockCalled -CommandName "New-SPTrustedSecurityTokenIssuer"
                Assert-MockCalled -Times 1 -CommandName "Get-SPAuthenticationRealm"
            }
        }

        Context -Name "The SPTrustedSecurityTokenIssuer does not exist and should be created, using a custom realm" -Fixture {
            $testParams = @{
                Name                           = "HighTrust"
                Description                    = "HighTrust fake"
                RegisteredIssuerNameIdentifier = "22222222-2222-2222-2222-222222222222"
                RegisteredIssuerNameRealm      = "C47023F3-4109-4C6E-8913-DFC3DBACD8C5"
                SigningCertificateThumbprint   = "123ABCFACE123ABCFACE123ABCFACE123ABCFACE"
                IsTrustBroker                  = $true
                Ensure                         = "Present"
            }

            It "Should create the SPTrustedSecurityTokenIssuer using the custom realm" {
                Set-TargetResource @testParams
                Assert-MockCalled -CommandName "New-SPTrustedSecurityTokenIssuer"
                Assert-MockCalled -Times 0 -CommandName "Get-SPAuthenticationRealm"
            }
        }

        Context -Name "The SPTrustedSecurityTokenIssuer does not exist and should be created, using a MetadataEndPoint" -Fixture {
            $testParams = @{
                Name             = "HighTrust"
                Description      = "HighTrust fake"
                MetadataEndPoint = "https://accounts.accesscontrol.windows.net/TENANT.onmicrosoft.com/metadata/json/1"
                IsTrustBroker    = $true
                Ensure           = "Present"
            }

            It "Should create the SPTrustedSecurityTokenIssuer using a MetadataEndPoint" {
                Set-TargetResource @testParams
                Assert-MockCalled -CommandName "New-SPTrustedSecurityTokenIssuer"
                Assert-MockCalled -Times 0 -CommandName "Get-SPAuthenticationRealm"
            }
        }

        Context -Name "The SPTrustedSecurityTokenIssuer is desired, but both parameters SigningCertificateThumbprint and SigningCertificateFilePath are set while exactly 1 should" -Fixture {
            $testParams = @{
                Name                           = "HighTrust"
                Description                    = "HighTrust fake"
                RegisteredIssuerNameIdentifier = "22222222-2222-2222-2222-222222222222"
                SigningCertificateThumbprint   = "123ABCFACE123ABCFACE123ABCFACE123ABCFACE"
                SigningCertificateFilePath     = "F:\Data\DSC\FakeSigning.cer"
                IsTrustBroker                  = $true
                Ensure                         = "Present"
            }

            It "should fail validation of signing certificate parameters in the Set method" {
                { Set-TargetResource @testParams } | Should Throw "Cannot use both parameters SigningCertificateThumbprint and SigningCertificateFilePath at the same time."
            }

            It "should fail validation of signing certificate parameters in the Test method" {
                { Test-TargetResource @testParams } | Should Throw "Cannot use both parameters SigningCertificateThumbprint and SigningCertificateFilePath at the same time."
            }
        }

        Context -Name "The SPTrustedSecurityTokenIssuer is desired, but both parameters SigningCertificateThumbprint and MetadataEndPoint are set while exactly 1 should" -Fixture {
            $testParams = @{
                Name                           = "HighTrust"
                Description                    = "HighTrust fake"
                RegisteredIssuerNameIdentifier = "22222222-2222-2222-2222-222222222222"
                SigningCertificateThumbprint   = "123ABCFACE123ABCFACE123ABCFACE123ABCFACE"
                MetadataEndPoint               = "https://accounts.accesscontrol.windows.net/TENANT.onmicrosoft.com/metadata/json/1"
                IsTrustBroker                  = $true
                Ensure                         = "Present"
            }

            It "should fail validation of signing certificate parameters in the Set method" {
                { Set-TargetResource @testParams } | Should Throw "Cannot use both parameters SigningCertificateThumbprint and MetadataEndPoint at the same time."
            }

            It "should fail validation of signing certificate parameters in the Test method" {
                { Test-TargetResource @testParams } | Should Throw "Cannot use both parameters SigningCertificateThumbprint and MetadataEndPoint at the same time."
            }
        }

        Context -Name "The SPTrustedSecurityTokenIssuer is desired, but both parameters SigningCertificateFilePath and MetadataEndPoint are set while exactly 1 should" -Fixture {
            $testParams = @{
                Name                           = "HighTrust"
                Description                    = "HighTrust fake"
                RegisteredIssuerNameIdentifier = "22222222-2222-2222-2222-222222222222"
                SigningCertificateFilePath     = "F:\Data\DSC\FakeSigning.cer"
                MetadataEndPoint               = "https://accounts.accesscontrol.windows.net/TENANT.onmicrosoft.com/metadata/json/1"
                IsTrustBroker                  = $true
                Ensure                         = "Present"
            }

            It "should fail validation of signing certificate parameters in the Set method" {
                { Set-TargetResource @testParams } | Should Throw "Cannot use both parameters SigningCertificateFilePath and MetadataEndPoint at the same time."
            }

            It "should fail validation of signing certificate parameters in the Test method" {
                { Test-TargetResource @testParams } | Should Throw "Cannot use both parameters SigningCertificateFilePath and MetadataEndPoint at the same time."
            }
        }

        Context -Name "The SPTrustedSecurityTokenIssuer is desired, but the thumbprint of the signing certificate in parameter SigningCertificateThumbprint is invalid" -Fixture {
            $testParams = @{
                Name                           = "HighTrust"
                Description                    = "HighTrust fake"
                RegisteredIssuerNameIdentifier = "22222222-2222-2222-2222-222222222222"
                SigningCertificateThumbprint   = "XX123ABCFACEXX"
                IsTrustBroker                  = $true
                Ensure                         = "Present"
            }

            It "should fail validation of parameter SigningCertificateThumbprint in the Set method" {
                { Set-TargetResource @testParams } | Should Throw "Parameter SigningCertificateThumbprint does not match valid format '^[A-Fa-f0-9]{40}$'."
            }
        }

        Context -Name "The SPTrustedSecurityTokenIssuer already exists and should not be changed" -Fixture {
            $testParams = @{
                Name                           = "HighTrust"
                Description                    = "HighTrust fake"
                RegisteredIssuerNameIdentifier = "22222222-2222-2222-2222-222222222222"
                SigningCertificateThumbprint   = "123ABCFACE123ABCFACE123ABCFACE123ABCFACE"
                IsTrustBroker                  = $true
                Ensure                         = "Present"
            }

            Mock -CommandName Get-SPTrustedSecurityTokenIssuer -MockWith {
                $sptrust = [pscustomobject]@{
                    Name                 = $testParams.Name
                    RegisteredIssuerName = "$($testParams.RegisteredIssuerNameIdentifier)@$(Get-SPAuthenticationRealm)"
                }
                return $sptrust
            }

            It "Should be returned the get method with expected properties" {
                $getResults = Get-TargetResource @testParams
                $getResults.Ensure | Should Be "Present"
                $getResults.RegisteredIssuerNameIdentifier | Should Be "$($testParams.RegisteredIssuerNameIdentifier)"
                $getResults.RegisteredIssuerNameRealm | Should Be "$(Get-SPAuthenticationRealm)"
            }

            It "Should return true from the Test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "The SPTrustedSecurityTokenIssuer exists and should be removed" -Fixture {
            $testParams = @{
                Name                           = "HighTrust"
                Description                    = "HighTrust fake"
                RegisteredIssuerNameIdentifier = "22222222-2222-2222-2222-222222222222"
                SigningCertificateThumbprint   = "123ABCFACE123ABCFACE123ABCFACE123ABCFACE"
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

            It "Should be returned the get method with expected properties" {
                $getResults = Get-TargetResource @testParams
                $getResults.Ensure | Should Be "Present"
                $getResults.RegisteredIssuerNameIdentifier | Should Be "$($testParams.RegisteredIssuerNameIdentifier)"
                $getResults.RegisteredIssuerNameRealm | Should Be "$(Get-SPAuthenticationRealm)"
            }

            It "Should return false from the Test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should remove the SPTrustedSecurityTokenIssuer" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPTrustedSecurityTokenIssuer
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
