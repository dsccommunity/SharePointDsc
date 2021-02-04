$script:SPDscUtilModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SharePointDsc.Util'
Import-Module -Name $script:SPDscUtilModulePath

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
        [ValidateSet("WebApplication", "SiteCollection")]
        [System.String]
        $SettingsScope,

        [Parameter()]
        [System.Boolean]
        $AllowSharePointDesigner,

        [Parameter()]
        [System.Boolean]
        $AllowDetachPagesFromDefinition,

        [Parameter()]
        [System.Boolean]
        $AllowCustomiseMasterPage,

        [Parameter()]
        [System.Boolean]
        $AllowManageSiteURLStructure,

        [Parameter()]
        [System.Boolean]
        $AllowCreateDeclarativeWorkflow,

        [Parameter()]
        [System.Boolean]
        $AllowSavePublishDeclarativeWorkflow,

        [Parameter()]
        [System.Boolean]
        $AllowSaveDeclarativeWorkflowAsTemplate,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting SharePoint Designer configuration settings"

    switch ($SettingsScope)
    {
        "WebApplication"
        {
            $result = Invoke-SPDscCommand -Credential $InstallAccount `
                -Arguments $PSBoundParameters `
                -ScriptBlock {
                $params = $args[0]

                $nullReturn = @{
                    WebAppUrl                              = $params.WebAppUrl
                    SettingsScope                          = $params.SettingsScope
                    AllowSharePointDesigner                = $null
                    AllowDetachPagesFromDefinition         = $null
                    AllowCustomiseMasterPage               = $null
                    AllowManageSiteURLStructure            = $null
                    AllowCreateDeclarativeWorkflow         = $null
                    AllowSavePublishDeclarativeWorkflow    = $null
                    AllowSaveDeclarativeWorkflowAsTemplate = $null
                }

                try
                {
                    $null = Get-SPFarm
                }
                catch
                {
                    Write-Verbose -Message ("No local SharePoint farm was detected. " + `
                            "SharePoint Designer settings will not be applied")
                    return $nullReturn
                }

                # Check if web application exists
                $webapp = Get-SPWebApplication | Where-Object -FilterScript {
                    ($_.Url).StartsWith($params.WebAppUrl, "CurrentCultureIgnoreCase")
                }
                if ($null -eq $webapp)
                {
                    Write-Verbose -Message ("Web application not found. SharePoint Designer " + `
                            "settings will not be applied")
                    return $nullReturn
                }
                else
                {
                    # Get SPD settings for the web application
                    $spdSettings = Get-SPDesignerSettings $params.WebAppUrl

                    return @{
                        # Set the SPD settings
                        WebAppUrl                              = $params.WebAppUrl
                        SettingsScope                          = $params.SettingsScope
                        AllowSharePointDesigner                = $spdSettings.AllowDesigner
                        AllowDetachPagesFromDefinition         = $spdSettings.AllowRevertFromTemplate
                        AllowCustomiseMasterPage               = $spdSettings.AllowMasterPageEditing
                        AllowManageSiteURLStructure            = $spdSettings.ShowURLStructure
                        AllowCreateDeclarativeWorkflow         = `
                            $spdSettings.AllowCreateDeclarativeWorkflow
                        AllowSavePublishDeclarativeWorkflow    = `
                            $spdSettings.AllowSavePublishDeclarativeWorkflow
                        AllowSaveDeclarativeWorkflowAsTemplate = `
                            $spdSettings.AllowSaveDeclarativeWorkflowAsTemplate
                    }
                }
            }
        }
        "SiteCollection"
        {
            if ((Test-SPDscRunAsCredential -Credential $InstallAccount) -eq $true)
            {
                $result = Invoke-SPDscCommand -Credential $InstallAccount `
                    -Arguments $PSBoundParameters `
                    -ScriptBlock {
                    $params = $args[0]

                    $nullReturn = @{
                        WebAppUrl                              = $params.WebAppUrl
                        SettingsScope                          = $params.SettingsScope
                        AllowSharePointDesigner                = $null
                        AllowDetachPagesFromDefinition         = $null
                        AllowCustomiseMasterPage               = $null
                        AllowManageSiteURLStructure            = $null
                        AllowCreateDeclarativeWorkflow         = $null
                        AllowSavePublishDeclarativeWorkflow    = $null
                        AllowSaveDeclarativeWorkflowAsTemplate = $null
                    }

                    try
                    {
                        $null = Get-SPFarm
                    }
                    catch
                    {
                        Write-Verbose -Message ("No local SharePoint farm was detected. " + `
                                "SharePoint Designer settings will not be applied")
                        return $nullReturn
                    }

                    # Check if site collections exists
                    $site = Get-SPSite -Identity $params.WebAppUrl -ErrorAction SilentlyContinue
                    if ($null -eq $site)
                    {
                        Write-Verbose -Message ("Site collection not found. SharePoint " + `
                                "Designer settings will not be applied")
                        return $nullReturn
                    }
                    else
                    {
                        return @{
                            # Set the SPD settings
                            WebAppUrl                              = $params.WebAppUrl
                            SettingsScope                          = $params.SettingsScope
                            AllowSharePointDesigner                = $site.AllowDesigner
                            AllowDetachPagesFromDefinition         = $site.AllowRevertFromTemplate
                            AllowCustomiseMasterPage               = $site.AllowMasterPageEditing
                            AllowManageSiteURLStructure            = $site.ShowURLStructure
                            AllowCreateDeclarativeWorkflow         = $site.AllowCreateDeclarativeWorkflow
                            AllowSavePublishDeclarativeWorkflow    = `
                                $site.AllowSavePublishDeclarativeWorkflow
                            AllowSaveDeclarativeWorkflowAsTemplate = `
                                $site.AllowSaveDeclarativeWorkflowAsTemplate
                        }
                    }
                }
            }
            else
            {
                $message = ("A known issue exists that prevents these settings from being managed " + `
                        "when InstallAccount is used instead of PsDscRunAsAccount. See " + `
                        "http://aka.ms/SharePointDscRemoteIssues for details.")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
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
        $WebAppUrl,

        [Parameter(Mandatory = $true)]
        [ValidateSet("WebApplication", "SiteCollection")]
        [System.String]
        $SettingsScope,

        [Parameter()]
        [System.Boolean]
        $AllowSharePointDesigner,

        [Parameter()]
        [System.Boolean]
        $AllowDetachPagesFromDefinition,

        [Parameter()]
        [System.Boolean]
        $AllowCustomiseMasterPage,

        [Parameter()]
        [System.Boolean]
        $AllowManageSiteURLStructure,

        [Parameter()]
        [System.Boolean]
        $AllowCreateDeclarativeWorkflow,

        [Parameter()]
        [System.Boolean]
        $AllowSavePublishDeclarativeWorkflow,

        [Parameter()]
        [System.Boolean]
        $AllowSaveDeclarativeWorkflowAsTemplate,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting SharePoint Designer configuration settings"

    switch ($SettingsScope)
    {
        "WebApplication"
        {
            Invoke-SPDscCommand -Credential $InstallAccount `
                -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
                -ScriptBlock {
                $params = $args[0]
                $eventSource = $args[1]

                try
                {
                    $null = Get-SPFarm
                }
                catch
                {
                    $message = ("No local SharePoint farm was detected. SharePoint " + `
                            "Designer settings will not be applied")
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $eventSource
                    throw $message
                }

                Write-Verbose -Message "Start update SPD web application settings"

                # Check if web application exists
                $webapp = Get-SPWebApplication | Where-Object -FilterScript {
                    ($_.Url).StartsWith($params.WebAppUrl, "CurrentCultureIgnoreCase")
                }
                if ($null -eq $webapp)
                {
                    $message = ("Web application not found. SharePoint Designer settings " + `
                            "will not be applied")
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $eventSource
                    throw $message
                }
                else
                {
                    # Set the SharePoint Designer settings
                    if ($params.ContainsKey("AllowSharePointDesigner"))
                    {
                        $webapp.AllowDesigner = $params.AllowSharePointDesigner
                    }
                    if ($params.ContainsKey("AllowDetachPagesFromDefinition"))
                    {
                        $webapp.AllowRevertFromTemplate = $params.AllowDetachPagesFromDefinition
                    }
                    if ($params.ContainsKey("AllowCustomiseMasterPage"))
                    {
                        $webapp.AllowMasterPageEditing = $params.AllowCustomiseMasterPage
                    }
                    if ($params.ContainsKey("AllowManageSiteURLStructure"))
                    {
                        $webapp.ShowURLStructure = $params.AllowManageSiteURLStructure
                    }
                    if ($params.ContainsKey("AllowCreateDeclarativeWorkflow"))
                    {
                        $webapp.AllowCreateDeclarativeWorkflow = `
                            $params.AllowCreateDeclarativeWorkflow
                    }
                    if ($params.ContainsKey("AllowSavePublishDeclarativeWorkflow"))
                    {
                        $webapp.AllowSavePublishDeclarativeWorkflow = `
                            $params.AllowSavePublishDeclarativeWorkflow
                    }
                    if ($params.ContainsKey("AllowSaveDeclarativeWorkflowAsTemplate"))
                    {
                        $webapp.AllowSaveDeclarativeWorkflowAsTemplate = `
                            $params.AllowSaveDeclarativeWorkflowAsTemplate
                    }
                    $webapp.Update()
                }
            }
        }
        "SiteCollection"
        {
            if ((Test-SPDscRunAsCredential -Credential $InstallAccount) -eq $true)
            {
                Invoke-SPDscCommand -Credential $InstallAccount `
                    -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
                    -ScriptBlock {
                    $params = $args[0]
                    $eventSource = $args[1]

                    try
                    {
                        $null = Get-SPFarm
                    }
                    catch
                    {
                        $message = ("No local SharePoint farm was detected. SharePoint Designer " + `
                                "settings will not be applied")
                        Add-SPDscEvent -Message $message `
                            -EntryType 'Error' `
                            -EventID 100 `
                            -Source $eventSource
                        throw $message
                    }

                    Write-Verbose -Message "Start update SPD site collection settings"

                    # Check if site collection exists
                    $site = Get-SPSite -Identity $params.WebAppUrl -ErrorAction SilentlyContinue
                    if ($null -eq $site)
                    {
                        $message = ("Site collection not found. SharePoint Designer settings " + `
                                "will not be applied")
                        Add-SPDscEvent -Message $message `
                            -EntryType 'Error' `
                            -EventID 100 `
                            -Source $eventSource
                        throw $message
                    }
                    else
                    {
                        # Set the SharePoint Designer settings
                        if ($params.ContainsKey("AllowSharePointDesigner"))
                        {
                            $site.AllowDesigner = $params.AllowSharePointDesigner
                        }
                        if ($params.ContainsKey("AllowDetachPagesFromDefinition"))
                        {
                            $site.AllowRevertFromTemplate = $params.AllowDetachPagesFromDefinition
                        }
                        if ($params.ContainsKey("AllowCustomiseMasterPage"))
                        {
                            $site.AllowMasterPageEditing = $params.AllowCustomiseMasterPage
                        }
                        if ($params.ContainsKey("AllowManageSiteURLStructure"))
                        {
                            $site.ShowURLStructure = $params.AllowManageSiteURLStructure
                        }
                        if ($params.ContainsKey("AllowCreateDeclarativeWorkflow"))
                        {
                            $site.AllowCreateDeclarativeWorkflow = `
                                $params.AllowCreateDeclarativeWorkflow
                        }
                        if ($params.ContainsKey("AllowSavePublishDeclarativeWorkflow"))
                        {
                            $site.AllowSavePublishDeclarativeWorkflow = `
                                $params.AllowSavePublishDeclarativeWorkflow
                        }
                        if ($params.ContainsKey("AllowSaveDeclarativeWorkflowAsTemplate"))
                        {
                            $site.AllowSaveDeclarativeWorkflowAsTemplate = `
                                $params.AllowSaveDeclarativeWorkflowAsTemplate
                        }
                    }
                }
            }
            else
            {
                $message = ("A known issue exists that prevents these settings from being " + `
                        "managed when InstallAccount is used instead of PsDscRunAsAccount. " + `
                        "See http://aka.ms/SharePointDscRemoteIssues for details.")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
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
        $WebAppUrl,

        [Parameter(Mandatory = $true)]
        [ValidateSet("WebApplication", "SiteCollection")]
        [System.String]
        $SettingsScope,

        [Parameter()]
        [System.Boolean]
        $AllowSharePointDesigner,

        [Parameter()]
        [System.Boolean]
        $AllowDetachPagesFromDefinition,

        [Parameter()]
        [System.Boolean]
        $AllowCustomiseMasterPage,

        [Parameter()]
        [System.Boolean]
        $AllowManageSiteURLStructure,

        [Parameter()]
        [System.Boolean]
        $AllowCreateDeclarativeWorkflow,

        [Parameter()]
        [System.Boolean]
        $AllowSavePublishDeclarativeWorkflow,

        [Parameter()]
        [System.Boolean]
        $AllowSaveDeclarativeWorkflowAsTemplate,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing SharePoint Designer configuration settings"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

<# Nik20170106 - Read the Designer Settings of either the Site Collection or the Web Application #>
function Export-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [System.String]
        $URL,

        [Parameter()]
        [System.String]
        $Scope,

        [Parameter()]
        [System.String]
        $WebAppName
    )

    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPDesignerSettings\MSFT_SPDesignerSettings.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module

    $params.WebAppUrl = $URL
    $params.SettingsScope = $Scope
    $results = Get-TargetResource @params

    <# Nik20170106 - The logic here differs from other Read functions due to a bug in the Designer Resource that doesn't properly obtains a reference to the Site Collection. #>
    if ($null -ne $results)
    {
        $PartialContent = "        SPDesignerSettings " + $Scope + [System.Guid]::NewGuid().ToString() + "`r`n"
        $PartialContent += "        {`r`n"
        $results = Repair-Credentials -results $results
        $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
        $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
        $PartialContent += $currentBlock
        if ($webAppName)
        {
            $PartialContent += "            DependsOn = `"[SP" + $scope.Replace("Collection", "") + "]" + $WebAppName + "`";`r`n"
        }
        $PartialContent += "        }`r`n"
        $Content += $PartialContent
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
