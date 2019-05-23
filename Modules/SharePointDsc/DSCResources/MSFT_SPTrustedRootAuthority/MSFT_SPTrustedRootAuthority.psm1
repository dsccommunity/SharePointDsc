function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [String]
        $CertificateFilePath,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose "Getting Trusted Root Authority with name '$Name'"

    if ($PSBoundParameters.ContainsKey("CertificateThumbprint") -and `
        $PSBoundParameters.ContainsKey("CertificateFilePath"))
    {
        Write-Verbose -Message ("Cannot use both parameters CertificateThumbprint and " + `
                                "CertificateFilePath at the same time.")
    }

    if (-not ($PSBoundParameters.ContainsKey("CertificateThumbprint")) -and `
        -not($PSBoundParameters.ContainsKey("CertificateFilePath")))
    {
        Write-Verbose -Message ("At least one of the following parameters must be specified: " + `
                                "CertificateThumbprint, CertificateFilePath.")
    }

    if ($PSBoundParameters.ContainsKey("CertificateFilePath"))
    {
        if (-not(Test-Path -Path $CertificateFilePath))
        {
            throw ("Specified CertificateFilePath does not exist: $CertificateFilePath")
        }
    }

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]

        $rootCert = Get-SPTrustedRootAuthority -Identity $params.Name -ErrorAction SilentlyContinue

        $ensure = "Absent"

        if ($null -eq $rootCert)
        {
            return @{
                Name                  = $params.Name
                CertificateThumbprint = [string]::Empty
                CertificateFilePath   = ""
                Ensure                = $ensure
            }
        }
        else
        {
            $ensure = "Present"

            return @{
                Name                  = $params.Name
                CertificateThumbprint = $rootCert.Certificate.Thumbprint
                CertificateFilePath   = ""
                Ensure                = $ensure
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
        $Name,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [String]
        $CertificateFilePath,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting SPTrustedRootAuthority '$Name'"

    if ($PSBoundParameters.ContainsKey("CertificateThumbprint") -and `
        $PSBoundParameters.ContainsKey("CertificateFilePath"))
    {
        throw ("Cannot use both parameters CertificateThumbprint and CertificateFilePath " + `
               "at the same time.")
    }

    if (-not ($PSBoundParameters.ContainsKey("CertificateThumbprint")) -and `
        -not($PSBoundParameters.ContainsKey("CertificateFilePath")))
    {
        throw ("At least one of the following parameters must be specified: " + `
               "CertificateThumbprint, CertificateFilePath.")
    }

    if ($PSBoundParameters.ContainsKey("CertificateFilePath"))
    {
        if (-not(Test-Path -Path $CertificateFilePath))
        {
            throw ("Specified CertificateFilePath does not exist: $CertificateFilePath")
        }
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters
    if ($Ensure -eq "Present" -and $CurrentValues.Ensure -eq "Present")
    {
        Write-Verbose -Message "Updating SPTrustedRootAuthority '$Name'"
        $null = Invoke-SPDscCommand -Credential $InstallAccount `
                                    -Arguments $PSBoundParameters `
                                    -ScriptBlock {
            $params = $args[0]

            if ($params.ContainsKey("CertificateThumbprint"))
            {
                Write-Verbose -Message "Importing certificate from CertificateThumbprint"
                $cert = Get-Item -Path "CERT:\LocalMachine\My\$($params.CertificateThumbprint)" `
                                 -ErrorAction SilentlyContinue

                if ($null -eq $cert)
                {
                    throw "Certificate not found in the local Certificate Store"
                }
            }

            if ($params.ContainsKey("CertificateFilePath"))
            {
                Write-Verbose -Message "Importing certificate from CertificateFilePath"
                try
                {
                    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
                    $cert.Import($CertificateFilePath)
                }
                catch
                {
                    throw "An error occured: $($_.Exception.Message)"
                }

                if ($null -eq $cert)
                {
                    throw "Import of certificate failed."
                }
            }

            if ($cert.HasPrivateKey)
            {
                Write-Verbose -Message "Certificate has private key. Removing private key."
                $pubKeyBytes = $cert.Export("cert")
                $cert2 = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
                $cert2.Import($pubKeyBytes)
                $cert = $cert2
            }

            Write-Verbose -Message "Updating Root Authority"
            Set-SPTrustedRootAuthority -Identity $params.Name -Certificate $cert
        }
    }

    if ($Ensure -eq "Present" -and $CurrentValues.Ensure -eq "Absent")
    {
        Write-Verbose -Message "Adding SPTrustedRootAuthority '$Name'"
        $null = Invoke-SPDscCommand -Credential $InstallAccount `
                                      -Arguments $PSBoundParameters `
                                      -ScriptBlock {
            $params = $args[0]

            if ($params.ContainsKey("CertificateThumbprint"))
            {
                Write-Verbose -Message "Importing certificate from CertificateThumbprint"
                $cert = Get-Item -Path "CERT:\LocalMachine\My\$($params.CertificateThumbprint)" `
                                 -ErrorAction SilentlyContinue

                if ($null -eq $cert)
                {
                    throw "Certificate not found in the local Certificate Store"
                }
            }

            if ($params.ContainsKey("CertificateFilePath"))
            {
                Write-Verbose -Message "Importing certificate from CertificateFilePath"
                try
                {
                    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
                    $cert.Import($CertificateFilePath)
                }
                catch
                {
                    throw "An error occured: $($_.Exception.Message)"
                }

                if ($null -eq $cert)
                {
                    throw "Import of certificate failed."
                }
            }

            if ($cert.HasPrivateKey)
            {
                Write-Verbose -Message "Certificate has private key. Removing private key."
                $pubKeyBytes = $cert.Export("cert")
                $cert2 = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
                $cert2.Import($pubKeyBytes)
                $cert = $cert2
            }

            Write-Verbose -Message "Creating Root Authority"
            New-SPTrustedRootAuthority -Name $params.Name -Certificate $cert
        }
    }
    if ($Ensure -eq "Absent")
    {
        Write-Verbose -Message "Removing SPTrustedRootAuthority '$Name'"
        $null = Invoke-SPDscCommand -Credential $InstallAccount `
                                      -Arguments $PSBoundParameters `
                                      -ScriptBlock {
            $params = $args[0]
            Remove-SPTrustedRootAuthority -Identity $params.Name `
                                          -ErrorAction SilentlyContinue
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
        $Name,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [String]
        $CertificateFilePath,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing SPTrustedRootAuthority '$Name'"

    if ($PSBoundParameters.ContainsKey("CertificateThumbprint") -and `
        $PSBoundParameters.ContainsKey("CertificateFilePath"))
    {
        throw ("Cannot use both parameters CertificateThumbprint and CertificateFilePath " + `
            "at the same time.")
    }

    if (-not ($PSBoundParameters.ContainsKey("CertificateThumbprint")) -and `
        -not($PSBoundParameters.ContainsKey("CertificateFilePath")))
    {
        throw ("At least one of the following parameters must be specified: " + `
            "CertificateThumbprint, CertificateFilePath.")
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($PSBoundParameters.ContainsKey("CertificateFilePath"))
    {
        Write-Verbose "Retrieving thumbprint of CertificateFilePath"
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
        $cert.Import($CertificateFilePath)

        Write-Verbose "Thumbprint is $($cert.Thumbprint)"
        $PSBoundParameters.CertificateThumbprint = $cert.Thumbprint
    }

    if ($Ensure -eq "Present")
    {
        return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                        -DesiredValues $PSBoundParameters `
                                        -ValuesToCheck @("Name","CertificateThumbprint","Ensure")
    }
    else
    {
         return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                        -DesiredValues $PSBoundParameters `
                                        -ValuesToCheck @("Name","Ensure")
    }
}

Export-ModuleMember -Function *-TargetResource
