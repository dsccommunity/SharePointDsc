[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 
    
$ModuleName = "MSFT_xSPUserProfileProperty"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")


Describe "xSPUserProfileProperty" {
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
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Get-xSharePointServiceContext {return @{}}

        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        
        Mock New-PSSession { return $null } -ModuleName "xSharePoint.Util"

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
         <#  $userProfileServiceNoConnections =  @{
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
            #>
        }

        Context "When property doesn't exist" {
        }

        Context "When property exists" {
        }

        Context "When property exists and type is different" {
        }

        Context "When property exists and mapping does not " {
           
        }
        Context "When property exists and mapping exists, mapping config matches" {
           
        }
        Context "When property exists and mapping exists, mapping config does not match" {
           
        }
        Context "When creating property and user has no access to MMS" {
           
        }

        Context "When creating property and there is no MMS with default storage location for column specific" {
           
        }
        Context "When property exists and ensure equals Absent" {
           
        }
    }    
}
