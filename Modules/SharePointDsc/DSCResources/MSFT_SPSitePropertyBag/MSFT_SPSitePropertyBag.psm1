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
            $currentValue = $null
            $localEnsure = 'Absent'
        }
        else
        {
            if ($spSite.Properties)
            {
                if ($spSite.Properties.Contains($params.Key) -eq $true)
                {
                    $localEnsure = 'Present'
                    $currentValue = $spSite.Properties[$params.Key]
                }
                else
                {
                    $localEnsure = 'Absent'
                    $currentValue = $null
                }
            }
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

        if ($params.Ensure -eq 'Present')
        {
            Write-Verbose -Message "Adding property '$($params.Key)'='$($params.value)' to SPSite.Properties"
            $spSite.Properties[$params.Key] = $params.Value
            $spSite.Update()
        }
        else
        {
            Write-Verbose -Message "Removing property '$($params.Key)' from SPSite.Properties"
            $spSite.Properties.Remove($params.Key)
            $spSite.Update()
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
