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
        [System.String[]]
        $Blocked,

        [Parameter()]
        [System.String[]]
        $EnsureBlocked,

        [Parameter()]
        [System.String[]]
        $EnsureAllowed,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting web application '$WebAppUrl' blocked file types"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
                                  -Arguments @($PSBoundParameters,$PSScriptRoot) `
                                  -ScriptBlock {
        $params = $args[0]
        $ScriptRoot = $args[1]

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue
        if ($null -eq $wa)
        {
            return @{
                WebAppUrl     = $null
                Blocked       = $null
                EnsureBlocked = $null
                EnsureAllowed = $null
            }
        }

        $modulePath = "..\..\Modules\SharePointDsc.WebApplication\SPWebApplication.BlockedFileTypes.psm1"
        Import-Module -Name (Join-Path -Path $ScriptRoot -ChildPath $modulePath -Resolve)

        $result = Get-SPDscWebApplicationBlockedFileTypeConfig -WebApplication $wa
        $result.Add("WebAppUrl", $params.WebAppUrl)
        $result.Add("InstallAccount", $params.InstallAccount)
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
        $WebAppUrl,

        [Parameter()]
        [System.String[]]
        $Blocked,

        [Parameter()]
        [System.String[]]
        $EnsureBlocked,

        [Parameter()]
        [System.String[]]
        $EnsureAllowed,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting web application '$WebAppUrl' blocked file types"

    $null = Invoke-SPDscCommand -Credential $InstallAccount `
                                -Arguments @($PSBoundParameters,$PSScriptRoot) `
                                -ScriptBlock {
        $params = $args[0]
        $ScriptRoot = $args[1]

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue
        if ($null -eq $wa)
        {
            throw "Web application $($params.WebAppUrl) was not found"
            return
        }

        $modulePath = "..\..\Modules\SharePointDsc.WebApplication\SPWebApplication.BlockedFileTypes.psm1"
        Import-Module -Name (Join-Path -Path $ScriptRoot -ChildPath $modulePath -Resolve)

        Set-SPDscWebApplicationBlockedFileTypeConfig -WebApplication $wa -Settings $params
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
        [System.String[]]
        $Blocked,

        [Parameter()]
        [System.String[]]
        $EnsureBlocked,

        [Parameter()]
        [System.String[]]
        $EnsureAllowed,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing for web application '$WebAppUrl' blocked file types"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $modulePath = "..\..\Modules\SharePointDsc.WebApplication\SPWebApplication.BlockedFileTypes.psm1"
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath $modulePath -Resolve)

    return Test-SPDscWebApplicationBlockedFileTypeConfig -CurrentSettings $CurrentValues `
                                                         -DesiredSettings $PSBoundParameters
}

Export-ModuleMember -Function *-TargetResource
