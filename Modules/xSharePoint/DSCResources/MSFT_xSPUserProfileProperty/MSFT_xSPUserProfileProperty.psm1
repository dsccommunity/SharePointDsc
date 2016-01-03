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
        [parameter(Mandatory = $false)]  [System.bool ] $UserOverrridePrivacy ,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Getting user profile service application $Name"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        

        $upsa = Get-SPServiceApplication -Name $params.UserProfileServiceAppName -ErrorAction SilentlyContinue 
        $UPProperty = $userProfileProperties.GetPropertyByName($params.Name)  
        if ($null -eq $upsa) { 
            return $null 
        }
            return @{
                Name = $serviceApp.DisplayName
                ApplicationPool = $serviceApp.ApplicationPool.Name
                FarmAccount = $farmAccount
                MySiteHostLocation = $params.MySiteHostLocation
                ProfileDBName = $databases.ProfileDatabase.Name
                ProfileDBServer = $databases.ProfileDatabase.Server.Name
                SocialDBName = $databases.SocialDatabase.Name
                SocialDBServer = $databases.SocialDatabase.Server.Name
                SyncDBName = $databases.SynchronizationDatabase.Name
                SyncDBServer = $databases.SynchronizationDatabase.Server.Name
                InstallAccount = $params.InstallAccount
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
        [parameter(Mandatory = $false)]  [System.bool ] $UserOverrridePrivacy ,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Creating user profile property $Name"

    $result = Invoke-xSharePointCommand -Credential $FarmAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
        $UPAConfMgr = new-object Microsoft.Office.Server.UserProfiles.UserProfileConfigManager($context)

        #$UPAConnMgr = $UPAConfMgr.ConnectionManager
        $userProfilePropertyManager = $UPAConfMgr.ProfilePropertyManager
        $userProfileTypeProperties = $userProfilePropertyManager.GetProfileTypeProperties([Microsoft.Office.Server.UserProfiles.ProfileType]::User)
        $CoreProperties = $UPAConfMgr.ProfilePropertyManager.GetCoreProperties()                              

        $userProfileSubTypeManager = [Microsoft.Office.Server.UserProfiles.ProfileSubtypeManager]::Get($context)
        $userProfile = $userProfileSubTypeManager.GetProfileSubtype([Microsoft.Office.Server.UserProfiles.ProfileSubtypeManager]::GetDefaultProfileName([Microsoft.Office.Server.UserProfiles.ProfileType]::User))
        $UPProperty = $userProfileProperties.GetPropertyByName($params.Name)  

        if( $params.ContainsKey("Ensure") -and $params.Ensure -eq "Absent"){
	        if($UPProperty -ne $null)
	        {
		        $CoreProperties.RemovePropertyByName($params.Name)
	        }
        } elseif($UPProperty -eq $null){
	        $coreProperty = $CoreProperties.Create($false)
	        $coreProperty.Name = $params.Name
	        $coreProperty.DisplayName = $params.DisplayName
	        Set-xSharePointObjectPropertyIfValueExists -ObjectToSet $coreProperty -PropertyToSet "Length" -ParamsValue $params -ParamKey "PropLength"												
	
	        if($SharePointPropType.ToLower() -eq "stringmultivalue")
	        {
		        $coreProperty.IsMultivalued =$true;
	        }
	        $coreProperty.Type = $SharePointPropType
	        $CoreProperties.Add($coreProperty)
	        $UPTypeProperty = $userProfileTypeProperties.Create($coreProperty)                                                                
	        $upSubProperty = $userProfileProperties.Create($UPTypeProperty)
	        $userProfileProperties.Add($upSubProperty)																
	            Sleep -Miliseconds 100
	            $UPProperty = $userProfileProperties.GetPropertyByName($params.Name)   #sproperty
        }

        $UPTypeProperty = $userProfileTypeProperties.GetPropertyByName($params.Name)
        $coreProperty = $UPTypeProperty.CoreProperty
        Set-xSharePointObjectPropertyIfValueExists -ObjectToSet $coreProperty -PropertyToSet "DisplayName" -ParamsValue $params -ParamKey "DisplayName"

        Set-xSharePointObjectPropertyIfValueExists -ObjectToSet $UPTypeProperty -PropertyToSet "IsVisibleOnViewer" -ParamsValue $params -ParamKey "IsVisibleOnViewer"
        Set-xSharePointObjectPropertyIfValueExists -ObjectToSet $UPTypeProperty -PropertyToSet "IsVisibleOnEditor" -ParamsValue $params -ParamKey "IsVisibleOnEditor"
        Set-xSharePointObjectPropertyIfValueExists -ObjectToSet $UPTypeProperty -PropertyToSet "IsEventLog" -ParamsValue $params -ParamKey "IsEventLog"

        Set-xSharePointObjectPropertyIfValueExists -ObjectToSet $UPProperty -PropertyToSet "DefaultPrivacy" -ParamsValue $params -ParamKey "PrivacySetting"
        Set-xSharePointObjectPropertyIfValueExists -ObjectToSet $UPProperty -PropertyToSet "PrivacyPolicy" -ParamsValue $params -ParamKey "PolicySetting"
        Set-xSharePointObjectPropertyIfValueExists -ObjectToSet $UPProperty -PropertyToSet "IsUserEditable" -ParamsValue $params -ParamKey "IsUserEditable"																
        Set-xSharePointObjectPropertyIfValueExists -ObjectToSet $UPProperty -PropertyToSet "UserOverridePrivacy" -ParamsValue $params -ParamKey "UserOverridePrivacy"																

        $UPTypeProperty.CoreProperty.Commit()
        $UPTypeProperty.Commit()
        $UPProperty.Commit()
        #Setting the display order
        if($params.ContainsKey("DisplayOrder"))
        {
	        $userProfileProperties.SetDisplayOrderByPropertyName($params.Name,$SharePointPropDisplayOrder)
	        $userProfileProperties.CommitDisplayOrder()
        }

        #region mapping
        $syncConnection  = $UPAConfMgr.ConnectionManager[$params.MappingConnectionName]
        $PropertyMapping = $syncConnection.PropertyMapping
        $currentMapping  = $synchConnection.PropertyMapping.Item($params.Name)
        if($currentmapping -eq $null)
        {
	        $import = ((!$params.ContainsKey("MappingDirection")) -or ($params.ContainsKey("MappingDirection") -and $params.MappingDirection -eq "Import"))
	        $export = !$import -and ($params.ContainsKey("MappingDirection") -and $params.MappingDirection -eq "Export") 
            $synchConnection.PropertyMapping.Add( $params.Name, $params.MappingPropertyName,$import, $export) 
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
        [parameter(Mandatory = $false)]  [System.bool ] $UserOverrridePrivacy ,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount

    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing for user profile service application $Name"
    if ($null -eq $CurrentValues) { return $false }
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("Name")
}

Export-ModuleMember -Function *-TargetResource

