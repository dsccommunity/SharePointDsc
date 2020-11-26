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
        [ValidateSet("Reduced", "PartlyReduced", "Maximum")]
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

    if ($PSBoundParameters.ContainsKey("PerformanceLevel") -eq $false -and
        $PSBoundParameters.ContainsKey("ContactEmail") -eq $false -and `
            $PSBoundParameters.ContainsKey("WindowsServiceAccount") -eq $false)
    {
        Write-Verbose -Message ("You have to specify at least one of the following parameters: " + `
                "PerformanceLevel, ContactEmail or WindowsServiceAccount")
        return @{
            IsSingleInstance      = "Yes"
            PerformanceLevel      = $null
            ContactEmail          = $null
            WindowsServiceAccount = $null
            InstallAccount        = $InstallAccount
        }
    }

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        try
        {
            $null = Get-SPFarm
        }
        catch
        {
            Write-Verbose -Message ("No local SharePoint farm was detected. Search service " + `
                    "settings will not be applied")
            return @{
                IsSingleInstance      = "Yes"
                PerformanceLevel      = $null
                ContactEmail          = $null
                WindowsServiceAccount = $null
            }
        }

        $searchService = Get-SPEnterpriseSearchService

        $dummyPassword = ConvertTo-SecureString -String "-" -AsPlainText -Force
        $windowsAccount = New-Object -TypeName System.Management.Automation.PSCredential `
            -ArgumentList @($searchService.ProcessIdentity, $dummyPassword)

        $returnVal = @{
            IsSingleInstance      = "Yes"
            PerformanceLevel      = $searchService.PerformanceLevel
            ContactEmail          = $searchService.ContactEmail
            WindowsServiceAccount = $windowsAccount
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
        [ValidateSet("Reduced", "PartlyReduced", "Maximum")]
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

    if ($PSBoundParameters.ContainsKey("PerformanceLevel") -eq $false -and
        $PSBoundParameters.ContainsKey("ContactEmail") -eq $false -and `
            $PSBoundParameters.ContainsKey("WindowsServiceAccount") -eq $false)
    {
        $message = ("You have to specify at least one of the following parameters: " + `
                "PerformanceLevel, ContactEmail or WindowsServiceAccount")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $result = Get-TargetResource @PSBoundParameters

    # Update the service app that already exists
    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source, $result) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]
        $result = $args[2]

        try
        {
            $null = Get-SPFarm
        }
        catch
        {
            $message = ("No local SharePoint farm was detected. Search service " + `
                    "settings will not be applied")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }

        $setParams = @{ }

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
        [ValidateSet("Reduced", "PartlyReduced", "Maximum")]
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

    if ($PSBoundParameters.ContainsKey("PerformanceLevel") -eq $false -and
        $PSBoundParameters.ContainsKey("ContactEmail") -eq $false -and `
            $PSBoundParameters.ContainsKey("WindowsServiceAccount") -eq $false)
    {
        Write-Verbose -Message ("You have to specify at least one of the following parameters: " + `
                "PerformanceLevel, ContactEmail or WindowsServiceAccount")
        return $false
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($PSBoundParameters.ContainsKey("WindowsServiceAccount"))
    {
        $desired = $WindowsServiceAccount.UserName
        $current = $CurrentValues.WindowsServiceAccount.UserName

        if ($desired -ne $current)
        {
            $message = ("Specified Windows service account is not in the desired state" + `
                    "Actual: $current Desired: $desired")
            Write-Verbose -Message $message
            Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

            Write-Verbose -Message "Desired: $desired. Current: $current."
            return $false
        }
    }

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("PerformanceLevel",
        "ContactEmail")

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

Export-ModuleMember -Function *-TargetResource
