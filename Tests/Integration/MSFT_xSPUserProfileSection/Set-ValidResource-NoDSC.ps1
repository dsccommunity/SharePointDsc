#
# Set_ValidResource.ps1
#
param(
     $Name,
         $Ensure,
         $UserProfileService,
         $DisplayName,
         $DisplayOrder
            
)
 #   $creds = Get-Credential
Import-Module C:\Users\camilo.CONTOSO\Source\Repos\xSharePoint\Modules\xSharePoint\Modules\xSharePoint.Util\xSharePoint.Util.psm1


  $params =  @{
            Name = "PersonalSection4"
            UserProfileService = "User Profile Service Application"
            DisplayName = "Personal Section4"
            DisplayOrder =5000
            PsDscRunAsCredential = $cred
        }
        


        #region setting up objects 
        $ups = Get-SPServiceApplication -Name $params.UserProfileService -ErrorAction SilentlyContinue 
 
        If ($null -eq $ups)
        {
               throw "service application $( $params.UserProfileService) not found"
        }
        
        $caURL = (Get-SpWebApplication  -IncludeCentralAdministration | ?{$_.IsAdministrationWebApplication -eq $true }).Url
        $context = Get-SPServiceContext  $caURL 

        $userProfileConfigManager = new-object Microsoft.Office.Server.UserProfiles.UserProfileConfigManager($context)
        if($null -eq $userProfileConfigManager)
        {   #if config manager returns when ups is available then isuee is permissions
            throw "account running process needs admin permission on user profile service application"
        }
              $properties = $userProfileConfigManager.GetPropertiesWithSection()
#        $userProfilePropertyManager = $userProfileConfigManager.ProfilePropertyManager
#        $coreProperties = $userProfileConfigManager.ProfilePropertyManager.GetCoreProperties()                              
        $userProfileProperty = $properties.GetSectionByName($params.Name) 

        if( $params.ContainsKey("Ensure") -and $params.Ensure -eq "Absent"){
            if($userProfileProperty -ne $null)
            {
                $properties.RemoveSectionByName($params.Name)
            }
            return;
        } elseif($userProfileProperty -eq $null){
            $coreProperty = $properties.Create($true)
            $coreProperty.Name = $params.Name
            $coreProperty.DisplayName = $params.DisplayName
            $coreProperty.Commit()
        }else{
            Set-xSharePointObjectPropertyIfValueExists -ObjectToSet $userProfileProperty -PropertyToSet "DisplayName" -ParamsValue $params -ParamKey "DisplayName"
            $userProfileProperty.Commit()
        }

        #region display order
        if($params.ContainsKey("DisplayOrder"))
        {
            $properties = $userProfileConfigManager.GetPropertiesWithSection()
            $properties.SetDisplayOrderBySectionName($params.Name,$params.DisplayOrder)
            $properties.CommitDisplayOrder()
        }



break;






           $upsa = Get-SPServiceApplication -Name $params.UserProfileService -ErrorAction SilentlyContinue 
        if ($null -eq $upsa) { 
            return $null 
        }
        $caURL = (Get-SpWebApplication  -IncludeCentralAdministration | ?{$_.IsAdministrationWebApplication -eq $true }).Url
        $context = Get-SPServiceContext -Site $caURL 
        $userProfileConfigManager  = new-object Microsoft.Office.Server.UserProfiles.UserProfileConfigManager($context)
        
        $userProfileSubTypeManager = Get-xSharePointUserProfileSubTypeManager $context
        $userProfileSubType = $userProfileSubTypeManager.GetProfileSubtype("UserProfile")
        
        $userProfileProperty = $userProfileSubType.Properties.GetSectionByName($params.Name) 
        if($userProfileProperty -eq $null){
            return $null 
        }
        
        


        break
Import-Module C:\Users\camilo.CONTOSO\Source\Repos\xSharePoint\Modules\xSharePoint\DSCResources\MSFT_xSPUserProfileSection\MSFT_xSPUserProfileSection.psm1
Set-TargetResource  -Name  "PersonalInformationSection" `
            -UserProfileService  "User Profile Service Application" `
            -DisplayName  "Personal Information" `
            -DisplayOrder 5000 
          #  -InstallAccount $creds
#Set-TargetResource   $params