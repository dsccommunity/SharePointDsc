[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 
    
$ModuleName = "MSFT_SPUserProfileSyncConnection"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPUserProfileSyncConnection - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            UserProfileService = "User Profile Service Application"
            Forest = "contoso.com"
            Name = "Contoso"
            ConnectionCredentials = New-Object System.Management.Automation.PSCredential ("domain\username", (ConvertTo-SecureString "password" -AsPlainText -Force))
            Server = "server.contoso.com"
            UseSSL = $false
            IncludedOUs = @("OU=SharePoint Users,DC=Contoso,DC=com")
            ConnectionType = "ActiveDirectory"
        }
        
        try { [Microsoft.Office.Server.UserProfiles] }
        catch {
            Add-Type -TypeDefinition @"
                namespace Microsoft.Office.Server.UserProfiles {
                public enum ConnectionType { ActiveDirectory, BusinessDataCatalog };
                public enum ProfileType { User};
                }        
"@ -ErrorAction SilentlyContinue 
        }   
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDsc")
        
        Mock -CommandName Get-SPDSCServiceContext {return @{}}

        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        
        Mock -CommandName Start-Sleep { }
        Mock -CommandName New-PSSession { return $null } -ModuleName "SharePointDsc.Util"
        Mock -CommandName Get-SPWebapplication -MockWith { 
                return @{
                        Url="http://ca"
                        IsAdministrationWebApplication=$true
                }
        }
        $connection = @{ 
            DisplayName = "Contoso" 
            Server = "contoso.com"
            NamingContexts=  New-Object System.Collections.ArrayList
            AccountDomain = "Contoso"
            AccountUsername = "TestAccount"
            Type= "ActiveDirectory"
        }
        $connection = $connection  | Add-Member -MemberType ScriptMethod RefreshSchema {
                            $Global:SPUPSSyncConnectionRefreshSchemaCalled = $true
                        } -PassThru | Add-Member -MemberType ScriptMethod -Name Update -Value {
                            $Global:SPUPSSyncConnectionUpdateCalled = $true
                        } -PassThru | Add-Member -MemberType ScriptMethod SetCredentials {
                                param($userAccount,$securePassword )
                            $Global:SPUPSSyncConnectionSetCredentialsCalled  = $true
                        } -PassThru | Add-Member -MemberType ScriptMethod Delete {
                            $Global:SPUPSSyncConnectionDeleteCalled = $true
                        } -PassThru

        $namingContext =@{ 
            ContainersIncluded = New-Object System.Collections.ArrayList 
            ContainersExcluded = New-Object System.Collections.ArrayList 
            DisplayName="Contoso" 
            PreferredDomainControllers=$null;
        }
        $namingContext.ContainersIncluded.Add("OU=com, OU=Contoso, OU=Included")
        $namingContext.ContainersExcluded.Add("OU=com, OU=Contoso, OU=Excluded")
        $connection.NamingContexts.Add($namingContext);
        
        $ConnnectionManager = New-Object System.Collections.ArrayList | Add-Member -MemberType ScriptMethod  AddActiveDirectoryConnection{ `
                                                param([Microsoft.Office.Server.UserProfiles.ConnectionType] $connectionType,  `
                                                $name, `
                                                $forest, `
                                                $useSSL, `
                                                $userName, `
                                                $securePassword, `
                                                $namingContext, `
                                                $p1, $p2 `
                                            )

        $Global:SPUPSAddActiveDirectoryConnectionCalled =$true
        } -PassThru
            
        Mock -CommandName New-Object -MockWith {
            return (@{
            ConnectionManager = $ConnnectionManager  
            } | Add-Member -MemberType ScriptMethod IsSynchronizationRunning {
                $Global:UpsSyncIsSynchronizationRunning=$true;
                return $false; 
            } -PassThru   )
        } -ParameterFilter { $TypeName -eq "Microsoft.Office.Server.UserProfiles.UserProfileConfigManager" } 
        
        $userProfileServiceValidConnection =  @{
            Name = "User Profile Service Application"
            TypeName = "User Profile Service Application"
            ApplicationPool = "SharePoint Service Applications"
            FarmAccount = New-Object System.Management.Automation.PSCredential ("domain\username", (ConvertTo-SecureString "password" -AsPlainText -Force))
            ServiceApplicationProxyGroup = "Proxy Group"
            ConnectionManager=  New-Object System.Collections.ArrayList
        }
        $userProfileServiceValidConnection.ConnectionManager.Add($connection);
        
        Mock -CommandName Get-SPDSCADSIObject {
            return @{
                distinguishedName = "DC=Contoso,DC=Com"
                objectGUID = (New-Guid).ToString()
            }
        }
        Mock -CommandName New-SPDSCDirectoryServiceNamingContextList -MockWith {
            return New-Object System.Collections.Generic.List[[Object]]
        } 
        Mock Import-Module {} -ParameterFilter { $_.Name -eq $ModuleName }
        
        Context -Name "When connection doesn't exist" {
           $userProfileServiceNoConnections =  @{
                Name = "User Profile Service Application"
                ApplicationPool = "SharePoint Service Applications"
                FarmAccount = New-Object System.Management.Automation.PSCredential ("domain\username", (ConvertTo-SecureString "password" -AsPlainText -Force))
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
                $Global:SPUPSAddActiveDirectoryConnectionCalled =$false
                Set-TargetResource @testParams
                $Global:SPUPSAddActiveDirectoryConnectionCalled | Should be $true
            }
        }

        Context -Name "When connection exists and account is different" {
            Mock -CommandName Get-SPServiceApplication -MockWith { return $userProfileServiceValidConnection }
            
            $ConnnectionManager.Add($connection)
         
            It "Should return service instance from the Get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.UserProfileService } 
            }
            
            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "execute update credentials" {
                $Global:SPUPSSyncConnectionSetCredentialsCalled=$false
                $Global:SPUPSSyncConnectionRefreshSchemaCalled=$false
                Set-TargetResource @testParams
                $Global:SPUPSSyncConnectionSetCredentialsCalled | Should be $true
                $Global:SPUPSSyncConnectionRefreshSchemaCalled | Should be $true
            }
        }
        
        Context -Name "When connection exists and forest is different" {
            $litWareconnection = @{
                DisplayName = "Contoso" 
                Server = "litware.net"
                NamingContexts=  New-Object System.Collections.ArrayList
                AccountDomain = "Contoso"
                AccountUsername = "TestAccount"
                Type= "ActiveDirectory"
            }
            $litWareconnection.NamingContexts.Add($namingContext);
            $litWareconnection = $litWareconnection | Add-Member -MemberType ScriptMethod Delete {
                    $Global:SPUPSSyncConnectionDeleteCalled = $true
                } -PassThru
            $userProfileServiceValidConnection =  @{
                Name = "User Profile Service Application"
                TypeName = "User Profile Service Application"
                ApplicationPool = "SharePoint Service Applications"
                FarmAccount = New-Object System.Management.Automation.PSCredential ("domain\username", (ConvertTo-SecureString "password" -AsPlainText -Force))
                ServiceApplicationProxyGroup = "Proxy Group"
                ConnectionManager=  New-Object System.Collections.ArrayList
            }

            $userProfileServiceValidConnection.ConnectionManager.Add($litWareconnection);
            Mock -CommandName Get-SPServiceApplication -MockWith { return $userProfileServiceValidConnection }
            $litwareConnnectionManager = New-Object System.Collections.ArrayList | Add-Member -MemberType ScriptMethod  AddActiveDirectoryConnection{ `
                                                    param([Microsoft.Office.Server.UserProfiles.ConnectionType] $connectionType,  `
                                                    $name, `
                                                    $forest, `
                                                    $useSSL, `
                                                    $userName, `
                                                    $securePassword, `
                                                    $namingContext, `
                                                    $p1, $p2 `
                                                )

                $Global:SPUPSAddActiveDirectoryConnectionCalled =$true
            } -PassThru            
            $litwareConnnectionManager.Add($litWareconnection)

            Mock -CommandName New-Object -MockWith {
                return (@{} | Add-Member -MemberType ScriptMethod IsSynchronizationRunning {
                    $Global:UpsSyncIsSynchronizationRunning=$true;
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
                $Global:SPUPSSyncConnectionDeleteCalled=$false
                {Set-TargetResource @testParams} | should throw
                $Global:SPUPSSyncConnectionDeleteCalled | Should be $false
            }

            $forceTestParams = @{
                UserProfileService = "User Profile Service Application"
                Forest = "contoso.com"
                Name = "Contoso"
                ConnectionCredentials = New-Object System.Management.Automation.PSCredential ("domain\username", (ConvertTo-SecureString "password" -AsPlainText -Force))
                Server = "server.contoso.com"
                UseSSL = $false
                Force = $true
                IncludedOUs = @("OU=SharePoint Users,DC=Contoso,DC=com")
                ConnectionType = "ActiveDirectory"
            }
         
            It "delete and create as force is specified" {
                $Global:SPUPSSyncConnectionDeleteCalled=$false
                $Global:SPUPSAddActiveDirectoryConnectionCalled =$false
                Set-TargetResource @forceTestParams 
                $Global:SPUPSSyncConnectionDeleteCalled | Should be $true
                $Global:SPUPSAddActiveDirectoryConnectionCalled | Should be $true
            }
        }

        Context -Name "When synchronization is running" {
            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return @(
                    New-Object -TypeName "Object"|Add-Member -MemberType NoteProperty ServiceApplicationProxyGroup "Proxy Group" -PassThru 
                )
            }
            
            Mock -CommandName New-Object -MockWith {
                return (@{} | Add-Member -MemberType ScriptMethod IsSynchronizationRunning {
                    $Global:UpsSyncIsSynchronizationRunning=$true;
                    return $true;
                } -PassThru)
            } -ParameterFilter { $TypeName -eq "Microsoft.Office.Server.UserProfiles.UserProfileConfigManager" } 

            It "attempts to execute method but synchronization is running" {
                $Global:UpsSyncIsSynchronizationRunning=$false
                $Global:SPUPSAddActiveDirectoryConnectionCalled =$false
                {Set-TargetResource @testParams }| Should throw
                Assert-MockCalled Get-SPServiceApplication
                Assert-MockCalled New-Object -ParameterFilter { $TypeName -eq "Microsoft.Office.Server.UserProfiles.UserProfileConfigManager" } 
                $Global:UpsSyncIsSynchronizationRunning| Should be $true;
                $Global:SPUPSAddActiveDirectoryConnectionCalled | Should be $false;
            }

        }
        
        Context -Name "When connection exists and Excluded and Included OUs are different. force parameter provided" {
            $userProfileServiceValidConnection =  @{
                Name = "User Profile Service Application"
                TypeName = "User Profile Service Application"
                ApplicationPool = "SharePoint Service Applications"
                FarmAccount = New-Object System.Management.Automation.PSCredential ("domain\username", (ConvertTo-SecureString "password" -AsPlainText -Force))
                ServiceApplicationProxyGroup = "Proxy Group"
                ConnectionManager=  New-Object System.Collections.ArrayList
            }
            $userProfileServiceValidConnection.ConnectionManager.Add($connection);
            Mock -CommandName Get-SPServiceApplication -MockWith { return $userProfileServiceValidConnection }

            $difOUsTestParams = @{
                UserProfileService = "User Profile Service Application"
                Forest = "contoso.com"
                Name = "Contoso"
                ConnectionCredentials = New-Object System.Management.Automation.PSCredential ("domain\username", (ConvertTo-SecureString "password" -AsPlainText -Force))
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
                $Global:SPUPSSyncConnectionUpdateCalled= $false
                $Global:SPUPSSyncConnectionSetCredentialsCalled  = $false
                $Global:SPUPSSyncConnectionRefreshSchemaCalled =$false
                Set-TargetResource @difOUsTestParams
                $Global:SPUPSSyncConnectionUpdateCalled | Should be $true
                $Global:SPUPSSyncConnectionSetCredentialsCalled  | Should be $true
                $Global:SPUPSSyncConnectionRefreshSchemaCalled | Should be $true
            }
        }
    }    
}

