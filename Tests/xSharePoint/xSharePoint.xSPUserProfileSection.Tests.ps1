
[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)
Add-PSSnapin Microsoft.SharePoint.PowerShell -ea 0 

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 
    
$ModuleName = "MSFT_xSPUserProfileSection"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")


Describe "xSPUserProfileProperty" {
    InModuleScope $ModuleName {
        $testParamsNew= @{
           Name = "PersonalInformation"
           UserProfileService = "User Profile Service Application"
           DisplayName = "Personal Information"
           DisplayOrder = 5000 
        }
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        $farmAccount = New-Object System.Management.Automation.PSCredential ("domain\username", (ConvertTo-SecureString "password" -AsPlainText -Force))
        $testParamsUpdate = @{
           Name = "PersonalInformation"
           UserProfileService = "User Profile Service Application"
           DisplayName = "Personal InformationUpdate"
           DisplayOrder = 5000         }
        
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
        
        $corePropertyUpdate = @{ 
                           Name = "PersonalInformation"
                           DisplayName = "Personal InformationUpdate"
                        } | Add-Member ScriptMethod Commit {
                            $Global:xSPUPSPropertyCommitCalled = $true
                        } -PassThru | Add-Member ScriptMethod Delete {
                            $Global:xSPUPSPropertyDeleteCalled = $true
                        } -PassThru

        $coreProperties = @{WorkEmailUpdate = $corePropertyUpdate}

        $coreProperties = $coreProperties | Add-Member ScriptMethod Create {
                            $Global:xSPUPCoreCreateCalled = $true
                            return @{
                            Name="";
                            DisplayName=""
                            Type=""
                            TermSet=$null
                            Length=10
                            }
                        } -PassThru  | Add-Member ScriptMethod RemoveSectionByName {
                            $Global:xSPUPCoreRemovePropertyByNameCalled = $true
                        } -PassThru | Add-Member ScriptMethod Add {
                            $Global:xSPUPCoreAddCalled = $true
                        } -PassThru -Force 
                        
        
        #$typeProperties.Add($typeProperty)
       $subTypePropertyUpdate = @{
                            Name = "PersonalInformation"
                            DisplayName = "Personal InformationUpdate"
                            DisplayOrder =5401
                        }| Add-Member ScriptMethod Commit {
                            $Global:xSPUPPropertyCommitCalled = $true
                        } -PassThru 


        $coreProperty = @{ 
                            DisplayName = $testParamsNew.DisplayName
                            Name = $testParamsNew.Name
                        } | Add-Member ScriptMethod Commit {
                            $Global:xSPUPSPropertyCommitCalled = $true
                        } -PassThru | Add-Member ScriptMethod Delete {
                            $Global:xSPUPSPropertyDeleteCalled = $true
                        } -PassThru
        $subTypeProperty = @{
                            Name= $testParamsNew.Name
                            DisplayName= $testParamsNew.DisplayName
                            DisplayOrder =$testParamsNew.DisplayOrder
                        }
        $userProfileSubTypePropertiesNoProperty = @{} | Add-Member ScriptMethod Create {
                            $Global:xSPUPSubTypeCreateCalled = $true
                        } -PassThru  | Add-Member ScriptMethod GetSectionByName {
                            $result = $null
                            if($Global:xSPUPGetSectionByNameCalled -eq $TRUE){
                                $result = $subTypeProperty
                            }
                            $Global:xSPUPGetSectionByNameCalled  = $true
                            return $result
                        } -PassThru| Add-Member ScriptMethod Add {
                            $Global:xSPUPSubTypeAddCalled = $true
                        } -PassThru -Force 

        $userProfileSubTypePropertiesUpdateProperty = @{"WorkEmailUpdate" = $subTypePropertyUpdate } | Add-Member ScriptMethod Create {
                            $Global:xSPUPSubTypeCreateCalled = $true
                        } -PassThru | Add-Member ScriptMethod Add {
                            $Global:xSPUPSubTypeAddCalled = $true
                        } -PassThru -Force | Add-Member ScriptMethod GetSectionByName {
                            $Global:xSPUPGetSectionByNameCalled  = $true
                            return $subTypePropertyUpdate
                        } -PassThru
         #$userProfileSubTypePropertiesValidProperty.Add($subTypeProperty);
        mock Get-xSharePointUserProfileSubTypeManager -MockWith {
        $result = @{}| Add-Member ScriptMethod GetProfileSubtype {
                            $Global:xSPUPGetProfileSubtypeCalled = $true
                            return @{
                            Properties = $userProfileSubTypePropertiesNoProperty
                            }
                        } -PassThru 

        return $result
        }
        

        Mock Get-SPWebApplication -MockWith {
            return @(
                    @{
                        IsAdministrationWebApplication=$true
                        Url ="caURL"
                     })
        }  
        Mock New-Object -MockWith {
            return (@{
                Properties = @{} | Add-Member ScriptMethod SetDisplayOrderBySectionName {
                $Global:UpsSetDisplayOrderBySectionNameCalled=$true;
                return $false; 
            } -PassThru | Add-Member ScriptMethod CommitDisplayOrder {
                $Global:UpsSetDisplayOrderBySectionNameCalled=$true;
                return $false; 
            } -PassThru    })
        } -ParameterFilter { $TypeName -eq "Microsoft.Office.Server.UserProfiles.UserProfileManager" } 
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
  
        
        Mock New-PSSession { return $null } -ModuleName "xSharePoint.Util"
        
        Mock New-Object -MockWith {
            $ProfilePropertyManager = @{"Contoso"  = $connection} | Add-Member ScriptMethod GetCoreProperties {
                $Global:UpsConfigManagerGetCorePropertiesCalled=$true;

                return ($coreProperties); 
            } -PassThru | Add-Member ScriptMethod GetProfileTypeProperties {
                $Global:UpsConfigManagerGetProfileTypePropertiesCalled=$true;
                return $userProfileSubTypePropertiesUpdateProperty; 
            } -PassThru     
            return (@{
            ProfilePropertyManager = $ProfilePropertyManager
            ConnectionManager = $ConnnectionManager  
            })
        } -ParameterFilter { $TypeName -eq "Microsoft.Office.Server.UserProfiles.UserProfileConfigManager" } 
        
        $userProfileServiceValidConnection =  @{
            Name = "User Profile Service Application"
            TypeName = "User Profile Service Application"
            ApplicationPool = "SharePoint Service Applications"
            FarmAccount = $farmAccount 
            ServiceApplicationProxyGroup = "Proxy Group"
            ConnectionManager=  @($connection) #New-Object System.Collections.ArrayList
        }

        Mock Get-SPServiceApplication { return $userProfileServiceValidConnection }

        
        Context "When section doesn't exist" {
            
            It "returns null from the Get method" {
                $Global:xSPUPGetProfileSubtypeCalled = $false
                $Global:xSPUPGetSectionByNameCalled = $false
                $Global:xSPUPSMappingItemCalled = $false
                Get-TargetResource @testParamsNewProperty | Should BeNullOrEmpty
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParamsNewProperty.UserProfileService } 
                $Global:xSPUPGetProfileSubtypeCalled | Should be $true
                $Global:xSPUPGetSectionByNameCalled | Should be $true
                $Global:xSPUPSMappingItemCalled | Should be $false
            }
            
            It "returns false when the Test method is called" {
                $Global:xSPUPGetSectionByNameCalled = $false
                Test-TargetResource @testParamsNewProperty | Should Be $false
                $Global:xSPUPGetSectionByNameCalled | Should be $true
            }

            It "creates a new user profile property in the set method" {
                $Global:xSPUPGetProfileSubtypeCalled = $false
                
                $Global:xSPUPSMappingItemCalled = $false
                Set-TargetResource @testParamsNewProperty
                $Global:xSPUPGetProfileSubtypeCalled | Should be $true
                
                $Global:xSPUPSMappingItemCalled | Should be $true

            }

        }

        Context "When section exists and all properties match" {
            mock Get-xSharePointUserProfileSubTypeManager -MockWith {
            $result = @{}| Add-Member ScriptMethod GetProfileSubtype {
                                $Global:xSPUPGetProfileSubtypeCalled = $true
                                return @{
                                Properties = $userProfileSubTypePropertiesUpdateProperty
                                }
                            } -PassThru 

            return $result
            }
                    
            It "returns valid value from the Get method" {
                $Global:xSPUPGetProfileSubtypeCalled = $false
                $Global:xSPUPGetSectionByNameCalled = $false
                $Global:xSPUPSMappingItemCalled = $false
                Get-TargetResource @testParamsUpdateProperty | Should Not BeNullOrEmpty
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParamsUpdateProperty.UserProfileService } 
                $Global:xSPUPGetProfileSubtypeCalled | Should be $true
                $Global:xSPUPGetSectionByNameCalled | Should be $true
                $Global:xSPUPSMappingItemCalled | Should be $true
            }
            
            It "returns false when the Test method is called" {
                $Global:xSPUPGetSectionByNameCalled = $false
                Test-TargetResource @testParamsUpdateProperty | Should Be $true
                $Global:xSPUPGetSectionByNameCalled | Should be $true
            }

            It "updates an user profile property in the set method" {
                $Global:xSPUPGetProfileSubtypeCalled = $false
                $Global:xSPUPSMappingItemCalled = $false
                Set-TargetResource @testParamsUpdateProperty
                $Global:xSPUPGetProfileSubtypeCalled | Should be $true
                $Global:xSPUPSMappingItemCalled | Should be $true

            }


        }


        Context "When section exists and ensure equals Absent" {
            mock Get-xSharePointUserProfileSubTypeManager -MockWith {
            $result = @{}| Add-Member ScriptMethod GetProfileSubtype {
                                $Global:xSPUPGetProfileSubtypeCalled = $true
                                return @{
                                Properties = $userProfileSubTypePropertiesUpdateProperty
                                }
                            } -PassThru 

            return $result
            }
                    $testParamsUpdateProperty.Ensure = "Absent"
            It "deletes an user profile property in the set method" {
                $Global:xSPUPGetProfileSubtypeCalled = $false
                $Global:xSPUPGetSectionByNameCalled = $false
                $Global:xSPUPSMappingItemCalled = $false
                $Global:xSPUPCoreRemoveSectionByNameCalled=$false

                Set-TargetResource @testParamsUpdateProperty

                $Global:xSPUPGetProfileSubtypeCalled | Should be $true
                $Global:xSPUPGetSectionByNameCalled | Should be $true
                $Global:xSPUPSMappingItemCalled | Should be $false
                $Global:xSPUPCoreRemoveSectionByNameCalled | Should be $true
            }           
        }
    }    
}