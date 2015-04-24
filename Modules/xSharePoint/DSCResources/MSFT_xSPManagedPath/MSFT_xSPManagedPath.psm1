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

    Write-Verbose "Looking up the managed path $RelativeUrl in $WebAppUrl"

    $session = Get-xSharePointAuthenticatedPSSession $InstallAccount

    $result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        if ($params.HostHeader) {
            $path = Get-SPManagedPath -Identity $params.RelativeUrl -HostHeader -ErrorAction SilentlyContinue
        }
        else {
            $path = Get-SPManagedPath -WebApplication $params.WebAppUrl -Identity $params.RelativeUrl -ErrorAction SilentlyContinue
        }

        if ($path -eq $null) { return @{} }
        
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

    Write-Verbose "Creating the managed path $RelativeUrl in $WebAppUrl"

    $result = Invoke-Command -ComputerName localhost -Credential $InstallAccount -Authentication CredSSP -ArgumentList ($WebAppUrl,$RelativeUrl,$Explicit,$HostHeader) -ScriptBlock {

        $WebAppUrl = $args[0]
        $RelativeUrl = $args[1]
        $Explicit = $args[2]
        $HostHeader = $args[3]

        Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

        if ($HostHeader) {
            $path = Get-SPManagedPath -Identity $RelativeUrl -HostHeader -ErrorAction SilentlyContinue
        }
        else {
            $path = Get-SPManagedPath -WebApplication $WebAppUrl -Identity $RelativeUrl -ErrorAction SilentlyContinue
        }

        if ($path -eq $null) { 
            
            $newParams = @{}
            if ($HostHeader) {
                $newParams.Add("HostHeader", $HostHeader)
            }
            else {
                $newParams.Add("WebApplication", $WebAppUrl)
            }
            $newParams.Add("RelativeURL", $RelativeUrl)
            $newParams.Add("Explicit", $Explicit)

            New-SPManagedPath @newParams
        }
        
        if ($Explicit) {
            if ($path.Type -ne "ExplicitInclusion") { return $false }
        }
        else {
            if ($path.Type -ne "WildcardInclusion") { return $false }
        }

        return $true
    }

    if ($result -eq $false) { 
        Write-Error "Unable to create the managed path $RelativeUrl in $WebAppUrl - ensure a managed path with the same URL does not already exist."
    }
    $result
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
    Write-Verbose "Looking up the managed path $RelativeUrl in $WebAppUrl"
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

