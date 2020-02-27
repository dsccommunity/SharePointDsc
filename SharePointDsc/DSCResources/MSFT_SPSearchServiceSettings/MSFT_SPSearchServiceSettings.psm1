$script:resourceModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:resourceModulePath -ChildPath 'Modules'
$script:resourceHelperModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'SharePointDsc.Util'
Import-Module -Name (Join-Path -Path $script:resourceHelperModulePath -ChildPath 'SharePointDsc.Util.psm1')

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
                InstallAccount        = $params.InstallAccount
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
        throw ("You have to specify at least one of the following parameters: " + `
                "PerformanceLevel, ContactEmail or WindowsServiceAccount")
    }

    $result = Get-TargetResource @PSBoundParameters

    # Update the service app that already exists
    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters, $result) `
        -ScriptBlock {
        $params = $args[0]
        $result = $args[1]

        try
        {
            $null = Get-SPFarm
        }
        catch
        {
            throw ("No local SharePoint farm was detected. Search service " + `
                    "settings will not be applied")
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
            Write-Verbose -Message "Windows service account is different, returning false"
            Write-Verbose -Message "Desired: $desired. Current: $current."
            return $false
        }
    }

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("PerformanceLevel",
        "ContactEmail")

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

Export-ModuleMember -Function *-TargetResource
