function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]   $Url,
        [parameter(Mandatory = $false)] [System.String[]] $Blocked,
        [parameter(Mandatory = $false)] [System.String[]] $EnsureBlocked,
        [parameter(Mandatory = $false)] [System.String[]] $EnsureAllowed,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Getting web application '$url' blocked file types"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount -Arguments @($PSBoundParameters,$PSScriptRoot) -ScriptBlock {
        $params = $args[0]
        $ScriptRoot = $args[1]
        
        
        $wa = Get-SPWebApplication -Identity $params.Url -ErrorAction SilentlyContinue
        if ($null -eq $wa) { return $null }

        Import-Module (Join-Path $ScriptRoot "..\..\Modules\SharePointDsc.WebApplication\SPWebApplication.BlockedFileTypes.psm1" -Resolve)

        $result = Get-SPDSCWebApplicationBlockedFileTypes -WebApplication $wa
        $result.Add("Url", $params.Url)
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
        [parameter(Mandatory = $true)]  [System.String]   $Url,
        [parameter(Mandatory = $false)] [System.String[]] $Blocked,
        [parameter(Mandatory = $false)] [System.String[]] $EnsureBlocked,
        [parameter(Mandatory = $false)] [System.String[]] $EnsureAllowed,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Setting web application '$Url' blocked file types"
    $result = Invoke-SPDSCCommand -Credential $InstallAccount -Arguments @($PSBoundParameters,$PSScriptRoot) -ScriptBlock {
        $params = $args[0]
        $ScriptRoot = $args[1]

        $wa = Get-SPWebApplication -Identity $params.Url -ErrorAction SilentlyContinue
        if ($null -eq $wa) {
            throw "Web application $($params.Url) was not found"
            return
        }

        Import-Module (Join-Path $ScriptRoot "..\..\Modules\SharePointDsc.WebApplication\SPWebApplication.BlockedFileTypes.psm1" -Resolve)
        Set-SPDSCWebApplicationBlockedFileTypes -WebApplication $wa -Settings $params
        $wa.Update()
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]   $Url,
        [parameter(Mandatory = $false)] [System.String[]] $Blocked,
        [parameter(Mandatory = $false)] [System.String[]] $EnsureBlocked,
        [parameter(Mandatory = $false)] [System.String[]] $EnsureAllowed,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing for web application '$Url' blocked file types"
    if ($null -eq $CurrentValues) { return $false }

    Import-Module (Join-Path $PSScriptRoot "..\..\Modules\SharePointDsc.WebApplication\SPWebApplication.BlockedFileTypes.psm1" -Resolve)
    return Test-SPDSCWebApplicationBlockedFileTypes -CurrentSettings $CurrentValues -DesiredSettings $PSBoundParameters
}


Export-ModuleMember -Function *-TargetResource

