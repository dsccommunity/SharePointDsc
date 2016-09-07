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
                                              -DscResource "SPAccessServiceApp"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Mocks for all contexts
        Mock -CommandName New-SPAccessServicesApplication -MockWith { }
        Mock -CommandName Set-SPAccessServicesApplication -MockWith { }
        Mock -CommandName Remove-SPServiceApplication -MockWith { }

        Context -Name "When no service applications exist in the current farm" -Fixture {
            $testParams = @{
                Name = "Test Access Services App"
                DatabaseServer = "SQL.contoso.local"
                ApplicationPool = "Test App Pool"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return $null 
            }
            
            It "Should return null from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should create a new service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPAccessServicesApplication 
            }
        }

        Context -Name "When service applications exist in the current farm but the specific Access Services app does not" -Fixture {
            $testParams = @{
                Name = "Test Access Services App"
                DatabaseServer = "SQL.contoso.local"
                ApplicationPool = "Test App Pool"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return @(@{
                    TypeName = "Some other service app type"
                }) 
            }

            It "Should return null from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }
        }

        Context -Name "When a service application exists and is configured correctly" -Fixture {
            $testParams = @{
                Name = "Test Access Services App"
                DatabaseServer = "SQL.contoso.local"
                ApplicationPool = "Test App Pool"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return @(@{
                    TypeName = "Access Services Web Service Application"
                    DisplayName = $testParams.Name
                    DatabaseServer = $testParams.DatebaseName
                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                })
            }

            It "Should return values from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present" 
            }

            It "Should return true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        Context -Name "When the service application exists but it shouldn't" -Fixture {
            $testParams = @{
                Name = "Test App"
                ApplicationPool = "-"
                DatabaseServer = "-"
                Ensure = "Absent"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return @(@{
                    TypeName = "Access Services Web Service Application"
                    DisplayName = $testParams.Name
                    DatabaseServer = $testParams.DatabaseServer
                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                })
            }
            
            It "Should return present from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present" 
            }
            
            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "Should call the remove service application cmdlet in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPServiceApplication
            }
        }
        
        Context -Name "When the serivce application doesn't exist and it shouldn't" -Fixture {
            $testParams = @{
                Name = "Test App"
                ApplicationPool = "-"
                DatabaseServer = "-"
                Ensure = "Absent"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return $null 
            }
            
            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }
            
            It "Should return true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
