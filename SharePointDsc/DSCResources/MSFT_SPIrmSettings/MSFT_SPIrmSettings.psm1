function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter()]
        [System.String]
        [ValidateSet("Present", "Absent")]
        $Ensure,

        [Parameter()]
        [System.Boolean]
        $UseADRMS,

        [Parameter()]
        [System.String]
        $RMSserver,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose "Getting SharePoint IRM Settings"

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
            Write-Verbose -Message ("No local SharePoint farm was detected. IRM settings " + `
                    "will not be applied")
            return @{
                IsSingleInstance = "Yes"
                Ensure           = "Absent"
                UseADRMS         = $UseADRMS
                RMSserver        = $RMSserver
            }
        }

        # Get a reference to the Administration WebService
        $admService = Get-SPDscContentService

        if ($admService.IrmSettings.IrmRMSEnabled)
        {
            $Ensure = "Present"
        }
        else
        {
            $Ensure = "Absent"
        }

        return @{
            IsSingleInstance = "Yes"
            Ensure           = $Ensure
            UseADRMS         = $admService.IrmSettings.IrmRMSUseAD
            RMSserver        = $admService.IrmSettings.IrmRMSCertServer
        }
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
        [System.String]
        [ValidateSet("Present", "Absent")]
        $Ensure,

        [Parameter()]
        [System.Boolean]
        $UseADRMS,

        [Parameter()]
        [System.String]
        $RMSserver,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose "Setting SharePoint IRM Settings"

    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]

        try
        {
            $null = Get-SPFarm
        }
        catch
        {
            $message = "No local SharePoint farm was detected. IRM settings will not be applied"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }

        $admService = Get-SPDscContentService

        if ($params.UseADRMS -and ($null -ne $params.RMSserver))
        {
            $message = "Cannot specify both an RMSserver and set UseADRMS to True"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }

        if ($params.UseADRMS -ne $true)
        {
            $params.UseADRMS = $false
        }

        if ($params.Ensure -eq "Present")
        {
            $admService.IrmSettings.IrmRMSEnabled = $true
            $admService.IrmSettings.IrmRMSUseAD = $params.UseADRMS
            $admService.IrmSettings.IrmRMSCertServer = $params.RMSserver
        }
        else
        {
            $admService.IrmSettings.IrmRMSEnabled = $false
            $admService.IrmSettings.IrmRMSUseAD = $false
            $admService.IrmSettings.IrmRMSCertServer = $null
        }
        $admService.Update()
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
        [System.String]
        [ValidateSet("Present", "Absent")]
        $Ensure,

        [Parameter()]
        [System.Boolean]
        $UseADRMS,

        [Parameter()]
        [System.String]
        $RMSserver,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose "Testing SharePoint IRM settings"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($UseADRMS -ne $true)
    {
        $PSBoundParameters.UseADRMS = $false
    }

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    if (!(Get-PSSnapin Microsoft.SharePoint.Powershell -ErrorAction SilentlyContinue))
    {
        Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction 0
    }
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDSC" | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPIrmSettings\MSFT_SPIrmSettings.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module
    $PartialContent = "        SPIrmSettings " + [System.Guid]::NewGuid().ToString() + "`r`n"
    $PartialContent += "        {`r`n"
    $results = Get-TargetResource @params

    $results = Repair-Credentials -results $results

    $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
    $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
    $PartialContent += $currentBlock
    $PartialContent += "        }`r`n"
    $Content += $PartialContent
    return $Content
}

Export-ModuleMember -Function *-TargetResource
