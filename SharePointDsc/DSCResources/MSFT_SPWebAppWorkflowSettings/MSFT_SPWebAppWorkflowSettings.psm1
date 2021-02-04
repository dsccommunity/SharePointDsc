$script:SPDscUtilModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SharePointDsc.Util'
Import-Module -Name $script:SPDscUtilModulePath

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
        [System.Boolean]
        $ExternalWorkflowParticipantsEnabled,

        [Parameter()]
        [System.Boolean]
        $UserDefinedWorkflowsEnabled,

        [Parameter()]
        [System.Boolean]
        $EmailToNoPermissionWorkflowParticipantsEnable,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting web application '$WebAppUrl' workflow settings"

    $paramArgs = @($PSBoundParameters, $PSScriptRoot)
    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $paramArgs `
        -ScriptBlock {
        $params = $args[0]
        $ScriptRoot = $args[1]


        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue
        if ($null -eq $wa)
        {
            return @{
                WebAppUrl                                     = $params.WebAppUrl
                ExternalWorkflowParticipantsEnabled           = $null
                UserDefinedWorkflowsEnabled                   = $null
                EmailToNoPermissionWorkflowParticipantsEnable = $null
            }
        }

        $relPath = "..\..\Modules\SharePointDsc.WebApplication\SPWebApplication.Workflow.psm1"
        Import-Module (Join-Path $ScriptRoot $relPath -Resolve)

        $result = Get-SPDscWebApplicationWorkflowConfig -WebApplication $wa
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
        [System.Boolean]
        $ExternalWorkflowParticipantsEnabled,

        [Parameter()]
        [System.Boolean]
        $UserDefinedWorkflowsEnabled,

        [Parameter()]
        [System.Boolean]
        $EmailToNoPermissionWorkflowParticipantsEnable,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting web application '$WebAppUrl' workflow settings"

    $paramArgs = @($PSBoundParameters, $MyInvocation.MyCommand.Source, $PSScriptRoot)
    $null = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $paramArgs `
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
                -Source $eventSource
            throw $message
        }

        $relpath = "..\..\Modules\SharePointDsc.WebApplication\SPWebApplication.Workflow.psm1"
        Import-Module (Join-Path $ScriptRoot $relPath -Resolve)
        Set-SPDscWebApplicationWorkflowConfig -WebApplication $wa -Settings $params
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
        [System.Boolean]
        $ExternalWorkflowParticipantsEnabled,

        [Parameter()]
        [System.Boolean]
        $UserDefinedWorkflowsEnabled,

        [Parameter()]
        [System.Boolean]
        $EmailToNoPermissionWorkflowParticipantsEnable,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing web application '$WebAppUrl' workflow settings"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $relPath = "..\..\Modules\SharePointDsc.WebApplication\SPWebApplication.Workflow.psm1"
    Import-Module (Join-Path $PSScriptRoot $relPath -Resolve)
    $result = Test-SPDscWebApplicationWorkflowConfig -CurrentSettings $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredSettings $PSBoundParameters

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPWebAppWorkflowSettings\MSFT_SPWebAppWorkflowSettings.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module

    $webApps = Get-SPWebApplication
    foreach ($wa in $webApps)
    {
        try
        {
            if ($null -ne $wa)
            {
                $params.WebAppUrl = $wa.Url
                $PartialContent = "        SPWebAppWorkflowSettings " + [System.Guid]::NewGuid().toString() + "`r`n"
                $PartialContent += "        {`r`n"
                $results = Get-TargetResource @params

                if ($results.Contains("InstallAccount"))
                {
                    $results.Remove("InstallAccount")
                }
                $results = Repair-Credentials -results $results
                $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
                $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
                $PartialContent += $currentBlock
                $PartialContent += "        }`r`n"
                $Content += $PartialContent
            }
        }
        catch
        {
            $Global:ErrorLog += "[Web Application Workflow Settings]" + $wa.Url + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
