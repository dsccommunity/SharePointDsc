function Get-TargetResource()
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
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Looking for SPSite property '$Key'"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]

        $spSite = Get-SPSite -Identity $params.Url -ErrorAction SilentlyContinue

        if ($null -eq $spSite)
        {
            throw "Specified site collection could not be found."
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
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting SPSite property '$Key'"

    Invoke-SPDSCCommand -Credential $InstallAccount `
                        -Arguments $PSBoundParameters `
                        -ScriptBlock {
        $params = $args[0]

        $spSite = Get-SPSite -Identity $params.Url -ErrorAction SilentlyContinue

        if ($null -eq $spSite)
        {
            throw "Specified site collection could not be found."
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
            throw "Cannot retrieve the property bag. Please check if you have the correct permissions."
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
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing SPSite property '$Key'"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if($Ensure -eq 'Present')
    {
        return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                        -DesiredValues $PSBoundParameters `
                                        -ValuesToCheck @('Ensure','Key', 'Value')
    }
    else
    {
        return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                        -DesiredValues $PSBoundParameters `
                                        -ValuesToCheck @('Ensure','Key')

    }

}

Export-ModuleMember -Function *-TargetResource
