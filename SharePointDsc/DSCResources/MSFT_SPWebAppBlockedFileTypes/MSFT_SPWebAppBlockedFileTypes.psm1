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
        -Arguments @($PSBoundParameters, $PSScriptRoot) `
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
        -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source, $PSScriptRoot) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]
        $ScriptRoot = $args[2]

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue
        if ($null -eq $wa)
        {
            $message = "Web application $($params.WebAppUrl) was not found"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
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

    $result = Test-SPDscWebApplicationBlockedFileTypeConfig -CurrentSettings $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredSettings $PSBoundParameters

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPWebAppBlockedFileTypes\MSFT_SPWebAppBlockedFileTypes.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module
    $webApps = Get-SPWebApplication
    $i = 1
    $total = $webApps.Length
    foreach ($webApp in $webApps)
    {
        try
        {
            Write-Host "Scanning Web App Blocked File Types [$i/$total] {$($webApp.Url)}"
            $params.WebAppUrl = $webApp.Url
            $PartialContent = "        SPWebAppBlockedFileTypes " + [System.Guid]::NewGuid().ToString() + "`r`n"
            $PartialContent += "        {`r`n"
            $results = Get-TargetResource @params

            $results = Repair-Credentials -results $results
            $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
            $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
            $PartialContent += $currentBlock
            $PartialContent += "        }`r`n"
            $Content += $PartialContent
        }
        catch
        {
            $Global:ErrorLog += "[SPWebAppBlockedFileTypes] Couldn't properly retrieve all Blocked File Types from Web Application {$($webApp.Url)}`r`n"
        }
        $i++
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
