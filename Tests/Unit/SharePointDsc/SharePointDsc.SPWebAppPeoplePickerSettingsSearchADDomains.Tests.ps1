[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string] 
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
                                         -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
                                         -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
                                -ChildPath "..\UnitTestHelper.psm1" `
                                -Resolve)

$Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
                                              -DscResource "SPWebAppPeoplePickerSettingsSearchADDomains"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests


        # Mocks for all contexts    
        
        # Test contexts
        Context -Name "The web application does not exist" -Fixture {
            $testParams = @{
                Url         = 'http://intranet.contoso.local'
                DomainName  = 'contoso.com'
                LoginName   = 'CONTOSO\SVC-SP-LdapReader'
                Ensure      = 'Present'
            }

            Mock -CommandName Get-SPWebapplication -MockWith { return $null }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "retrieving non-existent web application fails in the set method" {
                { Set-TargetResource @testParams } | Should Throw "Web Application with URL $($testParams.Url) does not exist"
            }
        }

        Context -Name "The SPPeoplePickerSearchActiveDirectoryDomain exists and should" -Fixture {
            $testParams = @{
                Url         = 'http://intranet.contoso.local'
                DomainName  = 'contoso.com'
                LoginName   = 'CONTOSO\SVC-SP-LdapReader'
                Ensure      = 'Present'
            }
          
            Mock -CommandName Get-SPWebapplication -MockWith {
                $peoplePickerSettings =  @( 
                     @{}
                     @{
                         SearchActiveDirectoryDomains = @{
                             DomainName = 'contoso.com'
                             LoginName  = 'CONTOSO\SVC-SP-LdapReader'
                         }
                 })
                
                $returnValue = @{
                     DisplayName = 'Contoso Intranet'
                     URL = 'http://intranet.contoso.local'
                     PeoplePickerSettings = $peoplePickerSettings
                }
                
                $returnValue = $returnValue | Add-Member -MemberType ScriptMethod -Name Update -Value {
                    $SPDscWebApplicationUpdateCalled = $false
                } -PassThru
                return $returnValue
             }
                        
            It "Should return present from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be 'Present' 
            }
            
            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "The SPPeoplePickerSearchActiveDirectoryDomain doesn't exist but shouldn't" -Fixture {
            $testParams = @{
                Url         = 'http://intranet.contoso.local'
                DomainName  = 'domaintoremove.com'
                LoginName   = 'CONTOSO\SVC-SP-LdapReader'
                Ensure      = 'Absent'
            }
          
            Mock -CommandName Get-SPWebapplication -MockWith {
                $peoplePickerSettings =  @( 
                     @{}
                     @{
                         SearchActiveDirectoryDomains = @{
                             DomainName = 'domaintoremove.com'
                             LoginName  = 'CONTOSO\SVC-SP-LdapReader'
                         }
                 })
                
                $returnValue = @{
                     DisplayName = 'Contoso Intranet'
                     URL = 'http://intranet.contoso.local'
                     PeoplePickerSettings = $peoplePickerSettings
                }
                
                $returnValue = $returnValue | Add-Member -MemberType ScriptMethod -Name Update -Value {
                    $SPDscWebApplicationUpdateCalled = $true
                } -PassThru
                return $returnValue
             }
                        
            It "Should return present from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present" 
            }
            
            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "Should remove the absent domain in the set method" {
                Set-TargetResource @testParams
            }
        }

        Context -Name "The SPPeoplePickerSearchActiveDirectoryDomain doesn't exist and shouldn't" -Fixture {
            $testParams = @{
                Url         = 'http://intranet.contoso.local'
                DomainName  = 'domaintoremove.com'
                LoginName   = 'CONTOSO\SVC-SP-LdapReader'
                Ensure      = 'Absent'
            }
          
            Mock -CommandName Get-SPWebapplication -MockWith {
                $peoplePickerSettings =  @( 
                     @{}
                     @{
                         SearchActiveDirectoryDomains = @{
                             DomainName = 'contoso.com'
                             LoginName  = 'CONTOSO\SVC-SP-LdapReader'
                         }
                 })
                
                $returnValue = @{
                     DisplayName = 'Contoso Intranet'
                     URL = 'http://intranet.contoso.local'
                     PeoplePickerSettings = $peoplePickerSettings
                }
                
                $returnValue = $returnValue | Add-Member -MemberType ScriptMethod -Name Update -Value {
                    $SPDscWebApplicationUpdateCalled = $false
                } -PassThru
                return $returnValue
             }
                        
            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be 'Absent' 
            }
            
            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
        }
<#
        Context -Name "The web appliation extension does exist and should with mismatched Windows Authentication" -Fixture {
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
                    DisplayName = "Windows Authentication"
                    DisableKerberos = $true 
                    AllowAnonymous = $false 
                } 
            }
            
             Mock -CommandName Get-SPWebapplication -MockWith {
                 $IISSettings =  @( 
                     @{}
                     @{
                         SecureBindings = @{}
                         ServerBindings = @{
                             HostHeader = "intranet.sharepoint.com"
                             Port = 80
                         }
                 })

                 return (
                  @{ 
                     DisplayName = "Company SharePoint"
                     URL = "http://company.sharepoint.com"
                     IISSettings = $IISSettings
                  } | add-member ScriptMethod Update { $Global:WebAppUpdateCalled = $true} -PassThru 
                 ) 
            }

            Mock -CommandName Get-SPAlternateUrl -MockWith {
                return @{
                    PublicURL = $testParams.Url 
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
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPWebApplication 
            }
        }

        Context -Name "The web appliation extension does exist and should with mismatched Authentication (Windows / Claims)" -Fixture {
            $testParams = @{
                WebAppUrl = "http://company.sharepoint.com"
                Name = "Intranet Zone"
                Url = "http://intranet.sharepoint.com"
                HostHeader = "intranet.sharepoint.com"
                Zone = "Intranet"
                AuthenticationMethod = "Claims"
                AuthenticationProvider = "MyClaimsProvider"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPAuthenticationProvider -MockWith { 
                return @{ 
                    DisplayName = "Windows Authentication"
                    DisableKerberos = $true 
                    AllowAnonymous = $false 
                } 
            }
            
             Mock -CommandName Get-SPWebapplication -MockWith {
                 $IISSettings =  @( 
                     @{}
                     @{
                         SecureBindings = @{}
                         ServerBindings = @{
                             HostHeader = "intranet.sharepoint.com"
                             Port = 80
                         }
                 })

                 return (
                  @{ 
                     DisplayName = "Company SharePoint"
                     URL = "http://company.sharepoint.com"
                     IISSettings = $IISSettings
                  } | add-member ScriptMethod Update { $Global:WebAppUpdateCalled = $true} -PassThru 
                 ) 
            }

            Mock -CommandName Get-SPAlternateUrl -MockWith {
                return @{
                    PublicURL = $testParams.Url 
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

            It "Should update the web application extension authentication settings in the set method" {
                 Set-TargetResource @testParams
                 
                 Assert-MockCalled Set-SPWebApplication 
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
                    DisplayName = "Windows Authentication"
                    DisableKerberos = $true 
                    AllowAnonymous = $false 
                } 
            }
            
             Mock -CommandName Get-SPWebapplication -MockWith {
                 $IISSettings =  @( 
                     @{}
                     @{
                         SecureBindings = @{}
                         ServerBindings = @{
                             HostHeader = "intranet.sharepoint.com"
                             Port = 80
                         }
                 })

                 return (
                  @{ 
                     DisplayName = "Company SharePoint"
                     URL = "http://company.sharepoint.com"
                     IISSettings = $IISSettings
                  } | add-member ScriptMethod Update { $Global:WebAppUpdateCalled = $true} -PassThru 
                 ) 
            }

            Mock -CommandName Get-SPAlternateUrl -MockWith {
                return @{
                    PublicURL = $testParams.Url 
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

        Context -Name "The web application extension exists but shouldn't" -Fixture {
            $testParams = @{
                WebAppUrl = "http://company.sharepoint.com"
                Name = "Intranet Zone"
                Url = "http://intranet.sharepoint.com"
                Zone = "Intranet"
                Ensure = "Absent"
            }

            Mock -CommandName Get-SPWebapplication -MockWith {
                $IISSettings =  @( 
                     @{}
                     @{
                         SecureBindings = @{}
                         ServerBindings = @{
                             HostHeader = "intranet.sharepoint.com"
                             Port = 80
                         }
                 })

                 return @{ 
                     DisplayName = "Company SharePoint"
                     URL = "http://company.sharepoint.com"
                     IISSettings = $IISSettings
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
                     IISSettings = @()
                } 
            }
            
           

            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }
            
            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
#>
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
