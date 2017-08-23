function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  
        [System.String] 
        $Url,
        
        [parameter(Mandatory = $false)]  
        [System.String[]] 
        $GroupNames,

        [parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present",

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Getting license status for Project Server"

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
        Use-SPDscProjectServerWebService -Service $adminService -ScriptBlock {
            $script:currentSettings = $adminService.GetActiveDirectorySyncEnterpriseResourcePoolSettings2()
        }

        if ($null -eq $script:currentSettings)
        {
            return @{
                Url = $params.Url
                GroupNames = @()
                Ensure = "Absent"
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
        [parameter(Mandatory = $true)]  
        [System.String] 
        $Url,
        
        [parameter(Mandatory = $false)]  
        [System.String[]] 
        $GroupNames,

        [parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present",

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Setting Project Server License status"

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
        [parameter(Mandatory = $true)]  
        [System.String] 
        $Url,
        
        [parameter(Mandatory = $false)]  
        [System.String[]] 
        $GroupNames,

        [parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present",

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Testing Project Server License status"

    $currentValues = Get-TargetResource @PSBoundParameters

    $PSBoundParameters.Ensure = $Ensure
    
    if ($Ensure -eq "Present")
    {
        return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                        -DesiredValues $PSBoundParameters `
                                        -ValuesToCheck @("Ensure", "GroupNames")
    }
    else 
    {
        return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                        -DesiredValues $PSBoundParameters `
                                        -ValuesToCheck @("Ensure")
    }
}

Export-ModuleMember -Function *-TargetResource
