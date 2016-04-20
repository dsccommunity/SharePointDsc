function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $WebAppUrl,
        [parameter(Mandatory = $true)]  [System.String]  $RelativeUrl,
        [parameter(Mandatory = $true)]  [System.Boolean] $Explicit,
        [parameter(Mandatory = $true)]  [System.Boolean] $HostHeader,
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] [System.String] $Ensure = "Present",
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Looking up the managed path $RelativeUrl in $WebAppUrl"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $getParams = @{
            Identity = $params.RelativeUrl 
        }
        if ($params.HostHeader) {
            $getParams.Add("HostHeader", $true)
        } else {
            $getParams.Add("WebApplication", $params.WebAppUrl)
        }
        $path = Get-SPManagedPath @getParams -ErrorAction SilentlyContinue
        if ($null -eq $path) { return @{
            WebAppUrl      = $params.WebAppUrl
            RelativeUrl    = $params.RelativeUrl
            Explicit       = $params.Explicit
            HostHeader     = $params.HostHeader
            InstallAccount = $params.InstallAccount
            Ensure         = "Absent" 
        } }
        
        return @{
            RelativeUrl    = $path.Name
            Explicit       = ($path.Type -eq "ExplicitInclusion")
            WebAppUrl      = $params.WebAppUrl
            HostHeader     = $params.HostHeader
            InstallAccount = $params.InstallAccount
            Ensure         = "Present"
        }
    }
    return $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $WebAppUrl,
        [parameter(Mandatory = $true)]  [System.String]  $RelativeUrl,
        [parameter(Mandatory = $true)]  [System.Boolean] $Explicit,
        [parameter(Mandatory = $true)]  [System.Boolean] $HostHeader,
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] [System.String] $Ensure = "Present",
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentResults = Get-TargetResource @PSBoundParameters

    if ($CurrentResults.Ensure -eq "Absent" -and $Ensure -eq "Present") { 
        Write-Verbose -Message "Creating the managed path $RelativeUrl in $WebAppUrl"
        Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]

            $newParams = @{}
            if ($params.HostHeader) {
                $newParams.Add("HostHeader", $params.HostHeader)
            }
            else {
                $newParams.Add("WebApplication", $params.WebAppUrl)
            }
            $newParams.Add("RelativeURL", $params.RelativeUrl)
            $newParams.Add("Explicit", $params.Explicit)

            New-SPManagedPath @newParams
        }
    }
    
    if ($Ensure -eq "Absent") {
        Write-Verbose -Message "Removing the managed path $RelativeUrl from $WebAppUrl"
        Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]

            $removeParams = @{}
            if ($params.HostHeader) {
                $removeParams.Add("HostHeader", $params.HostHeader)
            }
            else {
                $removeParams.Add("WebApplication", $params.WebAppUrl)
            }
            $removeParams.Add("Identity", $params.RelativeUrl)

            Remove-SPManagedPath @removeParams -Confirm:$false
        }
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $WebAppUrl,
        [parameter(Mandatory = $true)]  [System.String]  $RelativeUrl,
        [parameter(Mandatory = $true)]  [System.Boolean] $Explicit,
        [parameter(Mandatory = $true)]  [System.Boolean] $HostHeader,
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] [System.String] $Ensure = "Present",
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Looking up the managed path $RelativeUrl in $WebAppUrl"
    $PSBoundParameters.Ensure = $Ensure
    return Test-SPDSCSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("WebAppUrl","RelativeUrl","Explicit","HostHeader", "Ensure")
}


Export-ModuleMember -Function *-TargetResource

