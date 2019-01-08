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
                                              -DscResource "SPAuthenticationRealm"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        Mock -CommandName Get-SPAuthenticationRealm {
            return $Global:SPAuthenticationRealm
        }

        Mock -CommandName Set-SPAuthenticationRealm {
            $Global:SPAuthenticationRealm = $Realm
        }

        Context -Name "Authentication realm matches the farm's current atuhentication realm" -Fixture {
            $Global:SPAuthenticationRealm = [System.Guid]"14757a87-4d74-4323-83b9-fb1e77e8f22f"
            $testParams = @{
                IsSingleInstance = "Yes"
                AuthenticationRealm = $Global:SPAuthenticationRealm
            }

            It "Should return true from the set method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "Authentication realm does not match the farm's current atuhentication realm" -Fixture {
            $Global:SPAuthenticationRealm = [System.Guid]"11111111-1111-1111-1111-111111111111"

            $testParams = @{
                IsSingleInstance = "Yes"
                AuthenticationRealm = [System.Guid]"14757a87-4d74-4323-83b9-fb1e77e8f22f"
            }

            It "Should return false from the set method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should modify the authentication realm in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled -CommandName Set-SPAuthenticationRealm -Times 1
                $Global:SPAuthenticationRealm | Should Be "14757a87-4d74-4323-83b9-fb1e77e8f22f"
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
