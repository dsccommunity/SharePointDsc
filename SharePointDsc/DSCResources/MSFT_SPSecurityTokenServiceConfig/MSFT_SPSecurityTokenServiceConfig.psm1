$script:SPDscUtilModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SharePointDsc.Util'
Import-Module -Name $script:SPDscUtilModulePath

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $NameIdentifier,

        [Parameter()]
        [System.Boolean]
        $UseSessionCookies = $false,

        [Parameter()]
        [System.Boolean]
        $AllowOAuthOverHttp = $false,

        [Parameter()]
        [System.Boolean]
        $AllowMetadataOverHttp = $false,

        [Parameter()]
        [System.Int32]
        $FormsTokenLifetime,

        [Parameter()]
        [System.Int32]
        $WindowsTokenLifetime,

        [Parameter()]
        [System.Int32]
        $LogonTokenCacheExpirationWindow,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Getting Security Token Service Configuration"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $config = Get-SPSecurityTokenServiceConfig

        if ($null -ne $config)
        {
            # Converting timespan values back to int32
            [Int32]$FormsTokenLifetime = $config.FormsTokenLifetime
            [Int32]$WindowsTokenLifetime = $config.WindowsTokenLifetime
            [Int32]$LogonTokenCacheExpirationWindow = $config.LogonTokenCacheExpirationWindow
            
            if ( ($params.LogonTokenCacheExpirationWindow -le $FormsTokenLifetime) -or ($params.LogonTokenCacheExpirationWindow -le $WindowsTokenLifetime) )
            {
                $message = ("Setting LogonTokenCacheExpirationWindow to a value lower or equal as WindowsTokenLifetime or FormsTokenLifetime ist not supported. " + `
                            "Please set LogonTokenCacheExpirationWindow to value higher than WindowsTokenLifetime and FormsTokenLifetime")
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $MyInvocation.MyCommand.Source
                    throw $message
            }
        }

        $nullReturn = @{
            IsSingleInstance                = "Yes"
            Name                            = $params.Name
            NameIdentifier                  = $params.NameIdentifier
            UseSessionCookies               = $params.UseSessionCookies
            AllowOAuthOverHttp              = $params.AllowOAuthOverHttp
            AllowMetadataOverHttp           = $params.AllowMetadataOverHttp
            FormsTokenLifetime              = $params.FormsTokenLifetime
            WindowsTokenLifetime            = $params.WindowsTokenLifetime
            LogonTokenCacheExpirationWindow = $params.LogonTokenCacheExpirationWindow
            Ensure                          = "Absent"
        }
        if ($null -eq $config)
        {
            return $nullReturn
        }

        return @{
            IsSingleInstance                = "Yes"
            Name                            = $config.Name
            NameIdentifier                  = $config.NameIdentifier
            UseSessionCookies               = $config.UseSessionCookies
            AllowOAuthOverHttp              = $config.AllowOAuthOverHttp
            AllowMetadataOverHttp           = $config.AllowMetadataOverHttp
            FormsTokenLifetime              = $FormsTokenLifetime
            WindowsTokenLifetime            = $WindowsTokenLifetime
            LogonTokenCacheExpirationWindow = $LogonTokenCacheExpirationWindow
            Ensure                          = "Present"
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
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $NameIdentifier,

        [Parameter()]
        [System.Boolean]
        $UseSessionCookies = $false,

        [Parameter()]
        [System.Boolean]
        $AllowOAuthOverHttp = $false,

        [Parameter()]
        [System.Boolean]
        $AllowMetadataOverHttp = $false,

        [Parameter()]
        [System.Int32]
        $FormsTokenLifetime,

        [Parameter()]
        [System.Int32]
        $WindowsTokenLifetime,

        [Parameter()]
        [System.Int32]
        $LogonTokenCacheExpirationWindow,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Setting Security Token Service Configuration"

    if ($Ensure -eq "Absent")
    {
        $message = ("This resource cannot undo Security Token Service Configuration changes. " + `
                "Please set Ensure to Present or omit the resource")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]
        $config = Get-SPSecurityTokenServiceConfig
        $config.Name = $params.Name

        if ($params.ContainsKey("NameIdentifier"))
        {
            $config.NameIdentifier = $params.NameIdentifier
        }

        if ($params.ContainsKey("UseSessionCookies"))
        {
            $config.UseSessionCookies = $params.UseSessionCookies
        }

        if ($params.ContainsKey("AllowOAuthOverHttp"))
        {
            $config.AllowOAuthOverHttp = $params.AllowOAuthOverHttp
        }

        if ($params.ContainsKey("AllowMetadataOverHttp"))
        {
            $config.AllowMetadataOverHttp = $params.AllowMetadataOverHttp
        }

        if ($params.ContainsKey("FormsTokenLifetime"))
        {
            $config.FormsTokenLifetime = (New-TimeSpan -Minutes $params.FormsTokenLifetime)
        }

        if ($params.ContainsKey("WindowsTokenLifetime"))
        {
            $config.WindowsTokenLifetime = (New-TimeSpan -Minutes $params.WindowsTokenLifetime)
        }

        if ($params.ContainsKey("LogonTokenCacheExpirationWindow"))
        {
            if ($params.ContainsKey("WindowsTokenLifetime") -or $params.ContainsKey("FormsTokenLifetime"))
            {
                if ( ($params.LogonTokenCacheExpirationWindow -le $params.WindowsTokenLifetime) -or ($params.LogonTokenCacheExpirationWindow -le $params.FormsTokenLifetime) )
                {
                    $message = ("Setting LogonTokenCacheExpirationWindow to a value lower or equal as WindowsTokenLifetime or FormsTokenLifetime ist not supported. " + `
                            "Please set LogonTokenCacheExpirationWindow to value higher than WindowsTokenLifetime and FormsTokenLifetime")
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $MyInvocation.MyCommand.Source
                    throw $message
                }
            }
            
            $config.LogonTokenCacheExpirationWindow = (New-TimeSpan -Minutes $params.LogonTokenCacheExpirationWindow)
        }

        $config.Update()
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $NameIdentifier,

        [Parameter()]
        [System.Boolean]
        $UseSessionCookies = $false,

        [Parameter()]
        [System.Boolean]
        $AllowOAuthOverHttp = $false,

        [Parameter()]
        [System.Boolean]
        $AllowMetadataOverHttp = $false,

        [Parameter()]
        [System.Int32]
        $FormsTokenLifetime,

        [Parameter()]
        [System.Int32]
        $WindowsTokenLifetime,

        [Parameter()]
        [System.Int32]
        $LogonTokenCacheExpirationWindow,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Testing the Security Token Service Configuration"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("Ensure",
        "NameIdentifier",
        "UseSessionCookies",
        "AllowOAuthOverHttp",
        "AllowMetadataOverHttp",
        "FormsTokenLifetime",
        "WindowsTokenLifetime",
        "LogonTokenCacheExpirationWindow")

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

Export-ModuleMember -Function *-TargetResource
