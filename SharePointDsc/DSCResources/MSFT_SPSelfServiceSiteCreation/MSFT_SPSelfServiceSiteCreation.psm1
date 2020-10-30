$script:resourceModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:resourceModulePath -ChildPath 'Modules'
$script:resourceHelperModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'SharePointDsc.Util'
Import-Module -Name (Join-Path -Path $script:resourceHelperModulePath -ChildPath 'SharePointDsc.Util.psm1')

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $Enabled,

        [Parameter()]
        [System.Boolean]
        $OnlineEnabled,

        [Parameter()]
        [System.String]
        $QuotaTemplate,

        [Parameter()]
        [System.Boolean]
        $ShowStartASiteMenuItem,

        [Parameter()]
        [System.Boolean]
        $CreateIndividualSite,

        [Parameter()]
        [System.String]
        $ParentSiteUrl,

        [Parameter()]
        [ValidateSet("MustHavePolicy", "CanHavePolicy", "NotHavePolicy")]
        [System.String]
        $PolicyOption,

        [Parameter()]
        [System.Boolean]
        $RequireSecondaryContact,

        [Parameter()]
        [System.String]
        $CustomFormUrl,

        [Parameter()]
        [System.String]
        $ManagedPath,

        [Parameter()]
        [System.String]
        $AlternateUrl,

        [Parameter()]
        [ValidateSet("Modern", "Classic", "Latest")]
        [System.String]
        $UserExperienceVersion,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting self service site creation settings for Web Application '$WebAppUrl'"

    $installedVersion = Get-SPDscInstalledProductVersion
    if ($installedVersion.FileMajorPart -eq 15 -or $installedVersion.FileBuildPart.ToString().Length -eq 4)
    {
        if ($PSBoundParameters.ContainsKey("ManagedPath") -eq $true)
        {
            throw "Parameter ManagedPath is only supported in SharePoint 2019"
        }

        if ($PSBoundParameters.ContainsKey("AlternateUrl") -eq $true)
        {
            throw "Parameter AlternateUrl is only supported in SharePoint 2019"
        }

        if ($PSBoundParameters.ContainsKey("UserExperienceVersion") -eq $true)
        {
            throw "Parameter UserExperienceVersion is only supported in SharePoint 2019"
        }
    }
    else
    {
        if ($PSBoundParameters.ContainsKey("AlternateUrl") -eq $true -and
            $PSBoundParameters.ContainsKey("ManagedPath") -eq $true)
        {
            throw "You cannot specify both AlternateUrl and ManagedPath. Please use just one of these."
        }
    }

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $webApplication = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue

        if ($null -eq $webApplication)
        {
            Write-Verbose "Web application $($params.WebAppUrl) was not found"
            return @{
                WebAppUrl               = $null
                Enabled                 = $null
                OnlineEnabled           = $null
                QuotaTemplate           = $null
                ShowStartASiteMenuItem  = $null
                CreateIndividualSite    = $null
                ParentSiteUrl           = $null
                CustomFormUrl           = $null
                ManagedPath             = $null
                AlternateUrl            = $null
                UserExperienceVersion   = $null
                PolicyOption            = $null
                RequireSecondaryContact = $null
            }
        }

        $policyOption = "NotHavePolicy"
        if ($webApplication.Properties.Contains("PolicyOption"))
        {
            $policyOptionProperty = $webApplication.Properties["PolicyOption"]
            if ($policyOptionProperty -eq "CanHavePolicy" -or $policyOptionProperty -eq "MustHavePolicy")
            {
                $policyOption = $policyOptionProperty
            }
        }

        $userExperienceVersion = $null
        if ($null -ne $webApplication.SiteCreationUserExperienceVersion)
        {
            switch ($webApplication.SiteCreationUserExperienceVersion)
            {
                "Version1"
                { $userExperienceVersion = "Classic"
                }
                "Version2"
                { $userExperienceVersion = "Modern"
                }
                "Latest"
                { $userExperienceVersion = "Latest"
                }
            }
        }

        return @{
            WebAppUrl               = $params.WebAppUrl
            Enabled                 = $webApplication.SelfServiceSiteCreationEnabled
            OnlineEnabled           = $webApplication.SelfServiceSiteCreationOnlineEnabled
            QuotaTemplate           = $webApplication.SelfServiceCreationQuotaTemplate
            ShowStartASiteMenuItem  = $webApplication.ShowStartASiteMenuItem
            CreateIndividualSite    = $webApplication.SelfServiceCreateIndividualSite
            ParentSiteUrl           = $webApplication.SelfServiceCreationParentSiteUrl
            CustomFormUrl           = $webApplication.SelfServiceSiteCustomFormUrl
            ManagedPath             = $webApplication.SelfServiceCreationManagedPath
            AlternateUrl            = $webApplication.SelfServiceCreationAlternateUrl
            UserExperienceVersion   = $userExperienceVersion
            PolicyOption            = $policyOption
            RequireSecondaryContact = $webApplication.RequireContactForSelfServiceSiteCreation
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
        $WebAppUrl,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $Enabled,

        [Parameter()]
        [System.Boolean]
        $OnlineEnabled,

        [Parameter()]
        [System.String]
        $QuotaTemplate,

        [Parameter()]
        [System.Boolean]
        $ShowStartASiteMenuItem,

        [Parameter()]
        [System.Boolean]
        $CreateIndividualSite,

        [Parameter()]
        [System.String]
        $ParentSiteUrl,

        [Parameter()]
        [ValidateSet("MustHavePolicy", "CanHavePolicy", "NotHavePolicy")]
        [System.String]
        $PolicyOption,

        [Parameter()]
        [System.Boolean]
        $RequireSecondaryContact,

        [Parameter()]
        [System.String]
        $CustomFormUrl,

        [Parameter()]
        [System.String]
        $ManagedPath,

        [Parameter()]
        [System.String]
        $AlternateUrl,

        [Parameter()]
        [ValidateSet("Modern", "Classic", "Latest")]
        [System.String]
        $UserExperienceVersion,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting self service site creation settings for Web Application '$WebAppUrl'"

    $installedVersion = Get-SPDscInstalledProductVersion
    if ($installedVersion.FileMajorPart -eq 15 -or $installedVersion.ProductBuildPart.ToString().Length -eq 4)
    {
        if ($PSBoundParameters.ContainsKey("ManagedPath") -eq $true)
        {
            throw "Parameter ManagedPath is only supported in SharePoint 2019"
        }

        if ($PSBoundParameters.ContainsKey("AlternateUrl") -eq $true)
        {
            throw "Parameter AlternateUrl is only supported in SharePoint 2019"
        }

        if ($PSBoundParameters.ContainsKey("UserExperienceVersion") -eq $true)
        {
            throw "Parameter UserExperienceVersion is only supported in SharePoint 2019"
        }
    }
    else
    {
        if ($PSBoundParameters.ContainsKey("AlternateUrl") -eq $true -and `
                $PSBoundParameters.ContainsKey("ManagedPath") -eq $true)
        {
            throw "You cannot specify both AlternateUrl and ManagedPath. Please use just one of these."
        }

        if ($PSBoundParameters.ContainsKey("UserExperienceVersion") -eq $false)
        {
            $PSBoundParameters.UserExperienceVersion = "Modern"
        }
    }

    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        if ($params.ContainsKey("AlternateUrl") -and `
                $params.AlternateUrl.TrimEnd("/") -in (Get-SPWebApplication).Url.TrimEnd("/"))
        {
            throw ("Specified AlternateUrl is unknown as web application URL. " + `
                    "Please specify an existing URL")
        }

        $webApplication = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue

        if ($null -eq $webApplication)
        {
            throw "The specified web application could not be found."
        }

        $webApplicationNeedsUpdate = $false

        if ($params.Enabled -eq $false)
        {
            if ($params.ContainsKey("ShowStartASiteMenuItem"))
            {
                if ($ShowStartASiteMenuItem -eq $true)
                {
                    throw ("It is not allowed to set the ShowStartASiteMenuItem to true when self service site creation is disabled.")
                }
            }
            else
            {
                $params.Add("ShowStartASiteMenuItem", $false)
            }
        }

        if ($params.Enabled -ne $webApplication.SelfServiceSiteCreationEnabled)
        {
            $webApplication.SelfServiceSiteCreationEnabled = $params.Enabled
            $webApplicationNeedsUpdate = $true
        }

        if ($params.ContainsKey("OnlineEnabled") -eq $true)
        {
            if ($params.OnlineEnabled -ne $webApplication.SelfServiceSiteCreationOnlineEnabled)
            {
                $webApplication.SelfServiceSiteCreationOnlineEnabled = $params.OnlineEnabled
                $webApplicationNeedsUpdate = $true
            }
        }

        if ($params.ContainsKey("QuotaTemplate") -eq $true)
        {
            if ($params.QuotaTemplate -ne $webApplication.SelfServiceCreationQuotaTemplate)
            {
                $webApplication.SelfServiceCreationQuotaTemplate = $params.QuotaTemplate
                $webApplicationNeedsUpdate = $true
            }
        }

        if ($params.ContainsKey("ShowStartASiteMenuItem") -eq $true)
        {
            if ($params.ShowStartASiteMenuItem -ne $webApplication.ShowStartASiteMenuItem)
            {
                $webApplication.ShowStartASiteMenuItem = $params.ShowStartASiteMenuItem
                $webApplicationNeedsUpdate = $true
            }
        }

        if ($params.ContainsKey("CreateIndividualSite") -eq $true)
        {
            if ($params.CreateIndividualSite -ne $webApplication.SelfServiceCreateIndividualSite)
            {
                $webApplication.SelfServiceCreateIndividualSite = $params.CreateIndividualSite
                $webApplicationNeedsUpdate = $true
            }
        }

        if ($params.ContainsKey("ParentSiteUrl") -eq $true)
        {
            if ($params.ParentSiteUrl -ne $webApplication.SelfServiceCreationParentSiteUrl)
            {
                $webApplication.SelfServiceCreationParentSiteUrl = $params.ParentSiteUrl
                $webApplicationNeedsUpdate = $true
            }
        }

        if ($params.ContainsKey("CustomFormUrl") -eq $true)
        {
            if ($params.CustomFormUrl -ne $webApplication.SelfServiceSiteCustomFormUrl)
            {
                $webApplication.SelfServiceSiteCustomFormUrl = $params.CustomFormUrl
                $webApplicationNeedsUpdate = $true
            }
        }

        if ($params.ContainsKey("ManagedPath") -eq $true)
        {
            if ($params.ManagedPath -ne $webApplication.SelfServiceCreationManagedPath)
            {
                $webApplication.SelfServiceCreationManagedPath = $params.ManagedPath
                $webApplicationNeedsUpdate = $true
            }
        }

        if ($params.ContainsKey("AlternateUrl") -eq $true)
        {
            if ($params.AlternateUrl -ne $webApplication.SelfServiceCreationAlternateUrl)
            {
                $webApplication.SelfServiceCreationAlternateUrl = $params.AlternateUrl
                $webApplicationNeedsUpdate = $true
            }
        }

        if ($params.ContainsKey("UserExperienceVersion") -eq $true)
        {
            switch ($params.UserExperienceVersion)
            {
                "Modern"
                { $newValue = [Microsoft.SharePoint.Administration.SiteCreationUserExperienceVersion]::Version2
                }
                "Classic"
                { $newValue = [Microsoft.SharePoint.Administration.SiteCreationUserExperienceVersion]::Version1
                }
                "Latest"
                { $newValue = [Microsoft.SharePoint.Administration.SiteCreationUserExperienceVersion]::Latest
                }
            }

            if ($newValue -ne $webApplication.SiteCreationUserExperienceVersion)
            {
                $webApplication.SiteCreationUserExperienceVersion = $newValue
                $webApplicationNeedsUpdate = $true
            }
        }

        if ($params.ContainsKey("PolicyOption") -eq $true)
        {
            if ($params.PolicyOption -ne $webApplication.Properties["PolicyOption"])
            {
                $webApplication.Properties["PolicyOption"] = $params.PolicyOption
                $webApplicationNeedsUpdate = $true
            }
        }

        if ($params.ContainsKey("RequireSecondaryContact") -eq $true)
        {
            if ($params.RequireSecondaryContact -ne $webApplication.RequireContactForSelfServiceSiteCreation)
            {
                $webApplication.RequireContactForSelfServiceSiteCreation = $params.RequireSecondaryContact
                $webApplicationNeedsUpdate = $true
            }
        }

        if ($webApplicationNeedsUpdate -eq $true)
        {
            Write-Verbose -Message "Updating web application"
            $webApplication.Update()
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
        $WebAppUrl,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $Enabled,

        [Parameter()]
        [System.Boolean]
        $OnlineEnabled,

        [Parameter()]
        [System.String]
        $QuotaTemplate,

        [Parameter()]
        [System.Boolean]
        $ShowStartASiteMenuItem,

        [Parameter()]
        [System.Boolean]
        $CreateIndividualSite,

        [Parameter()]
        [System.String]
        $ParentSiteUrl,

        [Parameter()]
        [ValidateSet("MustHavePolicy", "CanHavePolicy", "NotHavePolicy")]
        [System.String]
        $PolicyOption,

        [Parameter()]
        [System.Boolean]
        $RequireSecondaryContact,

        [Parameter()]
        [System.String]
        $CustomFormUrl,

        [Parameter()]
        [System.String]
        $ManagedPath,

        [Parameter()]
        [System.String]
        $AlternateUrl,

        [Parameter()]
        [ValidateSet("Modern", "Classic", "Latest")]
        [System.String]
        $UserExperienceVersion,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing self service site creation settings for Web Application '$WebAppUrl'"

    if ($Enabled -eq $false)
    {
        if ($PSBoundParameters.ContainsKey("ShowStartASiteMenuItem") -eq $true)
        {
            if ($ShowStartASiteMenuItem -eq $true)
            {
                throw ("It is not allowed to set the ShowStartASiteMenuItem to true when self service site creation is disabled.")
            }
        }
        else
        {
            $PSBoundParameters.Add("ShowStartASiteMenuItem", $false)
        }
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($Enabled)
    {
        $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("WebAppUrl", `
                "Enabled", `
                "OnlineEnabled", `
                "ShowStartASiteMenuItem", `
                "CreateIndividualSite", `
                "ParentSiteUrl", `
                "CustomFormUrl", `
                "ManagedPath", `
                "AlternateUrl", `
                "UserExperienceVersion", `
                "PolicyOption", `
                "RequireSecondaryContact")
    }
    else
    {
        $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("WebAppUrl", `
                "Enabled", `
                "ShowStartASiteMenuItem")
    }

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}
