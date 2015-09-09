function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [parameter(Mandatory = $true)]
        [System.String]
        $RelativeUrl,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $Explicit,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $HostHeader
    )

    Write-Verbose -Message "Looking up the managed path $RelativeUrl in $WebAppUrl"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
		$getParams = @{
			Identity = $params.RelativeUrl 
		}
        if ($params.HostHeader) {
            $getParams.Add("HostHeader", $true)
        }
		$path = Invoke-xSharePointSPCmdlet -CmdletName "Get-SPManagedPath" -Arguments $getParams -ErrorAction SilentlyContinue
        if ($null -eq $path) { return @{} }
        
        return @{
            Name = $path.Name
            PathType = $path.Type
        }
    }
    return $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [parameter(Mandatory = $true)]
        [System.String]
        $RelativeUrl,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $Explicit,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $HostHeader
    )

    Write-Verbose -Message "Creating the managed path $RelativeUrl in $WebAppUrl"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $path = Get-TargetResource @params
        if ($null -eq $path) { 
            
            $newParams = @{}
            if ($params.HostHeader) {
                $newParams.Add("HostHeader", $params.HostHeader)
            }
            else {
                $newParams.Add("WebApplication", $params.WebAppUrl)
            }
            $newParams.Add("RelativeURL", $params.RelativeUrl)
            $newParams.Add("Explicit", $params.Explicit)

            Invoke-xSharePointSPCmdlet -CmdletName "New-SPManagedPath" -Arguements $newParams
        }
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [parameter(Mandatory = $true)]
        [System.String]
        $RelativeUrl,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $Explicit,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $HostHeader
    )

    $result = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Looking up the managed path $RelativeUrl in $WebAppUrl"
    if ($result.Count -eq 0) { return $false }
    else {
        if ($Explicit) {
            if ($result.PathType -ne "ExplicitInclusion") { return $false }
        }
        else {
            if ($result.PathType -ne "WildcardInclusion") { return $false }
        }
    }
    return $true
}


Export-ModuleMember -Function *-TargetResource

