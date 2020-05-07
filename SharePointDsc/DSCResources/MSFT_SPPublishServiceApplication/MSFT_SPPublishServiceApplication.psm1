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
        [System.String]
        $Name,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Getting service application publish status '$Name'"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $serviceApp = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue

        if ($null -eq $serviceApp)
        {
            Write-Verbose -Message "The service application $Name does not exist"
            $sharedEnsure = "Absent"
        }

        if ($null -eq $serviceApp.Uri)
        {
            Write-Verbose -Message ("Only Business Data Connectivity, Machine Translation, Managed Metadata, " + `
                    "User Profile, Search, Secure Store are supported to be published via DSC.")
            $sharedEnsure = "Absent"
        }
        else
        {
            if ($serviceApp.Shared -eq $true)
            {
                $sharedEnsure = "Present"
            }
            elseif ($serviceApp.Shared -eq $false)
            {
                $sharedEnsure = "Absent"
            }
        }

        return @{
            Name   = $params.Name
            Ensure = $sharedEnsure
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
        [System.String]
        $Name,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Setting service application publish status '$Name'"

    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $serviceApp = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue
        if ($null -eq $serviceApp)
        {
            throw [Exception] ("The service application $Name does not exist")
        }

        if ($null -eq $serviceApp.Uri)
        {
            throw [Exception] ("Only Business Data Connectivity, Machine Translation, Managed Metadata, " + `
                    "User Profile, Search, Secure Store are supported to be published via DSC.")
        }

        if ($Ensure -eq "Present")
        {
            Write-Verbose -Message "Publishing Service Application $Name"
            Publish-SPServiceApplication -Identity $serviceApp
        }

        if ($Ensure -eq "Absent")
        {
            Write-Verbose -Message "Unpublishing Service Application $Name"
            Unpublish-SPServiceApplication  -Identity $serviceApp
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
        [System.String]
        $Name,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Testing service application '$Name'"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("Name", "Ensure")

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

Export-ModuleMember -Function *-TargetResource
