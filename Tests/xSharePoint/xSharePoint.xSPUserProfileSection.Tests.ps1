
[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)
Add-PSSnapin Microsoft.SharePoint.PowerShell -ea 0 

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 
    
$ModuleName = "MSFT_xSPUserProfileSection"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")


Describe "xSPUserProfileSection" {
    InModuleScope $ModuleName {
        $testParams= @{
           Name = "PersonalInformation"
           UserProfileService = "User Profile Service Application"
           DisplayName = "Personal Information"
           DisplayOrder = 5000 
        }
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
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
                        }| Add-Member ScriptMethod Commit {
                            $Global:xSPUPSPropertyCommitCalled = $true
                        } -PassThru
        $userProfileSubTypePropertiesNoProperty = @{} | Add-Member ScriptMethod Create {
        param($section)
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
        $userProfileSubTypePropertiesProperty = @{"ProfileInformation" = $subTypeProperty } | Add-Member ScriptMethod Create {
                            $Global:xSPUPSubTypeCreateCalled = $true
                        } -PassThru | Add-Member ScriptMethod Add {
                            $Global:xSPUPSubTypeAddCalled = $true
                        } -PassThru -Force
        mock Get-xSharePointUserProfileSubTypeManager -MockWith {
        $result = @{}| Add-Member ScriptMethod GetProfileSubtype {
                            $Global:xSPUPGetProfileSubtypeCalled = $true
                            return @{
                            Properties = $userProfileSubTypePropertiesNoProperty
                            }
                        } -PassThru 

        return $result
        }
        
        Mock Set-xSharePointObjectPropertyIfValueExists -MockWith {return ;}
        Mock Get-SPWebApplication -MockWith {
            return @(
                    @{
                        IsAdministrationWebApplication=$true
                        Url ="caURL"
                     })
        }  
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
  
        
        Mock New-PSSession { return $null } -ModuleName "xSharePoint.Util"
        
        
        Mock New-Object -MockWith {
            $ProfilePropertyManager = @{"Contoso"  = $connection}      
            return (@{
            ProfilePropertyManager = $ProfilePropertyManager
            ConnectionManager = $ConnnectionManager  
            } | Add-Member ScriptMethod GetPropertiesWithSection {
                $Global:UpsConfigManagerGetPropertiesWithSectionCalled=$true;

                $result = (@{}|Add-Member ScriptMethod Create {
                param ($section)


                    $result = @{Name = ""
                            DisplayName=""
                            DisplayOrder=0}|Add-Member ScriptMethod Commit {
                                $Global:UpsConfigManagerCommitCalled=$true;
                            } -PassThru
                    return $result
                } -PassThru -Force | Add-Member ScriptMethod GetSectionByName {
                           $result = $null
                            if($Global:UpsConfigManagerGetSectionByNameCalled -eq $TRUE){
                                $result = $subTypeProperty
                            }
                            $Global:UpsConfigManagerGetSectionByNameCalled=$true
                            return $result
                return $userProfileSubTypePropertiesUpdateProperty; 
            } -PassThru | Add-Member ScriptMethod SetDisplayOrderBySectionName {
                $Global:UpsConfigManagerSetDisplayOrderBySectionNameCalled=$true;
                return $userProfileSubTypePropertiesUpdateProperty; 
            } -PassThru | Add-Member ScriptMethod CommitDisplayOrder {
                $Global:UpsConfigManagerCommitDisplayOrderCalled=$true;
                return $userProfileSubTypePropertiesUpdateProperty; 
            } -PassThru| Add-Member ScriptMethod RemoveSectionByName {
                $Global:UpsConfigManagerRemoveSectionByNameCalled=$true;
                return ($coreProperties); 
            } -PassThru  

) 
           return $result

             } -PassThru )
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
                $Global:UpsConfigManagerGetSectionByNameCalled = $false
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.UserProfileService } 
                $Global:UpsConfigManagerGetSectionByNameCalled | Should be $true
            }
            
            It "returns false when the Test method is called" {
                $Global:UpsConfigManagerGetSectionByNameCalled = $false
                Test-TargetResource @testParams | Should Be $false
                $Global:UpsConfigManagerGetSectionByNameCalled | Should be $true
            }

            It "creates a new user profile section in the set method" {
                $Global:xSPUPSubTypeCreateCalled = $false
                $Global:UpsConfigManagerSetDisplayOrderBySectionNameCalled = $false
                $Global:xSPUPSPropertyCommitCalled=$false;

                Set-TargetResource @testParams
                $Global:xSPUPSubTypeCreateCalled | should be $false
                $Global:xSPUPSPropertyCommitCalled|should be $true                
                $Global:UpsConfigManagerSetDisplayOrderBySectionNameCalled | Should be $true
            }

        }
        Context "When section exists and all properties match" {
            It "returns valid value from the Get method" {
                $Global:UpsConfigManagerGetSectionByNameCalled = $true
  
                (Get-TargetResource @testParams).Ensure | Should Be "Present" 
                $Global:UpsConfigManagerGetSectionByNameCalled | Should be $true
            }
            
            It "returns true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
            It "updates an user profile property in the set method" {
                $Global:UpsConfigManagerCommitCalled = $false
                $Global:UpsConfigManagerSetDisplayOrderBySectionNameCalled = $false
                Set-TargetResource @testParams
                $Global:UpsConfigManagerCommitCalled | should be $false
                $Global:UpsConfigManagerSetDisplayOrderBySectionNameCalled | Should be $true
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
                    $testParams.Ensure = "Absent"

            It "returns true when the Test method is called" {
                $Global:xSPUPGetSectionByNameCalled = $true
                Test-TargetResource @testParams | Should Be $false

            }


            It "deletes an user profile property in the set method" {
                $Global:UpsConfigManagerGetSectionByNameCalled = $true
                $Global:UpsConfigManagerRemoveSectionByNameCalled=$false
                Set-TargetResource @testParams 
                $Global:UpsConfigManagerRemoveSectionByNameCalled | Should be $true
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
            $testParams.Ensure = "Present"
            $testParams.DisplayOrder = 5401
            $testParams.DisplayName = "ProfileInformationUpdate"

            It "returns valid value from the Get method" {
                $Global:xSPUPGetSectionByNameCalled = $true
                $currentValues = Get-TargetResource @testParams 
                $currentValues.Ensure | Should Be "Present"
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.UserProfileService } 
            }
            
            It "returns false when the Test method is called" {
                $Global:xSPUPGetSectionByNameCalled = $true
                Test-TargetResource @testParams | Should Be $false
            }
            It "updates an user profile property in the set method" {
                $Global:xSPUPSubTypeCreateCalled = $false
                $Global:UpsConfigManagerSetDisplayOrderBySectionNameCalled = $false
                $Global:xSPUPGetSectionByNameCalled=$true
                Set-TargetResource @testParams
                Assert-MockCalled Set-xSharePointObjectPropertyIfValueExists
                $Global:xSPUPSubTypeCreateCalled | should be $false
                $Global:UpsConfigManagerSetDisplayOrderBySectionNameCalled | Should be $true
            }
        }
    }    
}

