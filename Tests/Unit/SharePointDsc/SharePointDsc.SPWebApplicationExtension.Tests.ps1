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
                                              -DscResource "SPWebApplicationExtension"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests

        # Mocks for all contexts   
        Mock -CommandName New-SPAuthenticationProvider -MockWith { }
        Mock -CommandName New-SPWebApplicationExtension -MockWith { }
        Mock -CommandName Remove-SPWebApplication -MockWith { }

        
        #Tests:
        # extension does not exist
        #  it should not
        # extention exists 
        #  it should
        #  it should not
        #  mismatch authentication
        #  mismatch AllowAnonymous


        # Test contexts
        Context -Name "The parent web application does not exist" -Fixture {
            $testParams = @{
                WebAppUrl = "http://nosuchwebapplication.sharepoint.com"
                Name = "Intranet Zone"
                Url = "http://intranet.sharepoint.com"
                Zone = "Intranet"
                AuthenticationMethod = "NTLM"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPWebapplication -MockWith { return $null }
            
            It "retrieving non-existent web application fails in the set method" {
                { Set-TargetResource @testParams } | Should Throw "Web Application with URL http://nosuchwebapplication.sharepoint.com does not exist"
            }
        }

        Context -Name "The web application extension that uses NTLM authentication doesn't exist but should" -Fixture {
            $testParams = @{
                WebAppUrl = "http://company.sharepoint.com"
                Name = "Intranet Zone"
                Url = "http://intranet.sharepoint.com"
                Zone = "Intranet"
                AuthenticationMethod = "NTLM"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPWebapplication -MockWith {
                 return @{ 
                     DisplayName = "Company SharePoint"
                     URL = "http://company.sharepoint.com"
                } 
            }

            Mock -CommandName Get-SPDSCWebAppExtension -MockWith { return $null }
            
            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call the new cmdlet from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled New-SPWebApplicationExtension
                Assert-MockCalled New-SPAuthenticationProvider -ParameterFilter { $DisableKerberos -eq $true }
            }

            $testParams.Add("AllowAnonymous", $true)
            It "Should call the new cmdlet from the set where anonymous authentication is requested" {
                Set-TargetResource @testParams

                Assert-MockCalled New-SPWebApplicationExtension
                Assert-MockCalled New-SPAuthenticationProvider -ParameterFilter { $DisableKerberos -eq $true }
            }
        }

        Context -Name "The web application extension that uses Kerberos doesn't exist but should" -Fixture {
            $testParams = @{
                WebAppUrl = "http://company.sharepoint.com"
                Name = "Intranet Zone"
                Url = "http://intranet.sharepoint.com"
                Zone = "Intranet"
                AuthenticationMethod = "Kerberos"
                Ensure = "Present"
            }

             Mock -CommandName Get-SPWebapplication -MockWith {
                 return @{ 
                     DisplayName = "Company SharePoint"
                     URL = "http://company.sharepoint.com"
                } 
            }

            Mock -CommandName Get-SPDSCWebAppExtension -MockWith { return $null }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call the new cmdlet from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled New-SPWebApplicationExtension
                Assert-MockCalled New-SPAuthenticationProvider -ParameterFilter { $DisableKerberos -eq $false }
            }
        }

        Context -Name "The web appliation extension does exist and should that uses NTLM without AllowAnonymous" -Fixture {
            $testParams = @{
                WebAppUrl = "http://company.sharepoint.com"
                Name = "Intranet Zone"
                Url = "http://intranet.sharepoint.com"
                HostHeader = "intranet.sharepoint.com"
                Zone = "Intranet"
                AuthenticationMethod = "NTLM"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPAuthenticationProvider -MockWith { 
                return @{ 
                    DisableKerberos = $true 
                    AllowAnonymous = $false 
                } 
            }
            
             Mock -CommandName Get-SPWebapplication -MockWith {
                 return (
                  @{ 
                     DisplayName = "Company SharePoint"
                     URL = "http://company.sharepoint.com"
                  } | add-member ScriptMethod Update { $Global:WebAppUpdateCalled = $true} -PassThru 
                 ) 
            }

            Mock -CommandName Get-SPAlternateUrl -MockWith {
                return @{
                    PublicURL = $testParams.Url 
                }
            }

            Mock -CommandName Get-SPDSCWebAppExtension -MockWith {
                return @{
                    ServerBindings = @{ 
                        HostHeader = $testParams.HostHeader
                        Port = 80
                    }
                    AllowAnonymous = $testParams.AllowAnonymous
                    DisableKerberos = $true  
                    Path = "c:\inetpub\wwwroot\wss\VirtualDirectories\intranet"
                }
            }


            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return AllowAnonymous False from the get method" {
                (Get-TargetResource @testParams).AllowAnonymous | Should Be $false
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }


        Context -Name "The web appliation extension does exist and should that uses NTLM and AllowAnonymous" -Fixture {
            $testParams = @{
                WebAppUrl = "http://company.sharepoint.com"
                Name = "Intranet Zone"
                Url = "http://intranet.sharepoint.com"
                HostHeader = "intranet.sharepoint.com"
                Zone = "Intranet"
                AuthenticationMethod = "NTLM"
                AllowAnonymous = $true 
                Ensure = "Present"
            }

            Mock -CommandName Get-SPAuthenticationProvider -MockWith { 
                return @{ 
                    DisableKerberos = $true 
                    AllowAnonymous = $true  
                } 
            }
            
             Mock -CommandName Get-SPWebapplication -MockWith {
                 return (
                  @{ 
                     DisplayName = "Company SharePoint"
                     URL = "http://company.sharepoint.com"
                  } | add-member ScriptMethod Update { $Global:WebAppUpdateCalled = $true} -PassThru 
                 ) 
            }

            Mock -CommandName Get-SPAlternateUrl -MockWith {
                return @{
                    PublicURL = $testParams.Url 
                }
            }
            
            Mock -CommandName Get-SPDSCWebAppExtension -MockWith {
                return @{
                    ServerBindings = @{ 
                        HostHeader = $testParams.HostHeader
                        Port = 80
                    }
                    AllowAnonymous = $testParams.AllowAnonymous
                    DisableKerberos = $true  
                    Path = "c:\inetpub\wwwroot\wss\VirtualDirectories\intranet"
                }
            }


            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return AllowAnonymous True from the get method" {
                (Get-TargetResource @testParams).AllowAnonymous | Should Be $true
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "The web appliation extension does exist and should that uses Kerberos without AllowAnonymous" -Fixture {
            $testParams = @{
                WebAppUrl = "http://company.sharepoint.com"
                Name = "Intranet Zone"
                Url = "http://intranet.sharepoint.com"
                HostHeader = "intranet.sharepoint.com"
                Zone = "Intranet"
                AuthenticationMethod = "Kerberos"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPAuthenticationProvider -MockWith { 
                return @{ 
                    DisableKerberos = $false 
                    AllowAnonymous = $false 
                } 
            }
            
             Mock -CommandName Get-SPWebapplication -MockWith {
                 return (
                  @{ 
                     DisplayName = "Company SharePoint"
                     URL = "http://company.sharepoint.com"
                  } | add-member ScriptMethod Update { $Global:WebAppUpdateCalled = $true} -PassThru 
                 ) 
            }

            Mock -CommandName Get-SPAlternateUrl -MockWith {
                return @{
                    PublicURL = $testParams.Url 
                }
            }

            Mock -CommandName Get-SPDSCWebAppExtension -MockWith {
                return @{
                    ServerBindings = @{ 
                        HostHeader = $testParams.HostHeader
                        Port = 80
                    }
                    AllowAnonymous = $testParams.AllowAnonymous
                    DisableKerberos = $false  
                    Path = "c:\inetpub\wwwroot\wss\VirtualDirectories\intranet"
                }
            }


            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return AllowAnonymous False from the get method" {
                (Get-TargetResource @testParams).AllowAnonymous | Should Be $false
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }


        Context -Name "The web appliation extension does exist and should that uses Kerberos and AllowAnonymous" -Fixture {
            $testParams = @{
                WebAppUrl = "http://company.sharepoint.com"
                Name = "Intranet Zone"
                Url = "http://intranet.sharepoint.com"
                HostHeader = "intranet.sharepoint.com"
                Zone = "Intranet"
                AuthenticationMethod = "Kerberos"
                AllowAnonymous = $true 
                Ensure = "Present"
            }

            Mock -CommandName Get-SPAuthenticationProvider -MockWith { 
                return @{ 
                    DisableKerberos = $false 
                    AllowAnonymous = $true 
                } 
            }
            
             Mock -CommandName Get-SPWebapplication -MockWith {
                 return (
                  @{ 
                     DisplayName = "Company SharePoint"
                     URL = "http://company.sharepoint.com"
                  } | add-member ScriptMethod Update { $Global:WebAppUpdateCalled = $true} -PassThru 
                 ) 
            }

            Mock -CommandName Get-SPAlternateUrl -MockWith {
                return @{
                    PublicURL = $testParams.Url 
                }
            }
            Mock -CommandName Get-SPDSCWebAppExtension -MockWith {
                return @{
                    ServerBindings = @{ 
                        HostHeader = $testParams.HostHeader
                        Port = 80
                    }
                    AllowAnonymous = $testParams.AllowAnonymous
                    DisableKerberos = $false  
                    Path = "c:\inetpub\wwwroot\wss\VirtualDirectories\intranet"
                }
            }


            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return AllowAnonymous True from the get method" {
                (Get-TargetResource @testParams).AllowAnonymous | Should Be $true
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }


        Context -Name "The web appliation extension does exist and should with mismatched AuthenticationMethod" -Fixture {
            $testParams = @{
                WebAppUrl = "http://company.sharepoint.com"
                Name = "Intranet Zone"
                Url = "http://intranet.sharepoint.com"
                HostHeader = "intranet.sharepoint.com"
                Zone = "Intranet"
                AuthenticationMethod = "Kerberos"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPAuthenticationProvider -MockWith { 
                return @{ 
                    DisableKerberos = $true 
                    AllowAnonymous = $false 
                } 
            }
            
             Mock -CommandName Get-SPWebapplication -MockWith {
                 return (
                  @{ 
                     DisplayName = "Company SharePoint"
                     URL = "http://company.sharepoint.com"
                  } | add-member ScriptMethod Update { $Global:WebAppUpdateCalled = $true} -PassThru 
                 ) 
            }

            Mock -CommandName Get-SPAlternateUrl -MockWith {
                return @{
                    PublicURL = $testParams.Url 
                }
            }

            Mock -CommandName Get-SPDSCWebAppExtension -MockWith {
                return @{
                    ServerBindings = @{ 
                        HostHeader = $testParams.HostHeader
                        Port = 80
                    }
                    AllowAnonymous = $testParams.AllowAnonymous
                    DisableKerberos = $true  
                    Path = "c:\inetpub\wwwroot\wss\VirtualDirectories\intranet"
                }
            }


            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return AuthenticationMethod NTLM from the get method" {
                (Get-TargetResource @testParams).AuthenticationMethod | Should Be "NTLM"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should update the web application extension settings in the set method" {
                $Global:WebAppUpdateCalled = $false
                Set-TargetResource @testParams
                 $Global:WebAppUpdateCalled | Should Be $true 
            }
        }

         Context -Name "The web appliation extension does exist and should with mismatched AllowAnonymous" -Fixture {
            $testParams = @{
                WebAppUrl = "http://company.sharepoint.com"
                Name = "Intranet Zone"
                Url = "http://intranet.sharepoint.com"
                HostHeader = "intranet.sharepoint.com"
                Zone = "Intranet"
                AuthenticationMethod = "NTLM"
                AllowAnonymous = $true 
                Ensure = "Present"
            }

            Mock -CommandName Get-SPAuthenticationProvider -MockWith { 
                return @{ 
                    DisableKerberos = $true 
                    AllowAnonymous = $false 
                } 
            }
            
             Mock -CommandName Get-SPWebapplication -MockWith {
                 return (
                  @{ 
                     DisplayName = "Company SharePoint"
                     URL = "http://company.sharepoint.com"
                  } | add-member ScriptMethod Update { $Global:WebAppUpdateCalled = $true} -PassThru 
                 ) 
            }

            Mock -CommandName Get-SPAlternateUrl -MockWith {
                return @{
                    PublicURL = $testParams.Url 
                }
            }

            Mock -CommandName Get-SPDSCWebAppExtension -MockWith {
                return @{
                    ServerBindings = @{ 
                        HostHeader = $testParams.HostHeader
                        Port = 80
                    }
                    AllowAnonymous = $false 
                    DisableKerberos = $true  
                    Path = "c:\inetpub\wwwroot\wss\VirtualDirectories\intranet"
                }
            }


            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return AllowAnonymous False from the get method" {
                (Get-TargetResource @testParams).AllowAnonymous | Should Be $false
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should update the web application extension settings in the set method" {
                $Global:WebAppUpdateCalled = $false
                Set-TargetResource @testParams
                 $Global:WebAppUpdateCalled | Should Be $true 
            }
        }

        Context -Name "The web application extension exists but should" -Fixture {
            $testParams = @{
                WebAppUrl = "http://company.sharepoint.com"
                Name = "Intranet Zone"
                Url = "http://intranet.sharepoint.com"
                Zone = "Intranet"
                Ensure = "Absent"
            }

            Mock -CommandName Get-SPWebapplication -MockWith {
                 return @{ 
                     DisplayName = "Company SharePoint"
                     URL = "http://company.sharepoint.com"
                } 
            }

             Mock -CommandName Get-SPDSCWebAppExtension -MockWith {
                return @{
                    ServerBindings = @{ 
                        HostHeader = $testParams.HostHeader
                        Port = 80
                    }
                    AllowAnonymous = $false 
                    DisableKerberos = $true  
                    Path = "c:\inetpub\wwwroot\wss\VirtualDirectories\intranet"
                }
            }
           
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
      
        Context -Name "A web application extension doesn't exist and shouldn't" -Fixture {
            $testParams = @{
                WebAppUrl = "http://company.sharepoint.com"
                Name = "Intranet Zone"
                Url = "http://intranet.sharepoint.com"
                Zone = "Intranet"
                Ensure = "Absent"
            }

             Mock -CommandName Get-SPWebapplication -MockWith {
                 return @{ 
                     DisplayName = "Company SharePoint"
                     URL = "http://company.sharepoint.com"
                } 
            }
            
             Mock -CommandName Get-SPDSCWebAppExtension -MockWith { }

            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }
            
            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
