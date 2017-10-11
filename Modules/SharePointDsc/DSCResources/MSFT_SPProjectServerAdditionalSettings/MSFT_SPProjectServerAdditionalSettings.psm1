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
        [System.String]
        $ProjectProfessionalMinBuilNumber,

        [Parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Getting additional settings for $Url"

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

        $script:ProjectProfessionalMinBuilNumberValue = $null
        Use-SPDscProjectServerWebService -Service $adminService -ScriptBlock {
            $buildInfo = $adminService.GetProjectProfessionalMinimumBuildNumbers().Versions
            $script:ProjectProfessionalMinBuilNumberValue = "$($buildInfo.Major).$($buildInfo.Minor).$($buildInfo.Build).$($buildInfo.Revision)"
        }

        return @{
            Url = $params.Url
            ProjectProfessionalMinBuilNumber = $script:ProjectProfessionalMinBuilNumberValue
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
        [Parameter(Mandatory = $true)]  
        [System.String] 
        $Url,
        
        [Parameter(Mandatory = $false)]  
        [System.String]
        $ProjectProfessionalMinBuilNumber,

        [Parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Setting additional settings for $Url"

    if ((Get-SPDSCInstalledProductVersion).FileMajorPart -lt 16) 
    {
        throw [Exception] ("Support for Project Server in SharePointDsc is only valid for " + `
                           "SharePoint 2016.")
    }

    Invoke-SPDSCCommand -Credential $InstallAccount `
                        -Arguments @($PSBoundParameters, $PSScriptRoot) `
                        -ScriptBlock {
        $params = $args[0]
        $scriptRoot = $args[1]
        
        $modulePath = "..\..\Modules\SharePointDsc.ProjectServer\ProjectServerConnector.psm1"
        Import-Module -Name (Join-Path -Path $scriptRoot -ChildPath $modulePath -Resolve)

        $adminService = New-SPDscProjectServerWebService -PwaUrl $params.Url -EndpointName Admin

        Use-SPDscProjectServerWebService -Service $adminService -ScriptBlock {
            if ($params.ContainsKey("ProjectProfessionalMinBuilNumber") -eq $true)
            {
                $buildInfo = $adminService.GetProjectProfessionalMinimumBuildNumbers()
                $versionInfo = [System.Version]::New($params.ProjectProfessionalMinBuilNumber)
                $buildInfo.Versions.Rows[0]["Major"] = $versionInfo.Major
                $buildInfo.Versions.Rows[0]["Minor"] = $versionInfo.Minor
                $buildInfo.Versions.Rows[0]["Build"] = $versionInfo.Build
                $buildInfo.Versions.Rows[0]["Revision"] = $versionInfo.Revision
                $adminService.SetProjectProfessionalMinimumBuildNumbers($buildInfo)
            }
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
        [System.String]
        $ProjectProfessionalMinBuilNumber,

        [Parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Testing additional settings for $Url"

    $currentValues = Get-TargetResource @PSBoundParameters

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @(
                                        "ProjectProfessionalMinBuilNumber"
                                    )
}

Export-ModuleMember -Function *-TargetResource
