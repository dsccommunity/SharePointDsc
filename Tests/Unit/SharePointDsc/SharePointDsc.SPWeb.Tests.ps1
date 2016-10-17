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
                                              -DscResource "SPWeb"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests
        $fakeWebApp = [PSCustomObject]@{ }
        $fakeWebApp | Add-Member -MemberType ScriptMethod `
                                 -Name GrantAccessToProcessIdentity `
                                 -PassThru `
                                 -Value { }

        # Mocks for all contexts   
        Mock -CommandName New-Object -MockWith { 
            [PSCustomObject]@{ 
                WebApplication = $fakeWebApp
            } 
        } -ParameterFilter { 
            $TypeName -eq "Microsoft.SharePoint.SPSite" 
        }
        Mock -CommandName Remove-SPWeb -MockWith { }
        
        # Test contexts
        Context -Name "The SPWeb doesn't exist yet and should" -Fixture {
            $testParams = @{
                Url = "http://site.sharepoint.com/sites/web"
                Name = "Team Site"
                Description = "desc"
            }

            Mock -CommandName Get-SPWeb -MockWith { return $null }

            It "Should return 'Absent' from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should create a new SPWeb from the set method" {
                Mock -CommandName New-SPWeb { } -Verifiable

                Set-TargetResource @testParams

                Assert-MockCalled New-SPWeb
                Assert-MockCalled New-Object
            }
        }

        Context -Name "The SPWeb exists and has the correct name and description" -Fixture {
            $testParams = @{
                Url = "http://site.sharepoint.com/sites/web"
                Name = "Team Site"
                Description = "desc"
            }

            Mock -CommandName Get-SPWeb -MockWith { 
                return @{
                    Url           = $testParams.Url
                    Title         = $testParams.Name
                    Description   = $testParams.Description
                    WebTemplate   = "STS"
                    WebTemplateId = "0"
                    Navigation    = @{ UseShared = $true }
                    Language      = 1033
                    HasUniquePerm = $false
                }
            }

            It "Should return the SPWeb data from the get method" {
                
                $result = Get-TargetResource @testParams

                $result.Ensure            | Should be "Present"
                $result.Template          | Should be "STS#0"
                $result.UniquePermissions | Should be $false
                $result.UseParentTopNav   | Should be $true                

            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        Context -Name "The SPWeb exists and should not" -Fixture {
            $testParams = @{
                Url = "http://site.sharepoint.com/sites/web"
                Name = "Team Site"
                Description = "desc"
                Ensure = "Absent"
            }

            Mock -CommandName Get-SPWeb -MockWith { 
                return @{
                    Url           = $testParams.Url
                }
            }

            It "Should return 'Present' from the get method" {
                (Get-TargetResource @testParams).Ensure | Should be "Present"             
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should remove the SPWeb in the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Remove-SPWeb
            }
        }

        Context -Name "The SPWeb exists but has the wrong editable values" -Fixture {
            $testParams = @{
                Url = "http://site.sharepoint.com/sites/web"
                Name = "Team Site"
                Description = "desc"
                UseParentTopNav = $false
                UniquePermissions = $true
            }

            $web = [pscustomobject] @{
                Url           = $testParams.Url
                Title         = "Another title"
                Description   = "Another description"
                Navigation    = @{ UseShared = $true }
                HasUniquePerm = $false
            }

            $web |  Add-Member -Name Update `
                               -MemberType ScriptMethod `
                               -Value { }

            Mock -CommandName Get-SPWeb -MockWith { $web }

            It "Should return the SPWeb data from the get method" {
                
                $result = Get-TargetResource @testParams

                $result.Ensure            | Should be "Present"
                $result.UniquePermissions | Should be $false
                $result.UseParentTopNav   | Should be $true                

            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should update the values in the set method" {
                
                Set-TargetResource @testParams

                $web.Title       | Should be $testParams.Name
                $web.Description | Should be $testParams.Description
                $web.Navigation.UseShared | Should be $false
                $web.HasUniquePerm | Should be $true

                Assert-MockCalled New-Object
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
