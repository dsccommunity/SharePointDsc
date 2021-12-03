function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $CertificateFilePath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $CertificatePassword,

        [Parameter()]
        [ValidateSet('EndEntity', 'Intermediate', 'Pending', 'Root')]
        [System.String]
        $Store = 'EndEntity',

        [Parameter()]
        [System.Boolean]
        $Exportable,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Getting certificate"

    $PSBoundParameters.Store = $Store

    $installedVersion = Get-SPDscInstalledProductVersion
    if ($installedVersion.FileMajorPart -lt 16 -or `
            $installedVersion.ProductBuildPart -lt 13000)
    {
        $message = ("Certificate Management is not available in SharePoint 2019 or earlier")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if ((Test-Path -Path $PSBoundParameters.CertificateFilePath) -eq $false)
    {
        throw "CertificateFilePath '$($PSBoundParameters.CertificateFilePath)' not found"
    }

    # Check for PFX or CER
    $file = Get-ChildItem -Path $PSBoundParameters.CertificateFilePath
    switch ($file.Extension)
    {
        ".cer"
        {
            Write-Verbose "Specified CertificateFilePath is a CER file"
            if ($PSBoundParameters.ContainsKey("CertificatePassword"))
            {
                Write-Verbose "Specifying a CertificatePassword isn't required when CertificateFilePath is a CER file."
            }
        }
        ".pfx"
        {
            Write-Verbose "Specified CertificateFilePath is a PFX file"
            if ($PSBoundParameters.ContainsKey("CertificatePassword") -eq $false)
            {
                throw "You have to specify a CertificatePassword when CertificateFilePath is a PFX file."
            }
        }
        default
        {
            throw "Unsupported file extension. Please specify a PFX or CER file"
        }
    }

    $result = Invoke-SPDscCommand -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        try
        {
            $null = Get-SPFarm
        }
        catch
        {
            Write-Verbose -Message ("No local SharePoint farm was detected. Certificate " + `
                    "will not be applied")
            return @{
                CertificateFilePath = $params.CertificateFilePath
                Ensure              = "Absent"
            }
        }

        # Check for PFX or CER
        $file = Get-ChildItem -Path $params.CertificateFilePath
        switch ($file.Extension)
        {
            ".cer"
            {
                $isPFX = $false
                $certificateObject = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList $params.CertificateFilePath
            }
            ".pfx"
            {
                $isPFX = $true
                $certificateObject = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList $params.CertificateFilePath, $params.CertificatePassword.Password
            }
        }

        $thumbprint = $certificateObject.Thumbprint
        $spCertificate = Get-SPCertificate -Thumbprint $thumbprint -ErrorAction SilentlyContinue

        $result = @{
            CertificateFilePath = $params.CertificateFilePath
        }

        if ($null -ne $spCertificate)
        {
            if ($spCertificate -isnot [Array])
            {
                Write-Verbose "Certificate with thumbprint $thumbprint found in SharePoint"
                if ($spCertificate.HasPrivateKey -eq $false -and $isPFX -eq $true)
                {
                    Write-Verbose ("Discovered certificate does not have a private key and the " + `
                            "specified CertificateFilePath is a PFX. Returning Absent.")
                    $result.Ensure = "Absent"
                }
                else
                {
                    $result.CertificatePassword = $params.CertificatePassword
                    $result.Store = $spCertificate.StoreType
                    $result.Exportable = $spCertificate.Exportable
                    $result.Ensure = "Present"
                }
            }
            else
            {
                Write-Verbose "Multiple certificates with thumbprint $thumbprint found in SharePoint"
                Write-Verbose "Checking for correct certificate"
                $spCertificate = $spCertificate | Where-Object -FilterScript {
                    $_.StoreType -eq $params.Store
                }

                if ($null -eq $spCertificate)
                {
                    Write-Verbose "Correct certificate not found, returning Absent"
                    $result.Ensure = "Absent"
                }
                else
                {
                    if ($spCertificate.HasPrivateKey -eq $false -and $isPFX -eq $true)
                    {
                        Write-Verbose ("Discovered certificate does not have a private key and the " + `
                                "specified CertificateFilePath is a PFX. Returning Absent.")
                        $result.Ensure = "Absent"
                    }
                    else
                    {
                        Write-Verbose "Correct certificate found, returning Present"
                        $result.Store = $spCertificate.StoreType
                        $result.Exportable = $spCertificate.Exportable
                        $result.Ensure = "Present"
                    }
                }
            }
        }
        else
        {
            Write-Verbose "Certificate with thumbprint $thumbprint not found in SharePoint"
            $result.Ensure = "Absent"
        }

        return $result
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
        $CertificateFilePath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $CertificatePassword,

        [Parameter()]
        [ValidateSet('EndEntity', 'Intermediate', 'Pending', 'Root')]
        [System.String]
        $Store = 'EndEntity',

        [Parameter()]
        [System.Boolean]
        $Exportable,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Setting certificate"

    $PSBoundParameters.Store = $Store
    $PSBoundParameters.Ensure = $Ensure

    $installedVersion = Get-SPDscInstalledProductVersion
    if ($installedVersion.FileMajorPart -lt 16 -or `
            $installedVersion.ProductBuildPart -lt 13000)
    {
        $message = ("Certificate Management is not available in SharePoint 2019 or earlier")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if ((Test-Path -Path $PSBoundParameters.CertificateFilePath) -eq $false)
    {
        $message = ("CertificateFilePath '$($PSBoundParameters.CertificateFilePath)' not found")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    # Check for PFX or CER
    $file = Get-ChildItem -Path $PSBoundParameters.CertificateFilePath
    switch ($file.Extension)
    {
        ".cer"
        {
            Write-Verbose "Specified CertificateFilePath is a CER file"
            if ($PSBoundParameters.ContainsKey("CertificatePassword"))
            {
                Write-Verbose ("Specifying a CertificatePassword isn't required when " + `
                        "CertificateFilePath is a CER file.")
            }
        }
        ".pfx"
        {
            Write-Verbose "Specified CertificateFilePath is a PFX file"
            if ($PSBoundParameters.ContainsKey("CertificatePassword") -eq $false)
            {
                $message = ("You have to specify a CertificatePassword when " + `
                        "CertificateFilePath is a PFX file.")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
        }
        default
        {
            $message = "Unsupported file extension. Please specify a PFX or CER file."
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }
    }

    Invoke-SPDscCommand -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]

        try
        {
            $null = Get-SPFarm
        }
        catch
        {
            $message = "No local SharePoint farm was detected. Antivirus settings will not be applied"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }

        # Check for PFX or CER
        Write-Verbose "Reading certificate thumbprint from CertificateFilePath"
        $file = Get-ChildItem -Path $params.CertificateFilePath
        switch ($file.Extension)
        {
            ".cer"
            {
                $isPFX = $false
                $certificateObject = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList $params.CertificateFilePath
            }
            ".pfx"
            {
                $isPFX = $true
                $certificateObject = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList $params.CertificateFilePath, $params.CertificatePassword.Password
            }
        }

        $thumbprint = $certificateObject.Thumbprint
        $spCertificate = Get-SPCertificate -Thumbprint $thumbprint -ErrorAction SilentlyContinue

        if ($params.Ensure -eq 'Present')
        {
            $runImport = $false
            if ($null -ne $spCertificate)
            {
                if ($spCertificate -isnot [Array])
                {
                    Write-Verbose "Certificate with thumbprint $thumbprint found in SharePoint"
                    if ($isPFX)
                    {
                        if ($spCertificate.HasPrivateKey -eq $false)
                        {
                            Write-Verbose -Message ("Discovered certificate does not have a private " + `
                                    "key and the specified CertificateFilePath is a PFX. Importing PFX.")
                            $runImport = $true
                        }
                        elseif ($params.Store -ne $spCertificate.StoreType)
                        {
                            Write-Verbose -Message "Moving certificate to store $($params.Store)"
                            Move-SPCertificate -Identity $spCertificate -NewStore $params.Store
                        }
                    }
                    else
                    {
                        if ($params.Store -ne $spCertificate.StoreType)
                        {
                            if ($spCertificate.HasPrivateKey -eq $true)
                            {
                                Write-Verbose -Message ("Discovered certificate has a private key, the " + `
                                        "specified CertificateFilePath is a CER and specified store " + `
                                        "is different. Importing CER.")
                                $runImport = $true
                            }
                            else
                            {
                                Write-Verbose -Message "Moving certificate to store $($params.Store)"
                                Move-SPCertificate -Identity $spCertificate -NewStore $params.Store
                            }
                        }
                    }
                }
                else
                {
                    Write-Verbose "Multiple certificates with thumbprint $thumbprint found in SharePoint"
                    Write-Verbose "Checking for correct certificate"
                    $spCertificate = $spCertificate | Where-Object -FilterScript {
                        $_.StoreType -eq $params.Store
                    }

                    if ($null -eq $spCertificate)
                    {
                        Write-Verbose "Correct certificate not found, importing certificate"
                        $runImport = $true
                    }
                    else
                    {
                        Write-Verbose "Correct certificate found"
                        if ($spCertificate.HasPrivateKey -eq $false -and $isPFX -eq $true)
                        {
                            Write-Verbose ("Discovered certificate does not have a private key and the " + `
                                    "specified CertificateFilePath is a PFX. Importing PFX.")
                            $runImport = $true
                        }
                    }
                }
            }
            else
            {
                Write-Verbose "Certificate with thumbprint $thumbprint not found in SharePoint. Importing file."
                $runImport = $true
            }

            if ($runImport -eq $true)
            {
                $certParams = @{
                    Path  = $params.CertificateFilePath
                    Store = $params.Store
                }

                if ($params.ContainsKey("CertificatePassword"))
                {
                    $certParams.Password = $params.CertificatePassword.Password
                }

                if ($params.ContainsKey("Exportable"))
                {
                    $certParams.Exportable = $params.Exportable
                }
                Write-Verbose "Running Import-SPCertificate with parameters: $(Convert-SPDscHashtableToString -Hashtable $certParams)"
                Import-SPCertificate @certParams
            }
        }
        else
        {
            if ($null -ne $spCertificate)
            {
                Write-Verbose "Certificate with thumbprint $thumbprint found. Removing certificate"
                Write-Verbose "Checking for correct certificate store"
                $spCertificate = $spCertificate | Where-Object -FilterScript {
                    $_.StoreType -eq $params.Store
                }

                if ($null -ne $spCertificate)
                {
                    Write-Verbose "Correct certificate found, removing certificate"
                    Remove-SPCertificate -Identity $spCertificate -Confirm:$false
                }
                else
                {
                    Write-Verbose "Certificate with thumbprint $thumbprint NOT found."
                }
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
        $CertificateFilePath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $CertificatePassword,

        [Parameter()]
        [ValidateSet('EndEntity', 'Intermediate', 'Pending', 'Root')]
        [System.String]
        $Store = 'EndEntity',

        [Parameter()]
        [System.Boolean]
        $Exportable,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Testing certificate"

    $PSBoundParameters.Store = $Store
    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($Ensure -eq 'Present')
    {
        $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck (
            "Store",
            "Ensure"
        )
    }
    else
    {
        $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck (
            "Ensure"
        )
    }

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"

    $installedVersion = Get-SPDscInstalledProductVersion
    if ($installedVersion.FileMajorPart -eq 16 -and `
            $installedVersion.ProductBuildPart -gt 13000)
    {
        $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
        $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPCertificate\MSFT_SPCertificate.psm1" -Resolve

        $Content = ''
        $params = Get-DSCFakeParameters -ModulePath $module

        $certificates = Get-SPCertificate

        $password = $global:spFarmAccount.Password

        foreach ($certificate in $certificates)
        {
            $exportPath = Join-Path -Path (Get-Location) -ChildPath ($certificate.Subject -replace 'CN=')
            if ($certificate.HasPrivateKey -eq $true -and $certificate.Exportable -eq $true)
            {
                $exportFilePath = "$exportPath.pfx"
                Export-SPCertificate -Identity $certificate -Password $password -Path $exportFilePath -Force
            }
            else
            {
                $exportFilePath = "$exportPath.cer"
                Export-SPCertificate -Identity $certificate -Type 'Cert' -Path $exportFilePath -Force
            }

            $params.CertificateFilePath = $exportFilePath
            $params.Store = $certificate.StoreType

            $PartialContent = "        SPCertificate " + [System.Guid]::NewGuid().ToString() + "`r`n"
            $PartialContent += "        {`r`n"
            $results = Get-TargetResource @params
            $results = Repair-Credentials -results $results
            $results.CertificatePassword = Resolve-Credentials -UserName $global:spFarmAccount.UserName
            $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
            $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "CertificatePassword"
            $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
            $PartialContent += $currentBlock
            $PartialContent += "        }`r`n"

            $Content += $PartialContent
        }

        return $Content
    }
}

Export-ModuleMember -Function *-TargetResource
