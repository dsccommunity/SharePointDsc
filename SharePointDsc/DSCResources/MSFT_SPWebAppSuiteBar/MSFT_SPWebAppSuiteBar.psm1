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
        [System.String]
        $SuiteNavBrandingLogoNavigationUrl,

        [Parameter()]
        [System.String]
        $SuiteNavBrandingLogoTitle,

        [Parameter()]
        [System.String]
        $SuiteNavBrandingLogoUrl,

        [Parameter()]
        [System.String]
        $SuiteNavBrandingText,

        [Parameter()]
        [System.String]
        $SuiteBarBrandingElementHtml,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting web app suite bar properties for $WebAppUrl"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl `
            -ErrorAction SilentlyContinue

        $returnval = @{
            WebAppUrl                         = $null
            SuiteNavBrandingLogoNavigationUrl = $null
            SuiteNavBrandingLogoTitle         = $null
            SuiteNavBrandingLogoUrl           = $null
            SuiteNavBrandingText              = $null
            SuiteBarBrandingElementHtml       = $null
        }

        if ($null -eq $wa)
        {
            return $returnval
        }

        $returnval.WebAppUrl = $wa.Url

        $installedVersion = Get-SPDscInstalledProductVersion

        if ($installedVersion.FileMajorPart -ge 15)
        {
            $returnval.SuiteBarBrandingElementHtml = $wa.SuiteBarBrandingElementHtml
        }

        if ($installedVersion.FileMajorPart -ge 16)
        {
            if ($installedVersion.ProductBuildPart.ToString().Length -eq 4)
            {
                $returnval.SuiteNavBrandingLogoNavigationUrl = $wa.SuiteNavBrandingLogoNavigationUrl
                $returnval.SuiteNavBrandingLogoTitle = $wa.SuiteNavBrandingLogoTitle
                $returnval.SuiteNavBrandingLogoUrl = $wa.SuiteNavBrandingLogoUrl
                $returnval.SuiteNavBrandingText = $wa.SuiteNavBrandingText
            }
            else
            {
                return $returnval
            }
        }

        return $returnval
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
        [System.String]
        $SuiteNavBrandingLogoNavigationUrl,

        [Parameter()]
        [System.String]
        $SuiteNavBrandingLogoTitle,

        [Parameter()]
        [System.String]
        $SuiteNavBrandingLogoUrl,

        [Parameter()]
        [System.String]
        $SuiteNavBrandingText,

        [Parameter()]
        [System.String]
        $SuiteBarBrandingElementHtml,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting web app suite bar properties for $WebAppUrl"

    $installedVersion = Get-SPDscInstalledProductVersion

    <# Handle SP2013 #>
    switch ($installedVersion.FileMajorPart)
    {
        15
        {
            <# Exception: One of the SP2016/SP2019 specific parameter was passed with SP2013 #>
            Write-Verbose -Message "SharePoint 2013 is used"
            if ($PSBoundParameters.ContainsKey("SuiteNavBrandingLogoNavigationUrl") `
                    -or $PSBoundParameters.ContainsKey("SuiteNavBrandingLogoTitle") `
                    -or $PSBoundParameters.ContainsKey("SuiteNavBrandingLogoUrl") `
                    -or $PSBoundParameters.ContainsKey("SuiteNavBrandingText"))
            {
                throw ("Cannot specify SuiteNavBrandingLogoNavigationUrl, SuiteNavBrandingLogoTitle, " + `
                        "SuiteNavBrandingLogoUrl or SuiteNavBrandingText with SharePoint 2013. Instead," + `
                        " only specify the SuiteBarBrandingElementHtml parameter")
            }

            <# Exception: The SP2013 optional parameter is null. #>
            if (!$PSBoundParameters.ContainsKey("SuiteBarBrandingElementHtml"))
            {
                throw ("You need to specify a value for the SuiteBarBrandingElementHtml parameter with" + `
                        " SharePoint 2013")
            }
        }
        16
        {
            if ($installedVersion.ProductBuildPart.ToString().Length -eq 4)
            {
                Write-Verbose -Message "SharePoint 2016 is used"
                if ($PSBoundParameters.ContainsKey("SuiteBarBrandingElementHtml"))
                {
                    Write-Verbose -Message ("SuiteBarBrandingElementHtml with SharePoint 2016 only " + `
                            "works if using a SharePoint 2013 masterpage")
                }

                <# Exception: All the optional parameters are null for SP2016. #>
                if (!$PSBoundParameters.ContainsKey("SuiteNavBrandingLogoNavigationUrl") `
                        -and !$PSBoundParameters.ContainsKey("SuiteNavBrandingLogoTitle") `
                        -and !$PSBoundParameters.ContainsKey("SuiteNavBrandingLogoUrl") `
                        -and !$PSBoundParameters.ContainsKey("SuiteNavBrandingText") `
                        -and !$PSBoundParameters.ContainsKey("SuiteBarBrandingElementHtml"))
                {
                    throw ("You need to specify a value for either SuiteNavBrandingLogoNavigationUrl, " + `
                            "SuiteNavBrandingLogoTitle, SuiteNavBrandingLogoUrl, SuiteNavBrandingText " + `
                            "or SuiteBarBrandingElementHtml with SharePoint 2016")
                }
            }
            else
            {
                Write-Verbose -Message "SharePoint 2019 is used"
                throw "Changing the Suite Bar is not possible in SharePoint 2019"
            }
        }
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($null -eq $CurrentValues.WebAppUrl)
    {
        throw "Web application does not exist"
    }

    ## Perform changes
    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters) `
        -ScriptBlock {
        $params = $args[0]

        $installedVersion = Get-SPDscInstalledProductVersion

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue

        if ($null -eq $wa)
        {
            throw "Specified web application could not be found."
        }

        Write-Verbose -Message "Processing changes"

        if ($installedVersion.FileMajorPart -ge 15)
        {
            $wa.SuiteBarBrandingElementHtml = $params.SuiteBarBrandingElementHtml
        }

        if ($installedVersion.FileMajorPart -ge 16)
        {
            $wa.SuiteNavBrandingLogoNavigationUrl = $params.SuiteNavBrandingLogoNavigationUrl
            $wa.SuiteNavBrandingLogoTitle = $params.SuiteNavBrandingLogoTitle
            $wa.SuiteNavBrandingLogoUrl = $params.SuiteNavBrandingLogoUrl
            $wa.SuiteNavBrandingText = $params.SuiteNavBrandingText
        }
        $wa.Update()
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
        [System.String]
        $SuiteNavBrandingLogoNavigationUrl,

        [Parameter()]
        [System.String]
        $SuiteNavBrandingLogoTitle,

        [Parameter()]
        [System.String]
        $SuiteNavBrandingLogoUrl,

        [Parameter()]
        [System.String]
        $SuiteNavBrandingText,

        [Parameter()]
        [System.String]
        $SuiteBarBrandingElementHtml,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing web app suite bar properties for $WebAppUrl"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($null -eq $CurrentValues.WebAppUrl)
    {
        Write-Verbose -Message "Test-TargetResource returned false"
        return $false
    }

    $installedVersion = Get-SPDscInstalledProductVersion

    if ($installedVersion.FileMajorPart -eq 15)
    {
        $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("SuiteBarBrandingElementHtml");
    }
    else
    {
        $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("SuiteBarBrandingElementHtml",
            "SuiteNavBrandingLogoNavigationUrl",
            "SuiteNavBrandingLogoTitle",
            "SuiteNavBrandingLogoUrl",
            "SuiteNavBrandingText")
    }

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

Export-ModuleMember -Function *-TargetResource
