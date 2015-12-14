[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 
    
$ModuleName = "MSFT_xSPUserProfileSyncConnection"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")


## New-Object Microsoft.Office.Server.UserProfiles.UserProfileConfigManager($context)
## New-Object Microsoft.Office.Server.UserProfiles.DirectoryServiceNamingContext
## Mock New-Object { return $zipMock } -ParameterFilter { $ComObject -eq 'Shell.Application' }


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
                }        
"@
        }    
        $connection = @(@{ DisplayName = "Contoso" })


        ## connection exist, forest is the same
        $connection = $connection  | Add-Member ScriptMethod RefreshSchema {
                            $Global:xSPUPSSyncConnectionRefreshSchemaCalled = $true
                        } -PassThru | Add-Member ScriptMethod Update {
                            $Global:xSPUPSSyncConnectionUpdateCalled = $true
                        } -PassThru| Add-Member ScriptMethod SetCredentials {
                                param($userAccount,$securePassword )
                            $Global:xSPUPSSyncConnectionSetCredentialsCalled  = $true
                        } -PassThru
        #connection exist, different forest, force provided
        $connection = $connection  | Add-Member ScriptMethod Delete {
                            $Global:xSPUPSSyncConnectionDeleteCalled = $true
                        } -PassThru

                        #connection exist, different forest, force not provided
                            #throw exception





        $namingContext =@( @{ AccountUserName = "TestAccount" 
                            IncludedOUs = @("OU=com, OU=Contoso, OU=Included")
                            ExcludedOUs = @("OU=com, OU=Contoso, OU=Excluded")
                            })
        $namingContext = $namingContext  | Add-Member ScriptMethod Update {
                            $Global:xSPWebApplicationUpdateCalled = $true
                        } -PassThru | Add-Member ScriptMethod UpdateWorkflowConfigurationSettings {
                            $Global:xSPWebApplicationUpdateWorkflowCalled = $true
                        } -PassThru
        
        
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

        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Get-xSharePointServiceContext {return @{}}

        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        
        Mock New-PSSession { return $null } -ModuleName "xSharePoint.Util"

        
        Context "When connection doesn't exist" {
           $userProfileServiceNoConnections =  @{
                Name = "User Profile Service Application"
                ApplicationPool = "SharePoint Service Applications"
                FarmAccount = New-Object System.Management.Automation.PSCredential ("domain\username", (ConvertTo-SecureString "password" -AsPlainText -Force))
                ServiceApplicationProxyGroup = "Proxy Group"
                ConnnectionManager = @()
            }

            Mock Get-SPServiceApplication { return $userProfileServiceNoConnections }

            Mock New-Object -MockWith {
            return (@{
            ConnectionManager = $ConnnectionManager  
            } | Add-Member ScriptMethod IsSynchronizationRunning {
                $Global:UpsSyncIsSynchronizationRunning=$true;
                return $false; 
            } -PassThru   )
            } -ParameterFilter { $TypeName -eq "Microsoft.Office.Server.UserProfiles.UserProfileConfigManager" } 
            
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
            $namingContext =@{ AccountUserName = "TestAccount" 
                    IncludedOUs = New-Object System.Collections.ArrayList 
                    ExcludedOUs = New-Object System.Collections.ArrayList 
                  }
            $namingContext.IncludedOUs.Add("OU=com, OU=Contoso, OU=Included")
            $namingContext.ExcludedOUs.Add("OU=com, OU=Contoso, OU=Excluded")


            $connection = @{ DisplayName = "Contoso" 
                              NamingContexts=  New-Object System.Collections.ArrayList
                            }
            
            $connection.NamingContexts.Add($namingContext);
            $connection = $connection  | Add-Member ScriptMethod RefreshSchema {
                    $Global:xSPUPSSyncConnectionRefreshSchemaCalled = $true
                } -PassThru | Add-Member ScriptMethod Update {
                    $Global:xSPUPSSyncConnectionUpdateCalled = $true
                } -PassThru| Add-Member ScriptMethod SetCredentials {
                     param($userAccount,$securePassword )
                    $Global:xSPUPSSyncConnectionSetCredentialsCalled  = $true
                } -PassThru

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
            
            
            $ConnnectionManager.Add($connection)
            Mock New-Object -MockWith {
            return (@{} | Add-Member ScriptMethod IsSynchronizationRunning {
                $Global:UpsSyncIsSynchronizationRunning=$true;
                return $false; 
            } -PassThru   |  Add-Member  ConnectionManager $ConnnectionManager  -PassThru )
            } -ParameterFilter { $TypeName -eq "Microsoft.Office.Server.UserProfiles.UserProfileConfigManager" } 
         


            It "returns valid value from the Get method" {
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

            Mock Get-SPServiceApplication { return @(@{
                TypeName = "Some other service app type"
            }) }

            It "returns null from the Get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name } 
            }

            It "returns false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }
        }
        Context "When synchronization is running" {
           #needs service application
            Mock Get-SPServiceApplication { 
                return @(
                    New-Object Object|Add-Member NoteProperty ServiceApplicationProxyGroup "" -PassThru 
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
                {Set-TargetResource @testParams }| Should throw
                Assert-MockCalled Get-SPServiceApplication
                Assert-MockCalled New-Object
                $Global:UpsSyncIsSynchronizationRunning| Should be $true;
            }

            
            #throw exception
        }
        Context "When connection exists and Excluded and Included OUs are different" {
            Mock Get-SPServiceApplication { 
                return @(
                    New-Object Object |            
                        Add-Member NoteProperty TypeName "User Profile Service Application" -PassThru |
                        Add-Member NoteProperty ServiceApplicationProxyGroup "" -PassThru |  
                        Add-Member NoteProperty DisplayName $testParams.Name -PassThru | 
                        Add-Member NoteProperty ApplicationPool @{ Name = $testParams.ApplicationPool } -PassThru              
                        
                )
            }

            Mock New-Object  -ParameterFilter { TypeName -eq "Microsoft.Office.Server.UserProfiles.UserProfileConfigManager" } { 
                return @{
                    ConnectionManager = @($ConnnectionManager)
                }
                }

<#            return @(        
                New-Object Object |            
                Add-Member NoteProperty TypeName "User Profile Service Application" -PassThru |
                Add-Member ScriptMethod ConnectionManager {return $ConnnectionManager}
            
            )#>
            #}
            It "returns values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name } 
            }

            It "returns true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }

            Mock Get-SPFarm { return @{
                DefaultServiceAccount = @{ Name = "WRONG\account" }
            }}

            It "returns values from the get method where the farm account doesn't match" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name } 
            }
        }
    }    
}
