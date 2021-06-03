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

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Default,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Intranet,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Internet,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Extranet,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Custom,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $DefaultSettings,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $IntranetSettings,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $InternetSettings,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $ExtranetSettings,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $CustomSettings,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting web application authentication for '$WebAppUrl'"

    $nullreturn = @{
        WebAppUrl        = $WebAppUrl
        Default          = $null
        Intranet         = $null
        Internet         = $null
        Extranet         = $null
        Custom           = $null
        DefaultSettings  = $null
        IntranetSettings = $null
        InternetSettings = $null
        ExtranetSettings = $null
        CustomSettings   = $null
    }

    if ($PSBoundParameters.ContainsKey("Default") -eq $false -and `
            $PSBoundParameters.ContainsKey("Intranet") -eq $false -and `
            $PSBoundParameters.ContainsKey("Internet") -eq $false -and `
            $PSBoundParameters.ContainsKey("Extranet") -eq $false -and `
            $PSBoundParameters.ContainsKey("Custom") -eq $false -and `
            $PSBoundParameters.ContainsKey("DefaultSettings") -eq $false -and `
            $PSBoundParameters.ContainsKey("IntranetSettings") -eq $false -and `
            $PSBoundParameters.ContainsKey("InternetSettings") -eq $false -and `
            $PSBoundParameters.ContainsKey("ExtranetSettings") -eq $false -and `
            $PSBoundParameters.ContainsKey("CustomSettings") -eq $false)
    {
        Write-Verbose -Message "You have to specify at least one parameter."
        return $nullreturn
    }

    if ($PSBoundParameters.ContainsKey("Default"))
    {
        $result = Test-Parameter -Zone $Default
        if ($result -eq $false)
        {
            return $nullreturn
        }
    }

    if ($PSBoundParameters.ContainsKey("Intranet"))
    {
        $result = Test-Parameter -Zone $Intranet
        if ($result -eq $false)
        {
            return $nullreturn
        }
    }

    if ($PSBoundParameters.ContainsKey("Internet"))
    {
        $result = Test-Parameter -Zone $Internet
        if ($result -eq $false)
        {
            return $nullreturn
        }
    }

    if ($PSBoundParameters.ContainsKey("Extranet"))
    {
        $result = Test-Parameter -Zone $Extranet
        if ($result -eq $false)
        {
            return $nullreturn
        }
    }

    if ($PSBoundParameters.ContainsKey("Custom"))
    {
        $result = Test-Parameter -Zone $Custom
        if ($result -eq $false)
        {
            return $nullreturn
        }
    }

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue
        if ($null -eq $wa)
        {
            Write-Verbose -Message "Specified web application not found!"
            return @{
                WebAppUrl        = $params.WebAppUrl
                Default          = $null
                Intranet         = $null
                Internet         = $null
                Extranet         = $null
                Custom           = $null
                DefaultSettings  = $null
                IntranetSettings = $null
                InternetSettings = $null
                ExtranetSettings = $null
                CustomSettings   = $null
            }
        }

        $zones = $wa.IisSettings.Keys
        $zoneConfig = @{}
        $zoneSettings = @{}

        foreach ($zone in $zones)
        {
            $zoneName = $zone.ToString()
            $zoneConfig.$zoneName = @()
            $zoneSettings.$zoneName = ""

            Write-Verbose -Message "Getting Zone Settings for zone '$zone'"
            $settings = @{
                AnonymousAuthentication    = $wa.IisSettings[$zone].AllowAnonymous
                CustomSignInPage           = $wa.IisSettings[$zone].ClaimsAuthenticationRedirectionUrl
                EnableClientIntegration    = $wa.IisSettings[$zone].EnableClientIntegration
                RequireUseRemoteInterfaces = $wa.IisSettings[$zone].ClientObjectModelRequiresUseRemoteAPIsPermission
            }

            $zoneSettings.$zoneName = $settings

            Write-Verbose -Message "Getting Authentication Methods for zone '$zone'"
            $authProviders = Get-SPAuthenticationProvider -WebApplication $params.WebAppUrl -Zone $zone
            if ($null -eq $authProviders)
            {
                $provider = @{
                    AuthenticationMethod   = "Classic"
                    WindowsAuthMethod      = $null
                    UseBasicAuth           = $null
                    AuthenticationProvider = $null
                    MembershipProvider     = $null
                    RoleProvider           = $null
                }

                $zoneConfig.$zoneName += $provider
            }
            else
            {
                foreach ($authProvider in $authProviders)
                {
                    $localAuthMode = $null
                    $windowsAuthMethod = $null
                    $basicAuth = $null
                    $authenticationProvider = $null
                    $roleProvider = $null
                    $membershipProvider = $null

                    if ($authProvider.ClaimProviderName -eq 'AD')
                    {
                        $localAuthMode = "WindowsAuthentication"
                        if ($authProvider.DisableKerberos -eq $true)
                        {
                            $windowsAuthMethod = "NTLM"
                        }
                        else
                        {
                            $windowsAuthMethod = "Kerberos"
                        }

                        if ($authProvider.UseBasicAuthentication -eq $true)
                        {
                            $basicAuth = $true
                        }
                        else
                        {
                            $basicAuth = $false
                        }
                    }
                    elseif ($authProvider.ClaimProviderName -eq 'Forms')
                    {
                        $localAuthMode = "FBA"
                        $roleProvider = $authProvider.RoleProvider
                        $membershipProvider = $authProvider.MembershipProvider
                    }
                    else
                    {
                        $localAuthMode = "Federated"
                        $authenticationProvider = $authProvider.DisplayName
                    }

                    $provider = @{
                        AuthenticationMethod   = $localAuthMode
                        WindowsAuthMethod      = $windowsAuthMethod
                        UseBasicAuth           = $basicAuth
                        AuthenticationProvider = $authenticationProvider
                        MembershipProvider     = $membershipProvider
                        RoleProvider           = $roleProvider
                    }

                    $zoneConfig.$zoneName += $provider
                }
            }
        }

        return @{
            WebAppUrl        = $params.WebAppUrl
            Default          = $zoneConfig.Default
            Intranet         = $zoneConfig.Intranet
            Internet         = $zoneConfig.Internet
            Extranet         = $zoneConfig.Extranet
            Custom           = $zoneConfig.Custom
            DefaultSettings  = $zoneSettings.Default
            IntranetSettings = $zoneSettings.Intranet
            InternetSettings = $zoneSettings.Internet
            ExtranetSettings = $zoneSettings.Extranet
            CustomSettings   = $zoneSettings.Custom
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

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Default,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Intranet,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Internet,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Extranet,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Custom,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $DefaultSettings,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $IntranetSettings,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $InternetSettings,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $ExtranetSettings,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $CustomSettings,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting web application authentication for '$WebAppUrl'"

    # Test is at least one zone is specified
    if ($PSBoundParameters.ContainsKey("Default") -eq $false -and `
            $PSBoundParameters.ContainsKey("Intranet") -eq $false -and `
            $PSBoundParameters.ContainsKey("Internet") -eq $false -and `
            $PSBoundParameters.ContainsKey("Extranet") -eq $false -and `
            $PSBoundParameters.ContainsKey("Custom") -eq $false -and `
            $PSBoundParameters.ContainsKey("DefaultSettings") -eq $false -and `
            $PSBoundParameters.ContainsKey("IntranetSettings") -eq $false -and `
            $PSBoundParameters.ContainsKey("InternetSettings") -eq $false -and `
            $PSBoundParameters.ContainsKey("ExtranetSettings") -eq $false -and `
            $PSBoundParameters.ContainsKey("CustomSettings") -eq $false)
    {
        $message = "You have to specify at least one parameter."
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    # Perform test on specified configurations for each zone
    if ($PSBoundParameters.ContainsKey("Default"))
    {
        Test-Parameter -Zone $Default -Exception
    }

    if ($PSBoundParameters.ContainsKey("Intranet"))
    {
        Test-Parameter -Zone $Intranet -Exception
    }

    if ($PSBoundParameters.ContainsKey("Internet"))
    {
        Test-Parameter -Zone $Internet -Exception
    }

    if ($PSBoundParameters.ContainsKey("Extranet"))
    {
        Test-Parameter -Zone $Extranet -Exception
    }

    if ($PSBoundParameters.ContainsKey("Custom"))
    {
        Test-Parameter -Zone $Custom -Exception
    }

    # Get current authentication method
    $authMethod = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue
        if ($null -eq $wa)
        {
            $message = "Specified Web Application $($params.WebAppUrl) does not exist"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }

        $authProviders = Get-SPAuthenticationProvider -WebApplication $params.WebAppUrl -Zone Default
        if ($null -eq $authProviders)
        {
            return "Classic"
        }
        else
        {
            return "Claims"
        }
    }

    # Check if web application is configured as Classic, but the config specifies a Claim model
    # This resource does not support Classic to Claims conversion.
    if ($authMethod -eq "Classic")
    {
        if ($PSBoundParameters.ContainsKey("Default"))
        {
            Test-ZoneIsNotClassic -Zone $Default
        }

        if ($PSBoundParameters.ContainsKey("Intranet"))
        {
            Test-ZoneIsNotClassic -Zone $Intranet
        }

        if ($PSBoundParameters.ContainsKey("Internet"))
        {
            Test-ZoneIsNotClassic -Zone $Internet
        }

        if ($PSBoundParameters.ContainsKey("Extranet"))
        {
            Test-ZoneIsNotClassic -Zone $Extranet
        }

        if ($PSBoundParameters.ContainsKey("Custom"))
        {
            Test-ZoneIsNotClassic -Zone $Custom
        }
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($Default)
    {
        # Test if current config matches desired config
        Write-Verbose -Message "Testing Authentication for Default zone"
        $result = Test-ZoneConfiguration -DesiredConfig $Default `
            -CurrentConfig $CurrentValues.Default

        # If that is the case, set desired config.
        if ($result -eq $false)
        {
            Write-Verbose -Message "Correcting Authentication for Default zone"
            Set-ZoneConfiguration -WebAppUrl $WebAppUrl -Zone "Default" -DesiredConfig $Default
        }
    }

    if ($DefaultSettings)
    {
        # Test if current config matches desired config
        Write-Verbose -Message "Testing Settings for Default zone"
        $result = Test-ZoneSettings -DesiredSettings $DefaultSettings `
            -CurrentSettings $CurrentValues.DefaultSettings

        # If that is the case, set desired config.
        if ($result -eq $false)
        {
            Write-Verbose -Message "Correcting Settings for Default zone"
            Set-ZoneSettings -WebAppUrl $WebAppUrl -Zone "Default" -DesiredSettings $DefaultSettings
        }
    }

    if ($Intranet)
    {
        # Check if specified zone exists
        if ($null -eq $CurrentValues.Intranet)
        {
            $message = "Specified zone Intranet does not exist"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }

        # Test if current config matches desired config
        Write-Verbose -Message "Testing Authentication for Intranet zone"
        $result = Test-ZoneConfiguration -DesiredConfig $Intranet `
            -CurrentConfig $CurrentValues.Intranet

        # If that is the case, set desired config.
        if ($result -eq $false)
        {
            Write-Verbose -Message "Correcting Authentication for Intranet zone"
            Set-ZoneConfiguration -WebAppUrl $WebAppUrl -Zone "Intranet" -DesiredConfig $Intranet
        }
    }

    if ($IntranetSettings)
    {
        # Check if specified zone exists
        if ($null -eq $CurrentValues.IntranetSettings)
        {
            $message = "Specified zone Intranet does not exist"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }

        # Test if current config matches desired config
        Write-Verbose -Message "Testing Settings for Intranet zone"
        $result = Test-ZoneSettings -DesiredSettings $IntranetSettings `
            -CurrentSettings $CurrentValues.IntranetSettings

        # If that is the case, set desired config.
        if ($result -eq $false)
        {
            Write-Verbose -Message "Correcting Settings for Intranet zone"
            Set-ZoneSettings -WebAppUrl $WebAppUrl -Zone "Intranet" -DesiredSettings $IntranetSettings
        }
    }

    if ($Internet)
    {
        # Check if specified zone exists
        if ($null -eq $CurrentValues.Internet)
        {
            $message = "Specified zone Internet does not exist"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }

        # Test if current config matches desired config
        Write-Verbose -Message "Testing Authentication for Internet zone"
        $result = Test-ZoneConfiguration -DesiredConfig $Internet `
            -CurrentConfig $CurrentValues.Internet

        # If that is the case, set desired config.
        if ($result -eq $false)
        {
            Write-Verbose -Message "Correcting Authentication for Internet zone"
            Set-ZoneConfiguration -WebAppUrl $WebAppUrl -Zone "Internet" -DesiredConfig $Internet
        }
    }

    if ($InternetSettings)
    {
        # Check if specified zone exists
        if ($null -eq $CurrentValues.InternetSettings)
        {
            $message = "Specified zone Internet does not exist"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }

        # Test if current config matches desired config
        Write-Verbose -Message "Testing Settings for Internet zone"
        $result = Test-ZoneSettings -DesiredSettings $InternetSettings `
            -CurrentSettings $CurrentValues.InternetSettings

        # If that is the case, set desired config.
        if ($result -eq $false)
        {
            Write-Verbose -Message "Correcting Settings for Internet zone"
            Set-ZoneSettings -WebAppUrl $WebAppUrl -Zone "Internet" -DesiredSettings $InternetSettings
        }
    }

    if ($Extranet)
    {
        # Check if specified zone exists
        if ($null -eq $CurrentValues.Extranet)
        {
            $message = "Specified zone Extranet does not exist"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }

        # Test if current config matches desired config
        Write-Verbose -Message "Testing Authentication for Extranet zone"
        $result = Test-ZoneConfiguration -DesiredConfig $Extranet `
            -CurrentConfig $CurrentValues.Extranet

        # If that is the case, set desired config.
        if ($result -eq $false)
        {
            Write-Verbose -Message "Correcting Authentication for Extranet zone"
            Set-ZoneConfiguration -WebAppUrl $WebAppUrl -Zone "Extranet" -DesiredConfig $Extranet
        }
    }

    if ($ExtranetSettings)
    {
        # Check if specified zone exists
        if ($null -eq $CurrentValues.ExtranetSettings)
        {
            $message = "Specified zone Extranet does not exist"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }

        # Test if current config matches desired config
        Write-Verbose -Message "Testing Settings for Extranet zone"
        $result = Test-ZoneSettings -DesiredSettings $ExtranetSettings `
            -CurrentSettings $CurrentValues.ExtranetSettings

        # If that is the case, set desired config.
        if ($result -eq $false)
        {
            Write-Verbose -Message "Correcting Settings for Extranet zone"
            Set-ZoneSettings -WebAppUrl $WebAppUrl -Zone "Extranet" -DesiredSettings $ExtranetSettings
        }
    }

    if ($Custom)
    {
        # Check if specified zone exists
        if ($null -eq $CurrentValues.Custom)
        {
            $message = "Specified zone Custom does not exist"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }

        # Test if current config matches desired config
        Write-Verbose -Message "Testing Authentication for Custom zone"
        $result = Test-ZoneConfiguration -DesiredConfig $Custom `
            -CurrentConfig $CurrentValues.Custom

        # If that is the case, set desired config.
        if ($result -eq $false)
        {
            Write-Verbose -Message "Correcting Authentication for Custom zone"
            Set-ZoneConfiguration -WebAppUrl $WebAppUrl -Zone "Custom" -DesiredConfig $Custom
        }
    }

    if ($CustomSettings)
    {
        # Check if specified zone exists
        if ($null -eq $CurrentValues.CustomSettings)
        {
            $message = "Specified zone Custom does not exist"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }

        # Test if current config matches desired config
        Write-Verbose -Message "Testing Settings for Custom zone"
        $result = Test-ZoneSettings -DesiredSettings $CustomSettings `
            -CurrentSettings $CurrentValues.CustomSettings

        # If that is the case, set desired config.
        if ($result -eq $false)
        {
            Write-Verbose -Message "Correcting Settings for Custom zone"
            Set-ZoneSettings -WebAppUrl $WebAppUrl -Zone "Custom" -DesiredSettings $CustomSettings
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

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Default,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Intranet,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Internet,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Extranet,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Custom,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $DefaultSettings,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $IntranetSettings,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $InternetSettings,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $ExtranetSettings,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $CustomSettings,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing web application authentication for '$WebAppUrl'"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($null -eq $CurrentValues.Default -and `
            $null -eq $CurrentValues.Intranet -and `
            $null -eq $CurrentValues.Internet -and `
            $null -eq $CurrentValues.Extranet -and `
            $null -eq $CurrentValues.Custom -and `
            $null -eq $CurrentValues.DefaultSettings -and `
            $null -eq $CurrentValues.IntranetSettings -and `
            $null -eq $CurrentValues.InternetSettings -and `
            $null -eq $CurrentValues.ExtranetSettings -and `
            $null -eq $CurrentValues.CustomSettings)
    {
        Write-Verbose -Message "Test-TargetResource returned false"
        return $false
    }

    if ($Default)
    {
        Write-Verbose -Message "Testing Authentication for Default zone"
        $result = Test-ZoneConfiguration -DesiredConfig $Default `
            -CurrentConfig $CurrentValues.Default `
            -ZoneName "Default"

        if ($result -eq $false)
        {
            Write-Verbose -Message "Parameter Default does not match Desired values"
            Write-Verbose -Message "Test-TargetResource returned false"
            return $false
        }
    }

    if ($DefaultSettings)
    {
        Write-Verbose -Message "Testing Settings for Default zone"
        $result = Test-ZoneSettings -DesiredSettings $DefaultSettings `
            -CurrentSettings $CurrentValues.DefaultSettings `
            -ZoneName "Default"

        if ($result -eq $false)
        {
            Write-Verbose -Message "Parameter DefaultSettings does not match Desired values"
            Write-Verbose -Message "Test-TargetResource returned false"
            return $false
        }
    }

    if ($Intranet)
    {
        Write-Verbose -Message "Testing Authentication for Intranet zone"
        if ($null -eq $CurrentValues.Intranet)
        {
            $message = "Specified zone Intranet does not exist"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }

        $result = Test-ZoneConfiguration -DesiredConfig $Intranet `
            -CurrentConfig $CurrentValues.Intranet `
            -ZoneName "Intranet"

        if ($result -eq $false)
        {
            Write-Verbose -Message "Parameter Intranet does not match Desired values"
            Write-Verbose -Message "Test-TargetResource returned false"
            return $false
        }
    }

    if ($IntranetSettings)
    {
        Write-Verbose -Message "Testing Settings for Intranet zone"
        if ($null -eq $CurrentValues.IntranetSettings)
        {
            $message = "Specified zone Intranet does not exist"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }

        $result = Test-ZoneSettings -DesiredSettings $IntranetSettings `
            -CurrentSettings $CurrentValues.IntranetSettings `
            -ZoneName "Intranet"

        if ($result -eq $false)
        {
            Write-Verbose -Message "Parameter IntranetSettings does not match Desired values"
            Write-Verbose -Message "Test-TargetResource returned false"
            return $false
        }
    }

    if ($Internet)
    {
        Write-Verbose -Message "Testing Authentication for Internet zone"
        if ($null -eq $CurrentValues.Internet)
        {
            $message = "Specified zone Internet does not exist"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }

        $result = Test-ZoneConfiguration -DesiredConfig $Internet `
            -CurrentConfig $CurrentValues.Internet `
            -ZoneName "Internet"

        if ($result -eq $false)
        {
            Write-Verbose -Message "Parameter Internet does not match Desired values"
            Write-Verbose -Message "Test-TargetResource returned false"
            return $false
        }
    }

    if ($InternetSettings)
    {
        Write-Verbose -Message "Testing Settings for Internet zone"
        if ($null -eq $CurrentValues.InternetSettings)
        {
            $message = "Specified zone Internet does not exist"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }

        $result = Test-ZoneSettings -DesiredSettings $InternetSettings `
            -CurrentSettings $CurrentValues.InternetSettings `
            -ZoneName "Internet"

        if ($result -eq $false)
        {
            Write-Verbose -Message "Parameter InternetSettings does not match Desired values"
            Write-Verbose -Message "Test-TargetResource returned false"
            return $false
        }
    }

    if ($Extranet)
    {
        Write-Verbose -Message "Testing Authentication for Extranet zone"
        if ($null -eq $CurrentValues.Extranet)
        {
            $message = "Specified zone Extranet does not exist"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }

        $result = Test-ZoneConfiguration -DesiredConfig $Extranet `
            -CurrentConfig $CurrentValues.Extranet `
            -ZoneName "Extranet"

        if ($result -eq $false)
        {
            Write-Verbose -Message "Parameter Extranet does not match Desired values"
            Write-Verbose -Message "Test-TargetResource returned false"
            return $false
        }
    }

    if ($ExtranetSettings)
    {
        Write-Verbose -Message "Testing Settings for Extranet zone"
        if ($null -eq $CurrentValues.ExtranetSettings)
        {
            $message = "Specified zone Extranet does not exist"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }

        $result = Test-ZoneSettings -DesiredSettings $ExtranetSettings `
            -CurrentSettings $CurrentValues.ExtranetSettings `
            -ZoneName "Extranet"

        if ($result -eq $false)
        {
            Write-Verbose -Message "Parameter ExtranetSettings does not match Desired values"
            Write-Verbose -Message "Test-TargetResource returned false"
            return $false
        }
    }

    if ($Custom)
    {
        Write-Verbose -Message "Testing Authentication for Custom zone"
        if ($null -eq $CurrentValues.Custom)
        {
            $message = "Specified zone Custom does not exist"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
            Write-Verbose -Message "Test-TargetResource returned false"
        }

        $result = Test-ZoneConfiguration -DesiredConfig $Custom `
            -CurrentConfig $CurrentValues.Custom `
            -ZoneName "Custom"

        if ($result -eq $false)
        {
            Write-Verbose -Message "Parameter Custom does not match Desired values"
            Write-Verbose -Message "Test-TargetResource returned false"
            return $false
        }
    }

    if ($CustomSettings)
    {
        Write-Verbose -Message "Testing Settings for Custom zone"
        if ($null -eq $CurrentValues.CustomSettings)
        {
            $message = "Specified zone Custom does not exist"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
            Write-Verbose -Message "Test-TargetResource returned false"
        }

        $result = Test-ZoneSettings -DesiredSettings $CustomSettings `
            -CurrentSettings $CurrentValues.CustomSettings `
            -ZoneName "Custom"

        if ($result -eq $false)
        {
            Write-Verbose -Message "Parameter CustomSettings does not match Desired values"
            Write-Verbose -Message "Test-TargetResource returned false"
            return $false
        }
    }

    Write-Verbose -Message "Test-TargetResource returned true"
    return $true
}

Export-ModuleMember -Function *-TargetResource

function Test-Parameter()
{
    param (
        [Parameter(Mandatory = $true)]
        $Zone,

        [Parameter()]
        [switch]
        $Exception
    )

    foreach ($zoneConfig in $Zone)
    {
        $authProviderUsed = $false
        $winAuthMethodUsed = $false
        $useBasicAuthUsed = $false
        $membProviderUsed = $false
        $roleProviderUsed = $false
        # Check if the config contains the AuthenticationProvider Property
        $prop = $zoneConfig.CimInstanceProperties | Where-Object -FilterScript {
            $_.Name -eq "AuthenticationProvider"
        }
        if ($null -ne $prop.Value)
        {
            $authProviderUsed = $true
        }

        # Check if the config contains the MembershipProvider Property
        $prop = $zoneConfig.CimInstanceProperties | Where-Object -FilterScript {
            $_.Name -eq "MembershipProvider"
        }
        if ($null -ne $prop.Value)
        {
            $membProviderUsed = $true
        }

        # Check if the config contains the WindowsAuthMethod Property
        $prop = $zoneConfig.CimInstanceProperties | Where-Object -FilterScript {
            $_.Name -eq "WindowsAuthMethod"
        }
        if ($null -ne $prop.Value)
        {
            $winAuthMethodUsed = $true
        }

        # Check if the config contains the UseBasicAuth Property
        $prop = $zoneConfig.CimInstanceProperties | Where-Object -FilterScript {
            $_.Name -eq "UseBasicAuth"
        }
        if ($null -ne $prop.Value)
        {
            $useBasicAuthUsed = $true
        }

        # Check if the config contains the MembershipProvider Property
        $prop = $zoneConfig.CimInstanceProperties | Where-Object -FilterScript {
            $_.Name -eq "MembershipProvider"
        }
        if ($null -ne $prop.Value)
        {
            $membProviderUsed = $true
        }

        # Check if the config contains the RoleProvider Property
        $prop = $zoneConfig.CimInstanceProperties | Where-Object -FilterScript {
            $_.Name -eq "RoleProvider"
        }
        if ($null -ne $prop.Value)
        {
            $roleProviderUsed = $true
        }

        switch ($zoneConfig.AuthenticationMethod)
        {
            "Classic"
            {
                $InstalledVersion = Get-SPDscInstalledProductVersion
                if ($InstalledVersion.FileMajorPart -ge 16)
                {
                    Write-Verbose ("AuthenticationMethod is set to Classic. Please note this " + `
                            "is unsupported for Production use in SharePoint 2016 and later")
                }
            }
            "WindowsAuthentication"
            {
                if ($winAuthMethodUsed -eq $false)
                {
                    $message = "You have to specify WindowsAuthMethod when " + `
                        "using WindowsAuthentication"
                    if ($Exception)
                    {
                        Add-SPDscEvent -Message $message `
                            -EntryType 'Error' `
                            -EventID 100 `
                            -Source $MyInvocation.MyCommand.Source
                        throw $message
                    }
                    else
                    {
                        Write-Verbose -Message $message
                        return $false
                    }
                }

                if ($authProviderUsed -eq $true -or `
                        $membProviderUsed -eq $true -or `
                        $roleProviderUsed -eq $true)
                {
                    $message = "You cannot use AuthenticationProvider, MembershipProvider " + `
                        "or RoleProvider when using WindowsAuthentication"
                    if ($Exception)
                    {
                        Add-SPDscEvent -Message $message `
                            -EntryType 'Error' `
                            -EventID 100 `
                            -Source $MyInvocation.MyCommand.Source
                        throw $message
                    }
                    else
                    {
                        Write-Verbose -Message $message
                        return $false
                    }
                }
            }
            "FBA"
            {
                if ($membProviderUsed -eq $false -or `
                        $roleProviderUsed -eq $false)
                {
                    $message = "You have to specify MembershipProvider and " + `
                        "RoleProvider when using FBA"
                    if ($Exception)
                    {
                        Add-SPDscEvent -Message $message `
                            -EntryType 'Error' `
                            -EventID 100 `
                            -Source $MyInvocation.MyCommand.Source
                        throw $message
                    }
                    else
                    {
                        Write-Verbose -Message $message
                        return $false
                    }
                }

                if ($winAuthMethodUsed -eq $true -or `
                        $useBasicAuthUsed -eq $true)
                {
                    $message = "You cannot use WindowsAuthMethod or UseBasicAuth " + `
                        "when using FBA"
                    if ($Exception)
                    {
                        Add-SPDscEvent -Message $message `
                            -EntryType 'Error' `
                            -EventID 100 `
                            -Source $MyInvocation.MyCommand.Source
                        throw $message
                    }
                    else
                    {
                        Write-Verbose -Message $message
                        return $false
                    }
                }

                if ($authProviderUsed -eq $true)
                {
                    $message = "You cannot use AuthenticationProvider when " + `
                        "using FBA"
                    if ($Exception)
                    {
                        Add-SPDscEvent -Message $message `
                            -EntryType 'Error' `
                            -EventID 100 `
                            -Source $MyInvocation.MyCommand.Source
                        throw $message
                    }
                    else
                    {
                        Write-Verbose -Message $message
                        return $false
                    }
                }
            }
            "Federated"
            {
                if ($membProviderUsed -eq $true -or `
                        $roleProviderUsed -eq $true)
                {
                    $message = "You cannot use MembershipProvider or " + `
                        "RoleProvider when using Federated"
                    if ($Exception)
                    {
                        Add-SPDscEvent -Message $message `
                            -EntryType 'Error' `
                            -EventID 100 `
                            -Source $MyInvocation.MyCommand.Source
                        throw $message
                    }
                    else
                    {
                        Write-Verbose -Message $message
                        return $false
                    }
                }

                if ($winAuthMethodUsed -eq $true -or `
                        $useBasicAuthUsed -eq $true)
                {
                    $message = "You cannot use WindowsAuthMethod or UseBasicAuth " + `
                        "when using Federated"
                    if ($Exception)
                    {
                        Add-SPDscEvent -Message $message `
                            -EntryType 'Error' `
                            -EventID 100 `
                            -Source $MyInvocation.MyCommand.Source
                        throw $message
                    }
                    else
                    {
                        Write-Verbose -Message $message
                        return $false
                    }
                }

                if ($authProviderUsed -eq $false)
                {
                    $message = "You have to specify AuthenticationProvider when " + `
                        "using Federated"
                    if ($Exception)
                    {
                        Add-SPDscEvent -Message $message `
                            -EntryType 'Error' `
                            -EventID 100 `
                            -Source $MyInvocation.MyCommand.Source
                        throw $message
                    }
                    else
                    {
                        Write-Verbose -Message $message
                        return $false
                    }
                }

            }
        }
    }
    if (-not $Exception)
    {
        return $true
    }
}

function Test-ZoneIsNotClassic()
{
    param (
        [Parameter(Mandatory = $true)]
        $Zone
    )

    foreach ($desiredAuth in $Zone)
    {
        if ($desiredAuth.AuthenticationMethod -ne "Classic")
        {
            $message = ("Specified Web Application is using Classic Authentication and " + `
                    "Claims Authentication is specified. Please use " + `
                    "Convert-SPWebApplication first!")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }
    }
}

function Set-ZoneConfiguration()
{
    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Default", "Intranet", "Internet", "Extranet", "Custom")]
        [System.String]
        $Zone,

        [Parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $DesiredConfig
    )

    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]

        $ap = @()

        foreach ($zoneConfig in $params.DesiredConfig)
        {
            switch ($zoneConfig.AuthenticationMethod)
            {
                "WindowsAuthentication"
                {
                    $apParams = @{
                        UseWindowsIntegratedAuthentication = $true
                    }

                    if ($zoneConfig.WindowsAuthMethod -eq "Kerberos")
                    {
                        $apParams.DisableKerberos = $false
                    }

                    if ($zoneConfig.UseBasicAuth -eq $true)
                    {
                        $apParams.UseBasicAuthentication = $true
                    }

                    $newap = New-SPAuthenticationProvider @apParams
                }
                "FBA"
                {
                    $newap = New-SPAuthenticationProvider -ASPNETMembershipProvider $zoneConfig.MembershipProvider `
                        -ASPNETRoleProviderName $zoneConfig.RoleProvider
                }
                "Federated"
                {
                    $tokenIssuer = Get-SPTrustedIdentityTokenIssuer -Identity $zoneConfig.AuthenticationProvider `
                        -ErrorAction SilentlyContinue
                    if ($null -eq $tokenIssuer)
                    {
                        $message = ("Specified AuthenticationProvider $($zoneConfig.AuthenticationProvider) " + `
                                "does not exist")
                        Add-SPDscEvent -Message $message `
                            -EntryType 'Error' `
                            -EventID 100 `
                            -Source $eventSource
                        throw $message
                    }
                    $newap = New-SPAuthenticationProvider -TrustedIdentityTokenIssuer $tokenIssuer
                }
            }
            $ap += $newap
        }

        Set-SPWebApplication -Identity $params.WebAppUrl -Zone $params.Zone -AuthenticationProvider $ap
    }
}

function Set-ZoneSettings()
{
    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Default", "Intranet", "Internet", "Extranet", "Custom")]
        [System.String]
        $Zone,

        [Parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance]
        $DesiredSettings
    )

    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl

        #Anonymous Authentication: True/False
        $prop = $params.DesiredSettings.CimInstanceProperties | Where-Object -FilterScript {
            $_.Name -eq "AnonymousAuthentication"
        }
        if ($null -ne $prop.Value)
        {
            Write-Verbose -Message ("Updating AnonymousAuthentication to " + `
                    "$($params.DesiredSettings.AnonymousAuthentication) for zone $($params.Zone)")
            $wa.IisSettings[$params.Zone].AllowAnonymous = $params.DesiredSettings.AnonymousAuthentication
        }

        #Custom Sign In Page (Empty string for default, URL for custom)
        $prop = $params.DesiredSettings.CimInstanceProperties | Where-Object -FilterScript {
            $_.Name -eq "CustomSignInPage"
        }
        if ($null -ne $prop.Value)
        {
            Write-Verbose -Message ("Updating CustomSignInPage to " + `
                    "$($params.DesiredSettings.CustomSignInPage) for zone $($params.Zone)")
            $wa.IisSettings[$params.Zone].ClaimsAuthenticationRedirectionUrl = $params.DesiredSettings.CustomSignInPage
        }

        #Require Use Remote Interfaces permission: True/False
        $prop = $params.DesiredSettings.CimInstanceProperties | Where-Object -FilterScript {
            $_.Name -eq "RequireUseRemoteInterfaces"
        }
        if ($null -ne $prop.Value)
        {
            Write-Verbose -Message ("Updating RequireUseRemoteInterfaces to " + `
                    "$($params.DesiredSettings.RequireUseRemoteInterfaces) for zone $($params.Zone)")
            $wa.IisSettings[$params.Zone].ClientObjectModelRequiresUseRemoteAPIsPermission = $params.DesiredSettings.RequireUseRemoteInterfaces
        }

        #Enable Client Integration
        $prop = $params.DesiredSettings.CimInstanceProperties | Where-Object -FilterScript {
            $_.Name -eq "EnableClientIntegration"
        }
        if ($null -ne $prop.Value)
        {
            Write-Verbose -Message ("Updating EnableClientIntegration to " + `
                    "$($params.DesiredSettings.EnableClientIntegration) for zone $($params.Zone)")
            $wa.IisSettings[$params.Zone].EnableClientIntegration = $params.DesiredSettings.EnableClientIntegration
        }

        Write-Verbose -Message "Committing changes to web application"
        $wa.Update()
    }
}

function Test-ZoneConfiguration()
{
    param (
        [Parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $DesiredConfig,

        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable[]]
        $CurrentConfig,

        [Parameter()]
        [System.String]
        $ZoneName
    )

    # Testing specified configuration against configured values
    foreach ($zoneConfig in $DesiredConfig)
    {
        switch ($zoneConfig.AuthenticationMethod)
        {
            "Classic"
            {
                $configuredMethod = $CurrentConfig | `
                        Where-Object -FilterScript {
                        $_.AuthenticationMethod -eq $zoneConfig.AuthenticationMethod
                    }
            }
            "WindowsAuthentication"
            {
                if ($null -eq $zoneConfig.UseBasicAuth)
                {
                    $configuredMethod = $CurrentConfig | `
                            Where-Object -FilterScript {
                            $_.AuthenticationMethod -eq $zoneConfig.AuthenticationMethod -and `
                                $_.WindowsAuthMethod -eq $zoneConfig.WindowsAuthMethod
                        }
                }
                else
                {
                    $configuredMethod = $CurrentConfig | `
                            Where-Object -FilterScript {
                            $_.AuthenticationMethod -eq $zoneConfig.AuthenticationMethod -and `
                                $_.WindowsAuthMethod -eq $zoneConfig.WindowsAuthMethod -and `
                                $_.UseBasicAuth -eq $zoneConfig.UseBasicAuth
                        }
                }
            }
            "FBA"
            {
                $configuredMethod = $CurrentConfig | `
                        Where-Object -FilterScript {
                        $_.AuthenticationMethod -eq $zoneConfig.AuthenticationMethod -and `
                            $_.MembershipProvider -eq $zoneConfig.MembershipProvider -and `
                            $_.RoleProvider -eq $zoneConfig.RoleProvider
                    }
            }
            "Federated"
            {
                $configuredMethod = $CurrentConfig | `
                        Where-Object -FilterScript {
                        $_.AuthenticationMethod -eq $zoneConfig.AuthenticationMethod -and `
                            $_.AuthenticationProvider -eq $zoneConfig.AuthenticationProvider
                    }
            }
        }

        if ($null -eq $configuredMethod)
        {
            if ($PSBoundParameters.ContainsKey('ZoneName') -eq $true)
            {
                $source = $MyInvocation.MyCommand.Source

                $EventMessage = "<SPDscEvent>`r`n"
                $EventMessage += "    <ConfigurationDrift Source=`"$source`">`r`n"

                $EventMessage += "        <ParametersNotInDesiredState>`r`n"
                foreach ($item in $CurrentConfig)
                {
                    $EventMessage += "            <AuthenticationMethod>`r`n"
                    foreach ($key in $item.Keys)
                    {
                        if (-not ([String]::IsNullOrEmpty($item.$key)))
                        {
                            $EventMessage += "                <Param Name=`"$($key)`">" + $item.$key + "</Param>`r`n"
                        }
                    }
                    $EventMessage += "            </AuthenticationMethod>`r`n"
                }
                $EventMessage += "        </ParametersNotInDesiredState>`r`n"
                $EventMessage += "    </ConfigurationDrift>`r`n"
                $EventMessage += "    <DesiredValues>`r`n"
                $EventMessage += "        <Zone>`r`n"
                $EventMessage += "            <ZoneName>$ZoneName</ZoneName>`r`n"
                foreach ($desired in $DesiredConfig)
                {
                    $EventMessage += "                <AuthenticationMethod>`r`n"
                    foreach ($prop in $desired.CimInstanceProperties)
                    {
                        $EventMessage += "                    <Param Name=`"$($prop.Name)`">" + $prop.Value + "</Param>`r`n"

                    }
                    $EventMessage += "                </AuthenticationMethod>`r`n"
                }
                $EventMessage += "        </Zone>`r`n"
                $EventMessage += "    </DesiredValues>`r`n"
                $EventMessage += "</SPDscEvent>"

                Add-SPDscEvent -Message $EventMessage -EntryType 'Error' -EventID 1 -Source $source
            }

            return $false
        }
    }

    # Reverse: Testing configured values against specified configuration
    foreach ($zoneConfig in $CurrentConfig)
    {
        switch ($zoneConfig.AuthenticationMethod)
        {
            "Classic"
            {
                $specifiedMethod = $DesiredConfig | `
                        Where-Object -FilterScript {
                        $_.AuthenticationMethod -eq $zoneConfig.AuthenticationMethod
                    }
            }
            "WindowsAuthentication"
            {
                $specifiedMethod = $DesiredConfig | `
                        Where-Object -FilterScript {
                        $_.AuthenticationMethod -eq $zoneConfig.AuthenticationMethod -and `
                            $_.WindowsAuthMethod -eq $zoneConfig.WindowsAuthMethod
                    }

                if ($null -ne $specifiedMethod.UseBasicAuth)
                {
                    $specifiedMethod = $specifiedMethod | `
                            Where-Object -FilterScript {
                            $_.UseBasicAuth -eq $zoneConfig.UseBasicAuth
                        }
                }
            }
            "FBA"
            {
                $specifiedMethod = $DesiredConfig | `
                        Where-Object -FilterScript {
                        $_.AuthenticationMethod -eq $zoneConfig.AuthenticationMethod -and `
                            $_.MembershipProvider -eq $zoneConfig.MembershipProvider -and `
                            $_.RoleProvider -eq $zoneConfig.RoleProvider
                    }
            }
            "Federated"
            {
                $specifiedMethod = $DesiredConfig | `
                        Where-Object -FilterScript {
                        $_.AuthenticationMethod -eq $zoneConfig.AuthenticationMethod -and `
                            $_.AuthenticationProvider -eq $zoneConfig.AuthenticationProvider
                    }
            }
        }

        if ($null -eq $specifiedMethod)
        {
            if ($PSBoundParameters.ContainsKey('ZoneName') -eq $true)
            {
                $source = $MyInvocation.MyCommand.Source

                $EventMessage = "<SPDscEvent>`r`n"
                $EventMessage += "    <ConfigurationDrift Source=`"$source`">`r`n"

                $EventMessage += "        <ParametersNotInDesiredState>`r`n"
                foreach ($item in $CurrentConfig)
                {
                    $EventMessage += "            <AuthenticationMethod>`r`n"
                    foreach ($key in $item.Keys)
                    {
                        if (-not ([String]::IsNullOrEmpty($item.$key)))
                        {
                            $EventMessage += "                <Param Name=`"$($key)`">" + $item.$key + "</Param>`r`n"
                        }
                    }
                    $EventMessage += "            </AuthenticationMethod>`r`n"
                }
                $EventMessage += "        </ParametersNotInDesiredState>`r`n"
                $EventMessage += "    </ConfigurationDrift>`r`n"
                $EventMessage += "    <DesiredValues>`r`n"
                $EventMessage += "        <Zone>`r`n"
                $EventMessage += "            <ZoneName>$ZoneName</ZoneName>`r`n"
                foreach ($desired in $DesiredConfig)
                {
                    $EventMessage += "                <AuthenticationMethod>`r`n"
                    foreach ($prop in $desired.CimInstanceProperties)
                    {
                        $EventMessage += "                    <Param Name=`"$($prop.Name)`">" + $prop.Value + "</Param>`r`n"

                    }
                    $EventMessage += "                </AuthenticationMethod>`r`n"
                }
                $EventMessage += "        </Zone>`r`n"
                $EventMessage += "    </DesiredValues>`r`n"
                $EventMessage += "</SPDscEvent>"

                Add-SPDscEvent -Message $EventMessage -EntryType 'Error' -EventID 1 -Source $source
            }

            return $false
        }
    }
    return $true
}

function Test-ZoneSettings()
{
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance]
        $DesiredSettings,

        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $CurrentSettings,

        [Parameter()]
        [System.String]
        $ZoneName
    )

    # Testing specified configuration against configured values
    $parametersNotInDesiredState = @()
    $prop = $DesiredSettings.CimInstanceProperties | Where-Object -FilterScript {
        $_.Name -eq "AnonymousAuthentication"
    }
    if ($null -ne $prop.Value)
    {
        if ($CurrentSettings.AnonymousAuthentication -ne $DesiredSettings.AnonymousAuthentication)
        {
            Write-Verbose "AnonymousAuthentication does not match"
            $parametersNotInDesiredState += "AnonymousAuthentication"
        }
    }

    $prop = $DesiredSettings.CimInstanceProperties | Where-Object -FilterScript {
        $_.Name -eq "CustomSignInPage"
    }
    if ($null -ne $prop.Value)
    {
        if ($CurrentSettings.CustomSignInPage -ne $DesiredSettings.CustomSignInPage)
        {
            Write-Verbose "CustomSignInPage does not match"
            $parametersNotInDesiredState += "CustomSignInPage"
        }
    }

    $prop = $DesiredSettings.CimInstanceProperties | Where-Object -FilterScript {
        $_.Name -eq "EnableClientIntegration"
    }
    if ($null -ne $prop.Value)
    {
        if ($CurrentSettings.EnableClientIntegration -ne $DesiredSettings.EnableClientIntegration)
        {
            Write-Verbose "EnableClientIntegration does not match"
            $parametersNotInDesiredState += "EnableClientIntegration"
        }
    }

    $prop = $DesiredSettings.CimInstanceProperties | Where-Object -FilterScript {
        $_.Name -eq "RequireUseRemoteInterfaces"
    }
    if ($null -ne $prop.Value)
    {
        if ($CurrentSettings.RequireUseRemoteInterfaces -ne $DesiredSettings.RequireUseRemoteInterfaces)
        {
            Write-Verbose "RequireUseRemoteInterfaces does not match"
            $parametersNotInDesiredState += "RequireUseRemoteInterfaces"
        }
    }

    if ($parametersNotInDesiredState.Count -ne 0)
    {
        if ($PSBoundParameters.ContainsKey('ZoneName') -eq $true)
        {
            $source = $MyInvocation.MyCommand.Source

            $EventMessage = "<SPDscEvent>`r`n"
            $EventMessage += "    <ConfigurationDrift Source=`"$source`">`r`n"

            $EventMessage += "        <ParametersNotInDesiredState>`r`n"
            foreach ($parameter in $parametersNotInDesiredState)
            {
                $EventMessage += "            <Parameter>`r`n"
                $EventMessage += "                <Param Name=`"$parameter`">" + $CurrentSettings.$parameter + "</Param>`r`n"
                $EventMessage += "            </Parameter>`r`n"
            }
            $EventMessage += "        </ParametersNotInDesiredState>`r`n"
            $EventMessage += "    </ConfigurationDrift>`r`n"
            $EventMessage += "    <DesiredValues>`r`n"
            $EventMessage += "        <Zone>`r`n"
            $EventMessage += "            <ZoneName>$ZoneName</ZoneName>`r`n"
            $EventMessage += "                <Parameter>`r`n"
            foreach ($prop in $DesiredSettings.CimInstanceProperties)
            {
                $EventMessage += "                    <Param Name=`"$($prop.Name)`">" + $prop.Value + "</Param>`r`n"

            }
            $EventMessage += "                </Parameter>`r`n"
            $EventMessage += "        </Zone>`r`n"
            $EventMessage += "    </DesiredValues>`r`n"
            $EventMessage += "</SPDscEvent>"

            Add-SPDscEvent -Message $EventMessage -EntryType 'Error' -EventID 1 -Source $source
        }

        return $false
    }

    return $true
}
