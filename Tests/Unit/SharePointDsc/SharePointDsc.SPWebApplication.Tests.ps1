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
                                              -DscResource "SPWebApplication"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests

        # Mocks for all contexts   
        Mock -CommandName New-SPAuthenticationProvider -MockWith { }
        Mock -CommandName New-SPWebApplication -MockWith { }
        Mock -CommandName Remove-SPWebApplication -MockWith { }
        Mock -CommandName Get-SPManagedAccount -MockWith {}

        # Test contexts
        Context -Name "The specified Managed Account does not exist" -Fixture {
            $testParams = @{
                Name = "SharePoint Sites"
                ApplicationPool = "SharePoint Web Apps"
                ApplicationPoolAccount = "DEMO\ServiceAccount"
                Url = "http://sites.sharepoint.com"
                AuthenticationMethod = "NTLM"
                Ensure = "Present"              
            }

            Mock -CommandName Get-SPWebapplication -MockWith { return $null }
            Mock -CommandName Get-SPDSCContentService -MockWith {
                return @{ Name = "PlaceHolder" }
            }
            Mock -CommandName Get-SPManagedAccount -MockWith {
                Throw "No matching accounts were found"
            }

            It "retrieving Managed Account fails in the set method" {
                { Set-TargetResource @testParams } | Should Throw "The specified managed account was not found. Please make sure the managed account exists before continuing."
            }
        }


        Context -Name "The web application that uses NTLM doesn't exist but should" -Fixture {
            $testParams = @{
                Name = "SharePoint Sites"
                ApplicationPool = "SharePoint Web Apps"
                ApplicationPoolAccount = "DEMO\ServiceAccount"
                Url = "http://sites.sharepoint.com"
                AuthenticationMethod = "NTLM"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPWebapplication -MockWith { return $null }
            Mock -CommandName Get-SPDSCContentService -MockWith {
                return @{ Name = "PlaceHolder" }
            }

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

            $testParams.Add("AllowAnonymous", $true)
            It "Should call the new cmdlet from the set where anonymous authentication is requested" {
                Set-TargetResource @testParams

                Assert-MockCalled New-SPWebApplication
                Assert-MockCalled New-SPAuthenticationProvider -ParameterFilter { $DisableKerberos -eq $true }
            }
        }

        Context -Name "The web application that uses Kerberos doesn't exist but should" -Fixture {
            $testParams = @{
                Name = "SharePoint Sites"
                ApplicationPool = "SharePoint Web Apps"
                ApplicationPoolAccount = "DEMO\ServiceAccount"
                Url = "http://sites.sharepoint.com"
                AuthenticationMethod = "Kerberos"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPWebapplication -MockWith { return $null }
            Mock -CommandName Get-SPDSCContentService -MockWith {
                return @{ Name = "PlaceHolder" }
            }
            Mock -CommandName Get-SPManagedAccount -MockWith {}

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

        Context -Name "The web appliation does exist and should that uses NTLM" -Fixture {
            $testParams = @{
                Name = "SharePoint Sites"
                ApplicationPool = "SharePoint Web Apps"
                ApplicationPoolAccount = "DEMO\ServiceAccount"
                Url = "http://sites.sharepoint.com"
                AuthenticationMethod = "NTLM"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPAuthenticationProvider -MockWith { 
                return @{ 
                    DisableKerberos = $true 
                    AllowAnonymous = $false 
                } 
            }
            
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

        Context -Name "The web application does exist and should that uses Kerberos" -Fixture {
            $testParams = @{
                Name = "SharePoint Sites"
                ApplicationPool = "SharePoint Web Apps"
                ApplicationPoolAccount = "DEMO\ServiceAccount"
                Url = "http://sites.sharepoint.com"
                AuthenticationMethod = "Kerberos"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPAuthenticationProvider -MockWith { 
                return @{ 
                    DisableKerberos = $false 
                    AllowAnonymous = $false 
                } 
            }
            
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
        
        Context -Name "A web application exists but shouldn't" -Fixture {
            $testParams = @{
                Name = "SharePoint Sites"
                ApplicationPool = "SharePoint Web Apps"
                ApplicationPoolAccount = "DEMO\ServiceAccount"
                Url = "http://sites.sharepoint.com"
                AuthenticationMethod = "NTLM"
                Ensure = "Absent"
            }

            Mock -CommandName Get-SPAuthenticationProvider -MockWith { 
                return @{ 
                    DisplayName = "Windows Authentication"
                    DisableKerberos = $true
                    AllowAnonymous = $false 
                } 
            }
            
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
        
        Context -Name "A web application doesn't exist and shouldn't" -Fixture {
            $testParams = @{
                Name = "SharePoint Sites"
                ApplicationPool = "SharePoint Web Apps"
                ApplicationPoolAccount = "DEMO\ServiceAccount"
                Url = "http://sites.sharepoint.com"
                AuthenticationMethod = "NTLM"
                Ensure = "Absent"
            }

            Mock -CommandName Get-SPWebapplication -MockWith { return $null }
            
            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }
            
            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
      
        Context -Name "The web application does exist and should that uses Claims" -Fixture {
            $testParams = @{
                Name = "SharePoint Sites"
                ApplicationPool = "SharePoint Web Apps"
                ApplicationPoolAccount = "DEMO\ServiceAccount"
                Url = "http://sites.sharepoint.com"
                AuthenticationMethod = "Claims"
                AuthenticationProvider = "TestProvider"
                Ensure = "Present"
            }

             Mock -CommandName Get-SPAuthenticationProvider -MockWith { 
                return @{ 

                   DisplayName = "TestProvider"
                   LoginProviderName = "TestProvider"
                   ClaimProviderName = "TestClaimProvider"
                   AuthenticationRedirectUrl = "/_trust/default.aspx?trust=TestProvider"
                } 
            }

            Mock -CommandName Get-SPWebApplication -MockWith { return @(@{
                DisplayName = $testParams.Name
                ApplicationPool = @{ 
                    Name = $testParams.ApplicationPool
                    Username = $testParams.ApplicationPoolAccount
                }
                USeClaimsAuthentication = $true
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
                }
            )}

            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "The web application does exist and shouldn't that uses Claims" -Fixture {
            $testParams = @{
                Name = "SharePoint Sites"
                ApplicationPool = "SharePoint Web Apps"
                ApplicationPoolAccount = "DEMO\ServiceAccount"
                Url = "http://sites.sharepoint.com"
                AuthenticationMethod = "Claims"
                AuthenticationProvider = "TestProvider"
                Ensure = "Absent"
            }

             Mock -CommandName Get-SPAuthenticationProvider -MockWith { 
                return @{ 

                   DisplayName = "TestProvider"
                   LoginProviderName = "TestProvider"
                   ClaimProviderName = "TestClaimProvider"
                   AuthenticationRedirectUrl = "/_trust/default.aspx?trust=TestProvider"
                } 
            }

            Mock -CommandName Get-SPWebApplication -MockWith { return @(@{
                DisplayName = $testParams.Name
                ApplicationPool = @{ 
                    Name = $testParams.ApplicationPool
                    Username = $testParams.ApplicationPoolAccount
                }
                USeClaimsAuthentication = $true
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
                }
            )}

            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context -Name "The web application doesn't exist and should that uses Claims" -Fixture {
            $testParams = @{
                Name = "SharePoint Sites"
                ApplicationPool = "SharePoint Web Apps"
                ApplicationPoolAccount = "DEMO\ServiceAccount"
                Url = "http://sites.sharepoint.com"
                AuthenticationMethod = "Claims"
                AuthenticationProvider = "TestProvider"
                Ensure = "Present"
            }
            
            Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith {
                return @{
                    Name = $testParams.AuthenticationProvider
                }
            }
            
            Mock -CommandName Get-SPAuthenticationProvider -MockWith { 
                return @{ 

                   DisplayName = $testParams.AuthenticationProvider
                   LoginProviderName = $testParams.AuthenticationProvider
                   ClaimProviderName = "TestClaimProvider"
                   AuthenticationRedirectUrl = "/_trust/default.aspx?trust=$($testParams.AuthenticationProvider)"
                } 
            }

            Mock -CommandName Get-SPWebApplication -MockWith { 
                return $null
            }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
             It "Should call the new cmdlet from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled New-SPWebApplication
                Assert-MockCalled Get-SPAuthenticationProvider
            }
        }

        
        Context -Name "The web application doesn't exist and shouldn't that uses Claims" -Fixture {
            $testParams = @{
                Name = "SharePoint Sites"
                ApplicationPool = "SharePoint Web Apps"
                ApplicationPoolAccount = "DEMO\ServiceAccount"
                Url = "http://sites.sharepoint.com"
                AuthenticationMethod = "Claims"
                AuthenticationProvider = "TestProvider"
                Ensure = "Absent"
            }

             Mock -CommandName Get-SPAuthenticationProvider -MockWith { 
                return @{ 

                   DisplayName = "TestProvider"
                   LoginProviderName = "TestProvider"
                   ClaimProviderName = "TestClaimProvider"
                   AuthenticationRedirectUrl = "/_trust/default.aspx?trust=TestProvider"
                } 
            }

            Mock -CommandName Get-SPWebApplication -MockWith { 
                return $null
            }

            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

                  
        Context -Name "The web application doesn't exists authentication method is specified with NTLM provider" -Fixture {
            $testParams = @{
                Name = "SharePoint Sites"
                ApplicationPool = "SharePoint Web Apps"
                ApplicationPoolAccount = "DEMO\ServiceAccount"
                Url = "http://sites.sharepoint.com"
                AuthenticationMethod = "NTLM"
                AuthenticationProvider = "Windows Authentication"
                Ensure = "Present"
            }

             Mock -CommandName Get-SPAuthenticationProvider -MockWith { 
                return @{ 
                    DisplayName = "Windows Authentication"
                    DisableKerberos = $true 
                    AllowAnonymous = $false 
                } 
            }

            Mock -CommandName Get-SPWebApplication -MockWith { 
                return $null
            }

            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context -Name "The web application does exist and authentication method is specified with Kerberos provider" -Fixture {
            $testParams = @{
                Name = "SharePoint Sites"
                ApplicationPool = "SharePoint Web Apps"
                ApplicationPoolAccount = "DEMO\ServiceAccount"
                Url = "http://sites.sharepoint.com"
                AuthenticationMethod = "Kerberos"
                AuthenticationProvider = "Windows Authentication"
                Ensure = "Present"
            }

             Mock -CommandName Get-SPAuthenticationProvider -MockWith { 
                return @{ 
                    DisplayName = "Windows Authentication"
                    DisableKerberos = $false 
                    AllowAnonymous = $false 
                } 
               
            }
            

           Mock -CommandName Get-SPWebApplication -MockWith { return @(@{
                DisplayName = $testParams.Name
                ApplicationPool = @{ 
                    Name = $testParams.ApplicationPool
                    Username = $testParams.ApplicationPoolAccount
                }
                USeClaimsAuthentication = $false
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
                }
            )}

            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "The web application authentication method is claims with no authentication provider" -Fixture {
            
            $testParams = @{
                Name = "SharePoint Sites"
                ApplicationPool = "SharePoint Web Apps"
                ApplicationPoolAccount = "DEMO\ServiceAccount"
                Url = "http://sites.sharepoint.com"
                AuthenticationMethod = "Claims"
                Ensure = "Present"
            }

             Mock -CommandName Get-SPAuthenticationProvider -MockWith { 
                return @{ 
                    DisplayName = "TestProvider"
                    LoginProviderName = "TestProvider"
                    ClaimProviderName = "TestClaimProvider"
                    AuthenticationRedirectUrl = "/_trust/default.aspx?trust=TestProvider"
                } 
                
            }
            
            Mock -CommandName Get-SPWebApplication -MockWith { return @(@{
                DisplayName = $testParams.Name
                ApplicationPool = @{ 
                    Name = $testParams.ApplicationPool
                    Username = $testParams.ApplicationPoolAccount
                }
                USeClaimsAuthentication = $true
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
                }
            )}
            
            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }    
            It "Should return exception from the set method" {
                {Set-TargetResource @testParams} | Should Throw "When configuring SPWebApplication to use Claims the AuthenticationProvider value must be specified."
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "The web appliation does not exist and should that uses NTLM" -Fixture {
            $testParams = @{
                Name = "SharePoint Sites"
                ApplicationPool = "SharePoint Web Apps"
                ApplicationPoolAccount = "DEMO\ServiceAccount"
                Url = "http://sites.sharepoint.com"
                AuthenticationMethod = "NTLM"
                Ensure = "Present"
                DatabaseServer = "sql.domain.local"
                DatabaseName = "SP_Content_01"
                HostHeader = "sites.sharepoint.com"
                Path = "C:\inetpub\wwwroot\something"
                Port = 80
                UseSSL = $true
            }

            
            Mock -CommandName Get-SPDSCContentService -MockWith {
                ApplicationPools = @(
                     @{
                        Name = $testParams.ApplicationPool
                    },
                    @{
                        Name = "Default App Pool"
                    },
                    @{
                        Name = "SharePoint Token Service App Pool"
                    }
                )
            }
            Mock -CommandName Get-SPAuthenticationProvider -MockWith { 
                return @{ 
                    DisplayName = "Windows Authentication"
                    DisableKerberos = $true 
                    AllowAnonymous = $false 
                } 
            }
            
            Mock -CommandName Get-SPWebapplication -MockWith { 
                return $null
            }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }           
            
            It "Should return false from the set method" {
                Test-TargetResource @testParams | Should Be $false
            }           
        }
       
        
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
