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
        [parameter(Mandatory = $false)] [System.uint32] $DisplayOrder ,
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
        $properties = $userProfileConfigManager.GetPropertiesWithSection()
        
        $userProfileProperty = $properties.GetSectionByName($params.Name) 
        if($userProfileProperty -eq $null){
            return $null 
        }
        return @{
            Name = $userProfileProperty.Name 
            UserProfileService = $params.UserProfileService
            DisplayName = $userProfileProperty.DisplayName
            DisplayOrder =$userProfileProperty.DisplayOrder 
            Ensure = $params.Ensure
        }

    }
    return $result
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)] [System.string] $Name,
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] [System.string] $Ensure,
        [parameter(Mandatory = $true)] [System.string] $UserProfileService,
        [parameter(Mandatory = $false)] [System.string] $DisplayName,
        [parameter(Mandatory = $false)] [System.uint32] $DisplayOrder,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    # note for integration test: CA can take a couple of minutes to notice the change. 
    # don't try refreshing properties page. go through from a fresh "flow" from Service apps page :)

    Write-Verbose -Message "Creating user profile property $Name"
    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
            $ups = Get-SPServiceApplication -Name $params.UserProfileService -ErrorAction SilentlyContinue 
 
        If ($null -eq $ups)
        {
               throw "service application $( $params.UserProfileService) not found"
        }
        
        $caURL = (Get-SpWebApplication  -IncludeCentralAdministration | ?{$_.IsAdministrationWebApplication -eq $true }).Url
        $context = Get-SPServiceContext  $caURL 

        $userProfileConfigManager = new-object Microsoft.Office.Server.UserProfiles.UserProfileConfigManager($context)
        if($null -eq $userProfileConfigManager)
        {   #if config manager returns null when ups is available then isuee is permissions
            throw "account running process needs admin permission on user profile service application"
        }
        $properties = $userProfileConfigManager.GetPropertiesWithSection()
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
        [parameter(Mandatory = $false)] [System.uint32] $DisplayOrder ,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount

    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing for user profile property $Name"
    if ($null -eq $CurrentValues) { return $false  }
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("Name","DisplayName", "DisplayOrder")
}

Export-ModuleMember -Function *-TargetResource



