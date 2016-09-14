[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPWeb"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPWeb - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {

    InModuleScope $ModuleName {

        $testParams = @{
            Url = "http://site.sharepoint.com/sites/web"
            Name = "Team Site"
            Description = "desc"
        }

        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDsc")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        
        $fakeWebApp = [PSCustomObject]@{ }
        $fakeWebApp | Add-Member -MemberType ScriptMethod -Name GrantAccessToProcessIdentity -PassThru -Value { }

        Mock -CommandName New-Object { [PSCustomObject]@{ WebApplication = $fakeWebApp} } -Verifiable -ParameterFilter { $TypeName -eq "Microsoft.SharePoint.SPSite" }
        
        Mock -CommandName Remove-SPWeb { } -Verifiable

        Context -Name "The SPWeb doesn't exist yet and should" {

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

        Context -Name "The SPWeb exists and has the correct name and description" {

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
        
        Context -Name "The SPWeb exists and should not" {
            
            $testParams.Ensure = "Absent"

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

        Context -Name "The SPWeb exists but has the wrong editable values" {

            $testParams.Ensure = "Present"
            $testParams.UseParentTopNav = $false
            $testParams.UniquePermissions = $true

            $web = [pscustomobject] @{
                Url           = $testParams.Url
                Title         = "Another title"
                Description   = "Another description"
                Navigation    = @{ UseShared = $true }
                HasUniquePerm = $false
            }

            $web |  Add-Member -Name Update -MemberType ScriptMethod  -Value { }

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
