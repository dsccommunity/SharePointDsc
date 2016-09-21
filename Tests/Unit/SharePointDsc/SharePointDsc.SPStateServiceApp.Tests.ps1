[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
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
                                              -DscResource "SPStateServiceApp"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests
        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
        $mockCredential = New-Object -TypeName System.Management.Automation.PSCredential `
                                     -ArgumentList @("username", $mockPassword)

        # Mocks for all contexts   
        Mock -CommandName New-SPStateServiceDatabase -MockWith { return @{} }
        Mock -CommandName New-SPStateServiceApplication -MockWith { return @{} }
        Mock -CommandName New-SPStateServiceApplicationProxy -MockWith { return @{} }
        Mock -CommandName Remove-SPServiceApplication -MockWith { }

        # Test contexts
        Context -Name "the service app doesn't exist and should" -Fixture {
            $testParams = @{
                Name = "State Service App"
                DatabaseName = "SP_StateService"
                DatabaseServer = "SQL.test.domain"
                DatabaseCredentials = $mockCredential
                Ensure = "Present"
            }

            Mock -CommandName Get-SPStateServiceApplication -MockWith { 
                return $null 
            }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }

            It "Should return false from the get method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should create a state service app from the set method" {
                Set-TargetResource @testParams 

                Assert-MockCalled New-SPStateServiceApplication
            }
        }

        Context -Name "the service app exists and should" -Fixture {
            $testParams = @{
                Name = "State Service App"
                DatabaseName = "SP_StateService"
                DatabaseServer = "SQL.test.domain"
                DatabaseCredentials = $mockCredential
                Ensure = "Present"
            }
            
            Mock -CommandName Get-SPStateServiceApplication -MockWith { 
                return @{ 
                    DisplayName = $testParams.Name 
                } 
            }

            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present" 
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        Context -Name "When the service app exists but it shouldn't" -Fixture {
            $testParams = @{
                Name = "State Service App"
                DatabaseName = "-"
                Ensure = "Absent"
            }
            
            Mock -CommandName Get-SPStateServiceApplication -MockWith { 
                return @{ 
                    DisplayName = $testParams.Name 
                } 
            }
            
            It "Should return present from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present" 
            }
            
            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "Should remove the service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPServiceApplication
            }
        }
        
        Context -Name "When the service app doesn't exist and shouldn't" -Fixture {
            $testParams = @{
                Name = "State Service App"
                DatabaseName = "-"
                Ensure = "Absent"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return $null 
            }
            
            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }
            
            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
