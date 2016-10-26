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
                                              -DscResource "SPManagedPath"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope
        
        # Mocks for all contexts   
        Mock -CommandName New-SPManagedPath -MockWith { }
        Mock -CommandName Remove-SPManagedPath -MockWith { }

        # Test contexts
        Context -Name "The managed path does not exist and should" -Fixture {
            $testParams = @{
                WebAppUrl   = "http://sites.sharepoint.com"
                RelativeUrl = "teams"
                Explicit    = $false
                HostHeader  = $false
                Ensure      = "Present"
            }

            Mock -CommandName Get-SPManagedPath -MockWith { 
                return $null 
            }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should create a host header path in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPManagedPath
            }

            $testParams.HostHeader = $true
            It "Should create a host header path in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPManagedPath
            }
        }

        Context -Name "The path exists but is of the wrong type" -Fixture {
            $testParams = @{
                WebAppUrl   = "http://sites.sharepoint.com"
                RelativeUrl = "teams"
                Explicit    = $false
                HostHeader  = $false
                Ensure      = "Present"
            }
            
            Mock -CommandName Get-SPManagedPath -MockWith { 
                return @{
                    Name = $testParams.RelativeUrl
                    Type = "ExplicitInclusion"
                } 
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context -Name "The path exists and is the correct type" -Fixture {
            $testParams = @{
                WebAppUrl   = "http://sites.sharepoint.com"
                RelativeUrl = "teams"
                Explicit    = $false
                HostHeader  = $false
                Ensure      = "Present"
            }
            
            Mock -CommandName Get-SPManagedPath -MockWith { 
                return @{
                    Name = $testParams.RelativeUrl
                    Type = "WildcardInclusion"
                } 
            }

            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        Context -Name "The managed path exists but shouldn't" -Fixture {
            $testParams = @{
                WebAppUrl   = "http://sites.sharepoint.com"
                RelativeUrl = "teams"
                Explicit    = $false
                HostHeader  = $false
                Ensure      = "Absent"
            }

            Mock -CommandName Get-SPManagedPath -MockWith { 
                return @{
                    Name = $testParams.RelativeUrl
                    Type = "WildcardInclusion"
                } 
            }
            
            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }
            
            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "Should call the remove cmdlet from the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPManagedPath
            }
        }
        
        Context -Name "The managed path doesn't exist and shouldn't" -Fixture {
            $testParams = @{
                WebAppUrl   = "http://sites.sharepoint.com"
                RelativeUrl = "teams"
                Explicit    = $false
                HostHeader  = $false
                Ensure      = "Absent"
            }
            
            Mock -CommandName Get-SPManagedPath -MockWith { 
                return $null 
            }
            
            It "Should return absent from the set method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }
            
            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
