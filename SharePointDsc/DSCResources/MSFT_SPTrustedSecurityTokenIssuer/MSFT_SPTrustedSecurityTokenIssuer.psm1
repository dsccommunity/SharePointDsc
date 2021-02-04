$script:SPDscUtilModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SharePointDsc.Util'
Import-Module -Name $script:SPDscUtilModulePath

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter()]
        [String]
        $Description,

        [Parameter()]
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
        [ValidateSet("Present", "Absent")]
        [String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting SPTrustedSecurityTokenIssuer '$Name' settings"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]

        $spTrust = Get-SPTrustedSecurityTokenIssuer -Identity $params.Name `
            -ErrorAction SilentlyContinue

        if ($spTrust)
        {
            $description = $spTrust.Description
            $registeredIssuerNameIdentifier = $spTrust.RegisteredIssuerName.Split("@")[0]
            $registeredIssuerNameRealm = $spTrust.RegisteredIssuerName.Split("@")[1]
            $signingCertificateThumbprint = $spTrust.SigningCertificate.Thumbprint
            $metadataEndPoint = $spTrust.MetadataEndPoint.OriginalString
            # Get-SPTrustedSecurityTokenIssuer does not return a property IsTrustBroker. But value of property IsSelfIssuer is the complement of IsTrustBroker
            $isTrustBroker = $false
            if ($spTrust.IsSelfIssuer -eq $false)
            {
                $isTrustBroker = $true
            }
            $currentState = "Present"

            # If the signing certificate is specified to Get method from its filepath, it must be retrieved to compare its thumbprint with
            # the one set in the SPTrustedSecurityTokenIssuer ($signingCertificateThumbprint)
            if ($params.SigningCertificateFilePath)
            {
                Write-Verbose -Message "Getting signing certificate from file system path '$($params.SigningCertificateFilePath)'"
                $cert = $null
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

                if ($cert.Thumbprint -match $signingCertificateThumbprint)
                {
                    # Signing certificate is conform to the one specified
                    # Set signingCertificateThumbprint and signingCertificateFilePath to same value as passed to Get
                    # so that Test method sees this is conform
                    if (-not $params.SigningCertificateThumbprint)
                    {
                        $signingCertificateThumbprint = $cert.Thumbprint
                    }
                    $signingCertificateFilePath = $params.SigningCertificateFilePath
                    Write-Verbose -Message "Existing signing certificate in SPTrustedSecurityTokenIssuer '$($params.Name)' has the same thumbprint as the signing certificate passed in parameter, as expected."
                }
            }

            # If parameter RegisteredIssuerNameRealm is null, it means that registeredIssuerNameRealm of the existing trust should be equal to the SPAuthenticationRealm
            if ([string]::IsNullOrEmpty($params.RegisteredIssuerNameRealm))
            {
                $farmAuthenticationRealm = Get-SPAuthenticationRealm
                if ($registeredIssuerNameRealm -match $farmAuthenticationRealm)
                {
                    # RegisteredIssuerNameRealm in the SPTrustedSecurityTokenIssuer is conform to expected value (SPAuthenticationRealm)
                    # Set it to $params.RegisteredIssuerNameRealm so that Test method sees this is conform
                    $registeredIssuerNameRealm = $params.RegisteredIssuerNameRealm
                    Write-Verbose -Message "Existing registeredIssuerNameRealm in SPTrustedSecurityTokenIssuer '$($params.Name)' is set with the SPAuthenticationRealm of the farm, as expected."
                }
            }
        }
        else
        {
            $description = ""
            $registeredIssuerNameIdentifier = ""
            $registeredIssuerNameRealm = ""
            $signingCertificateThumbprint = ""
            $signingCertificateFilePath = ""
            $metadataEndPoint = ""
            $isTrustBroker = $false
            $currentState = "Absent"
        }

        return @{
            Name                           = $params.Name
            Description                    = $description
            RegisteredIssuerNameIdentifier = $registeredIssuerNameIdentifier
            RegisteredIssuerNameRealm      = $registeredIssuerNameRealm
            SigningCertificateThumbprint   = $signingCertificateThumbprint
            SigningCertificateFilePath     = $signingCertificateFilePath
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
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter()]
        [String]
        $Description,

        [Parameter()]
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
        [ValidateSet("Present", "Absent")]
        [String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting SPTrustedSecurityTokenIssuer '$Name' settings"

    $PSBoundParameters.IsTrustBroker = $IsTrustBroker

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($Ensure -eq "Present")
    {
        if ($PSBoundParameters.ContainsKey("SigningCertificateThumbprint") -and `
                $PSBoundParameters.ContainsKey("MetadataEndPoint"))
        {
            $message = ("Cannot use both parameters SigningCertificateThumbprint and MetadataEndPoint at the same time.")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }

        if ($PSBoundParameters.ContainsKey("SigningCertificateFilePath") -and `
                $PSBoundParameters.ContainsKey("MetadataEndPoint"))
        {
            $message = ("Cannot use both parameters SigningCertificateFilePath and MetadataEndPoint at the same time.")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }

        if ($PSBoundParameters.ContainsKey("SigningCertificateThumbprint") -eq $false -and `
                $PSBoundParameters.ContainsKey("SigningCertificateFilePath") -eq $false -and `
                $PSBoundParameters.ContainsKey("MetadataEndPoint") -eq $false)
        {
            $message = ("At least one of the following parameters must be specified: " + `
                    "SigningCertificateThumbprint, SigningCertificateFilePath, MetadataEndPoint.")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }

        if ($PSBoundParameters.ContainsKey("MetadataEndPoint") -and `
                $PSBoundParameters.ContainsKey("RegisteredIssuerNameIdentifier"))
        {
            $message = ("Cannot use both parameters MetadataEndPoint and RegisteredIssuerNameIdentifier at the same time.")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }

        if ($PSBoundParameters.ContainsKey("MetadataEndPoint") -and `
                $PSBoundParameters.ContainsKey("RegisteredIssuerNameRealm"))
        {
            $message = ("Cannot use both parameters MetadataEndPoint and RegisteredIssuerNameRealm at the same time.")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }

        $PSBoundParameters.Add("CurrentValues", $CurrentValues)


        $null = Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
            -ScriptBlock {
            $params = $args[0]
            $eventSource = $args[1]

            $runParams = @{ }
            if ($params.Description)
            {
                $runParams.Add("Description", $params.Description)
            }

            if ($params.IsTrustBroker -eq $true)
            {
                $runParams.Add("IsTrustBroker", $null)
            }

            if ($params.MetadataEndPoint)
            {
                # Configure OAuth trust automatically using metadata file specified in parameter MetadataEndPoint
                $runParams.Add("MetadataEndPoint", $params.MetadataEndPoint)
            }
            else
            {
                # Configure OAuth trust with specified certificate and a RegisteredIssuerName
                if ($params.SigningCertificateFilePath)
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
                    if ($params.SigningCertificateThumbprint)
                    {
                        if (-not ($params.SigningCertificateThumbprint -eq $cert.Thumbprint))
                        {
                            $message = "Imported certificate thumbprint ($($cert.Thumbprint)) does not match expected thumbprint ($($params.SigningCertificateThumbprint))."
                            Add-SPDscEvent -Message $message `
                                -EntryType 'Error' `
                                -EventID 100 `
                                -Source $eventSource
                            throw $message
                        }
                    }
                }
                else
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
                }

                if ([string]::IsNullOrEmpty($params.RegisteredIssuerNameRealm))
                {
                    Write-Verbose -Message "RegisteredIssuerNameRealm is not specified, use Get-SPAuthenticationRealm instead."
                    $registeredIssuerNameRealm = Get-SPAuthenticationRealm
                }
                else
                {
                    $registeredIssuerNameRealm = $params.RegisteredIssuerNameRealm
                }

                $registeredIssuerName = "$($params.RegisteredIssuerNameIdentifier)@$registeredIssuerNameRealm"

                $runParams.Add("RegisteredIssuerName", $registeredIssuerName)
                $runParams.Add("Certificate", $cert)
            }

            if ($params.CurrentValues.Ensure -eq "Absent")
            {
                $runParams.Add("Name", $params.Name)
                Write-Verbose -Message "Creating SPTrustedSecurityTokenIssuer '$($params.Name)'"
                New-SPTrustedSecurityTokenIssuer @runParams
            }
            else
            {
                $runParams.Add("Identity", $params.Name)
                $runParams.Add("Confirm", $false)
                Write-Verbose -Message "Updating SPTrustedSecurityTokenIssuer '$($params.Name)'"
                Write-Verbose -Message "New Values: $(Convert-SPDscHashtableToString -Hashtable $runParams)"
                Set-SPTrustedSecurityTokenIssuer @runParams
            }
        }
    }
    else
    {
        if ($CurrentValues.Ensure -eq "Present")
        {
            Write-Verbose "Removing SPTrustedSecurityTokenIssuer '$Name'"
            $null = Invoke-SPDscCommand -Credential $InstallAccount `
                -Arguments $PSBoundParameters `
                -ScriptBlock {
                $params = $args[0]

                $runParams = @{
                    Identity = $params.Name
                    Confirm  = $false
                }
                Remove-SPTrustedSecurityTokenIssuer @runParams
            }
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

        [Parameter()]
        [String]
        $Description,

        [Parameter()]
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
        [ValidateSet("Present", "Absent")]
        [String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing SPTrustedSecurityTokenIssuer '$Name' settings"

    $PSBoundParameters.Ensure = $Ensure
    $PSBoundParameters.IsTrustBroker = $IsTrustBroker

    if ($PSBoundParameters.ContainsKey("SigningCertificateThumbprint") -and `
            $PSBoundParameters.ContainsKey("MetadataEndPoint"))
    {
        $message = ("Cannot use both parameters SigningCertificateThumbprint and MetadataEndPoint at the same time.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if ($PSBoundParameters.ContainsKey("SigningCertificateFilePath") -and `
            $PSBoundParameters.ContainsKey("MetadataEndPoint"))
    {
        $message = ("Cannot use both parameters SigningCertificateFilePath and MetadataEndPoint at the same time.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if ($PSBoundParameters.ContainsKey("SigningCertificateThumbprint") -eq $false -and `
            $PSBoundParameters.ContainsKey("SigningCertificateFilePath") -eq $false -and `
            $PSBoundParameters.ContainsKey("MetadataEndPoint") -eq $false)
    {
        $message = ("At least one of the following parameters must be specified: " + `
                "SigningCertificateThumbprint, SigningCertificateFilePath, MetadataEndPoint.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if ($PSBoundParameters.ContainsKey("MetadataEndPoint") -and `
            $PSBoundParameters.ContainsKey("RegisteredIssuerNameIdentifier"))
    {
        $message = ("Cannot use both parameters MetadataEndPoint and RegisteredIssuerNameIdentifier at the same time.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if ($PSBoundParameters.ContainsKey("MetadataEndPoint") -and `
            $PSBoundParameters.ContainsKey("RegisteredIssuerNameRealm"))
    {
        $message = ("Cannot use both parameters MetadataEndPoint and RegisteredIssuerNameRealm at the same time.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    # If RegisteredIssuerNameRealm was not set, it won't be present in the $PSBoundParameters
    # But it must be added to be actually tested by Test-SPDscParameterState
    if ($PSBoundParameters.ContainsKey("RegisteredIssuerNameRealm") -eq $false)
    {
        $PSBoundParameters.Add("RegisteredIssuerNameRealm", "")
    }

    if ($PSBoundParameters.ContainsKey("SigningCertificateFilePath") -and `
            -not ($PSBoundParameters.ContainsKey("SigningCertificateThumbprint")))
    {
        Write-Verbose "Retrieving thumbprint of SigningCertificateThumbprint"
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
        $cert.Import($SigningCertificateFilePath)

        Write-Verbose "Thumbprint is $($cert.Thumbprint)"
        $PSBoundParameters.SigningCertificateThumbprint = $cert.Thumbprint
    }

    # If SigningCertificateThumbprint was not set, it won't be present in the $PSBoundParameters
    # Since it is set in the Get method, it must be added to be tested correctly by Test-SPDscParameterState
    if ($PSBoundParameters.ContainsKey("SigningCertificateThumbprint") -eq $false)
    {
        $PSBoundParameters.Add("SigningCertificateThumbprint", "")
    }

    # If SigningCertificateFilePath was not set, it won't be present in the $PSBoundParameters
    # Since it is set in the Get method, it must be added to be tested correctly by Test-SPDscParameterState
    if ($PSBoundParameters.ContainsKey("SigningCertificateFilePath") -eq $false)
    {
        $PSBoundParameters.Add("SigningCertificateFilePath", "")
    }

    # If MetadataEndPoint was not set, it won't be present in the $PSBoundParameters
    # But it must be added to be actually tested by Test-SPDscParameterState
    if ($PSBoundParameters.ContainsKey("MetadataEndPoint") -eq $false)
    {
        $PSBoundParameters.Add("MetadataEndPoint", "")
        $valuesToCheck = @("Ensure", "Description", "RegisteredIssuerNameIdentifier", "RegisteredIssuerNameRealm", "SigningCertificateThumbprint", "IsTrustBroker")
    }
    else
    {
        # If MetadataEndPoint is set, the only property that really matters is MetadataEndPoint
        $valuesToCheck = @("Ensure", "Description", "MetadataEndPoint", "IsTrustBroker")
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck $valuesToCheck

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

Export-ModuleMember -Function *-TargetResource
