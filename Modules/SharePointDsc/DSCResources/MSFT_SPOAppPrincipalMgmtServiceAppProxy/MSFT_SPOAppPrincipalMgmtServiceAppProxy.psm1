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
        $OnlineTenantUri,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting SPO application principal management service app proxy '$Name'"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $serviceAppProxy = Get-SPServiceApplicationProxy `
        | Where-Object -FilterScript {
            $_.Name -eq $params.Name -and `
                $_.GetType().FullName -eq "Microsoft.SharePoint.Administration.SPOnlineApplicationPrincipalManagementServiceApplicationProxy"
        }
        $nullReturn = @{
            Name            = $params.Name
            OnlineTenantUri = $null
            Ensure          = "Absent"
            InstallAccount  = $params.InstallAccount
        }
        if ($null -eq $serviceAppProxy)
        {
            return $nullReturn
        }
        else
        {
            $returnVal = @{
                Name            = $serviceAppProxy.Name
                OnlineTenantUri = $serviceAppProxy.OnlineTenantUri.OriginalString
                Ensure          = "Present"
                InstallAccount  = $params.InstallAccount
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
        $OnlineTenantUri,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting SPO application principal management service app proxy '$Name'"

    $result = Get-TargetResource @PSBoundParameters

    if ($result.Ensure -eq "Absent" -and $Ensure -eq "Present")
    {
        # The service app proxy doesn't exist but should
        Write-Verbose -Message "Creating SPO application principal management service app proxy $Name"
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            New-SPOnlineApplicationPrincipalManagementServiceApplicationProxy -Name $params.Name `
                -OnlineTenantUri $params.OnlineTenantUri
        }
    }

    if ($result.Ensure -eq "Present" -and $Ensure -eq "Present")
    {
        # The service app proxy exists but has the wrong Online Tenant Uri
        if ($OnlineTenantUri -ne $result.OnlineTenantUri)
        {
            Write-Verbose -Message "Recreating SPO application principal management service app proxy $Name"
            Invoke-SPDscCommand -Credential $InstallAccount `
                -Arguments $PSBoundParameters `
                -ScriptBlock {
                $params = $args[0]

                Get-SPServiceApplicationProxy `
                | Where-Object -FilterScript {
                    $_.Name -eq $params.Name -and `
                        $_.GetType().FullName -eq "Microsoft.SharePoint.Administration.SPOnlineApplicationPrincipalManagementServiceApplicationProxy"
                } `
                | ForEach-Object {
                    Remove-SPServiceApplicationProxy $_ -Confirm:$false
                }

                New-SPOnlineApplicationPrincipalManagementServiceApplicationProxy -Name $params.Name `
                    -OnlineTenantUri $params.OnlineTenantUri
            }
        }
    }

    if ($Ensure -eq "Absent")
    {
        # The service app proxy should not exit
        Write-Verbose -Message "Removing SPO application principal management service app proxy $Name"
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            Get-SPServiceApplicationProxy | Where-Object -FilterScript {
                $_.Name -eq $params.Name -and `
                    $_.GetType().FullName -eq "Microsoft.SharePoint.Administration.SPOnlineApplicationPrincipalManagementServiceApplicationProxy"
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
        $OnlineTenantUri,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing SPO application principal management service app proxy '$Name'"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($Ensure -eq "Present")
    {
        return Test-SPDscParameterState -CurrentValues $CurrentValues `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("OnlineTenantUri", "Ensure")
    }
    else
    {
        return Test-SPDscParameterState -CurrentValues $CurrentValues `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("Ensure")
    }
}

Export-ModuleMember -Function *-TargetResource
