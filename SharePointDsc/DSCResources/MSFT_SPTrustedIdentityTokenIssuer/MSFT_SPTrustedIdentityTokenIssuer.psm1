function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter(Mandatory = $true)]
        [String]
        $Description,

        # SAML-specific
        [Parameter()]
        [String]
        $Realm,

        # SAML-specific
        [Parameter()]
        [String]
        $SignInUrl,

        [Parameter()]
        [String]
        $RegisteredIssuerName,

        # OIDC-specific
        [Parameter()]
        [String]
        $AuthorizationEndPointUri,

        # OIDC-specific
        [Parameter()]
        [String]
        $DefaultClientIdentifier,

        # OIDC-specific
        [Parameter()]
        [String]
        $SignOutUrl,

        [Parameter(Mandatory = $true)]
        [String]
        $IdentifierClaim,

        [Parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $ClaimsMappings,

        [Parameter()]
        [String]
        $SigningCertificateThumbprint,

        [Parameter()]
        [String]
        $SigningCertificateFilePath,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [String]
        $Ensure = "Present",

        [Parameter()]
        [String]
        $ClaimProviderName,

        [Parameter()]
        [String]
        $ProviderSignOutUri,

        # SAML-specific
        [Parameter()]
        [System.Boolean]
        $UseWReplyParameter = $false
    )

    Write-Verbose -Message "Getting SPTrustedIdentityTokenIssuer '$Name' settings"

    $result = Invoke-SPDscCommand -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $claimsMappings = @()
        $spTrust = Get-SPTrustedIdentityTokenIssuer -Identity $params.Name `
            -ErrorAction SilentlyContinue
        if ($spTrust)
        {
            $description = $spTrust.Description
            $realm = $spTrust.DefaultProviderRealm
            $signInUrl = $spTrust.ProviderUri.OriginalString
            $registeredIssuerName = $spTrust.RegisteredIssuerName
            if ($false -eq [String]::IsNullOrWhiteSpace($params.AuthorizationEndPointUri))
            {
                $authorizationEndPointUri = $spTrust.AuthorizationEndPointUri.ToString()
            }
            $defaultClientIdentifier = $spTrust.DefaultClientIdentifier
            $signOutUrl = $spTrust.SignOutUrl
            $identifierClaim = $spTrust.IdentityClaimTypeInformation.InputClaimType
            $SigningCertificateThumbprint = $spTrust.SigningCertificate.Thumbprint
            $currentState = "Present"
            $claimProviderName = $sptrust.ClaimProviderName
            if ($false -eq [String]::IsNullOrWhiteSpace($params.ProviderSignOutUri))
            {
                $providerSignOutUri = $sptrust.ProviderSignOutUri.OriginalString
            }
            $useWReplyParameter = $sptrust.UseWReplyParameter

            $spTrust.ClaimTypeInformation | ForEach-Object -Process {
                $claimsMappings = $claimsMappings + @{
                    Name              = $_.DisplayName
                    IncomingClaimType = $_.InputClaimType
                    LocalClaimType    = $_.MappedClaimType
                }
            }
        }
        else
        {
            $description = ""
            $realm = ""
            $signInUrl = ""
            $registeredIssuerName = ""
            $authorizationEndPointUri = ""
            $defaultClientIdentifier = ""
            $signOutUrl = ""
            $identifierClaim = ""
            $SigningCertificateThumbprint = ""
            $currentState = "Absent"
            $claimProviderName = ""
            $providerSignOutUri = ""
            $useWReplyParameter = $false
        }

        return @{
            Name                         = $params.Name
            Description                  = $description
            Realm                        = $realm
            SignInUrl                    = $signInUrl
            RegisteredIssuerName         = $registeredIssuerName
            AuthorizationEndPointUri     = $authorizationEndPointUri
            DefaultClientIdentifier      = $defaultClientIdentifier
            SignOutUrl                   = $signOutUrl
            IdentifierClaim              = $identifierClaim
            ClaimsMappings               = $claimsMappings
            SigningCertificateThumbprint = $SigningCertificateThumbprint
            SigningCertificateFilePath   = ""
            Ensure                       = $currentState
            ClaimProviderName            = $claimProviderName
            ProviderSignOutUri           = $providerSignOutUri
            UseWReplyParameter           = $useWReplyParameter
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
        [String]
        $Name,

        [Parameter(Mandatory = $true)]
        [String]
        $Description,

        # SAML-specific
        [Parameter()]
        [String]
        $Realm,

        # SAML-specific
        [Parameter()]
        [String]
        $SignInUrl,

        [Parameter()]
        [String]
        $RegisteredIssuerName,

        # OIDC-specific
        [Parameter()]
        [String]
        $AuthorizationEndPointUri,

        # OIDC-specific
        [Parameter()]
        [String]
        $DefaultClientIdentifier,

        # OIDC-specific
        [Parameter()]
        [String]
        $SignOutUrl,

        [Parameter(Mandatory = $true)]
        [String]
        $IdentifierClaim,

        [Parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $ClaimsMappings,

        [Parameter()]
        [String]
        $SigningCertificateThumbprint,

        [Parameter()]
        [String]
        $SigningCertificateFilePath,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [String]
        $Ensure = "Present",

        [Parameter()]
        [String]
        $ClaimProviderName,

        [Parameter()]
        [String]
        $ProviderSignOutUri,

        # SAML-specific
        [Parameter()]
        [System.Boolean]
        $UseWReplyParameter = $false
    )

    Write-Verbose -Message "Setting SPTrustedIdentityTokenIssuer '$Name' settings"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($Ensure -eq "Present")
    {
        if ($CurrentValues.Ensure -eq "Absent")
        {
            if ($true -eq $PSBoundParameters.ContainsKey("SigningCertificateThumbprint") -and
                $true -eq $PSBoundParameters.ContainsKey("SigningCertificateFilePath"))
            {
                $message = ("Cannot use both parameters SigningCertificateThumbprint and SigningCertificateFilePath at the same time.")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }

            if ($false -eq $PSBoundParameters.ContainsKey("SigningCertificateThumbprint") -and
                $false -eq $PSBoundParameters.ContainsKey("SigningCertificateFilePath"))
            {
                $message = ("At least one of the following parameters must be specified: " + `
                        "SigningCertificateThumbprint, SigningCertificateFilePath.")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }

            # Ensure that at least one parameter is specified between Realm (SAML trust) or DefaultClientIdentifier (OIDC trust)
            if ($false -eq $PSBoundParameters.ContainsKey("Realm") -and
                $false -eq $PSBoundParameters.ContainsKey("DefaultClientIdentifier"))
            {
                $message = ("At least one of the following parameters must be specified: " + `
                        "Realm (for SAML trust), DefaultClientIdentifier (for OIDC trust).")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }

            # Ensure that parameters Realm (SAML trust) or DefaultClientIdentifier (OIDC trust) are not both set
            if ($true -eq $PSBoundParameters.ContainsKey("Realm") -and
                $true -eq $PSBoundParameters.ContainsKey("DefaultClientIdentifier"))
            {
                $message = ("Parameters Realm (for SAML trust) and DefaultClientIdentifier (for OIDC trust) cannot be both set.")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }

            # SAML trust: If parameter Realm is set, then parameter SignInUrl is required
            if ($true -eq $PSBoundParameters.ContainsKey("Realm") -and
                $false -eq $PSBoundParameters.ContainsKey("SignInUrl"))
            {
                $message = ("Parameter Realm was set but SignInUrl is not set. Parameter SignInUrl required when Realm is set.")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }

            # OIDC trust: If parameter DefaultClientIdentifier is set,
            # then parameters AuthorizationEndPointUri, RegisteredIssuerName and SignOutUrl are required
            if ($true -eq $PSBoundParameters.ContainsKey("DefaultClientIdentifier") -and (
                    $false -eq $PSBoundParameters.ContainsKey("AuthorizationEndPointUri") -or
                    $false -eq $PSBoundParameters.ContainsKey("RegisteredIssuerName") -or
                    $false -eq $PSBoundParameters.ContainsKey("SignOutUrl") ))
            {
                $message = ("Parameter DefaultClientIdentifier was set but AuthorizationEndPointUri, RegisteredIssuerName or SignOutUrl are not set." + `
                        "Parameters AuthorizationEndPointUri, RegisteredIssuerName, DefaultClientIdentifier and SignOutUrl are required when DefaultClientIdentifier is set")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }

            $productVersion = Get-SPDscInstalledProductVersion
            if ($true -eq $PSBoundParameters.ContainsKey("DefaultClientIdentifier") -and
                $productVersion.FileMajorPart -eq 16 -and $productVersion.FileBuildPart -gt 13000)
            {
                $message = ("OIDC parameters can only be used with SharePoint Server Subscription Edition.")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }

            Write-Verbose -Message "Creating SPTrustedIdentityTokenIssuer '$Name'"
            $null = Invoke-SPDscCommand -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
                -ScriptBlock {
                $params = $args[0]
                $eventSource = $args[1]

                if ($params.SigningCertificateThumbprint)
                {
                    Write-Verbose -Message ("Getting signing certificate with thumbprint " + `
                            "$($params.SigningCertificateThumbprint) from the certificate store 'LocalMachine\My'")

                    if ($params.SigningCertificateThumbprint -notmatch "^[A-Fa-f0-9]{40}$")
                    {
                        $message = ("Parameter SigningCertificateThumbprint does not match valid format '^[A-Fa-f0-9]{40}$'.")
                        Add-SPDscEvent -Message $message `
                            -EntryType 'Error' `
                            -EventID 100 `
                            -Source $eventSource
                        throw $message
                    }

                    $cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object -FilterScript {
                        $_.Thumbprint -match $params.SigningCertificateThumbprint
                    }

                    if (!$cert)
                    {
                        $message = ("Signing certificate with thumbprint $($params.SigningCertificateThumbprint) " + `
                                "was not found in certificate store 'LocalMachine\My'.")
                        Add-SPDscEvent -Message $message `
                            -EntryType 'Error' `
                            -EventID 100 `
                            -Source $eventSource
                        throw $message
                    }

                    if ($cert.HasPrivateKey)
                    {
                        $message = ("SharePoint requires that the private key of the signing certificate" + `
                                " is not installed in the certificate store.")
                        Add-SPDscEvent -Message $message `
                            -EntryType 'Error' `
                            -EventID 100 `
                            -Source $eventSource
                        throw $message
                    }
                }
                else
                {
                    Write-Verbose -Message "Getting signing certificate from file system path '$($params.SigningCertificateFilePath)'"
                    try
                    {
                        $cert = New-Object -TypeName "System.Security.Cryptography.X509Certificates.X509Certificate2" `
                            -ArgumentList @($params.SigningCertificateFilePath)
                    }
                    catch
                    {
                        $message = ("Signing certificate was not found in path '$($params.SigningCertificateFilePath)'.")
                        Add-SPDscEvent -Message $message `
                            -EntryType 'Error' `
                            -EventID 100 `
                            -Source $eventSource
                        throw $message
                    }
                }

                $claimsMappingsArray = @()
                $params.ClaimsMappings | ForEach-Object -Process {
                    $runParams = @{ }
                    $runParams.Add("IncomingClaimTypeDisplayName", $_.Name)
                    $runParams.Add("IncomingClaimType", $_.IncomingClaimType)

                    if ($null -eq $_.LocalClaimType)
                    {
                        $runParams.Add("LocalClaimType", $_.IncomingClaimType)
                    }
                    else
                    {
                        $runParams.Add("LocalClaimType", $_.LocalClaimType)
                    }

                    $newMapping = New-SPClaimTypeMapping @runParams
                    $claimsMappingsArray += $newMapping
                }

                $mappings = ($claimsMappingsArray | Where-Object -FilterScript {
                        $_.InputClaimType -like $params.IdentifierClaim
                    })
                if ($null -eq $mappings)
                {
                    $message = ("IdentifierClaim does not match any claim type specified in ClaimsMappings.")
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $eventSource
                    throw $message
                }

                $oidcSetup = $false
                if ($false -eq [String]::IsNullOrWhiteSpace($params.RegisteredIssuerName))
                {
                    $oidcSetup = $true
                }

                $runParams = @{ }
                $runParams.Add("ImportTrustCertificate", $cert)
                $runParams.Add("Name", $params.Name)
                $runParams.Add("Description", $params.Description)

                if ($true -eq $oidcSetup)
                {
                    $runParams.Add("RegisteredIssuerName", $params.RegisteredIssuerName)
                    $runParams.Add("AuthorizationEndPointUri", $params.AuthorizationEndPointUri)
                    $runParams.Add("DefaultClientIdentifier", $params.DefaultClientIdentifier)
                    $runParams.Add("SignOutUrl", $params.SignOutUrl)
                }
                else
                {
                    $runParams.Add("Realm", $params.Realm)
                    $runParams.Add("SignInUrl", $params.SignInUrl)
                    $runParams.Add("UseWReply", $params.UseWReplyParameter)
                }

                $runParams.Add("IdentifierClaim", $params.IdentifierClaim)
                $runParams.Add("ClaimsMappings", $claimsMappingsArray)
                $trust = New-SPTrustedIdentityTokenIssuer @runParams

                if ($null -eq $trust)
                {
                    $message = "SharePoint failed to create the SPTrustedIdentityTokenIssuer."
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $eventSource
                    throw $message
                }

                if ($false -eq [String]::IsNullOrWhiteSpace($params.ClaimProviderName))
                {
                    $claimProvider = (Get-SPClaimProvider | Where-Object -FilterScript {
                            $_.DisplayName -eq $params.ClaimProviderName
                        })
                    if ($null -ne $claimProvider)
                    {
                        $trust.ClaimProviderName = $params.ClaimProviderName
                    }
                }

                if ($params.ProviderSignOutUri -and $false -eq $oidcSetup)
                {
                    $installedVersion = Get-SPDscInstalledProductVersion
                    # This property does not exist in SharePoint 2013
                    if ($installedVersion.FileMajorPart -ne 15)
                    {
                        $trust.ProviderSignOutUri = New-Object -TypeName System.Uri ($params.ProviderSignOutUri)
                    }
                }
                $trust.Update()
            }
        }
    }
    else
    {
        Write-Verbose "Removing SPTrustedIdentityTokenIssuer '$Name'"
        $null = Invoke-SPDscCommand -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]
            $Name = $params.Name
            # SPTrustedIdentityTokenIssuer must be removed from each zone of each web app before
            # it can be deleted
            Get-SPWebApplication | ForEach-Object -Process {
                $wa = $_
                $webAppUrl = $wa.Url
                $update = $false
                $urlZones = [Enum]::GetNames([Microsoft.SharePoint.Administration.SPUrlZone])
                $urlZones | ForEach-Object -Process {
                    $zone = $_
                    $providers = Get-SPAuthenticationProvider -WebApplication $wa.Url `
                        -Zone $zone `
                        -ErrorAction SilentlyContinue
                    if (!$providers)
                    {
                        return
                    }
                    $trustedProviderToRemove = $providers | Where-Object -FilterScript {
                        $_ -is [Microsoft.SharePoint.Administration.SPTrustedAuthenticationProvider] `
                            -and $_.LoginProviderName -like $params.Name
                    }
                    if ($trustedProviderToRemove)
                    {
                        Write-Verbose -Message ("Removing SPTrustedAuthenticationProvider " + `
                                "'$Name' from web app '$webAppUrl' in zone " + `
                                "'$zone'")
                        $wa.GetIisSettingsWithFallback($zone).ClaimsAuthenticationProviders.Remove($trustedProviderToRemove) | Out-Null
                        $update = $true
                    }
                }
                if ($update)
                {
                    $wa.Update()
                }
            }

            $runParams = @{
                Identity = $params.Name
                Confirm  = $false
            }
            Remove-SPTrustedIdentityTokenIssuer @runParams
        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter(Mandatory = $true)]
        [String]
        $Description,

        # SAML-specific
        [Parameter()]
        [String]
        $Realm,

        # SAML-specific
        [Parameter()]
        [String]
        $SignInUrl,

        [Parameter()]
        [String]
        $RegisteredIssuerName,

        # OIDC-specific
        [Parameter()]
        [String]
        $AuthorizationEndPointUri,

        # OIDC-specific
        [Parameter()]
        [String]
        $DefaultClientIdentifier,

        # OIDC-specific
        [Parameter()]
        [String]
        $SignOutUrl,

        [Parameter(Mandatory = $true)]
        [String]
        $IdentifierClaim,

        [Parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $ClaimsMappings,

        [Parameter()]
        [String]
        $SigningCertificateThumbprint,

        [Parameter()]
        [String]
        $SigningCertificateFilePath,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [String]
        $Ensure = "Present",

        [Parameter()]
        [String]
        $ClaimProviderName,

        [Parameter()]
        [String]
        $ProviderSignOutUri,

        # SAML-specific
        [Parameter()]
        [System.Boolean]
        $UseWReplyParameter = $false
    )

    Write-Verbose -Message "Testing SPTrustedIdentityTokenIssuer '$Name' settings"

    if ($true -eq $PSBoundParameters.ContainsKey("SigningCertificateThumbprint") -and
        $true -eq $PSBoundParameters.ContainsKey("SigningCertificateFilePath"))
    {
        $message = ("Cannot use both parameters SigningCertificateThumbprint and SigningCertificateFilePath at the same time.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if ($false -eq $PSBoundParameters.ContainsKey("SigningCertificateThumbprint") -and
        $false -eq $PSBoundParameters.ContainsKey("SigningCertificateFilePath"))
    {
        $message = ("At least one of the following parameters must be specified: " + `
                "SigningCertificateThumbprint, SigningCertificateFilePath.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    # Ensure that at least one parameter is specified between Realm (SAML trust) or DefaultClientIdentifier (OIDC trust)
    if ($false -eq $PSBoundParameters.ContainsKey("Realm") -and
        $false -eq $PSBoundParameters.ContainsKey("DefaultClientIdentifier"))
    {
        $message = ("At least one of the following parameters must be specified: " + `
                "Realm (for SAML trust), DefaultClientIdentifier (for OIDC trust).")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    # Ensure that parameters Realm (SAML trust) or DefaultClientIdentifier (OIDC trust) are not both set
    if ($true -eq $PSBoundParameters.ContainsKey("Realm") -and
        $true -eq $PSBoundParameters.ContainsKey("DefaultClientIdentifier"))
    {
        $message = ("Parameters Realm (for SAML trust) and DefaultClientIdentifier (for OIDC trust) cannot be both set.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    # SAML trust: If parameter Realm is set, then parameter SignInUrl is required
    if ($true -eq $PSBoundParameters.ContainsKey("Realm") -and
        $false -eq $PSBoundParameters.ContainsKey("SignInUrl"))
    {
        $message = ("Parameter Realm was set but SignInUrl is not set. Parameter SignInUrl required when Realm is set.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    # OIDC trust: If parameter DefaultClientIdentifier is set,
    # then parameters AuthorizationEndPointUri, RegisteredIssuerName and SignOutUrl are required
    if ($true -eq $PSBoundParameters.ContainsKey("DefaultClientIdentifier") -and (
            $false -eq $PSBoundParameters.ContainsKey("AuthorizationEndPointUri") -or
            $false -eq $PSBoundParameters.ContainsKey("RegisteredIssuerName") -or
            $false -eq $PSBoundParameters.ContainsKey("SignOutUrl") ))
    {
        $message = ("Parameter DefaultClientIdentifier was set but AuthorizationEndPointUri, RegisteredIssuerName or SignOutUrl are not set." + `
                "Parameters AuthorizationEndPointUri, RegisteredIssuerName, DefaultClientIdentifier and SignOutUrl are required when DefaultClientIdentifier is set")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $productVersion = Get-SPDscInstalledProductVersion
    if ($true -eq $PSBoundParameters.ContainsKey("DefaultClientIdentifier") -and
        ($productVersion.FileMajorPart -ne 16 -or $productVersion.FileBuildPart -le 13000))
    {
        $message = ("OIDC parameters can only be used with SharePoint Server Subscription Edition.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("Ensure")

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPTrustedIdentityTokenIssuer\MSFT_SPTrustedIdentityTokenIssuer.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module

    $tips = Get-SPTrustedIdentityTokenIssuer

    $i = 1
    $total = $tips.Length
    foreach ($tip in $tips)
    {
        try
        {
            $tokenName = $tip.Name
            Write-Host "Scanning Trusted Identity Token Issuer [$i/$total] {$tokenName}"

            $PartialContent = ''

            $params.Name = $tokenName
            $params.Description = $tip.Description

            $property = @{
                Handle = 0
            }
            $fake = New-CimInstance -ClassName Win32_Process -Property $property -Key Handle -ClientOnly

            if (!$params.Contains("ClaimsMappings"))
            {
                $params.Add("ClaimsMappings", $fake)
            }
            $results = Get-TargetResource @params

            $foundOne = $false
            foreach ($ctm in $results.ClaimsMappings)
            {
                $ctmResult = Get-SPDscClaimTypeMapping -params $ctm
                if ($null -ne $ctmResult)
                {
                    if (!$foundOne)
                    {
                        $PartialContent += "        `$members = @();`r`n"
                        $foundOne = $true
                    }
                    $PartialContent += "        `$members += " + $ctmResult + ";`r`n"
                }
            }

            if ($foundOne)
            {
                $results.ClaimsMappings = "`$members"
            }

            $PartialContent += "        SPTrustedIdentityTokenIssuer " + [System.Guid]::NewGuid().toString() + "`r`n"
            $PartialContent += "        {`r`n"

            if ($null -ne $results.Get_Item("SigningCertificateThumbprint") -and $results.Contains("SigningCertificateFilePath"))
            {
                $results.Remove("SigningCertificateFilePath")
            }

            $results = Repair-Credentials -results $results
            $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
            $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
            $PartialContent += $currentBlock
            $PartialContent += "        }`r`n"
            $Content += $PartialContent
            $i++
        }
        catch
        {
            $_
            $Global:ErrorLog += "[Trusted Identity Token Issuer]" + $tip.Name + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
