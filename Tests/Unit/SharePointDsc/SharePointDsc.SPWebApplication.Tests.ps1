[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_SPWebApplication"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\Modules\SharePointDsc.Util\SharePointDsc.Util.psm1") -Force

Describe "SPWebApplication - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "SharePoint Sites"
            ApplicationPool = "SharePoint Web Apps"
            ApplicationPoolAccount = "DEMO\ServiceAccount"
            Url = "http://sites.sharepoint.com"
            AuthenticationMethod = "NTLM"
            Ensure = "Present"
        }
        
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDsc")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue

        Mock -CommandName New-SPAuthenticationProvider { }
        Mock -CommandName New-SPWebApplication { }
        Mock -CommandName Remove-SPWebApplication { }

        Context -Name "The specified Managed Account does not exist" {
            Mock -CommandName Get-SPWebapplication -MockWith { return $null }
            Mock -CommandName Get-SPDSCContentService {
                return @{ Name = "PlaceHolder" }
            }
            Mock -CommandName Get-SPManagedAccount {
                Throw "No matching accounts were found"
            }

            It "retrieving Managed Account fails in the set method" {
                { Set-TargetResource @testParams } | Should Throw "The specified managed account was not found. Please make sure the managed account exists before continuing."
            }
        }

        Context -Name "The web application that uses NTLM doesn't exist but should" {
            Mock -CommandName Get-SPWebapplication -MockWith { return $null }
            Mock -CommandName Get-SPDSCContentService {
                return @{ Name = "PlaceHolder" }
            }
            Mock -CommandName Get-SPManagedAccount {}

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call the new cmdlet from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled New-SPWebApplication
                Assert-MockCalled New-SPAuthenticationProvider -ParameterFilter { $DisableKerberos -eq $true }
            }

            $testParams.Add("InstallAccount", (New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))))
            It "Should call the new cmdlet from the set method where InstallAccount is used" {
                Set-TargetResource @testParams

                Assert-MockCalled New-SPWebApplication
                Assert-MockCalled New-SPAuthenticationProvider -ParameterFilter { $DisableKerberos -eq $true }
            }
            $testParams.Remove("InstallAccount")

            $testParams.Add("AllowAnonymous", $true)
            It "Should call the new cmdlet from the set where anonymous authentication is requested" {
                Set-TargetResource @testParams

                Assert-MockCalled New-SPWebApplication
                Assert-MockCalled New-SPAuthenticationProvider -ParameterFilter { $DisableKerberos -eq $true }
            }
            $testParams.Remove("AllowAnonymous")
        }

        $testParams.AuthenticationMethod = "Kerberos"

        Context -Name "The web application that uses Kerberos doesn't exist but should" {
            Mock -CommandName Get-SPWebapplication -MockWith { return $null }
            Mock -CommandName Get-SPDSCContentService {
                return @{ Name = "PlaceHolder" }
            }
            Mock -CommandName Get-SPManagedAccount {}

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call the new cmdlet from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled New-SPWebApplication
            }
        }

        $testParams.AuthenticationMethod = "NTLM"

        Context -Name "The web appliation does exist and should that uses NTLM" {
            Mock -CommandName Get-SPAuthenticationProvider { return @{ DisableKerberos = $true; AllowAnonymous = $false } }
            Mock -CommandName Get-SPWebapplication -MockWith { return @(@{
                DisplayName = $testParams.Name
                ApplicationPool = @{ 
                    Name = $testParams.ApplicationPool
                    Username = $testParams.ApplicationPoolAccount
                }
                ContentDatabases = @(
                    @{
                        Name = "SP_Content_01"
                        Server = "sql.domain.local"
                    }
                )
                IisSettings = @( 
                    @{ Path = "C:\inetpub\wwwroot\something" }
                )
                Url = $testParams.Url
            })}

            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        $testParams.AuthenticationMethod = "Kerberos"

        Context -Name "The web appliation does exist and should that uses Kerberos" {
            Mock -CommandName Get-SPAuthenticationProvider { return @{ DisableKerberos = $false; AllowAnonymous = $false } }
            Mock -CommandName Get-SPWebapplication -MockWith { return @(@{
                DisplayName = $testParams.Name
                ApplicationPool = @{ 
                    Name = $testParams.ApplicationPool
                    Username = $testParams.ApplicationPoolAccount
                }
                ContentDatabases = @(
                    @{
                        Name = "SP_Content_01"
                        Server = "sql.domain.local"
                    }
                )
                IisSettings = @( 
                    @{ Path = "C:\inetpub\wwwroot\something" }
                )
                Url = $testParams.Url
            })}

            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        $testParams = @{
            Name = "SharePoint Sites"
            ApplicationPool = "SharePoint Web Apps"
            ApplicationPoolAccount = "DEMO\ServiceAccount"
            Url = "http://sites.sharepoint.com"
            AuthenticationMethod = "NTLM"
            Ensure = "Absent"
        }
        
        Context -Name "A web application exists but shouldn't" {
            Mock -CommandName Get-SPAuthenticationProvider { return @{ DisableKerberos = $true; AllowAnonymous = $false } }
            Mock -CommandName Get-SPWebapplication -MockWith { return @(@{
                DisplayName = $testParams.Name
                ApplicationPool = @{ 
                    Name = $testParams.ApplicationPool
                    Username = $testParams.ApplicationPoolAccount
                }
                ContentDatabases = @(
                    @{
                        Name = "SP_Content_01"
                        Server = "sql.domain.local"
                    }
                )
                IisSettings = @( 
                    @{ Path = "C:\inetpub\wwwroot\something" }
                )
                Url = $testParams.Url
            })}
            
            It "Should return present from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present" 
            }
            
            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "Should remove the web application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPWebApplication
            }
        }
        
        Context -Name "A web application doesn't exist and shouldn't" {
            Mock -CommandName Get-SPWebapplication -MockWith { return $null }
            
            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }
            
            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }    
}
