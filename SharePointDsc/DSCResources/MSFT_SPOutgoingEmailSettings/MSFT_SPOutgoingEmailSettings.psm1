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
        [System.String]
        $SMTPServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $FromAddress,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ReplyToAddress,

        [Parameter(Mandatory = $true)]
        [System.String]
        $CharacterSet,

        [Parameter()]
        [System.Boolean]
        $UseTLS,

        [Parameter()]
        [System.UInt32]
        $SMTPPort,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting outgoing email settings configuration for $WebAppUrl"

    $installedVersion = Get-SPDscInstalledProductVersion
    if (($PSBoundParameters.ContainsKey("UseTLS") -eq $true) -and `
            $installedVersion.FileMajorPart -ne 16)
    {
        $message = "UseTLS is only supported in SharePoint 2016 and SharePoint 2019."
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if (($PSBoundParameters.ContainsKey("SMTPPort") -eq $true) -and `
            $installedVersion.FileMajorPart -ne 16)
    {
        $message = "SMTPPort is only supported in SharePoint 2016 and SharePoint 2019."
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]
        $webApp = Get-SPWebApplication -Identity $params.WebAppUrl `
            -IncludeCentralAdministration `
            -ErrorAction SilentlyContinue

        if ($null -eq $webApp)
        {
            return @{
                WebAppUrl      = $null
                SMTPServer     = $null
                FromAddress    = $null
                ReplyToAddress = $null
                CharacterSet   = $null
                UseTLS         = $null
                SMTPPort       = $null
            }
        }

        $mailServer = $null
        if ($null -ne $webApp.OutboundMailServiceInstance)
        {
            $mailServer = $webApp.OutboundMailServiceInstance.Server.Name
        }

        return @{
            WebAppUrl      = $webApp.Url
            SMTPServer     = $mailServer
            FromAddress    = $webApp.OutboundMailSenderAddress
            ReplyToAddress = $webApp.OutboundMailReplyToAddress
            CharacterSet   = $webApp.OutboundMailCodePage
            UseTLS         = $webApp.OutboundMailEnableSsl
            SMTPPort       = $webApp.OutboundMailPort
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
        [System.String]
        $SMTPServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $FromAddress,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ReplyToAddress,

        [Parameter(Mandatory = $true)]
        [System.String]
        $CharacterSet,

        [Parameter()]
        [System.Boolean]
        $UseTLS,

        [Parameter()]
        [System.UInt32]
        $SMTPPort,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting outgoing email settings configuration for $WebAppUrl"

    $installedVersion = Get-SPDscInstalledProductVersion
    if (($PSBoundParameters.ContainsKey("UseTLS") -eq $true) -and `
            $installedVersion.FileMajorPart -lt 16)
    {
        $message = "UseTLS is only supported in SharePoint 2016 and SharePoint 2019."
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if (($PSBoundParameters.ContainsKey("SMTPPort") -eq $true) -and `
            $installedVersion.FileMajorPart -lt 16)
    {
        $message = "SMTPPort is only supported in SharePoint 2016 and SharePoint 2019."
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $null = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]
        $webApp = $null

        Write-Verbose -Message "Retrieving $($params.WebAppUrl) settings"

        $webApp = Get-SPWebApplication $params.WebAppUrl -IncludeCentralAdministration
        if ($null -eq $webApp)
        {
            $message = "Web Application $webAppUrl not found"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }

        $installedVersion = Get-SPDscInstalledProductVersion
        switch ($installedVersion.FileMajorPart)
        {
            15
            {
                $webApp.UpdateMailSettings($params.SMTPServer, `
                        $params.FromAddress, `
                        $params.ReplyToAddress, `
                        $params.CharacterSet)
            }
            16
            {
                if ($params.ContainsKey("UseTLS") -eq $false)
                {
                    $UseTLS = $false
                }
                else
                {
                    $UseTLS = $params.UseTLS
                }

                if ($params.ContainsKey("SMTPPort") -eq $false)
                {
                    $SMTPPort = 25
                }
                else
                {
                    $SMTPPort = $params.SMTPPort
                }

                $webApp.UpdateMailSettings($params.SMTPServer, `
                        $params.FromAddress, `
                        $params.ReplyToAddress, `
                        $params.CharacterSet, `
                        $UseTLS, `
                        $SMTPPort)
            }
            default
            {
                $message = ("Detected an unsupported major version of SharePoint. SharePointDsc only " + `
                        "supports SharePoint 2013, 2016 or 2019.")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
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
        [System.String]
        $SMTPServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $FromAddress,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ReplyToAddress,

        [Parameter(Mandatory = $true)]
        [System.String]
        $CharacterSet,

        [Parameter()]
        [System.Boolean]
        $UseTLS,

        [Parameter()]
        [System.UInt32]
        $SMTPPort,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting outgoing email settings configuration for $WebAppUrl"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("SMTPServer",
        "FromAddress",
        "ReplyToAddress",
        "CharacterSet",
        "UseTLS",
        "SMTPPort")

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    Param(
        $WebAppUrl,
        $DependsOn
    )
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDSC" | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath "\DSCResources\MSFT_SPOutgoingEmailSettings\MSFT_SPOutgoingEmailSettings.psm1" -Resolve
    Import-Module $module
    $params = Get-DSCFakeParameters -ModulePath $module

    $params.WebAppUrl = $WebAppUrl
    $spMajorVersion = (Get-SPDscInstalledProductVersion).FileMajorPart
    if ($spMajorVersion.ToString() -ge "15" -and $params.Contains("UseTLS"))
    {
        $params.Remove("UseTLS")
    }
    if ($spMajorVersion.ToString() -ge "15" -and $params.Contains("SMTPPort"))
    {
        $params.Remove("SMTPPort")
    }

    $results = Get-TargetResource @params
    if ($null -eq $results["SMTPPort"])
    {
        $results.Remove("SMTPPort")
    }
    if ($null -eq $results["UseTLS"])
    {
        $results.Remove("UseTLS")
    }
    if ($null -eq $results["ReplyToAddress"])
    {
        $results["ReplyToAddress"] = "*"
    }
    if ($null -ne $results["SMTPServer"] -and "" -ne $results["SMTPServer"])
    {
        Write-Host "    -> Scanning Outgoing Email Settings"
        $Content += "        SPOutgoingEmailSettings " + [System.Guid]::NewGuid().ToString() + "`r`n"
        $Content += "        {`r`n"
        $results = Repair-Credentials -results $results
        if ($DependsOn)
        {
            $results.add("DependsOn", $DependsOn)
        }
        if ($null -eq $results.ReplyToAddress -or $results.ReplyToAddress -eq "")
        {
            $results.ReplyToAddress = "*"
        }
        $currentDSCBlock = Get-DSCBlock -Params $results -ModulePath $module
        $currentDSCBlock = Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock -ParameterName "PsDscRunAsCredential"
        $Content += $currentDSCBlock
        $Content += "        }`r`n"
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
