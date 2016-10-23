[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string] 
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
                                         -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
                                         -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
                                -ChildPath "..\SharePointDsc.TestHarness.psm1" `
                                -Resolve)

$Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
                                              -DscResource "SPOfficeOnlineServerBinding"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Mocks for all contexts   
        Mock -CommandName Remove-SPWOPIBinding -MockWith {}
        Mock -CommandName New-SPWOPIBinding -MockWith {}
        Mock -CommandName Set-SPWOPIZone -MockWith {}
        Mock -CommandName Get-SPWOPIZone -MockWith { return "internal-https" }
        
        # Test contexts
        Context -Name "No bindings are set for the specified zone, but they should be" -Fixture {
            $testParams = @{
                Zone    = "internal-https"
                DnsName = "webapps.contoso.com"
                Ensure  = "Present"
            }

            Mock -CommandName Get-SPWOPIBinding -MockWith {
                return $null
            }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should create the bindings in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPWOPIBinding 
                Assert-MockCalled Set-SPWOPIZone
            }
        }

        Context -Name "Incorrect bindings are set for the specified zone that should be configured" -Fixture {
            $testParams = @{
                Zone    = "internal-https"
                DnsName = "webapps.contoso.com"
                Ensure  = "Present"
            }

            Mock -CommandName Get-SPWOPIBinding -MockWith {
                return @(
                    @{
                        ServerName = "wrong.contoso.com"
                    }
                )
            }

            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should remove the old bindings and create the new bindings in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPWOPIBinding
                Assert-MockCalled New-SPWOPIBinding 
                Assert-MockCalled Set-SPWOPIZone
            }
        }

        Context -Name "Correct bindings are set for the specified zone" -Fixture {
            $testParams = @{
                Zone    = "internal-https"
                DnsName = "webapps.contoso.com"
                Ensure  = "Present"
            }

            Mock -CommandName Get-SPWOPIBinding -MockWith {
                return @(
                    @{
                        ServerName = "webapps.contoso.com"
                    }
                )
            }

            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "Bindings are set for the specified zone, but they should not be" -Fixture {
            $testParams = @{
                Zone    = "internal-https"
                DnsName = "webapps.contoso.com"
                Ensure  = "Absent"
            }

            Mock -CommandName Get-SPWOPIBinding -MockWith {
                return @(
                    @{
                        ServerName = "webapps.contoso.com"
                    }
                )
            }

            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should remove the bindings in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPWOPIBinding
            }
        } 

        Context -Name "Bindings are not set for the specified zone, and they should not be" -Fixture {
            $testParams = @{
                Zone    = "internal-https"
                DnsName = "webapps.contoso.com"
                Ensure  = "Absent"
            }

            Mock -CommandName Get-SPWOPIBinding -MockWith {
                return $null
            }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
