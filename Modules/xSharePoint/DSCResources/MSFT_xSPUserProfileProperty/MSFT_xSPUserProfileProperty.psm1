function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)] [System.string] $Name ,
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] [System.string ] $Ensure ,
        [parameter(Mandatory = $true)] [System.string] $UserProfileService ,
        [parameter(Mandatory = $false)] [System.string] $DisplayName ,
        [parameter(Mandatory = $false)] [ValidateSet("BigInteger", "Binary", "Boolean", "Date", "DateNoYear", "DateTime", "Email", "Float", "Guid", "HTML", "Integer", "Person", "String",  "StringMultiValue", "TimeZone", "URL")] [System.string] $Type ,
        [parameter(Mandatory = $false)] [System.string] $Description ,
        [parameter(Mandatory = $false)] [ValidateSet("Mandatory", "Optin","Optout", "Disabled")] [System.string] $PolicySetting ,
        [parameter(Mandatory = $false)] [ValidateSet("Public", "Contacts", "Organization", "Manager", "Private")] [System.string] $PrivacySetting ,
        [parameter(Mandatory = $false)] [System.string] $MappingConnectionName ,
        [parameter(Mandatory = $false)] [System.string] $MappingPropertyName ,
        [parameter(Mandatory = $false)] [System.string] $MappingDirection ,
        [parameter(Mandatory = $false)] [System.uint32] $Length ,
        [parameter(Mandatory = $false)] [System.uint32] $DisplayOrder ,
        [parameter(Mandatory = $false)] [System.Boolean] $IsEventLog ,
        [parameter(Mandatory = $false)] [System.Boolean] $IsVisibleOnEditor ,
        [parameter(Mandatory = $false)] [System.Boolean] $IsVisibleOnViewer ,
        [parameter(Mandatory = $false)] [System.Boolean] $IsUserEditable ,
        [parameter(Mandatory = $false)] [System.Boolean] $IsAlias ,
        [parameter(Mandatory = $false)] [System.Boolean] $IsSearchable,
        [parameter(Mandatory = $false)] [System.Boolean] $UserOverridePrivacy ,
        [parameter(Mandatory = $false)] [System.string] $TermStore ,
        [parameter(Mandatory = $false)] [System.string] $TermGroup ,
        [parameter(Mandatory = $false)] [System.string] $TermSet ,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Getting user profile service application $Name"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
        
        $upsa = Get-SPServiceApplication -Name $params.UserProfileService -ErrorAction SilentlyContinue 
        if ($null -eq $upsa) { 
            return $null 
        }
        $caURL = (Get-SpWebApplication  -IncludeCentralAdministration | ?{$_.IsAdministrationWebApplication -eq $true }).Url
        $context = Get-SPServiceContext -Site $caURL 
        $userProfileConfigManager  = new-object Microsoft.Office.Server.UserProfiles.UserProfileConfigManager($context)
        
        $userProfileSubTypeManager = Get-xSharePointUserProfileSubTypeManager $context
        $userProfileSubType = $userProfileSubTypeManager.GetProfileSubtype("UserProfile")
        
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
            $currentMapping  = $syncConnection.PropertyMapping.Item($params.Name)
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
        

        return @{
            Name = $userProfileProperty.Name 
            UserProfileServiceAppName = $params.UserProfileService
            DisplayName = $userProfileProperty.DisplayName
            Type = $userProfileProperty.CoreProperty.Type
            Description = $userProfileProperty.Description 
            PolicySetting = $userProfileProperty.PrivacyPolicy
            PrivacySetting = $userProfileProperty.DefaultPrivacy
            MappingConnectionName = $mapping.ConnectionName
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
        [parameter(Mandatory = $true)] [System.string ] $Name ,
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] [System.string ] $Ensure ,
        [parameter(Mandatory = $true)] [System.string ] $UserProfileService ,
        [parameter(Mandatory = $false)] [System.string ] $DisplayName ,
        [parameter(Mandatory = $false)] [ValidateSet("BigInteger", "Binary", "Boolean", "Date", "DateNoYear", "DateTime", "Email", "Float", "Guid", "HTML", "Integer", "Person", "String",  "StringMultiValue", "TimeZone", "URL")][System.string ] $Type ,
        [parameter(Mandatory = $false)] [System.string ] $Description ,
        [parameter(Mandatory = $false)] [ValidateSet("Mandatory", "Optin","Optout", "Disabled")] [System.string ] $PolicySetting ,
        [parameter(Mandatory = $false)] [ValidateSet("Public", "Contacts", "Organization", "Manager", "Private")] [System.string ] $PrivacySetting ,
        [parameter(Mandatory = $false)] [System.string ] $MappingConnectionName ,
        [parameter(Mandatory = $false)] [System.string ] $MappingPropertyName ,
        [parameter(Mandatory = $false)] [System.string ] $MappingDirection ,
        [parameter(Mandatory = $false)] [System.uint32] $Length ,
        [parameter(Mandatory = $false)] [System.uint32] $DisplayOrder ,
        [parameter(Mandatory = $false)] [System.Boolean] $IsEventLog ,
        [parameter(Mandatory = $false)] [System.Boolean] $IsVisibleOnEditor ,
        [parameter(Mandatory = $false)] [System.Boolean] $IsVisibleOnViewer ,
        [parameter(Mandatory = $false)] [System.Boolean] $IsUserEditable ,
        [parameter(Mandatory = $false)] [System.Boolean] $IsAlias ,
        [parameter(Mandatory = $false)] [System.Boolean] $IsSearchable,
        [parameter(Mandatory = $false)] [System.Boolean] $UserOverridePrivacy ,
        [parameter(Mandatory = $false)] [System.string ] $TermStore ,
        [parameter(Mandatory = $false)] [System.string ] $TermGroup ,
        [parameter(Mandatory = $false)] [System.string ] $TermSet ,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    #note for integration test: CA can take a couple of minutes to notice the change. don't try refreshing properties page. go through from a fresh "flow" from Service apps page :)

    Write-Verbose -Message "Creating user profile property $Name"
    $test = $PSBoundParameters
    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $test -ScriptBlock {
        $params = $args[0]
        #region Validating parameter combinations
        if( ($params.ContainsKey("TermSet")  -or $params.ContainsKey("TermGroup") -or $params.ContainsKey("TermSet") ) -and
            ($params.ContainsKey("TermSet")  -and $params.ContainsKey("TermGroup") -and $params.ContainsKey("TermSet") -eq $false ) 
            )
        {
            throw "You have to provide all 3 parameters Termset, TermGroup and TermStore when providing any of the 3."
        }

        #what if combination property type + termstore isn't possible?
        if($params.ContainsKey("TermSet")  -and (@("string","stringmultivalue").Contains($params.Type.ToLower()) -eq $false)  ){
            throw "Only String and String Maultivalue can use Termsets"
        }
        #endregion 
        #region setting up objects 
        $ups = Get-SPServiceApplication -Name $params.UserProfileService -ErrorAction SilentlyContinue 
 
        If ($null -eq $ups)
        {
            return $null
        }
        
        $caURL = (Get-SpWebApplication  -IncludeCentralAdministration | ?{$_.IsAdministrationWebApplication -eq $true }).Url
        $context = Get-SPServiceContext  $caURL 

        $userProfileConfigManager = new-object Microsoft.Office.Server.UserProfiles.UserProfileConfigManager($context)
        if($null -eq $userProfileConfigManager)
        {   #if config manager returns when ups is available then isuee is permissions
            throw "account running process needs admin permissions on the user profile service application"
        }
        $coreProperties = $userProfileConfigManager.ProfilePropertyManager.GetCoreProperties()                              
        
        $userProfilePropertyManager = $userProfileConfigManager.ProfilePropertyManager
        $userProfileTypeProperties = $userProfilePropertyManager.GetProfileTypeProperties([Microsoft.Office.Server.UserProfiles.ProfileType]::User)
        

        $userProfileSubTypeManager = Get-xSharePointUserProfileSubTypeManager $context
        $userProfileSubType = $userProfileSubTypeManager.GetProfileSubtype("UserProfile")
        
        $userProfileSubTypeProperties = $userProfileSubType.Properties
        
        
        #endregion 

        $userProfileProperty = $userProfileSubType.Properties.GetPropertyByName($params.Name) 

        if($userProfileProperty -ne $null -and $userProfileProperty.CoreProperty.Type -ne $params.Type )
        {
            throw "Can't change property type. Current Type  is $($userProfileProperty.CoreProperty.Type)"
        }

        #region retrieving term set 
        $termSet =$null
        #Get-TermSet
        if ($params.ContainsKey("TermSet"))
        {
            $currentTermSet=$userProfileProperty.CoreProperty.TermSet;
            if($currentTermSet.Name -ne $params.TermSet -or 
                $currentTermSet.Group.Name -ne $params.TermGroup -or 
                $currentTermSet.TermStore.Name -ne $params.TermStore){

                $session = new-Object  Microsoft.SharePoint.Taxonomy.TaxonomySession($caURL);
                $termStore = $session.TermStores[$params.TermStore];
                if($termStore -eq $null)
                {
                    throw "Term Store $($params.termStore) not found"
                }
                $group = $termStore.Groups[$params.TermGroup];
                if($group -eq $null)
                {
                    throw "Term Group $($params.termGroup) not found"
                }
                $termSet = $group.TermSets[$params.TermSet];
                if($termSet -eq $null)
                {
                    throw "Term Set $($params.termSet) not found"
                }
            }
        }

        #endregion

        #Ensure-Property $params
        if( $params.ContainsKey("Ensure") -and $params.Ensure -eq "Absent"){
            if($userProfileProperty -ne $null)
            {
                $coreProperties.RemovePropertyByName($params.Name)
                return;
            }
        } elseif($userProfileProperty -eq $null){
            #region creating property
            $coreProperty = $coreProperties.Create($false)
            $coreProperty.Name = $params.Name
            $coreProperty.DisplayName = $params.DisplayName

            Set-xSharePointObjectPropertyIfValueExists -ObjectToSet $coreProperty -PropertyToSet "Length" -ParamsValue $params -ParamKey "Length"                                                
    
            if($params.Type.ToLower() -eq "stringmultivalue")
            {
                $coreProperty.IsMultivalued =$true;
            }
            $coreProperty.Type = $params.Type
            if($termSet -ne $null){
                $coreProperty.TermSet = $termSet 
            }

            $CoreProperties.Add($coreProperty)
            $upTypeProperty = $userProfileTypeProperties.Create($coreProperty)                                                                
            $userProfileTypeProperties.Add($upTypeProperty)
            $upSubProperty = $userProfileSubTypeProperties.Create($UPTypeProperty)
            $userProfileSubTypeProperties.Add($upSubProperty)        
            Sleep -Milliseconds 100
            $userProfileProperty =  $userProfileSubType.Properties.GetPropertyByName($params.Name) 

            #return $userProfileProperty
            #endregion
        }
        #region setting up  properties 
        #update-property $userProfileProperty $params $termSet

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
        if($termSet -ne $null){
            $coreProperty.TermSet = $termSet
        }
        #endregion
        $userProfileProperty.CoreProperty.Commit()
        $userProfileTypeProperty.Commit()
        $userProfileProperty.Commit()
        
        
        #/Ensure-Property 

        #region display order
        # Set-DisplayOrder
        if($params.ContainsKey("DisplayOrder"))
        {
            $profileManager = New-Object Microsoft.Office.Server.UserProfiles.UserProfileManager($context)
            $profileManager.Properties.SetDisplayOrderByPropertyName($params.Name,$params.DisplayOrder)
            $profileManager.Properties.CommitDisplayOrder()
        }
        #endregion
        #region mapping
        #Set-Mapping
        if($params.ContainsKey("MappingConnectionName") -and $params.ContainsKey("MappingPropertyName")){
            $syncConnection  = $userProfileConfigManager.ConnectionManager | Where-Object { $_.DisplayName -eq $params.MappingConnectionName} 
            if($null -eq $syncConnection ) {
                throw "connection not found"
            }
            $syncConnection  = $userProfileConfigManager.ConnectionManager| Where-Object { $_.DisplayName -eq $params.MappingConnectionName}  
            #$userProfileConfigManager.ConnectionManager[$params.MappingConnectionName]
            $currentMapping  = $syncConnection.PropertyMapping.Item($params.Name)
            if($currentMapping -eq $null -or
                ($currentMapping.DataSourcePropertyName -ne $params.MappingPropertyName) -or
                ($currentMapping.IsImport -and $params.ContainsKey("MappingDirection") -and $params.MappingDirection -eq "Export") 
               ){
                if($currentMapping -ne $null ){
                    $currentMapping.Delete() #API allows updating, but UI doesn't do that.
                }
                $export = $params.ContainsKey("MappingDirection") -and $params.MappingDirection -eq "Export"
                if ($Connection.Type -eq "ActiveDirectoryImport"){  
                        if($export){
                            throw "not implemented"
                        }else{
                            $Connection.AddPropertyMapping($params.MappingPropertyName,$params.Name)  
                            $Connection.Update()  
                        }
                }else{
                    if ($export){  
                        $syncConnection.PropertyMapping.AddNewExportMapping([Microsoft.Office.Server.UserProfiles.ProfileType]::User,$params.Name,$params.MappingPropertyName)
                    }else{
                        $syncConnection.PropertyMapping.AddNewMapping([Microsoft.Office.Server.UserProfiles.ProfileType]::User,$params.Name,$params.MappingPropertyName)
                    }
                }
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
        [parameter(Mandatory = $true)] [System.string ] $Name ,
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] [System.string ] $Ensure ,
        [parameter(Mandatory = $true)] [System.string ] $UserProfileService ,
        [parameter(Mandatory = $false)] [System.string ] $DisplayName ,
        [parameter(Mandatory = $false)] [ValidateSet("BigInteger", "Binary", "Boolean", "Date", "DateNoYear", "DateTime", "Email", "Float", "Guid", "HTML", "Integer", "Person", "String",  "StringMultiValue", "TimeZone", "URL")][System.string ] $Type ,
        [parameter(Mandatory = $false)] [System.string ] $Description ,
        [parameter(Mandatory = $false)] [ValidateSet("Mandatory","Optin","Optout","Disabled")] [System.string ] $PolicySetting ,
        [parameter(Mandatory = $false)] [ValidateSet("Public","Contacts","Organization","Manager","Private")] [System.string ] $PrivacySetting ,
        [parameter(Mandatory = $false)] [System.string ] $MappingConnectionName ,
        [parameter(Mandatory = $false)] [System.string ] $MappingPropertyName ,
        [parameter(Mandatory = $false)] [System.string ] $MappingDirection ,
        [parameter(Mandatory = $false)] [System.uint32] $Length ,
        [parameter(Mandatory = $false)] [System.uint32] $DisplayOrder ,
        [parameter(Mandatory = $false)] [System.Boolean] $IsEventLog ,
        [parameter(Mandatory = $false)] [System.Boolean] $IsVisibleOnEditor ,
        [parameter(Mandatory = $false)] [System.Boolean] $IsVisibleOnViewer ,
        [parameter(Mandatory = $false)] [System.Boolean] $IsUserEditable ,
        [parameter(Mandatory = $false)] [System.Boolean] $IsAlias ,
        [parameter(Mandatory = $false)] [System.Boolean] $IsSearchable,
        [parameter(Mandatory = $false)] [System.Boolean] $UserOverridePrivacy ,
        [parameter(Mandatory = $false)] [System.string ] $TermStore ,
        [parameter(Mandatory = $false)] [System.string ] $TermGroup ,
        [parameter(Mandatory = $false)] [System.string ] $TermSet ,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount

    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing for user profile property $Name"
    if ($null -eq $CurrentValues) { return $false  }
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("Name","DisplayName","Type", "Description", "PolicySetting", "PrivacySetting","MappingConnectionName","MappingPropertyName", "MappingDirection", "Length", "DisplayOrder", "IsEventLog", "IsVisibleOnEditor", "IsVisibleOnViewer","IsUserEditable", "IsAlias", "IsSearchabe", "UserOverridePrivacy", "TermGroup", "TermStore", "TermSet")
}

Export-ModuleMember -Function *-TargetResource

