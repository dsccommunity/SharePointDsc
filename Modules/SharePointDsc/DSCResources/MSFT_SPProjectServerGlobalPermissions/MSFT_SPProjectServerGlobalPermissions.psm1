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
        [ValidateSet("USer", "Group")]  
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
            throw [Exception] ("SPProjectServerGroup is design for Project Server permissions " + `
                               "mode only, and this site is set to SharePoint mode")
        }
        
        $modulePath = "..\..\Modules\SharePointDsc.ProjectServer\ProjectServerConnector.psm1"
        Import-Module -Name (Join-Path -Path $scriptRoot -ChildPath $modulePath -Resolve)

        $securityService = New-SPDscProjectServerWebService -PwaUrl $params.Url -EndpointName Security

        $script:groupDataSet = $null
        Use-SPDscProjectServerWebService -Service $securityService -ScriptBlock {
            
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
        [ValidateSet("USer", "Group")]  
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
        [ValidateSet("USer", "Group")]  
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
