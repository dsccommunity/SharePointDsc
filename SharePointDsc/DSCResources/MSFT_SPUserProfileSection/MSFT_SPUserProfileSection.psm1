function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.string]
        $Name,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter(Mandatory = $true)]
        [System.string]
        $UserProfileService,

        [Parameter()]
        [System.string]
        $DisplayName,

        [Parameter()]
        [System.uint32]
        $DisplayOrder,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting user profile section $Name"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $upsa = Get-SPServiceApplication -Name $params.UserProfileService `
            -ErrorAction SilentlyContinue
        $nullReturn = @{
            Name               = $params.Name
            Ensure             = "Absent"
            UserProfileService = $params.UserProfileService
        }

        if ($null -eq $upsa)
        {
            return $nullReturn
        }

        $caURL = (Get-SpWebApplication -IncludeCentralAdministration | Where-Object -FilterScript {
                $_.IsAdministrationWebApplication -eq $true
            }).Url
        $context = Get-SPServiceContext -Site $caURL
        $userProfileConfigManager = New-Object -TypeName "Microsoft.Office.Server.UserProfiles.UserProfileConfigManager" `
            -ArgumentList $context
        $properties = $userProfileConfigManager.GetPropertiesWithSection()

        $userProfileProperty = $properties.GetSectionByName($params.Name)
        if ($null -eq $userProfileProperty)
        {
            return $nullReturn
        }

        return @{
            Name               = $userProfileProperty.Name
            UserProfileService = $params.UserProfileService
            DisplayName        = $userProfileProperty.DisplayName
            DisplayOrder       = $userProfileProperty.DisplayOrder
            Ensure             = "Present"
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
        [System.string]
        $Name,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter(Mandatory = $true)]
        [System.string]
        $UserProfileService,

        [Parameter()]
        [System.string]
        $DisplayName,

        [Parameter()]
        [System.uint32]
        $DisplayOrder,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    # note for integration test: CA can take a couple of minutes to notice the change.
    # don't try refreshing properties page. go through from a fresh "flow" from Service apps page
    Write-Verbose -Message "Setting user profile section $Name"

    $PSBoundParameters.Ensure = $Ensure

    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]

        $ups = Get-SPServiceApplication -Name $params.UserProfileService `
            -ErrorAction SilentlyContinue

        if ($null -eq $ups)
        {
            $message = "Service application $($params.UserProfileService) not found"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }

        $caURL = (Get-SpWebApplication  -IncludeCentralAdministration | Where-Object -FilterScript {
                $_.IsAdministrationWebApplication -eq $true
            }).Url
        $context = Get-SPServiceContext  $caURL

        $userProfileConfigManager = New-Object -TypeName "Microsoft.Office.Server.UserProfiles.UserProfileConfigManager" `
            -ArgumentList $context

        if ($null -eq $userProfileConfigManager)
        {
            #if config manager returns null when ups is available then isuee is permissions
            $message = "Account running process needs admin permission on user profile service application"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }
        $properties = $userProfileConfigManager.GetPropertiesWithSection()
        $userProfileProperty = $properties.GetSectionByName($params.Name)

        if ($params.ContainsKey("Ensure") -and $params.Ensure -eq "Absent")
        {
            if ($null -ne $userProfileProperty)
            {
                $properties.RemoveSectionByName($params.Name)
            }
            return
        }
        elseif ($null -eq $userProfileProperty)
        {
            $coreProperty = $properties.Create($true)
            $coreProperty.Name = $params.Name
            $coreProperty.DisplayName = $params.DisplayName
            $coreProperty.Commit()
        }
        else
        {
            Set-SPDscObjectPropertyIfValuePresent -ObjectToSet $userProfileProperty `
                -PropertyToSet "DisplayName" `
                -ParamsValue $params `
                -ParamKey "DisplayName"
            $userProfileProperty.Commit()
        }

        #region display order
        if ($params.ContainsKey("DisplayOrder"))
        {
            $properties = $userProfileConfigManager.GetPropertiesWithSection()
            $properties.SetDisplayOrderBySectionName($params.Name, $params.DisplayOrder)
            $properties.CommitDisplayOrder()
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
        [System.string]
        $Name,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter(Mandatory = $true)]
        [System.string]
        $UserProfileService,

        [Parameter()]
        [System.string]
        $DisplayName,

        [Parameter()]
        [System.uint32]
        $DisplayOrder,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount

    )

    Write-Verbose -Message "Testing user profile section $Name"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($Ensure -eq "Present")
    {
        $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("Name",
            "DisplayName",
            "DisplayOrder",
            "Ensure")
    }
    else
    {
        $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("Ensure")
    }

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}


function Export-TargetResource
{
    if (!(Get-PSSnapin Microsoft.SharePoint.Powershell -ErrorAction SilentlyContinue))
    {
        Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction 0
    }
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDSC" | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPUserProfileSection\MSFT_SPUserProfileSection.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module
    $caURL = (Get-SpWebApplication -IncludeCentralAdministration | Where-Object -FilterScript { $_.IsAdministrationWebApplication -eq $true }).Url
    $context = Get-SPServiceContext -Site $caURL
    try
    {
        $userProfileConfigManager = New-Object -TypeName "Microsoft.Office.Server.UserProfiles.UserProfileConfigManager" `
            -ArgumentList $context
        $properties = $userProfileConfigManager.GetPropertiesWithSection()
        $sections = $properties | Where-Object { $_.IsSection -eq $true }

        $userProfileServiceApp = Get-SPServiceApplication | Where-Object { $_.GetType().Name -eq "UserProfileApplication" }

        foreach ($section in $sections)
        {
            try
            {
                $params.Name = $section.Name
                $params.UserProfileService = $userProfileServiceApp[0].DisplayName
                $PartialContent = "        SPUserProfileSection " + [System.Guid]::NewGuid().ToString() + "`r`n"
                $PartialContent += "        {`r`n"
                $results = Get-TargetResource @params

                $results = Repair-Credentials -results $results
                $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
                $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
                $PartialContent += $currentBlock
                $PartialContent += "        }`r`n"
                $Content += $PartialContent
            }
            catch
            {
                $Global:ErrorLog += "[User Profile Section]" + $section.Name + "`r`n"
                $Global:ErrorLog += "$_`r`n`r`n"
            }
        }
    }
    catch
    {
    }
    return $Content
}


Export-ModuleMember -Function *-TargetResource

