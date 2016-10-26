[CmdletBinding()]
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
                                              -DscResource "SPUserProfileSection"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        $testParams= @{
           Name = "PersonalInformation"
           UserProfileService = "User Profile Service Application"
           DisplayName = "Personal Information"
           DisplayOrder = 5000 
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

        
        $coreProperty = @{ 
                            DisplayName = $testParams.DisplayName
                            Name = $testParams.Name
                        } | Add-Member -MemberType ScriptMethod Commit {
                            $Global:SPUPSPropertyCommitCalled = $true
                        } -PassThru | Add-Member -MemberType ScriptMethod Delete {
                            $Global:SPUPSPropertyDeleteCalled = $true
                        } -PassThru
        $subTypeProperty = @{
                            Name= $testParams.Name
                            DisplayName= $testParams.DisplayName
                            DisplayOrder =$testParams.DisplayOrder
                            CoreProperty = $coreProperty
                        }| Add-Member -MemberType ScriptMethod Commit {
                            $Global:SPUPSPropertyCommitCalled = $true
                        } -PassThru
        $userProfileSubTypePropertiesNoProperty = @{} | Add-Member -MemberType ScriptMethod Create {
        param($section)
                            $Global:SPUPSubTypeCreateCalled = $true
                        } -PassThru  | Add-Member -MemberType ScriptMethod GetSectionByName {
                            $result = $null
                            if($Global:SPUPGetSectionByNameCalled -eq $TRUE){
                                $result = $subTypeProperty
                            }
                            $Global:SPUPGetSectionByNameCalled  = $true
                            return $result
                        } -PassThru| Add-Member -MemberType ScriptMethod -Name Add -Value {
                            $Global:SPUPSubTypeAddCalled = $true
                        } -PassThru -Force 
        $coreProperties = @{ProfileInformation = $coreProperty}
        $userProfileSubTypePropertiesProperty = @{"ProfileInformation" = $subTypeProperty } | Add-Member -MemberType ScriptMethod Create {
                            $Global:SPUPSubTypeCreateCalled = $true
                        } -PassThru | Add-Member -MemberType ScriptMethod -Name Add -Value {
                            $Global:SPUPSubTypeAddCalled = $true
                        } -PassThru -Force
        Mock -CommandName Get-SPDSCUserProfileSubTypeManager -MockWith {
        $result = @{}| Add-Member -MemberType ScriptMethod GetProfileSubtype {
                            $Global:SPUPGetProfileSubtypeCalled = $true
                            return @{
                            Properties = $userProfileSubTypePropertiesNoProperty
                            }
                        } -PassThru 

        return $result
        }
        
        Mock -CommandName Set-SPDscObjectPropertyIfValuePresent -MockWith {return ;}
        Mock -CommandName Get-SPWebApplication -MockWith {
            return @(
                    @{
                        IsAdministrationWebApplication=$true
                        Url ="caURL"
                     })
        }     
        
        Mock -CommandName New-Object -MockWith {
            $ProfilePropertyManager = @{"Contoso"  = $connection}      
            return (@{
            ProfilePropertyManager = $ProfilePropertyManager
            ConnectionManager = $ConnnectionManager  
            } | Add-Member -MemberType ScriptMethod GetPropertiesWithSection {
                $Global:UpsConfigManagerGetPropertiesWithSectionCalled=$true;

                $result = (@{}|Add-Member -MemberType ScriptMethod Create {
                param ($section)


                    $result = @{Name = ""
                            DisplayName=""
                            DisplayOrder=0}|Add-Member -MemberType ScriptMethod Commit {
                                $Global:UpsConfigManagerCommitCalled=$true;
                            } -PassThru
                    return $result
                } -PassThru -Force | Add-Member -MemberType ScriptMethod GetSectionByName {
                           $result = $null
                            if($Global:UpsConfigManagerGetSectionByNameCalled -eq $TRUE){
                                $result = $subTypeProperty
                            }
                            $Global:UpsConfigManagerGetSectionByNameCalled=$true
                            return $result
                return $userProfileSubTypePropertiesUpdateProperty; 
            } -PassThru | Add-Member -MemberType ScriptMethod SetDisplayOrderBySectionName {
                $Global:UpsConfigManagerSetDisplayOrderBySectionNameCalled=$true;
                return $userProfileSubTypePropertiesUpdateProperty; 
            } -PassThru | Add-Member -MemberType ScriptMethod CommitDisplayOrder {
                $Global:UpsConfigManagerCommitDisplayOrderCalled=$true;
                return $userProfileSubTypePropertiesUpdateProperty; 
            } -PassThru| Add-Member -MemberType ScriptMethod RemoveSectionByName {
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

        Mock -CommandName Get-SPServiceApplication -MockWith { return $userProfileService }

        
        Context -Name "When section doesn't exist" {
            
            It "Should return null from the Get method" {
                $Global:UpsConfigManagerGetSectionByNameCalled = $false
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.UserProfileService } 
                $Global:UpsConfigManagerGetSectionByNameCalled | Should be $true
            }
            
            It "Should return false when the Test method is called" {
                $Global:UpsConfigManagerGetSectionByNameCalled = $false
                Test-TargetResource @testParams | Should Be $false
                $Global:UpsConfigManagerGetSectionByNameCalled | Should be $true
            }

            It "Should create a new user profile section in the set method" {
                $Global:SPUPSubTypeCreateCalled = $false
                $Global:UpsConfigManagerSetDisplayOrderBySectionNameCalled = $false
                $Global:SPUPSPropertyCommitCalled=$false;

                Set-TargetResource @testParams
                $Global:SPUPSubTypeCreateCalled | should be $false
                $Global:SPUPSPropertyCommitCalled|should be $true                
                $Global:UpsConfigManagerSetDisplayOrderBySectionNameCalled | Should be $true
            }

        }
        Context -Name "When section exists and all properties match" {
            It "Should return valid value from the Get method" {
                $Global:UpsConfigManagerGetSectionByNameCalled = $true
  
                (Get-TargetResource @testParams).Ensure | Should Be "Present" 
                $Global:UpsConfigManagerGetSectionByNameCalled | Should be $true
            }
            
            It "Should return true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
            It "Should update an user profile property in the set method" {
                $Global:UpsConfigManagerCommitCalled = $false
                $Global:UpsConfigManagerSetDisplayOrderBySectionNameCalled = $false
                Set-TargetResource @testParams
                $Global:UpsConfigManagerCommitCalled | should be $false
                $Global:UpsConfigManagerSetDisplayOrderBySectionNameCalled | Should be $true
            }
        }
        
        Context -Name "When section exists and ensure equals Absent" {
            Mock -CommandName Get-SPDSCUserProfileSubTypeManager -MockWith {
            $result = @{}| Add-Member -MemberType ScriptMethod GetProfileSubtype {
                                $Global:SPUPGetProfileSubtypeCalled = $true
                                return @{
                                Properties = $userProfileSubTypePropertiesProperty
                                }
                            } -PassThru 

            return $result
            }
                    $testParams.Ensure = "Absent"

            It "Should return true when the Test method is called" {
                $Global:SPUPGetSectionByNameCalled = $true
                Test-TargetResource @testParams | Should Be $false

            }


            It "deletes an user profile property in the set method" {
                $Global:UpsConfigManagerGetSectionByNameCalled = $true
                $Global:UpsConfigManagerRemoveSectionByNameCalled=$false
                Set-TargetResource @testParams 
                $Global:UpsConfigManagerRemoveSectionByNameCalled | Should be $true
            }           
        }


        Context -Name "When section exists and display name and display order are different" {
            Mock -CommandName Get-SPDSCUserProfileSubTypeManager -MockWith {
            $result = @{}| Add-Member -MemberType ScriptMethod GetProfileSubtype {
                                $Global:SPUPGetProfileSubtypeCalled = $true
                                return @{
                                Properties = $userProfileSubTypePropertiesProperty
                                }
                            } -PassThru 
                return $result
            }
            $testParams.Ensure = "Present"
            $testParams.DisplayOrder = 5401
            $testParams.DisplayName = "ProfileInformationUpdate"

            It "Should return valid value from the Get method" {
                $Global:SPUPGetSectionByNameCalled = $true
                $currentValues = Get-TargetResource @testParams 
                $currentValues.Ensure | Should Be "Present"
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.UserProfileService } 
            }
            
            It "Should return false when the Test method is called" {
                $Global:SPUPGetSectionByNameCalled = $true
                Test-TargetResource @testParams | Should Be $false
            }
            It "Should update an user profile property in the set method" {
                $Global:SPUPSubTypeCreateCalled = $false
                $Global:UpsConfigManagerSetDisplayOrderBySectionNameCalled = $false
                $Global:SPUPGetSectionByNameCalled=$true
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPDscObjectPropertyIfValuePresent
                $Global:SPUPSubTypeCreateCalled | should be $false
                $Global:UpsConfigManagerSetDisplayOrderBySectionNameCalled | Should be $true
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope

