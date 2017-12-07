function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $WorkflowHostUri,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SPSiteUrl,

        [Parameter()]
        [System.Boolean]
        $AllowOAuthHttp,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting the current Workflow Service Configuration(s)"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]

        $returnvalNull = @{
            WorkflowHostUri = $null
            SPSiteUrl = $null
            AllowOAuthHttp = $null
        }
        $workflowProxy = Get-SPWorkflowServiceProxy

        if($null -eq $workflowProxy)
        {
            return $returnValNull
        }
        $returnval = @{
            WorkflowHostUri = $workflowProxy.GetHostname($SPSiteUrl)
            SPSiteUrl = $SPSiteUrl
            AllowOAuthHttp = $AllowOAuthHttp
        }

        if ($null -eq $wa)
        {
            return $returnvalNull
        }

        return $returnval
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
        $WorkflowHostUri,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SPSiteUrl,

        [Parameter()]
        [System.Boolean]
        $AllowOAuthHttp,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Registering the Workflow Service"

    ## Perform changes
    Invoke-SPDSCCommand -Credential $InstallAccount `
                        -Arguments @($PSBoundParameters) `
                        -ScriptBlock {
        $params = $args[0]

        $site = Get-SPSite $SPSiteUrl

        if ($null -eq $site)
        {
            throw "Specified site collection could not be found."
        }

        Write-Verbose -Message "Processing changes"

        Register-SPWorkflowService -WorkflowServiceUri $WorkflowServiceUri -SPSite $SPSiteUrl -AllowOAuthHtpp:$AllowOAuthHttp
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
        $WorkflowHostUri,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SPSiteUrl,

        [Parameter()]
        [System.Boolean]
        $AllowOAuthHttp,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing Workflow Service"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($null -eq $CurrentValues.WorkflowServiceUri)
    {
        return $false
    }

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
    -DesiredValues $PSBoundParameters `
    -ValuesToCheck @("Ensure")
}

Export-ModuleMember -Function *-TargetResource
