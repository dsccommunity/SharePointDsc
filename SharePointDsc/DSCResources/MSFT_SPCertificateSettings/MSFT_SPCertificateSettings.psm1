function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter()]
        [System.String]
        $OrganizationalUnit,

        [Parameter()]
        [System.String]
        $Organization,

        [Parameter()]
        [System.String]
        $Locality,

        [Parameter()]
        [System.String]
        $State,

        [Parameter()]
        [ValidateLength(2, 2)]
        [System.String]
        $Country,

        [Parameter()]
        [ValidateSet('ECC', 'RSA')]
        [System.String]
        $KeyAlgorithm,

        [Parameter()]
        [ValidateSet('0', '2048', '4096', '8192', '16384')]
        [System.UInt16]
        $KeySize,

        [Parameter()]
        [ValidateSet('nistP256', 'nistP384', 'nistP521')]
        [System.String]
        $EllipticCurve,

        [Parameter()]
        [ValidateSet('SHA256', 'SHA384', 'SHA512')]
        [System.String]
        $HashAlgorithm,

        [Parameter()]
        [ValidateSet('Pkcs1', 'Pss')]
        [System.String]
        $RsaSignaturePadding,

        [Parameter()]
        [System.UInt32]
        $CertificateExpirationAttentionThreshold,

        [Parameter()]
        [System.UInt32]
        $CertificateExpirationWarningThreshold,

        [Parameter()]
        [System.UInt32]
        $CertificateExpirationErrorThreshold,

        [Parameter()]
        [System.String[]]
        $CertificateNotificationContacts
    )

    Write-Verbose -Message "Getting certificate configuration settings"

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

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        try
        {
            $spFarm = Get-SPFarm
        }
        catch
        {
            Write-Verbose -Message ("No local SharePoint farm was detected. Certificate " + `
                    "settings will not be applied")
            return @{
                IsSingleInstance = "Yes"
            }
        }

        # Get a reference to the Administration WebService
        $spCertSettings = Get-SPCertificateSettings

        return @{
            IsSingleInstance                        = "Yes"
            OrganizationalUnit                      = $spCertSettings.DefaultOrganizationalUnit
            Organization                            = $spCertSettings.DefaultOrganization
            Locality                                = $spCertSettings.DefaultLocality
            State                                   = $spCertSettings.DefaultState
            Country                                 = $spCertSettings.DefaultCountry
            KeyAlgorithm                            = $spCertSettings.DefaultKeyAlgorithm
            KeySize                                 = $spCertSettings.DefaultRsaKeySize
            EllipticCurve                           = $spCertSettings.DefaultEllipticCurve
            HashAlgorithm                           = $spCertSettings.DefaultHashAlgorithm
            RsaSignaturePadding                     = $spCertSettings.DefaultRsaSignaturePadding
            CertificateExpirationAttentionThreshold = $spCertSettings.CertificateExpirationAttentionThresholdDays
            CertificateExpirationWarningThreshold   = $spCertSettings.CertificateExpirationWarningThresholdDays
            CertificateExpirationErrorThreshold     = $spCertSettings.CertificateExpirationErrorThresholdDays
            CertificateNotificationContacts         = [array]$spCertSettings.CertificateNotificationContacts.Address
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
        [System.String]
        $IsSingleInstance,

        [Parameter()]
        [System.String]
        $OrganizationalUnit,

        [Parameter()]
        [System.String]
        $Organization,

        [Parameter()]
        [System.String]
        $Locality,

        [Parameter()]
        [System.String]
        $State,

        [Parameter()]
        [System.String]
        [ValidateLength(2, 2)]
        $Country,

        [Parameter()]
        [ValidateSet('ECC', 'RSA')]
        [System.String]
        $KeyAlgorithm,

        [Parameter()]
        [ValidateSet('0', '2048', '4096', '8192', '16384')]
        [System.UInt16]
        $KeySize,

        [Parameter()]
        [ValidateSet('nistP256', 'nistP384', 'nistP521')]
        [System.String]
        $EllipticCurve,

        [Parameter()]
        [ValidateSet('SHA256', 'SHA384', 'SHA512')]
        [System.String]
        $HashAlgorithm,

        [Parameter()]
        [ValidateSet('Pkcs1', 'Pss')]
        [System.String]
        $RsaSignaturePadding,

        [Parameter()]
        [System.UInt32]
        $CertificateExpirationAttentionThreshold,

        [Parameter()]
        [System.UInt32]
        $CertificateExpirationWarningThreshold,

        [Parameter()]
        [System.UInt32]
        $CertificateExpirationErrorThreshold,

        [Parameter()]
        [System.String[]]
        $CertificateNotificationContacts
    )

    Write-Verbose -Message "Setting certificate configuration settings"

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

    $CurrentValues = Get-TargetResource @PSBoundParameters
    if ($PSBoundParameters.ContainsKey("CertificateExpirationAttentionThreshold"))
    {
        $certExpAttTheshold = $CertificateExpirationAttentionThreshold
        Write-Verbose "Desired CertificateExpirationAttentionThreshold: $certExpAttTheshold"
    }
    else
    {
        $certExpAttTheshold = $CurrentValues.CertificateExpirationAttentionThreshold
        Write-Verbose "Current CertificateExpirationWarningThreshold: $certExpAttTheshold"
    }

    if ($PSBoundParameters.ContainsKey("CertificateExpirationWarningThreshold"))
    {
        $certExpWarTheshold = $CertificateExpirationWarningThreshold
        Write-Verbose "Desired CertificateExpirationWarningThreshold: $certExpWarTheshold"
    }
    else
    {
        $certExpWarTheshold = $CurrentValues.CertificateExpirationWarningThreshold
        Write-Verbose "Current CertificateExpirationWarningThreshold: $certExpWarTheshold"
    }

    if ($certExpAttTheshold -lt $certExpWarTheshold)
    {
        $message = ("CertificateExpirationAttentionThreshold should be larger " + `
                "than CertificateExpirationWarningThreshold")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]

        try
        {
            $spFarm = Get-SPFarm
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

        $contactsProvided = $false
        if ($params.ContainsKey("IsSingleInstance"))
        {
            $params.Remove("IsSingleInstance")
        }
        if ($params.ContainsKey("InstallAccount"))
        {
            $params.Remove("InstallAccount")
        }
        if ($params.ContainsKey("CertificateNotificationContacts"))
        {
            $contactsProvided = $true
            $desiredContacts = $params.CertificateNotificationContacts
            $params.Remove("CertificateNotificationContacts")
        }

        Write-Verbose "Updating Certificate Settings"
        Set-SPCertificateSettings @params

        if ($contactsProvided)
        {
            Write-Verbose "Checking Certificate Notification Contacts"
            $currentContacts = [array](Get-SPCertificateNotificationContact).Address

            $diffs = Compare-Object -ReferenceObject $desiredContacts -DifferenceObject $currentContacts
            foreach ($diff in $diffs)
            {
                switch ($diff.SideIndicator)
                {
                    "<="
                    {
                        Write-Verbose "Adding $($diff.InputObject)"
                        $null = Add-SPCertificateNotificationContact -EmailAddress $diff.InputObject
                    }
                    "=>"
                    {
                        Write-Verbose "Removing $($diff.InputObject)"
                        $null = Remove-SPCertificateNotificationContact -EmailAddress $diff.InputObject -Confirm:$false
                    }
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
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter()]
        [System.String]
        $OrganizationalUnit,

        [Parameter()]
        [System.String]
        $Organization,

        [Parameter()]
        [System.String]
        $Locality,

        [Parameter()]
        [System.String]
        $State,

        [Parameter()]
        [ValidateLength(2, 2)]
        [System.String]
        $Country,

        [Parameter()]
        [ValidateSet('ECC', 'RSA')]
        [System.String]
        $KeyAlgorithm,

        [Parameter()]
        [ValidateSet('0', '2048', '4096', '8192', '16384')]
        [System.UInt16]
        $KeySize,

        [Parameter()]
        [ValidateSet('nistP256', 'nistP384', 'nistP521')]
        [System.String]
        $EllipticCurve,

        [Parameter()]
        [ValidateSet('SHA256', 'SHA384', 'SHA512')]
        [System.String]
        $HashAlgorithm,

        [Parameter()]
        [ValidateSet('Pkcs1', 'Pss')]
        [System.String]
        $RsaSignaturePadding,

        [Parameter()]
        [System.UInt32]
        $CertificateExpirationAttentionThreshold,

        [Parameter()]
        [System.UInt32]
        $CertificateExpirationWarningThreshold,

        [Parameter()]
        [System.UInt32]
        $CertificateExpirationErrorThreshold,

        [Parameter()]
        [System.String[]]
        $CertificateNotificationContacts
    )

    Write-Verbose -Message "Testing certificate configuration settings"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPCertificateSettings\MSFT_SPCertificateSettings.psm1" -Resolve

    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module
    $params.Country = "US"

    $PartialContent = "        SPCertificateSettings CertificateSettings`r`n"
    $PartialContent += "        {`r`n"
    $results = Get-TargetResource @params
    $results = Repair-Credentials -results $results
    $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
    $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
    $PartialContent += $currentBlock
    $PartialContent += "        }`r`n"

    $Content += $PartialContent

    return $Content
}

Export-ModuleMember -Function *-TargetResource
