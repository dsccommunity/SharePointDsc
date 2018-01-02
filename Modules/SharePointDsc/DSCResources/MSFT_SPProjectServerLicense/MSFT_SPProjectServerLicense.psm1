function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [Parameter()]
        [System.String]
        $ProductKey,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting license status for Project Server"

    if ((Get-SPDSCInstalledProductVersion).FileMajorPart -lt 16)
    {
        throw [Exception] ("Support for Project Server in SharePointDsc is only valid for " + `
                           "SharePoint 2016.")
    }

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]

        try
        {
            $currentLicense = Get-ProjectServerLicense

            if ($currentLicense -match "Project Server [0-9]{4} : (?<Status>[a-zA-Z]+)")
            {
                if ($Matches.Status -eq "Active")
                {
                    $status = "Present"
                }
                else
                {
                    $status = "Absent"
                }

                return @{
                    Ensure = $status
                    ProductKey = $params.ProductKey
                    InstallAccount = $params.InstallAccount
                }
            }
            else
            {
                Write-Verbose -Message "Unable to determine the license status for Project Server"
                return @{
                    Ensure = "Absent"
                    ProductKey = $params.ProductKey
                    InstallAccount = $params.InstallAccount
                }
            }
        }
        catch
        {
            Write-Verbose -Message "Unable to determine the license status for Project Server"
            return @{
                Ensure = "Absent"
                ProductKey = $params.ProductKey
                InstallAccount = $params.InstallAccount
            }
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
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [Parameter()]
        [System.String]
        $ProductKey,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting Project Server License status"

    if ((Get-SPDSCInstalledProductVersion).FileMajorPart -lt 16)
    {
        throw [Exception] ("Support for Project Server in SharePointDsc is only valid for " + `
                           "SharePoint 2016.")
    }

    if ($Ensure -eq "Present" -and $PSBoundParameters.ContainsKey("ProductKey") -eq $false)
    {
        throw [Exception] "ProductKey is requried when Ensure equals 'Present'"
    }

    $currentValues = Get-TargetResource @PSBoundParameters

    if ($currentValues.Ensure -ne $Ensure)
    {
        # License status does not match
        if ($Ensure -eq "Present")
        {
            Invoke-SPDSCCommand -Credential $InstallAccount `
                                -Arguments $PSBoundParameters `
                                -ScriptBlock {

                $params = $args[0]
                Enable-ProjectServerLicense -key $params.ProductKey
            }
        }
        if ($Ensure -eq "Absent")
        {
            Invoke-SPDSCCommand -Credential $InstallAccount `
                                -Arguments $PSBoundParameters `
                                -ScriptBlock {

                Disable-ProjectServerLicense
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
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [Parameter()]
        [System.String]
        $ProductKey,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing Project Server License status"

    $currentValues = Get-TargetResource @PSBoundParameters

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @("Ensure")
}

Export-ModuleMember -Function *-TargetResource
