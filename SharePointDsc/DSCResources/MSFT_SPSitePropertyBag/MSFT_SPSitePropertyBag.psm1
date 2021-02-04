$script:SPDscUtilModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SharePointDsc.Util'
Import-Module -Name $script:SPDscUtilModulePath

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.HashTable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Url,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Key,

        [Parameter()]
        [System.String]
        $Value,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Looking for SPSite property '$Key'"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]

        $spSite = Get-SPSite -Identity $params.Url -ErrorAction SilentlyContinue

        if ($null -eq $spSite)
        {
            $message = "Specified site collection could not be found."
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }

        if ($null -ne $spSite.RootWeb.Properties -and `
                $spSite.RootWeb.Properties.ContainsKey($params.Key) -eq $true)
        {
            $localEnsure = 'Present'
            $currentValue = $spSite.RootWeb.Properties[$params.Key]
        }
        else
        {
            $localEnsure = 'Absent'
            $currentValue = $null
        }

        return @{
            Url    = $params.Url
            Key    = $params.Key
            Value  = $currentValue
            Ensure = $localEnsure
        }
    }
    return $result
}

function Set-TargetResource()
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Url,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Key,

        [Parameter()]
        [System.String]
        $Value,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting SPSite property '$Key'"

    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]

        $spSite = Get-SPSite -Identity $params.Url -ErrorAction SilentlyContinue

        if ($null -eq $spSite)
        {
            $message = "Specified site collection could not be found."
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }

        $spWeb = $spSite.OpenWeb()

        if ($null -ne $spWeb.Properties)
        {
            if ($params.Ensure -eq 'Present')
            {
                Write-Verbose -Message "Adding property '$($params.Key)'='$($params.value)' to SPWeb.Properties"
                $spWeb.Properties[$params.Key] = $params.Value
                $spWeb.Properties.Update()
                $spWeb.Update()
            }
            else
            {
                Write-Verbose -Message "Removing property '$($params.Key)' from SPWeb.AllProperties"
                $spWeb.AllProperties.Remove($params.Key.ToLower())
                $spWeb.Update()
            }
        }
        else
        {
            $message = "Cannot retrieve the property bag. Please check if you have the correct permissions."
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }
    }
}

function Test-TargetResource()
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Url,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Key,

        [Parameter()]
        [System.String]
        $Value,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing SPSite property '$Key'"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($Ensure -eq 'Present')
    {
        $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @('Ensure', 'Key', 'Value')
    }
    else
    {
        $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @('Ensure', 'Key')

    }

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

Export-ModuleMember -Function *-TargetResource
