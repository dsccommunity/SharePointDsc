function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $WebAppUrl,
        [parameter(Mandatory = $false)] [ValidateSet("Manage Lists","Override List Behaviors", "Add Items","Edit Items","Delete Items","View Items","Approve Items","Open Items","View Versions","Delete Versions","Create Alerts","View Application Pages")] [System.String[]] $ListPermissions,
        [parameter(Mandatory = $false)] [ValidateSet("Manage Permissions","View Web Analytics Data","Create Subsites","Manage Web Site","Add and Customize Pages","Apply Themes and Borders","Apply Style Sheets","Create Groups","Browse Directories","Use Self-Service Site Creation","View Pages","Enumerate Permission","Browse User Information","Manage Alerts","Use Remote Interfaces","Use Client Integration Features","Open","Edit Personal User Information")] [System.String[]] $SitePermissions,
        [parameter(Mandatory = $false)] [ValidateSet("Manage Personal Views","Add/Remove Personal Web Parts","Update Personal Web Parts")] [System.String[]] $PersonalPermissions,
        [parameter(Mandatory = $false)] [System.Boolean] $AllPermissions,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Getting permissions for Web Application '$WebAppUrl'"

    if ($AllPermissions) {
        # AllPermissions parameter specified with and one of the other parameters 
        if ($ListPermissions -or $SitePermissions -or $PersonalPermissions) {
            Throw "Do not specify parameters ListPermissions, SitePermissions or PersonalPermissions when specifying parameter AllPermissions"
        }
    } else {
        # You have to specify all three parameters 
        if (-not ($ListPermissions -and $SitePermissions -and $PersonalPermissions)) {
            Throw "One of the parameters ListPermissions, SitePermissions or PersonalPermissions is missing"
        }
    }

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $wa = Get-SPWebApplication $params.WebAppUrl -ErrorAction SilentlyContinue
        
        if ($null -eq $wa) { throw "The specified web application could not be found." }

        if ($wa.RightsMask -eq [Microsoft.SharePoint.SPBasePermissions]::FullMask) {
            $returnval = @{
                WebAppUrl = "url"
                AllPermissions = $true
            }
        } else {
            $ListPermissions     = @()
            $SitePermissions     = @()
            $PersonalPermissions = @()

            $rightsmask = ($wa.RightsMask -split ",").trim()
            foreach ($rightmask in $rightsmask) {
                switch ($rightmask) {
                    "ManageLists"     { $ListPermissions += "Manage Lists" }
                    "CancelCheckout"  { $ListPermissions += "Override List Behaviors" }
                    "AddListItems"    { $ListPermissions += "Add Items" }
                    "EditListItems"   { $ListPermissions += "Edit Items" }
                    "DeleteListItems" { $ListPermissions += "Delete Items" }
                    "ViewListItems"   { $ListPermissions += "View Items" }
                    "ApproveItems"    { $ListPermissions += "Approve Items" }
                    "OpenItems"       { $ListPermissions += "Open Items" }
                    "ViewVersions"    { $ListPermissions += "View Versions" }
                    "DeleteVersions"  { $ListPermissions += "Delete Versions" }
                    "CreateAlerts"    { $ListPermissions += "Create Alerts" }
                    "ViewFormPages"   { $ListPermissions += "View Application Pages" }

                    "ManagePermissions"    { $SitePermissions += "Manage Permissions" }
                    "ViewUsageData"        { $SitePermissions += "View Web Analytics Data" }
                    "ManageSubwebs"        { $SitePermissions += "Create Subsites" }
                    "ManageWeb"            { $SitePermissions += "Manage Web Site" }
                    "AddAndCustomizePages" { $SitePermissions += "Add and Customize Pages" }
                    "ApplyThemeAndBorder"  { $SitePermissions += "Apply Themes and Borders" }
                    "ApplyStyleSheets"     { $SitePermissions += "Apply Style Sheets" }
                    "CreateGroups"         { $SitePermissions += "Create Groups" }
                    "BrowseDirectories"    { $SitePermissions += "Browse Directories" }
                    "CreateSSCSite"        { $SitePermissions += "Use Self-Service Site Creation" }
                    "ViewPages"            { $SitePermissions += "View Pages" }
                    "EnumeratePermissions" { $SitePermissions += "Enumerate Permission" }
                    "BrowseUserInfo"       { $SitePermissions += "Browse User Information" }
                    "ManageAlerts"         { $SitePermissions += "Manage Alerts" }
                    "UseRemoteAPIs"        { $SitePermissions += "Use Remote Interfaces" }
                    "UseClientIntegration" { $SitePermissions += "Use Client Integration Features" }
                    "Open"                 { $SitePermissions += "Open" }
                    "EditMyUserInfo"       { $SitePermissions += "Edit Personal User Information" }

                    "ManagePersonalViews"    { $PersonalPermissions += "Manage Personal Views" }
                    "AddDelPrivateWebParts"  { $PersonalPermissions += "Add/Remove Personal Web Parts" }
                    "UpdatePersonalWebParts" { $PersonalPermissions += "Update Personal Web Parts" }
                }
            }

            $returnval = @{
                WebAppUrl = $params.WebAppUrl
                ListPermissions     = $ListPermissions
                SitePermissions     = $SitePermissions
                PersonalPermissions = $PersonalPermissions
            }
        }
        return $returnval
    }
    return $result
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $WebAppUrl,
        [parameter(Mandatory = $false)] [ValidateSet("Manage Lists","Override List Behaviors", "Add Items","Edit Items","Delete Items","View Items","Approve Items","Open Items","View Versions","Delete Versions","Create Alerts","View Application Pages")] [System.String[]] $ListPermissions,
        [parameter(Mandatory = $false)] [ValidateSet("Manage Permissions","View Web Analytics Data","Create Subsites","Manage Web Site","Add and Customize Pages","Apply Themes and Borders","Apply Style Sheets","Create Groups","Browse Directories","Use Self-Service Site Creation","View Pages","Enumerate Permission","Browse User Information","Manage Alerts","Use Remote Interfaces","Use Client Integration Features","Open","Edit Personal User Information")] [System.String[]] $SitePermissions,
        [parameter(Mandatory = $false)] [ValidateSet("Manage Personal Views","Add/Remove Personal Web Parts","Update Personal Web Parts")] [System.String[]] $PersonalPermissions,
        [parameter(Mandatory = $false)] [System.Boolean] $AllPermissions,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )
    $result = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Setting permissions for Web Application '$WebAppUrl'"

    if ($AllPermissions) {
        # AllPermissions parameter specified with and one of the other parameters 
        if ($ListPermissions -or $SitePermissions -or $PersonalPermissions) {
            Throw "Do not specify parameters ListPermissions, SitePermissions or PersonalPermissions when specifying parameter AllPermissions"
        }
    } else {
        # You have to specify all three parameters 
        if (-not ($ListPermissions -and $SitePermissions -and $PersonalPermissions)) {
            Throw "One of the parameters ListPermissions, SitePermissions or PersonalPermissions is missing"
        }
    }

    if ($AllPermissions) {
        $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]

            $wa = Get-SPWebApplication $params.WebAppUrl -ErrorAction SilentlyContinue
            
            if ($null -eq $wa) { throw "The specified web application could not be found." }

            $wa.RightsMask = [Microsoft.SharePoint.SPBasePermissions]::FullMask
            $wa.Update()
        }
    } else {
        $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]

            $wa = Get-SPWebApplication $params.WebAppUrl -ErrorAction SilentlyContinue
            
            if ($null -eq $wa) { throw "The specified web application could not be found." }

            $newMask = [Microsoft.SharePoint.SPBasePermissions]::EmptyMask
            foreach ($lp in $ListPermissions) {
                switch ($lp) {
                    "Manage Lists"            { $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::ManageLists}
                    "Override List Behaviors" { $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::CancelCheckout}
                    "Add Items"               { $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::AddListItems}
                    "Edit Items"              { $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::EditListItems}
                    "Delete Items"            { $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::DeleteListItems}
                    "View Items"              { $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::ViewListItems}
                    "Approve Items"           { $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::ApproveItems}
                    "Open Items"              { $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::OpenItems}
                    "View Versions"           { $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::ViewVersions}
                    "Delete Versions"         { $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::DeleteVersions}
                    "Create Alerts"           { $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::CreateAlerts}
                    "View Application Pages"  { $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::ViewFormPages}
                }
            }

            foreach ($sp in $SitePermissions) {
                switch ($sp) {
                    "Manage Permissions"              { $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::ManagePermissions}
                    "View Web Analytics Data"         { $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::ViewUsageData}
                    "Create Subsites"                 { $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::ManageSubwebs}
                    "Manage Web Site"                 { $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::ManageWeb}
                    "Add and Customize Pages"         { $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::AddAndCustomizePages}
                    "Apply Themes and Borders"        { $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::ApplyThemeAndBorder}
                    "Apply Style Sheets"              { $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::ApplyStyleSheets}
                    "Create Groups"                   { $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::CreateGroups}
                    "Browse Directories"              { $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::BrowseDirectories}
                    "Use Self-Service Site Creation"  { $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::CreateSSCSite}
                    "View Pages"                      { $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::ViewPages}
                    "Enumerate Permissions"           { $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::EnumeratePermissions}
                    "Browse User Information"         { $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::BrowseUserInfo}
                    "Manage Alerts"                   { $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::ManageAlerts}
                    "Use Remote Interfaces"           { $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::UseRemoteAPIs}
                    "Use Client Integration Features" { $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::UseClientIntegration}
                    "Open"                            { $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::Open}
                    "Edit Personal User Information"  { $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::EditMyUserInfo}
                }
            }

            foreach ($pp in $PersonalPermissions) {
                switch ($pp) {
                    "Manage Personal Views"         { $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::ManagePersonalViews}
                    "Add/Remove Personal Web Parts" { $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::AddDelPrivateWebParts}
                    "Update Personal Web Parts"     { $newMask = $newMask -bor [Microsoft.SharePoint.SPBasePermissions]::UpdatePersonalWebParts}
                }
            }
            $wa.RightsMask = $newMask
            $wa.Update()
        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $WebAppUrl,
        [parameter(Mandatory = $false)] [ValidateSet("Manage Lists","Override List Behaviors", "Add Items","Edit Items","Delete Items","View Items","Approve Items","Open Items","View Versions","Delete Versions","Create Alerts","View Application Pages")] [System.String[]] $ListPermissions,
        [parameter(Mandatory = $false)] [ValidateSet("Manage Permissions","View Web Analytics Data","Create Subsites","Manage Web Site","Add and Customize Pages","Apply Themes and Borders","Apply Style Sheets","Create Groups","Browse Directories","Use Self-Service Site Creation","View Pages","Enumerate Permission","Browse User Information","Manage Alerts","Use Remote Interfaces","Use Client Integration Features","Open","Edit Personal User Information")] [System.String[]] $SitePermissions,
        [parameter(Mandatory = $false)] [ValidateSet("Manage Personal Views","Add/Remove Personal Web Parts","Update Personal Web Parts")] [System.String[]] $PersonalPermissions,
        [parameter(Mandatory = $false)] [System.Boolean] $AllPermissions,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing permissions for Web Application '$WebAppUrl'"

    if ($AllPermissions) {
        # AllPermissions parameter specified with and one of the other parameters 
        if ($ListPermissions -or $SitePermissions -or $PersonalPermissions) {
            Throw "Do not specify parameters ListPermissions, SitePermissions or PersonalPermissions when specifying parameter AllPermissions"
        }
    } else {
        # You have to specify all three parameters 
        if (-not ($ListPermissions -and $SitePermissions -and $PersonalPermissions)) {
            Throw "One of the parameters ListPermissions, SitePermissions or PersonalPermissions is missing"
        }
    }

    if ($AllPermissions -eq $true) {
        if ($CurrentValues.ContainsKey("AllPermissions")) {
            return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("AllPermissions")
        } else {
            return $false
        }    
    } else {
        if ($CurrentValues.ContainsKey("AllPermissions")) {
            return $false
        } else {
            if ((Compare-Object -ReferenceObject $ListPermissions -DifferenceObject $CurrentValues.ListPermissions) -ne $null) { return $false }
            if ((Compare-Object -ReferenceObject $SitePermissions -DifferenceObject $CurrentValues.SitePermissions) -ne $null) { return $false }
            if ((Compare-Object -ReferenceObject $PersonalPermissions -DifferenceObject $CurrentValues.PersonalPermissions) -ne $null) { return $false }
            return $true
        }    
    }
}

Export-ModuleMember -Function *-TargetResource
