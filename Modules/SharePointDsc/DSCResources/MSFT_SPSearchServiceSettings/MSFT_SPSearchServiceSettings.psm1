function Get-TargetResource
{
    # Ignoring this because we need to generate a stub credential to return up the current
    # crawl account as a PSCredential
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter()]
        [ValidateSet("Reduced","PartlyReduced","Maximum")]
        [System.String]
        $PerformanceLevel,

        [Parameter()]
        [System.String]
        $ContactEmail,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $WindowsServiceAccount,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting Search service settings"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]

        $searchService = Get-SPEnterpriseSearchService

        $dummyPassword = ConvertTo-SecureString -String "-" -AsPlainText -Force
        $windowsAccount = New-Object -TypeName System.Management.Automation.PSCredential `
                                     -ArgumentList @($searchService.ProcessIdentity, $dummyPassword)

        $returnVal =  @{
            IsSingleInstance      = "Yes"
            PerformanceLevel      = $searchService.PerformanceLevel
            ContactEmail          = $searchService.ContactEmail
            WindowsServiceAccount = $windowsAccount
            InstallAccount        = $params.InstallAccount
        }
        return $returnVal
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
        [String]
        $IsSingleInstance,

        [Parameter()]
        [ValidateSet("Reduced","PartlyReduced","Maximum")]
        [System.String]
        $PerformanceLevel,

        [Parameter()]
        [System.String]
        $ContactEmail,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $WindowsServiceAccount,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting Search service settings"

    $result = Get-TargetResource @PSBoundParameters

    # Update the service app that already exists
    Invoke-SPDSCCommand -Credential $InstallAccount `
                        -Arguments @($PSBoundParameters, $result) `
                        -ScriptBlock {
        $params = $args[0]
        $result = $args[1]

        $setParams = @{}

        if ($params.ContainsKey("PerformanceLevel") -eq $true -and `
            $result.PerformanceLevel -ne $params.PerformanceLevel)
        {
            Write-Verbose -Message "Updating PerformanceLevel to $($params.PerformanceLevel)"
            $setParams.Add("PerformanceLevel", $params.PerformanceLevel)
        }

        if ($params.ContainsKey("ContactEmail") -eq $true -and `
            $result.ContactEmail -ne $params.ContactEmail)
        {
            Write-Verbose -Message "Updating ContactEmail to $($params.ContactEmail)"
            $setParams.Add("ContactEmail", $params.ContactEmail)
        }

        if ($params.ContainsKey("WindowsServiceAccount") -eq $true -and `
            $result.WindowsServiceAccount.UserName -ne $params.WindowsServiceAccount.UserName)
        {
            Write-Verbose -Message ("Updating WindowsServiceAccount to " + `
                                    $params.WindowsServiceAccount.UserName)
            $setParams.Add("ServiceAccount", $params.WindowsServiceAccount.UserName)
            $setParams.Add("ServicePassword", $params.WindowsServiceAccount.Password)
        }

        if ($setParams.Count -gt 0)
        {
            Set-SPEnterpriseSearchService @setParams
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
        [String]
        $IsSingleInstance,

        [Parameter()]
        [ValidateSet("Reduced","PartlyReduced","Maximum")]
        [System.String]
        $PerformanceLevel,

        [Parameter()]
        [System.String]
        $ContactEmail,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $WindowsServiceAccount,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing Search service settings"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($PSBoundParameters.ContainsKey("WindowsServiceAccount"))
    {
        $desired = $WindowsServiceAccount.UserName
        $current = $CurrentValues.WindowsServiceAccount.UserName

        if ($desired -ne $current)
        {
            Write-Verbose -Message "Windows service account is different, returning false"
            Write-Verbose -Message "Desired: $desired. Current: $current."
            return $false
        }
    }

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @("PerformanceLevel",
                                                     "ContactEmail")
}

Export-ModuleMember -Function *-TargetResource
