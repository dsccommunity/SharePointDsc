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
        $testParamsNewProperty = @{
           Name = "WorkEmailNew"
           UserProfileService = "User Profile Service Application"
           DisplayName = "WorkEmailNew"
           Type = "String"
           Description = "" 
           PolicySetting = "Mandatory"
           PrivacySetting = "Public"
           MappingConnectionName = "contoso"
           MappingPropertyName = "department"
           MappingDirection = "Import"
           Length = 30
           DisplayOrder = 5496 
           IsEventLog =$false
           IsVisibleOnEditor=$true
           IsVisibleOnViewer = $true
           IsUserEditable = $true
           IsAlias = $false
           IsSearchable = $false 
           TermStore = "Managed Metadata service"
           TermGroup = "People"
           TermSet = "Department" 
           UserOverridePrivacy = $false
        }

        $testParamsUpdateProperty = @{
           Name = "WorkEmailUpdate"
           UserProfileService = "User Profile Service Application"
           DisplayName = "WorkEmailUpdate"
           Type = "String"
           Description = ""
           PolicySetting = "Optional"
           PrivacySetting = "Private"
           MappingConnectionName = "contoso"
           MappingPropertyName = "mail"
           MappingDirection = "Import"
           Length = 30
           DisplayOrder = 5496 
           IsEventLog =$true
           IsVisibleOnEditor=$false
           IsVisibleOnViewer = $false
           IsUserEditable = $false
           IsAlias = $true 
           IsSearchable = $true 
           TermStore = "Managed Metadata service"
           TermGroup = "People"
           TermSet = "Location" 
           UserOverridePrivacy = $false
        }
        
        try { [Microsoft.Office.Server.UserProfiles] }
        catch {
            Add-Type @"
                namespace Microsoft.Office.Server.UserProfiles {
                public enum ConnectionType { ActiveDirectory, BusinessDataCatalog };
                public enum ProfileType { User};
                }        
"@
        }   

        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        $coreProperty = @{ 
                            DisplayName = "WorkEmailUpdate" 
                            Name = "WorkEmailUpdate"
                            IsMultiValued=$false
                            Type = "String"
                            TermSet = $null
                            Length=25
                            IsSearchable =$true
                        } | Add-Member ScriptMethod Commit {
                            $Global:xSPUPSPropertyCommitCalled = $true
                        } -PassThru | Add-Member ScriptMethod Delete {
                            $Global:xSPUPSPropertyDeleteCalled = $true
                        } -PassThru


        $coreProperties = @() | Add-Member ScriptMethod Create {
                            $Global:xSPUPCoreCreateCalled = $true
                        } -PassThru | Add-Member ScriptMethod Add {
                            $Global:xSPUPCoreAddCalled  = $true
                        } -PassThru 


        $typeProperty = @{
                            IsVisibleOnViewer=$true
                            IsVisibleOnEditor=$true
                            IsEventLog=$true
                        }| Add-Member ScriptMethod Commit {
                            $Global:xSPUPPropertyCommitCalled = $true
                        } -PassThru 

        $typeProperties = @() | Add-Member ScriptMethod Create {
                            $Global:xSPUPTypeCreateCalled = $true
                        } -PassThru | Add-Member ScriptMethod Add {
                            $Global:xSPUPTypeAddCalled  = $true
                        } -PassThru 
       $subTypeProperty = @{
                            Name= "WorkEmailUpdate"
                            DisplayName="WorkEmailUpdate"
                            Description = ""
                            PrivacyPolicy = "Required"
                            DefaultPrivacy = "Everyone"
                            DisplayOrder =5401
                            IsUserEditable= $true
                            IsAlias =  $true
                            CoreProperty = $coreProperty
                            TypeProperty = $typeProperty
                            AllowPolicyOverride=$true;
                        }| Add-Member ScriptMethod Commit {
                            $Global:xSPUPPropertyCommitCalled = $true
                        } -PassThru 

        $userProfileSubTypePropertiesNoProperty = @() | Add-Member ScriptMethod Create {
                            $Global:xSPUPSubTypeCreateCalled = $true
                        } -PassThru | Add-Member ScriptMethod Add {
                            $Global:xSPUPSubTypeAddCalled  = $true
                        } -PassThru | Add-Member ScriptMethod GetPropertyByName {
                            $Global:xSPUPGetPropertyByNameCalled  = $true
                            return $null
                        } -PassThru

        $userProfileSubTypePropertiesValidProperty = @() | Add-Member ScriptMethod Create {
                            $Global:xSPUPSubTypeCreateCalled = $true
                        } -PassThru | Add-Member ScriptMethod Add {
                            $Global:xSPUPSubTypeAddCalled  = $true
                        } -PassThru | Add-Member ScriptMethod GetPropertyByName {
                            $Global:xSPUPGetPropertyByNameCalled  = $true
                            return $subTypeProperty
                        } -PassThru

        mock Get-xSharePointUserProfileSubTypeManager {
        return @()| Add-Member ScriptMethod GetProfileSubtype {
                            $Global:xSPUPGetProfileSubtypeCalled = $true
                            return @{
                            Properties = $userProfileSubTypePropertiesNoProperty
                            }
                        } -PassThru 
        }
        

        Mock Get-SPWebApplication {
        return @(IsAdministrationWebApplication=$true
                  Url ="caURL")
        }
        $TermSets =@{Department = @(Name="Department"
                                )} 

        $TermGroups = @{People = @(Name="People"
                                TermSets = @TermSets 
                                )}

        $TermStoresList = @{"Managed Metadata service" = @(Name="Managed Metadata service"
                                Groups = @TermGroups 
                                )}    


        Mock New-Object -MockWith {
            return (@{
                TermStores = $TermStoresList
            })
        } -ParameterFilter { $TypeName -eq "Microsoft.SharePoint.Taxonomy.TaxonomySession" } 

        Mock New-Object -MockWith {
            return (@{
                Properties = @()
            } | Add-Member ScriptMethod SetDisplayOrderByPropertyName {
                $Global:UpsSetDisplayOrderByPropertyNameCalled=$true;
                return $false; 
            } -PassThru | Add-Member ScriptMethod CommitDisplayOrder {
                $Global:UpsSetDisplayOrderByPropertyNameCalled=$true;
                return $false; 
            } -PassThru    )
        } -ParameterFilter { $TypeName -eq "Microsoft.Office.Server.UserProfiles.UserProfileManager" } 
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        
        Mock New-PSSession { return $null } -ModuleName "xSharePoint.Util"

        $propertyMapping = @{}| Add-Member ScriptMethod Item {
                            param( [string]$property  )
                            $Global:xSPUPSMappingItemCalled = $true
                                if($property="WorkEmailUpdate"){
                                    return @{
                                    DataSourcePropertyName="WorkEmailUpdate"
                                    IsImport=$true
                                    IsExport=$false
                                    }| Add-Member ScriptMethod Delete {
                                        $Global:UpsMappingDeleteCalled=$true;
                                        return $true; 
                                        } -PassThru | Add-Member ScriptMethod AddNewExportMapping {
                                        $Global:UpsMappingAddNewExportCalled=$true;
                                        return $true; 
                                        } -PassThru | Add-Member ScriptMethod AddNewMapping {
                                        $Global:UpsMappingAddNewMappingCalled=$true;
                                        return $true; 
                                        } -PassThru 
                                }
                            
                        } -PassThru
        $connection = @{ 
            DisplayName = "Contoso" 
            Server = "contoso.com"
            NamingContexts=  New-Object System.Collections.ArrayList
            AccountDomain = "Contoso"
            AccountUsername = "TestAccount"
            Type= "ActiveDirectory"
            PropertyMapping = $propertyMapping
        }
        $connection = $connection   | Add-Member ScriptMethod Update {
                            $Global:xSPUPSSyncConnectionUpdateCalled = $true
                        } -PassThru  | Add-Member ScriptMethod AddPropertyMapping {
                            $Global:xSPUPSSyncConnectionAddPropertyMappingCalled = $true
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
        
        Context "When property doesn't exist" {
<#           $userProfileServiceNoConnections =  @{
                Name = "User Profile Service Application"
                ApplicationPool = "SharePoint Service Applications"
                FarmAccount = New-Object System.Management.Automation.PSCredential ("domain\username", (ConvertTo-SecureString "password" -AsPlainText -Force))
                ServiceApplicationProxyGroup = "Proxy Group"
                ConnnectionManager = @()
            }#>

            Mock Get-SPServiceApplication { return $userProfileServiceValidConnection }

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

        Context "When property doesn't exist, connection doesn't exist" {
        }

        Context "When property doesn't exist, termset doesn't exist" {
        }

        Context "When property doesn't exist, termgroup doesn't exist" {
        }

        Context "When property doesn't exist, termgstore doesn't exist" {
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
