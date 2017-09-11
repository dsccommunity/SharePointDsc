function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]  
        [System.String] 
        $Url,
        
        [Parameter(Mandatory = $false)]  
        [System.String[]] 
        $GroupNames,

        [Parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present",

        [Parameter(Mandatory = $false)]  
        [System.Boolean] 
        $AutoReactivateUsers = $false,

        [Parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Getting AD Resource Pool Sync settings for $Url"

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
        
        $modulePath = "..\..\Modules\SharePointDsc.ProjectServer\ProjectServerConnector.psm1"
        Import-Module -Name (Join-Path -Path $scriptRoot -ChildPath $modulePath -Resolve)

        $adminService = New-SPDscProjectServerWebService -PwaUrl $params.Url -EndpointName Admin

        $script:currentSettings = $null
        $script:reactivateUsers = $false
        Use-SPDscProjectServerWebService -Service $adminService -ScriptBlock {
            $script:currentSettings = $adminService.GetActiveDirectorySyncEnterpriseResourcePoolSettings2()
            $secondSettings = $adminService.GetActiveDirectorySyncEnterpriseResourcePoolSettings()
            $script:reactivateUsers = $secondSettings.AutoReactivateInactiveUsers
        }

        if ($null -eq $script:currentSettings)
        {
            return @{
                Url = $params.Url
                GroupNames = @()
                Ensure = "Absent"
                AutoReactivateUsers = $false
                InstallAccount = $params.InstallAccount
            }
        }
        else
        {
            if ($null -eq $script:currentSettings.ADGroupGuids -or $script:currentSettings.ADGroupGuids.Length -lt 1)
            {
                return @{
                    Url = $params.Url
                    GroupNames = @()
                    Ensure = "Absent"
                    AutoReactivateUsers = $script:reactivateUsers
                    InstallAccount = $params.InstallAccount
                }
            }
            else 
            {
                $adGroups = @()
                $script:currentSettings.ADGroupGuids | ForEach-Object -Process {
                    $guid = $_
                    $bytes = $guid.ToByteArray()
                    $queryGuid = ""
                    $bytes | ForEach-Object -Process { 
                        $queryGuid += "\" + $_.ToString("x2") 
                    }
                    
                    $domain = New-Object -TypeName "System.DirectoryServices.DirectoryEntry"
                    $search = New-Object -TypeName "System.DirectoryServices.DirectorySearcher"
                    $search.SearchRoot = $domain
                    $search.PageSize = 1
                    $search.Filter = "(&(objectGuid=$queryGuid))"
                    $search.SearchScope = "Subtree"
                    $search.PropertiesToLoad.Add("name") | Out-Null
                    $result = $search.FindOne() 

                    if ($null -ne $result)
                    {
                        $sid = New-Object -TypeName "System.Security.Principal.SecurityIdentifier" `
                                          -ArgumentList @($result.GetDirectoryEntry().objectsid[0], 0)

                        $adGroups += $sid.Translate([System.Security.Principal.NTAccount]).ToString()
                    }
                    else 
                    {
                        $adGroups += $guid.ToString()
                    }
                }

                return @{
                    Url = $params.Url
                    GroupNames = $adGroups
                    Ensure = "Present"
                    AutoReactivateUsers = $script:reactivateUsers
                    InstallAccount = $params.InstallAccount
                }
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
        
        [Parameter(Mandatory = $false)]  
        [System.String[]] 
        $GroupNames,

        [Parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present",

        [Parameter(Mandatory = $false)]  
        [System.Boolean] 
        $AutoReactivateUsers = $false,

        [Parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Setting AD Resource Pool Sync settings for $Url"

    if ((Get-SPDSCInstalledProductVersion).FileMajorPart -lt 16) 
    {
        throw [Exception] ("Support for Project Server in SharePointDsc is only valid for " + `
                           "SharePoint 2016.")
    }

    if ($Ensure -eq "Present")
    {
        Invoke-SPDSCCommand -Credential $InstallAccount `
                            -Arguments $PSBoundParameters `
                            -ScriptBlock {

            $params = $args[0]

            $groupIDs = New-Object -TypeName "System.Collections.Generic.List[System.Guid]"

            $params.GroupNames | ForEach-Object -Process {
                $groupName = $_
                $groupNTaccount = New-Object -TypeName "System.Security.Principal.NTAccount" `
                                             -ArgumentList $groupName
                $groupSid = $groupNTaccount.Translate([System.Security.Principal.SecurityIdentifier])

                $result = New-Object -TypeName "System.DirectoryServices.DirectoryEntry" `
                                     -ArgumentList "LDAP://<SID=$($groupSid.ToString())>"
                $groupIDs.Add(([Guid]::new($result.objectGUID.Value)))
            }
            
            Enable-SPProjectActiveDirectoryEnterpriseResourcePoolSync -Url $params.Url `
                                                                      -GroupUids $groupIDs.ToArray()

            if ($params.ContainsKey("AutoReactivateUsers") -eq $true)
            {
                $adminService = New-SPDscProjectServerWebService -PwaUrl $params.Url -EndpointName Admin

                Use-SPDscProjectServerWebService -Service $adminService -ScriptBlock {
                    $settings = $adminService.GetActiveDirectorySyncEnterpriseResourcePoolSettings()
                    $settings.AutoReactivateInactiveUsers  = $params.AutoReactivateUsers
                    $adminService.SetActiveDirectorySyncEnterpriseResourcePoolSettings($settings)
                }
            }
        }
    }
    else
    {
        Invoke-SPDSCCommand -Credential $InstallAccount `
                            -Arguments $PSBoundParameters `
                            -ScriptBlock {

            $params = $args[0]

            Disable-SPProjectActiveDirectoryEnterpriseResourcePoolSync -Url $params.Url
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
        
        [Parameter(Mandatory = $false)]  
        [System.String[]] 
        $GroupNames,

        [Parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present",

        [Parameter(Mandatory = $false)]  
        [System.Boolean] 
        $AutoReactivateUsers = $false,

        [Parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Testing AD Resource Pool Sync settings for $Url"

    $currentValues = Get-TargetResource @PSBoundParameters

    $PSBoundParameters.Ensure = $Ensure

    $paramsToCheck = @("Ensure")
    
    if ($Ensure -eq "Present")
    {
        $paramsToCheck += "GroupNames"
        if ($PSBoundParameters.ContainsKey("AutoReactivateUsers") -eq $true)
        {
            $paramsToCheck += "AutoReactivateUsers"
        }
    }

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck $paramsToCheck
}

Export-ModuleMember -Function *-TargetResource
