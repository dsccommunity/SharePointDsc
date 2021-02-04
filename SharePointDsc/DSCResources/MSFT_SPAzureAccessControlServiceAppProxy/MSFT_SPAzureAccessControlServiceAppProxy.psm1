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

        [Parameter(Mandatory = $true)]
        [System.String]
        $MetadataServiceEndpointUri,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting ACS service app proxy '$Name'"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $serviceAppProxy = Get-SPServiceApplicationProxy `
        | Where-Object -FilterScript {
            $_.Name -eq $params.Name -and `
                $_.GetType().FullName -eq "Microsoft.SharePoint.Administration.SPAzureAccessControlServiceApplicationProxy"
        }
        $nullReturn = @{
            Name                       = $params.Name
            MetadataServiceEndpointUri = $null
            Ensure                     = "Absent"
        }
        if ($null -eq $serviceAppProxy)
        {
            return $nullReturn
        }
        else
        {
            $returnVal = @{
                Name                       = $serviceAppProxy.Name
                MetadataServiceEndpointUri = $serviceAppProxy.MetadataEndpointUri.OriginalString
                Ensure                     = "Present"
            }
            return $returnVal
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

        [Parameter(Mandatory = $true)]
        [System.String]
        $MetadataServiceEndpointUri,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting ACS service app proxy '$Name'"

    $result = Get-TargetResource @PSBoundParameters

    if ($result.Ensure -eq "Absent" -and $Ensure -eq "Present")
    {
        # The service app proxy doesn't exist but should
        Write-Verbose -Message "Creating ACS service app proxy $Name"
        Invoke-SPDSCCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            New-SPAzureAccessControlServiceApplicationProxy -Name $params.Name `
                -MetadataServiceEndpointUri $params.MetadataServiceEndpointUri
        }
    }

    if ($result.Ensure -eq "Present" -and $Ensure -eq "Present")
    {
        # The service app proxy exists but has the wrong Metadata Service Endpoint Uri
        if ($MetadataServiceEndpointUri -ne $result.MetadataServiceEndpointUri)
        {
            Write-Verbose -Message "Recreating ACS service app proxy $Name"
            Invoke-SPDSCCommand -Credential $InstallAccount `
                -Arguments $PSBoundParameters `
                -ScriptBlock {
                $params = $args[0]

                Get-SPServiceApplicationProxy `
                | Where-Object -FilterScript {
                    $_.Name -eq $params.Name -and `
                        $_.GetType().FullName -eq "Microsoft.SharePoint.Administration.SPAzureAccessControlServiceApplicationProxy"
                } `
                | ForEach-Object {
                    Remove-SPServiceApplicationProxy $_ -Confirm:$false
                }

                New-SPAzureAccessControlServiceApplicationProxy -Name $params.Name `
                    -MetadataServiceEndpointUri $params.MetadataServiceEndpointUri
            }
        }
    }

    if ($Ensure -eq "Absent")
    {
        # The service app proxy should not exit
        Write-Verbose -Message "Removing ACS service app proxy $Name"
        Invoke-SPDSCCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            Get-SPServiceApplicationProxy | Where-Object -FilterScript {
                $_.Name -eq $params.Name -and `
                    $_.GetType().FullName -eq "Microsoft.SharePoint.Administration.SPAzureAccessControlServiceApplicationProxy"
            } | ForEach-Object {
                Remove-SPServiceApplicationProxy $_ -Confirm:$false
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

        [Parameter(Mandatory = $true)]
        [System.String]
        $MetadataServiceEndpointUri,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing ACS service app proxy '$Name'"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($Ensure -eq "Present")
    {
        $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("MetadataServiceEndpointUri", "Ensure")
    }
    else
    {
        $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("Ensure")
    }

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

Export-ModuleMember -Function *-TargetResource
