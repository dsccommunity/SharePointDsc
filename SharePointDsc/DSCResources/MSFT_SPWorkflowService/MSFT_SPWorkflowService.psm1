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
        $WorkflowHostUri,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SPSiteUrl,

        [Parameter()]
        [System.String]
        $ScopeName,

        [Parameter()]
        [System.Boolean]
        $AllowOAuthHttp,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting the current Workflow Service Configuration(s)"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $returnval = @{
            WorkflowHostUri = $null
            SPSiteUrl       = $params.SPSiteUrl
            ScopeName       = $null
            AllowOAuthHttp  = $null
        }

        $site = Get-SPSite $params.SPSiteUrl

        if ($null -eq $site)
        {
            Write-Verbose "Specified site collection could not be found."
        }
        else
        {
            $workflowProxy = Get-SPWorkflowServiceApplicationProxy

            if ($null -ne $workflowProxy)
            {
                $workflowHostUri = $workflowProxy.GetHostname($site)

                if ($null -ne $workflowHostUri)
                {
                    $workflowHostUri = $workflowHostUri.TrimEnd("/")
                }

                $returnval = @{
                    WorkflowHostUri = $workflowHostUri
                    SPSiteUrl       = $params.SPSiteUrl
                    ScopeName       = $workflowProxy.GetWorkflowScopeName($site)
                    AllowOAuthHttp  = $params.AllowOAuthHttp
                }
            }
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
        [System.String]
        $ScopeName,

        [Parameter()]
        [System.Boolean]
        $AllowOAuthHttp,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Registering the Workflow Service"

    ## Perform changes
    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]

        $site = Get-SPSite $params.SPSiteUrl

        if ($null -eq $site)
        {
            $message = "Specified site collection could not be found."
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }

        Write-Verbose -Message "Processing changes"

        $workflowServiceParams = @{
            WorkflowHostUri = $params.WorkflowHostUri.TrimEnd("/")
            SPSite          = $site
            AllowOAuthHttp  = $params.AllowOAuthHttp
        }

        if ($params.ContainsKey("ScopeName"))
        {
            $workflowServiceParams.Add("ScopeName", $params.ScopeName)
        }

        Register-SPWorkflowService @workflowServiceParams -Force
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
        [System.String]
        $ScopeName,

        [Parameter()]
        [System.Boolean]
        $AllowOAuthHttp,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing Workflow Service"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($null -eq $CurrentValues.WorkflowHostUri)
    {
        $message = "WorkflowHostUri is not configured"
        Write-Verbose -Message $message
        Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

        Write-Verbose -Message "Test-TargetResource returned false"
        return $false
    }

    $PSBoundParameters.WorkflowHostUri = $PSBoundParameters.WorkflowHostUri.TrimEnd("/")
    $valuesToCheck = @("WorkflowHostUri")

    if ($ScopeName)
    {
        $valuesToCheck += "ScopeName"
    }

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck $valuesToCheck

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

Export-ModuleMember -Function *-TargetResource
