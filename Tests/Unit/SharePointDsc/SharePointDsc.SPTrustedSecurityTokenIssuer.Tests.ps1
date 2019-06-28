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
                Name = $testParams.Name
            }
            $sptrust | Add-Member -Name Update -MemberType ScriptMethod -Value { }
            return $sptrust
        }

        # Mock -CommandName New-SPTrustedSecurityTokenIssuer {
        #     return @{
        #         NameId = "22222222-2222-2222-2222-222222222222@bc23e3e4-5899-4b5d-9cee-27344da5deb5"
        #         Certificate = [pscustomobject]@{
        #             Thumbprint = "123ABCFACE123ABCFACE123ABCFACE123ABCFACE"
        #         }
        #     }
        # }

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

        # Test contexts
        Context -Name "The SPTrustedSecurityTokenIssuer does not exist but should, using a signing certificate in the certificate store" -Fixture {
            $testParams = @{
                Name                         = "HighTrust"
                Description                  = "HighTrust fake"
                RegisteredIssuerNameIdentifier = "22222222-2222-2222-2222-222222222222"
                RegisteredIssuerNameRealm = $null
                SigningCertificateThumbprint   = "123ABCFACE123ABCFACE123ABCFACE123ABCFACE"
                IsTrustBroker            = $true
                Ensure                       = "Present"
            }

            It "Should return absent from the get method" {
                $getResults = Get-TargetResource @testParams
                $getResults.Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should create the SPTrustedSecurityTokenIssuer" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPTrustedSecurityTokenIssuer
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
