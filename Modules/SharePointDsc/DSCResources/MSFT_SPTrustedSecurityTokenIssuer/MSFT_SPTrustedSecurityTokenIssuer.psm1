function Get-TargetResource
{
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSDSCUseIdenticalMandatoryParametersForDSC", "", Justification  =  "Temporary workaround for issue introduced in PSSA v1.18")]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter()]
        [String]
        $Description,

        [Parameter(Mandatory = $true)]
        [String]
        $RegisteredIssuerNameIdentifier,
        
        [Parameter()]
        [String]
        $RegisteredIssuerNameRealm,

        [Parameter()]
        [String]
        $SigningCertificateThumbprint,

        [Parameter()]
        [String]
        $SigningCertificateFilePath,

        [Parameter()]
        [String]
        $MetadataEndPoint,

        [Parameter()]
        [System.Boolean]
        $IsTrustBroker = $true,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting SPTrustedSecurityTokenIssuer '$Name' settings"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]

        $spTrust = Get-SPTrustedSecurityTokenIssuer -Identity $params.Name `
                                                    -ErrorAction SilentlyContinue
        if ($spTrust)
        {
            $description                    = $spTrust.Description
            $registeredIssuerNameIdentifier = $spTrust.RegisteredIssuerName.Split("@")[0]
            $registeredIssuerNameRealm      = $spTrust.RegisteredIssuerName.Split("@")[1]
            $signingCertificateThumbprint   = $spTrust.SigningCertificate.Thumbprint
            $metadataEndPoint               = $spTrust.MetadataEndPoint.OriginalString
            $isTrustBroker                  = $spTrust.IsTrustBroker
            $currentState                   = "Present"
        }
        else
        {
            $description                    = ""
            $registeredIssuerNameIdentifier = ""
            $registeredIssuerNameRealm      = ""
            $signingCertificateThumbprint   = ""
            $metadataEndPoint               = ""
            $isTrustBroker                  = ""
            $currentState                   = "Absent"
        }

        return @{
            Name                           = $params.Name
            Description                    = $description
            RegisteredIssuerNameIdentifier = $registeredIssuerNameIdentifier
            RegisteredIssuerNameRealm      = $registeredIssuerNameRealm
            SigningCertificateThumbprin    = $signingCertificateThumbprint
            SigningCertificateFilePath     = ""
            MetadataEndPoint               = $metadataEndPoint
            IsTrustBroker                  = $isTrustBroker
            Ensure                         = $currentState
        }
    }
    return $result
}

function Set-TargetResource
{
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSDSCUseIdenticalMandatoryParametersForDSC", "", Justification  =  "Temporary workaround for issue introduced in PSSA v1.18")]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter()]
        [String]
        $Description,

        [Parameter(Mandatory = $true)]
        [String]
        $RegisteredIssuerNameIdentifier,
        
        [Parameter()]
        [String]
        $RegisteredIssuerNameRealm,

        [Parameter()]
        [String]
        $SigningCertificateThumbprint,

        [Parameter()]
        [String]
        $SigningCertificateFilePath,

        [Parameter()]
        [String]
        $MetadataEndPoint,

        [Parameter()]
        [System.Boolean]
        $IsTrustBroker = $true,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting SPTrustedSecurityTokenIssuer '$Name' settings"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($Ensure -eq "Present")
    {
        if ($CurrentValues.Ensure -eq "Absent")
        {
            if ($PSBoundParameters.ContainsKey("SigningCertificateThumbprint") -and `
                $PSBoundParameters.ContainsKey("SigningCertificateFilePath"))
            {
                throw ("Cannot use both parameters SigningCertificateThumbprint and SigningCertificateFilePath at the same time.")
                return
            }
            
            if ($PSBoundParameters.ContainsKey("SigningCertificateThumbprint") -and `
                $PSBoundParameters.ContainsKey("MetadataEndPoint"))
            {
                throw ("Cannot use both parameters SigningCertificateThumbprint and MetadataEndPoint at the same time.")
                return
            }

            if ($PSBoundParameters.ContainsKey("SigningCertificateFilePath") -and `
                $PSBoundParameters.ContainsKey("MetadataEndPoint"))
            {
                throw ("Cannot use both parameters SigningCertificateFilePath and MetadataEndPoint at the same time.")
                return
            }

            if ($PSBoundParameters.ContainsKey("SigningCertificateThumbprint") -eq $false -and `
                $PSBoundParameters.ContainsKey("SigningCertificateFilePath") -eq $false -and `
                $PSBoundParameters.ContainsKey("MetadataEndPoint") -eq $false)
            {
                throw ("At least one of the following parameters must be specified: " + `
                    "SigningCertificateThumbprint, SigningCertificateFilePath, MetadataEndPoint.")
                return
            }

            Write-Verbose -Message "Creating SPTrustedSecurityTokenIssuer '$Name'"
            $null = Invoke-SPDscCommand -Credential $InstallAccount `
                                        -Arguments $PSBoundParameters `
                                        -ScriptBlock {
                $params = $args[0]
                if ($params.SigningCertificateThumbprint)
                {
                    Write-Verbose -Message ("Getting signing certificate with thumbprint " + `
                        "$($params.SigningCertificateThumbprint) from the certificate store 'LocalMachine\My'")

                    if ($params.SigningCertificateThumbprint -notmatch "^[A-Fa-f0-9]{40}$")
                    {
                        throw ("Parameter SigningCertificateThumbprint does not match valid format '^[A-Fa-f0-9]{40}$'.")
                    }

                    $cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object -FilterScript {
                        $_.Thumbprint -match $params.SigningCertificateThumbprint
                    }

                    if (!$cert)
                    {
                        throw ("Signing certificate with thumbprint $($params.SigningCertificateThumbprint) " + `
                               "was not found in certificate store 'LocalMachine\My'.")
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
                        throw ("Signing certificate was not found in path '$($params.SigningCertificateFilePath)'.")
                    }
                }

                if ($null -eq $params.RegisteredIssuerNameRealm)
                {
                    Write-Verbose -Message "RegisteredIssuerNameRealm is not specified, use Get-SPAuthenticationRealm instead."
                    $registeredIssuerNameRealm = Get-SPAuthenticationRealm
                }

                $registeredIssuerName = "$($params.RegisteredIssuerNameIdentifier)@$registeredIssuerNameRealm"

                $runParams = @{}
                $runParams.Add("Name", $params.Name)
                $runParams.Add("Description", $params.Description)
                $runParams.Add("RegisteredIssuerName", $registeredIssuerName)
                $runParams.Add("Certificate", $cert)
                if ($params.IsTrustBroker -eq $true) {
                    $runParams.Add("IsTrustBroker", $null)
                }
                New-SPTrustedSecurityTokenIssuer @runParams
             }
        }
    }
    else
    {
        Write-Verbose "Removing SPTrustedSecurityTokenIssuer '$Name'"
        $null = Invoke-SPDscCommand -Credential $InstallAccount `
                                    -Arguments $PSBoundParameters `
                                    -ScriptBlock {
            $params = $args[0]

            $runParams = @{
                Identity = $params.Name
                Confirm = $false
            }

            Remove-SPTrustedSecurityTokenIssuer @runParams
        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSDSCUseIdenticalMandatoryParametersForDSC", "", Justification  =  "Temporary workaround for issue introduced in PSSA v1.18")]
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter()]
        [String]
        $Description,

        [Parameter(Mandatory = $true)]
        [String]
        $RegisteredIssuerNameIdentifier,
        
        [Parameter()]
        [String]
        $RegisteredIssuerNameRealm,

        [Parameter()]
        [String]
        $SigningCertificateThumbprint,

        [Parameter()]
        [String]
        $SigningCertificateFilePath,

        [Parameter()]
        [String]
        $MetadataEndPoint,

        [Parameter()]
        [System.Boolean]
        $IsTrustBroker = $true,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing SPTrustedSecurityTokenIssuer '$Name' settings"

    if ($PSBoundParameters.ContainsKey("SigningCertificateThumbprint") -and `
        $PSBoundParameters.ContainsKey("SigningCertificateFilePath"))
    {
        throw ("Cannot use both parameters SigningCertificateThumbprint and SigningCertificateFilePath at the same time.")
        return
    }

    if ($PSBoundParameters.ContainsKey("SigningCertificateThumbprint") -and `
        $PSBoundParameters.ContainsKey("MetadataEndPoint"))
    {
        throw ("Cannot use both parameters SigningCertificateThumbprint and MetadataEndPoint at the same time.")
        return
    }

    if ($PSBoundParameters.ContainsKey("SigningCertificateFilePath") -and `
        $PSBoundParameters.ContainsKey("MetadataEndPoint"))
    {
        throw ("Cannot use both parameters SigningCertificateFilePath and MetadataEndPoint at the same time.")
        return
    }

    if ($PSBoundParameters.ContainsKey("SigningCertificateThumbprint") -eq $false -and `
        $PSBoundParameters.ContainsKey("SigningCertificateFilePath") -eq $false -and `
        $PSBoundParameters.ContainsKey("MetadataEndPoint") -eq $false)
    {
        throw ("At least one of the following parameters must be specified: " + `
            "SigningCertificateThumbprint, SigningCertificateFilePath, MetadataEndPoint.")
        return
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @("Ensure")
}

Export-ModuleMember -Function *-TargetResource
