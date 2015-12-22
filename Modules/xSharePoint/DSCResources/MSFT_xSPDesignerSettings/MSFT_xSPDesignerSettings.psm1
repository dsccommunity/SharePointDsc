function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)] [System.String] $Url,
        [parameter(Mandatory = $true)]  [ValidateSet("WebApplication","SiteCollection")] [System.String] $SettingsScope,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowSharePointDesigner,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowDetachPagesFromDefinition,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowCustomiseMasterPage,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowManageSiteURLStructure,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowCreateDeclarativeWorkflow,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowSavePublishDeclarativeWorkflow,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowSaveDeclarativeWorkflowAsTemplate,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Getting SharePoint Designer configuration settings"

    switch ($SettingsScope) {
        "WebApplication" {
            $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
                $params = $args[0]
        
                try {
                    $spFarm = Get-SPFarm
                } catch {
                    Write-Verbose -Verbose "No local SharePoint farm was detected. SharePoint Designer settings will not be applied"
                    return $null
                }

                # Check if web application exists
                $webapp = Get-SPWebApplication | Where {($_.Url).StartsWith($params.Url)}
                if ($webapp -eq $null) {
                    Write-Verbose -Verbose "Web application not found. SharePoint Designer settings will not be applied"
                    return $null
                } else {
                    # Get SPD settings for the web application
                    $spdSettings = Get-SPDesignerSettings $params.Url
        
                    return @{
                        # Set the SPD settings
                        Url = $params.Url
                        SettingsScope = $params.SettingsScope
                        AllowSharePointDesigner = $spdSettings.AllowDesigner
                        AllowDetachPagesFromDefinition = $spdSettings.AllowRevertFromTemplate
                        AllowCustomiseMasterPage = $spdSettings.AllowMasterPageEditing
                        AllowManageSiteURLStructure = $spdSettings.ShowURLStructure
                        AllowCreateDeclarativeWorkflow = $spdSettings.AllowCreateDeclarativeWorkflow
                        AllowSavePublishDeclarativeWorkflow = $spdSettings.AllowSavePublishDeclarativeWorkflow
                        AllowSaveDeclarativeWorkflowAsTemplate = $spdSettings.AllowSaveDeclarativeWorkflowAsTemplate
                        InstallAccount = $params.InstallAccount
                    }
                }
            }
        }
        "SiteCollection" {
            $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
                $params = $args[0]
        
                try {
                    $spFarm = Get-SPFarm
                } catch {
                    Write-Verbose -Verbose "No local SharePoint farm was detected. SharePoint Designer settings will not be applied"
                    return $null
                }

                # Check if site collections exists
                $site = Get-SPSite | Where {$_.Url -eq $url}
                if ($site -eq $null) {
                    Write-Verbose -Verbose "Site collection not found. SharePoint Designer settings will not be applied"
                    return $null
                } else {
                    return @{
                        # Set the SPD settings
                        Url = $params.Url
                        SettingsScope = $params.SettingsScope
                        AllowSharePointDesigner = $site.AllowDesigner
                        AllowDetachPagesFromDefinition = $site.AllowRevertFromTemplate
                        AllowCustomiseMasterPage = $site.AllowMasterPageEditing
                        AllowManageSiteURLStructure = $site.ShowURLStructure
                        AllowCreateDeclarativeWorkflow = $site.AllowCreateDeclarativeWorkflow
                        AllowSavePublishDeclarativeWorkflow = $site.AllowSavePublishDeclarativeWorkflow
                        AllowSaveDeclarativeWorkflowAsTemplate = $site.AllowSaveDeclarativeWorkflowAsTemplate
                        InstallAccount = $params.InstallAccount
                    }
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
        [parameter(Mandatory = $true)] [System.String] $Url,
        [parameter(Mandatory = $true)]  [ValidateSet("WebApplication","SiteCollection")] [System.String] $SettingsScope,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowSharePointDesigner,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowDetachPagesFromDefinition,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowCustomiseMasterPage,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowManageSiteURLStructure,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowCreateDeclarativeWorkflow,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowSavePublishDeclarativeWorkflow,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowSaveDeclarativeWorkflowAsTemplate,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Setting SharePoint Designer configuration settings"

    switch ($SettingsScope) {
        "WebApplication" {
            Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
                $params = $args[0]

                try {
                    $spFarm = Get-SPFarm
                } catch {
                    throw "No local SharePoint farm was detected. SharePoint Designer settings will not be applied"
                    return
                }
        
                Write-Verbose -Verbose "Start update SPD web application settings"

                # Check if web application exists
                $webapp = Get-SPWebApplication | Where {($_.Url).StartsWith($params.Url)}
                if ($webapp -eq $null) {
                    throw "Web application not found. SharePoint Designer settings will not be applied"
                    return
                } else {
                    # Set the SharePoint Designer settings
                    if ($params.ContainsKey("InstallAccount")) { $params.Remove("InstallAccount") | Out-Null } 
                    if ($params.ContainsKey("SettingsScope")) { $params.Remove("SettingsScope") | Out-Null }
 
                    $params = $params | Rename-xSharePointParamValue -oldName "Url" -newName "WebApplication" `
                                      | Rename-xSharePointParamValue -oldName "AllowSharePointDesigner" -newName "AllowDesigner" `
                                      | Rename-xSharePointParamValue -oldName "AllowDetachPagesFromDefinition" -newName "AllowRevertFromTemplate" `
                                      | Rename-xSharePointParamValue -oldName "AllowCustomiseMasterPage" -newName "AllowMasterPageEditing" `
                                      | Rename-xSharePointParamValue -oldName "AllowManageSiteURLStructure" -newName "ShowURLStructure"

                    Set-SPDesignerSettings @params
                }
            }
        }
        "SiteCollection" {
            Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
                $params = $args[0]

                try {
                    $spFarm = Get-SPFarm
                } catch {
                    throw "No local SharePoint farm was detected. SharePoint Designer settings will not be applied"
                    return
                }
        
                Write-Verbose -Verbose "Start update SPD site collection settings"

                # Check if site collection exists
                $site = Get-SPSite | Where {$_.Url -eq $url}
                if ($site -eq $null) {
                    throw "Site collection not found. SharePoint Designer settings will not be applied"
                    return $null
                } else {
                    # Set the SharePoint Designer settings
                    if ($params.ContainsKey("AllowSharePointDesigner")) { $site.AllowDesigner = $params.AllowSharePointDesigner }
                    if ($params.ContainsKey("AllowDetachPagesFromDefinition")) { $site.AllowRevertFromTemplate = $params.AllowDetachPagesFromDefinition }
                    if ($params.ContainsKey("AllowCustomiseMasterPage")) { $site.AllowMasterPageEditing = $params.AllowCustomiseMasterPage }
                    if ($params.ContainsKey("AllowManageSiteURLStructure")) {$site.ShowURLStructure = $params.AllowManageSiteURLStructure }
                    if ($params.ContainsKey("AllowCreateDeclarativeWorkflow")) { $site.AllowCreateDeclarativeWorkflow = $params.AllowCreateDeclarativeWorkflow }
                    if ($params.ContainsKey("AllowSavePublishDeclarativeWorkflow")) { $site.AllowSavePublishDeclarativeWorkflow = $params.AllowSavePublishDeclarativeWorkflow }
                    if ($params.ContainsKey("AllowSaveDeclarativeWorkflowAsTemplate")) { $site.AllowSaveDeclarativeWorkflowAsTemplate = $params.AllowSaveDeclarativeWorkflowAsTemplate }
                    $site.Update()
                }
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
        [parameter(Mandatory = $true)] [System.String] $Url,
        [parameter(Mandatory = $true)]  [ValidateSet("WebApplication","SiteCollection")] [System.String] $SettingsScope,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowSharePointDesigner,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowDetachPagesFromDefinition,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowCustomiseMasterPage,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowManageSiteURLStructure,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowCreateDeclarativeWorkflow,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowSavePublishDeclarativeWorkflow,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowSaveDeclarativeWorkflowAsTemplate,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Testing SharePoint Designer configuration settings"
    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($null -eq $CurrentValues) { return $false }

    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters
}

Export-ModuleMember -Function *-TargetResource
