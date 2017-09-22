function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]  
        [System.String] 
        $Url,

        [Parameter(Mandatory = $true)]  
        [System.String] 
        $Name,

        [Parameter(Mandatory = $false)]  
        [System.String] 
        $Description,

        [Parameter(Mandatory = $false)]  
        [System.String]
        $ADGroup,

        [Parameter(Mandatory = $false)]
        [System.String[]]
        $Members,

        [Parameter(Mandatory = $false)]
        [System.String[]]
        $MembersToInclude,

        [Parameter(Mandatory = $false)]
        [System.String[]]
        $MembersToExclude,

        [Parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Getting group settings for '$Name' at '$Url'"

    if ((Get-SPDSCInstalledProductVersion).FileMajorPart -lt 16) 
    {
        throw [Exception] ("Support for Project Server in SharePointDsc is only valid for " + `
                           "SharePoint 2016.")
    }

    if ($PSBoundParameters.ContainsKey("ADGroup") -eq $true -and `
        ($PSBoundParameters.ContainsKey("Members") -eq $true -or `
         $PSBoundParameters.ContainsKey("MembersToInclude") -eq $true -or `
         $PSBoundParameters.ContainsKey("MembersToExclude") -eq $true))
    {
        throw ("Property ADGroup can not be used at the same time as Members, " + `
               "MembersToInclude or MembersToExclude")
    }

    if ($PSBoundParameters.ContainsKey("Members") -eq $true -and `
        ($PSBoundParameters.ContainsKey("MembersToInclude") -eq $true -or `
         $PSBoundParameters.ContainsKey("MembersToExclude") -eq $true))
    {
        throw ("Property Members can not be used at the same time as " + `
               "MembersToInclude or MembersToExclude")
    }

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments @($PSBoundParameters, $PSScriptRoot) `
                                  -ScriptBlock {
        $params = $args[0]
        $scriptRoot = $args[1]

        if ((Get-SPProjectPermissionMode -Url $params.Url) -ne "ProjectServer")
        {
            throw [Exception] ("SPProjectServerGroup is design for Project Server permissions " + `
                               "mode only, and this site is set to SharePoint mode")
        }
        
        $modulePath = "..\..\Modules\SharePointDsc.ProjectServer\ProjectServerConnector.psm1"
        Import-Module -Name (Join-Path -Path $scriptRoot -ChildPath $modulePath -Resolve)

        $securityService = New-SPDscProjectServerWebService -PwaUrl $params.Url -EndpointName Security

        $script:groupDataSet = $null
        Use-SPDscProjectServerWebService -Service $securityService -ScriptBlock {
            $groupInfo  = $securityService.ReadGroupList().SecurityGroups | Where-Object -FilterScript {
                $_.WSEC_GRP_NAME -eq $params.Name
            }

            if ($null -ne $groupInfo)
            {
                $script:groupDataSet = $securityService.ReadGroup($groupInfo.WSEC_GRP_UID)
            }
        }

        if ($null -eq $script:groupDataSet)
        {
            return @{
                Url = $params.Url
                Name = ""
                Description = ""
                ADGroup = ""
                Members = $null
                MembersToInclude = $null
                MembersToExclude = $null
                InstallAccount = $params.InstallAccount
            }
        }
        else
        {
            $adGroup = ""
            if ($script:groupDataSet.SecurityGroups.WSEC_GRP_AD_GUID.GetType() -ne [System.DBNull])
            {
                $adGroup = Convert-SPDscADGroupIDToName -GroupId $script:groupDataSet.SecurityGroups.WSEC_GRP_AD_GUID
            }

            if ($adGroup -eq "")
            {
                # No AD group is set, check for individual members
                $resourceService = New-SPDscProjectServerWebService -PwaUrl $params.Url -EndpointName Resource

                $script:groupMembers = @()
                Use-SPDscProjectServerWebService -Service $resourceService -ScriptBlock {
                    $script:groupDataSet.GroupMembers.RES_UID | ForEach-Object -Process {
                        $userName = $resourceService.ReadResource($_).Resources.WRES_ACCOUNT

                        if ($userName.Contains(":0") -eq $true)
                        {
                            $realUserName = New-SPClaimsPrincipal -Identity $userName `
                                                                  -IdentityType EncodedClaim
                            $script:groupMembers += $realUserName.Value
                        }
                        else 
                        {
                            $script:groupMembers += $userName
                        }
                    }
                }
            }

            return @{
                Url = $params.Url
                Name = $script:groupDataSet.SecurityGroups.WSEC_GRP_NAME
                Description = $script:groupDataSet.SecurityGroups.WSEC_GRP_DESC
                ADGroup = $adGroup
                Members = $script:groupMembers
                MembersToInclude = $null
                MembersToExclude = $null
                InstallAccount = $params.InstallAccount
            }
        }
    }
    return $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]  
        [System.String] 
        $Url,

        [Parameter(Mandatory = $true)]  
        [System.String] 
        $Name,

        [Parameter(Mandatory = $false)]  
        [System.String] 
        $Description,

        [Parameter(Mandatory = $false)]  
        [System.String]
        $ADGroup,

        [Parameter(Mandatory = $false)]
        [System.String[]]
        $Members,

        [Parameter(Mandatory = $false)]
        [System.String[]]
        $MembersToInclude,

        [Parameter(Mandatory = $false)]
        [System.String[]]
        $MembersToExclude,

        [Parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Setting group settings for '$Name' at '$Url'"

    $currentSettings = Get-TargetResource @PSBoundParameters

    Invoke-SPDSCCommand -Credential $InstallAccount `
                        -Arguments @($PSBoundParameters, $PSScriptRoot) `
                        -ScriptBlock {

        $params = $args[0]
        $scriptRoot = $args[1]

        $modulePath = "..\..\Modules\SharePointDsc.ProjectServer\ProjectServerConnector.psm1"
        Import-Module -Name (Join-Path -Path $scriptRoot -ChildPath $modulePath -Resolve)

        $securityService = New-SPDscProjectServerWebService -PwaUrl $params.Url -EndpointName Security

        Use-SPDscProjectServerWebService -Service $securityService -ScriptBlock {
            $groupInfo  = $securityService.ReadGroupList().SecurityGroups | Where-Object -FilterScript {
                $_.WSEC_GRP_NAME -eq $params.Name
            }

            if ($null -eq $groupInfo)
            {
                # Create a new group with jsut a name so it can be updated with the properties later
                $newGroupDS = [SvcSecurity.SecurityGroupsDataSet]::new()
                $newGroup = $newGroupDS.SecurityGroups.NewSecurityGroupsRow()
                $newGroup.WSEC_GRP_NAME = $params.Name
                $newGroup.WSEC_GRP_UID = New-Guid
                $newGroupDS.SecurityGroups.AddSecurityGroupsRow($newGroup)
                $securityService.CreateGroups($newGroupDS)

                $groupInfo  = $securityService.ReadGroupList().SecurityGroups | Where-Object -FilterScript {
                    $_.WSEC_GRP_NAME -eq $params.Name
                }
            }
            
            # Update the existing group
            $groupDS = $securityService.ReadGroup($groupInfo.WSEC_GRP_UID)
            $group = $groupDS.SecurityGroups.FindByWSEC_GRP_UID($groupInfo.WSEC_GRP_UID)

            $group.WSEC_GRP_NAME = $params.Name
            if ($params.ContainsKey("Description") -eq $true)
            {
                $group.WSEC_GRP_DESC = $params.Description
            }
            if ($params.ContainsKey("ADGroup") -eq $true)
            {
                $group.WSEC_GRP_AD_GUID = (Convert-SPDscADGroupNameToID -GroupName $params.ADGroup)
                $group.WSEC_GRP_AD_GROUP = $params.ADGroup.Split('\')[1]
            }

            $securityService.SetGroups($groupDS)
        }
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]  
        [System.String] 
        $Url,

        [Parameter(Mandatory = $true)]  
        [System.String] 
        $Name,

        [Parameter(Mandatory = $false)]  
        [System.String] 
        $Description,

        [Parameter(Mandatory = $false)]  
        [System.String]
        $ADGroup,

        [Parameter(Mandatory = $false)]
        [System.String[]]
        $Members,

        [Parameter(Mandatory = $false)]
        [System.String[]]
        $MembersToInclude,

        [Parameter(Mandatory = $false)]
        [System.String[]]
        $MembersToExclude,

        [Parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Testing group settings for '$Name' at '$Url'"

    $currentValues = Get-TargetResource @PSBoundParameters

    if ($PSBoundParameters.ContainsKey("Members") -eq $true)
    {
        $membersMatch = Test-SPDscParameterState -CurrentValues $CurrentValues `
                                                 -DesiredValues $PSBoundParameters `
                                                 -ValuesToCheck @("Members")
        if ($membersMatch -eq $false)
        {
            return $false
        }
    }

    if ($PSBoundParameters.ContainsKey("MembersToInclude") -eq $true)
    {
        $missingMembers = $false
        $MembersToInclude | ForEach-Object -Process {
            if ($currentValues.Members -notcontains $_)
            {
                Write-Verbose -Message "'$_' is not in the members list, but should be"
                $missingMembers = $true
            }
        }
        if ($missingMembers -eq $true)
        {
            Write-Verbose -Message "Users from the MembersToInclude property are not included, returning false"
            return $false
        }
    }

    if ($PSBoundParameters.ContainsKey("MembersToExclude") -eq $true)
    {
        $extraMembers = $false
        $MembersToExclude | ForEach-Object -Process {
            if ($currentValues.Members -contains $_)
            {
                Write-Verbose -Message "'$_' is in the members list, but should not be"
                $extraMembers = $true
            }
        }
        if ($extraMembers -eq $true)
        {
            Write-Verbose -Message "Users from the MembersToExclude property are included, returning false"
            return $false
        }
    }

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @(
                                        "Name",
                                        "Description",
                                        "ADGroup"
                                    )
}

Export-ModuleMember -Function *-TargetResource
