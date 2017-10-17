function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $WebAppUrl,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $SuiteNavBrandingLogoNavigationUrl,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $SuiteNavBrandingLogoTitle,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $SuiteNavBrandingLogoUrl,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $SuiteNavBrandingText,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $SuiteBarBrandingElementHtml,

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Getting web app suite bar properties for $WebAppUrl"

    $installedVersion = Get-SPDSCInstalledProductVersion

    <# Handle SP2013 #>
    if($installedVersion.FileMajorPart -eq 15)
    {
        <# Exception: One of the SP2016 specific parameter was passed with SP2013 #>
        if(!$PSBoundParameters.ContainsKey("SuiteNavBrandingLogoNavigationUrl") `
        -or !$PSBoundParameters.ContainsKey("SuiteNavBrandingLogoTitle") `
        -or $PSBoundParameters.ContainsKey("SuiteNavBrandingLogoUrl") `
        -or $PSBoundParameters.ContainsKey("SuiteNavBrandingText"))
        {
            Write-Verbose -Message ("Cannot specify SuiteNavBrandingLogoNavigationUrl, SuiteNavBrandingLogoTitle, " + `
                                    "SuiteNavBrandingLogoUrl or SuiteNavBrandingText whith SharePoint 2013. Instead," + `
                                    " only specify the SuiteBarBrandingElementHtml parameter")
            return $null
        }

        <# Exception: The SP2013 optional parameter is null. #>
        if($PSBoundParameters.ContainsKey("SuiteBarBrandingElementHtml"))
        {
            Write-Verbose -Message ("You need to specify a value for the SuiteBarBrandingElementHtml parameter with" + `
                                    " SharePoint 2013")
            return $null
        }
    }
    elseif($installedVersion.FileMajorPart -ge 16)
    {
        <# Exception: The SP2013 specific SuiteBarBrandingElementHtml parameter was passed with SP2016. #>
        if($PSBoundParameters.ContainsKey("SuiteBarBrandingElementHtml"))
        {
            Write-Verbose -Message ("Cannot specify SuiteBarBrandingElementHtml whith SharePoint 2016. Instead," + `
                                    " use the SuiteNavBrandingLogoNavigationUrl, SuiteNavBrandingLogoTitle, " + `
                                    "SuiteNavBrandingLogoUrl and SuiteNavBrandingText parameters")
            return $null
        }

        <# Exception: All the optional parameters are null for SP2016. #>
        if(!$PSBoundParameters.ContainsKey("SuiteNavBrandingLogoNavigationUrl") `
        -and !$PSBoundParameters.ContainsKey("SuiteNavBrandingLogoTitle") `
        -and !$PSBoundParameters.ContainsKey("SuiteNavBrandingLogoUrl") `
        -and !$PSBoundParameters.ContainsKey("SuiteNavBrandingText"))
        {
            Write-Verbose -Message ("You need to specify a value for either SuiteNavBrandingLogoNavigationUrl " + `
                                    ", SuiteNavBrandingLogoTitle, SuiteNavBrandingLogoUrl and SuiteNavBrandingText " + `
                                    "whith SharePoint 2016")
            return $null
        }
    }
    
    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl `
                                   -ErrorAction SilentlyContinue

        if ($null -eq $wa) 
        { 
            return $null 
        }        

        $returnval = @{
            WebAppUrl = $params.WebAppUrl
            SuiteNavBrandingLogoNavigationUrl = $null
            SuiteNavBrandingLogoTitle = $null
            SuiteNavBrandingLogoUrl = $null
            SuiteNavBrandingText = $null
            SuiteBarBrandingElementHtml = $null
        }
        
        $installedVersion = Get-SPDSCInstalledProductVersion

        if($installedVersion.FileMajorPart -eq 15)
        {
            $returnval.SuiteBarBrandingElementHtml = $wa.SuiteBarBrandingElementHtml
        }
        elseif($installedVersion.FileMajorPart -ge 16)
        {
            $returnval.SuiteNavBrandingLogoNavigationUrl = $wa.SuiteNavBrandingLogoNavigationUrl
            $returnval.SuiteNavBrandingLogoTitle = $wa.SuiteNavBrandingLogoTitle
            $returnval.SuiteNavBrandingLogoUrl = $wa.SuiteNavBrandingLogoUrl
            $returnval.SuiteNavBrandingText = $wa.SuiteNavBrandingText
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
        [parameter(Mandatory = $true)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $WebAppUrl,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $SuiteNavBrandingLogoNavigationUrl,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $SuiteNavBrandingLogoTitle,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $SuiteNavBrandingLogoUrl,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $SuiteNavBrandingText,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $SuiteBarBrandingElementHtml,

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Setting web app suite bar properties for $WebAppUrl"

    $installedVersion = Get-SPDSCInstalledProductVersion

    <# Handle SP2013 #>
    if($installedVersion.FileMajorPart -eq 15)
    {
        <# Exception: One of the SP2016 specific parameter was passed with SP2013 #>
        if(!$PSBoundParameters.ContainsKey("SuiteNavBrandingLogoNavigationUrl") `
        -or !$PSBoundParameters.ContainsKey("SuiteNavBrandingLogoTitle") `
        -or $PSBoundParameters.ContainsKey("SuiteNavBrandingLogoUrl") `
        -or $PSBoundParameters.ContainsKey("SuiteNavBrandingText"))
        {
            throw ("Cannot specify SuiteNavBrandingLogoNavigationUrl, SuiteNavBrandingLogoTitle, " + `
                                    "SuiteNavBrandingLogoUrl or SuiteNavBrandingText whith SharePoint 2013. Instead," + `
                                    " only specify the SuiteBarBrandingElementHtml parameter")
        }

        <# Exception: The SP2013 optional parameter is null. #>
        if($PSBoundParameters.ContainsKey("SuiteBarBrandingElementHtml"))
        {
            throw ("You need to specify a value for the SuiteBarBrandingElementHtml parameter with" + `
                                    " SharePoint 2013")
        }
    }
    elseif($installedVersion.FileMajorPart -ge 16)
    {
        <# Exception: The SP2013 specific SuiteBarBrandingElementHtml parameter was passed with SP2016. #>
        if($PSBoundParameters.ContainsKey("SuiteBarBrandingElementHtml"))
        {
            throw ("Cannot specify SuiteBarBrandingElementHtml whith SharePoint 2016. Instead," + `
                                    " use the SuiteNavBrandingLogoNavigationUrl, SuiteNavBrandingLogoTitle, " + `
                                    "SuiteNavBrandingLogoUrl and SuiteNavBrandingText parameters")
        }

        <# Exception: All the optional parameters are null for SP2016. #>
        if(!$PSBoundParameters.ContainsKey("SuiteNavBrandingLogoNavigationUrl") `
        -and !$PSBoundParameters.ContainsKey("SuiteNavBrandingLogoTitle") `
        -and !$PSBoundParameters.ContainsKey("SuiteNavBrandingLogoUrl") `
        -and !$PSBoundParameters.ContainsKey("SuiteNavBrandingText"))
        {
            throw ("You need to specify a value for either SuiteNavBrandingLogoNavigationUrl " + `
                                    ", SuiteNavBrandingLogoTitle, SuiteNavBrandingLogoUrl and SuiteNavBrandingText " + `
                                    "whith SharePoint 2016")
        }
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters
    
    if ($null -eq $CurrentValues) 
    {
        throw "Web application does not exist"
    }
    
    ## Perform changes
    Invoke-SPDSCCommand -Credential $InstallAccount `
                        -Arguments @($PSBoundParameters) `
                        -ScriptBlock {
        $params = $args[0]

        $installedVersion = Get-SPDSCInstalledProductVersion

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue

        if ($null -eq $wa) 
        {
            throw "Specified web application could not be found."
        }

        Write-Verbose -Message "Processing changes"

        if($installedVersion.FileMajorPart -eq 15)
        {
            $wa.SuiteBarBrandingElementHtml = $params.SuiteBarBrandingElementHtml
            $wa.Update()
        }
        elseif($installedVersion.FileMajorPart -ge 16)
        {
            $wa.SuiteNavBrandingLogoNavigationUrl = $params.SuiteNavBrandingLogoNavigationUrl
            $wa.SuiteNavBrandingLogoTitle = $params.SuiteNavBrandingLogoTitle
            $wa.SuiteNavBrandingLogoUrl = $params.SuiteNavBrandingLogoUrl
            $wa.SuiteNavBrandingText = $params.SuiteNavBrandingText
            $wa.Update()
        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $WebAppUrl,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $SuiteNavBrandingLogoNavigationUrl,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $SuiteNavBrandingLogoTitle,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $SuiteNavBrandingLogoUrl,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $SuiteNavBrandingText,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $SuiteBarBrandingElementHtml,

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Testing web app suite bar properties for $WebAppUrl"

    $CurrentValues = Get-TargetResource @PSBoundParameters
    
    if ($null -eq $CurrentValues) 
    { 
        return $false 
    }

    # Determine the default identity type to use for entries that do not have it specified
    $returnValue = Invoke-SPDSCCommand -Credential $InstallAccount `
                                               -Arguments $PSBoundParameters `
                                               -ScriptBlock {
        $params = $args[0]

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl
        
        $installedVersion = Get-SPDSCInstalledProductVersion

        if($installedVersion.FileMajorPart -eq 15)
        {
            return ($wa.SuiteBarBrandingElementHtml -eq $params.SuiteBarBrandingElementHtml)
        }
        elseif($installedVersion.FileMajorPart -ge 16)
        {
            return ($wa.SuiteNavBrandingLogoNavigationUrl -eq $params.SuiteNavBrandingLogoNavigationUrl -and `
            $wa.SuiteNavBrandingLogoTitle -eq $params.SuiteNavBrandingLogoTitle -and `
            $wa.SuiteNavBrandingLogoUrl -eq $params.SuiteNavBrandingLogoUrl -and `
            $wa.SuiteNavBrandingText -eq $params.SuiteNavBrandingText)
        }
    }    

    return $returnValue
}

Export-ModuleMember -Function *-TargetResource
