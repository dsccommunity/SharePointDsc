function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [parameter(Mandatory = $true)]
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

    $session = Get-xSharePointAuthenticatedPSSession -Credential $InstallAccount

    $result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        if ($params.HostHeader) {
            $path = Get-SPManagedPath -Identity $params.RelativeUrl -HostHeader -ErrorAction SilentlyContinue
        }
        else {
            $path = Get-SPManagedPath -WebApplication $params.WebAppUrl -Identity $params.RelativeUrl -ErrorAction SilentlyContinue
        }

        if ($null -eq $path) { return @{} }
        
        return @{
            Name = $path.Name
            PathType = $path.Type
        }
    }
    $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [parameter(Mandatory = $true)]
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

    $session = Get-xSharePointAuthenticatedPSSession -Credential $InstallAccount

    $result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        if ($params.HostHeader) {
            $path = Get-SPManagedPath -Identity $params.RelativeUrl -HostHeader -ErrorAction SilentlyContinue
        }
        else {
            $path = Get-SPManagedPath -WebApplication $params.WebAppUrl -Identity $params.RelativeUrl -ErrorAction SilentlyContinue
        }

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

            New-SPManagedPath @newParams
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

        [parameter(Mandatory = $true)]
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

    $result = Get-TargetResource -WebAppUrl $WebAppUrl -InstallAccount $InstallAccount -RelativeUrl $RelativeUrl -Explicit $Explicit -HostHeader $HostHeader
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

