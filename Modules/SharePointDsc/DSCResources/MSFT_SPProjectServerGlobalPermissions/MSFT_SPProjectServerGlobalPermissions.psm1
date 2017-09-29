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
        $EntityName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("User", "Group")]  
        [System.String] 
        $EntityType,

        [Parameter(Mandatory = $false)]
        [System.String[]]
        $AllowPermissions,

        [Parameter(Mandatory = $false)]
        [System.String[]]
        $DenyPermissions,

        [Parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Getting global permissions for $EntityType '$EntityName' at '$Url'"

    if ((Get-SPDSCInstalledProductVersion).FileMajorPart -lt 16) 
    {
        throw [Exception] ("Support for Project Server in SharePointDsc is only valid for " + `
                           "SharePoint 2016.")
    }

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments @($PSBoundParameters, $PSScriptRoot) `
                                  -ScriptBlock {
        $params = $args[0]
        $scriptRoot = $args[1]

        if ((Get-SPProjectPermissionMode -Url $params.Url) -ne "ProjectServer")
        {
            throw [Exception] ("SPProjectServerGlobalPermissions is design for Project Server " + `
                               "permissions mode only, and this site is set to SharePoint mode")
        }
        
        $modulePath = "..\..\Modules\SharePointDsc.ProjectServer\ProjectServerConnector.psm1"
        Import-Module -Name (Join-Path -Path $scriptRoot -ChildPath $modulePath -Resolve)

        $allowPermissions = @()
        $denyPermissions = @()
        $script:resultDataSet = $null

        switch($params.EntityType)
        {
            "User" {
                $resourceService = New-SPDscProjectServerWebService -PwaUrl $params.Url -EndpointName Resource
                
                $userId = Get-SPDscProjectServerResourceId -PwaUrl $params.Url -ResourceName $params.EntityName
                Use-SPDscProjectServerWebService -Service $resourceService -ScriptBlock {
                    $script:resultDataSet = $resourceService.ReadResourceAuthorization($userId)
                }
            }
            "Group" {
                $securityService = New-SPDscProjectServerWebService -PwaUrl $params.Url -EndpointName Security

                Use-SPDscProjectServerWebService -Service $securityService -ScriptBlock {
                    $groupInfo  = $securityService.ReadGroupList().SecurityGroups | Where-Object -FilterScript {
                        $_.WSEC_GRP_NAME -eq $params.EntityName
                    }
                    $script:resultDataSet = $securityService.ReadGroup($groupInfo.WSEC_GRP_UID)
                }
            }
        }

        $script:resultDataSet.GlobalPermissions.Rows | ForEach-Object -Process {
            $permissionName = Get-SPDscProjectServerPermissionName -PermissionId $_.WSEC_FEA_ACT_UID
            if ($_.WSEC_ALLOW -eq $true)
            {
                $allowPermissions += $permissionName
            }
            if ($_.WSEC_DENY -eq $true)
            {
                $denyPermissions += $permissionName
            }
        }

        return @{
            Url = $params.Url
            EntityName = $params.EntityName
            EntityType = $params.EntityType
            AllowPermissions = $allowPermissions
            DenyPermissions = $denyPermissions
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
        $EntityName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("User", "Group")]  
        [System.String] 
        $EntityType,

        [Parameter(Mandatory = $false)]
        [System.String[]]
        $AllowPermissions,

        [Parameter(Mandatory = $false)]
        [System.String[]]
        $DenyPermissions,

        [Parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Setting global permissions for $EntityType '$EntityName' at '$Url'"

      
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
        $EntityName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("User", "Group")]  
        [System.String] 
        $EntityType,

        [Parameter(Mandatory = $false)]
        [System.String[]]
        $AllowPermissions,

        [Parameter(Mandatory = $false)]
        [System.String[]]
        $DenyPermissions,

        [Parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Testing global permissions for $EntityType '$EntityName' at '$Url'"

    $currentValues = Get-TargetResource @PSBoundParameters

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @(
                                        "Name",
                                        "Description",
                                        "ADGroup",
                                        "Ensure"
                                    )
}

Export-ModuleMember -Function *-TargetResource
