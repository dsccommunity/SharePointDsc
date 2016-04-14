[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 
    
$ModuleName = "MSFT_xSPUserProfileSyncConnection"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")


Describe "xSPUserProfileSyncConnection" {
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
            Add-Type @"
                namespace Microsoft.Office.Server.UserProfiles {
                public enum ConnectionType { ActiveDirectory, BusinessDataCatalog };
                public enum ProfileType { User};
                }        
"@ -ErrorAction SilentlyContinue 
        }   
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Get-xSharePointServiceContext {return @{}}

        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        
        Mock New-PSSession { return $null } -ModuleName "xSharePoint.Util"
        Mock Get-SPWebApplication { 
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
        $connection = $connection  | Add-Member ScriptMethod RefreshSchema {
                            $Global:xSPUPSSyncConnectionRefreshSchemaCalled = $true
                        } -PassThru | Add-Member ScriptMethod Update {
                            $Global:xSPUPSSyncConnectionUpdateCalled = $true
                        } -PassThru | Add-Member ScriptMethod SetCredentials {
                                param($userAccount,$securePassword )
                            $Global:xSPUPSSyncConnectionSetCredentialsCalled  = $true
                        } -PassThru | Add-Member ScriptMethod Delete {
                            $Global:xSPUPSSyncConnectionDeleteCalled = $true
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
        
        $ConnnectionManager = New-Object System.Collections.ArrayList | Add-Member ScriptMethod  AddActiveDirectoryConnection{ `
                                                param([Microsoft.Office.Server.UserProfiles.ConnectionType] $connectionType,  `
                                                $name, `
                                                $forest, `
                                                $useSSL, `
                                                $userName, `
                                                $securePassword, `
                                                $namingContext, `
                                                $p1, $p2 `
                                            )

        $Global:xSPUPSAddActiveDirectoryConnectionCalled =$true
        } -PassThru
            
        Mock New-Object -MockWith {
            return (@{
            ConnectionManager = $ConnnectionManager  
            } | Add-Member ScriptMethod IsSynchronizationRunning {
                $Global:UpsSyncIsSynchronizationRunning=$true;
                return $false; 
            } -PassThru   )
        } -ParameterFilter { $TypeName -eq "Microsoft.Office.Server.UserProfiles.UserProfileConfigManager" } 
        
        Mock New-Object -MockWith {
            return (New-Object System.Collections.Generic.List[System.Object])
        }  -ParameterFilter { $TypeName -eq "System.Collections.Generic.List[[Microsoft.Office.Server.UserProfiles.DirectoryServiceNamingContext]]" } 
        $userProfileServiceValidConnection =  @{
            Name = "User Profile Service Application"
            TypeName = "User Profile Service Application"
            ApplicationPool = "SharePoint Service Applications"
            FarmAccount = New-Object System.Management.Automation.PSCredential ("domain\username", (ConvertTo-SecureString "password" -AsPlainText -Force))
            ServiceApplicationProxyGroup = "Proxy Group"
            ConnectionManager=  New-Object System.Collections.ArrayList
        }
        $userProfileServiceValidConnection.ConnectionManager.Add($connection);
        
        Context "When connection doesn't exist" {
           $userProfileServiceNoConnections =  @{
                Name = "User Profile Service Application"
                ApplicationPool = "SharePoint Service Applications"
                FarmAccount = New-Object System.Management.Automation.PSCredential ("domain\username", (ConvertTo-SecureString "password" -AsPlainText -Force))
                ServiceApplicationProxyGroup = "Proxy Group"
                ConnnectionManager = @()
            }

            Mock Get-SPServiceApplication { return $userProfileServiceNoConnections }

            Mock New-Object -MockWith {return @{}
            
            }  -ParameterFilter { $TypeName -eq "Microsoft.Office.Server.UserProfiles.DirectoryServiceNamingContext"}
            It "returns null from the Get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.UserProfileService } 
            }
            
            It "returns false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "creates a new service application in the set method" {
                $Global:xSPUPSAddActiveDirectoryConnectionCalled =$false
                Set-TargetResource @testParams
                $Global:xSPUPSAddActiveDirectoryConnectionCalled | Should be $true
            }
        }

        Context "When connection exists and account is different" {
            Mock Get-SPServiceApplication { return $userProfileServiceValidConnection }
            
            $ConnnectionManager.Add($connection)
         
            It "returns service instance from the Get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.UserProfileService } 
            }
            
            It "returns false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "execute update credentials" {
                $Global:xSPUPSSyncConnectionSetCredentialsCalled=$false
                $Global:xSPUPSSyncConnectionRefreshSchemaCalled=$false
                Set-TargetResource @testParams
                $Global:xSPUPSSyncConnectionSetCredentialsCalled | Should be $true
                $Global:xSPUPSSyncConnectionRefreshSchemaCalled | Should be $true
            }
        }
        
        Context "When connection exists and forest is different" {
            $litWareconnection = @{
                DisplayName = "Contoso" 
                Server = "litware.net"
                NamingContexts=  New-Object System.Collections.ArrayList
                AccountDomain = "Contoso"
                AccountUsername = "TestAccount"
                Type= "ActiveDirectory"
            }
            $litWareconnection.NamingContexts.Add($namingContext);
            $litWareconnection = $litWareconnection | Add-Member ScriptMethod Delete {
                    $Global:xSPUPSSyncConnectionDeleteCalled = $true
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
            Mock Get-SPServiceApplication { return $userProfileServiceValidConnection }
            $litwareConnnectionManager = New-Object System.Collections.ArrayList | Add-Member ScriptMethod  AddActiveDirectoryConnection{ `
                                                    param([Microsoft.Office.Server.UserProfiles.ConnectionType] $connectionType,  `
                                                    $name, `
                                                    $forest, `
                                                    $useSSL, `
                                                    $userName, `
                                                    $securePassword, `
                                                    $namingContext, `
                                                    $p1, $p2 `
                                                )

                $Global:xSPUPSAddActiveDirectoryConnectionCalled =$true
            } -PassThru            
            $litwareConnnectionManager.Add($litWareconnection)

            Mock New-Object -MockWith {
                return (@{} | Add-Member ScriptMethod IsSynchronizationRunning {
                    $Global:UpsSyncIsSynchronizationRunning=$true;
                    return $false; 
                } -PassThru   |  Add-Member  ConnectionManager $litwareConnnectionManager  -PassThru )
            } -ParameterFilter { $TypeName -eq "Microsoft.Office.Server.UserProfiles.UserProfileConfigManager" } 
        
            Mock New-Object -MockWith {return @{}
            }  -ParameterFilter { $TypeName -eq "Microsoft.Office.Server.UserProfiles.DirectoryServiceNamingContext"}

            It "returns service instance from the Get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.UserProfileService } 
            }

            It "returns false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "throws exception as force isn't specified" {
                $Global:xSPUPSSyncConnectionDeleteCalled=$false
                {Set-TargetResource @testParams} | should throw
                $Global:xSPUPSSyncConnectionDeleteCalled | Should be $false
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
                $Global:xSPUPSSyncConnectionDeleteCalled=$false
                $Global:xSPUPSAddActiveDirectoryConnectionCalled =$false
                Set-TargetResource @forceTestParams 
                $Global:xSPUPSSyncConnectionDeleteCalled | Should be $true
                $Global:xSPUPSAddActiveDirectoryConnectionCalled | Should be $true
            }
        }

        Context "When synchronization is running" {
            Mock Get-SPServiceApplication { 
                return @(
                    New-Object Object|Add-Member NoteProperty ServiceApplicationProxyGroup "Proxy Group" -PassThru 
                )
            }
            
            Mock New-Object -MockWith {
                return (@{} | Add-Member ScriptMethod IsSynchronizationRunning {
                    $Global:UpsSyncIsSynchronizationRunning=$true;
                    return $true;
                } -PassThru)
            } -ParameterFilter { $TypeName -eq "Microsoft.Office.Server.UserProfiles.UserProfileConfigManager" } 

            It "attempts to execute method but synchronization is running" {
                $Global:UpsSyncIsSynchronizationRunning=$false
                $Global:xSPUPSAddActiveDirectoryConnectionCalled =$false
                {Set-TargetResource @testParams }| Should throw
                Assert-MockCalled Get-SPServiceApplication
                Assert-MockCalled New-Object -ParameterFilter { $TypeName -eq "Microsoft.Office.Server.UserProfiles.UserProfileConfigManager" } 
                $Global:UpsSyncIsSynchronizationRunning| Should be $true;
                $Global:xSPUPSAddActiveDirectoryConnectionCalled | Should be $false;
            }

        }
        
        Context "When connection exists and Excluded and Included OUs are different. force parameter provided" {
            $userProfileServiceValidConnection =  @{
                Name = "User Profile Service Application"
                TypeName = "User Profile Service Application"
                ApplicationPool = "SharePoint Service Applications"
                FarmAccount = New-Object System.Management.Automation.PSCredential ("domain\username", (ConvertTo-SecureString "password" -AsPlainText -Force))
                ServiceApplicationProxyGroup = "Proxy Group"
                ConnectionManager=  New-Object System.Collections.ArrayList
            }
            $userProfileServiceValidConnection.ConnectionManager.Add($connection);
            Mock Get-SPServiceApplication { return $userProfileServiceValidConnection }

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

            It "returns values from the get method" {
                Get-TargetResource @difOUsTestParams | Should Not BeNullOrEmpty
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.UserProfileService } 
            }

            It "returns false when the Test method is called" {
                Test-TargetResource @difOUsTestParams | Should Be $false
            }

            It "updates OU lists" {
                $Global:xSPUPSSyncConnectionUpdateCalled= $false
                $Global:xSPUPSSyncConnectionSetCredentialsCalled  = $false
                $Global:xSPUPSSyncConnectionRefreshSchemaCalled =$false
                Set-TargetResource @difOUsTestParams
                $Global:xSPUPSSyncConnectionUpdateCalled | Should be $true
                $Global:xSPUPSSyncConnectionSetCredentialsCalled  | Should be $true
                $Global:xSPUPSSyncConnectionRefreshSchemaCalled | Should be $true
            }
        }
    }    
}

