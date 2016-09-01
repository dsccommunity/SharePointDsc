function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,
        
        [parameter(Mandatory = $true)]
        [System.String]
        $UserProfileService,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $DisplayName,
        
        [parameter(Mandatory = $false)]
        [ValidateSet("BigInteger",
                     "Binary",
                     "Boolean",
                     "Date",
                     "DateNoYear",
                     "DateTime",
                     "Email",
                     "Float",
                     "Guid",
                     "HTML",
                     "Integer",
                     "Person",
                     "String",
                     "StringMultiValue",
                     "TimeZone",
                     "URL")]
        [System.String]
        $Type,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $Description,
        
        [parameter(Mandatory = $false)]
        [ValidateSet("Mandatory", "Optin","Optout", "Disabled")]
        [System.String]
        $PolicySetting,
        
        [parameter(Mandatory = $false)]
        [ValidateSet("Public", "Contacts", "Organization", "Manager", "Private")]
        [System.String] $PrivacySetting ,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $MappingConnectionName,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $MappingPropertyName,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $MappingDirection,
        
        [parameter(Mandatory = $false)]
        [System.Uint32]
        $Length,
        
        [parameter(Mandatory = $false)]
        [System.Uint32]
        $DisplayOrder,
        
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $IsEventLog,
        
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $IsVisibleOnEditor,
        
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $IsVisibleOnViewer,
        
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $IsUserEditable,
        
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $IsAlias,
        
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $IsSearchable,
        
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $UserOverridePrivacy,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $TermStore,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $TermGroup,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $TermSet,
        
        [parameter(Mandatory = $false)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",
        
        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting user profile service application $Name"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]
        
        $upsa = Get-SPServiceApplication -Name $params.UserProfileService -ErrorAction SilentlyContinue

        $nullReturn = @{
            Name = $params.Name
            UserProfileService = $params.UserProfileService
            Ensure = "Absent"
        } 

        if ($null -eq $upsa)
        { 
            return $nullReturn 
        }

        $caURL = (Get-SpWebApplication -IncludeCentralAdministration `
                  | Where-Object -FilterScript { $_.IsAdministrationWebApplication -eq $true }).Url
        $context = Get-SPServiceContext -Site $caURL
        $userProfileConfigManager = new-object Microsoft.Office.Server.UserProfiles.UserProfileConfigManager($context)
        
        $userProfileSubTypeManager = Get-SPDSCUserProfileSubTypeManager -Context $context
        $userProfileSubType = $userProfileSubTypeManager.GetProfileSubtype("UserProfile")
        
        $userProfileProperty = $userProfileSubType.Properties.GetPropertyByName($params.Name) 
        if ($null -eq $userProfileProperty)
        {
            return $nullReturn 
        }
        
        $termSet = @{
            TermSet = ""
            TermGroup =""
            TermStore = ""
        }

        if ($null -ne $userProfileProperty.CoreProperty.TermSet)
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
        $syncConnection  = $userProfileConfigManager.ConnectionManager `
                           | Where-Object -FilterScript {
                               $null -ne $_.PropertyMapping.Item($params.Name)
                             }
        if ($null -ne $syncConnection)
        {
            $currentMapping  = $syncConnection.PropertyMapping.Item($params.Name)
            if ($null -ne $currentMapping)
            {
                $mapping.Direction = "Import"
                $mapping.ConnectionName = $params.MappingConnectionName 
                if ($currentMapping.IsExport)
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
            Ensure = "Present"
        }
    }
    return $result
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,
        
        [parameter(Mandatory = $true)]
        [System.String]
        $UserProfileService,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $DisplayName,
        
        [parameter(Mandatory = $false)]
        [ValidateSet("BigInteger",
                     "Binary",
                     "Boolean",
                     "Date",
                     "DateNoYear",
                     "DateTime",
                     "Email",
                     "Float",
                     "Guid",
                     "HTML",
                     "Integer",
                     "Person",
                     "String",
                     "StringMultiValue",
                     "TimeZone",
                     "URL")]
        [System.String]
        $Type,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $Description,
        
        [parameter(Mandatory = $false)]
        [ValidateSet("Mandatory", "Optin","Optout", "Disabled")]
        [System.String]
        $PolicySetting,
        
        [parameter(Mandatory = $false)]
        [ValidateSet("Public", "Contacts", "Organization", "Manager", "Private")]
        [System.String] $PrivacySetting ,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $MappingConnectionName,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $MappingPropertyName,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $MappingDirection,
        
        [parameter(Mandatory = $false)]
        [System.Uint32]
        $Length,
        
        [parameter(Mandatory = $false)]
        [System.Uint32]
        $DisplayOrder,
        
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $IsEventLog,
        
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $IsVisibleOnEditor,
        
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $IsVisibleOnViewer,
        
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $IsUserEditable,
        
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $IsAlias,
        
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $IsSearchable,
        
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $UserOverridePrivacy,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $TermStore,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $TermGroup,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $TermSet,
        
        [parameter(Mandatory = $false)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",
        
        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    # note for integration test: CA can take a couple of minutes to notice the change.
    # don't try refreshing properties page. Go through from a fresh "flow" from Service apps page :)

    Write-Verbose -Message "Creating user profile property $Name"

    $PSBoundParameters.Ensure = $Ensure

    Invoke-SPDSCCommand -Credential $InstallAccount `
                        -Arguments $PSBoundParameters `
                        -ScriptBlock {
        $params = $args[0]
        #region Validating parameter combinations
        if (($params.ContainsKey("TermSet") `
                -or $params.ContainsKey("TermGroup") `
                -or $params.ContainsKey("TermSet") ) `
            -and ($params.ContainsKey("TermSet") `
                -and $params.ContainsKey("TermGroup") `
                -and $params.ContainsKey("TermSet") -eq $false))
        {
            throw ("You have to provide all 3 parameters Termset, TermGroup and TermStore when " + `
                   "providing any of the 3.")
        }

        #what if combination property type + termstore isn't possible?
        if ($params.ContainsKey("TermSet") `
            -and (@("string","stringmultivalue").Contains($params.Type.ToLower()) -eq $false))
        {
            throw "Only String and String Maultivalue can use Termsets"
        }
        #endregion
        #region setting up objects 
        $ups = Get-SPServiceApplication -Name $params.UserProfileService -ErrorAction SilentlyContinue 
 
        if ($null -eq $ups)
        {
            return $null
        }
        
        $caURL = (Get-SpWebApplication  -IncludeCentralAdministration `
                  | Where-Object -FilterScript {
                      $_.IsAdministrationWebApplication -eq $true
                    }).Url
        $context = Get-SPServiceContext  $caURL 

        $userProfileConfigManager = new-object Microsoft.Office.Server.UserProfiles.UserProfileConfigManager($context)
        if ($null -eq $userProfileConfigManager)
        {   #if config manager returns when ups is available then isuee is permissions
            throw ("account running process needs admin permissions on the user profile service " + `
                   "application")
        }
        $coreProperties = $userProfileConfigManager.ProfilePropertyManager.GetCoreProperties()                              
        
        $userProfilePropertyManager = $userProfileConfigManager.ProfilePropertyManager
        $userProfileTypeProperties = $userProfilePropertyManager.GetProfileTypeProperties([Microsoft.Office.Server.UserProfiles.ProfileType]::User)
        

        $userProfileSubTypeManager = Get-SPDSCUserProfileSubTypeManager -Context $context
        $userProfileSubType = $userProfileSubTypeManager.GetProfileSubtype("UserProfile")
        
        $userProfileSubTypeProperties = $userProfileSubType.Properties
        #endregion 

        $userProfileProperty = $userProfileSubType.Properties.GetPropertyByName($params.Name) 

        if ($null -ne $userProfileProperty -and $userProfileProperty.CoreProperty.Type -ne $params.Type )
        {
            throw "Can't change property type. Current Type  is $($userProfileProperty.CoreProperty.Type)"
        }

        #region retrieving term set 
        $termSet =$null
        #Get-TermSet
        if ($params.ContainsKey("TermSet"))
        {
            $currentTermSet=$userProfileProperty.CoreProperty.TermSet
            if ($currentTermSet.Name -ne $params.TermSet -or 
                $currentTermSet.Group.Name -ne $params.TermGroup -or 
                $currentTermSet.TermStore.Name -ne $params.TermStore){

                $session = new-Object  Microsoft.SharePoint.Taxonomy.TaxonomySession($caURL)
                $termStore = $session.TermStores[$params.TermStore]
                if ($null -eq $termStore)
                {
                    throw "Term Store $($params.termStore) not found"
                }
                $group = $termStore.Groups[$params.TermGroup]

                if ($null -eq $group)
                {
                    throw "Term Group $($params.termGroup) not found"
                }
                $termSet = $group.TermSets[$params.TermSet]
                
                if ($null -eq $termSet)
                {
                    throw "Term Set $($params.termSet) not found"
                }
            }
        }
        #endregion

        #Ensure-Property $params
        if ($params.ContainsKey("Ensure") -and $params.Ensure -eq "Absent")
        {
            if ($null -ne $userProfileProperty)
            {
                $coreProperties.RemovePropertyByName($params.Name)
                return;
            }
        }
        elseif ($null -eq $userProfileProperty)
        {
            #region creating property
            $coreProperty = $coreProperties.Create($false)
            $coreProperty.Name = $params.Name
            $coreProperty.DisplayName = $params.DisplayName

            Set-SPDscObjectPropertyIfValuePresent -ObjectToSet $coreProperty `
                                                  -PropertyToSet "Length" `
                                                  -ParamsValue $params `
                                                  -ParamKey "Length"                                                
    
            if ($params.Type.ToLower() -eq "stringmultivalue")
            {
                $coreProperty.IsMultivalued =$true;
            }
            $coreProperty.Type = $params.Type
            if ($null -ne $termSet)
            {
                $coreProperty.TermSet = $termSet 
            }

            $CoreProperties.Add($coreProperty)
            $upTypeProperty = $userProfileTypeProperties.Create($coreProperty)                                                                
            $userProfileTypeProperties.Add($upTypeProperty)
            $upSubProperty = $userProfileSubTypeProperties.Create($UPTypeProperty)
            $userProfileSubTypeProperties.Add($upSubProperty)        
            Start-Sleep -Milliseconds 100
            $userProfileProperty =  $userProfileSubType.Properties.GetPropertyByName($params.Name) 
            #endregion
        }
        #region setting up  properties 
        $coreProperty = $userProfileProperty.CoreProperty
        $userProfileTypeProperty = $userProfileProperty.TypeProperty
        Set-SPDscObjectPropertyIfValuePresent -ObjectToSet $coreProperty `
                                              -PropertyToSet "DisplayName" `
                                              -ParamsValue $params `
                                              -ParamKey "DisplayName"
        Set-SPDscObjectPropertyIfValuePresent -ObjectToSet $coreProperty `
                                              -PropertyToSet "Description" `
                                              -ParamsValue $params `
                                              -ParamKey "Description"

        Set-SPDscObjectPropertyIfValuePresent -ObjectToSet $userProfileTypeProperty `
                                              -PropertyToSet "IsVisibleOnViewer" `
                                              -ParamsValue $params `
                                              -ParamKey "IsVisibleOnViewer"
        Set-SPDscObjectPropertyIfValuePresent -ObjectToSet $userProfileTypeProperty `
                                              -PropertyToSet "IsVisibleOnEditor" `
                                              -ParamsValue $params `
                                              -ParamKey "IsVisibleOnEditor"
        Set-SPDscObjectPropertyIfValuePresent -ObjectToSet $userProfileTypeProperty `
                                              -PropertyToSet "IsEventLog" `
                                              -ParamsValue $params `
                                              -ParamKey "IsEventLog"

        Set-SPDscObjectPropertyIfValuePresent -ObjectToSet $userProfileProperty `
                                              -PropertyToSet "DefaultPrivacy" `
                                              -ParamsValue $params `
                                              -ParamKey "PrivacySetting"
        Set-SPDscObjectPropertyIfValuePresent -ObjectToSet $userProfileProperty `
                                              -PropertyToSet "PrivacyPolicy" `
                                              -ParamsValue $params `
                                              -ParamKey "PolicySetting"
        Set-SPDscObjectPropertyIfValuePresent -ObjectToSet $userProfileProperty `
                                              -PropertyToSet "IsUserEditable" `
                                              -ParamsValue $params `
                                              -ParamKey "IsUserEditable"                                                                
        Set-SPDscObjectPropertyIfValuePresent -ObjectToSet $userProfileProperty `
                                              -PropertyToSet "UserOverridePrivacy" `
                                              -ParamsValue $params `
                                              -ParamKey "UserOverridePrivacy"                                                                
        if ($null -ne $termSet)
        {
            $coreProperty.TermSet = $termSet
        }
        #endregion
        $userProfileProperty.CoreProperty.Commit()
        $userProfileTypeProperty.Commit()
        $userProfileProperty.Commit()
        #/Ensure-Property 

        #region display order
        # Set-DisplayOrder
        if ($params.ContainsKey("DisplayOrder"))
        {
            $profileManager = New-Object Microsoft.Office.Server.UserProfiles.UserProfileManager($context)
            $profileManager.Properties.SetDisplayOrderByPropertyName($params.Name,$params.DisplayOrder)
            $profileManager.Properties.CommitDisplayOrder()
        }
        #endregion
        #region mapping
        #Set-Mapping
        if ($params.ContainsKey("MappingConnectionName") `
            -and $params.ContainsKey("MappingPropertyName"))
        {
            $syncConnection = $userProfileConfigManager.ConnectionManager `
                              | Where-Object {
                                  $_.DisplayName -eq $params.MappingConnectionName
                                } 
            if ($null -eq $syncConnection )
            {
                throw "connection not found"
            }
            $syncConnection  = $userProfileConfigManager.ConnectionManager `
                               | Where-Object {
                                   $_.DisplayName -eq $params.MappingConnectionName
                                 }  
            #$userProfileConfigManager.ConnectionManager[$params.MappingConnectionName]
            $currentMapping  = $syncConnection.PropertyMapping.Item($params.Name)
            if ($null -eq $currentMapping `
                -or ($currentMapping.DataSourcePropertyName -ne $params.MappingPropertyName) `
                -or ($currentMapping.IsImport `
                    -and $params.ContainsKey("MappingDirection") `
                    -and $params.MappingDirection -eq "Export"))
            {
                if ($null -ne $currentMapping)
                {
                    $currentMapping.Delete() #API allows updating, but UI doesn't do that.
                }
                $export = $params.ContainsKey("MappingDirection") `
                          -and $params.MappingDirection -eq "Export"
                if ($Connection.Type -eq "ActiveDirectoryImport")
                {  
                        if ($export)
                        {
                            throw "not implemented"
                        }
                        else
                        {
                            $Connection.AddPropertyMapping($params.MappingPropertyName,$params.Name)  
                            $Connection.Update()  
                        }
                }
                else
                {
                    if ($export)
                    {  
                        $syncConnection.PropertyMapping.AddNewExportMapping([Microsoft.Office.Server.UserProfiles.ProfileType]::User,$params.Name,$params.MappingPropertyName)
                    }
                    else
                    {
                        $syncConnection.PropertyMapping.AddNewMapping([Microsoft.Office.Server.UserProfiles.ProfileType]::User,$params.Name,$params.MappingPropertyName)
                    }
                }
            } 
        }       
        #endregion 
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,
        
        [parameter(Mandatory = $true)]
        [System.String]
        $UserProfileService,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $DisplayName,
        
        [parameter(Mandatory = $false)]
        [ValidateSet("BigInteger",
                     "Binary",
                     "Boolean",
                     "Date",
                     "DateNoYear",
                     "DateTime",
                     "Email",
                     "Float",
                     "Guid",
                     "HTML",
                     "Integer",
                     "Person",
                     "String",
                     "StringMultiValue",
                     "TimeZone",
                     "URL")]
        [System.String]
        $Type,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $Description,
        
        [parameter(Mandatory = $false)]
        [ValidateSet("Mandatory", "Optin","Optout", "Disabled")]
        [System.String]
        $PolicySetting,
        
        [parameter(Mandatory = $false)]
        [ValidateSet("Public", "Contacts", "Organization", "Manager", "Private")]
        [System.String] $PrivacySetting ,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $MappingConnectionName,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $MappingPropertyName,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $MappingDirection,
        
        [parameter(Mandatory = $false)]
        [System.Uint32]
        $Length,
        
        [parameter(Mandatory = $false)]
        [System.Uint32]
        $DisplayOrder,
        
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $IsEventLog,
        
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $IsVisibleOnEditor,
        
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $IsVisibleOnViewer,
        
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $IsUserEditable,
        
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $IsAlias,
        
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $IsSearchable,
        
        [parameter(Mandatory = $false)]
        [System.Boolean]
        $UserOverridePrivacy,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $TermStore,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $TermGroup,
        
        [parameter(Mandatory = $false)]
        [System.String]
        $TermSet,
        
        [parameter(Mandatory = $false)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",
        
        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing for user profile property $Name"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters
    if ($Ensure -eq "Present") {
        return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                        -DesiredValues $PSBoundParameters `
                                        -ValuesToCheck @("Name",
                                                         "DisplayName",
                                                         "Type",
                                                         "Description",
                                                         "PolicySetting",
                                                         "PrivacySetting",
                                                         "MappingConnectionName",
                                                         "MappingPropertyName",
                                                         "MappingDirection",
                                                         "Length",
                                                         "DisplayOrder",
                                                         "IsEventLog",
                                                         "IsVisibleOnEditor",
                                                         "IsVisibleOnViewer",
                                                         "IsUserEditable",
                                                         "IsAlias",
                                                         "IsSearchabe",
                                                         "UserOverridePrivacy",
                                                         "TermGroup",
                                                         "TermStore",
                                                         "TermSet",
                                                         "Ensure")
    }
    else
    {
        return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                        -DesiredValues $PSBoundParameters `
                                        -ValuesToCheck @("Ensure")
    }    
}

Export-ModuleMember -Function *-TargetResource
