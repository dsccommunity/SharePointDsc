$script:resourceModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:resourceModulePath -ChildPath 'Modules'
$script:resourceHelperModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'SharePointDsc.Util'
Import-Module -Name (Join-Path -Path $script:resourceHelperModulePath -ChildPath 'SharePointDsc.Util.psm1')

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
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        try
        {
            $null = Get-SPFarm
        }
        catch
        {
            throw "No local SharePoint farm was detected. IRM settings will not be applied"
            return
        }

        $admService = Get-SPDscContentService

        if ($params.UseADRMS -and ($null -ne $params.RMSserver))
        {
            throw "Cannot specify both an RMSserver and set UseADRMS to True"
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

Export-ModuleMember -Function *-TargetResource
