
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
        $testParams= @{
           Name = "PersonalInformation"
           UserProfileService = "User Profile Service Application"
           DisplayName = "Personal Information"
           DisplayOrder = 5000 
        }
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
  
        
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
        
        $coreProperty = @{ 
                            DisplayName = $testParams.DisplayName
                            Name = $testParams.Name
                        } | Add-Member ScriptMethod Commit {
                            $Global:xSPUPSPropertyCommitCalled = $true
                        } -PassThru | Add-Member ScriptMethod Delete {
                            $Global:xSPUPSPropertyDeleteCalled = $true
                        } -PassThru
        $subTypeProperty = @{
                            Name= $testParams.Name
                            DisplayName= $testParams.DisplayName
                            DisplayOrder =$testParams.DisplayOrder
                            CoreProperty = $coreProperty
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
        $coreProperties = @{ProfileInformation = $coreProperty}

        $coreProperties = $coreProperties | Add-Member ScriptMethod Create {
                            $Global:xSPUPCoreCreateCalled = $true
                            return @{
                            Name="";
                            DisplayName=""
                            }
                        } -PassThru  | Add-Member ScriptMethod RemoveSectionByName {
                            $Global:xSPUPCoreRemovePropertyByNameCalled = $true
                        } -PassThru | Add-Member ScriptMethod Add {
                            $Global:xSPUPCoreAddCalled = $true
                        } -PassThru -Force 

        $userProfileSubTypePropertiesProperty = @{"ProfileInformation" = $subTypeProperty } | Add-Member ScriptMethod Create {
                            $Global:xSPUPSubTypeCreateCalled = $true
                        } -PassThru | Add-Member ScriptMethod Add {
                            $Global:xSPUPSubTypeAddCalled = $true
                        } -PassThru -Force | Add-Member ScriptMethod GetSectionByName {
                            $Global:xSPUPGetSectionByNameCalled  = $true
                            return $subTypeProperty
                        } -PassThru
                        #>
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
        
        $userProfileService =  @{
            Name = "User Profile Service Application"
            TypeName = "User Profile Service Application"
            ApplicationPool = "SharePoint Service Applications"
            ServiceApplicationProxyGroup = "Proxy Group"
        }

        Mock Get-SPServiceApplication { return $userProfileService }

        
        Context "When section doesn't exist" {
            
            It "returns null from the Get method" {
                $Global:xSPUPGetProfileSubtypeCalled = $false
                $Global:xSPUPGetSectionByNameCalled = $false
                Get-TargetResource @testParams | Should BeNullOrEmpty
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.UserProfileService } 
                $Global:xSPUPGetProfileSubtypeCalled | Should be $true
                $Global:xSPUPGetSectionByNameCalled | Should be $true
            }
            
            It "returns false when the Test method is called" {
                $Global:xSPUPGetSectionByNameCalled = $false
                Test-TargetResource @testParams | Should Be $false
                $Global:xSPUPGetSectionByNameCalled | Should be $true
            }

            It "creates a new user profile property in the set method" {
                $Global:xSPUPGetProfileSubtypeCalled = $false
                Set-TargetResource @testParams
                $Global:xSPUPGetProfileSubtypeCalled | Should be $true
            }

        }
        
        Context "When section exists and all properties match" {
            mock Get-xSharePointUserProfileSubTypeManager -MockWith {
            $result = @{}| Add-Member ScriptMethod GetProfileSubtype {
                                $Global:xSPUPGetProfileSubtypeCalled = $true
                                return @{
                                Properties = $userProfileSubTypePropertiesProperty
                                }
                            } -PassThru 
                return $result
            }
                    
            It "returns valid value from the Get method" {
                $Global:xSPUPGetProfileSubtypeCalled = $false
                $Global:xSPUPGetSectionByNameCalled = $false
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.UserProfileService } 
                $Global:xSPUPGetProfileSubtypeCalled | Should be $true
                $Global:xSPUPGetSectionByNameCalled | Should be $true
            }
            
            It "returns true when the Test method is called" {
                $Global:xSPUPGetSectionByNameCalled = $false
                Test-TargetResource @testParams | Should Be $true
                $Global:xSPUPGetSectionByNameCalled | Should be $true
            }
            It "updates an user profile property in the set method" {
                $Global:xSPUPGetProfileSubtypeCalled = $false
                Set-TargetResource @testParams
                $Global:xSPUPGetProfileSubtypeCalled | Should be $true
            }
        }
       
        Context "When section exists and display name and display order are different" {
            mock Get-xSharePointUserProfileSubTypeManager -MockWith {
            $result = @{}| Add-Member ScriptMethod GetProfileSubtype {
                                $Global:xSPUPGetProfileSubtypeCalled = $true
                                return @{
                                Properties = $userProfileSubTypePropertiesProperty
                                }
                            } -PassThru 
                return $result
            }
            $testParams.DisplayOrder = 5401
            $testParams.DisplayName = "ProfileInformationUpdate"

            It "returns valid value from the Get method" {
                $Global:xSPUPGetProfileSubtypeCalled = $false
                $Global:xSPUPGetSectionByNameCalled = $false
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.UserProfileService } 
                $Global:xSPUPGetProfileSubtypeCalled | Should be $true
                $Global:xSPUPGetSectionByNameCalled | Should be $true
            }
            
            It "returns false when the Test method is called" {
                $Global:xSPUPGetSectionByNameCalled = $false
                Test-TargetResource @testParams | Should Be $false
                $Global:xSPUPGetSectionByNameCalled | Should be $true
            }
            It "updates an user profile property in the set method" {
                $Global:xSPUPGetProfileSubtypeCalled = $false
                Set-TargetResource @testParams
                $Global:xSPUPGetProfileSubtypeCalled | Should be $true
            }
        }
        Context "When section exists and ensure equals Absent" {
            mock Get-xSharePointUserProfileSubTypeManager -MockWith {
            $result = @{}| Add-Member ScriptMethod GetProfileSubtype {
                                $Global:xSPUPGetProfileSubtypeCalled = $true
                                return @{
                                Properties = $userProfileSubTypePropertiesProperty
                                }
                            } -PassThru 

            return $result
            }
                    $testParamsUpdate.Ensure = "Absent"
            It "deletes an user profile property in the set method" {
                $Global:xSPUPGetProfileSubtypeCalled = $false
                $Global:xSPUPGetSectionByNameCalled = $false
                $Global:xSPUPCoreRemoveSectionByNameCalled=$false
                Set-TargetResource @testParams 
                $Global:xSPUPGetProfileSubtypeCalled | Should be $true
                $Global:xSPUPGetSectionByNameCalled | Should be $true
                $Global:xSPUPCoreRemoveSectionByNameCalled | Should be $true
            }           
        }
    }    
}