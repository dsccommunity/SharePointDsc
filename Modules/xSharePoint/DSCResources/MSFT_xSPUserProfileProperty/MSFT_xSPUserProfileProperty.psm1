function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.string ] $Name ,
        [parameter(Mandatory = $false)]  [System.string ] $Ensure ,
        [parameter(Mandatory = $true)]  [System.string ] $UserProfileServiceAppName ,
        [parameter(Mandatory = $false)]  [System.string ] $DisplayName ,
        [parameter(Mandatory = $false)]  [System.string ] $Type ,
        [parameter(Mandatory = $false)]  [System.string ] $Description ,
        [parameter(Mandatory = $false)]  [System.string ] $PolicySetting ,
        [parameter(Mandatory = $false)]  [System.string ] $PrivacySetting ,
        [parameter(Mandatory = $false)]  [System.bool ] $AllowUserEdit ,
        [parameter(Mandatory = $false)]  [System.string ] $MappingConnectionName ,
        [parameter(Mandatory = $false)]  [System.string ] $MappingPropertyName ,
        [parameter(Mandatory = $false)]  [System.string ] $MappingDirection ,
        [parameter(Mandatory = $false)]  [System.int ] $Length ,
        [parameter(Mandatory = $false)]  [System.int ] $DisplayOrder ,
        [parameter(Mandatory = $false)]  [System.bool ] $IsEventLog ,
        [parameter(Mandatory = $false)]  [System.bool ] $IsVisibleOnEditor ,
        [parameter(Mandatory = $false)]  [System.bool ] $IsVisibleOnViewer ,
        [parameter(Mandatory = $false)]  [System.bool ] $IsUserEditable ,
        [parameter(Mandatory = $false)]  [System.bool ] $IsAlias ,
        [parameter(Mandatory = $false)]  [System.bool ] $IsSearchable,
        [parameter(Mandatory = $false)]  [System.bool ] $UserOverrridePrivacy ,
        [parameter(Mandatory = $false)]  [System.string ] $TermStore ,
        [parameter(Mandatory = $false)]  [System.string ] $TermGroup ,
        [parameter(Mandatory = $false)]  [System.string ] $TermSet ,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Getting user profile service application $Name"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
        
        $upsa = Get-SPServiceApplication -Name $params.UserProfileServiceAppName -ErrorAction SilentlyContinue 
        if ($null -eq $upsa) { 
            return $null 
        }
        $caURL = (Get-SpWebApplication  -IncludeCentralAdministration | ?{$_.IsAdministrationWebApplication -eq $true }).Url
        $context = Get-SPServiceContext  $caURL 
        $userProfileConfigManager  = new-object Microsoft.Office.Server.UserProfiles.UserProfileConfigManager($context)
        $userProfileSubTypeManager = [Microsoft.Office.Server.UserProfiles.ProfileSubtypeManager]::Get($context)
        $userProfileSubType = $userProfileSubTypeManager.GetProfileSubtype([Microsoft.Office.Server.UserProfiles.ProfileSubtypeManager]::GetDefaultProfileName([Microsoft.Office.Server.UserProfiles.ProfileType]::User))
        $userProfileProperty = $userProfileSubType.Properties.GetPropertyByName($params.Name) 
        if($null -eq $userProfileProperty ){
            return $null 
        }
        
        $termSet = @{
            TermSet = ""
            TermGroup =""
            TermStore = ""
        }

        if($userProfileProperty.CoreProperty.TermSet -ne $null)
        {
            $termSet.TermSet = $userProfileProperty.CoreProperty.TermSet.Name
            $termSet.TermGroup = $userProfileProperty.CoreProperty.TermSet.Group.Name
            $termSet.TermStore = $userProfileProperty.CoreProperty.TermSet.TermStore.Name
        }
        $mapping  = @{
            ConectionName = ""
            PropertyName =""
            Direction = ""
        }
        $syncConnection  = $userProfileConfigManager.ConnectionManager | ? {$_.PropertyMapping.Item($params.Name) -ne $null} 
        if($syncConnection -ne $null) {
            $currentMapping  = $synchConnection.PropertyMapping.Item($params.Name)
            if($currentMapping -ne $null)
            {
                $mapping.Direction = "Import"
                $mapping.ConnectionName = $params.MappingConnectionName 
                if($currentMapping.IsExport)
                {
                    $mapping.Direction = "Export"
                }
                $mapping.PropertyName = $currentMapping.DataSourcePropertyName
                }
            }
        }

        return @{
            Name = $userProfileProperty.Name 
            UserProfileServiceAppName = $params.$UserProfileServiceAppName
            DisplayName = $userProfileProperty.DisplayName
            Type = $userProfileProperty.CoreProperty.Type.GetTypeCode()
            Description = $userProfileProperty.Description 
            PolicySetting = $userProfileProperty.PrivacyPolicy
            PrivacySetting = $userProfileProperty.DefaultPrivacy
            MappingConnectionName = $MappingConnectionName.ConnectionName
            MappingPropertyName = $mapping.PropertyName
            MappingDirection = $Mapping.Direction
            Length = $userProfileProperty.CoreProperty.Length
            DisplayOrder =$userProfileProperty.DisplayOrder 
            IsEventLog =$userProfileProperty.TypeProperty.IsEventLog
            IsVisibleOnEditor=$userProfileProperty.TypeProperty.IsVisibleOnEditor
            IsVisibleOnViewer  =$userProfileProperty.TypeProperty.IsVisibleOnViewer
            IsUserEditable = $userProfileProperty.IsUserEditable
            IsAlias = $userProfileProperty.IsAlias 
            IsSearchable = $userProfileProperty.CoreProperty.IsSearchable 
            TermStore = $termSet.TermStore
            TermGroup = $termSet.TermGroup
            TermSet = $termSet.TermSet
            UserOverridePrivacy = $userProfileProperty.AllowPolicyOverride
        }

    }
    return $result
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  [System.string ] $Name ,
        [parameter(Mandatory = $false)]  [System.string ] $Ensure ,
        [parameter(Mandatory = $true)]  [System.string ] $UserProfileServiceAppName ,
        [parameter(Mandatory = $true)]  [System.string ] $DisplayName ,
        [parameter(Mandatory = $true)]  [System.string ] $Type ,
        [parameter(Mandatory = $false)]  [System.string ] $Description ,
        [parameter(Mandatory = $false)]  [System.string ] $PolicySetting ,
        [parameter(Mandatory = $false)]  [System.string ] $PrivacySetting ,
        [parameter(Mandatory = $false)]  [System.bool ] $AllowUserEdit ,
        [parameter(Mandatory = $false)]  [System.string ] $MappingConnectionName ,
        [parameter(Mandatory = $false)]  [System.string ] $MappingPropertyName ,
        [parameter(Mandatory = $false)]  [System.string ] $MappingDirection ,
        [parameter(Mandatory = $false)]  [System.int ] $Length ,
        [parameter(Mandatory = $false)]  [System.int ] $DisplayOrder ,
        [parameter(Mandatory = $false)]  [System.bool ] $IsEventLog ,
        [parameter(Mandatory = $false)]  [System.bool ] $IsVisibleOnEditor ,
        [parameter(Mandatory = $false)]  [System.bool ] $IsVisibleOnViewer ,
        [parameter(Mandatory = $false)]  [System.bool ] $IsUserEditable ,
        [parameter(Mandatory = $false)]  [System.bool ] $IsAlias ,
        [parameter(Mandatory = $false)]  [System.bool ] $IsSearchable,
        [parameter(Mandatory = $false)]  [System.bool ] $UserOverrridePrivacy ,
        [parameter(Mandatory = $false)]  [System.string ] $TermStore ,
        [parameter(Mandatory = $false)]  [System.string ] $TermGroup ,
        [parameter(Mandatory = $false)]  [System.string ] $TermSet ,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Creating user profile property $Name"

    $result = Invoke-xSharePointCommand -Credential $FarmAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
          $ups = Get-SPServiceApplication -Name $params.UserProfileService -ErrorAction SilentlyContinue 
 
        If ($null -eq $ups)
        {
            return $null
        }
        #what if permission isn't granted ?
        
        $caURL = (Get-SpWebApplication  -IncludeCentralAdministration | ?{$_.IsAdministrationWebApplication -eq $true }).Url
        $context = Get-SPServiceContext  $caURL 
        $userProfileConfigManager = new-object Microsoft.Office.Server.UserProfiles.UserProfileConfigManager($context)

        #$UPAConnMgr = $userProfileConfigManager.ConnectionManager
        $userProfilePropertyManager = $userProfileConfigManager.ProfilePropertyManager
        $userProfileTypeProperties = $userProfilePropertyManager.GetProfileTypeProperties([Microsoft.Office.Server.UserProfiles.ProfileType]::User)
        $coreProperties = $userProfileConfigManager.ProfilePropertyManager.GetCoreProperties()                              

        $userProfileSubTypeManager = [Microsoft.Office.Server.UserProfiles.ProfileSubtypeManager]::Get($context)
        $userProfileSubType = $userProfileSubTypeManager.GetProfileSubtype([Microsoft.Office.Server.UserProfiles.ProfileSubtypeManager]::GetDefaultProfileName([Microsoft.Office.Server.UserProfiles.ProfileType]::User))
        
        $userProfileProperty = $userProfileSubType.Properties.GetPropertyByName($params.Name) 

        if( $params.ContainsKey("Ensure") -and $params.Ensure -eq "Absent"){
	        if($userProfileProperty -ne $null)
	        {
		        $CoreProperties.RemovePropertyByName($params.Name)
	        }
        } elseif($userProfileProperty -eq $null){
	        $coreProperty = $CoreProperties.Create($false)
	        $coreProperty.Name = $params.Name
	        $coreProperty.DisplayName = $params.DisplayName

	        Set-xSharePointObjectPropertyIfValueExists -ObjectToSet $coreProperty -PropertyToSet "Length" -ParamsValue $params -ParamKey "Length"												
	
	        if($SharePointPropType.ToLower() -eq "stringmultivalue")
	        {
		        $coreProperty.IsMultivalued =$true;
	        }
	        $coreProperty.Type = $SharePointPropType
	        $CoreProperties.Add($coreProperty)
	        $UPTypeProperty = $userProfileTypeProperties.Create($coreProperty)                                                                
	        $upSubProperty = $UPProperties.Create($UPTypeProperty)
	        $UPProperties.Add($upSubProperty)																
	        Sleep -Miliseconds 100
	        $userProfileProperty =  $userProfileSubType.Properties.GetPropertyByName($params.Name) 
        }

        $coreProperty = $userProfileProperty.CoreProperty
        $userProfileTypeProperty = $userProfileProperty.TypeProperty
        Set-xSharePointObjectPropertyIfValueExists -ObjectToSet $coreProperty -PropertyToSet "DisplayName" -ParamsValue $params -ParamKey "DisplayName"
        Set-xSharePointObjectPropertyIfValueExists -ObjectToSet $coreProperty -PropertyToSet "Description" -ParamsValue $params -ParamKey "Description"

        Set-xSharePointObjectPropertyIfValueExists -ObjectToSet $userProfileTypeProperty -PropertyToSet "IsVisibleOnViewer" -ParamsValue $params -ParamKey "IsVisibleOnViewer"
        Set-xSharePointObjectPropertyIfValueExists -ObjectToSet $userProfileTypeProperty -PropertyToSet "IsVisibleOnEditor" -ParamsValue $params -ParamKey "IsVisibleOnEditor"
        Set-xSharePointObjectPropertyIfValueExists -ObjectToSet $userProfileTypeProperty -PropertyToSet "IsEventLog" -ParamsValue $params -ParamKey "IsEventLog"

        Set-xSharePointObjectPropertyIfValueExists -ObjectToSet $userProfileProperty -PropertyToSet "DefaultPrivacy" -ParamsValue $params -ParamKey "PrivacySetting"
        Set-xSharePointObjectPropertyIfValueExists -ObjectToSet $userProfileProperty -PropertyToSet "PrivacyPolicy" -ParamsValue $params -ParamKey "PolicySetting"
        Set-xSharePointObjectPropertyIfValueExists -ObjectToSet $userProfileProperty -PropertyToSet "IsUserEditable" -ParamsValue $params -ParamKey "IsUserEditable"																
        Set-xSharePointObjectPropertyIfValueExists -ObjectToSet $userProfileProperty -PropertyToSet "UserOverridePrivacy" -ParamsValue $params -ParamKey "UserOverridePrivacy"																
        #region MMS properties
        if ((![String]::IsNullOrEmpty($termStoreName)) -and (![String]::IsNullOrEmpty($termgroupName)) -and (![String]::IsNullOrEmpty($termSetName)))
        {
            $session = new-Object  Microsoft.SharePoint.Taxonomy.TaxonomySession($caURL);
            $termStore = $session.TermStores[$params.TermStore];
            $group = $termStore.Groups[$params.TermGroup];
            $termSet = $group.TermSets[$params.TermSet];
            if($termSet -ne $null)
            {
                $coreProperty.TermSet = $termSet
            }
        }
        #endregion
        
        $coreProperty.CoreProperty.Commit()
        $userProfileTypeProperty.Commit()
        $userProfileProperty.Commit()
        #Setting the display order
        if($params.ContainsKey("DisplayOrder"))
        {
	        $UPProperties.SetDisplayOrderByPropertyName($params.Name,$SharePointPropDisplayOrder)
	        $UPProperties.CommitDisplayOrder()
        }

        #region mapping
        if($params.ContainsKey("MappingConnectionName") -and $params.ContainsKey("MappingPropertyName")){
            $syncConnection  = $userProfileConfigManager.ConnectionManager[$params.MappingConnectionName]
            $currentMapping  = $synchConnection.PropertyMapping.Item($params.Name)
            if($currentmapping -eq $null)
            {
	            $import = ((!$params.ContainsKey("MappingDirection")) -or ($params.ContainsKey("MappingDirection") -and $params.MappingDirection -eq "Import"))
	            $export = !$import -and ($params.ContainsKey("MappingDirection") -and $params.MappingDirection -eq "Export") 
                $synchConnection.PropertyMapping.Add( $params.Name, $params.MappingPropertyName,$import, $export) 
            }
        }
        #endregion 
    }
    return  $result
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.string ] $Name ,
        [parameter(Mandatory = $false)]  [System.string ] $Ensure ,
        [parameter(Mandatory = $true)]  [System.string ] $UserProfileServiceAppName ,
        [parameter(Mandatory = $false)]  [System.string ] $DisplayName ,
        [parameter(Mandatory = $false)]  [System.string ] $Type ,
        [parameter(Mandatory = $false)]  [System.string ] $Description ,
        [parameter(Mandatory = $false)]  [System.string ] $PolicySetting ,
        [parameter(Mandatory = $false)]  [System.string ] $PrivacySetting ,
        [parameter(Mandatory = $false)]  [System.bool ] $AllowUserEdit ,
        [parameter(Mandatory = $false)]  [System.string ] $MappingConnectionName ,
        [parameter(Mandatory = $false)]  [System.string ] $MappingPropertyName ,
        [parameter(Mandatory = $false)]  [System.string ] $MappingDirection ,
        [parameter(Mandatory = $false)]  [System.int ] $Length ,
        [parameter(Mandatory = $false)]  [System.int ] $DisplayOrder ,
        [parameter(Mandatory = $false)]  [System.bool ] $IsEventLog ,
        [parameter(Mandatory = $false)]  [System.bool ] $IsVisibleOnEditor ,
        [parameter(Mandatory = $false)]  [System.bool ] $IsVisibleOnViewer ,
        [parameter(Mandatory = $false)]  [System.bool ] $IsUserEditable ,
        [parameter(Mandatory = $false)]  [System.bool ] $IsAlias ,
        [parameter(Mandatory = $false)]  [System.bool ] $IsSearchable,
        [parameter(Mandatory = $false)]  [System.bool ] $UserOverrridePrivacy ,
        [parameter(Mandatory = $false)]  [System.string ] $TermStore ,
        [parameter(Mandatory = $false)]  [System.string ] $TermGroup ,
        [parameter(Mandatory = $false)]  [System.string ] $TermSet ,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount

    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing for user profile service application $Name"
    if ($null -eq $CurrentValues) { return $false }
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("Name")
}

Export-ModuleMember -Function *-TargetResource

