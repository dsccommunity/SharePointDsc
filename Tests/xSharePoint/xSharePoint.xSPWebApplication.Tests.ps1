[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule

$ModuleName = "MSFT_xSPWebApplication"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPWebApplication" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Managed Metadata Service App"
            ApplicationPool = "SharePoint Web Apps"
            ApplicationPoolAccount = "DEMO\ServiceAccount"
            Url = "http://sites.sharepoint.com"
            AuthenticationMethod = "NTLM"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue
        
        Mock New-SPAuthenticationProvider { }
        Mock New-SPWebApplication { }


        Context "The web application that uses NTLM doesn't exist but should" {
            Mock Get-SPWebApplication { return $null }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "calls the new cmdlet from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled New-SPWebApplication
                Assert-MockCalled New-SPAuthenticationProvider -ParameterFilter { $DisableKerberos -eq $true }
            }

            $testParams.Add("InstallAccount", (New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))))
            It "calls the new cmdlet from the set method where InstallAccount is used" {
                Set-TargetResource @testParams

                Assert-MockCalled New-SPWebApplication
                Assert-MockCalled New-SPAuthenticationProvider -ParameterFilter { $DisableKerberos -eq $true }
            }
            $testParams.Remove("InstallAccount")

            $testParams.Add("AllowAnonymous", $true)
            It "calls the new cmdlet from the set where anonymous authentication is requested" {
                Set-TargetResource @testParams

                Assert-MockCalled New-SPWebApplication
                Assert-MockCalled New-SPAuthenticationProvider -ParameterFilter { $DisableKerberos -eq $true }
            }
            $testParams.Remove("AllowAnonymous")
        }

        $testParams.AuthenticationMethod = "Kerberos"

        Context "The web application that uses Kerberos doesn't exist but should" {
            Mock Get-SPWebApplication { return $null }

            It "returns null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "calls the new cmdlet from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled New-SPWebApplication
            }
        }

        $testParams.AuthenticationMethod = "NTLM"

        Context "The web appliation does exist and should that uses NTLM" {
            Mock Get-SPAuthenticationProvider { return @{ DisableKerberos = $true; AllowAnonymous = $false } }
            Mock Get-SPWebApplication { return @(@{
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

            It "returns the current data from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        $testParams.AuthenticationMethod = "Kerberos"

        Context "The web appliation does exist and should that uses Kerberos" {
            Mock Get-SPAuthenticationProvider { return @{ DisableKerberos = $false; AllowAnonymous = $false } }
            Mock Get-SPWebApplication { return @(@{
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

            It "returns the current data from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "backwards compatibility: set target resorce works with null/missing BlockedFileTypes" {
            Mock Get-SPAuthenticationProvider { return @{ DisableKerberos = $false; AllowAnonymous = $false } }
            Mock Get-SPWebApplication { 
                $result =  @(@{
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
                })
                $blockedFileTypes= @();
                $blockedFileTypes= $blockedFileTypes | Add-Member  ScriptMethod RemoveAll { 
                    $Global:BlockedFilesRemoveAllCalled = $true;
                    return $true;
                } -passThru
                $blockedFileTypes= $blockedFileTypes | Add-Member  ScriptMethod Add {
                    param( [string]$fileType)
                    $Global:BlockedFilesAddCalled = $true;
                    return $true;
                } -passThru
                $result= $result | Add-Member -MemberType MemberSet -value $blockedFileTypes -Name "BlockedFileExtensions"
                 $result = $result | Add-Member -MemberType ScriptMethod Update { 
                    $Global:SPWebApplicationUpdateCalled = $true;
                    return $true;
                
                    } -PassThru
                return $result;
            }

            It "calls the new cmdlet from the set method and does not touch blockedFileExtensions" {
                $Global:SPWebApplicationUpdateCalled = $false;
                $Global:BlockedFilesAddCalled = $false;
                $Global:BlockedFilesRemoveAllCalled = $false;
                Set-TargetResource @testParams
                $Global:BlockedFilesAddCalled| Should be  $false;
                $Global:BlockedFilesRemoveAllCalled| Should be  $false;
                $Global:SPWebApplicationUpdateCalled| Should be  $false;
                Assert-MockCalled New-SPWebApplication
            }

        }
    
       $testParams = @{
            Name = "Managed Metadata Service App"
            ApplicationPool = "SharePoint Web Apps"
            ApplicationPoolAccount = "DEMO\ServiceAccount"
            Url = "http://sites.sharepoint.com"
            AuthenticationMethod = "NTLM"
            BlockedFileTypes  = @("java", "vbs")
        }


        Context "set target resorce works with blockedFileTypes" {
            Mock Get-SPAuthenticationProvider { return @{ DisableKerberos = $false; AllowAnonymous = $false } }
            
            Mock Get-SPWebApplication {  $result= @(@{
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
                })
               
               $blockedFileTypes = new-object PSObject 
               $blockedFileTypes =  $blockedFileTypes | Add-Member  ScriptMethod RemoveAll { 
                    $Global:BlockedFilesRemoveAllCalled = $true;
                    return $true;
                } -passThru
               $blockedFileTypes = $blockedFileTypes | Add-Member  ScriptMethod Add {
                    param( [string]$fileType)
                    $Global:BlockedFilesAddCalled = $true;
                    return $true;
                } -passThru

                $result=$result| Add-Member  ScriptMethod Update { 
                    $Global:SPWebApplicationUpdateCalled = $true;
                    return $true;               
                   } -PassThru
               
                              $result= $result | Add-Member NoteProperty  -value $blockedFileTypes -Name "BlockedFileExtensions" -PassThru

            return $result
            }

            It "calls the new cmdlet from the set method and does update blockedFileExtensions" {
                $Global:BlockedFilesAddCalled = $false;
                $Global:BlockedFilesRemoveAllCalled = $false;
                Set-TargetResource @testParams
                $Global:BlockedFilesAddCalled| Should be  $true;
                $Global:BlockedFilesRemoveAllCalled| Should be  $true;
                $Global:SPWebApplicationUpdateCalled| Should be  $true;

                Assert-MockCalled Get-SPWebApplication
            }

        }
 

    }    
}