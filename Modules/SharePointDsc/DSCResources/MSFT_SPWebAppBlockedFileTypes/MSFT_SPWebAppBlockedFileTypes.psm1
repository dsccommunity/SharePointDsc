function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  
        [System.String]
        $Url,

        [parameter(Mandatory = $false)] 
        [System.String[]] 
        $Blocked,

        [parameter(Mandatory = $false)]
        [System.String[]]
        $EnsureBlocked,

        [parameter(Mandatory = $false)]
        [System.String[]]
        $EnsureAllowed,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Getting web application '$url' blocked file types"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments @($PSBoundParameters,$PSScriptRoot) `
                                  -ScriptBlock {
        $params = $args[0]
        $ScriptRoot = $args[1]
        
        $wa = Get-SPWebApplication -Identity $params.Url -ErrorAction SilentlyContinue
        if ($null -eq $wa) { return $null }

        $modulePath = "..\..\Modules\SharePointDsc.WebApplication\SPWebApplication.BlockedFileTypes.psm1"
        Import-Module -Name (Join-Path -Path $ScriptRoot -ChildPath $modulePath -Resolve)

        $result = Get-SPDSCWebApplicationBlockedFileTypeConfig -WebApplication $wa
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
        [parameter(Mandatory = $true)]  
        [System.String]
        $Url,

        [parameter(Mandatory = $false)] 
        [System.String[]] 
        $Blocked,

        [parameter(Mandatory = $false)]
        [System.String[]]
        $EnsureBlocked,

        [parameter(Mandatory = $false)]
        [System.String[]]
        $EnsureAllowed,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Setting web application '$Url' blocked file types"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments @($PSBoundParameters,$PSScriptRoot) `
                                  -ScriptBlock {
        $params = $args[0]
        $ScriptRoot = $args[1]

        $wa = Get-SPWebApplication -Identity $params.Url -ErrorAction SilentlyContinue
        if ($null -eq $wa) {
            throw "Web application $($params.Url) was not found"
            return
        }

        $modulePath = "..\..\Modules\SharePointDsc.WebApplication\SPWebApplication.BlockedFileTypes.psm1"
        Import-Module -Name (Join-Path -Path $ScriptRoot -ChildPath $modulePath -Resolve)

        Set-SPDSCWebApplicationBlockedFileTypeConfig -WebApplication $wa -Settings $params
        $wa.Update()
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  
        [System.String]
        $Url,

        [parameter(Mandatory = $false)] 
        [System.String[]] 
        $Blocked,

        [parameter(Mandatory = $false)]
        [System.String[]]
        $EnsureBlocked,

        [parameter(Mandatory = $false)]
        [System.String[]]
        $EnsureAllowed,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Testing for web application '$Url' blocked file types"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($null -eq $CurrentValues)
    {
        return $false
    }

    $modulePath = "..\..\Modules\SharePointDsc.WebApplication\SPWebApplication.BlockedFileTypes.psm1"
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath $modulePath -Resolve)

    return Test-SPDSCWebApplicationBlockedFileTypeConfig -CurrentSettings $CurrentValues `
                                                         -DesiredSettings $PSBoundParameters
}

Export-ModuleMember -Function *-TargetResource
