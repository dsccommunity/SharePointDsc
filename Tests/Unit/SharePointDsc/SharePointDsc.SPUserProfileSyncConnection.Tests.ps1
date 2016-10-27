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
                                              -DscResource "SPUserProfileSyncConnection"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests
        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
        $mockCredential = New-Object -TypeName System.Management.Automation.PSCredential `
                                     -ArgumentList @("DOMAIN\username", $mockPassword)

        try { [Microsoft.Office.Server.UserProfiles] }
        catch {
            Add-Type -TypeDefinition @"
                namespace Microsoft.Office.Server.UserProfiles {
                public enum ConnectionType { ActiveDirectory, BusinessDataCatalog };
                public enum ProfileType { User};
                }        
"@ -ErrorAction SilentlyContinue 
        }   

        # Mocks for all contexts   
        Mock -CommandName Get-SPDSCServiceContext -MockWith { 
            return @{} 
        }
        Mock -CommandName Start-Sleep -MockWith { }
        
        Mock -CommandName Get-SPWebapplication -MockWith { 
            return @{
                Url = "http://ca"
                IsAdministrationWebApplication = $true
            }
        }
        $connection = @{ 
            DisplayName = "Contoso" 
            Server = "contoso.com"
            NamingContexts =  New-Object -TypeName System.Collections.ArrayList
            AccountDomain = "Contoso"
            AccountUsername = "TestAccount"
            Type = "ActiveDirectory"
        }
        $connection = $connection  | Add-Member -MemberType ScriptMethod `
                                                -Name RefreshSchema `
                                                -Value {
                                                    $Global:SPDscUPSSyncConnectionRefreshSchemaCalled = $true
                                                } -PassThru | 
                                     Add-Member -MemberType ScriptMethod `
                                                -Name Update `
                                                -Value {
                                                    $Global:SPDscUPSSyncConnectionUpdateCalled = $true
                                                } -PassThru | `
                                     Add-Member -MemberType ScriptMethod `
                                                -Name SetCredentials `
                                                -Value {
                                                    param($userAccount,$securePassword)
                                                    $Global:SPDscUPSSyncConnectionSetCredentialsCalled = $true
                                                } -PassThru | 
                                     Add-Member -MemberType ScriptMethod `
                                                -Name Delete `
                                                -Value {
                                                    $Global:SPDscUPSSyncConnectionDeleteCalled = $true
                                                } -PassThru

        $namingContext =@{ 
            ContainersIncluded = New-Object -TypeName System.Collections.ArrayList 
            ContainersExcluded = New-Object -TypeName System.Collections.ArrayList 
            DisplayName = "Contoso" 
            PreferredDomainControllers = $null
        }
        $namingContext.ContainersIncluded.Add("OU=com, OU=Contoso, OU=Included")
        $namingContext.ContainersExcluded.Add("OU=com, OU=Contoso, OU=Excluded")
        $connection.NamingContexts.Add($namingContext);
        
        $ConnnectionManager = New-Object -TypeName System.Collections.ArrayList | 
                                Add-Member -MemberType ScriptMethod `
                                           -Name AddActiveDirectoryConnection `
                                           -Value { 
                                                param(
                                                    [Microsoft.Office.Server.UserProfiles.ConnectionType] 
                                                    $connectionType, 
                                                    $name, 
                                                    $forest, 
                                                    $useSSL, 
                                                    $userName, 
                                                    $securePassword, 
                                                    $namingContext, 
                                                    $p1, 
                                                    $p2 
                                            )
                                                $Global:SPDscUPSAddActiveDirectoryConnectionCalled = $true
                                        } -PassThru
            
        Mock -CommandName New-Object -MockWith {
            return (@{
                ConnectionManager = $ConnnectionManager  
            } | Add-Member -MemberType ScriptMethod `
                           -Name IsSynchronizationRunning `
                           -Value {
                                $Global:SPDscUpsSyncIsSynchronizationRunning = $true
                                return $false
                            } -PassThru
            )} -ParameterFilter { 
                $TypeName -eq "Microsoft.Office.Server.UserProfiles.UserProfileConfigManager" 
            } 
        
        $userProfileServiceValidConnection =  @{
            Name = "User Profile Service Application"
            TypeName = "User Profile Service Application"
            ApplicationPool = "SharePoint Service Applications"
            FarmAccount = $mockCredential
            ServiceApplicationProxyGroup = "Proxy Group"
            ConnectionManager=  New-Object -TypeName System.Collections.ArrayList
        }
        $userProfileServiceValidConnection.ConnectionManager.Add($connection)
        
        Mock -CommandName Get-SPDSCADSIObject -MockWith {
            return @{
                distinguishedName = "DC=Contoso,DC=Com"
                objectGUID = (New-Guid).ToString()
            }
        }
        Mock -CommandName New-SPDSCDirectoryServiceNamingContextList -MockWith {
            return New-Object -TypeName System.Collections.Generic.List[[Object]]
        } 
        Mock -CommandName Import-Module {} -ParameterFilter { 
            $_.Name -eq $ModuleName 
        }

        # Test contexts
        Context -Name "When connection doesn't exist" -Fixture {
            $testParams = @{
                UserProfileService = "User Profile Service Application"
                Forest = "contoso.com"
                Name = "Contoso"
                ConnectionCredentials = $mockCredential
                Server = "server.contoso.com"
                UseSSL = $false
                IncludedOUs = @("OU=SharePoint Users,DC=Contoso,DC=com")
                ConnectionType = "ActiveDirectory"
            }
            
            $userProfileServiceNoConnections =  @{
                Name = "User Profile Service Application"
                ApplicationPool = "SharePoint Service Applications"
                FarmAccount = $mockCredential
                ServiceApplicationProxyGroup = "Proxy Group"
                ConnnectionManager = @()
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { return $userProfileServiceNoConnections }
            Mock -CommandName New-SPDSCDirectoryServiceNamingContext -MockWith {return @{} }
            
            It "Should return null from the Get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.UserProfileService } 
            }
            
            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should create a new service application in the set method" {
                $Global:SPDscUPSAddActiveDirectoryConnectionCalled =$false
                Set-TargetResource @testParams
                $Global:SPDscUPSAddActiveDirectoryConnectionCalled | Should be $true
            }
        }

        Context -Name "When connection exists and account is different" -Fixture {
            $testParams = @{
                UserProfileService = "User Profile Service Application"
                Forest = "contoso.com"
                Name = "Contoso"
                ConnectionCredentials = $mockCredential
                Server = "server.contoso.com"
                UseSSL = $false
                IncludedOUs = @("OU=SharePoint Users,DC=Contoso,DC=com")
                ConnectionType = "ActiveDirectory"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return $userProfileServiceValidConnection 
            }
            
            $ConnnectionManager.Add($connection)
         
            It "Should return service instance from the Get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.UserProfileService } 
            }
            
            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "execute update credentials" {
                $Global:SPDscUPSSyncConnectionSetCredentialsCalled=$false
                $Global:SPDscUPSSyncConnectionRefreshSchemaCalled=$false
                Set-TargetResource @testParams
                $Global:SPDscUPSSyncConnectionSetCredentialsCalled | Should be $true
                $Global:SPDscUPSSyncConnectionRefreshSchemaCalled | Should be $true
            }
        }
        
        Context -Name "When connection exists and forest is different" -Fixture {
            $testParams = @{
                UserProfileService = "User Profile Service Application"
                Forest = "contoso.com"
                Name = "Contoso"
                ConnectionCredentials = $mockCredential
                Server = "server.contoso.com"
                UseSSL = $false
                IncludedOUs = @("OU=SharePoint Users,DC=Contoso,DC=com")
                ConnectionType = "ActiveDirectory"
            }

            $litWareconnection = @{
                DisplayName = "Contoso" 
                Server = "litware.net"
                NamingContexts=  New-Object -TypeName System.Collections.ArrayList
                AccountDomain = "Contoso"
                AccountUsername = "TestAccount"
                Type= "ActiveDirectory"
            }
            $litWareconnection.NamingContexts.Add($namingContext);
            $litWareconnection = $litWareconnection | Add-Member -MemberType ScriptMethod `
                                                                 -Name Delete `
                                                                 -Value {
                                                                        $Global:SPDscUPSSyncConnectionDeleteCalled = $true
                                                                    } -PassThru
            $userProfileServiceValidConnection =  @{
                Name = "User Profile Service Application"
                TypeName = "User Profile Service Application"
                ApplicationPool = "SharePoint Service Applications"
                FarmAccount = $mockCredential
                ServiceApplicationProxyGroup = "Proxy Group"
                ConnectionManager=  New-Object -TypeName System.Collections.ArrayList
            }

            $userProfileServiceValidConnection.ConnectionManager.Add($litWareconnection);
            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return $userProfileServiceValidConnection 
            }
            $litwareConnnectionManager = New-Object -TypeName System.Collections.ArrayList | Add-Member -MemberType ScriptMethod  AddActiveDirectoryConnection{ `
                                                    param([Microsoft.Office.Server.UserProfiles.ConnectionType] $connectionType,  `
                                                    $name, `
                                                    $forest, `
                                                    $useSSL, `
                                                    $userName, `
                                                    $securePassword, `
                                                    $namingContext, `
                                                    $p1, $p2 `
                                                )

                $Global:SPDscUPSAddActiveDirectoryConnectionCalled =$true
            } -PassThru            
            $litwareConnnectionManager.Add($litWareconnection)

            Mock -CommandName New-Object -MockWith {
                return (@{} | Add-Member -MemberType ScriptMethod IsSynchronizationRunning {
                    $Global:SPDscUpsSyncIsSynchronizationRunning=$true;
                    return $false; 
                } -PassThru   |  Add-Member  ConnectionManager $litwareConnnectionManager  -PassThru )
            } -ParameterFilter { $TypeName -eq "Microsoft.Office.Server.UserProfiles.UserProfileConfigManager" } 
        
            Mock -CommandName New-Object -MockWith {return @{}
            }  -ParameterFilter { $TypeName -eq "Microsoft.Office.Server.UserProfiles.DirectoryServiceNamingContext"}

            It "Should return service instance from the Get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.UserProfileService } 
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw exception as force isn't specified" {
                $Global:SPDscUPSSyncConnectionDeleteCalled=$false
                {Set-TargetResource @testParams} | should throw
                $Global:SPDscUPSSyncConnectionDeleteCalled | Should be $false
            }

            $forceTestParams = @{
                UserProfileService = "User Profile Service Application"
                Forest = "contoso.com"
                Name = "Contoso"
                ConnectionCredentials = $mockCredential
                Server = "server.contoso.com"
                UseSSL = $false
                Force = $true
                IncludedOUs = @("OU=SharePoint Users,DC=Contoso,DC=com")
                ConnectionType = "ActiveDirectory"
            }
         
            It "delete and create as force is specified" {
                $Global:SPDscUPSSyncConnectionDeleteCalled=$false
                $Global:SPDscUPSAddActiveDirectoryConnectionCalled =$false
                Set-TargetResource @forceTestParams 
                $Global:SPDscUPSSyncConnectionDeleteCalled | Should be $true
                $Global:SPDscUPSAddActiveDirectoryConnectionCalled | Should be $true
            }
        }

        Context -Name "When synchronization is running" -Fixture {
            $testParams = @{
                UserProfileService = "User Profile Service Application"
                Forest = "contoso.com"
                Name = "Contoso"
                ConnectionCredentials = $mockCredential
                Server = "server.contoso.com"
                UseSSL = $false
                IncludedOUs = @("OU=SharePoint Users,DC=Contoso,DC=com")
                ConnectionType = "ActiveDirectory"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return @(
                    New-Object -TypeName "Object" | Add-Member -MemberType NoteProperty `
                                                               -Name ServiceApplicationProxyGroup `
                                                               -Value "Proxy Group" `
                                                               -PassThru 
                )
            }
            
            Mock -CommandName New-Object -MockWith {
                return (@{} | Add-Member -MemberType ScriptMethod `
                                         -Name IsSynchronizationRunning `
                                         -Value {
                                            $Global:SPDscUpsSyncIsSynchronizationRunning=$true;
                                            return $true
                                        } -PassThru)
            } -ParameterFilter { 
                $TypeName -eq "Microsoft.Office.Server.UserProfiles.UserProfileConfigManager" 
            } 

            It "attempts to execute method but synchronization is running" {
                $Global:SPDscUpsSyncIsSynchronizationRunning=$false
                $Global:SPDscUPSAddActiveDirectoryConnectionCalled =$false
                { Set-TargetResource @testParams }| Should throw
                Assert-MockCalled Get-SPServiceApplication
                Assert-MockCalled New-Object -ParameterFilter { $TypeName -eq "Microsoft.Office.Server.UserProfiles.UserProfileConfigManager" } 
                $Global:SPDscUpsSyncIsSynchronizationRunning| Should be $true;
                $Global:SPDscUPSAddActiveDirectoryConnectionCalled | Should be $false;
            }
        }
        
        Context -Name "When connection exists and Excluded and Included OUs are different. force parameter provided" -Fixture {
            $testParams = @{
                UserProfileService = "User Profile Service Application"
                Forest = "contoso.com"
                Name = "Contoso"
                ConnectionCredentials = $mockCredential
                Server = "server.contoso.com"
                UseSSL = $false
                IncludedOUs = @("OU=SharePoint Users,DC=Contoso,DC=com")
                ConnectionType = "ActiveDirectory"
            }

            $userProfileServiceValidConnection =  @{
                Name = "User Profile Service Application"
                TypeName = "User Profile Service Application"
                ApplicationPool = "SharePoint Service Applications"
                FarmAccount = $mockCredential
                ServiceApplicationProxyGroup = "Proxy Group"
                ConnectionManager=  New-Object -TypeName System.Collections.ArrayList
            }
            $userProfileServiceValidConnection.ConnectionManager.Add($connection);
            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return $userProfileServiceValidConnection 
            }

            $difOUsTestParams = @{
                UserProfileService = "User Profile Service Application"
                Forest = "contoso.com"
                Name = "Contoso"
                ConnectionCredentials = $mockCredential
                Server = "server.contoso.com"
                UseSSL = $false
                Force = $false
                IncludedOUs = @("OU=SharePoint Users,DC=Contoso,DC=com","OU=Notes Users,DC=Contoso,DC=com")
                ExcludedOUs = @("OU=Excluded, OU=SharePoint Users,DC=Contoso,DC=com")
                ConnectionType = "ActiveDirectory"
            }

            It "Should return values from the get method" {
                Get-TargetResource @difOUsTestParams | Should Not BeNullOrEmpty
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.UserProfileService } 
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @difOUsTestParams | Should Be $false
            }

            It "Should update OU lists" {
                $Global:SPDscUPSSyncConnectionUpdateCalled= $false
                $Global:SPDscUPSSyncConnectionSetCredentialsCalled  = $false
                $Global:SPDscUPSSyncConnectionRefreshSchemaCalled =$false
                Set-TargetResource @difOUsTestParams
                $Global:SPDscUPSSyncConnectionUpdateCalled | Should be $true
                $Global:SPDscUPSSyncConnectionSetCredentialsCalled  | Should be $true
                $Global:SPDscUPSSyncConnectionRefreshSchemaCalled | Should be $true
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope

