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
        -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]

        $serviceApp = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue
        if ($null -eq $serviceApp)
        {
            $message = ("The service application $Name does not exist")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }

        if ($null -eq $serviceApp.Uri)
        {
            $message = ("Only Business Data Connectivity, Machine Translation, Managed Metadata, " + `
                    "User Profile, Search, Secure Store are supported to be published via DSC.")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
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


function Export-TargetResource
{
    if (!(Get-PSSnapin Microsoft.SharePoint.Powershell -ErrorAction SilentlyContinue))
    {
        Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction 0
    }
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDSC" | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPPublishServiceApplication\MSFT_SPPublishServiceApplication.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module

    $ssas = Get-SPServiceApplication | Where-Object { $_.Shared -eq $true }
    foreach ($ssa in $ssas)
    {
        $params.Name = $ssa.DisplayName
        $results = Get-TargetResource @params
        $PartialContent = "        SPPublishServiceApplication " + [System.Guid]::NewGuid().ToString() + "`r`n"
        $PartialContent += "        {`r`n"
        $results = Repair-Credentials -results $results
        $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
        $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
        $PartialContent += $currentBlock
        $PartialContent += "        }`r`n"
        $Content += $PartialContent
    }
    return $Content
}


Export-ModuleMember -Function *-TargetResource

