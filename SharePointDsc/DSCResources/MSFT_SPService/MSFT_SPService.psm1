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
        $Name,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting status for service '$Name'"

    if ((Get-SPDscInstalledProductVersion).FileMajorPart -eq 15)
    {
        $message = ("This resource is only supported on SharePoint 2016 and later. " + `
                "SharePoint 2013 does not support MinRole yet.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters) `
        -ScriptBlock {
        $params = $args[0]

        $service = Get-SPService -Identity $params.Name -ErrorAction 'SilentlyContinue'

        if ($null -eq $service)
        {
            return @{
                Name   = $params.Name
                Ensure = "Absent"
            }
        }

        if ($service.AutoProvision -eq $true)
        {
            $localEnsure = "Present"
        }
        else
        {
            $localEnsure = "Absent"
        }

        return @{
            Name   = $params.Name
            Ensure = $localEnsure
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
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting status for service '$Name'"

    if ((Get-SPDscInstalledProductVersion).FileMajorPart -eq 15)
    {
        $message = ("This resource is only supported on SharePoint 2016 and later. " + `
                "SharePoint 2013 does not support MinRole yet.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $invokeArgs = @{
        Credential = $InstallAccount
        Arguments  = @($PSBoundParameters, $MyInvocation.MyCommand.Source)
    }

    if ($Ensure -eq "Present")
    {
        Write-Verbose -Message "Provisioning service '$Name'"

        Invoke-SPDscCommand @invokeArgs -ScriptBlock {
            $params = $args[0]
            $eventSource = $args[1]

            $service = Get-SPService -Identity $params.Name -ErrorAction 'SilentlyContinue'

            if ($null -eq $service)
            {
                $message = "Specified service does not exist '$($params.Name)'"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
                throw $message
            }

            Start-SPService -Identity $params.Name | Out-Null

            # Waiting for the service to start before continuing (max 30 minutes)
            $serviceCheck = Get-SPService -Identity $params.Name

            $count = 0
            $maxCount = 60

            while (($count -lt $maxCount) -and ($serviceCheck.CompliantWithMinRole -ne $true))
            {
                Write-Verbose -Message ("$([DateTime]::Now.ToShortTimeString()) - Waiting " + `
                        "for services to start on all servers. Current status: $($serviceCheck.Status) " + `
                        "(waited $count of $maxCount)")
                Start-Sleep -Seconds 30
                $serviceCheck = Get-SPService -Identity $params.Name
                $count++
            }
        }
    }
    else
    {
        Write-Verbose -Message "Deprovisioning service '$Name'"

        Invoke-SPDscCommand @invokeArgs -ScriptBlock {
            $params = $args[0]
            $eventSource = $args[1]

            $service = Get-SPService -Identity $params.Name -ErrorAction 'SilentlyContinue'

            if ($null -eq $service)
            {
                $message = "Specified service does not exist '$($params.Name)'"
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
                throw $message
            }

            Stop-SPService -Identity $params.Name -Confirm:$false | Out-Null

            # Waiting for the service to stop before continuing (max 30 minutes)
            $serviceCheck = Get-SPService -Identity $params.Name

            $count = 0
            $maxCount = 60

            while (($count -lt $maxCount) -and ($serviceCheck.AutoProvision -ne $false))
            {
                Write-Verbose -Message ("$([DateTime]::Now.ToShortTimeString()) - Waiting " + `
                        "for service to stop on all servers. Current status: $($serviceCheck.Status) " + `
                        "(waited $count of $maxCount)")
                Start-Sleep -Seconds 30
                $serviceCheck = Get-SPService -Identity $params.Name
                $count++
            }
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
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing status for service '$Name'"

    $PSBoundParameters.Ensure = $Ensure

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
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath "\DSCResources\MSFT_SPService\MSFT_SPService.psm1" -Resolve

    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module

    $services = Get-SPService
    foreach ($service in $services)
    {
        $PartialContent = "        SPService Service_" + $($service.TypeName -replace " ", '') + "`r`n"
        $PartialContent += "        {`r`n"
        $params.Name = $service.TypeName
        $params.Ensure = "Present"
        $results = Get-TargetResource @params

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
