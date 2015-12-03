function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $Name,
        [parameter(Mandatory = $true)]  [System.String]  $ApplicationPool,
        [parameter(Mandatory = $true)]  [System.String]  $ApplicationPoolAccount,
        [parameter(Mandatory = $true)]  [System.String]  $Url,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowAnonymous,
        [parameter(Mandatory = $false)] [System.String]  $DatabaseName,
        [parameter(Mandatory = $false)] [System.String]  $DatabaseServer,
        [parameter(Mandatory = $false)] [System.String]  $HostHeader,
        [parameter(Mandatory = $false)] [System.String]  $Path,
        [parameter(Mandatory = $false)] [System.String]  $Port,
        [parameter(Mandatory = $false)] [ValidateSet("NTLM","Kerberos")] [System.String] $AuthenticationMethod,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Getting web application '$Name'"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments @($PSBoundParameters,$PSScriptRoot) -ScriptBlock {
        $params = $args[0]
        $ScriptRoot = $args[1]
        
        $wa = Get-SPWebApplication -Identity $params.Name -ErrorAction SilentlyContinue
        if ($null -eq $wa) { return $null }

        $authProvider = Get-SPAuthenticationProvider -WebApplication $wa.Url -Zone "Default" 
        if ($authProvider.DisableKerberos -eq $true) { $localAuthMode = "NTLM" } else { $localAuthMode = "Kerberos" }

        Import-Module (Join-Path $ScriptRoot "..\..\Modules\xSharePoint.WebApplication\xSPWebApplication.Throttling.psm1" -Resolve)
        Import-Module (Join-Path $ScriptRoot "..\..\Modules\xSharePoint.WebApplication\xSPWebApplication.Workflow.psm1" -Resolve)
        Import-Module (Join-Path $ScriptRoot "..\..\Modules\xSharePoint.WebApplication\xSPWebApplication.BlockedFileTypes.psm1" -Resolve)
        Import-Module (Join-Path $ScriptRoot "..\..\Modules\xSharePoint.WebApplication\xSPWebApplication.GeneralSettings.psm1" -Resolve)

        return @{
            Name = $wa.DisplayName
            ApplicationPool = $wa.ApplicationPool.Name
            ApplicationPoolAccount = $wa.ApplicationPool.Username
            Url = $wa.Url
            AllowAnonymous = $authProvider.AllowAnonymous
            DatabaseName = $wa.ContentDatabases[0].Name
            DatabaseServer = $wa.ContentDatabases[0].Server
            HostHeader = (New-Object System.Uri $wa.Url).Host
            Path = $wa.IisSettings[0].Path
            Port = (New-Object System.Uri $wa.Url).Port
            AuthenticationMethod = $localAuthMode
            InstallAccount = $params.InstallAccount
            ThrottlingSettings = (Get-xSPWebApplicationThrottlingSettings -WebApplication $wa)
            WorkflowSettings = (Get-xSPWebApplicationWorkflowSettings -WebApplication $wa)
            BlockedFileTypes = (Get-xSPWebApplicationBlockedFileTypes -WebApplication $wa)
            GeneralSettings = (Get-xSPWebApplicationGeneralSettings -WebApplication $wa)
        }
    }
    return $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $Name,
        [parameter(Mandatory = $true)]  [System.String]  $ApplicationPool,
        [parameter(Mandatory = $true)]  [System.String]  $ApplicationPoolAccount,
        [parameter(Mandatory = $true)]  [System.String]  $Url,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowAnonymous,
        [parameter(Mandatory = $false)] [System.String]  $DatabaseName,
        [parameter(Mandatory = $false)] [System.String]  $DatabaseServer,
        [parameter(Mandatory = $false)] [System.String]  $HostHeader,
        [parameter(Mandatory = $false)] [System.String]  $Path,
        [parameter(Mandatory = $false)] [System.String]  $Port,
        [parameter(Mandatory = $false)] [ValidateSet("NTLM","Kerberos")] [System.String] $AuthenticationMethod,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Creating web application '$Name'"
    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments @($PSBoundParameters,$PSScriptRoot) -ScriptBlock {
        $params = $args[0]
        $ScriptRoot = $args[1]

        $wa = Get-SPWebApplication -Identity $params.Name -ErrorAction SilentlyContinue
        if ($null -eq $wa) {
            $newWebAppParams = @{
                Name = $params.Name
                ApplicationPool = $params.ApplicationPool
                ApplicationPoolAccount = $params.ApplicationPoolAccount
                Url = $params.Url
            }
            if ($params.ContainsKey("AuthenticationMethod") -eq $true) {
                if ($params.AuthenticationMethod -eq "NTLM") {
                    $ap = New-SPAuthenticationProvider -UseWindowsIntegratedAuthentication -DisableKerberos 
                } else {
                    $ap = New-SPAuthenticationProvider -UseWindowsIntegratedAuthentication
                }
                $newWebAppParams.Add("AuthenticationProvider", $ap)
            }
            if ($params.ContainsKey("AllowAnonymous")) { 
                $newWebAppParams.Add("AllowAnonymousAccess", $true)
            }
            if ($params.ContainsKey("DatabaseName") -eq $true) { $newWebAppParams.Add("DatabaseName", $params.DatabaseName) }
            if ($params.ContainsKey("DatabaseServer") -eq $true) { $newWebAppParams.Add("DatabaseServer", $params.DatabaseServer) }
            if ($params.ContainsKey("HostHeader") -eq $true) { $newWebAppParams.Add("HostHeader", $params.HostHeader) }
            if ($params.ContainsKey("Path") -eq $true) { $newWebAppParams.Add("Path", $params.Path) }
            if ($params.ContainsKey("Port") -eq $true) { $newWebAppParams.Add("Port", $params.Port) } 
         
            $wa = New-SPWebApplication @newWebAppParams
        }

        # Resource throttling settings
        if ($params.ContainsKey("ThrottlingSettings") -eq $true) {
            Import-Module (Join-Path $ScriptRoot "..\..\Modules\xSharePoint.WebApplication\xSPWebApplication.Throttling.psm1" -Resolve)
            Set-xSPWebApplicationThrottlingSettings -WebApplication $wa -Settings $params.ThrottlingSettings
        }
        
        # Blocked file types
        if ($params.ContainsKey("BlockedFileTypes") -eq $true) {
            Import-Module (Join-Path $ScriptRoot "..\..\Modules\xSharePoint.WebApplication\xSPWebApplication.BlockedFileTypes.psm1" -Resolve)
            Set-xSPWebApplicationBlockedFileTypes -WebApplication $wa -Settings $params.BlockedFileTypes
        }

        # General Settings
        if ($params.ContainsKey("GeneralSettings") -eq $true) {
            Import-Module (Join-Path $ScriptRoot "..\..\Modules\xSharePoint.WebApplication\xSPWebApplication.GeneralSettings.psm1" -Resolve)
            Set-xSPWebApplicationGeneralSettings -WebApplication $wa -Settings $params.GeneralSettings
        }

        if( ($params.GeneralSettings -ne $null) -or
            ($params.ThrottlingSettings -ne $null) -or
            ($params.BlockedFileTypes -ne $null) ) {
                $wa.Update()
        }

        # Workflow settings
        if ($params.ContainsKey("WorkflowSettings") -eq $true) {
            Import-Module (Join-Path $ScriptRoot "..\..\Modules\xSharePoint.WebApplication\xSPWebApplication.Workflow.psm1" -Resolve)
            # Workflow uses a seperate update method, to avoid update conflicts get a fresh web app object
            $wa2 = Get-SPWebApplication -Identity $params.Name
            Set-xSPWebApplicationWorkflowSettings -WebApplication $wa2 -Settings $params.WorkflowSettings
        }

        # Happy hour settings
        if ($params.ContainsKey("ThrottlingSettings") -eq $true) {
            if ((Test-xSharePointObjectHasProperty $params.ThrottlingSettings "HappyHour") -eq $true) {
                Import-Module (Join-Path $ScriptRoot "..\..\Modules\xSharePoint.WebApplication\xSPWebApplication.Throttling.psm1" -Resolve)
                # Happy hour settins use separate update method so use a fresh web app to update these
                $wa3 = Get-SPWebApplication -Identity $params.Name
                Set-xSPWebApplicationHappyHourSettings -WebApplication $wa3 -Settings $params.ThrottlingSettings.HappyHour
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
        [parameter(Mandatory = $true)]  [System.String]  $Name,
        [parameter(Mandatory = $true)]  [System.String]  $ApplicationPool,
        [parameter(Mandatory = $true)]  [System.String]  $ApplicationPoolAccount,
        [parameter(Mandatory = $true)]  [System.String]  $Url,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowAnonymous,
        [parameter(Mandatory = $false)] [System.String]  $DatabaseName,
        [parameter(Mandatory = $false)] [System.String]  $DatabaseServer,
        [parameter(Mandatory = $false)] [System.String]  $HostHeader,
        [parameter(Mandatory = $false)] [System.String]  $Path,
        [parameter(Mandatory = $false)] [System.String]  $Port,
        [parameter(Mandatory = $false)] [ValidateSet("NTLM","Kerberos")] [System.String] $AuthenticationMethod,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing for web application '$Name'"
    if ($null -eq $CurrentValues) { return $false }

    $testReturn = Test-xSharePointSpecificParameters -CurrentValues $CurrentValues `
                                                     -DesiredValues $PSBoundParameters `
                                                     -ValuesToCheck @("ApplicationPool")

    if ($testReturn -eq $false) { return $false }

    # Resource throttling settings
    if ($PSBoundParameters.ContainsKey("ThrottlingSettings") -eq $true) {
        Import-Module (Join-Path $PSScriptRoot "..\..\Modules\xSharePoint.WebApplication\xSPWebApplication.Throttling.psm1" -Resolve)
        $testReturn = Test-xSPWebApplicationThrottlingSettings -CurrentSettings $CurrentValues.ThrottlingSettings -DesiredSettings $ThrottlingSettings
    }
    if ($testReturn -eq $false) { return $false }

    # Workflow settings
    if ($PSBoundParameters.ContainsKey("WorkflowSettings") -eq $true) {
        Import-Module (Join-Path $PSScriptRoot "..\..\Modules\xSharePoint.WebApplication\xSPWebApplication.Workflow.psm1" -Resolve)
        $testReturn = Test-xSPWebApplicationWorkflowSettings -CurrentSettings $CurrentValues.WorkflowSettings -DesiredSettings $WorkflowSettings
    }
    if ($testReturn -eq $false) { return $false }

    # Blocked file types
    if ($PSBoundParameters.ContainsKey("BlockedFileTypes") -eq $true) {
        Import-Module (Join-Path $PSScriptRoot "..\..\Modules\xSharePoint.WebApplication\xSPWebApplication.BlockedFileTypes.psm1" -Resolve)
        $testReturn = Test-xSPWebApplicationBlockedFileTypes -CurrentSettings $CurrentValues.BlockedFileTypes -DesiredSettings $BlockedFileTypes
    }
    if ($testReturn -eq $false) { return $false }

    # General settings
    if ($PSBoundParameters.ContainsKey("GeneralSettings") -eq $true) {
        Import-Module (Join-Path $PSScriptRoot "..\..\Modules\xSharePoint.WebApplication\xSPWebApplication.GeneralSettings.psm1" -Resolve)
        $testReturn = Test-xSPWebApplicationGeneralSettings -CurrentSettings $CurrentValues.GeneralSettings -DesiredSettings $GeneralSettings
    }
    if ($testReturn -eq $false) { return $false }

    return $testReturn
}


Export-ModuleMember -Function *-TargetResource

