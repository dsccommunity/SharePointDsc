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
        $Name,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [String]
        $CertificateFilePath,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose "Getting Trusted Root Authority with name '$Name'"

    if (-not ($PSBoundParameters.ContainsKey("CertificateThumbprint")) -and `
            -not($PSBoundParameters.ContainsKey("CertificateFilePath")))
    {
        Write-Verbose -Message ("At least one of the following parameters must be specified: " + `
                "CertificateThumbprint, CertificateFilePath.")
    }

    if ($PSBoundParameters.ContainsKey("CertificateFilePath") -and `
            -not ($PSBoundParameters.ContainsKey("CertificateThumbprint")))
    {
        if (-not (Test-Path -Path $CertificateFilePath))
        {
            $message = ("Specified CertificateFilePath does not exist: $CertificateFilePath")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
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
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting SPTrustedRootAuthority '$Name'"

    if (-not ($PSBoundParameters.ContainsKey("CertificateThumbprint")) -and `
            -not($PSBoundParameters.ContainsKey("CertificateFilePath")))
    {
        $message = ("At least one of the following parameters must be specified: " + `
                "CertificateThumbprint, CertificateFilePath.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if ($PSBoundParameters.ContainsKey("CertificateFilePath") -and `
            -not ($PSBoundParameters.ContainsKey("CertificateThumbprint")))
    {
        if (-not (Test-Path -Path $CertificateFilePath))
        {
            $message = ("Specified CertificateFilePath does not exist: $CertificateFilePath")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters
    if ($Ensure -eq "Present" -and $CurrentValues.Ensure -eq "Present")
    {
        Write-Verbose -Message "Updating SPTrustedRootAuthority '$Name'"
        $null = Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
            -ScriptBlock {
            $params = $args[0]
            $eventSource = $args[1]

            if ($params.ContainsKey("CertificateFilePath"))
            {
                Write-Verbose -Message "Importing certificate from CertificateFilePath"
                try
                {
                    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
                    $cert.Import($params.CertificateFilePath)
                }
                catch
                {
                    $message = "An error occured: $($_.Exception.Message)"
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $eventSource
                    throw $message
                }

                if ($null -eq $cert)
                {
                    $message = "Import of certificate failed."
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $eventSource
                    throw $message
                }

                if ($params.ContainsKey("CertificateThumbprint"))
                {
                    if (-not $params.CertificateThumbprint.Equals($cert.Thumbprint))
                    {
                        $message = "Imported certificate thumbprint ($($cert.Thumbprint)) does not match expected thumbprint ($($params.CertificateThumbprint))."
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
                Write-Verbose -Message "Importing certificate from CertificateThumbprint"
                $cert = Get-Item -Path "CERT:\LocalMachine\My\$($params.CertificateThumbprint)" `
                    -ErrorAction SilentlyContinue

                if ($null -eq $cert)
                {
                    $message = "Certificate not found in the local Certificate Store"
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $eventSource
                    throw $message
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
            -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
            -ScriptBlock {
            $params = $args[0]
            $eventSource = $args[1]

            if ($params.ContainsKey("CertificateFilePath"))
            {
                Write-Verbose -Message "Importing certificate from CertificateFilePath"
                try
                {
                    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
                    $cert.Import($params.CertificateFilePath)
                }
                catch
                {
                    $message = "An error occured: $($_.Exception.Message)"
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $eventSource
                    throw $message
                }

                if ($null -eq $cert)
                {
                    $message = "Import of certificate failed."
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $eventSource
                    throw $message
                }

                if ($params.ContainsKey("CertificateThumbprint"))
                {
                    if (-not $params.CertificateThumbprint.Equals($cert.Thumbprint))
                    {
                        $message = "Imported certificate thumbprint ($($cert.Thumbprint)) does not match expected thumbprint ($($params.CertificateThumbprint))."
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
                Write-Verbose -Message "Importing certificate from CertificateThumbprint"
                $cert = Get-Item -Path "CERT:\LocalMachine\My\$($params.CertificateThumbprint)" `
                    -ErrorAction SilentlyContinue

                if ($null -eq $cert)
                {
                    $message = "Certificate not found in the local Certificate Store"
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $eventSource
                    throw $message
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
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing SPTrustedRootAuthority '$Name'"

    if (-not ($PSBoundParameters.ContainsKey("CertificateThumbprint")) -and `
            -not($PSBoundParameters.ContainsKey("CertificateFilePath")))
    {
        $message = ("At least one of the following parameters must be specified: " + `
                "CertificateThumbprint, CertificateFilePath.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if ($PSBoundParameters.ContainsKey("CertificateFilePath") -and `
            -not ($PSBoundParameters.ContainsKey("CertificateThumbprint")))
    {
        if (-not (Test-Path -Path $CertificateFilePath))
        {
            $message = ("Specified CertificateFilePath does not exist: $CertificateFilePath")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($PSBoundParameters.ContainsKey("CertificateFilePath") -and `
            -not ($PSBoundParameters.ContainsKey("CertificateThumbprint")))
    {
        Write-Verbose "Retrieving thumbprint of CertificateFilePath"
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
        $cert.Import($CertificateFilePath)

        Write-Verbose "Thumbprint is $($cert.Thumbprint)"
        $PSBoundParameters.CertificateThumbprint = $cert.Thumbprint
    }

    if ($Ensure -eq "Present")
    {
        $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("Name", "CertificateThumbprint", "Ensure")
    }
    else
    {
        $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("Name", "Ensure")
    }

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

Export-ModuleMember -Function *-TargetResource
